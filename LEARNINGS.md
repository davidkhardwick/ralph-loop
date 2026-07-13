# Learnings — review queue

Append-only capture of **durable, non-obvious** learnings surfaced while building, staged for
**human review**. This file is NOT a source of truth — `spec.md`, `implementation_plan.md`,
`prompt.md`, and your repo's `CLAUDE.md` are. Its only job is to queue learnings so a human can
decide what graduates into those docs.

## How this works
- Each loop iteration appends an entry below when it discovers something a future pass or feature
  would waste time rediscovering (see `prompt.md` → "Capturing learnings").
- **You (human)** review the queue, promote the worthwhile ones into the suggested home, and mark
  each `promoted` or `rejected` (or delete it). Prune regularly so it stays scannable.
- Keep entries to genuinely reusable facts — not routine implementation detail.

## Categories → typical home
| Category | Typical home | Notes |
| :-- | :-- | :-- |
| **Codebase-wide fact** | `CLAUDE.md` | Auto-loaded every pass + inherited by future work (e.g. "public endpoints resolve the tenant manually"). |
| **Resolved ambiguity** | `spec.md` | A gap the spec left open that got settled. Human should ratify. |
| **Product decision** | `spec.md` | A behaviour or scope call. |
| **Invariant** | a test/assertion (+ `CLAUDE.md` if broad) | Best captured as enforced code, not just prose. |
| **Convention / house style** | `prompt.md` or `CLAUDE.md` | How this codebase does a thing. |
| **Tooling / process** | `prompt.md` or `CLAUDE.md` | A build/test/command quirk. |
| **Loop-scoped follow-up** | `implementation_plan.md` → Notes | Transient, next-pass hint — put it THERE, not here. |

## Entry format
Append newest at the bottom of the Log, one block per learning:

```
### <category> — <task id>
- **Home:** <CLAUDE.md | spec.md | prompt.md | implementation_plan.md | code/test>
- **Learning:** <1–2 lines, specific and actionable>
- **Evidence:** <file:line or what surfaced it>     (optional)
- **Status:** proposed        <!-- human sets: promoted | rejected -->
```

---

## Log
<!-- iterations append entries below this line -->
