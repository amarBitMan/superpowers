#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: complete skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/completing-project/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/complete.md"

# Test 1: Files exist
echo -e "\nTest 1: File structure..."
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Frontmatter
echo -e "\nTest 2: Frontmatter..."
grep -q "^name: completing-project$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"
grep -q "description:" "$SKILL_FILE" && echo "  [PASS] Has description" || echo "  [FAIL] No description"

# Test 3: Key content
echo -e "\nTest 3: Key content..."
grep -q "archive" "$SKILL_FILE" && echo "  [PASS] Mentions archive" || echo "  [FAIL] Missing archive"
grep -q "Retrospective" "$SKILL_FILE" && echo "  [PASS] Has retrospective" || echo "  [FAIL] Missing retrospective"
grep -q "verification" "$SKILL_FILE" && echo "  [PASS] Has final verification" || echo "  [FAIL] Missing verification"

echo -e "\n=== Tests complete ==="
