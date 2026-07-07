# Backend Decisions & Critique

Rationale behind the changes made across the five PRs, plus a few things noticed along the way that weren't in scope for any specific ticket.

## Why `date`, not `created_at` (BUG-001)

The index action sorted (and month-filtered) on `created_at` — when the row was saved — instead of `date`, the expense's actual date. Most people don't log an expense the same day it happened, so the two regularly disagree, and the bug report ("new expense doesn't show up at the top") was exactly that mismatch. The fix defaults to `date` but keeps the column selectable via `order_by`, since there's no reason to hardcode away a caller's ability to ask for creation order later.

## Why service objects, not an interactor gem or GraphQL

The brief complaint was "controllers do too much." The smallest fix that actually addresses that is a plain Ruby class per action with a `.call` entry point — no new dependency, no new query language, no abstract base class to learn. GraphQL in particular would have meant a schema/resolver layer on the backend *and* rewriting every frontend `fetch` call to a GraphQL client, for a two-resource CRUD app that doesn't have the kind of nested/overfetching problem GraphQL exists to solve. An `interactor`-style gem would add a dependency for something a five-line `Struct` already covers.

## Why validations were added only where the tickets required

There are no validations at all on `Expense`/`Category` beyond what BONUS-001 (future date) and FEATURE-001 (category uniqueness) specifically asked for. `expenses_spec.rb` has two pre-existing test cases — "with negative amounts" and "with empty descriptions" — that assert the expense **is created anyway**, i.e. they document the lack of validation rather than guard against it. Left alone rather than "fixed," since tightening those wasn't part of any ticket and would be a scope call for whoever owns this app, not something to sneak into an unrelated PR.

## Things noticed along the way, not fixed (flagging instead)

- **`expenses_spec.rb`'s "creates a new expense" test asserts `json["amount"]` equals the string `"150.5"`**, but `format_expense` returns `amount.to_f`, which serializes as the JSON number `150.5`. This test fails on `main` today, unrelated to anything in these PRs — left it alone since fixing it wasn't in scope for the PR that happened to touch that file.
- **`spec/factories/expenses.rb` referenced a `payer_name` field and left `category` nil** — neither works against the current schema (`payer_name` doesn't exist, `category` is a required association). Turned out to trace back to `db/init.sql`, which defined an entirely different, older version of the `expenses` table (see `docs/DECISIONS.md`-equivalent note in the Docker PR) — `payer_name` was a real column in that older schema, just never updated when the app moved to `date`-based tracking. Fixed the factory since PR3 was the first thing to actually use it.
- **CORS allows every origin and method** (`origins "*"`) — normal for local dev, but if this app were ever deployed, that's the first thing to lock down.
- **`Category` cascades deletes in Ruby** (`dependent: :destroy`) with no DB-level `ON DELETE` behavior backing it up — fine as long as everything goes through Rails, but a direct SQL delete or a different app touching this DB wouldn't get the same cascade.
