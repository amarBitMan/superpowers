---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

## Project Context Integration

**Before starting, check for existing project context:**

1. Look for `docs/plans/*/state.md` in current directory
2. If found, load:
   - `requirement.md` — Original requirement
   - `design.md` — Design from brainstorming (if exists)
   - `state.md` — Current phase and decisions
3. Use this context to inform the plan
4. **Save plan to:** `docs/plans/<project>/plan.md`
5. After saving, add checkpoint to state.md: `- **[<date>]** \`plan\`: implementation plan complete`
6. Update Phase to `planning`

**If no project context:** Save plans to `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Skill-Aware Planning

**Before writing the plan, scan available skills** (listed in system prompt). If relevant skills exist for the work, embed them as `REQUIRED SUB-SKILL` markers in the appropriate plan steps.

Common mappings:
- Test writing steps → `superpowers:test-driven-development`
- Bug investigation steps → `superpowers:systematic-debugging`
- Final verification steps → `superpowers:verification-before-completion`
- Code review steps → `superpowers:requesting-code-review`

Example of a skill-aware step:
```markdown
**Step 1: Write the failing test**
> **REQUIRED SUB-SKILL:** Use superpowers:test-driven-development
```

The executing agent will invoke these skills when it reaches those steps. Only reference skills that are actually available — do not invent skill names.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
```

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Embed `REQUIRED SUB-SKILL` markers for available skills in relevant steps
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
