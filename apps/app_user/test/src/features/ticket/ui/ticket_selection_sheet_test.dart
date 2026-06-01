import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockEventRepository mockEventRepo;
  late MockUserRepository mockUserRepo;
  late MockUser mockUser;

  final now = DateTime.now();
  final testTicket = Ticket(
    id: 'ticket-1',
    name: '일반',
    price: 10000,
    createdAt: now,
    updatedAt: now,
  );
  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: 'Test Event',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [testTicket],
    entryGroups: [],
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUserRepo = MockUserRepository();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user-1');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User'});

    when(
      () => mockEventRepo.getTicketBalanceStatus(any()),
    ).thenAnswer((_) async => <String, bool>{});

    // isVerified=true → 티켓 자격 검사 통과 → 티켓 자동 선택
    when(() => mockUserRepo.getUserProfile(any())).thenAnswer(
      (_) async => const UserProfile(
        id: 'user-1',
        name: 'Test',
        username: 'test',
        isVerified: true,
        gender: 'male',
        birthYear: 1995,
      ),
    );

    when(
      () => mockUserRepo.getApprovedVerificationIds(any()),
    ).thenAnswer((_) async => <String>[]);
  });

  Widget buildSheet() {
    return ProviderScope(
      overrides: [
        // 로그인 상태 + verified profile → TicketRecommendationUtil이 티켓 선택
        currentUserProvider.overrideWith((_) => mockUser),
        eventRepositoryProvider.overrideWith((_) => mockEventRepo),
        userRepositoryProvider.overrideWith((_) => mockUserRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TicketSelectionSheet(
            event: testEvent,
            onTicketSelected: (_, __) {},
          ),
        ),
      ),
    );
  }

  group('TicketSelectionSheet quantity controls', () {
    testWidgets(
      'does not show quantity controls before friends-together purchase ships',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pumpAndSettle();

        expect(find.text('수량'), findsNothing);
        expect(find.text('총 결제 금액'), findsNothing);
        expect(find.byTooltip('수량 감소'), findsNothing);
        expect(find.byTooltip('수량 증가'), findsNothing);
      },
    );
  });
}
