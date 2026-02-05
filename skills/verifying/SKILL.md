---
name: verifying
description: Use to run tests and capture outcomes - logs failures to problems.md, checkpoints results
---

# Verify

## Overview

Run verification (tests, linting, type checks) and capture outcomes to project context.

**Announce at start:** "I'm using the verify skill to run tests and capture results."

## Usage

```bash
/verify                    # Run tests, capture outcomes
/verify --all              # Run all checks (tests + lint + types)
```

## The Process

### Step 1: Find Active Project

Load project context from `docs/plans/*/state.md`.

### Step 2: Detect Test Commands

Auto-detect based on project files:

```bash
# Priority order
if [ -f "package.json" ]; then
    # Check for test script
    npm test
elif [ -f "Cargo.toml" ]; then
    cargo test
elif [ -f "pyproject.toml" ]; then
    poetry run pytest
elif [ -f "pytest.ini" ] || [ -d "tests" ]; then
    pytest
elif [ -f "go.mod" ]; then
    go test ./...
fi
```

### Step 3: Run Tests

**Prefer integration tests:**
- Look for `tests/integration/` directory
- Run integration tests first if separate
- Then run full suite

Capture:
- Pass/fail count
- Failure messages
- Test duration

### Step 4: Handle Results

**All passing:**
```
Verification complete

Tests: 24 passing, 0 failing
Duration: 12.3s

Checkpoint: "verified: all tests passing"
```

Add checkpoint to state.md.

**Failures found:**

1. Log each failure to `problems.md`:
   ```markdown
   ## test-failure-<test-name>
   **Status:** Active
   **Discovered:** <date>

   ### Symptom
   Test `<test-name>` failing:
   ```
   <error message>
   ```

   ### Investigation
   (pending)
   ```

2. Report:
   ```
   Verification complete

   Tests: 20 passing, 4 failing
   Duration: 15.1s

   Failures logged to problems.md:
   - test-failure-auth-refresh
   - test-failure-token-expiry

   Checkpoint: "verified: 4 failures"

   Want to investigate? Use /continue to iterate.
   ```

### Step 5: Optional --all Flag

If `--all` specified, also run:

```bash
# Linting
npm run lint || eslint .
cargo clippy
ruff check .

# Type checking
npx tsc --noEmit
mypy .
```

Report all results together.

## Key Principles

- **Integration test first** - Prefer integration tests over unit tests
- **Capture everything** - All failures logged to problems.md
- **Checkpoint results** - State updated with verification outcome

## Integration

**Updates:**
- state.md - Checkpoint with verification results
- problems.md - Failure entries if tests fail

**Called by:**
- Manual invocation
- /checkpoint --verify
- Auto-verify in executing-plans (after final batch)
