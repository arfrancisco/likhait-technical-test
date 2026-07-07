# Frontend Architecture

React 18 + TypeScript + Vite. No global store, no router (despite a dependency on one — see `DECISIONS.md`).

## Component tree

```
App
├─ Sidebar                     (nav shell; only one page exists — "history")
└─ HistoryPage                 (owns all state: expenses, categories, selected year/month)
   ├─ YearNavigation
   ├─ MonthNavigation
   ├─ CategoryBreakdown         (collapsible per-category totals for the selected month)
   ├─ CalendarExpenseTable      (paginated table; owns its own edit/delete modals)
   │  └─ ExpenseForm            (shared by "Add Expense" and "Edit Expense")
   ├─ ExpenseForm                (in the "Add Expense" modal)
   └─ CategoryForm               (in the "Add Category" modal)
```

`ExpenseForm` and `CategoryForm` are both driven by hooks (`useExpenseForm` owns the expense form's state/validation/submit; `CategoryForm` keeps its own local state inline since it's a single field). Both forms are dumb otherwise — they render `vibes/` primitives (`TextField`, `SelectBox`, `Button`) and call the `onSubmit` prop they're given; `HistoryPage`/`CalendarExpenseTable` own what actually happens with the result (call the API, refresh state, close the modal).

## Data fetching

No React Query / SWR / global store — just `useState` + `useEffect` in `HistoryPage`, calling plain `fetch`-based functions in `services/api.ts`. Two independent effects: one refetches expenses whenever `selectedYear`/`selectedMonth` change, the other loads categories once on mount (categories aren't month-scoped, so no need to refetch them on every navigation — `loadCategories()` gets called again explicitly after a category is created).

`api.ts` is a flat set of exported functions (`fetchExpenses`, `getExpenses`, `fetchCategories`, `createCategory`, `createExpense`, `updateExpense`, `deleteExpense`) — no class, no client object, just functions that `fetch()` and return parsed JSON or throw.

## "Vibes" design system

`frontend/src/vibes/` is a small internal component library (`Button`, `Modal`, `TextField`, `SelectBox`, `Pagination`, plus a couple of unused pieces — see `DECISIONS.md`) backed by a hand-rolled color palette in `constants/colors.ts` (`COLORS.primary.p01`–`p10`, `secondary.s01`–`s10`, semantic aliases like `COLORS.danger`). Every component in the app styles itself with plain inline `style={{...}}` objects built from these tokens — no CSS modules, no styled-components, no Tailwind.

## Category handling

`frontend/src/constants/categoryEmojis.ts` maps known category names to an emoji, falling back to 📦 for anything it doesn't recognize (including any category created through the UI after FEATURE-001, since that list is never updated dynamically). Category *options* themselves are no longer hardcoded — `HistoryPage` fetches them from `GET /api/categories` into state and passes them down as a `categories: string[]` prop to `ExpenseForm`/`CalendarExpenseTable`, so a category created through the "Add Category" modal is immediately selectable without a page reload.

## Known gaps

- No test tooling installed at all (no Jest/Vitest/Cypress/Playwright in `package.json`) — the only test coverage for this app is the backend's RSpec suite plus manual/browser verification during development.
- Pagination (`CalendarExpenseTable`) is entirely client-side — the backend returns the full filtered result set and the table slices it into pages of 10 after the fact.

See `DECISIONS.md` for the reasoning behind the FEATURE-001/BONUS-001 approach and a few other things worth flagging.
