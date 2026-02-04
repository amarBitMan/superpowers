/**
 * Project Context Library
 *
 * Foundation library for the persistent development context system.
 * Provides functions to manage project state, checkpoints, and problems.
 */

const fs = require('fs');
const path = require('path');

/**
 * Default directory for project plans
 */
const PLANS_DIR = 'docs/plans';

/**
 * State file sections in order
 */
const STATE_SECTIONS = ['summary', 'checkpoints', 'decisions', 'implementation', 'testing'];

/**
 * Create initial state.md content
 */
function createInitialState(projectName) {
    return `# ${projectName} - State

## Summary

*Project initialized. No summary yet.*

## Checkpoints

*No checkpoints recorded yet.*

## Decisions

*No decisions recorded yet.*

## Implementation

*No implementation progress recorded yet.*

## Testing Approach

*No testing approach defined yet.*
`;
}

/**
 * Create initial problems.md content
 */
function createInitialProblems(projectName) {
    return `# ${projectName} - Problems

*No problems recorded yet.*
`;
}

/**
 * Creates project folder structure with requirement.md, state.md, problems.md
 *
 * @param {string} baseDir - Base directory (usually repo root)
 * @param {string} projectName - Name of the project
 * @param {string} requirement - The requirement text
 * @returns {{projectDir: string, files: string[]}} - Created project info
 */
function createProject(baseDir, projectName, requirement) {
    const projectDir = path.join(baseDir, PLANS_DIR, projectName);

    // Check if project already exists
    if (fs.existsSync(projectDir)) {
        throw new Error(`Project already exists: ${projectDir}`);
    }

    // Create directory
    fs.mkdirSync(projectDir, { recursive: true });

    // Create requirement.md
    const reqFile = path.join(projectDir, 'requirement.md');
    const reqContent = `# ${projectName} - Requirement\n\n${requirement}\n`;
    fs.writeFileSync(reqFile, reqContent, 'utf8');

    // Create state.md
    const stateFile = path.join(projectDir, 'state.md');
    fs.writeFileSync(stateFile, createInitialState(projectName), 'utf8');

    // Create problems.md
    const problemsFile = path.join(projectDir, 'problems.md');
    fs.writeFileSync(problemsFile, createInitialProblems(projectName), 'utf8');

    return {
        projectDir,
        files: [reqFile, stateFile, problemsFile]
    };
}

/**
 * Parse state.md content into sections
 *
 * @param {string} content - Full content of state.md
 * @returns {Object} - Parsed sections
 */
function parseState(content) {
    const sections = {
        summary: '',
        checkpoints: '',
        decisions: '',
        implementation: '',
        testing: ''
    };

    const lines = content.split('\n');
    let currentSection = null;
    let sectionContent = [];

    // Known section headers (lowercase)
    const knownSections = ['summary', 'checkpoints', 'decisions', 'implementation', 'testing approach', 'testing'];

    for (const line of lines) {
        // Check for section headers
        const headerMatch = line.match(/^## (.+)$/);
        if (headerMatch) {
            const headerText = headerMatch[1].toLowerCase();

            // Only switch sections for known headers
            if (knownSections.includes(headerText)) {
                // Save previous section
                if (currentSection) {
                    sections[currentSection] = sectionContent.join('\n').trim();
                }

                // Map header to section key
                if (headerText === 'summary') currentSection = 'summary';
                else if (headerText === 'checkpoints') currentSection = 'checkpoints';
                else if (headerText === 'decisions') currentSection = 'decisions';
                else if (headerText === 'implementation') currentSection = 'implementation';
                else if (headerText === 'testing approach' || headerText === 'testing') currentSection = 'testing';

                sectionContent = [];
            } else if (currentSection !== null) {
                // Unknown ## header within a section - include it as content
                sectionContent.push(line);
            }
        } else if (currentSection !== null && !line.match(/^# /)) {
            // Ignore the main title line
            sectionContent.push(line);
        }
    }

    // Save the last section
    if (currentSection) {
        sections[currentSection] = sectionContent.join('\n').trim();
    }

    return sections;
}

/**
 * Loads state.md with optional section filtering
 *
 * @param {string} projectDir - Path to project directory
 * @param {Object} options - Options
 * @param {string[]} options.sections - Specific sections to load
 * @returns {Object} - State object with sections
 */
function loadState(projectDir, options = {}) {
    const stateFile = path.join(projectDir, 'state.md');

    if (!fs.existsSync(stateFile)) {
        return {
            summary: '',
            checkpoints: '',
            decisions: '',
            implementation: '',
            testing: ''
        };
    }

    const content = fs.readFileSync(stateFile, 'utf8');
    const state = parseState(content);

    // Filter sections if specified
    if (options.sections && Array.isArray(options.sections)) {
        const filtered = {};
        for (const section of options.sections) {
            if (state[section] !== undefined) {
                filtered[section] = state[section];
            }
        }
        return filtered;
    }

    return state;
}

/**
 * Saves/updates state.md
 *
 * @param {string} projectDir - Path to project directory
 * @param {Object} sections - Sections to update (keys: summary, checkpoints, decisions, implementation, testing)
 */
function saveState(projectDir, sections) {
    const stateFile = path.join(projectDir, 'state.md');

    // Load existing state
    let existingState = {
        summary: '*No summary yet.*',
        checkpoints: '*No checkpoints recorded yet.*',
        decisions: '*No decisions recorded yet.*',
        implementation: '*No implementation progress recorded yet.*',
        testing: '*No testing approach defined yet.*'
    };

    if (fs.existsSync(stateFile)) {
        existingState = loadState(projectDir);
    }

    // Merge in new sections
    for (const [key, value] of Object.entries(sections)) {
        if (STATE_SECTIONS.includes(key)) {
            existingState[key] = value;
        }
    }

    // Extract project name from directory
    const projectName = path.basename(projectDir);

    // Rebuild state.md
    const content = `# ${projectName} - State

## Summary

${existingState.summary}

## Checkpoints

${existingState.checkpoints}

## Decisions

${existingState.decisions}

## Implementation

${existingState.implementation}

## Testing Approach

${existingState.testing}
`;

    try {
        fs.writeFileSync(stateFile, content, 'utf8');
    } catch (err) {
        throw new Error(`Failed to write state file '${stateFile}': ${err.message}`);
    }
}

/**
 * Adds checkpoint entry to state.md
 *
 * @param {string} projectDir - Path to project directory
 * @param {string} phase - Phase name (e.g., 'planning', 'implementation', 'testing')
 * @param {string} description - Checkpoint description
 * @param {Object} options - Additional options
 * @param {string} options.timestamp - Custom timestamp (default: current time)
 */
function addCheckpoint(projectDir, phase, description, options = {}) {
    const state = loadState(projectDir);

    // Generate timestamp
    const timestamp = options.timestamp || new Date().toISOString().split('T')[0];

    // Format the checkpoint entry
    const entry = `- **[${timestamp}]** \`${phase}\`: ${description}`;

    // Add to checkpoints
    let checkpoints = state.checkpoints || '';

    // Remove placeholder text if present
    if (checkpoints.includes('*No checkpoints recorded yet.*')) {
        checkpoints = '';
    }

    // Append new checkpoint
    checkpoints = checkpoints.trim();
    if (checkpoints) {
        checkpoints += '\n' + entry;
    } else {
        checkpoints = entry;
    }

    // Save updated state
    saveState(projectDir, { checkpoints });
}

/**
 * Parse problems.md into structured problem entries
 *
 * @param {string} content - Full content of problems.md
 * @returns {Array} - Array of problem objects
 */
function parseProblems(content) {
    const problems = [];
    const lines = content.split('\n');

    let currentProblem = null;
    let currentField = null;
    let fieldContent = [];

    for (const line of lines) {
        // Check for problem header (### Problem: Title)
        const problemMatch = line.match(/^### Problem: (.+)$/);
        if (problemMatch) {
            // Save previous problem
            if (currentProblem) {
                if (currentField) {
                    currentProblem[currentField] = fieldContent.join('\n').trim();
                }
                problems.push(currentProblem);
            }

            currentProblem = {
                title: problemMatch[1],
                description: '',
                status: 'open',
                severity: 'medium'
            };
            currentField = null;
            fieldContent = [];
            continue;
        }

        if (currentProblem) {
            // Check for field markers
            const statusMatch = line.match(/^\*\*Status:\*\*\s*(.+)$/);
            const severityMatch = line.match(/^\*\*Severity:\*\*\s*(.+)$/);
            const descMatch = line.match(/^\*\*Description:\*\*\s*(.*)$/);

            if (statusMatch) {
                if (currentField) {
                    currentProblem[currentField] = fieldContent.join('\n').trim();
                }
                currentProblem.status = statusMatch[1].toLowerCase();
                currentField = null;
                fieldContent = [];
            } else if (severityMatch) {
                if (currentField) {
                    currentProblem[currentField] = fieldContent.join('\n').trim();
                }
                currentProblem.severity = severityMatch[1].toLowerCase();
                currentField = null;
                fieldContent = [];
            } else if (descMatch) {
                if (currentField) {
                    currentProblem[currentField] = fieldContent.join('\n').trim();
                }
                currentField = 'description';
                fieldContent = descMatch[1] ? [descMatch[1]] : [];
            } else if (currentField) {
                fieldContent.push(line);
            }
        }
    }

    // Save last problem
    if (currentProblem) {
        if (currentField) {
            currentProblem[currentField] = fieldContent.join('\n').trim();
        }
        problems.push(currentProblem);
    }

    return problems;
}

/**
 * Loads problems.md
 *
 * @param {string} projectDir - Path to project directory
 * @param {Object} options - Options
 * @param {string} options.status - Filter by status (e.g., 'open', 'resolved')
 * @returns {Array} - Array of problem objects
 */
function loadProblems(projectDir, options = {}) {
    const problemsFile = path.join(projectDir, 'problems.md');

    if (!fs.existsSync(problemsFile)) {
        return [];
    }

    const content = fs.readFileSync(problemsFile, 'utf8');
    let problems = parseProblems(content);

    // Filter by status if specified
    if (options.status) {
        problems = problems.filter(p => p.status === options.status.toLowerCase());
    }

    return problems;
}

/**
 * Adds problem entry to problems.md
 *
 * @param {string} projectDir - Path to project directory
 * @param {Object} problem - Problem object
 * @param {string} problem.title - Problem title
 * @param {string} problem.description - Problem description
 * @param {string} problem.status - Status (default: 'open')
 * @param {string} problem.severity - Severity (default: 'medium')
 */
function addProblem(projectDir, problem) {
    const problemsFile = path.join(projectDir, 'problems.md');
    const projectName = path.basename(projectDir);

    // Read existing content
    let content = '';
    if (fs.existsSync(problemsFile)) {
        content = fs.readFileSync(problemsFile, 'utf8');
    }

    // Remove placeholder text if present
    content = content.replace(/\*No problems recorded yet\.\*\n?/, '');

    // Format the problem entry
    const status = problem.status || 'open';
    const severity = problem.severity || 'medium';
    const entry = `
### Problem: ${problem.title}

**Status:** ${status}
**Severity:** ${severity}
**Description:** ${problem.description}
`;

    // If file doesn't have header, add it
    if (!content.includes('# ') || !content.includes(' - Problems')) {
        content = `# ${projectName} - Problems\n`;
    }

    // Append problem
    content = content.trim() + '\n' + entry;

    try {
        fs.writeFileSync(problemsFile, content, 'utf8');
    } catch (err) {
        throw new Error(`Failed to write problems file '${problemsFile}': ${err.message}`);
    }
}

/**
 * Finds all projects in docs/plans/
 *
 * @param {string} baseDir - Base directory (usually repo root)
 * @returns {Array<{name: string, projectDir: string, hasState: boolean, hasProblems: boolean}>}
 */
function findProjects(baseDir) {
    const plansDir = path.join(baseDir, PLANS_DIR);
    const projects = [];

    if (!fs.existsSync(plansDir)) {
        return projects;
    }

    const entries = fs.readdirSync(plansDir, { withFileTypes: true });

    for (const entry of entries) {
        if (entry.isDirectory()) {
            const projectDir = path.join(plansDir, entry.name);

            // Check if it has the expected files
            const hasRequirement = fs.existsSync(path.join(projectDir, 'requirement.md'));
            const hasState = fs.existsSync(path.join(projectDir, 'state.md'));
            const hasProblems = fs.existsSync(path.join(projectDir, 'problems.md'));

            // Consider it a project if it has at least a requirement or state file
            if (hasRequirement || hasState) {
                projects.push({
                    name: entry.name,
                    projectDir,
                    hasState,
                    hasProblems
                });
            }
        }
    }

    return projects;
}

// CommonJS exports for Node.js compatibility
module.exports = {
    createProject,
    loadState,
    saveState,
    addCheckpoint,
    loadProblems,
    addProblem,
    findProjects,
    // Constants for external use
    PLANS_DIR,
    STATE_SECTIONS
};
