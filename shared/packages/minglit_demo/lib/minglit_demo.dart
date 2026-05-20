/// minglit_demo — Demo flavor fixtures + ProviderScope overrides.
///
/// Consumers:
///   - `apps/app_user/lib/main_demo.dart`
///   - `apps/app_partner/lib/main_demo.dart`
///   - `apps/app_user/integration_test/mds-emulator-render/` (per-screen builders)
///
/// Usage:
/// ```dart
/// ProviderScope(
///   overrides: demoOverrides(),
///   child: MyApp(),
/// )
/// ```
///
/// See docs/infra/app_demo/architecture.md for design rationale.
library;

// Public surface — keep this barrel minimal. fixtures are mostly internal
// (consumed by overrides), but they are exported for emulator-render
// per-screen builders that need to compose specific states.

export 'fixtures/demo_world.dart';
export 'fixtures/demo_users.dart';
export 'fixtures/demo_events.dart';
export 'fixtures/demo_parties.dart';
export 'fixtures/demo_tickets.dart';
export 'fixtures/demo_partners.dart';
export 'fixtures/demo_settlements.dart';
export 'fixtures/demo_misc.dart';

export 'overrides/demo_overrides.dart';
export 'overrides/poison_supabase_client.dart';
