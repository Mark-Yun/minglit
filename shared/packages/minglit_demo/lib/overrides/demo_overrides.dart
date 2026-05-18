// Importing Override from riverpod's internal path because flutter_riverpod's
// public barrel doesn't re-export it (Riverpod 3 design choice). Required so
// the return type is `List<Override>` at runtime, not `List<dynamic>` —
// otherwise `ProviderScope(overrides: ...)` fails the runtime type check.
// `Override` is not exported via flutter_riverpod's public barrel in
// Riverpod 3, so we import it from the riverpod internals barrel where
// framework.dart (which contains it as a `part`) IS re-exported.
// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';

import 'auth_overrides.dart';
import 'event_overrides.dart';
import 'misc_overrides.dart';
import 'partner_overrides.dart';
import 'poison_supabase_client.dart';
import 'ticket_overrides.dart';

/// Returns the full list of ProviderScope overrides for demo flavor.
///
/// Both `apps/app_user/lib/main_demo.dart` and
/// `apps/app_partner/lib/main_demo.dart` call this from their
/// `ProviderScope(overrides: ...)`.
///
/// Apps add their own **app-local** overrides (e.g. `secureStorageProvider`
/// in app_user) on top of this list. See B2 in plan.md.
///
/// Future-extensible signature: optional named params allow demo variants
/// like `demoOverrides(empty: true)` without breaking call sites.
List<Override> demoOverrides({
  /// Reserved for P6+ — when true, return overrides that surface empty
  /// states (no events, no tickets, etc.) for testing edge cases.
  bool empty = false,
}) => [
  // Foundation: pin SupabaseClient to the poison stub. Every Repository
  // fake passes this into super(...) so the parent class can hold a client
  // without actually using it.
  supabaseClientProvider.overrideWith((_) => const PoisonSupabaseClient()),

  // Domain overrides — created by P1-1..P1-5 agents.
  ...authDomainOverrides(),
  ...eventDomainOverrides(),
  ...ticketDomainOverrides(),
  ...partnerDomainOverrides(),
  ...miscDomainOverrides(),
];
