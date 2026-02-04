#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: executing-plans enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/executing-plans/SKILL.md"

# Test 1: Auto-checkpoint
echo -e "\nTest 1: Auto-checkpoint..."
grep -qi "auto-checkpoint" "$SKILL_FILE" && echo "  [PASS] Has auto-checkpoint" || echo "  [FAIL] Missing auto-checkpoint"

# Test 2: Problem logging
echo -e "\nTest 2: Problem logging..."
grep -q "problems.md" "$SKILL_FILE" && echo "  [PASS] Logs to problems.md" || echo "  [FAIL] Missing problems.md logging"

# Test 3: Auto-verify
echo -e "\nTest 3: Auto-verify..."
grep -qi "auto-verify" "$SKILL_FILE" && echo "  [PASS] Has auto-verify" || echo "  [FAIL] Missing auto-verify"

# Test 4: Project context section
echo -e "\nTest 4: Project context integration..."
grep -q "Project Context Integration" "$SKILL_FILE" && echo "  [PASS] Has context integration section" || echo "  [FAIL] Missing context integration section"

echo -e "\n=== Tests complete ==="
