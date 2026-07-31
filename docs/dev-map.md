# Dev Map — singbox-cli

> Project structure and conventions navigation. **Update this whenever you add / move / remove a module.**
>
> The developer agent reads this before writing code, so it doesn't reinvent existing patterns.

## Folder layout

(Update as the project grows.)

```
singbox-cli/
├── (project root)
├── .claude/        ← AI configuration (do not commit secrets here)
├── docs/           ← Specs, features, this map, task board
├── scripts/        ← verify_all, baselines, sync helpers
└── (source folders go here)
```

## Where features live

| Feature area | Files | Convention |
|---|---|---|
| (empty — fill in as you build) | | |

## Reusable utilities

| Need | Existing | File | Notes |
|---|---|---|---|
| (empty — fill in as you build) | | | |

## Patterns to follow

(Examples to add as you discover them:)

- "All HTTP errors use the `AppError` class in `src/errors.ts`."
- "DB migrations live in `migrations/` and are applied by `scripts/migrate.sh`."
- "Tests for `src/X.ts` live at `tests/X.test.ts`."

## Patterns to avoid

(Examples to add as you discover them:)

- "Don't import server code from client code."
- "Don't write raw SQL in route handlers; use the `OrdersRepo` class."
