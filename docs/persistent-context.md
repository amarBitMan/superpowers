# Persistent Development Context

A system for maintaining project context across Claude Code sessions, enabling iterative development cycles that survive session restarts.

## Quick Start

```bash
# Start a new project
/superpowers:init "Build a user authentication system with JWT"

# Save progress anytime
/superpowers:checkpoint "decided on refresh token approach"

# Resume in a new session
/superpowers:continue

# Run tests and capture results
/superpowers:verify

# Complete the project
/superpowers:complete
```

## Commands

### /superpowers:init - Start a Project

Creates project folder structure with persistent context files.

```bash
/superpowers:init "your requirement or idea"
/superpowers:init @requirement.md                    # From file
/superpowers:init --name "my-feature" "description"  # Explicit name
```

**Creates:**
- `docs/plans/<project-name>/requirement.md` - Original requirement
- `docs/plans/<project-name>/state.md` - Progress tracking
- `docs/plans/<project-name>/problems.md` - Issue log

**Options:**
- Light/Medium/Thorough research before brainstorming
- Skip research to go straight to design

### /superpowers:checkpoint - Save State

Capture current progress at any point.

```bash
/superpowers:checkpoint                              # Auto-describe from activity
/superpowers:checkpoint "implemented login flow"     # Explicit description
/superpowers:checkpoint --verify                     # Run tests + capture results
```

**Captures:**
- Current phase
- Recent git commits
- Key decisions (prompts during design phases)

### /superpowers:continue - Resume Work

Single entry point for returning to a project.

```bash
/superpowers:continue                                # Load context, ask what to do
/superpowers:continue "auth broken after deploy"     # Log issue + iterate
/superpowers:continue --from brainstorm              # Resume from specific phase
/superpowers:continue my-project                     # Explicit project name
/superpowers:continue --full                         # Load all context sections
```

**Iteration types:**
1. **Quick fix** - Small code changes, direct execution
2. **Scoped rework** - Mini brainstorm → plan → execute
3. **Full rework** - Back to brainstorm with learnings
4. **Research** - Investigate before deciding

### /superpowers:verify - Run Tests

Execute verification and capture outcomes.

```bash
/superpowers:verify                    # Run tests
/superpowers:verify --all              # Tests + lint + type checks
```

**On failure:**
- Logs each failure to `problems.md`
- Checkpoints verification results
- Offers to iterate with `/superpowers:continue`

### /superpowers:complete - Finish Project

Mark project done with retrospective.

```bash
/superpowers:complete                  # Mark done, offer archive
/superpowers:complete --keep-active    # Done but keep visible
/superpowers:complete --archive        # Done and archive immediately
```

**Generates:**
- Retrospective (duration, iterations, learnings)
- Final verification
- Optional archival to `docs/plans/archive/`

## Project Structure

```
docs/plans/<project-name>/
├── requirement.md    # Original requirement (preserved)
├── state.md          # Progress tracking
│   ├── Summary       # Phase, status, key commits
│   ├── Checkpoints   # Timestamped progress entries
│   ├── Decisions     # Key design decisions
│   └── Implementation# Files changed, approach notes
├── problems.md       # Issue tracking
│   ├── Active        # Current issues
│   └── Resolved      # Fixed issues with resolution
├── research.md       # Research findings (if researched)
└── design.md         # Design document (after brainstorm)
```

## Workflow Integration

### With Brainstorming

When `/superpowers:brainstorm` detects project context:
- Loads requirement.md and research.md
- Saves design to project folder
- Checkpoints "brainstorm: design complete"

### With Plan Execution

When `executing-plans` has project context:
- Auto-checkpoints after each batch
- Logs errors to problems.md
- Auto-verifies after final batch

### With TDD

Testing preference hierarchy:
1. Integration tests first (real behavior)
2. Unit tests for pure functions/algorithms
3. Minimize mocking (external services only)

## Context Loading

Context is loaded hierarchically based on iteration type:

| Iteration | Sections Loaded |
|-----------|-----------------|
| Quick fix | Summary + Active problems |
| Scoped rework | + Checkpoints + Related decisions |
| Full rework | + All decisions + Implementation |
| Research | Summary + Problems + Research.md |

## Tips

- **Checkpoint often** - Low friction, captures git commits automatically
- **Log issues immediately** - `/superpowers:continue "issue description"` before fixing
- **Use iteration types** - Match workflow depth to problem size
- **Review problems.md** - Patterns reveal design issues
- **Archive completed projects** - Keep active list focused
