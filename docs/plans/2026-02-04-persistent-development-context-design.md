# Persistent Development Context - Design Document

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:writing-plans to create implementation plan from this design.

**Goal:** Extend superpowers workflow to support iterative development cycles with persistent context that survives session restarts and auto-compaction.

**Architecture:** Project-as-folder structure with hierarchical state management, git-backed implementation tracking, and smart context loading based on current work.

**Tech Stack:** Markdown files for state, JavaScript for context management, existing superpowers skill infrastructure.

---

## Problem Statement

After implementing a feature using `brainstorm` → `write-plan` → `execute-plan`, issues often arise during deployment/testing. Currently:

- No automatic way to resume with full context of previous work
- When auto-compact happens or new session starts, context is lost
- Each iteration requires manually re-explaining what was done previously

## Solution Overview

### Philosophy

1. **Project-as-folder**: Each project lives in `plans/<project-name>/` with structured files
2. **Git-backed state**: Implementation details reference commits, not duplicate code
3. **Hierarchical context**: Summaries at top, details loaded on-demand based on current work
4. **Anytime checkpoints**: Capture decisions and state at any moment, not just phase transitions
5. **Research-first**: Enrich requirements with industry knowledge before designing

### New Commands

| Command | Purpose |
|---------|---------|
| `/init` | Start new project, capture requirement, create folder structure |
| `/checkpoint` | Save current state with optional description |
| `/continue` | Resume project with full context loaded |
| `/verify` | Run tests and capture outcomes |
| `/complete` | Mark project complete, archive context |

### Enhanced Existing Commands

| Command | Enhancement |
|---------|-------------|
| `/brainstorm` | Integrates research phase, reads from `requirement.md` if exists |
| `/write-plan` | Auto-checkpoints, TDD-first with integration test preference |
| `/execute-plan` | Auto-checkpoints per batch, logs problems, auto-verify at end |

---

## File Structure

```
plans/<project-name>/
├── requirement.md      # Original prompt + enriched version after research
├── research.md         # Industry research, similar solutions, references
├── design.md           # From brainstorm (existing pattern)
├── plan.md             # From write-plan (existing pattern)
├── state.md            # Hierarchical: summary → sections → details
└── problems.md         # Issues log with status tracking
```

### state.md - Hierarchical Structure

```markdown
# my-auth-feature

## Summary (always loaded)
Phase: execute-plan complete, deployed to staging
Status: Issues found during deployment
Last active: 2024-01-15 18:30
Key commits: abc123, def456, ghi789 (3 total)
Active problems: 2 (see problems.md)

## Checkpoints (loaded on /continue)
- [01-15 10:30] init: "Add JWT auth to API"
- [01-15 11:00] research: Chose JWT over sessions (stateless, mobile-friendly)
- [01-15 12:15] design: REST endpoints, refresh token flow
- [01-15 14:00] plan: 12 tasks identified
- [01-15 17:45] execute: All tasks complete
- [01-15 18:00] verify: Tests pass, ready for deploy
- [01-15 18:30] continue: "Safari auth failure, need logout button"

## Decisions (loaded when relevant)
### auth-approach
Chose JWT over session cookies
- Stateless, scales horizontally
- Better for mobile clients
- Trade-off: Token refresh complexity
Commit: abc123

### token-storage
Chose httpOnly cookies over localStorage
- XSS protection
- Trade-off: CSRF considerations
Commit: def456

## Implementation (loaded when debugging)
### Files Changed
- `src/auth/jwt.py` - Token generation/validation
- `src/api/middleware.py` - Auth middleware
- `src/api/routes/auth.py` - Login/refresh endpoints
- `tests/integration/test_auth.py` - Auth flow tests

## Testing Approach
- Prefer: Integration tests over unit tests
- Minimize: Mocking - test real behavior with real dependencies
- Coverage: Critical paths must have integration tests
- When to unit test: Pure functions, complex algorithms, edge cases
```

### problems.md - Issues Log

```markdown
# Problems Log: my-feature

## token-refresh
**Status:** Active
**Discovered:** 2024-01-15 16:45
**Commit:** def456

### Symptom
Mobile clients get 401 after token expires, refresh not working

### Investigation
1. Server logs show refresh endpoint receiving request ✓
2. New token generated correctly ✓
3. Response sent but client not receiving → **CORS issue**

### Resolution
(pending)

---

## previous-issue
**Status:** Resolved
**Discovered:** 2024-01-15 11:00
**Resolved:** 2024-01-15 11:30
**Commit:** abc123

### Symptom
...

### Resolution
Fixed by adding X
```

### Smart Loading Rules

| Context | What's Loaded |
|---------|---------------|
| `/continue` (any) | Summary + Checkpoints + Active problems |
| `/continue` (debugging) | + Implementation + Related decisions |
| `/continue --full` | Everything |
| Scoped iteration on "auth" | + Decisions tagged "auth" + Files with "auth" |

---

## Command Workflows

### `/init` - Project Initialization

```bash
/init "your idea, requirement, or problem statement"
/init @requirement.md                    # From file
/init --name "my-feature" "description"  # Explicit project name
```

**Flow:**
1. Create `plans/<project-name>/` folder (name derived from prompt or explicit)
2. Save original prompt to `requirement.md`
3. Initialize empty `state.md` with summary section
4. Ask: **"What depth of research?"**
   - Light (2-3 min): Quick GitHub search, top similar projects
   - Medium (5-10 min): GitHub + web, brief analysis
   - Thorough (15+ min): Deep dive, pros/cons matrix, recommendations
   - Skip: No research, go straight to brainstorm
5. Run research phase (unless skipped)
6. Update `requirement.md` with enriched version + create `research.md`
7. Auto-transition to brainstorm (or ask)

### `/checkpoint` - Anytime State Capture

```bash
/checkpoint                                    # Auto-describe from recent activity
/checkpoint "decided X over Y because Z"       # Explicit description
/checkpoint --verify                           # Run tests + capture results
```

**Flow:**
1. Capture current phase, recent git commits since last checkpoint
2. Add timestamped entry to `state.md` Checkpoints section
3. If `--verify`: run tests, capture pass/fail, log failures to `problems.md`
4. If during brainstorm/design: prompt to capture key decision in Decisions section

### `/continue` - Context-Aware Resume

```bash
/continue                                      # Load context, ask what to do
/continue "Safari auth broken, need logout"    # Log issues + iterate
/continue --from brainstorm "rethink approach" # Force phase
/continue my-other-project                     # Explicit project
```

**Flow:**
1. Find project (auto-detect single, prompt if multiple, or use explicit name)
2. Load hierarchical context (summary + checkpoints + active problems)
3. If new issues provided: log to `problems.md`
4. Present context summary
5. Ask iteration type:
   - Quick fix → execute-plan with scoped task
   - Scoped rework → mini brainstorm → plan → execute
   - Full rework → brainstorm with all learnings
   - Research → investigate before deciding
6. Load additional context based on choice (decisions, implementation details)
7. Run chosen workflow

### `/verify` - Manual Verification

```bash
/verify                    # Run tests, check outcomes
/verify --deploy staging   # Run tests + deployment checks
```

**Flow:**
1. Run test suite (prefer integration tests)
2. Capture results in `state.md`
3. If failures: log to `problems.md`, ask if you want to iterate
4. If pass: checkpoint as "verified", ready for deploy/complete

### `/complete` - Project Completion

```bash
/complete                  # Mark done, archive
/complete --keep-active    # Mark done but keep in active projects
```

**Flow:**
1. Final checkpoint with completion summary
2. Move resolved problems to "Resolved" section
3. Generate brief retrospective (what worked, what didn't)
4. Optionally archive to `plans/archive/<project-name>/`

---

## TDD Integration

### Testing Philosophy

- **Prefer integration tests** over unit tests
- **Minimize mocking** - test real behavior with real dependencies
- **When to unit test**: Pure functions, complex algorithms, edge cases only

### TDD in `/write-plan`

Plans enforce TDD structure per task:

```markdown
### Task 3: Auth Middleware

**Test type:** Integration (hits real endpoint, real DB)

**Step 1: Write failing test**
```python
# tests/integration/test_auth_middleware.py
def test_protected_endpoint_requires_valid_token(client, db):
    # No mocking - real client, real database
    response = client.get("/api/protected")
    assert response.status_code == 401

    token = create_test_user_and_login(db)
    response = client.get("/api/protected", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
```

**Step 2: Run test - expect FAIL**
```bash
pytest tests/integration/test_auth_middleware.py -v
# Expected: FAILED (endpoint not protected yet)
```

**Step 3: Implement**
...

**Step 4: Run test - expect PASS**
...

**Step 5: Commit**
```bash
git commit -m "Add auth middleware with integration test"
```
```

### TDD in `/execute-plan`

Execution enforces the cycle:

1. **Before implementation**: Check test exists and fails
2. **After implementation**: Run test, must pass
3. **Auto-log violation**: If code written before test, log to `problems.md`

### Auto-Verify After Execute-Plan

After final task batch:
- Run full test suite
- Capture results in `state.md`
- Log any failures to `problems.md`
- Checkpoint as "execute-plan complete, verified"

---

## Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│  /init "add JWT auth to my API"                                        │
│      → Creates plans/jwt-auth/                                          │
│      → Asks research depth                                              │
│      → Enriches requirement with industry research                      │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  /brainstorm                                                            │
│      → Loads requirement.md + research.md                               │
│      → Collaborative design exploration                                 │
│      → /checkpoint "chose JWT over sessions"                            │
│      → Saves design.md                                                  │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  /write-plan                                                            │
│      → Loads design.md                                                  │
│      → Creates TDD tasks (integration tests preferred)                  │
│      → Auto-checkpoint on save                                          │
│      → Saves plan.md                                                    │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  /execute-plan                                                          │
│      → Loads plan.md + state.md                                         │
│      → TDD cycle per task                                               │
│      → Auto-checkpoint per batch                                        │
│      → Auto-logs problems encountered                                   │
│      → Auto-verify at end                                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  [You deploy to staging]                                                │
│  [Discover: Safari auth broken + need logout button]                    │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  /continue "Safari auth broken on mobile, also need logout button"      │
│      → Loads state.md (summary + checkpoints)                           │
│      → Loads problems.md                                                │
│      → Logs new issues                                                  │
│      → Asks: Quick fix? Scoped rework? Full rework? Research?           │
│      → You choose: "Scoped rework"                                      │
│      → Mini: brainstorm → plan → execute for these issues               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────────────┐
│  [Cycle repeats until satisfied]                                        │
│                                                                         │
│  /complete                                                              │
│      → Final checkpoint                                                 │
│      → Archive project                                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Scope

### New Skills to Create

| Skill | Purpose | Complexity |
|-------|---------|------------|
| `superpowers:init` | Project initialization + research phase | Medium |
| `superpowers:checkpoint` | Anytime state capture | Low |
| `superpowers:continue` | Context loading + iteration routing | High |
| `superpowers:verify` | Test runner + outcome capture | Medium |
| `superpowers:complete` | Project completion + archival | Low |

### Existing Skills to Modify

| Skill | Changes |
|-------|---------|
| `brainstorming` | Check for existing project context, integrate research, save to project folder |
| `writing-plans` | TDD-first structure, integration test preference, link to project state |
| `executing-plans` | TDD enforcement, auto-checkpoint, auto-log problems, auto-verify |
| `test-driven-development` | Add integration test preference, minimal mocking guidance |

### New Commands to Create

```
commands/
├── init.md           → invokes superpowers:init
├── checkpoint.md     → invokes superpowers:checkpoint
├── continue.md       → invokes superpowers:continue
├── verify.md         → invokes superpowers:verify
└── complete.md       → invokes superpowers:complete
```

### Supporting Infrastructure

| Component | Purpose |
|-----------|---------|
| `lib/project-context.js` | Load/save state.md, problems.md with hierarchical parsing |
| `lib/research.js` | GitHub search, web search, findings aggregation |
| State schema | Consistent format for state.md sections |
| Problems schema | Consistent format for problems.md entries |

### Implementation Order (Suggested)

**Phase 1: Foundation**
1. Define state.md and problems.md schemas
2. Create `lib/project-context.js` for read/write operations
3. Implement `/init` (without research - just folder + requirement capture)
4. Implement `/checkpoint`

**Phase 2: Context Resume**
5. Implement `/continue` with hierarchical loading
6. Implement iteration type routing (quick-fix, scoped, full, research)

**Phase 3: Integration**
7. Modify `/brainstorm` to read/write project context
8. Modify `/write-plan` with TDD structure
9. Modify `/execute-plan` with auto-checkpoint + problem logging

**Phase 4: Verification**
10. Implement `/verify` with test runner integration
11. Add auto-verify to execute-plan
12. Implement `/complete`

**Phase 5: Research**
13. Create `lib/research.js`
14. Integrate research phase into `/init`
15. Add research option to `/continue`

---

## Out of Scope (YAGNI)

- Multi-user collaboration / shared context
- Cloud sync of project state
- GUI/dashboard for project status
- Automatic project discovery across directories
- Integration with external issue trackers (Jira, GitHub Issues)
- Custom workflow definitions

These can be added later if needed.

---

## Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Context loading | Explicit `/continue` command | User control, avoids confusion when starting fresh |
| Context saving | Mix of explicit + auto + continuous | Captures all important moments without overhead |
| Context priority | Problems > Implementation > Tests > Decisions | Most valuable when debugging/iterating |
| State storage | Git commits as source + concrete details in docs | Lean but self-contained |
| File structure | Minimal (state.md + problems.md) | Easy to manage, less overhead |
| Research depth | Ask each time | Context-dependent, quick fix ≠ new architecture |
| Project discovery | Auto-detect single, prompt if multiple | Smart defaults with override |
| Context size management | Smart summarization + tiered loading | Stays lean, drills down when needed |
| Post-execution | Auto-verify + manual `/verify` | Catches issues early, manual option for deploy checks |
| Logging vs acting | `/continue` does both | Single command, less ceremony |
| Testing approach | Integration tests preferred, minimal mocking | Tests real behavior |

---

## References

- [GSD Project](https://github.com/glittercowboy/get-shit-done) - Phase-wise implementation inspiration
- [PR #386](https://github.com/obra/superpowers/pull/386) - Research existing solutions step
- [PR #362](https://github.com/obra/superpowers/pull/362) - Parallel agent execution patterns
