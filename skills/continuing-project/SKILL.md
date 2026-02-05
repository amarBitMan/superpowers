---
name: continuing-project
description: Use to resume work on a project with full context loaded - handles iteration after deployment/testing issues
---

# Continue Work on Project

## Overview

Resume work on a project with full context loaded. This skill is the single entry point for returning to a project - it loads relevant context, logs any new issues discovered during deployment or testing, and routes to the appropriate iteration workflow.

## Usage

```
/continue
/continue "login page returns 500 error after deploy"
/continue --from brainstorm
/continue project-name
/continue --full
```

- **No arguments**: Resume with default context (summary + checkpoints + active problems)
- **Quoted string**: Log new issue to problems.md, then route to iteration workflow
- **`--from` flag**: Resume from specific phase (brainstorm, plan, implement, test)
- **Project name**: Explicitly specify which project to continue
- **`--full`**: Load complete context including all implementation details

## Process

### Step 1: Find Project

Locate the active project:

```javascript
const pc = require('./lib/project-context.js');
const projects = pc.findProjects('.');
```

**Project selection logic:**
- **Single project**: Auto-select it
- **Multiple projects**: Prompt user to select
- **Explicit name provided**: Use that project directly
- **No projects found**: Suggest running `/init`

### Step 2: Load Context

Load project context based on flags:

| Flag | Sections Loaded |
|------|-----------------|
| (default) | Summary + Checkpoints + Active problems |
| `--from brainstorm` | Summary + Decisions |
| `--from plan` | Summary + Checkpoints + Implementation outline |
| `--from implement` | Summary + Checkpoints + Implementation + Testing |
| `--from test` | Summary + Checkpoints + Testing + Active problems |
| `--full` | All sections from state.md + all problems.md |

```javascript
// Default context loading
const state = pc.loadState(projectDir, {
    sections: ['summary', 'checkpoints']
});
const problems = pc.loadProblems(projectDir, { status: 'open' });
```

### Step 3: Log New Issues (if provided)

If user provided issues in quotes:

```javascript
pc.addProblem(projectDir, {
    title: 'Issue from deployment/testing',
    description: userProvidedIssue,
    severity: 'high',
    status: 'open'
});
```

### Step 4: Present Context Summary

Display loaded context to user:

> **Project: `<project-name>`**
>
> **Summary:** <brief summary>
>
> **Recent Checkpoints:**
> - [date] phase: description
> - [date] phase: description
>
> **Active Problems:** <count>
> - Problem 1 (severity)
> - Problem 2 (severity)

### Step 5: Ask Iteration Type

Present iteration options:

> "What kind of iteration is needed?"
>
> 1. **Quick fix** - Minor bug fix or small tweak (< 30 min)
> 2. **Scoped rework** - Focused changes to specific component (1-2 hours)
> 3. **Full rework** - Significant changes across multiple files (half day+)
> 4. **Research** - Need to investigate before deciding approach

### Step 6: Route to Workflow

Based on selection:

**Quick fix:**
- Jump straight to implementation
- Make the fix
- Run tests
- Offer `/checkpoint` when done

**Scoped rework:**
- Clarify scope with 1-2 questions
- Create mini-plan (bullet points, not full doc)
- Implement changes
- Run tests
- Offer `/checkpoint` when done

**Full rework:**
- Route to `/brainstorm` for design discussion
- Then `/write-plan` for detailed plan
- Then implementation

**Research:**
- Ask what needs investigation
- Perform research (web search, code exploration, documentation)
- Present findings
- Return to iteration type selection

## Hierarchical Context Loading

Context is loaded hierarchically to manage token usage:

| Level | Content | Use Case |
|-------|---------|----------|
| **Minimal** | Summary only | Quick status check |
| **Default** | Summary + Checkpoints + Active problems | Most iterations |
| **Phase-specific** | Default + phase-relevant sections | Resuming specific work |
| **Full** | Everything | Deep debugging, major rework |

## Key Principles

- **Single entry point** - All resumption flows through `/continue`
- **Log + act** - Always capture issues before working on them
- **Smart routing** - Match iteration type to appropriate workflow depth
- **Context-appropriate** - Load only what's needed to minimize noise

## Integration Notes

- **Depends on**: `/init` (must have project created first)
- **Routes to**: `/brainstorm` (for full rework), implementation (for quick fix/scoped)
- **Uses**: `state.md` for context, `problems.md` for issue tracking
- **Paired with**: `/checkpoint` (save state after iteration complete)
