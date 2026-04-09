// Ref #1072: IT-P03 — 체크인 관리 CUJ 통합 테스트
//
// 검증 포인트:
// 1. /checkin 접근 시 CheckinPlaceholderPage 렌더링
// 2. 오늘 이벤트 없을 때 빈 상태
// 3. 오늘 이벤트 2개 이상 시 이벤트 선택 UI 노출
// 4. 비로그인 시 접근 차단
// 변형:
// - P03-V1: 카메라 권한 거부 → 에러 표시
// - P03-V2: 오프라인 환경 → 에러 처리
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/test_app.dart';

void main() {
  final testUser = MockUser();
  const testPartner = Partner(id: 'partner-p03', name: 'Checkin Partner');
  final now = DateTime(2026, 4, 5, 19);

  setUp(() {
    when(() => testUser.id).thenReturn('user-p03');
    when(() => testUser.email).thenReturn('partner@test.com');
    when(() => testUser.userMetadata).thenReturn({});
  });

  Event makeEvent(String id, {String? title}) {
    return Event(
      id: id,
      partyId: 'party-1',
      title: title ?? '이벤트 $id',
      startTime: now.subtract(const Duration(minutes: 30)),
      endTime: now.add(const Duration(hours: 3)),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('IT-P03: 체크인 관리', () {
    testWidgets('비로그인 사용자는 체크인 페이지에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          initialLocation: '/checkin',
        ),
      );
      await tester.pump();
      await tester.pump();

      // /login으로 리다이렉트
      expect(find.byType(PartnerLoginPage), findsOneWidget);
    });

    testWidgets('오늘 이벤트 없을 때 빈 상태 메시지 표시', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => <Event>[],
            ),
          ],
          child: const MaterialApp(home: CheckinPlaceholderPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 예정된 이벤트가 없습니다'), findsOneWidget);
    });

    testWidgets('오늘 이벤트 2개 이상 시 이벤트 선택 UI가 노출된다', (tester) async {
      final event1 = makeEvent('ev1', title: '소셜 이벤트 A');
      final event2 = makeEvent('ev2', title: '소셜 이벤트 B');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => [event1, event2],
            ),
          ],
          child: const MaterialApp(home: CheckinPlaceholderPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 선택하세요'), findsOneWidget);
      expect(find.text('소셜 이벤트 A'), findsOneWidget);
      expect(find.text('소셜 이벤트 B'), findsOneWidget);
    });

    testWidgets('P03-V2: 이벤트 로드 실패 시 에러 메시지 표시', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) => Future<List<Event>>.error('네트워크 오류'),
            ),
          ],
          child: const MaterialApp(home: CheckinPlaceholderPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 불러올 수 없습니다'), findsOneWidget);
    });
  });
}
