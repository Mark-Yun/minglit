# Draft: Minglit Major Development Sprint

## Requirements (confirmed)
- 4 missions spanning auth changes, DB testing, CI pipeline, and 11 pending feature tracks
- Mission 1 & 2 should complete before Mission 4 (safety net)
- Mission 3 can partially parallel with Mission 2
- Solo developer - automation is critical

## Technical Decisions
- Tech stack: Flutter (Riverpod 3 + GoRouter 17 + Freezed), Supabase, Deno 2, Next.js
- Both apps run in Flutter web via DevMap
- Local Supabase with seed data

## Research Findings
- [Pending agent results]

## Open Questions
- pgTAP vs Dart-based integration tests for DB testing?
- How to handle deep link URL access for non-auth routes?
- Priority order for 11 pending tracks?
- Test infrastructure for Flutter widgets/units?

## Scope Boundaries
- INCLUDE: All 4 missions as one integrated plan
- INCLUDE: Both app_user and app_partner where applicable
- EXCLUDE: Production deployment / release
