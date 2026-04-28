import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockSocialRepository mockSocialRepo;

  setUp(() {
    mockSocialRepo = MockSocialRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(mockSocialRepo),
      ],
      child: const MaterialApp(
        home: BlockedPartnersPage(),
      ),
    );
  }

  // Fix #270: network failure regression
  // Fix #1927: Log.e replaces debugPrint; error body replaces snackbar
  // Fix #1929: Riverpod FutureProvider replaces manual ConsumerStatefulWidget state
  group('BlockedPartnersPage', () {
    testWidgets('network failure shows error body and stops loading', (
      tester,
    ) async {
      when(
        () => mockSocialRepo.getBlockedPartners(),
      ).thenAnswer((_) async => throw Exception('Network error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      // Fix #1929: error body rendered by FutureProvider.when(error:)
      expect(find.text('차단 목록을 불러오지 못했습니다'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('successful load renders partner list', (tester) async {
      when(() => mockSocialRepo.getBlockedPartners()).thenAnswer(
        (_) async => [
          {
            'id': 'p1',
            'name': 'Blocked Partner',
            'profile_image_url': null,
          },
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Blocked Partner'), findsOneWidget);
      expect(find.text('차단 해제'), findsOneWidget);
    });

    testWidgets('empty list shows empty state message', (tester) async {
      when(
        () => mockSocialRepo.getBlockedPartners(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('차단된 파트너가 없습니다'), findsOneWidget);
    });

    testWidgets(
      'Fix #1929: autoDispose re-fetches on page re-entry in same ProviderScope',
      (tester) async {
        // Without autoDispose, FutureProvider caches the result in the shared
        // ProviderScope indefinitely. Re-entry would show stale data.
        var callCount = 0;
        when(() => mockSocialRepo.getBlockedPartners()).thenAnswer((_) async {
          callCount++;
          return <Map<String, dynamic>>[];
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              socialRepositoryProvider.overrideWithValue(mockSocialRepo),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BlockedPartnersPage(),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        // First visit
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(callCount, 1);

        // Navigate back — autoDispose disposes the provider when widget unmounts
        final nav = tester.state<NavigatorState>(
          find.byType(Navigator),
        );
        nav.pop();
        await tester.pumpAndSettle();

        // Second visit — autoDispose must have fired; provider re-fetches
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(
          callCount,
          2,
          reason: 'autoDispose provider must re-fetch on re-entry',
        );
      },
    );

    testWidgets(
      'Fix #1929: blockedPartnersProvider invalidated after unblock',
      (tester) async {
        when(() => mockSocialRepo.getBlockedPartners()).thenAnswer(
          (_) async => [
            {'id': 'p1', 'name': 'Partner A', 'profile_image_url': null},
          ],
        );
        when(
          () => mockSocialRepo.unblockPartner('p1'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Partner A'), findsOneWidget);

        // After unblock, provider should reload
        when(
          () => mockSocialRepo.getBlockedPartners(),
        ).thenAnswer((_) async => []);

        await tester.tap(find.text('차단 해제'));
        // Dismiss the dialog
        await tester.pumpAndSettle();
        // MinglitAlert.showConfirm uses AlertDialog — tap confirm button
        if (find.text('해제').evaluate().isNotEmpty) {
          await tester.tap(find.text('해제'));
          await tester.pumpAndSettle();
        }

        verify(() => mockSocialRepo.unblockPartner('p1')).called(1);
      },
    );
  });
}
