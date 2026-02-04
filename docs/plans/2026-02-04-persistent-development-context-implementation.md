# Persistent Development Context - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a persistent context system that enables iterative development cycles with context that survives session restarts.

**Architecture:** New skills (`init`, `checkpoint`, `continue`, `verify`, `complete`) with supporting JavaScript library for hierarchical state management. Skills are markdown-based, commands invoke skills.

**Tech Stack:** Markdown (skills, state files), JavaScript (lib/project-context.js), Bash (test scripts), existing superpowers infrastructure.

---

## Phase 1: Foundation

### Task 1: Create Project Context Library - State Schema

**Files:**
- Create: `lib/project-context.js`

**Step 1: Write the failing test**

Create test file first:

```bash
# tests/claude-code/test-project-context.sh
```

```bash
#!/bin/bash
# Test project-context.js functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: project-context library ==="

# Test 1: Module exports expected functions
echo -e "\nTest 1: Module exports..."

node -e "
const pc = require('../../lib/project-context.js');
const fns = ['createProject', 'loadState', 'saveState', 'addCheckpoint', 'loadProblems', 'addProblem', 'findProjects'];
const missing = fns.filter(f => typeof pc[f] !== 'function');
if (missing.length > 0) {
  console.log('Missing exports:', missing.join(', '));
  process.exit(1);
}
console.log('All exports present');
" && echo "  [PASS] Module exports correct" || echo "  [FAIL] Module exports"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-project-context.sh
bash tests/claude-code/test-project-context.sh
```

Expected: FAIL with "Cannot find module" or "Missing exports"

**Step 3: Write minimal implementation**

```javascript
// lib/project-context.js
import fs from 'fs';
import path from 'path';

/**
 * Create a new project folder structure.
 *
 * @param {string} baseDir - Base directory (usually repo root)
 * @param {string} projectName - Name for the project
 * @param {string} requirement - Initial requirement/prompt text
 * @returns {{projectDir: string, files: string[]}}
 */
function createProject(baseDir, projectName, requirement) {
    const projectDir = path.join(baseDir, 'docs', 'plans', projectName);

    if (fs.existsSync(projectDir)) {
        throw new Error(`Project already exists: ${projectDir}`);
    }

    fs.mkdirSync(projectDir, { recursive: true });

    // Create requirement.md
    const requirementPath = path.join(projectDir, 'requirement.md');
    fs.writeFileSync(requirementPath, requirement);

    // Create initial state.md
    const now = new Date();
    const timestamp = now.toISOString().split('T')[0];
    const stateContent = `# ${projectName}

## Summary
Phase: init
Status: Created
Last active: ${timestamp}
Key commits: (none)
Active problems: 0

## Checkpoints
- [${formatTimestamp(now)}] init: Project created

## Decisions

## Implementation

## Testing Approach
- Prefer: Integration tests over unit tests
- Minimize: Mocking - test real behavior with real dependencies
- Coverage: Critical paths must have integration tests
`;

    const statePath = path.join(projectDir, 'state.md');
    fs.writeFileSync(statePath, stateContent);

    // Create empty problems.md
    const problemsContent = `# Problems Log: ${projectName}

(No problems recorded yet)
`;
    const problemsPath = path.join(projectDir, 'problems.md');
    fs.writeFileSync(problemsPath, problemsContent);

    return {
        projectDir,
        files: [requirementPath, statePath, problemsPath]
    };
}

/**
 * Load state.md with optional section filtering.
 *
 * @param {string} projectDir - Path to project directory
 * @param {object} options - Loading options
 * @param {boolean} options.summaryOnly - Load only Summary section
 * @param {boolean} options.includeCheckpoints - Include Checkpoints section
 * @param {boolean} options.includeDecisions - Include Decisions section
 * @param {boolean} options.includeImplementation - Include Implementation section
 * @param {boolean} options.full - Load everything
 * @returns {{content: string, sections: object}}
 */
function loadState(projectDir, options = {}) {
    const statePath = path.join(projectDir, 'state.md');

    if (!fs.existsSync(statePath)) {
        throw new Error(`State file not found: ${statePath}`);
    }

    const content = fs.readFileSync(statePath, 'utf8');
    const sections = parseStateSections(content);

    if (options.full) {
        return { content, sections };
    }

    // Build filtered content based on options
    let filtered = `# ${sections.title || 'Project'}\n\n`;
    filtered += `## Summary\n${sections.summary || ''}\n\n`;

    if (options.includeCheckpoints !== false) {
        filtered += `## Checkpoints\n${sections.checkpoints || ''}\n\n`;
    }

    if (options.includeDecisions) {
        filtered += `## Decisions\n${sections.decisions || ''}\n\n`;
    }

    if (options.includeImplementation) {
        filtered += `## Implementation\n${sections.implementation || ''}\n\n`;
    }

    return { content: filtered.trim(), sections };
}

/**
 * Save/update state.md file.
 *
 * @param {string} projectDir - Path to project directory
 * @param {object} sections - Sections to update
 */
function saveState(projectDir, sections) {
    const statePath = path.join(projectDir, 'state.md');
    const existing = fs.existsSync(statePath)
        ? parseStateSections(fs.readFileSync(statePath, 'utf8'))
        : {};

    const merged = { ...existing, ...sections };
    const content = buildStateContent(merged);

    fs.writeFileSync(statePath, content);
}

/**
 * Add a checkpoint entry to state.md.
 *
 * @param {string} projectDir - Path to project directory
 * @param {string} phase - Current phase (init, brainstorm, plan, execute, etc.)
 * @param {string} description - Checkpoint description
 * @param {object} options - Additional options
 * @param {string} options.commit - Git commit SHA if relevant
 */
function addCheckpoint(projectDir, phase, description, options = {}) {
    const statePath = path.join(projectDir, 'state.md');
    const content = fs.readFileSync(statePath, 'utf8');
    const sections = parseStateSections(content);

    const now = new Date();
    const timestamp = formatTimestamp(now);
    let checkpointLine = `- [${timestamp}] ${phase}: ${description}`;

    if (options.commit) {
        checkpointLine += ` (${options.commit.substring(0, 7)})`;
    }

    // Append to checkpoints
    sections.checkpoints = (sections.checkpoints || '').trim() + '\n' + checkpointLine;

    // Update summary
    sections.summary = updateSummaryPhase(sections.summary, phase, now);

    const newContent = buildStateContent(sections);
    fs.writeFileSync(statePath, newContent);
}

/**
 * Load problems.md file.
 *
 * @param {string} projectDir - Path to project directory
 * @param {object} options - Loading options
 * @param {boolean} options.activeOnly - Only return active problems
 * @returns {{content: string, problems: Array}}
 */
function loadProblems(projectDir, options = {}) {
    const problemsPath = path.join(projectDir, 'problems.md');

    if (!fs.existsSync(problemsPath)) {
        return { content: '', problems: [] };
    }

    const content = fs.readFileSync(problemsPath, 'utf8');
    const problems = parseProblems(content);

    if (options.activeOnly) {
        const active = problems.filter(p => p.status === 'Active');
        return { content, problems: active };
    }

    return { content, problems };
}

/**
 * Add a problem entry to problems.md.
 *
 * @param {string} projectDir - Path to project directory
 * @param {object} problem - Problem details
 * @param {string} problem.id - Unique identifier (slug)
 * @param {string} problem.symptom - What's happening
 * @param {string} problem.commit - Related commit SHA
 */
function addProblem(projectDir, problem) {
    const problemsPath = path.join(projectDir, 'problems.md');
    let content = '';

    if (fs.existsSync(problemsPath)) {
        content = fs.readFileSync(problemsPath, 'utf8');
    } else {
        const projectName = path.basename(projectDir);
        content = `# Problems Log: ${projectName}\n\n`;
    }

    // Remove the "no problems" placeholder if present
    content = content.replace(/\(No problems recorded yet\)\n?/, '');

    const now = new Date();
    const timestamp = now.toISOString().split('T')[0];

    const problemEntry = `
## ${problem.id}
**Status:** Active
**Discovered:** ${timestamp}
${problem.commit ? `**Commit:** ${problem.commit}\n` : ''}
### Symptom
${problem.symptom}

### Investigation
(pending)

### Resolution
(pending)

---
`;

    content = content.trim() + '\n' + problemEntry;
    fs.writeFileSync(problemsPath, content);
}

/**
 * Find all projects in docs/plans directory.
 *
 * @param {string} baseDir - Base directory to search
 * @returns {Array<{name: string, path: string, phase: string, lastActive: string}>}
 */
function findProjects(baseDir) {
    const plansDir = path.join(baseDir, 'docs', 'plans');

    if (!fs.existsSync(plansDir)) {
        return [];
    }

    const projects = [];
    const entries = fs.readdirSync(plansDir, { withFileTypes: true });

    for (const entry of entries) {
        if (entry.isDirectory()) {
            const projectDir = path.join(plansDir, entry.name);
            const statePath = path.join(projectDir, 'state.md');

            if (fs.existsSync(statePath)) {
                const content = fs.readFileSync(statePath, 'utf8');
                const sections = parseStateSections(content);
                const summary = parseSummary(sections.summary || '');

                projects.push({
                    name: entry.name,
                    path: projectDir,
                    phase: summary.phase || 'unknown',
                    lastActive: summary.lastActive || 'unknown'
                });
            }
        }
    }

    // Sort by last active, most recent first
    projects.sort((a, b) => b.lastActive.localeCompare(a.lastActive));

    return projects;
}

// Helper functions

function formatTimestamp(date) {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const mins = String(date.getMinutes()).padStart(2, '0');
    return `${month}-${day} ${hours}:${mins}`;
}

function parseStateSections(content) {
    const sections = {};
    const lines = content.split('\n');

    let currentSection = null;
    let sectionContent = [];

    // Get title from first line
    if (lines[0]?.startsWith('# ')) {
        sections.title = lines[0].substring(2).trim();
    }

    for (const line of lines) {
        if (line.startsWith('## ')) {
            // Save previous section
            if (currentSection) {
                sections[currentSection] = sectionContent.join('\n').trim();
            }

            // Start new section
            currentSection = line.substring(3).trim().toLowerCase().replace(/\s+/g, '');
            sectionContent = [];
        } else if (currentSection) {
            sectionContent.push(line);
        }
    }

    // Save last section
    if (currentSection) {
        sections[currentSection] = sectionContent.join('\n').trim();
    }

    return sections;
}

function parseSummary(summaryContent) {
    const result = {};
    const lines = summaryContent.split('\n');

    for (const line of lines) {
        const match = line.match(/^(\w+[\w\s]*):\s*(.+)$/);
        if (match) {
            const key = match[1].toLowerCase().replace(/\s+/g, '');
            result[key] = match[2].trim();
        }
    }

    return result;
}

function updateSummaryPhase(summaryContent, phase, date) {
    const lines = (summaryContent || '').split('\n');
    const newLines = [];
    let foundPhase = false;
    let foundLastActive = false;

    for (const line of lines) {
        if (line.startsWith('Phase:')) {
            newLines.push(`Phase: ${phase}`);
            foundPhase = true;
        } else if (line.startsWith('Last active:')) {
            newLines.push(`Last active: ${date.toISOString().split('T')[0]}`);
            foundLastActive = true;
        } else {
            newLines.push(line);
        }
    }

    if (!foundPhase) {
        newLines.unshift(`Phase: ${phase}`);
    }
    if (!foundLastActive) {
        newLines.push(`Last active: ${date.toISOString().split('T')[0]}`);
    }

    return newLines.join('\n');
}

function buildStateContent(sections) {
    let content = `# ${sections.title || 'Project'}\n\n`;

    if (sections.summary) {
        content += `## Summary\n${sections.summary}\n\n`;
    }

    if (sections.checkpoints) {
        content += `## Checkpoints\n${sections.checkpoints}\n\n`;
    }

    if (sections.decisions) {
        content += `## Decisions\n${sections.decisions}\n\n`;
    }

    if (sections.implementation) {
        content += `## Implementation\n${sections.implementation}\n\n`;
    }

    if (sections.testingapproach) {
        content += `## Testing Approach\n${sections.testingapproach}\n\n`;
    }

    return content.trim() + '\n';
}

function parseProblems(content) {
    const problems = [];
    const sections = content.split(/\n(?=## )/);

    for (const section of sections) {
        if (!section.startsWith('## ') || section.startsWith('# Problems Log')) {
            continue;
        }

        const lines = section.split('\n');
        const id = lines[0].substring(3).trim();

        let status = 'Active';
        let discovered = '';
        let commit = '';
        let symptom = '';

        let inSymptom = false;

        for (const line of lines) {
            if (line.startsWith('**Status:**')) {
                status = line.replace('**Status:**', '').trim();
            } else if (line.startsWith('**Discovered:**')) {
                discovered = line.replace('**Discovered:**', '').trim();
            } else if (line.startsWith('**Commit:**')) {
                commit = line.replace('**Commit:**', '').trim();
            } else if (line === '### Symptom') {
                inSymptom = true;
            } else if (line.startsWith('### ')) {
                inSymptom = false;
            } else if (inSymptom && line.trim()) {
                symptom += line + '\n';
            }
        }

        problems.push({
            id,
            status,
            discovered,
            commit,
            symptom: symptom.trim()
        });
    }

    return problems;
}

export {
    createProject,
    loadState,
    saveState,
    addCheckpoint,
    loadProblems,
    addProblem,
    findProjects
};
```

**Step 4: Run test to verify it passes**

```bash
bash tests/claude-code/test-project-context.sh
```

Expected: PASS - "All exports present"

**Step 5: Commit**

```bash
git add lib/project-context.js tests/claude-code/test-project-context.sh
git commit -m "feat: add project-context library with state management"
```

---

### Task 2: Create /init Skill

**Files:**
- Create: `skills/init/SKILL.md`
- Create: `commands/init.md`

**Step 1: Write the test**

Add to existing test file or create new:

```bash
# tests/claude-code/test-init-skill.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: init skill ==="

# Test 1: Skill file exists with correct frontmatter
echo -e "\nTest 1: Skill structure..."

SKILL_FILE="$SCRIPT_DIR/../../skills/init/SKILL.md"
if [ -f "$SKILL_FILE" ]; then
    echo "  [PASS] Skill file exists"
else
    echo "  [FAIL] Skill file missing"
    exit 1
fi

# Check frontmatter
if grep -q "^name: init$" "$SKILL_FILE"; then
    echo "  [PASS] Name in frontmatter"
else
    echo "  [FAIL] Name missing from frontmatter"
fi

if grep -q "description:" "$SKILL_FILE"; then
    echo "  [PASS] Description in frontmatter"
else
    echo "  [FAIL] Description missing from frontmatter"
fi

# Test 2: Command file exists
echo -e "\nTest 2: Command file..."

CMD_FILE="$SCRIPT_DIR/../../commands/init.md"
if [ -f "$CMD_FILE" ]; then
    echo "  [PASS] Command file exists"
else
    echo "  [FAIL] Command file missing"
fi

if grep -q "superpowers:init" "$CMD_FILE"; then
    echo "  [PASS] Command invokes skill"
else
    echo "  [FAIL] Command doesn't invoke skill"
fi

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-init-skill.sh
bash tests/claude-code/test-init-skill.sh
```

Expected: FAIL - "Skill file missing"

**Step 3: Write the skill**

```markdown
<!-- skills/init/SKILL.md -->
---
name: init
description: Use when starting a new project - captures requirement, creates folder structure, optionally runs research phase
---

# Project Initialization

## Overview

Start a new project with persistent context. Creates project folder, captures requirement, optionally researches existing solutions.

**Announce at start:** "I'm using the init skill to set up a new project with persistent context."

## Usage

```bash
/init "your idea, requirement, or problem statement"
/init @requirement.md                    # From file
/init --name "my-feature" "description"  # Explicit project name
```

## The Process

### Step 1: Parse Input

1. Extract requirement text (from argument or file)
2. Derive project name:
   - If `--name` provided, use it
   - Otherwise, generate slug from first 3-5 words of requirement
   - Validate: lowercase, hyphens, no special chars

### Step 2: Create Project Structure

Create `docs/plans/<project-name>/` with:
- `requirement.md` - Original requirement text
- `state.md` - Initial state (phase: init)
- `problems.md` - Empty problems log

Report:
```
Created project: <project-name>
Location: docs/plans/<project-name>/

Files:
- requirement.md (your original prompt)
- state.md (tracks progress)
- problems.md (tracks issues)
```

### Step 3: Ask Research Depth

Present options:
```
What depth of research before brainstorming?

1. Light (2-3 min) - Quick GitHub search, top similar projects
2. Medium (5-10 min) - GitHub + web search, brief analysis
3. Thorough (15+ min) - Deep dive, pros/cons matrix, recommendations
4. Skip - No research, go straight to brainstorm
```

### Step 4: Run Research (unless skipped)

**Light:**
- `gh search repos "<keywords>" --limit 5`
- Present: name, stars, description, last updated

**Medium:**
- GitHub search + web search
- Brief analysis of approaches found
- Present findings with recommendation

**Thorough:**
- Multiple search queries
- Read top project READMEs
- Analyze patterns, trade-offs
- Present comprehensive findings with pros/cons matrix

After research:
1. Update `requirement.md` with enriched context
2. Create `research.md` with findings
3. Add checkpoint: "research: <summary>"

### Step 5: Offer Next Step

```
Project initialized. Ready to brainstorm the design?

Use /brainstorm to explore approaches and create a design document.
```

## Key Principles

- **Capture everything** - Original requirement preserved, enriched version separate
- **Research by default** - Ask for depth, don't skip silently
- **Checkpoint early** - State tracked from moment of init

## Integration

**Creates context for:**
- superpowers:brainstorming - Reads requirement.md, research.md
- superpowers:checkpoint - Updates state.md
- superpowers:continue - Finds project, loads context
```

**Step 4: Write the command file**

```markdown
<!-- commands/init.md -->
---
description: "Start a new project with persistent context - captures requirement, creates folder structure, optionally researches solutions"
disable-model-invocation: true
---

Invoke the superpowers:init skill and follow it exactly as presented to you
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-init-skill.sh
```

Expected: All PASS

**Step 6: Commit**

```bash
git add skills/init/SKILL.md commands/init.md tests/claude-code/test-init-skill.sh
git commit -m "feat: add /init skill for project initialization"
```

---

### Task 3: Create /checkpoint Skill

**Files:**
- Create: `skills/checkpoint/SKILL.md`
- Create: `commands/checkpoint.md`

**Step 1: Write the test**

```bash
# tests/claude-code/test-checkpoint-skill.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: checkpoint skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/checkpoint/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/checkpoint.md"

# Test 1: Files exist
echo -e "\nTest 1: File structure..."
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Frontmatter
echo -e "\nTest 2: Frontmatter..."
grep -q "^name: checkpoint$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"
grep -q "description:" "$SKILL_FILE" && echo "  [PASS] Has description" || echo "  [FAIL] No description"

# Test 3: Key content
echo -e "\nTest 3: Key content..."
grep -q "state.md" "$SKILL_FILE" && echo "  [PASS] Mentions state.md" || echo "  [FAIL] Missing state.md reference"
grep -q "\-\-verify" "$SKILL_FILE" && echo "  [PASS] Mentions --verify flag" || echo "  [FAIL] Missing --verify flag"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-checkpoint-skill.sh
bash tests/claude-code/test-checkpoint-skill.sh
```

Expected: FAIL

**Step 3: Write the skill**

```markdown
<!-- skills/checkpoint/SKILL.md -->
---
name: checkpoint
description: Use anytime to save current state - captures phase, decisions, git commits, optionally runs tests
---

# Checkpoint

## Overview

Save current state to project context. Can be called anytime - during brainstorming, after key decisions, mid-implementation.

**Announce at start:** "I'm using the checkpoint skill to save current state."

## Usage

```bash
/checkpoint                                    # Auto-describe from recent activity
/checkpoint "decided X over Y because Z"       # Explicit description
/checkpoint --verify                           # Run tests + capture results
```

## The Process

### Step 1: Find Active Project

1. Look for project context in `docs/plans/*/state.md`
2. If multiple projects: use most recently active
3. If no project found: error - "No active project. Use /init first."

### Step 2: Gather State

1. **Current phase**: Infer from recent activity or state.md
2. **Git commits**: Get commits since last checkpoint
   ```bash
   git log --oneline -5
   ```
3. **Description**: Use provided text or auto-generate from:
   - Recent file changes
   - Git commit messages
   - Current activity

### Step 3: Update state.md

Add checkpoint entry:
```markdown
- [MM-DD HH:MM] <phase>: <description> (<commit-sha>)
```

Update Summary section:
- Phase: current phase
- Last active: now
- Key commits: add new commits

### Step 4: Handle --verify Flag

If `--verify` specified:

1. Detect test command:
   ```bash
   # Check for test scripts
   [ -f package.json ] && npm test
   [ -f Cargo.toml ] && cargo test
   [ -f pytest.ini ] || [ -d tests/ ] && pytest
   ```

2. Run tests, capture output

3. If tests pass:
   - Add to checkpoint: "verified: all tests passing"

4. If tests fail:
   - Log failures to `problems.md`
   - Add to checkpoint: "verified: X failures"
   - Ask: "Tests failing. Want to investigate?"

### Step 5: Handle Decision Capture

If during brainstorm/design phase, prompt:
```
This looks like a key decision. Want to add it to the Decisions section?

Decision name (e.g., "auth-approach"):
```

If yes, add to Decisions section in state.md:
```markdown
### <decision-name>
<description>
Commit: <sha>
```

### Step 6: Confirm

```
Checkpoint saved to <project-name>/state.md

Phase: <phase>
Commits: <list>
Description: <description>
```

## Key Principles

- **Low friction** - Works with no arguments
- **Git-aware** - Automatically captures relevant commits
- **Decision capture** - Prompts for important decisions during design

## Integration

**Updates:**
- state.md - Checkpoints, Summary, optionally Decisions
- problems.md - If --verify finds failures

**Called by:**
- Manual invocation anytime
- Other skills (brainstorming, executing-plans) for auto-checkpoints
```

**Step 4: Write the command file**

```markdown
<!-- commands/checkpoint.md -->
---
description: "Save current state - captures phase, decisions, git commits to project context"
disable-model-invocation: true
---

Invoke the superpowers:checkpoint skill and follow it exactly as presented to you
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-checkpoint-skill.sh
```

**Step 6: Commit**

```bash
git add skills/checkpoint/SKILL.md commands/checkpoint.md tests/claude-code/test-checkpoint-skill.sh
git commit -m "feat: add /checkpoint skill for anytime state capture"
```

---

## Phase 2: Context Resume

### Task 4: Create /continue Skill

**Files:**
- Create: `skills/continue/SKILL.md`
- Create: `commands/continue.md`

**Step 1: Write the test**

```bash
# tests/claude-code/test-continue-skill.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: continue skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/continue/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/continue.md"

# Test 1: Files exist
echo -e "\nTest 1: File structure..."
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Frontmatter
echo -e "\nTest 2: Frontmatter..."
grep -q "^name: continue$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"

# Test 3: Key content - iteration types
echo -e "\nTest 3: Iteration types..."
grep -q "Quick fix" "$SKILL_FILE" && echo "  [PASS] Has Quick fix option" || echo "  [FAIL] Missing Quick fix"
grep -q "Scoped rework" "$SKILL_FILE" && echo "  [PASS] Has Scoped rework option" || echo "  [FAIL] Missing Scoped rework"
grep -q "Full rework" "$SKILL_FILE" && echo "  [PASS] Has Full rework option" || echo "  [FAIL] Missing Full rework"
grep -q "Research" "$SKILL_FILE" && echo "  [PASS] Has Research option" || echo "  [FAIL] Missing Research"

# Test 4: Context loading
echo -e "\nTest 4: Context loading..."
grep -q "state.md" "$SKILL_FILE" && echo "  [PASS] Loads state.md" || echo "  [FAIL] Missing state.md"
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Loads problems.md" || echo "  [FAIL] Missing problems.md"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-continue-skill.sh
bash tests/claude-code/test-continue-skill.sh
```

**Step 3: Write the skill**

```markdown
<!-- skills/continue/SKILL.md -->
---
name: continue
description: Use to resume work on a project with full context loaded - handles iteration after deployment/testing issues
---

# Continue Project

## Overview

Resume work on a project with full context. Loads state, logs new issues, routes to appropriate iteration workflow.

**Announce at start:** "I'm using the continue skill to resume with project context."

## Usage

```bash
/continue                                      # Load context, ask what to do
/continue "Safari auth broken, need logout"    # Log issues + iterate
/continue --from brainstorm "rethink approach" # Force phase
/continue my-other-project                     # Explicit project
/continue --full                               # Load all context sections
```

## The Process

### Step 1: Find Project

1. Check for explicit project name in arguments
2. If not specified, scan `docs/plans/*/state.md`
3. If single project: use it
4. If multiple projects: present list, ask which one
   ```
   Found multiple projects:
   1. jwt-auth (last active: 2024-01-15, phase: execute-plan)
   2. user-dashboard (last active: 2024-01-10, phase: brainstorm)

   Which project? (or specify: /continue jwt-auth)
   ```
5. If no projects: error - "No projects found. Use /init to start one."

### Step 2: Load Context

**Default loading (Summary + Checkpoints + Active problems):**

```markdown
## Project Context: <name>

### Summary
Phase: <current phase>
Status: <status>
Last active: <date>
Key commits: <list>

### Recent Checkpoints
- [date] phase: description
- [date] phase: description
...

### Active Problems
1. <problem-id>: <symptom summary>
2. <problem-id>: <symptom summary>
```

**With --full flag:** Also load Decisions and Implementation sections.

### Step 3: Log New Issues (if provided)

If user provided issue description:

1. Parse issues from description (can be multiple)
2. For each issue:
   - Generate slug ID
   - Add to `problems.md` with Status: Active
3. Add checkpoint: "continue: <issue summary>"

### Step 4: Present Context Summary

```
## Resumed: <project-name>

**Last checkpoint:** "<description>" (<time ago>)
**Phase completed:** <phase>
**Recent commits:** <sha>, <sha>, <sha>

**New issues logged:**
1. <issue-id>: <symptom>

**Active problems:** <count>
```

### Step 5: Ask Iteration Type

```
How do you want to proceed?

1. Quick fix - Small code changes, jump straight to execute
2. Scoped rework - Mini brainstorm → plan → execute for specific issues
3. Full rework - Back to brainstorm with all learnings
4. Research - Investigate solutions before deciding approach

> You can also: "Fix issue-1 with quick fix, issue-2 needs scoped rework"
```

### Step 6: Route to Workflow

**Quick fix:**
1. Create minimal plan with single task
2. Execute immediately (no subagent, direct implementation)
3. Run verification
4. Checkpoint result

**Scoped rework:**
1. Mini brainstorm focused on specific issues
2. Write focused plan (fewer tasks)
3. Execute with normal workflow
4. Checkpoint at completion

**Full rework:**
1. Load all context including Decisions (learn from past)
2. Invoke superpowers:brainstorming with full context
3. Normal workflow: brainstorm → plan → execute

**Research:**
1. Ask research focus/question
2. Run research (GitHub, web, docs)
3. Present findings
4. Ask: "Ready to proceed with an approach?"
5. Route to appropriate workflow

## Hierarchical Context Loading

| Iteration Type | Sections Loaded |
|----------------|-----------------|
| Quick fix | Summary + Active problems |
| Scoped rework | + Checkpoints + Related decisions |
| Full rework | + All decisions + Implementation |
| Research | Summary + Problems + Research.md if exists |

## Key Principles

- **Single entry point** - One command to resume any project
- **Log + act** - New issues logged before iterating
- **Smart routing** - Right workflow for right problem size
- **Context-appropriate** - Load only what's needed

## Integration

**Reads:**
- state.md - Project state
- problems.md - Active issues

**Updates:**
- problems.md - Logs new issues
- state.md - Adds continue checkpoint

**Routes to:**
- Direct execution (quick fix)
- superpowers:brainstorming (scoped/full rework)
- Research workflow
```

**Step 4: Write the command file**

```markdown
<!-- commands/continue.md -->
---
description: "Resume work on a project with full context - loads state, logs issues, routes to iteration workflow"
disable-model-invocation: true
---

Invoke the superpowers:continue skill and follow it exactly as presented to you
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-continue-skill.sh
```

**Step 6: Commit**

```bash
git add skills/continue/SKILL.md commands/continue.md tests/claude-code/test-continue-skill.sh
git commit -m "feat: add /continue skill for context-aware project resume"
```

---

## Phase 3: Verification & Completion

### Task 5: Create /verify Skill

**Files:**
- Create: `skills/verify/SKILL.md`
- Create: `commands/verify.md`

**Step 1: Write the test**

```bash
# tests/claude-code/test-verify-skill.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: verify skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/verify/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/verify.md"

# Test 1: Files exist
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Key content
grep -q "integration test" "$SKILL_FILE" && echo "  [PASS] Mentions integration tests" || echo "  [FAIL] Missing integration test reference"
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Logs to problems.md" || echo "  [FAIL] Missing problems.md reference"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-verify-skill.sh
bash tests/claude-code/test-verify-skill.sh
```

**Step 3: Write the skill**

```markdown
<!-- skills/verify/SKILL.md -->
---
name: verify
description: Use to run tests and capture outcomes - logs failures to problems.md, checkpoints results
---

# Verify

## Overview

Run verification (tests, linting, type checks) and capture outcomes to project context.

**Announce at start:** "I'm using the verify skill to run tests and capture results."

## Usage

```bash
/verify                    # Run tests, capture outcomes
/verify --all              # Run all checks (tests + lint + types)
```

## The Process

### Step 1: Find Active Project

Load project context from `docs/plans/*/state.md`.

### Step 2: Detect Test Commands

Auto-detect based on project files:

```bash
# Priority order
if [ -f "package.json" ]; then
    # Check for test script
    npm test
elif [ -f "Cargo.toml" ]; then
    cargo test
elif [ -f "pyproject.toml" ]; then
    poetry run pytest
elif [ -f "pytest.ini" ] || [ -d "tests" ]; then
    pytest
elif [ -f "go.mod" ]; then
    go test ./...
fi
```

### Step 3: Run Tests

**Prefer integration tests:**
- Look for `tests/integration/` directory
- Run integration tests first if separate
- Then run full suite

Capture:
- Pass/fail count
- Failure messages
- Test duration

### Step 4: Handle Results

**All passing:**
```
Verification complete

Tests: 24 passing, 0 failing
Duration: 12.3s

Checkpoint: "verified: all tests passing"
```

Add checkpoint to state.md.

**Failures found:**

1. Log each failure to `problems.md`:
   ```markdown
   ## test-failure-<test-name>
   **Status:** Active
   **Discovered:** <date>

   ### Symptom
   Test `<test-name>` failing:
   ```
   <error message>
   ```

   ### Investigation
   (pending)
   ```

2. Report:
   ```
   Verification complete

   Tests: 20 passing, 4 failing
   Duration: 15.1s

   Failures logged to problems.md:
   - test-failure-auth-refresh
   - test-failure-token-expiry

   Checkpoint: "verified: 4 failures"

   Want to investigate? Use /continue to iterate.
   ```

### Step 5: Optional --all Flag

If `--all` specified, also run:

```bash
# Linting
npm run lint || eslint .
cargo clippy
ruff check .

# Type checking
npx tsc --noEmit
mypy .
```

Report all results together.

## Key Principles

- **Integration first** - Prefer integration tests over unit tests
- **Capture everything** - All failures logged to problems.md
- **Checkpoint results** - State updated with verification outcome

## Integration

**Updates:**
- state.md - Checkpoint with verification results
- problems.md - Failure entries if tests fail

**Called by:**
- Manual invocation
- /checkpoint --verify
- Auto-verify in executing-plans (after final batch)
```

**Step 4: Write the command file**

```markdown
<!-- commands/verify.md -->
---
description: "Run tests and capture outcomes - logs failures to problems.md, checkpoints results"
disable-model-invocation: true
---

Invoke the superpowers:verify skill and follow it exactly as presented to you
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-verify-skill.sh
```

**Step 6: Commit**

```bash
git add skills/verify/SKILL.md commands/verify.md tests/claude-code/test-verify-skill.sh
git commit -m "feat: add /verify skill for test running and outcome capture"
```

---

### Task 6: Create /complete Skill

**Files:**
- Create: `skills/complete/SKILL.md`
- Create: `commands/complete.md`

**Step 1: Write the test**

```bash
# tests/claude-code/test-complete-skill.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: complete skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/complete/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/complete.md"

[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"
grep -q "^name: complete$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"
grep -q "archive" "$SKILL_FILE" && echo "  [PASS] Mentions archive" || echo "  [FAIL] Missing archive"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-complete-skill.sh
bash tests/claude-code/test-complete-skill.sh
```

**Step 3: Write the skill**

```markdown
<!-- skills/complete/SKILL.md -->
---
name: complete
description: Use when project is done - creates final checkpoint, generates retrospective, optionally archives
---

# Complete Project

## Overview

Mark a project as complete. Creates final checkpoint, generates brief retrospective, optionally archives context.

**Announce at start:** "I'm using the complete skill to finalize this project."

## Usage

```bash
/complete                  # Mark done, offer to archive
/complete --keep-active    # Mark done but keep in active projects
/complete --archive        # Mark done and archive immediately
```

## The Process

### Step 1: Load Project

Find and load project context.

### Step 2: Final Verification

Run `/verify` if not recently verified:
- Check last checkpoint for "verified"
- If not verified in last hour, run verification
- If tests failing, warn before completing

### Step 3: Generate Retrospective

Create brief summary:

```markdown
## Retrospective

**Duration:** <start date> to <end date> (<X days>)
**Iterations:** <count of continue checkpoints>

**What worked:**
- <inferred from smooth checkpoints>

**What didn't:**
- <inferred from problems.md>

**Key decisions:**
- <list from Decisions section>

**Final state:**
- Tests: <passing/failing>
- Problems resolved: <count>
- Problems remaining: <count>
```

### Step 4: Update State

1. Update state.md:
   - Phase: complete
   - Status: Done
   - Add final checkpoint

2. Update problems.md:
   - Move resolved problems to "Resolved" section
   - Keep active problems visible with note

### Step 5: Archive (if requested)

If `--archive` or user confirms:

1. Create archive directory:
   ```bash
   mkdir -p docs/plans/archive/
   ```

2. Move project folder:
   ```bash
   mv docs/plans/<project>/ docs/plans/archive/<project>/
   ```

3. Report:
   ```
   Project archived to docs/plans/archive/<project>/

   To restore: mv docs/plans/archive/<project> docs/plans/
   ```

### Step 6: Confirm Completion

```
Project complete: <name>

Duration: <X days>
Commits: <count>
Problems resolved: <count>

Retrospective saved to state.md.
<Archived to docs/plans/archive/ | Kept in active projects>

Great work!
```

## Key Principles

- **Verify before complete** - Don't mark done with failing tests
- **Learn from problems** - Retrospective captures learnings
- **Archive optional** - Some projects worth keeping visible

## Integration

**Reads:**
- state.md - Full project history
- problems.md - All problems for retrospective

**Updates:**
- state.md - Final checkpoint, retrospective
- problems.md - Resolve status updates

**Optionally:**
- Moves to archive/
```

**Step 4: Write the command file**

```markdown
<!-- commands/complete.md -->
---
description: "Mark project complete - creates final checkpoint, generates retrospective, optionally archives"
disable-model-invocation: true
---

Invoke the superpowers:complete skill and follow it exactly as presented to you
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-complete-skill.sh
```

**Step 6: Commit**

```bash
git add skills/complete/SKILL.md commands/complete.md tests/claude-code/test-complete-skill.sh
git commit -m "feat: add /complete skill for project completion and archival"
```

---

## Phase 4: Enhance Existing Skills

### Task 7: Enhance brainstorming Skill

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Step 1: Review current content**

Read existing skill to understand structure.

**Step 2: Write test for enhancements**

```bash
# tests/claude-code/test-brainstorming-enhanced.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: brainstorming enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/brainstorming/SKILL.md"

# Test: Project context integration
grep -q "requirement.md" "$SKILL_FILE" && echo "  [PASS] Checks for requirement.md" || echo "  [FAIL] Missing requirement.md check"
grep -q "research.md" "$SKILL_FILE" && echo "  [PASS] Checks for research.md" || echo "  [FAIL] Missing research.md check"
grep -q "checkpoint" "$SKILL_FILE" && echo "  [PASS] Mentions checkpoint" || echo "  [FAIL] Missing checkpoint integration"

echo -e "\n=== Tests complete ==="
```

**Step 3: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-brainstorming-enhanced.sh
bash tests/claude-code/test-brainstorming-enhanced.sh
```

**Step 4: Update the skill**

Add new section after "## Overview":

```markdown
## Project Context Integration

**Before starting, check for existing project context:**

1. Look for `docs/plans/*/requirement.md` in current directory
2. If found, load:
   - `requirement.md` - Original/enriched requirement
   - `research.md` - Prior research findings (if exists)
   - `state.md` - Current phase, prior decisions

3. If project context exists:
   ```
   Found project context: <name>

   Requirement: <first 100 chars>...
   Research: <summary if exists>
   Phase: <current phase>

   Continuing brainstorm with this context.
   ```

4. If no context: proceed normally (standalone brainstorm)

**After design complete:**

1. If project context exists:
   - Save design to `docs/plans/<project>/design.md`
   - Add checkpoint: "brainstorm: design complete"

2. If no project context:
   - Save to `docs/plans/YYYY-MM-DD-<topic>-design.md` (existing behavior)
```

Add to "## Key Principles":

```markdown
- **Context-aware** - Load existing project context if available
- **Checkpoint decisions** - Offer to checkpoint key design decisions
```

**Step 5: Run test to verify it passes**

```bash
bash tests/claude-code/test-brainstorming-enhanced.sh
```

**Step 6: Commit**

```bash
git add skills/brainstorming/SKILL.md tests/claude-code/test-brainstorming-enhanced.sh
git commit -m "feat: enhance brainstorming with project context integration"
```

---

### Task 8: Enhance executing-plans Skill

**Files:**
- Modify: `skills/executing-plans/SKILL.md`

**Step 1: Write test for enhancements**

```bash
# tests/claude-code/test-executing-plans-enhanced.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: executing-plans enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/executing-plans/SKILL.md"

# Test: Auto-checkpoint
grep -q "auto-checkpoint" "$SKILL_FILE" && echo "  [PASS] Has auto-checkpoint" || echo "  [FAIL] Missing auto-checkpoint"

# Test: Problem logging
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Logs to problems.md" || echo "  [FAIL] Missing problems.md logging"

# Test: Auto-verify
grep -q "auto-verify" "$SKILL_FILE" && echo "  [PASS] Has auto-verify" || echo "  [FAIL] Missing auto-verify"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify it fails**

```bash
chmod +x tests/claude-code/test-executing-plans-enhanced.sh
bash tests/claude-code/test-executing-plans-enhanced.sh
```

**Step 3: Update the skill**

Add new section after "## The Process":

```markdown
## Project Context Integration

**If project context exists (`docs/plans/<project>/state.md`):**

### Auto-Checkpoint Per Batch

After completing each batch of tasks:
1. Get recent git commits
2. Add checkpoint: "execute: tasks N-M complete"
3. Update Implementation section with files changed

### Auto-Log Problems

When errors occur during execution:
1. Log to `problems.md`:
   ```markdown
   ## execution-error-<task-number>
   **Status:** Active
   **Discovered:** <now>
   **Task:** <task name>

   ### Symptom
   <error message>

   ### Investigation
   (pending)
   ```
2. Continue or stop based on severity

### Auto-Verify at End

After final task batch:
1. Run full test suite
2. If all pass: checkpoint "execute: complete, verified"
3. If failures:
   - Log failures to `problems.md`
   - Checkpoint "execute: complete, X test failures"
   - Ask: "Tests failing. Want to continue to iterate?"
```

Update "## Remember" section to include:
```markdown
- Auto-checkpoint after each batch (if project context exists)
- Log errors to problems.md
- Run verification after final batch
```

**Step 4: Run test to verify it passes**

```bash
bash tests/claude-code/test-executing-plans-enhanced.sh
```

**Step 5: Commit**

```bash
git add skills/executing-plans/SKILL.md tests/claude-code/test-executing-plans-enhanced.sh
git commit -m "feat: enhance executing-plans with auto-checkpoint and problem logging"
```

---

### Task 9: Enhance test-driven-development Skill

**Files:**
- Modify: `skills/test-driven-development/SKILL.md`

**Step 1: Write test for enhancements**

```bash
# tests/claude-code/test-tdd-enhanced.sh
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: TDD enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/test-driven-development/SKILL.md"

# Test: Integration test preference
grep -qi "integration test" "$SKILL_FILE" && echo "  [PASS] Mentions integration tests" || echo "  [FAIL] Missing integration test mention"
grep -qi "prefer.*integration" "$SKILL_FILE" && echo "  [PASS] Prefers integration tests" || echo "  [FAIL] Missing integration preference"
grep -qi "minimal.*mock" "$SKILL_FILE" && echo "  [PASS] Mentions minimal mocking" || echo "  [FAIL] Missing minimal mocking"

echo -e "\n=== Tests complete ==="
```

**Step 2: Run test to verify current state**

```bash
chmod +x tests/claude-code/test-tdd-enhanced.sh
bash tests/claude-code/test-tdd-enhanced.sh
```

Note: Some may already pass since TDD skill mentions mocking. Check which enhancements needed.

**Step 3: Update the skill**

Add new section after "## When to Use":

```markdown
## Testing Preference Hierarchy

**Prefer integration tests:**
1. Integration tests - Test real behavior with real dependencies
2. Unit tests - Only for pure functions, complex algorithms, edge cases

**Why integration tests first:**
- Catch real bugs (not mock behavior)
- Verify components work together
- More confidence in actual system behavior
- Fewer false positives from incorrect mocks

**When to write unit tests:**
- Pure functions with no side effects
- Complex algorithms needing edge case coverage
- Performance-critical code paths
- When integration test would be impractically slow

**Minimize mocking:**
- Mock only external services you don't control
- Never mock your own code unless absolutely necessary
- If you need many mocks, design is too coupled
```

Update the "Good/Bad" example to show integration test preference:

```markdown
<Good>
```typescript
// Integration test - tests real behavior
test('user can complete checkout flow', async () => {
  const user = await createTestUser(db);
  const cart = await addToCart(db, user.id, productId);

  const result = await checkout(cart.id);

  expect(result.orderId).toBeDefined();
  expect(await getOrderStatus(result.orderId)).toBe('confirmed');
});
```
Real database, real checkout, tests actual flow
</Good>

<Bad>
```typescript
// Over-mocked unit test
test('checkout calls payment service', async () => {
  const mockPayment = jest.fn().mockResolvedValue({ success: true });
  const mockInventory = jest.fn().mockResolvedValue(true);
  const mockEmail = jest.fn();

  await checkout(mockPayment, mockInventory, mockEmail);

  expect(mockPayment).toHaveBeenCalled();
});
```
Tests mock behavior, not real behavior
</Bad>
```

**Step 4: Run test to verify it passes**

```bash
bash tests/claude-code/test-tdd-enhanced.sh
```

**Step 5: Commit**

```bash
git add skills/test-driven-development/SKILL.md tests/claude-code/test-tdd-enhanced.sh
git commit -m "feat: enhance TDD skill with integration test preference"
```

---

## Phase 5: Integration Test

### Task 10: Create Integration Test for Full Workflow

**Files:**
- Create: `tests/claude-code/test-persistent-context-integration.sh`

**Step 1: Write the integration test**

```bash
#!/bin/bash
# Integration test for persistent development context workflow
# This test simulates the full workflow: init → brainstorm → plan → execute → continue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Integration Test: Persistent Development Context ==="

# Test 1: All skills exist
echo -e "\nTest 1: All skills present..."
SKILLS="init checkpoint continue verify complete"
for skill in $SKILLS; do
    SKILL_FILE="$SCRIPT_DIR/../../skills/$skill/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
        echo "  [PASS] $skill skill exists"
    else
        echo "  [FAIL] $skill skill missing"
    fi
done

# Test 2: All commands exist
echo -e "\nTest 2: All commands present..."
COMMANDS="init checkpoint continue verify complete"
for cmd in $COMMANDS; do
    CMD_FILE="$SCRIPT_DIR/../../commands/$cmd.md"
    if [ -f "$CMD_FILE" ]; then
        echo "  [PASS] $cmd command exists"
    else
        echo "  [FAIL] $cmd command missing"
    fi
done

# Test 3: Project context library
echo -e "\nTest 3: Project context library..."
LIB_FILE="$SCRIPT_DIR/../../lib/project-context.js"
if [ -f "$LIB_FILE" ]; then
    echo "  [PASS] project-context.js exists"
else
    echo "  [FAIL] project-context.js missing"
fi

# Test 4: Enhanced skills have context integration
echo -e "\nTest 4: Skill enhancements..."
BRAINSTORM="$SCRIPT_DIR/../../skills/brainstorming/SKILL.md"
EXECUTE="$SCRIPT_DIR/../../skills/executing-plans/SKILL.md"
TDD="$SCRIPT_DIR/../../skills/test-driven-development/SKILL.md"

grep -q "requirement.md" "$BRAINSTORM" && echo "  [PASS] brainstorming: context integration" || echo "  [FAIL] brainstorming: missing context"
grep -q "auto-checkpoint" "$EXECUTE" && echo "  [PASS] executing-plans: auto-checkpoint" || echo "  [FAIL] executing-plans: missing auto-checkpoint"
grep -qi "integration test" "$TDD" && echo "  [PASS] TDD: integration preference" || echo "  [FAIL] TDD: missing integration preference"

echo -e "\n=== Integration Test Complete ==="
```

**Step 2: Run the integration test**

```bash
chmod +x tests/claude-code/test-persistent-context-integration.sh
bash tests/claude-code/test-persistent-context-integration.sh
```

**Step 3: Commit**

```bash
git add tests/claude-code/test-persistent-context-integration.sh
git commit -m "test: add integration test for persistent development context"
```

---

### Task 11: Update Test Runner

**Files:**
- Modify: `tests/claude-code/run-skill-tests.sh`

**Step 1: Check current test runner**

Read the file to understand how to add new tests.

**Step 2: Add new tests to runner**

Add the new test files to the test runner's list of tests to execute.

**Step 3: Run full test suite**

```bash
bash tests/claude-code/run-skill-tests.sh
```

**Step 4: Commit**

```bash
git add tests/claude-code/run-skill-tests.sh
git commit -m "test: add persistent context tests to test runner"
```

---

### Task 12: Final Documentation

**Files:**
- Update: `README.md` or create `docs/persistent-context.md`

**Step 1: Document the new workflow**

Create user-facing documentation explaining:
- New commands: /init, /checkpoint, /continue, /verify, /complete
- Project folder structure
- How to use the iterative workflow
- Examples

**Step 2: Commit documentation**

```bash
git add <doc-file>
git commit -m "docs: add persistent development context documentation"
```

---

## Summary

**Total Tasks:** 12

**New Files Created:**
- `lib/project-context.js` - State management library
- `skills/init/SKILL.md` - Project initialization
- `skills/checkpoint/SKILL.md` - State capture
- `skills/continue/SKILL.md` - Context resume
- `skills/verify/SKILL.md` - Test runner
- `skills/complete/SKILL.md` - Project completion
- `commands/init.md`, `checkpoint.md`, `continue.md`, `verify.md`, `complete.md`
- Test files for each component

**Files Modified:**
- `skills/brainstorming/SKILL.md` - Context integration
- `skills/executing-plans/SKILL.md` - Auto-checkpoint, problem logging
- `skills/test-driven-development/SKILL.md` - Integration test preference
- `tests/claude-code/run-skill-tests.sh` - Include new tests

---

Plan complete and saved to `docs/plans/2026-02-04-persistent-development-context-implementation.md`.

**Two execution options:**

1. **Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

2. **Parallel Session (separate)** - Open new session in worktree with executing-plans, batch execution with checkpoints

Which approach?
