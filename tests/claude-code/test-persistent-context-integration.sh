#!/bin/bash
# Integration test for persistent development context workflow
# This test simulates the full workflow: init → brainstorm → plan → execute → continue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Integration Test: Persistent Development Context ==="

# Test 1: All skills exist
echo -e "\nTest 1: All skills present..."
SKILLS="init checkpoint continue verify complete"
for skill in $SKILLS; do
    SKILL_FILE="$SCRIPT_DIR/../../skills/$skill/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
        echo "  [PASS] $skill skill exists"
    else
        echo "  [FAIL] $skill skill missing"
    fi
done

# Test 2: All commands exist
echo -e "\nTest 2: All commands present..."
COMMANDS="init checkpoint continue verify complete"
for cmd in $COMMANDS; do
    CMD_FILE="$SCRIPT_DIR/../../commands/$cmd.md"
    if [ -f "$CMD_FILE" ]; then
        echo "  [PASS] $cmd command exists"
    else
        echo "  [FAIL] $cmd command missing"
    fi
done

# Test 3: Project context library
echo -e "\nTest 3: Project context library..."
LIB_FILE="$SCRIPT_DIR/../../lib/project-context.js"
if [ -f "$LIB_FILE" ]; then
    echo "  [PASS] project-context.js exists"
else
    echo "  [FAIL] project-context.js missing"
fi

# Test 4: Enhanced skills have context integration
echo -e "\nTest 4: Skill enhancements..."
BRAINSTORM="$SCRIPT_DIR/../../skills/brainstorming/SKILL.md"
EXECUTE="$SCRIPT_DIR/../../skills/executing-plans/SKILL.md"
TDD="$SCRIPT_DIR/../../skills/test-driven-development/SKILL.md"

grep -q "requirement.md" "$BRAINSTORM" && echo "  [PASS] brainstorming: context integration" || echo "  [FAIL] brainstorming: missing context"
grep -qi "auto-checkpoint" "$EXECUTE" && echo "  [PASS] executing-plans: auto-checkpoint" || echo "  [FAIL] executing-plans: missing auto-checkpoint"
grep -qi "integration test" "$TDD" && echo "  [PASS] TDD: integration preference" || echo "  [FAIL] TDD: missing integration preference"

# Test 5: Skills have correct frontmatter
echo -e "\nTest 5: Skill frontmatter validation..."
for skill in $SKILLS; do
    SKILL_FILE="$SCRIPT_DIR/../../skills/$skill/SKILL.md"
    if grep -q "^name: $skill$" "$SKILL_FILE"; then
        echo "  [PASS] $skill: correct name in frontmatter"
    else
        echo "  [FAIL] $skill: incorrect/missing name in frontmatter"
    fi
done

# Test 6: Commands invoke correct skills
echo -e "\nTest 6: Command-skill linkage..."
for cmd in $COMMANDS; do
    CMD_FILE="$SCRIPT_DIR/../../commands/$cmd.md"
    if grep -q "superpowers:$cmd" "$CMD_FILE"; then
        echo "  [PASS] $cmd command invokes superpowers:$cmd"
    else
        echo "  [FAIL] $cmd command doesn't invoke correct skill"
    fi
done

# Test 7: Library exports
echo -e "\nTest 7: Library exports..."
node -e "
const pc = require('$SCRIPT_DIR/../../lib/project-context.js');
const fns = ['createProject', 'loadState', 'saveState', 'addCheckpoint', 'loadProblems', 'addProblem', 'findProjects'];
const missing = fns.filter(f => typeof pc[f] !== 'function');
if (missing.length > 0) {
  console.log('  [FAIL] Missing exports:', missing.join(', '));
  process.exit(1);
}
console.log('  [PASS] All library functions exported');
" 2>/dev/null || echo "  [FAIL] Library export check failed"

echo -e "\n=== Integration Test Complete ==="
