---
name: verifying
description: Use to run tests and capture outcomes - logs failures to problems.md, checkpoints results
---

# Verify

## Overview

Run tests and capture results to project context. Log failures. Checkpoint outcomes.

**Announce at start:** "I'm using the verify skill to run tests and capture results."

## The Process

### Step 1: Find the active project

Look for `docs/plans/*/state.md` in the current directory.

If no project found, run tests anyway but skip the checkpoint/logging steps.

### Step 2: Detect the test command

Auto-detect based on project files. Check in this order:

1. `package.json` with test script → `npm test`
2. `Cargo.toml` → `cargo test`
3. `pyproject.toml` → `poetry run pytest` or `pytest`
4. `go.mod` → `go test ./...`
5. `pytest.ini` or `tests/` directory → `pytest`
6. `pom.xml` or `build.gradle` → `mvn test` or `gradle test`

If you can't detect the command, ask: "What command runs your tests?"

### Step 3: Run the tests

Run the detected test command. Capture:
- Pass/fail count
- Failure messages
- Test duration

### Step 4: Handle results

**All passing:**

Report to the user:
```
Verification complete

Tests: <count> passing, 0 failing
Duration: <time>
```

If a project exists, add checkpoint to state.md:
```
- **[<date>]** `verified`: all tests passing
```

**Failures found:**

1. If a project exists, log each failure to `problems.md` under `## Active`:
   ```markdown
   ### test-failure: <test-name>
   **Status:** Active
   **Discovered:** <date>
   **Symptom:** <error message>
   **Investigation:** (pending)
   ```

2. Report to the user:
   ```
   Verification complete

   Tests: <pass count> passing, <fail count> failing
   Duration: <time>

   Failures logged to problems.md.
   Want to investigate? Use /superpowers:continue to iterate.
   ```

3. Add checkpoint:
   ```
   - **[<date>]** `verified`: <fail count> failures
   ```

### Step 5: Extended checks (if --all flag)

If the user passed `--all`, also run:

- **Linting:** `npm run lint`, `cargo clippy`, `ruff check .` (whichever applies)
- **Type checking:** `npx tsc --noEmit`, `mypy .` (whichever applies)

Report all results together.

## Key Principles

- **Run first, report after** — Don't speculate about test results
- **Log everything** — All failures go to problems.md
- **Checkpoint outcomes** — State updated with verification result
