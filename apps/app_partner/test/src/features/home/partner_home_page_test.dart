// Smoke tests for PartnerHomePage v2 (Fix #2219).
//
// v2 is a notification-center feed replacing the old EventActionCard hero.
// These tests verify the new structure and guard against regressions.
import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/home/widgets/weekly_stats_row.dart';
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/logic/event_create_draft_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockPartnerHomeCoordinator extends Mock
    implements PartnerHomeCoordinator {}

class _EmptyNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

class _LoadedDashboardController extends PartnerDashboardController {
  @override
  PartnerDashboardState build() => _dashboardState;
}

PartnerDashboardState _dashboardState = const PartnerDashboardState(
  status: AsyncValue.data(null),
  hasAnyEvents: true,
  bankAccountReady: true,
  bankVerificationStatus: 'manual_review_approved',
);

Party _makeParty() {
  final now = DateTime(2030);
  return Party(
    id: 'party-1',
    partnerId: 'partner_1',
    title: '테스트 파티',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildPage({
  PartnerHomeCoordinator? coordinator,
  PartnerDashboardState? dashboardState,
}) {
  _dashboardState =
      dashboardState ??
      const PartnerDashboardState(
        status: AsyncValue.data(null),
        hasAnyEvents: true,
        bankAccountReady: true,
        bankVerificationStatus: 'manual_review_approved',
      );
  final coord = coordinator ?? _MockPartnerHomeCoordinator();
  when(coord.pushNotificationCenter).thenReturn(null);
  when(coord.pushBankAccount).thenReturn(null);
  when(() => coord.pushEventCreate(any())).thenReturn(null);
  return ProviderScope(
    overrides: [
      currentPartnerInfoProvider.overrideWith(
        (_) async => const Partner(id: 'partner_1', name: '테스트 파트너'),
      ),
      partnerHomeCoordinatorProvider.overrideWithValue(coord),
      partnerDashboardControllerProvider.overrideWith(
        _LoadedDashboardController.new,
      ),
      notificationListProvider.overrideWith(_EmptyNotificationList.new),
    ],
    child: const MaterialApp(home: PartnerHomePage()),
  );
}

void main() {
  group('PartnerHomePage', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets(
      'Fix #2354: AppBar shows PARTNER wordmark, not bare minglit logo',
      (tester) async {
        await tester.pumpWidget(_buildPage());
        await tester.pump();
        // partnerAppBarLogo() must render 'PARTNER' text in the AppBar.
        // If this fails, appBarLogo() was used instead of partnerAppBarLogo().
        expect(
          find.text('PARTNER'),
          findsOneWidget,
          reason: 'AppBar must show minglit · PARTNER wordmark',
        );
      },
    );

    testWidgets(
      'Fix #1950: WeeklyStatsRow is not rendered on PartnerHomePage',
      (tester) async {
        // Regression guard: WeeklyStatsRow was showing hardcoded ₩0 / 0%
        // because the backend API is not yet wired. It must stay hidden until
        // the API is implemented and real data is available.
        await tester.pumpWidget(_buildPage());
        await tester.pumpAndSettle();

        expect(
          find.byType(WeeklyStatsRow),
          findsNothing,
          reason: 'WeeklyStatsRow must not appear until backend API is wired',
        );
        expect(
          find.text('이번 주 성과'),
          findsNothing,
          reason:
              'Weekly stats header must not appear until backend API is wired',
        );
      },
    );

    testWidgets(
      'shows draft event resume card instead of first event CTA',
      (tester) async {
        final party = _makeParty();
        final draft = EventCreateDraft(
          id: 'draft-1',
          partyId: party.id,
          checkpointTabIndex: 1,
          startTime: DateTime(2030, 1, 1, 19),
          endTime: DateTime(2030, 1, 1, 22),
          maxParticipants: 20,
          title: '작성 중인 이벤트',
          description: const {},
          contactOptions: const {},
          entryGroups: const [],
          tickets: const [],
          recurrence: const RecurrenceSettingsState(),
          updatedAt: DateTime(2030, 1, 1, 18),
        );
        final coord = _MockPartnerHomeCoordinator();
        when(coord.pushNotificationCenter).thenReturn(null);
        when(() => coord.pushEventCreate(any())).thenReturn(null);

        await tester.pumpWidget(
          _buildPage(
            coordinator: coord,
            dashboardState: PartnerDashboardState(
              status: const AsyncValue.data(null),
              activeParties: [party],
              draftEvents: [draft],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('작성 중인 이벤트'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, '첫 이벤트 만들기'),
          findsNothing,
        );

        await tester.ensureVisible(find.text('작성 중인 이벤트'));
        await tester.tap(find.text('작성 중인 이벤트'));
        await tester.pump();

        verify(() => coord.pushEventCreate('party-1')).called(1);
      },
    );

    testWidgets('pending bank account todo opens BankAccountRoute owner', (
      tester,
    ) async {
      final coordinator = _MockPartnerHomeCoordinator();
      when(coordinator.pushNotificationCenter).thenReturn(null);
      when(coordinator.pushBankAccount).thenReturn(null);
      when(() => coordinator.pushEventCreate(any())).thenReturn(null);

      await tester.pumpWidget(
        _buildPage(
          coordinator: coordinator,
          dashboardState: const PartnerDashboardState(
            status: AsyncValue.data(null),
            hasAnyEvents: true,
            bankVerificationStatus: 'manual_review_pending',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('계좌 확인 중'), findsOneWidget);
      await tester.tap(find.text('계좌 확인 중'));

      verify(coordinator.pushBankAccount).called(1);
    });
  });
}
