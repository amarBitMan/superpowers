---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## Project Context Integration

**Before starting, check for existing project context:**

1. Look for `docs/plans/*/requirement.md` in current directory
2. If found, load:
   - `requirement.md` - Original/enriched requirement
   - `research.md` - Prior research findings (if exists)
   - `state.md` - Current phase, prior decisions

3. If project context exists:
   ```
   Found project context: <name>

   Requirement: <first 100 chars>...
   Research: <summary if exists>
   Phase: <current phase>

   Continuing brainstorm with this context.
   ```

4. If no context: proceed normally (standalone brainstorm)

**After design complete:**

1. If project context exists:
   - Save design to `docs/plans/<project>/design.md`
   - Add checkpoint: "brainstorm: design complete"

2. If no project context:
   - Save to `docs/plans/YYYY-MM-DD-<topic>-design.md` (existing behavior)

## The Process

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
- **Context-aware** - Load existing project context if available
- **Checkpoint decisions** - Offer to checkpoint key design decisions
