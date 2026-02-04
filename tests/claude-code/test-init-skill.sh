#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: init skill ==="

# Test 1: Skill file exists with correct frontmatter
echo -e "\nTest 1: Skill structure..."

SKILL_FILE="$SCRIPT_DIR/../../skills/init/SKILL.md"
if [ -f "$SKILL_FILE" ]; then
    echo "  [PASS] Skill file exists"
else
    echo "  [FAIL] Skill file missing"
    exit 1
fi

# Check frontmatter
if grep -q "^name: init$" "$SKILL_FILE"; then
    echo "  [PASS] Name in frontmatter"
else
    echo "  [FAIL] Name missing from frontmatter"
fi

if grep -q "description:" "$SKILL_FILE"; then
    echo "  [PASS] Description in frontmatter"
else
    echo "  [FAIL] Description missing from frontmatter"
fi

# Test 2: Command file exists
echo -e "\nTest 2: Command file..."

CMD_FILE="$SCRIPT_DIR/../../commands/init.md"
if [ -f "$CMD_FILE" ]; then
    echo "  [PASS] Command file exists"
else
    echo "  [FAIL] Command file missing"
fi

if grep -q "superpowers:init" "$CMD_FILE"; then
    echo "  [PASS] Command invokes skill"
else
    echo "  [FAIL] Command doesn't invoke skill"
fi

echo -e "\n=== Tests complete ==="
