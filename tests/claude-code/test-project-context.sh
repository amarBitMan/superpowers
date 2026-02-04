#!/bin/bash
# Test project-context.js functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: project-context library ==="

# Test 1: Module exports expected functions
echo -e "\nTest 1: Module exports..."

node -e "
const pc = require('../../lib/project-context.js');
const fns = ['createProject', 'loadState', 'saveState', 'addCheckpoint', 'loadProblems', 'addProblem', 'findProjects'];
const missing = fns.filter(f => typeof pc[f] !== 'function');
if (missing.length > 0) {
  console.log('Missing exports:', missing.join(', '));
  process.exit(1);
}
console.log('All exports present');
" && echo "  [PASS] Module exports correct" || echo "  [FAIL] Module exports"

# Test 2: createProject creates folder structure
echo -e "\nTest 2: createProject creates folder structure..."

TEST_DIR=$(mktemp -d)
node -e "
const pc = require('../../lib/project-context.js');
const fs = require('fs');
const path = require('path');

const baseDir = '$TEST_DIR';
const projectName = 'test-project';
const requirement = 'Build a test feature';

const result = pc.createProject(baseDir, projectName, requirement);

// Check all files were created
const reqFile = path.join(result.projectDir, 'requirement.md');
const stateFile = path.join(result.projectDir, 'state.md');
const problemsFile = path.join(result.projectDir, 'problems.md');

if (!fs.existsSync(reqFile)) {
  console.log('Missing requirement.md');
  process.exit(1);
}
if (!fs.existsSync(stateFile)) {
  console.log('Missing state.md');
  process.exit(1);
}
if (!fs.existsSync(problemsFile)) {
  console.log('Missing problems.md');
  process.exit(1);
}

// Check requirement.md content
const reqContent = fs.readFileSync(reqFile, 'utf8');
if (!reqContent.includes('Build a test feature')) {
  console.log('requirement.md missing content');
  process.exit(1);
}

console.log('Folder structure created correctly');
" && echo "  [PASS] createProject" || echo "  [FAIL] createProject"
rm -rf "$TEST_DIR"

# Test 3: loadState and saveState work correctly
echo -e "\nTest 3: loadState and saveState..."

TEST_DIR=$(mktemp -d)
node -e "
const pc = require('../../lib/project-context.js');
const fs = require('fs');
const path = require('path');

const baseDir = '$TEST_DIR';
const projectName = 'state-test';
const requirement = 'Test state management';

const result = pc.createProject(baseDir, projectName, requirement);

// Save some state
pc.saveState(result.projectDir, {
  summary: 'This is the project summary',
  implementation: '## Current Progress\n\nWorking on feature X'
});

// Load full state
const state = pc.loadState(result.projectDir);
if (!state.summary.includes('project summary')) {
  console.log('Summary not saved/loaded correctly');
  process.exit(1);
}
if (!state.implementation.includes('feature X')) {
  console.log('Implementation not saved/loaded correctly');
  process.exit(1);
}

// Load specific section
const partial = pc.loadState(result.projectDir, { sections: ['summary'] });
if (!partial.summary) {
  console.log('Section filtering failed');
  process.exit(1);
}

console.log('State operations work correctly');
" && echo "  [PASS] loadState/saveState" || echo "  [FAIL] loadState/saveState"
rm -rf "$TEST_DIR"

# Test 4: addCheckpoint adds entries
echo -e "\nTest 4: addCheckpoint..."

TEST_DIR=$(mktemp -d)
node -e "
const pc = require('../../lib/project-context.js');
const fs = require('fs');
const path = require('path');

const baseDir = '$TEST_DIR';
const projectName = 'checkpoint-test';
const requirement = 'Test checkpoints';

const result = pc.createProject(baseDir, projectName, requirement);

// Add a checkpoint
pc.addCheckpoint(result.projectDir, 'planning', 'Completed initial design');
pc.addCheckpoint(result.projectDir, 'implementation', 'Built core module');

// Load state and verify checkpoints
const state = pc.loadState(result.projectDir);
if (!state.checkpoints || !state.checkpoints.includes('planning')) {
  console.log('Checkpoint not added correctly');
  process.exit(1);
}
if (!state.checkpoints.includes('implementation')) {
  console.log('Multiple checkpoints not working');
  process.exit(1);
}

console.log('Checkpoints work correctly');
" && echo "  [PASS] addCheckpoint" || echo "  [FAIL] addCheckpoint"
rm -rf "$TEST_DIR"

# Test 5: loadProblems and addProblem
echo -e "\nTest 5: loadProblems and addProblem..."

TEST_DIR=$(mktemp -d)
node -e "
const pc = require('../../lib/project-context.js');
const fs = require('fs');
const path = require('path');

const baseDir = '$TEST_DIR';
const projectName = 'problems-test';
const requirement = 'Test problems tracking';

const result = pc.createProject(baseDir, projectName, requirement);

// Add a problem
pc.addProblem(result.projectDir, {
  title: 'Build fails on CI',
  description: 'Tests pass locally but fail on CI',
  status: 'open',
  severity: 'high'
});

// Load problems
const problems = pc.loadProblems(result.projectDir);
if (!problems.length || !problems[0].title.includes('Build fails')) {
  console.log('Problem not added/loaded correctly');
  process.exit(1);
}

console.log('Problems tracking works correctly');
" && echo "  [PASS] loadProblems/addProblem" || echo "  [FAIL] loadProblems/addProblem"
rm -rf "$TEST_DIR"

# Test 6: findProjects discovers projects
echo -e "\nTest 6: findProjects..."

TEST_DIR=$(mktemp -d)
node -e "
const pc = require('../../lib/project-context.js');
const fs = require('fs');
const path = require('path');

const baseDir = '$TEST_DIR';

// Create multiple projects
pc.createProject(baseDir, 'project-alpha', 'First project');
pc.createProject(baseDir, 'project-beta', 'Second project');

// Find all projects
const projects = pc.findProjects(baseDir);
if (projects.length !== 2) {
  console.log('Expected 2 projects, found:', projects.length);
  process.exit(1);
}

const names = projects.map(p => p.name);
if (!names.includes('project-alpha') || !names.includes('project-beta')) {
  console.log('Project names not found correctly:', names);
  process.exit(1);
}

console.log('findProjects works correctly');
" && echo "  [PASS] findProjects" || echo "  [FAIL] findProjects"
rm -rf "$TEST_DIR"

echo -e "\n=== Tests complete ==="
