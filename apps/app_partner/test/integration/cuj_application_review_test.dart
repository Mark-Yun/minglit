// Ref #1072: IT-P02 — 신청 심사 (승인/거절) CUJ 통합 테스트
//
// 검증 포인트:
// 1. /applications 페이지 접근 (로그인 + hasPartner 필요)
// 2. 대기중/승인됨/거절됨 탭 렌더링
// 3. 승인/거절 버튼 노출
// 4. 빈 상태 메시지 표시
// 변형:
// - P02-V1: 정원 초과 → 승인 시 경고
// - P02-V2: 일괄 승인 버튼 노출
import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final testUser = MockUser();
  const testPartner = Partner(id: 'partner-p02', name: 'P02 Partner');
  final now = DateTime(2026, 4, 5, 14);

  setUp(() {
    when(() => testUser.id).thenReturn('user-p02');
    when(() => testUser.email).thenReturn('partner@example.com');
    when(() => testUser.userMetadata).thenReturn({});
  });

  group('IT-P02: 신청 심사 (승인/거절)', () {
    testWidgets('비로그인 사용자는 신청 관리에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          initialLocation: '/applications',
        ),
      );
      await tester.pump();
      await tester.pump();

      // /login으로 리다이렉트
      expect(find.byType(PartnerLoginPage), findsOneWidget);
    });

    testWidgets('신청 관리 페이지 — 3개 탭이 표시된다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventApplicationsGroupedProvider.overrideWith(
              (ref, _) async => <Event, List<EventApplication>>{},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('신청관리'), findsWidgets);
      expect(find.text('대기중'), findsOneWidget);
      expect(find.text('승인됨'), findsOneWidget);
      expect(find.text('거절됨'), findsOneWidget);
    });

    testWidgets('P02-V2: 대기 중 신청이 있을 때 전체 승인 버튼이 노출된다', (
      tester,
    ) async {
      final testEvent = Event(
        id: 'event-review-1',
        partyId: 'party-1',
        title: '심사 이벤트',
        startTime: now.add(const Duration(hours: 3)),
        endTime: now.add(const Duration(hours: 5)),
        createdAt: now,
        updatedAt: now,
        currentParticipants: 2,
      );

      EventApplication makeApp(String id) => EventApplication(
        id: id,
        eventId: testEvent.id,
        ticketId: 'ticket-1',
        userId: 'applicant-$id',
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
        user: UserProfile(
          id: 'applicant-$id',
          name: '신청자$id',
          username: 'applicant$id',
        ),
      );

      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventApplicationsGroupedProvider.overrideWith((ref, params) async {
              if (params.statusFilter.contains('pending')) {
                return {
                  testEvent: [makeApp('1'), makeApp('2')],
                };
              }
              return <Event, List<EventApplication>>{};
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('전체 승인 (2건)'), findsOneWidget);
    });

    testWidgets('빈 상태 — 대기 중인 신청이 없을 때 안내 메시지 표시', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventApplicationsGroupedProvider.overrideWith(
              (ref, _) async => <Event, List<EventApplication>>{},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('대기 중인 신청이 없습니다'), findsOneWidget);
    });

    testWidgets('승인/거절 버튼이 대기중 탭에 표시된다', (tester) async {
      final testEvent = Event(
        id: 'event-review-2',
        partyId: 'party-1',
        title: '심사 이벤트 2',
        startTime: now.add(const Duration(hours: 3)),
        endTime: now.add(const Duration(hours: 5)),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventApplicationsGroupedProvider.overrideWith((ref, params) async {
              if (params.statusFilter.contains('pending')) {
                return {
                  testEvent: [
                    EventApplication(
                      id: 'app-btn-1',
                      eventId: testEvent.id,
                      ticketId: 'ticket-1',
                      userId: 'applicant-1',
                      status: 'pending',
                      createdAt: now,
                      updatedAt: now,
                      user: const UserProfile(
                        id: 'applicant-1',
                        name: '신청자A',
                        username: 'applicanta',
                      ),
                    ),
                  ],
                };
              }
              return <Event, List<EventApplication>>{};
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('승인됨 탭 — 파트너가 처리한 신청이 표시된다', (tester) async {
      final testEvent = Event(
        id: 'event-approved',
        partyId: 'party-1',
        title: '승인 이벤트',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventApplicationsGroupedProvider.overrideWith((ref, params) async {
              if (params.statusFilter.contains('approved')) {
                return {
                  testEvent: [
                    EventApplication(
                      id: 'app-approved-1',
                      eventId: testEvent.id,
                      ticketId: 'ticket-1',
                      userId: 'approved-user-1',
                      status: 'approved',
                      createdAt: now,
                      updatedAt: now,
                      user: const UserProfile(
                        id: 'approved-user-1',
                        name: '승인된 유저',
                        username: 'approveduser',
                      ),
                    ),
                  ],
                };
              }
              return <Event, List<EventApplication>>{};
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 승인됨 탭으로 이동
      await tester.tap(find.text('승인됨'));
      await tester.pumpAndSettle();

      expect(find.text('승인된 유저'), findsOneWidget);
    });
  });
}
