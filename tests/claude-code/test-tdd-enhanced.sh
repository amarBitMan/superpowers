#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: TDD enhancements ==="

SKILL_FILE="$SCRIPT_DIR/../../skills/test-driven-development/SKILL.md"

# Test 1: Integration test preference
echo -e "\nTest 1: Integration test preference..."
grep -qi "integration test" "$SKILL_FILE" && echo "  [PASS] Mentions integration tests" || echo "  [FAIL] Missing integration test mention"
grep -qi "prefer.*integration" "$SKILL_FILE" && echo "  [PASS] Prefers integration tests" || echo "  [FAIL] Missing integration preference"

# Test 2: Minimal mocking
echo -e "\nTest 2: Minimal mocking..."
grep -qi "minimal.*mock\|minimize.*mock" "$SKILL_FILE" && echo "  [PASS] Mentions minimal mocking" || echo "  [FAIL] Missing minimal mocking"

# Test 3: Testing hierarchy section
echo -e "\nTest 3: Testing hierarchy..."
grep -qi "Testing Preference\|test.*hierarchy\|prefer.*hierarchy" "$SKILL_FILE" && echo "  [PASS] Has testing hierarchy section" || echo "  [FAIL] Missing testing hierarchy section"

echo -e "\n=== Tests complete ==="
