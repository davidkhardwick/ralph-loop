# Feature: Budget Tracker

> This is a worked example (the one from the video). Replace it with your own
> spec. The rule that matters: **read every line and sign off on every line.**
> If the plan isn't bulletproof, errors cascade and amplify across loops.

## Problem
Users cannot see their spending across multiple accounts in one place. They have
to log into each bank separately and add things up by hand, so they never get a
clear, category-level picture of where their money actually goes.

## Goal
A single dashboard that imports transactions from multiple accounts and shows
spending broken down by category.

## Requirements
- Multi-account support (checking, savings, credit cards)
- Import transactions from CSV
- Category breakdown (e.g. groceries, rent, transport)
- Dashboard summarizing spend per category and per account

## Out of scope (v1)
- Live bank API integration
- Multi-currency
- Budgets and alerts (a later phase)

## Key decisions & constraints
_These exist to kill implicit assumptions before Ralph runs — the whole point of
bidirectional planning. Every ambiguity resolved here is a bug that never happens._

- **Accounts are FLAT, not nested.** A transaction belongs to exactly one account.
  (This is the "nested or flat?" question from the video, answered up front so no
  iteration ever has to guess.)
- Language: TypeScript, `strict: true`, no `any`. Runtime: Node.js. Tests: Vitest.
- Money is stored as integer cents, never floating point.
- Each transaction has exactly one category; uncategorized transactions fall back
  to a reserved `"uncategorized"` category rather than being dropped.
- CSV format (v1): `date,description,amount,account` — amount in dollars with two
  decimals, parsed into integer cents on import.

## Acceptance criteria
- Importing a CSV produces one Transaction per data row, attached to its Account.
- Every Transaction resolves to exactly one Category.
- The dashboard reports correct totals per category and per account for a known
  fixture, with no floating-point rounding errors.
