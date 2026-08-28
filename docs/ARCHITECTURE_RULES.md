# Architecture Rules

1. **Never read the entire repository unless absolutely required.** Use targeted search instead.
2. **Always identify the smallest affected feature first.**
3. **Search before reading large numbers of files.**
4. **Read only:** directly relevant files, immediate dependencies, required data services, and required shared types.
5. **Do not modify unrelated working systems.** Prefer surgical fixes over refactoring.
6. **Do not duplicate business logic.** Maintain a single source of truth.
7. **Do not create duplicate Firebase writes or duplicate financial calculations.**
8. **Do not change database architecture without understanding existing usage.**
9. **Do not delete code simply because it appears unused without verifying references.**
10. **Preserve backwards compatibility unless explicitly instructed otherwise.**
11. **Before making major changes, trace:** UI → state → business logic → service → Firebase → downstream consumers.
12. **Every financial change must be traced through:** Game → Bill → Payment → Transaction → Player Profile → Financial Reports → Firebase.
13. **Every game change must verify that other game types remain unaffected.**
14. **Never perform broad rewrites to fix a local bug.**
