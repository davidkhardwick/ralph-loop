---
description: Plan a new Ralph loop — interview the user, then write spec.md + implementation_plan.md + prompt.md
argument-hint: [one-line description of what you want to build]
---

You are setting up a new "Ralph Wiggum" loop project in the current directory.
Your job is the PLANNING phase only — the highest-leverage part of Ralph. Do NOT
write application code and do NOT run the loop. Produce a bulletproof spec and plan.

Seed idea from the user (may be empty): $ARGUMENTS

## Step 1 — Bidirectional planning (this is the whole point)
Interview the user to remove implicit assumptions before any code is written. Ask
pointed questions — and surface the assumptions YOU are making that would have
seemed obvious, because those are exactly where insidious bugs come from. Cover at
least:
- The core problem and who has it
- Concrete requirements, and explicit out-of-scope items
- Data model / key entities and their relationships — resolve ambiguities like
  "nested vs flat?" NOW, not mid-loop
- Language, runtime, test framework, and any hard constraints
- Acceptance criteria: how we'll know each piece works

Keep asking until you and the user are genuinely on the same page. Do not write any
files until the ambiguities are resolved.

## Step 2 — Write spec.md (source of truth for WHAT to build)
Sections: Problem, Goal, Requirements, Out of scope, Key decisions & constraints
(record every resolved ambiguity here), Acceptance criteria. Keep it brief — a spec
so big that a single loop hits the "dumb zone" (~100k tokens) will fail
catastrophically.

## Step 3 — Write implementation_plan.md (source of truth for PROGRESS)
A short list of `- [ ]` checkbox tasks, each small enough to finish in one fresh
context and each independently testable. End with a "Notes for future iterations"
section. The loop stops when zero `- [ ]` remain.

## Step 4 — Ensure prompt.md exists
If prompt.md is not already present, create it from the standard Ralph template:
the five steps (study spec → study plan → pick the highest-leverage unchecked task
→ complete it → write an unbiased unit test), plus a "Repository context &
conventions" section filled in from what you learned in Step 1.

## Step 5 — Hand off
Tell the user to READ EVERY LINE of spec.md and implementation_plan.md and sign off
before running anything. Then give them the command to start:

    ralph        (or ./ralph.sh if it isn't installed globally)

Remind them to watch the first few passes and, if it goes off track,
Ctrl+C → edit the spec → restart until it's reliably on track.
