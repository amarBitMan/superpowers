---
name: completing-project
description: Use when project is done - creates final checkpoint, generates retrospective, optionally archives
---

# Complete Project

## Overview

Mark a project as complete. Verify tests, generate retrospective, optionally archive.

**Announce at start:** "I'm using the complete skill to finalize this project."

**Do not mark a project complete with failing tests.** Run verification first.

## The Process

### Step 1: Find and load the project

Look for `docs/plans/*/state.md`. Read state.md and problems.md fully.

If no project found, say "No active project found." and stop.

### Step 2: Run final verification

Check the last checkpoint in state.md for a recent "verified" entry.

- If verified within the last hour: skip re-verification
- If not recently verified: run `/superpowers:verify` now
- If tests are failing: warn the user — "Tests are failing. Complete anyway?" Wait for confirmation.

### Step 3: Generate retrospective

Read through the full state.md and problems.md. Write a retrospective and append it to state.md:

```markdown
## Retrospective

**Duration:** <start date> to <today> (<X days>)
**Checkpoints:** <count>

**What worked:**
- <inferred from smooth progress between checkpoints>

**What didn't:**
- <inferred from problems.md entries>

**Key decisions:**
- <list from Decisions section>

**Final state:**
- Tests: <passing/failing>
- Problems resolved: <count>
- Problems remaining: <count>
```

### Step 4: Update state

Update state.md:
- Change Phase to `complete`
- Change Status to `Done`
- Add final checkpoint: `- **[<date>]** \`complete\`: Project finalized`

### Step 5: Ask about archiving

Ask the user:

"Archive this project to `docs/plans/archive/`?"

1. **Yes** — Move the project folder to `docs/plans/archive/<project>/`
2. **No** — Keep it in `docs/plans/` as-is

If `--archive` flag was passed, archive without asking.
If `--keep-active` flag was passed, skip this step.

### Step 6: Confirm completion

```
Project complete: <name>

Duration: <X days>
Checkpoints: <count>
Problems resolved: <count>

Retrospective saved to state.md.
<Archived to docs/plans/archive/ | Kept in active projects>
```

## Key Principles

- **Verify before completing** — Don't mark done with failing tests
- **Capture learnings** — The retrospective is for future reference
- **Ask about archiving** — Don't auto-archive unless flagged
