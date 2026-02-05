---
name: initializing-project
description: Use when starting a new project - captures requirement, creates folder structure, optionally runs research phase
---

# Initialize New Project

## Overview

Set up persistent context for a new project. Create the folder structure, capture the requirement, and optionally research before brainstorming.

**Announce at start:** "I'm using the init skill to set up this project with persistent context."

**Do NOT skip steps. Do NOT jump to implementation. Do NOT write code or deliverables.** This skill ONLY sets up the project structure and routes to brainstorming. Thinking "I can just do the task directly"? Stop. That's rationalization.

## The Process

### Step 1: Parse the requirement

Extract the requirement from user input:
- **Quoted string**: Use as the requirement
- **File reference** (`@file.md`): Read the file as the requirement
- **`--name` flag**: Use as the project name

If no input provided, ask: "What would you like to build?"

**Wait for the user's response before continuing.**

### Step 2: Confirm project name

If `--name` was not provided, derive a kebab-case name from the requirement (e.g., "dotfiles-manager", "api-gateway").

Ask the user: "I'll call this project `<name>`. Sound good?"

**Wait for confirmation before creating anything.**

### Step 3: Create the project folder

Create the following structure. Use `mkdir -p` and write the files directly:

```
docs/plans/<project-name>/
  requirement.md    # The user's requirement text, exactly as provided
  state.md          # Initial state file (template below)
  problems.md       # Empty problems file (template below)
```

**requirement.md** — Write the user's requirement exactly as provided.

**state.md** — Write this template:
```markdown
# <Project Name>

## Summary
- **Phase:** initialized
- **Status:** Active
- **Started:** <today's date>

## Checkpoints
- **[<today's date>]** `initialized`: Project created

## Decisions
(none yet)

## Implementation
(not started)
```

**problems.md** — Write this template:
```markdown
# Problems

## Active
(none)

## Resolved
(none)
```

### Step 4: Ask research depth

Present these options. **You must wait for the user to choose before proceeding:**

"Before we brainstorm, would you like me to research existing solutions?"

1. **Light** — Quick search for similar projects (2-3 min)
2. **Medium** — Search for patterns, approaches, and useful libraries (5 min)
3. **Thorough** — Deep dive into docs, tutorials, best practices (10+ min)
4. **Skip** — Jump straight to brainstorming

### Step 5: Run research (if not skipped)

Based on the user's choice:

**Light:** Search GitHub for similar projects. Note 2-3 relevant repos with brief descriptions.

**Medium:** All of Light, plus web search for common patterns and useful libraries.

**Thorough:** All of Medium, plus read documentation, search for tutorials, identify pitfalls.

Save findings to `docs/plans/<project>/research.md`.

Add a checkpoint to state.md:
```
- **[<date>]** `research`: <depth> research complete
```

### Step 6: Route to brainstorming

Say exactly:

"Project initialized! Run `/superpowers:brainstorm` to explore approaches and create a design."

**Stop here. Do NOT proceed to implementation. Do NOT write code. Do NOT create deliverables.** The next step is always brainstorming.

## Key Principles

- **Capture intent clearly** — The requirement should be specific enough to guide brainstorming
- **Research is optional** — Don't force it if user wants to skip
- **One question at a time** — Don't overwhelm with multiple prompts
- **Confirm before creating** — Verify project name before creating folders
- **NEVER skip to implementation** — This skill creates structure, brainstorming creates the design
