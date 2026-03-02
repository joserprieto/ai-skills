# Architecture Snippets

These snippets use **TypeScript as notation** — not as a language prescription. Each pattern applies
identically in any typed language. See the equivalence table in `SKILL.md` for translations to
Python, Go, Java, Rust, etc.

Each file demonstrates exactly ONE architectural pattern in 15–40 lines. Comments explain **why**,
not what.

## Frontend exception

`frontend-store-with-di.ts` is React/Zustand-specific and labeled as such. The dependency injection
principle transfers to other frameworks, but the implementation details (store factory, hooks) do
not.
