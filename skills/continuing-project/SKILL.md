---
name: continuing-project
description: Use to resume work on a project with full context loaded - handles iteration after deployment/testing issues
---

# Continue Work on Project

## Overview

Resume work on a project. Load context, log new issues, route to the right workflow.

**Announce at start:** "I'm using the continue skill to load project context and resume work."

**This is the single entry point for returning to a project.** Do not freelance. Follow the steps. Present context to the user. Ask what kind of iteration they need. Route accordingly.

## The Process

### Step 1: Find the project

Look for `docs/plans/*/state.md` in the current directory.

- **No projects found:** Say "No active project found. Run `/superpowers:init` to start one." and stop.
- **Multiple projects:** Ask the user which one. Wait for their answer.
- **Single project:** Use it.
- **Explicit name in arguments:** Use that project directly.

### Step 2: Load context

Read the project files and load context based on flags:

| Flag | What to read |
|------|-------------|
| (default) | state.md Summary + Checkpoints + problems.md Active section |
| `--from brainstorm` | state.md Summary + Decisions |
| `--from plan` | state.md Summary + Checkpoints + Implementation |
| `--from implement` | state.md Summary + Checkpoints + Implementation |
| `--from test` | state.md Summary + Checkpoints + problems.md Active |
| `--full` | Everything in state.md + all of problems.md |

### Step 3: Log new issues (if provided)

If the user provided a description in quotes (e.g., `/continue "login returns 500"`):

Append to `problems.md` under `## Active`:
```markdown
### <brief title derived from description>
**Status:** Active
**Discovered:** <today's date>
**Symptom:** <user's description>
**Investigation:** (pending)
```

### Step 4: Present context to the user

Display what you loaded. **You must show this before doing anything else:**

```
Project: <project-name>

Phase: <current phase>
Status: <active/complete>
Last checkpoint: <date> — <description>

Active problems: <count>
- <problem 1>
- <problem 2>
```

### Step 5: Ask the iteration type

**You must ask this question and wait for the user to answer. Do NOT assume.**

"What kind of iteration is needed?"

1. **Quick fix** — Minor bug fix or small tweak
2. **Scoped rework** — Focused changes to a specific component
3. **Full rework** — Significant changes, needs re-design
4. **Research** — Need to investigate before deciding

### Step 6: Route to the right workflow

Based on the user's selection:

**Quick fix:**
- Make the fix directly
- Run tests
- Run `/superpowers:verify` to confirm the fix
- Offer `/superpowers:checkpoint` when done

**Scoped rework:**
- Ask 1-2 clarifying questions about scope
- Create a mini-plan (bullet points, not a full doc)
- Implement changes
- Run `/superpowers:verify` to confirm changes
- Offer `/superpowers:checkpoint` when done

**Full rework:**
- Route to `/superpowers:brainstorm` — this will chain through write-plan → execute-plan automatically

**Research:**
- Ask what needs investigation
- Perform research (web search, code exploration, docs)
- Present findings
- Return to iteration type selection

## Key Principles

- **Always show context first** — The user needs to see where things stand
- **Always ask iteration type** — Don't assume the scope of work needed
- **Log before fixing** — Capture issues to problems.md before working on them
- **Route, don't improvise** — Match iteration type to the right workflow depth
