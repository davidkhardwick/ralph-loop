---
description: Revise an existing Ralph loop's spec/plan non-destructively — read everything, interview about the change, apply targeted edits
argument-hint: [one-line description of what needs to change]
---

You are revising an EXISTING "Ralph Wiggum" loop project in the current directory.
This is the counterpart to /ralph-init: init authors artifacts from scratch;
revise treats the artifacts already on disk as the source of truth and makes the
smallest targeted edits that accomplish the change. You must NEVER regenerate a
file wholesale. Do NOT write application code and do NOT run the loop.

Requested change from the user (may be empty): $ARGUMENTS

## Step 0 — Verify this is an initialized Ralph project
spec.md AND implementation_plan.md must both exist in the current directory. If
either is missing, STOP and tell the user to run /ralph-init instead — there is
nothing to revise.

## Step 1 — Back up before touching anything
If the directory is a git repo with a clean working tree, git already has the
current state — skip backups. Otherwise copy each file you may edit to a
timestamped backup first:

    cp spec.md spec.md.bak-<YYYYMMDD-HHMMSS>
    cp implementation_plan.md implementation_plan.md.bak-<YYYYMMDD-HHMMSS>
    cp prompt.md prompt.md.bak-<YYYYMMDD-HHMMSS>   (if it exists)

## Step 2 — Read every line of the existing artifacts
Read spec.md, implementation_plan.md, and prompt.md in full — no partial reads.
Also read LEARNINGS.md and any spec-review documents if present; they record
hard-won decisions that a revision must not contradict. Build a picture of:
- What is already decided (Key decisions & constraints)
- What is already DONE (checked `- [x]` tasks — these are progress records)
- What the loop is currently working toward

## Step 3 — Interview about the change (not about the whole project)
Ask pointed questions until the change is unambiguous:
- What exactly should be different, and why now?
- Does it contradict any existing requirement, decision, or completed task?
  If yes, name the conflict out loud and make the user choose.
- Does it add scope, cut scope, or redirect scope?
- How will we know the revised piece works (acceptance criteria)?

Surface the assumptions YOU are making. Do not edit any file until the
ambiguities are resolved.

## Step 4 — Apply targeted edits
Rules, in priority order:
1. Use surgical edits (Edit tool), never a full-file rewrite.
2. NEVER delete or uncheck a completed `- [x]` task. If a done task is now
   obsolete, leave it checked and note the supersession beside it.
3. New work = new `- [ ]` tasks, each small enough for one fresh context and
   independently testable. Obsolete unchecked tasks are removed, with a line
   in "Notes for future iterations" saying what was dropped and why.
4. Spec changes go in the section they belong to; every resolved ambiguity or
   reversed decision is recorded in "Key decisions & constraints" with a
   one-line reason (append — do not erase the superseded decision, mark it).
5. Touch prompt.md only if the change alters repository conventions or the
   loop's standing instructions; otherwise leave it alone.
6. Keep the spec brief — if the revision grows it toward the ~100k-token
   "dumb zone", propose splitting instead of appending.

## Step 5 — Hand off with a diff, not a summary
Show the user exactly what changed (diff against git or the Step 1 backups).
Tell them to read every changed line and sign off before resuming the loop.
Remind them: if the loop had already started, restart it after a spec change
so no iteration runs on a stale plan — and watch the first pass or two.
