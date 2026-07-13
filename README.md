# Ralph Wiggum Loop — starter kit

A "Ralph Wiggum" loop is a dead-simple bash loop that hands a coding agent the same
prompt over and over, in a **fresh context each time**, until a stopping criteria is
met. It trades tokens for mental horsepower: state lives in files, not in the model's
context window, so the agent never has to compact and never rots into the "dumb zone."

> Endorsed as the "official explainer" by Geoffrey Huntley, who coined the technique.

This kit gives you a runnable example (the video's Budget Tracker) plus a hardened
loop you can actually leave running.

## Files

| File | What it is |
|------|-----------|
| `ralph.sh` | Hardened loop: stop condition, caps, stall detection, logging. For using. |
| `ralph-minimal.sh` | The canonical loop, exactly as in the video. For understanding. |
| `install.sh` | Installs `ralph` + `ralph-init` + the `/ralph-init` command once, so you never copy them again. |
| `ralph-init` | Scaffolds `prompt.md` / `spec.md` / `implementation_plan.md` templates into a new project. |
| `.claude/commands/ralph-init.md` | The `/ralph-init` Claude Code slash command — interviews you and writes the spec/plan. |
| `prompt.md` | The per-iteration prompt (the 5 steps + repo conventions). |
| `spec.md` | **What** to build and why — the source of truth for intent. |
| `implementation_plan.md` | Checkbox task list — the source of truth for progress. |
| `logs/` | One raw stream-json log per iteration (git-ignored). The terminal shows a live prettified feed; re-render an old log with `jq`. |

## Do I copy these files into every project? (No)

Short answer: **no — not the way you might picture it.** You never copy the
*script*, and the files you do create per project are ones you'd be writing anyway.
The files fall into three very different buckets:

| File | Reusable? | Reality |
|------|-----------|---------|
| `ralph.sh` / `ralph-init` | ✅ Fully generic | They're **tools**. Install once; never copy. `ralph` reads `prompt.md`/`spec.md`/`plan` from whatever directory you run it in. |
| `prompt.md` | 🟡 Template | The 5-step skeleton is reusable; only the "repo conventions" block changes per project. |
| `spec.md` + `implementation_plan.md` | ❌ Per-project | These *are* the project — the source of truth for what you're building. You're not copying them, you **generate fresh ones during planning** every time. That's the actual Ralph workflow. |

So the "copying" worry really only applies to the script — and the fix is to stop
treating it like a project file and treat it like a CLI tool.

### One-time setup (do this once, ever)

```bash
# 1. Clone this repo to a PERMANENT location — the installer symlinks back to it,
#    so this folder needs to stay put (see caveats below).
git clone https://github.com/davidkhardwick/ralph-loop.git ~/tools/ralph-loop

# 2. From INSIDE the clone, run the installer:
cd ~/tools/ralph-loop
./install.sh
#    → adds `ralph` + `ralph-init` to ~/.local/bin and installs the /ralph-init
#      Claude Code command. If it warns that ~/.local/bin isn't on your PATH,
#      follow the one-line fix it prints, then open a new shell.
#      Prefer standalone copies you can delete the clone after? use: ./install.sh --copy
```

### Per-project (repeat forever)

```bash
# 3. In ANY project, scaffold the per-project files:
cd ~/my-new-project
ralph-init                   # plain terminal: blank prompt.md / spec.md / implementation_plan.md
#   ...or, inside a Claude Code session:
#   /ralph-init a CLI todo app in Rust
#     → Claude interviews you (bidirectional planning) and writes a tailored spec + plan.

# 4. Read & sign off on spec.md + implementation_plan.md, then run the loop:
ralph
```

That's it — the interesting work (spec + plan) is always new, and the boring part
(the loop) is installed once and never copied.

**Three things to know before you start:**
- **`claude` (the Claude Code CLI) must be on your PATH.** The loop shells out to
  it and refuses to start without it. Check with `claude --version`.
- **Don't move or delete the clone.** The default install symlinks back to it, so
  removing it breaks `ralph`. Use `./install.sh --copy` if you want a standalone
  install that survives deleting the clone (trade-off: `git pull` won't auto-update).
- **`/ralph-init` appears when a Claude Code session starts.** If you installed
  during an open session, start a fresh one. The plain `ralph-init` (no slash)
  works in any terminal immediately.

## The core idea (in one picture)

```
  spec.md ─────────┐
                   ├──▶  [ fresh claude --print ]  ──▶  do 1 task, tick a box, EXIT
  implementation_  │              ▲                                  │
  plan.md ─────────┘              └──────────── loop ────────────────┘
```

Every pass is a **new process** = a **clean context**. It reads the two `.md` files,
does the single highest-leverage unchecked task, writes a test, ticks the checkbox,
and exits. Because each task is small, the context stays well under ~100k tokens
(the "dumb zone" for Opus-class models, where quality drops sharply) — so it never
compacts. Contrast with vibe-coding, where one long session drifts into that zone
and compaction summaries start poisoning the model.

## Try the demo (in this repo)

This repo is a ready-to-run example. Run it in place with `./ralph.sh` (no install
needed) to watch the loop build the Budget Tracker:

```bash
# 1. Requires the Claude Code CLI on your PATH (and jq for the readable live
#    feed — optional; without it you'll see raw stream-json instead):
claude --version
jq --version    # optional but recommended

# 2. Watch a few passes, learn the model's behavior:
./ralph.sh

# 3. When it does something dumb: Ctrl+C, edit spec.md / implementation_plan.md
#    to remove whatever confused it, and re-run. A fresh loop resumes from the
#    checkboxes. Repeat until the spec is bulletproof — THEN walk away.
```

`./ralph.sh` exits on its own when `implementation_plan.md` has zero `- [ ]` left.

> Here it's `./ralph.sh` because you're inside the repo. To use Ralph on your **own**
> projects, don't copy these files — install once (see
> [Do I copy these files into every project?](#do-i-copy-these-files-into-every-project-no))
> and use `ralph-init` + `ralph` from anywhere.

## The workflow: watch → edit → restart

The biggest skill in Ralph loops is **architecting the plan**, not the bash. So:

1. **Plan with bidirectional prompting.** Have Claude interview you and write
   `spec.md` + `implementation_plan.md`. Ask *it* questions too — it surfaces the
   implicit assumptions that become insidious bugs later.
2. **Sign off on every line** of both files. If you don't understand the plan, the
   implementation won't go how you expect — and errors *cascade and amplify*
   because each loop builds on the last.
3. **Watch the first runs**, Ctrl+C, fix the spec, restart. You're hardening the
   spec, not the code.
4. **Leave it running** once it's on track. Come back, run your own end-to-end
   tests, skim the code, decide whether to edit specs and go again.

## Running unattended (the honest version)

To run truly hands-off overnight, the agent has to edit files **and** run your test
runner without stopping to ask. In headless (`--print`) mode:

- **Default (`acceptEdits`)** — Ralph can write files but will **not** run shell
  commands unattended. Fine for watching; it will stall on "run the tests."
- **`RALPH_YOLO=1`** — adds `--dangerously-skip-permissions`. This is what real
  overnight runs need. **Only do this in a sandbox / disposable environment.**

```bash
RALPH_YOLO=1 ./ralph.sh
```

⚠️ **Blast radius & cost.** A logged-in agent with skipped permissions can touch
anything your account can. Run it in a container/VM, on a dedicated git branch you
can throw away, and **disable API-fallback billing** so a Max-plan run can't silently
overflow into pay-per-token charges. The stall guard and iteration cap here are your
seatbelts, not a substitute for a sandbox.

## Configuration

All settings are environment variables passed to the **`ralph` loop command in your
terminal** (defaults in parentheses).

### Where do these go? (`/ralph-init` vs `ralph`)

These two are different tools in different places — and the variables only apply to
the second one:

| | Where it runs | What it does | `RALPH_*` vars? |
|---|---|---|---|
| **`/ralph-init`** | *inside* a Claude Code session | Planning only — writes `spec.md` / `implementation_plan.md` / `prompt.md` | **No** — it ignores them. |
| **`ralph`** | your **terminal / shell** | Runs the actual loop (`claude --print` per pass) | **Yes** — set them here. |

So you don't pass env vars to `/ralph-init`. You plan with it, leave Claude Code,
then set the variables when you launch the loop from your shell:

```bash
# Inline, for one run:
RALPH_MODEL=sonnet ralph

# Or export them for the whole shell session:
export RALPH_MODEL=sonnet
export RALPH_MAX_ITERS=20
ralph
```

**`RALPH_MODEL` only sets the *loop's* model — not the planner's.** Which model
`/ralph-init` plans with is just your Claude Code session's model (change it with
`/model`). So the classic "plan with Opus, loop with Sonnet" split is:

```bash
# In Claude Code:   /model opus     then   /ralph-init <your idea>
# In your terminal: RALPH_MODEL=sonnet ralph
```

### Variables

| Var | Default | Meaning |
|-----|---------|---------|
| `RALPH_MODEL` | `opus` | Model for the loop. `sonnet` = cheaper/more passes; `""` = CLI default. |
| `RALPH_MAX_ITERS` | `50` | Hard cap on iterations. |
| `RALPH_STALL_LIMIT` | `3` | Abort after this many passes with no checkbox ticked. |
| `RALPH_TIME_LIMIT` | `0` | Wall-clock seconds; `0` disables. |
| `RALPH_SLEEP` | `2` | Seconds between passes. |
| `RALPH_YOLO` | `0` | `1` → `--dangerously-skip-permissions` (sandbox only). |
| `RALPH_PROMPT` / `RALPH_PLAN` / `RALPH_SPEC` | `prompt.md` / `implementation_plan.md` / `spec.md` | File names. |
| `RALPH_LOG_DIR` | `logs` | Per-iteration log directory. |
| `RALPH_FULL_TEST_CMD` | `""` | Full suite to run as a circuit breaker; the loop **exits** if it fails (a regression shouldn't cascade). Use the real command (e.g. `pnpm test:working`), not a shell alias like `p`. `""` disables. |
| `RALPH_FULL_TEST_EVERY` | `1` | Run `RALPH_FULL_TEST_CMD` every Nth completed task (and always on the last). E.g. `3` = every third task, to amortize a slow suite. |

```bash
# Cheaper exploration run with tight caps (installed globally):
RALPH_MODEL=sonnet RALPH_MAX_ITERS=15 RALPH_TIME_LIMIT=3600 ralph

# Same thing from inside this repo, before installing:
RALPH_MODEL=sonnet RALPH_MAX_ITERS=15 RALPH_TIME_LIMIT=3600 ./ralph.sh
```

> Prefer per-project settings that stick, instead of retyping them each run?
> `export` them in your shell, or ask for the optional `ralph.env` auto-load feature.

## Stop conditions & guardrails (built in)

- **Done:** zero `- [ ]` tasks remain → exit 0.
- **Max iterations:** `RALPH_MAX_ITERS` reached → stop.
- **Time limit:** `RALPH_TIME_LIMIT` reached → stop.
- **Stall:** no task checked off for `RALPH_STALL_LIMIT` passes → abort (this is
  your defense against a bad test or wrong turn poisoning every future loop).
- **Ctrl+C:** prints the watch → edit → restart playbook and exits cleanly.

## Three ways to use Ralph

1. **Autonomous build** — the main event. High leverage, but demands a bulletproof
   spec. Test thoroughly and read the code before anything ships.
2. **Exploration mode** — a back-burner research task, MVP, or feature spike. Spend
   5 minutes on a rough spec, launch, walk away. Nearly no downside: great for
   burning tokens the night before a Max-plan reset, since you'd lose them anyway.
3. **Brute-force testing** — point Ralph at a checklist and let it grind overnight:
   security vectors (XSS, SQLi, CSRF, IDOR, SSRF, RCE, …) or every user-facing UI
   path (login, checkout, search, forms) via a browser. 100+ manual hours → one
   overnight run.

## Gotchas (straight from the video's comments)

- **It sits waiting instead of moving to the next pass.** It isn't really in print
  mode. `-p` / `--print` means "print response and exit" — that exit is what advances
  the loop. `ralph.sh` uses `--print`.
- **It keeps asking clarifying questions.** Either your spec is ambiguous (fix the
  spec — that's the point of the watch phase), or you need unattended permissions
  (`RALPH_YOLO=1`, sandboxed).
- **Do NOT use the "Ralph Wiggum" plugin that loops inside one session.** It causes
  exactly the context rot and compaction this technique exists to avoid. The whole
  trick is a *fresh process per pass*.
- **Keep spec + plan brief.** If the spec is so big that a single pass hits the dumb
  zone, every iteration risks catastrophic failure. Small tasks, small context.

## Credits

- **Technique:** the "Ralph Wiggum" loop, coined by **Geoffrey Huntley**.
- **Explainer:** this kit distills the video **"You're Using Ralph Wiggum Loops
  WRONG"** by **Agentic Lab** — including its diagrams and comment-thread gotchas.
  Geoffrey Huntley endorsed that video as the official explainer of the technique.

All credit for the concept and the teaching goes to them; this repo is just a
runnable starter kit built from their explanation.

## License

[MIT](./LICENSE) © 2026 David Hardwick
