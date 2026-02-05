---
name: checkpointing
description: Use anytime to save current state - captures phase, decisions, git commits, optionally runs tests
---

# Save Checkpoint

## Overview

Save current state to project context. This skill is callable anytime during development - during brainstorming, after key decisions, mid-implementation, or after completing a milestone. It captures context that persists across sessions.

## Usage

```
/checkpoint
/checkpoint "description of what was accomplished"
/checkpoint --verify
```

- **No arguments**: Save checkpoint with auto-generated description from git
- **Description**: Save checkpoint with custom description
- **`--verify`**: Run tests before saving, log any failures to problems.md

## Process

### Step 1: Find Active Project

Look for active project by finding `docs/plans/*/state.md`:

```javascript
const pc = require('./lib/project-context.js');
const projects = pc.findProjects('.');
```

If no project found:
> "No active project found. Run `/init` to start a new project."

If multiple projects found, ask user to select:
> "Multiple projects found. Which one are you working on?"
> 1. project-a
> 2. project-b

### Step 2: Gather State

Collect information for the checkpoint:

1. **Current phase**: Determine from context (brainstorming, planning, implementation, testing, review)
2. **Git state**: Run `git log -1 --oneline` to get recent commit
3. **Description**: Use provided description or generate from git commit message

### Step 3: Update state.md

Add checkpoint entry using the library:

```javascript
pc.addCheckpoint(projectDir, phase, description);
```

This adds an entry like:
```
- **[2024-01-15]** `implementation`: Added authentication middleware
```

### Step 4: Handle --verify Flag

If `--verify` was passed:

1. Look for test command in project (npm test, pytest, etc.)
2. Run the tests
3. If tests pass, include in checkpoint: "All tests passing"
4. If tests fail:
   - Log failures to problems.md:
   ```javascript
   pc.addProblem(projectDir, {
       title: 'Test failures during checkpoint',
       description: 'The following tests failed:\n' + failureOutput,
       severity: 'high',
       status: 'open'
   });
   ```
   - Include in checkpoint: "Tests failing - see problems.md"

### Step 5: Handle Decision Capture

During brainstorming phase, offer to capture decisions:

> "Would you like to record any key decisions made?"
>
> Examples:
> - "Using React over Vue for better ecosystem"
> - "Chose PostgreSQL for relational data needs"

If yes, append to Decisions section in state.md:

```javascript
const state = pc.loadState(projectDir);
let decisions = state.decisions || '';
decisions += `\n- ${decision}`;
pc.saveState(projectDir, { decisions });
```

### Step 6: Confirm

Show what was saved:

> **Checkpoint saved**
>
> - **Phase:** implementation
> - **Description:** Added authentication middleware
> - **Git:** abc123 - Add auth middleware
> - **Tests:** All passing

## Key Principles

- **Low friction** - One command captures state, minimal prompts
- **Git-aware** - Automatically pulls context from git history
- **Decision capture** - Important for brainstorming sessions
- **Test integration** - Optional verification ensures quality checkpoints

## Integration Notes

- **Depends on**: `/init` (must have project created first)
- **Used by**: `/continue` (reads checkpoints to restore context)
- **State file**: Updates `state.md` in project folder
- **Problems file**: May add entries when `--verify` finds test failures
