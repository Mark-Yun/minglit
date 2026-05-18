import 'package:supabase_flutter/supabase_flutter.dart';

/// A [SupabaseClient] stand-in that throws on every access.
///
/// Demo flavor Fake repositories pass this into `super(...)` constructor so
/// the parent Repository class has *something* to hold, but any attempt to
/// reach Supabase through it fails loudly. This surfaces gaps in the demo
/// override coverage immediately (a forgotten method override → crash, not
/// silent success).
///
/// **DO NOT replace with a no-op stub that returns empty data** — silent
/// success masks bugs. Loud failure is the design intent.
///
/// Acquired transitively via the `minglit_kit` dependency to avoid declaring
/// a direct `supabase_flutter` dependency in this package's pubspec
/// (per architecture.md "Dependency Rules" — types only, no SDK init).
class PoisonSupabaseClient implements SupabaseClient {
  const PoisonSupabaseClient();

  static const _message =
      'DEMO MODE: SupabaseClient was accessed directly. '
      'This means a Repository method is not overridden in minglit_demo. '
      'Add the missing override in lib/overrides/<domain>_overrides.dart '
      'and route data to a fixture in lib/fixtures/.';

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    '$_message Member: ${invocation.memberName}',
  );
}
