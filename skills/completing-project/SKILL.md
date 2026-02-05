---
name: completing-project
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
