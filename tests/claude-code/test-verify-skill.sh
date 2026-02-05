#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: verify skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/verifying/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/verify.md"

# Test 1: Files exist
echo -e "\nTest 1: File structure..."
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Frontmatter
echo -e "\nTest 2: Frontmatter..."
grep -q "^name: verifying$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"
grep -q "description:" "$SKILL_FILE" && echo "  [PASS] Has description" || echo "  [FAIL] No description"

# Test 3: Key content
echo -e "\nTest 3: Key content..."
grep -q "test command" "$SKILL_FILE" && echo "  [PASS] Mentions test detection" || echo "  [FAIL] Missing test detection reference"
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Logs to problems.md" || echo "  [FAIL] Missing problems.md reference"
grep -q "\-\-all" "$SKILL_FILE" && echo "  [PASS] Has --all flag" || echo "  [FAIL] Missing --all flag"

echo -e "\n=== Tests complete ==="
