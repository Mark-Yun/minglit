import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';
import '../../../utils/test_utils.dart';

/// Waits for all pending microtasks and async operations to complete.
Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

SettlementItemDetail _makeItem(String id) {
  final now = DateTime.now();
  return SettlementItemDetail(
    id: id,
    partnerId: 'partner-1',
    status: 'PENDING',
    grossAmount: 10000,
    platformFeeAmount: 500,
    pgFeeAmount: 200,
    vatAmount: 100,
    netAmount: 9200,
    currency: 'KRW',
    createdAt: now,
    updatedAt: now,
    retryable: false,
    retryCount: 0,
    histories: [],
    adjustments: [],
  );
}

void main() {
  late MockSettlementRepository mockRepo;
  late Partner fakePartner;

  setUp(() {
    mockRepo = MockSettlementRepository();
    fakePartner = const Partner(id: 'partner-1', name: 'Test Partner');
  });

  ProviderContainer makeContainer({
    Partner? partner,
    bool nullPartner = false,
    List<SettlementItemDetail>? items,
    Exception? loadError,
  }) {
    final resolvedPartner = nullPartner ? null : (partner ?? fakePartner);

    if (loadError != null) {
      when(
        () => mockRepo.getSettlementItems(
          partnerId: any(named: 'partnerId'),
          status: any(named: 'status'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(loadError);
    } else {
      when(
        () => mockRepo.getSettlementItems(
          partnerId: any(named: 'partnerId'),
          status: any(named: 'status'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => items ?? []);
    }

    return createContainer(
      overrides: [
        settlementRepositoryProvider.overrideWithValue(mockRepo),
        currentPartnerInfoProvider.overrideWith(
          (ref) async => resolvedPartner,
        ),
      ],
    );
  }

  group('SettlementListController', () {
    test('initial state has empty items and isLoading false', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final state = container.read(settlementListControllerProvider);
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.selectedStatus, isNull);
      expect(state.hasMore, isTrue);

      await pump();
    });

    test('loadMore success adds items to state', () async {
      final items = [_makeItem('item-1'), _makeItem('item-2')];
      final container = makeContainer(items: items);
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementListControllerProvider);
      await pump();

      final state = container.read(settlementListControllerProvider);
      expect(state.items.length, 2);
      expect(state.items.first.id, 'item-1');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test(
      'loadMore with fewer than pageSize items sets hasMore to false',
      () async {
        final items = List.generate(5, (i) => _makeItem('item-$i'));
        final container = makeContainer(items: items);
        final sub = container.listen(
          settlementListControllerProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        container.read(settlementListControllerProvider);
        await pump();

        final state = container.read(settlementListControllerProvider);
        expect(state.hasMore, isFalse);
      },
    );

    test('loadMore error sets error field', () async {
      final error = Exception('fetch failed');
      final container = makeContainer(loadError: error);
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementListControllerProvider);
      await pump();

      final state = container.read(settlementListControllerProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      expect(state.items, isEmpty);
    });

    test('loadMore with null partner stops loading without error', () async {
      final container = makeContainer(nullPartner: true);
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementListControllerProvider);
      await pump();

      final state = container.read(settlementListControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.items, isEmpty);
    });

    test('changeStatus resets items and changes filter', () async {
      final items = [_makeItem('item-1')];
      final container = makeContainer(items: items);
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      // Initial load
      container.read(settlementListControllerProvider);
      await pump();

      expect(
        container.read(settlementListControllerProvider).items.length,
        1,
      );

      // Change status — should reset items
      container
          .read(settlementListControllerProvider.notifier)
          .changeStatus('COMPLETED');

      final stateAfterChange = container.read(settlementListControllerProvider);
      expect(stateAfterChange.selectedStatus, 'COMPLETED');
      expect(stateAfterChange.items, isEmpty);
      expect(stateAfterChange.hasMore, isTrue);
      expect(stateAfterChange.error, isNull);

      // Wait for reload
      await pump();

      final stateAfterReload = container.read(settlementListControllerProvider);
      expect(stateAfterReload.isLoading, isFalse);
    });

    test('changeStatus to null clears filter', () async {
      final container = makeContainer();
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementListControllerProvider);
      await pump();

      container
          .read(settlementListControllerProvider.notifier)
          .changeStatus('PENDING');
      await pump();

      container
          .read(settlementListControllerProvider.notifier)
          .changeStatus(null);
      await pump();

      final state = container.read(settlementListControllerProvider);
      expect(state.selectedStatus, isNull);
    });

    test('refresh resets items and reloads', () async {
      final items = [_makeItem('item-1'), _makeItem('item-2')];
      final container = makeContainer(items: items);
      final sub = container.listen(
        settlementListControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(settlementListControllerProvider);
      await pump();

      expect(
        container.read(settlementListControllerProvider).items.length,
        2,
      );

      await container.read(settlementListControllerProvider.notifier).refresh();

      final state = container.read(settlementListControllerProvider);
      expect(state.items.length, 2);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });
}
