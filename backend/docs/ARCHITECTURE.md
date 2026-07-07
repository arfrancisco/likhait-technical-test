# Backend Architecture

Rails 7.2 API-only app. Two resources, no auth, MySQL 8.0.

## Data model

```
Category                     Expense
---------                    -------
id                           id
name (unique, required)      description (required)
                              amount (decimal 10,2, required)
                              date (required, can't be in the future)
                              category_id (FK -> categories.id)

Category has_many :expenses, dependent: :destroy
Expense  belongs_to :category
```

Deleting a category deletes its expenses (`dependent: :destroy`, handled in Ruby; there's no DB-level `ON DELETE CASCADE`).

## API endpoints

| Method | Path               | Params                                          | Response                         |
|--------|--------------------|--------------------------------------------------|-----------------------------------|
| GET    | `/api/categories`  | None                                             | `[{ id, name, created_at, updated_at }]`, alphabetical |
| POST   | `/api/categories`  | `category: { name }`                             | `201` + category, or `422` + `{ errors: [...] }` |
| GET    | `/api/expenses`    | `year`, `month` (optional filter), `order_by` (optional, `date` or `created_at`) | `[{ id, description, amount, category, date, created_at, updated_at }]`, sorted by `date` desc by default |
| POST   | `/api/expenses`    | `expense: { description, amount, category_id, date }` | `201` + expense, or `422` + `{ errors: [...] }` |
| PUT    | `/api/expenses/:id`| any subset of the create params                  | `200` + expense, or `422` + `{ errors: [...] }` |
| DELETE | `/api/expenses/:id`| None                                             | `204` |

`category` in the expense JSON is the category's **name** (a string), not its id. The frontend never needs to look up a category by id for display, only when submitting a form (see `frontend/docs/ARCHITECTURE.md`).

## Business rules

- **Expenses sort by `date` descending by default** (most recent expense date first), not by `created_at`. `order_by=created_at` is available as an explicit opt-out for callers that want the old behavior; any other value falls back to `date`.
- **Expense dates can't be in the future**: enforced on `Expense` via a model validation, and separately on the frontend via the date input's `max` attribute plus a client-side check (defense in depth: either layer alone would block it, but the backend one is the one that actually matters for correctness).
- **Category names must be present and unique**: enforced on `Category` via a model validation (the DB already has a unique index; the validation exists so a duplicate name comes back as a normal `422` instead of an unhandled 500).

## Request flow

Controllers are thin: they build permitted params, hand them to a service object, and render based on the result. See `app/services/`:

- `Expenses::Finder`: the `GET /api/expenses` sort/filter logic.
- `Expenses::Creator`, `Expenses::Updater`: the `POST`/`PUT /api/expenses` save-or-error logic.
- `Categories::Creator`: the `POST /api/categories` save-or-error logic.

`Categories#index` and `Expenses#destroy` stay as one-liners directly in the controller; there's no branching logic in either worth extracting into a service.

The create/update services return a `ServiceResult` struct (`success?`, `data`, `errors`) rather than raising or returning the record directly, so the controller has one consistent shape to render from.

## Known gaps

- **No authentication**: every endpoint is open; there's no concept of a user or ownership.
- **No server-side pagination**: `GET /api/expenses` returns the entire filtered result set; the frontend paginates client-side after the fact (`CalendarExpenseTable`, 10 rows/page). Fine at the current data volume (~4k seeded rows), but wouldn't scale indefinitely.
- **CORS is wide open** (`origins "*"`, all methods): reasonable for local dev, not something you'd want to ship as-is.

See `DECISIONS.md` for the reasoning behind the choices above and a few other things worth flagging that weren't part of any specific ticket.
