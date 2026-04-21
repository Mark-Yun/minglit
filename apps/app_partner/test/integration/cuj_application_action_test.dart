// Ref #1316: IT-P06 — 참가 신청 승인/거부 동작 통합 테스트
//
// 검증 포인트:
// 1. 대기중 탭 → 신청 리스트 + 승인/거부 버튼 렌더링
// 2. 개별 승인 → approveApplication() 호출 + "승인되었습니다" SnackBar
// 3. 개별 거부 → 거절 사유 다이얼로그 → rejectApplication() 호출 + SnackBar
// 4. 전체 승인 → 확인 다이얼로그 → bulkApproveApplications() 호출
// 5. 이벤트 정원 표시 — header에 현재/최대 인원 렌더링
// 6. 네트워크 에러 → 에러 메시지 + 다시 시도 버튼 렌더링
import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/golden_capture.dart';
import 'utils/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    registerFallbackValue('');
  });

  final testUser = MockUser();
  const testPartner = Partner(id: 'partner-p06', name: 'P06 Partner');
  final now = DateTime(2026, 4, 5, 14);

  setUp(() {
    when(() => testUser.id).thenReturn('user-p06');
    when(() => testUser.email).thenReturn('p06@example.com');
    when(() => testUser.userMetadata).thenReturn({});
  });

  // ─── 공통 테스트 데이터 ──────────────────────────────────────────────────

  Event makeEvent({
    String id = 'event-p06-1',
    String title = 'P06 테스트 이벤트',
    int currentParticipants = 2,
    int maxParticipants = 10,
  }) => Event(
    id: id,
    partyId: 'party-1',
    title: title,
    startTime: now.add(const Duration(hours: 3)),
    endTime: now.add(const Duration(hours: 5)),
    createdAt: now,
    updatedAt: now,
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
  );

  EventApplication makeApp(String id, {String status = 'pending'}) =>
      EventApplication(
        id: id,
        eventId: 'event-p06-1',
        ticketId: 'ticket-$id',
        userId: 'applicant-$id',
        status: status,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
        user: UserProfile(
          id: 'applicant-$id',
          name: '신청자$id',
          username: 'applicant$id',
        ),
      );

  // ─── TC1: 대기중 탭 렌더링 ──────────────────────────────────────────────

  group('IT-P06: 대기중 탭 렌더링', () {
    testWidgets('대기중 탭에 신청자 목록과 승인/거부 버튼이 표시된다', (tester) async {
      final testEvent = makeEvent();
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

      expect(find.text('신청자1'), findsOneWidget);
      expect(find.text('신청자2'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });
  });

  // ─── TC2: 개별 승인 ──────────────────────────────────────────────────────

  group('IT-P06: 개별 승인', () {
    testWidgets('승인 버튼 탭 → approveApplication() 호출 + SnackBar 표시', (
      tester,
    ) async {
      final capture = GoldenCapture('cuj_p02a');
      final mockEventRepo = MockEventRepository();
      when(
        () => mockEventRepo.approveApplication(
          applicationId: any(named: 'applicationId'),
        ),
      ).thenAnswer((_) async {});

      final testEvent = makeEvent();
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/applications',
          additionalOverrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            eventApplicationsGroupedProvider.overrideWith((ref, params) async {
              if (params.statusFilter.contains('pending')) {
                return {
                  testEvent: [makeApp('approve-1')],
                };
              }
              return <Event, List<EventApplication>>{};
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await capture.before(tester, 0);

      // 승인 버튼 탭
      await tester.tap(find.byIcon(Icons.check).first);
      // Fix #1677: pumpAndSettle() hangs here because approveApplication()
      // calls ref.invalidate(eventApplicationsGroupedProvider), which puts
      // the provider into loading state (CircularProgressIndicator with
      // repeat() animation), preventing pumpAndSettle() from ever settling.
      // Use bounded pump sequence: dispatch tap → resolve mock → settle UI.
      // Note: unlike TC3/TC4 (_showRejectDialog uses addPostFrameCallback),
      // _approve() calls showSnackBar + ref.invalidate() synchronously after
      // the async approveApplication() call, so both effects happen in the
      // same frame when the mock resolves.
      await tester.pump(); // dispatch tap, _approve() starts and suspends
      await tester
          .pump(); // mock resolves → showSnackBar + ref.invalidate() (synchronous, same frame)
      await tester
          .pump(); // SnackBar enters tree, providers switch to loading state
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // mocks resolve → data state

      await capture.after(tester, 1);

      verify(
        () => mockEventRepo.approveApplication(applicationId: 'approve-1'),
      ).called(1);
      expect(find.text('승인되었습니다'), findsOneWidget);
    });
  });

  // ─── TC3: 개별 거부 ──────────────────────────────────────────────────────
  // 다이얼로그 테스트는 GoRouter 없이 직접 위젯을 마운트하는 방식으로 구현.
  // MaterialApp.router + GoRouter에서 showDialog가 올바른 Navigator를
  // 찾지 못하는 경우가 있어 위젯 레벨 접근을 사용.

  group('IT-P06: 개별 거부', () {
    Widget buildActionPage({
      required MockEventRepository mockRepo,
      required Event event,
      required List<EventApplication> pendingApps,
    }) {
      return ProviderScope(
        overrides: [
          currentPartnerInfoProvider.overrideWith(
            (ref) async => testPartner,
          ),
          eventRepositoryProvider.overrideWithValue(mockRepo),
          eventApplicationsGroupedProvider.overrideWith(
            (ref, params) async {
              if (params.statusFilter.contains('pending')) {
                return {event: pendingApps};
              }
              return <Event, List<EventApplication>>{};
            },
          ),
        ],
        child: const MaterialApp(home: EventApplicationManagePage()),
      );
    }

    testWidgets('거부 버튼 탭 → 사유 다이얼로그 → rejectApplication() 호출 + SnackBar', (
      tester,
    ) async {
      final capture = GoldenCapture('cuj_p02a');
      final mockEventRepo = MockEventRepository();
      when(
        () => mockEventRepo.rejectApplication(
          applicationId: any(named: 'applicationId'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildActionPage(
          mockRepo: mockEventRepo,
          event: makeEvent(),
          pendingApps: [makeApp('reject-1')],
        ),
      );
      await tester.pumpAndSettle();

      // 거부 버튼 탭 → 다이얼로그 표시
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      await capture.before(tester, 2);

      expect(find.text('신청 거절'), findsOneWidget);

      // 거절 사유 입력
      await tester.enterText(find.byType(TextField), '정원 초과');
      await tester.pump();

      // 거절 버튼 탭
      await tester.tap(find.widgetWithText(FilledButton, '거절'));
      // Fix #1677: same pumpAndSettle() hang — rejectApplication() causes
      // deferred ref.invalidate() via addPostFrameCallback → CircularProgressIndicator
      await tester.pump(); // dispatch tap, rejectApplication() starts
      await tester
          .pump(); // mock resolves → showSnackBar + schedules deferred invalidate
      await tester.pump(); // deferred invalidate fires → providers loading
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // mocks resolve → data state

      await capture.after(tester, 3);

      verify(
        () => mockEventRepo.rejectApplication(
          applicationId: 'reject-1',
          reason: '정원 초과',
        ),
      ).called(1);
      expect(find.text('거절되었습니다'), findsOneWidget);
    });

    testWidgets('거부 다이얼로그 — 사유 없이 확인 시 rejectApplication() 미호출', (
      tester,
    ) async {
      final mockEventRepo = MockEventRepository();

      await tester.pumpWidget(
        buildActionPage(
          mockRepo: mockEventRepo,
          event: makeEvent(),
          pendingApps: [makeApp('reject-empty')],
        ),
      );
      await tester.pumpAndSettle();

      // 거부 버튼 탭 → 다이얼로그
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // 사유 없이 거절 버튼 탭
      await tester.tap(find.widgetWithText(FilledButton, '거절'));
      await tester.pumpAndSettle();

      // 빈 사유면 API 호출 없음
      verifyNever(
        () => mockEventRepo.rejectApplication(
          applicationId: any(named: 'applicationId'),
          reason: any(named: 'reason'),
        ),
      );
    });
  });

  // ─── TC4: 전체 승인 ──────────────────────────────────────────────────────

  group('IT-P06: 전체 승인', () {
    testWidgets('전체 승인 버튼 탭 → 확인 다이얼로그 → bulkApproveApplications() 호출', (
      tester,
    ) async {
      final mockEventRepo = MockEventRepository();
      when(
        () => mockEventRepo.bulkApproveApplications(
          eventId: any(named: 'eventId'),
        ),
      ).thenAnswer((_) async {});

      final testEvent = makeEvent();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            eventApplicationsGroupedProvider.overrideWith(
              (ref, params) async {
                if (params.statusFilter.contains('pending')) {
                  return {
                    testEvent: [makeApp('bulk-1'), makeApp('bulk-2')],
                  };
                }
                return <Event, List<EventApplication>>{};
              },
            ),
          ],
          child: const MaterialApp(home: EventApplicationManagePage()),
        ),
      );
      await tester.pumpAndSettle();

      // 전체 승인 버튼 탭
      await tester.tap(find.text('전체 승인 (2건)'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 표시
      expect(find.textContaining('2건을 모두 승인'), findsOneWidget);

      // 전체 승인 확인
      await tester.tap(find.widgetWithText(FilledButton, '전체 승인'));
      // Fix #1677: same pumpAndSettle() hang — bulkApproveApplications() causes
      // deferred ref.invalidate() via addPostFrameCallback → CircularProgressIndicator
      await tester.pump(); // dispatch tap, bulkApproveApplications() starts
      await tester
          .pump(); // mock resolves → showSnackBar + schedules deferred invalidate
      await tester.pump(); // deferred invalidate fires → providers loading
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // mocks resolve → data state

      verify(
        () => mockEventRepo.bulkApproveApplications(eventId: testEvent.id),
      ).called(1);
      expect(find.text('2건 승인 완료'), findsOneWidget);
    });
  });

  // ─── TC5: 이벤트 정원 표시 ──────────────────────────────────────────────

  group('IT-P06: 이벤트 정원 표시', () {
    testWidgets('이벤트 헤더에 현재/최대 인원 정보가 표시된다', (tester) async {
      final testEvent = makeEvent(
        currentParticipants: 3,
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
                  testEvent: [makeApp('cap-1')],
                };
              }
              return <Event, List<EventApplication>>{};
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 이벤트 헤더에 정원 정보 표시
      expect(find.textContaining('3/10명'), findsOneWidget);
    });
  });

  // ─── TC6: 네트워크 에러 ─────────────────────────────────────────────────

  group('IT-P06: 네트워크 에러 처리', () {
    testWidgets('신청 목록 로드 실패 → 에러 메시지 + 다시 시도 버튼', (tester) async {
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
              (ref, _) async => throw Exception('네트워크 오류'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('신청 목록을 불러올 수 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });
}
