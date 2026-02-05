---
name: checkpointing
description: Use anytime to save current state - captures phase, decisions, git commits, optionally runs tests
---

# Save Checkpoint

## Overview

Capture current progress to project context. Low friction, one command, minimal prompts.

**Announce at start:** "I'm using the checkpoint skill to save current state."

## The Process

### Step 1: Find the active project

Look for `docs/plans/*/state.md` in the current directory.

- **No project found:** Say "No active project found. Run `/superpowers:init` to start one." and stop.
- **Multiple projects:** Ask the user which one. Wait for their answer.
- **Single project:** Use it.

### Step 2: Gather state

Collect this information:

1. **Current phase** — Determine from recent activity: brainstorming, planning, implementation, testing, or review
2. **Recent git commit** — Run `git log -1 --oneline` to get the latest commit
3. **Description** — Use the user-provided description (from `$ARGUMENTS`), or generate one from the git commit message

### Step 3: Append checkpoint to state.md

Read the current `state.md`. Add a new entry under the `## Checkpoints` section:

```
- **[<today's date>]** `<phase>`: <description>
```

Update the Summary section's Phase field if it changed.

### Step 4: Run tests (if --verify flag)

If the user passed `--verify`:

1. Detect the test command (look for package.json, Cargo.toml, pyproject.toml, go.mod)
2. Run the tests
3. If all pass: add to checkpoint description "— all tests passing"
4. If failures: append each failure to `problems.md` under `## Active`:
   ```markdown
   ### <test-name> failure
   **Status:** Active
   **Discovered:** <date>
   **Symptom:** <error message>
   **Investigation:** (pending)
   ```

### Step 5: Offer decision capture

If the current phase is brainstorming or planning, ask:

"Any key decisions to record? (e.g., 'Chose PostgreSQL for relational data needs')"

If yes, append to the `## Decisions` section in state.md.

**If the phase is implementation or later, skip this step.**

### Step 6: Confirm what was saved

Display a summary:

```
Checkpoint saved

- Phase: <phase>
- Description: <description>
- Git: <commit hash> - <commit message>
- Tests: <passing/failing/not run>
```

## Key Principles

- **Low friction** — One command, minimal prompts, fast
- **Git-aware** — Automatically pulls context from git history
- **Always append** — Never overwrite existing checkpoints
