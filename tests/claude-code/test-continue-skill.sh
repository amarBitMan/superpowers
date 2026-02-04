#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: continue skill ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/continue/SKILL.md"
CMD_FILE="$SCRIPT_DIR/../../commands/continue.md"

# Test 1: Files exist
echo -e "\nTest 1: File structure..."
[ -f "$SKILL_FILE" ] && echo "  [PASS] Skill file exists" || echo "  [FAIL] Skill file missing"
[ -f "$CMD_FILE" ] && echo "  [PASS] Command file exists" || echo "  [FAIL] Command file missing"

# Test 2: Frontmatter
echo -e "\nTest 2: Frontmatter..."
grep -q "^name: continue$" "$SKILL_FILE" && echo "  [PASS] Name correct" || echo "  [FAIL] Name wrong"

# Test 3: Key content - iteration types
echo -e "\nTest 3: Iteration types..."
grep -q "Quick fix" "$SKILL_FILE" && echo "  [PASS] Has Quick fix option" || echo "  [FAIL] Missing Quick fix"
grep -q "Scoped rework" "$SKILL_FILE" && echo "  [PASS] Has Scoped rework option" || echo "  [FAIL] Missing Scoped rework"
grep -q "Full rework" "$SKILL_FILE" && echo "  [PASS] Has Full rework option" || echo "  [FAIL] Missing Full rework"
grep -q "Research" "$SKILL_FILE" && echo "  [PASS] Has Research option" || echo "  [FAIL] Missing Research"

# Test 4: Context loading
echo -e "\nTest 4: Context loading..."
grep -q "state.md" "$SKILL_FILE" && echo "  [PASS] Loads state.md" || echo "  [FAIL] Missing state.md"
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Loads problems.md" || echo "  [FAIL] Missing problems.md"

echo -e "\n=== Tests complete ==="
