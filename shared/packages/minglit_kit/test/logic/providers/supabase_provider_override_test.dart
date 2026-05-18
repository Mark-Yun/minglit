// P0-0d: Proves that overriding supabaseClientProvider in a ProviderContainer
// propagates the fake client to all dependent repository providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/account_repository.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  test(
    'overriding supabaseClientProvider propagates to all repo providers',
    () {
      final fake = _FakeSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWith((_) => fake)],
      );
      addTearDown(container.dispose);

      // Each provider reads supabaseClientProvider and passes the result
      // straight into the repository constructor — verify the container
      // resolves each one without falling back to Supabase.instance.client.

      final accountRepo = container.read(accountRepositoryProvider);
      expect(accountRepo, isNotNull);
      expect(accountRepo, isA<AccountRepository>());

      final eventRepo = container.read(eventRepositoryProvider);
      expect(eventRepo, isNotNull);
      expect(eventRepo, isA<EventRepository>());

      final partyRepo = container.read(partyRepositoryProvider);
      expect(partyRepo, isNotNull);
      expect(partyRepo, isA<PartyRepository>());

      // Confirm the override is actually in effect — the container must return
      // the fake instance when supabaseClientProvider is read directly.
      final resolvedClient = container.read(supabaseClientProvider);
      expect(resolvedClient, same(fake));
    },
  );
}
