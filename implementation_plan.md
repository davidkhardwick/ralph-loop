# Implementation Plan

Each unchecked `- [ ]` below is exactly one Ralph iteration. Keep tasks small so a
single fresh context can finish one without approaching the "dumb zone" (~100k
tokens). An iteration marks a task done by turning `- [ ]` into `- [x]` — and only
after its unit test passes.

`ralph.sh` stops automatically when zero `- [ ]` lines remain.

- [ ] Create data models: `Account`, `Transaction`, `Category` with strict types (money as integer cents)
- [ ] Build CSV import: parse `date,description,amount,account` rows into `Transaction`s attached to `Account`s
- [ ] Add category logic: assign each `Transaction` exactly one `Category`, defaulting to `"uncategorized"`
- [ ] Create dashboard aggregation: totals per category and per account, returned as a typed summary
- [ ] Write an end-to-end test: import a fixture CSV → categorize → assert dashboard totals (no rounding errors)

## Notes for future iterations
_(Ralph appends anything the next pass must know here.)_
