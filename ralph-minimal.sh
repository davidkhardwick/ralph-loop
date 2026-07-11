#!/usr/bin/env bash
#
# ralph-minimal.sh — the canonical Ralph Wiggum loop, exactly as shown in the video.
#
# Each pass spawns a BRAND-NEW `claude` process (a fresh context window) that reads
# prompt.md, does the single highest-leverage task, marks it complete, and EXITS.
# State lives in spec.md / implementation_plan.md — never in the context window.
#
# `-p` is --print: "Print response and exit." That exit is what hands control back
# to the loop so the next iteration starts clean. If claude ever just sits there
# waiting for input, it is NOT really in print mode.
#
# Stop it with Ctrl+C. There are NO guardrails here on purpose — this file exists
# to show the idea in its purest form. For stop-conditions, logging, unattended
# flags, and runaway protection, use ./ralph.sh instead.

while true; do
    cat prompt.md | claude -p
done
