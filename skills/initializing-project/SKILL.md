---
name: initializing-project
description: Use when starting a new project - captures requirement, creates folder structure, optionally runs research phase
---

# Initialize New Project

## Overview

Start a new project with persistent context. This skill captures the requirement, creates the project folder structure, and optionally runs a research phase to gather relevant information.

## Usage

```
/init "Build a CLI tool for managing dotfiles"
/init @requirements.md
/init --name "dotfiles-manager" "A CLI tool for managing dotfiles across machines"
```

## Process

### Step 1: Parse Input

Extract the requirement from the user's input:
- **Quoted string**: Use as the requirement description
- **File reference** (`@file.md`): Read the file contents as the requirement
- **`--name` flag**: Use as the project name (otherwise derive from requirement)

If no input provided, ask the user: "What would you like to build?"

### Step 2: Derive Project Name

If `--name` was not provided:
- Extract key concepts from the requirement
- Generate a kebab-case project name (e.g., "dotfiles-manager", "api-gateway")
- Confirm with user: "I'll call this project `<name>`. Sound good?"

### Step 3: Create Project Structure

Use the `lib/project-context.js` library to create the project:

```javascript
const pc = require('./lib/project-context.js');
const result = pc.createProject('docs/plans', projectName, requirement);
```

This creates:
```
docs/plans/<project-name>/
  requirement.md    # The original requirement
  state.md          # Current state (summary, implementation, checkpoints)
  problems.md       # Known issues and blockers
```

### Step 4: Ask Research Depth

Present research options:

> "Before we brainstorm, would you like me to research existing solutions?"
>
> 1. **Light** - Quick GitHub search for similar projects (2-3 min)
> 2. **Medium** - GitHub + web search for patterns and approaches (5 min)
> 3. **Thorough** - Deep dive into documentation, tutorials, best practices (10+ min)
> 4. **Skip** - Jump straight to brainstorming

### Step 5: Run Research (if not skipped)

Based on selected depth:

**Light:**
- Search GitHub for similar projects
- Note 2-3 relevant repositories with brief descriptions

**Medium:**
- All of Light, plus:
- Web search for common patterns/approaches
- Note any useful libraries or frameworks

**Thorough:**
- All of Medium, plus:
- Read documentation for key technologies
- Search for tutorials or guides
- Identify potential pitfalls or gotchas

Save research findings to `state.md`:
```javascript
pc.saveState(projectDir, {
  summary: `Project: ${projectName}`,
  implementation: `## Research Findings\n\n${findings}`
});
```

### Step 6: Offer Next Step

After research (or if skipped):

> "Project initialized! Ready to brainstorm the design?"
>
> Run `/brainstorm` to explore approaches and create a design document.

## Integration Notes

- **Creates context for**: brainstorming, checkpoint, continue, verify
- **Project folder**: All persistent state lives in `docs/plans/<project>/`
- **State file**: Use `loadState()` and `saveState()` for atomic updates
- **Problems file**: Track blockers discovered during research

## Key Principles

- **Capture intent clearly** - The requirement should be specific enough to guide brainstorming
- **Research is optional** - Don't force it if user wants to jump straight to design
- **One question at a time** - Don't overwhelm with multiple prompts
- **Confirm before creating** - Verify project name before creating folders
