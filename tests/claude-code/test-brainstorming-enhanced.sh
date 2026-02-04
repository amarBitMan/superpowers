#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: brainstorming enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/brainstorming/SKILL.md"

# Test 1: Project context integration
echo -e "\nTest 1: Project context integration..."
grep -q "requirement.md" "$SKILL_FILE" && echo "  [PASS] Checks for requirement.md" || echo "  [FAIL] Missing requirement.md check"
grep -q "research.md" "$SKILL_FILE" && echo "  [PASS] Checks for research.md" || echo "  [FAIL] Missing research.md check"
grep -q "checkpoint" "$SKILL_FILE" && echo "  [PASS] Mentions checkpoint" || echo "  [FAIL] Missing checkpoint integration"

# Test 2: Context-aware behavior
echo -e "\nTest 2: Context-aware behavior..."
grep -q "Project Context Integration" "$SKILL_FILE" && echo "  [PASS] Has context integration section" || echo "  [FAIL] Missing context integration section"

echo -e "\n=== Tests complete ==="
