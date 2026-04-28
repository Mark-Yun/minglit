# Known Migration Sequence Gaps

CI warns when a same-day migration sequence skips a number. Known intentional gaps are documented here.

| Gap | Reason |
|-----|--------|
| `20260322000003` | Intentional skip — accepted as harmless (Issue #1092) |
| `20260422000008` | Never authored — migration was planned but cancelled before commit (Issue #1968) |

If CI reports a new gap, confirm via `git log --all --full-history -- supabase/migrations/<date><seq>_*.sql`. If the file never existed (no git history), add a row here and close the loop.
