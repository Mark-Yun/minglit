// Fix #2358: TicketSelectionSheet 수량 stepper IconButton tooltip 회귀 가드.
//
// buildQuantityStepper()의 − / + IconButton에 tooltip이 없으면
// uidump에서 NAF="true" content-desc="" 로 캡처되어 스크린리더 접근 불가.
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

    // isVerified=true → 티켓 자격 검사 통과 → 티켓 자동 선택 → 수량 stepper 노출
    when(
      () => mockUserRepo.getUserProfile(any()),
    ).thenAnswer(
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

  group('TicketSelectionSheet quantity stepper', () {
    testWidgets(
      'Fix #2358: − 버튼에 tooltip "수량 감소"가 존재한다',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pumpAndSettle();

        expect(
          find.byTooltip('수량 감소'),
          findsOneWidget,
          reason: '수량 감소 IconButton에 tooltip이 없으면 NAF="true" 회귀',
        );
      },
    );

    testWidgets(
      'Fix #2358: + 버튼에 tooltip "수량 증가"가 존재한다',
      (tester) async {
        await tester.pumpWidget(buildSheet());
        await tester.pumpAndSettle();

        expect(
          find.byTooltip('수량 증가'),
          findsOneWidget,
          reason: '수량 증가 IconButton에 tooltip이 없으면 NAF="true" 회귀',
        );
      },
    );
  });
}
