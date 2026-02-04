# Superpowers

Superpowers is a complete software development workflow for your coding agents, built on top of a set of composable "skills" and some initial instructions that make sure your agent uses them.

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has Superpowers.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

**Note:** Installation differs by platform. Claude Code has a built-in plugin system. Codex and OpenCode require manual setup.

### Claude Code (via Plugin Marketplace)

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add obra/superpowers-marketplace
```

Then install the plugin from this marketplace:

```bash
/plugin install superpowers@superpowers-marketplace
```

### Claude Code (Local Development Version)

To use a local/forked version instead of the marketplace version:

1. **Clone or fork the repository:**
   ```bash
   git clone https://github.com/obra/superpowers.git
   cd superpowers
   ```

2. **Add your local directory as a marketplace:**
   ```bash
   /plugin marketplace add /path/to/your/superpowers
   ```

   This registers it as a local marketplace (e.g., `superpowers-dev` based on the `name` field in `.claude-plugin/marketplace.json`).

3. **Install from your local marketplace:**
   ```bash
   /plugin install superpowers@superpowers-dev
   ```

4. **Update `~/.claude/settings.json` to enable the local plugin:**

   If you previously had the official plugin installed, you must update `enabledPlugins`:
   ```json
   {
     "enabledPlugins": {
       "superpowers@superpowers-dev": true
     }
   }
   ```

   Remove or change any existing `superpowers@claude-plugins-official` entry.

5. **Clear the plugin cache:**
   ```bash
   rm -rf ~/.claude/plugins/cache
   ```

6. **Restart Claude Code**

**Troubleshooting:** If Claude Code still loads the official plugin:
- Check `~/.claude/settings.json` - ensure `enabledPlugins` points to your local marketplace
- Check `~/.claude/plugins/installed_plugins.json` - remove any `superpowers@claude-plugins-official` entries
- Clear cache again and restart

**To switch back to marketplace version:**
```bash
# Update ~/.claude/settings.json enabledPlugins to:
# "superpowers@superpowers-marketplace": true

/plugin uninstall superpowers@superpowers-dev
/plugin install superpowers@superpowers-marketplace
```

**For quick testing without marketplace setup**, use the `--plugin-dir` flag:
```bash
claude --plugin-dir /path/to/your/superpowers
```
This loads the plugin directly without installation, useful for rapid iteration.

### Verify Installation

Check that commands appear:

```bash
/help
```

```
# Should see:
# /superpowers:brainstorm - Interactive design refinement
# /superpowers:write-plan - Create implementation plan
# /superpowers:execute-plan - Execute plan in batches
# /superpowers:init - Start a new project with persistent context
# /superpowers:checkpoint - Save current state
# /superpowers:continue - Resume work with context
# /superpowers:verify - Run tests and capture outcomes
# /superpowers:complete - Mark project done
```

### Codex

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

**Detailed docs:** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## Persistent Development Context

For multi-session projects, superpowers provides persistent context that survives session restarts:

```bash
# Start a new project
/superpowers:init "Build user authentication with JWT"

# Work on the project... brainstorm, plan, execute...

# Save progress anytime
/superpowers:checkpoint "implemented login flow"

# --- Session ends, new session starts ---

# Resume with full context
/superpowers:continue

# Run tests and capture results
/superpowers:verify

# When done
/superpowers:complete
```

**Project context is stored in `docs/plans/<project-name>/`:**
- `requirement.md` - Original requirement
- `state.md` - Progress tracking (checkpoints, decisions)
- `problems.md` - Issue log with investigation notes
- `design.md` - Design document (after brainstorming)

See [docs/persistent-context.md](docs/persistent-context.md) for full documentation.

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle (includes testing anti-patterns reference)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Persistent Development Context**
- **init** - Start a new project with persistent context (`/superpowers:init`)
- **checkpoint** - Save current state anytime (`/superpowers:checkpoint`)
- **continue** - Resume work with full context loaded (`/superpowers:continue`)
- **verify** - Run tests and capture outcomes (`/superpowers:verify`)
- **complete** - Mark project done with retrospective (`/superpowers:complete`)

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-superpowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read more: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## Contributing

Skills live directly in this repository. To contribute:

1. Fork the repository
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. Submit a PR

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Skills update automatically when you update the plugin:

```bash
/plugin update superpowers
```

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: https://github.com/obra/superpowers/issues
- **Marketplace**: https://github.com/obra/superpowers-marketplace
