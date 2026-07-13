#!/usr/bin/env bash
#
# ralph.sh — a hardened "Ralph Wiggum" loop for Claude Code.
#
# Same core idea as ralph-minimal.sh (a fresh `claude --print` context every pass,
# with spec.md + implementation_plan.md as the only source of truth), but with the
# guardrails you need to actually leave it running:
#
#   • Stops when implementation_plan.md has zero unchecked "- [ ]" tasks.
#   • Max-iteration cap and optional wall-clock cap so it can't run away.
#   • Stall detection: aborts if no task gets checked off for N passes in a row
#     (a bad test or a wrong turn can otherwise burn tokens forever).
#   • Optional full-suite circuit breaker: after each completed task, runs
#     RALPH_FULL_TEST_CMD and STOPS the loop if it fails, so a regression can't cascade.
#   • Live, prettified streaming to your terminal (claude stream-json → jq); the raw
#     per-iteration stream is also saved to ./logs.
#   • Long-form, self-documenting flags. Configurable entirely via env vars.
#
# Usage:   ./ralph.sh
# Watch:   run it, watch a few passes, Ctrl+C, edit the spec, re-run. Repeat until
#          the spec is bulletproof — THEN walk away.
#
# Everything below is overridable, e.g.:
#   RALPH_MODEL=sonnet RALPH_MAX_ITERS=20 ./ralph.sh
#   RALPH_YOLO=1 ./ralph.sh            # unattended — SANDBOX ONLY (see README)

set -euo pipefail

# ---- Configuration (override via environment) ------------------------------
RALPH_PROMPT="${RALPH_PROMPT:-prompt.md}"                 # the per-iteration prompt
RALPH_PLAN="${RALPH_PLAN:-implementation_plan.md}"        # checkbox task list (source of truth for progress)
RALPH_SPEC="${RALPH_SPEC:-spec.md}"                       # spec (source of truth for intent)
RALPH_MODEL="${RALPH_MODEL:-opus}"                        # opus for quality; sonnet to save tokens; "" = CLI default
RALPH_MAX_ITERS="${RALPH_MAX_ITERS:-50}"                  # hard cap on iterations
RALPH_STALL_LIMIT="${RALPH_STALL_LIMIT:-3}"              # abort after this many no-progress passes
RALPH_SLEEP="${RALPH_SLEEP:-2}"                           # seconds between passes (breathing room for Ctrl+C)
RALPH_TIME_LIMIT="${RALPH_TIME_LIMIT:-0}"                 # wall-clock seconds; 0 = disabled
RALPH_YOLO="${RALPH_YOLO:-0}"                             # 1 = --dangerously-skip-permissions (unattended, sandbox only)
RALPH_LOG_DIR="${RALPH_LOG_DIR:-logs}"                    # where per-iteration logs go
RALPH_FULL_TEST_CMD="${RALPH_FULL_TEST_CMD:-}"           # after each completed task, run this full suite; loop EXITS if it fails. "" = skip

# ---- Pretty printing -------------------------------------------------------
if [ -t 1 ]; then
  c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_dim=$'\033[2m'
  c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_cyn=$'\033[36m'
else
  c_reset=''; c_bold=''; c_dim=''; c_grn=''; c_yel=''; c_red=''; c_cyn=''
fi
say()  { printf '%s\n' "${c_cyn}[ralph]${c_reset} $*"; }
warn() { printf '%s\n' "${c_yel}[ralph] WARN:${c_reset} $*" >&2; }
die()  { printf '%s\n' "${c_red}[ralph] ERROR:${c_reset} $*" >&2; exit 1; }

# ---- Count unchecked "- [ ]" tasks in the plan -----------------------------
count_unchecked() {
  local n
  n=$(grep -cE '^[[:space:]]*- \[ \]' "$RALPH_PLAN" 2>/dev/null || true)
  printf '%s' "${n:-0}"
}

# ---- Preflight -------------------------------------------------------------
command -v claude >/dev/null 2>&1 || die "the 'claude' CLI is not on PATH — install Claude Code first."
[ -f "$RALPH_PROMPT" ] || die "prompt file not found: $RALPH_PROMPT"
[ -f "$RALPH_PLAN" ]   || die "implementation plan not found: $RALPH_PLAN"
[ -f "$RALPH_SPEC" ]   || warn "spec file not found: $RALPH_SPEC — prompt.md should reference it."

mkdir -p "$RALPH_LOG_DIR"

# Permission flags. In headless (--print) mode, tools that need approval are
# skipped unless a permission mode allows them. `acceptEdits` lets Ralph write
# files but will NOT let it run shell commands (e.g. your test runner) unattended.
# A real overnight loop that runs tests needs RALPH_YOLO=1 — and a sandbox.
if [ "$RALPH_YOLO" = "1" ]; then
  perm_flags=(--dangerously-skip-permissions)
  warn "YOLO: --dangerously-skip-permissions is ON. Run ONLY in a sandbox / disposable env."
else
  perm_flags=(--permission-mode acceptEdits)
  say "${c_dim}Permission mode: acceptEdits. Ralph can edit files but will not run shell commands unattended.${c_reset}"
  say "${c_dim}For a fully unattended overnight run (tests, git, etc.), use RALPH_YOLO=1 in a sandbox.${c_reset}"
fi

model_flags=()
[ -n "$RALPH_MODEL" ] && model_flags=(--model "$RALPH_MODEL")

# ---- Terminal formatter ----------------------------------------------------
# The loop runs `claude --print --output-format stream-json`, which emits JSONL
# events in real time. `pretty` renders that as a readable live feed (assistant
# text, tool calls, iteration banners). Falls back to raw passthrough without jq.
if command -v jq >/dev/null 2>&1; then
  pretty() {
    jq -rR --unbuffered 'fromjson? // empty
      | if .type=="assistant" then (.message.content[]?
          | if .type=="text" then .text
            elif .type=="tool_use" then "  🔧 " + .name + " " + ((.input.file_path // .input.command // .input.pattern // .input.description // "") | tostring | .[0:80])
            else empty end)
        elif .type=="result" then "\n═══ iteration " + (.subtype // "?") + " ═══"
        else empty end'
  }
else
  warn "jq not found — terminal shows raw stream-json. For a readable live feed: 'brew install jq' (macOS) or 'apt-get install jq' (Linux)."
  pretty() { cat; }
fi

# ---- Graceful interrupt: print the watch → edit → restart playbook ---------
on_int() {
  printf '\n'
  warn "Interrupted. Ralph's playbook:"
  warn "  1) read the last log in ${RALPH_LOG_DIR}/"
  warn "  2) edit ${RALPH_SPEC} / ${RALPH_PLAN} to remove whatever confused it"
  warn "  3) re-run ./ralph.sh  (a fresh loop picks up from the checkboxes)"
  exit 130
}
trap on_int INT TERM

# ---- Main loop -------------------------------------------------------------
start_ts=$(date +%s)
iter=0
stall=0
prev_unchecked=$(count_unchecked)

say "${c_bold}Starting Ralph loop${c_reset}"
say "prompt=${RALPH_PROMPT}  plan=${RALPH_PLAN}  model=${RALPH_MODEL:-<cli default>}  max_iters=${RALPH_MAX_ITERS}"
say "unchecked tasks at start: ${c_bold}${prev_unchecked}${c_reset}"

if [ "$prev_unchecked" -eq 0 ]; then
  say "${c_grn}Nothing to do — no unchecked '- [ ]' tasks in ${RALPH_PLAN}.${c_reset}"
  exit 0
fi

while true; do
  # --- stop conditions (checked BEFORE spending another pass) ---
  remaining=$(count_unchecked)
  if [ "$remaining" -eq 0 ]; then
    say "${c_grn}All tasks complete — 0 unchecked tasks remain. Done after ${iter} iteration(s).${c_reset}"
    break
  fi
  if [ "$iter" -ge "$RALPH_MAX_ITERS" ]; then
    warn "Hit max iterations (${RALPH_MAX_ITERS}) with ${remaining} task(s) left. Stopping."
    break
  fi
  if [ "$RALPH_TIME_LIMIT" -gt 0 ]; then
    elapsed=$(( $(date +%s) - start_ts ))
    if [ "$elapsed" -ge "$RALPH_TIME_LIMIT" ]; then
      warn "Hit time limit (${RALPH_TIME_LIMIT}s) with ${remaining} task(s) left. Stopping."
      break
    fi
  fi

  iter=$(( iter + 1 ))
  log="${RALPH_LOG_DIR}/iter-$(printf '%03d' "$iter")-$(date +%Y%m%d-%H%M%S).log"
  say "${c_bold}Iteration ${iter}${c_reset} — ${remaining} task(s) remaining  ${c_dim}→ ${log}${c_reset}"

  # THE loop body. A brand-new `claude --print` process reads prompt.md from stdin,
  # giving it a fresh context every pass (the video's `cat prompt.md | claude -p`).
  # --output-format stream-json streams events live: the raw stream is tee'd to $log,
  # and `pretty` renders a readable feed to your terminal.
  set +e
  claude --print --verbose --output-format stream-json ${model_flags[@]+"${model_flags[@]}"} "${perm_flags[@]}" < "$RALPH_PROMPT" 2>&1 | tee "$log" | pretty
  rc=${PIPESTATUS[0]}
  set -e
  [ "$rc" -ne 0 ] && warn "claude exited non-zero (${rc}) on iteration ${iter} — see ${log}"

  # --- stall detection: did a checkbox actually get ticked this pass? ---
  now_unchecked=$(count_unchecked)
  if [ "$now_unchecked" -lt "$prev_unchecked" ]; then
    stall=0
    progressed=1
  else
    stall=$(( stall + 1 ))
    progressed=0
    warn "No task checked off this pass (${stall}/${RALPH_STALL_LIMIT} stalled)."
  fi
  prev_unchecked=$now_unchecked

  # --- circuit breaker: after a task completes, verify the FULL suite is green ---
  # A red suite means the just-checked task left (or introduced) a regression; stop
  # before it cascades into future passes. Opt-in via RALPH_FULL_TEST_CMD. Streamed
  # via tee (not piped through `tail`, which would buffer and look frozen); give it the
  # REAL command, not a shell alias like `p` (this runs non-interactively).
  if [ "$progressed" = "1" ] && [ -n "$RALPH_FULL_TEST_CMD" ]; then
    say "Verifying full suite: ${c_dim}${RALPH_FULL_TEST_CMD}${c_reset}"
    set +e
    eval "$RALPH_FULL_TEST_CMD" 2>&1 | tee -a "$log"
    test_rc=${PIPESTATUS[0]}
    set -e
    if [ "$test_rc" -ne 0 ]; then
      die "Full test suite FAILED (exit ${test_rc}) after iteration ${iter}. Stopping so the regression does not cascade.
       Read ${log}, fix the failing tests, then re-run."
    fi
    say "${c_grn}Full suite green.${c_reset}"
  fi

  if [ "$stall" -ge "$RALPH_STALL_LIMIT" ]; then
    die "No progress for ${RALPH_STALL_LIMIT} passes in a row. Stopping to avoid burning tokens.
       Read ${log}, fix ${RALPH_SPEC}/${RALPH_PLAN} (Ralph is probably confused or stuck on a bad test), then re-run."
  fi

  sleep "$RALPH_SLEEP"
done

# ---- Summary ---------------------------------------------------------------
elapsed=$(( $(date +%s) - start_ts ))
remaining=$(count_unchecked)
say "${c_bold}Ralph finished.${c_reset}  iterations=${iter}  elapsed=${elapsed}s  tasks_remaining=${remaining}"
if [ "$remaining" -eq 0 ]; then
  say "${c_grn}✔ implementation_plan.md is fully checked off.${c_reset}"
else
  say "${c_yel}➤ Review ${RALPH_LOG_DIR}/, edit the specs, and re-run to continue.${c_reset}"
fi
