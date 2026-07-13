# Ralph — per-iteration prompt

You are ONE iteration of an autonomous build loop. You have a FRESH context: the
only reliable memory of this project lives in `spec.md`, `implementation_plan.md`,
and the repository itself. Nothing from a "previous conversation" carries over —
those two files are the source of truth, not your context window.

Do exactly one task, well, then exit.

## Steps
1. Study `spec.md` thoroughly. It is the source of truth for WHAT to build and why.
2. Study `implementation_plan.md` thoroughly. It lists the tasks and their state.
3. Pick the single highest-leverage UNCHECKED task (`- [ ]`). Do ONLY that one.
4. Complete the task, following the repository's existing structure and conventions.
5. Write an unbiased unit test that would genuinely fail if the task were done
   wrong — not a test written to pass. Run it. For fast feedback, iterate against
   the NARROWEST test scope you have (a single file / package / module — usually
   seconds); only once that's green, run the full/slow suite ONCE as the final gate
   before marking the task done. Don't pay the whole-suite cost on every red pass.
   (If the loop sets a `RALPH_FULL_TEST_CMD` circuit-breaker, the harness runs the
   full suite for you — do only the scoped tests here.)

## Marking completion
- Only if the test passes: edit `implementation_plan.md` and change that task's
  `- [ ]` to `- [x]`. Add a one-line note beneath it if the next iteration needs
  to know something non-obvious.
- If the spec is ambiguous or contradictory, DO NOT guess. A wrong guess here
  poisons every future loop. Instead, record the decision in `spec.md` (or add a
  `> BLOCKED: <question>` note under the task) and stop.
- Do NOT start a second task. One task per iteration keeps context small and well
  under the "dumb zone" (~100k tokens), where quality falls off a cliff.

## Repository context & conventions
- Language: TypeScript, `strict: true`, never `any`. Runtime: Node.js. Tests: Vitest.
- Source in `src/`, organized BY DOMAIN (e.g. `src/account/`, `src/transaction/`),
  not by type. No `utils.ts` / `helpers.ts` catch-alls.
- Money is stored as integer minor units (cents). Never use floats for money.
- Do not add a dependency without recording why in `spec.md`.
- Keep each change atomic and self-contained so it could be reviewed on its own.

Now begin: study the specs, pick the highest-leverage unchecked task, and implement it.
