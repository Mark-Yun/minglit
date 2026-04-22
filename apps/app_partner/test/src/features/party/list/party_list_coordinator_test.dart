import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeGoRouter extends Fake implements GoRouter {
  final List<String> pushed = [];

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async {
    pushed.add(location);
    return null;
  }
}

void main() {
  group('PartyListCoordinator (#1680)', () {
    ProviderContainer buildContainer(FakeGoRouter fakeRouter) {
      return ProviderContainer(
        overrides: [goRouterProvider.overrideWithValue(fakeRouter)],
      );
    }

    // Regression: context.push() discards async errors via unawaited() — catch
    // block never reached. GoRouter instance must be used directly.
    test('goToCreate pushes /more/parties/create via GoRouter instance', () {
      final fakeRouter = FakeGoRouter();
      final container = buildContainer(fakeRouter);
      addTearDown(container.dispose);

      container.read(partyListCoordinatorProvider).goToCreate();

      expect(fakeRouter.pushed, [const PartyCreateRoute().location]);
    });

    test('goToDetail pushes /more/parties/:id via GoRouter instance', () {
      const partyId = 'party-abc';
      final fakeRouter = FakeGoRouter();
      final container = buildContainer(fakeRouter);
      addTearDown(container.dispose);

      container.read(partyListCoordinatorProvider).goToDetail(partyId);

      expect(
        fakeRouter.pushed,
        [const PartyDetailRoute(partyId: partyId).location],
      );
    });
  });
}
