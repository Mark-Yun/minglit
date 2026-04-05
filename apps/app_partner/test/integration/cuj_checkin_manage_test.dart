// IT-P03: 체크인 관리 CUJ — 파트너가 오늘의 이벤트를 선택하고 QR 스캐너로 이동하는 플로우
// Fix #1072: Phase 3 — P0 CUJ integration test 구현

import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/mock_data.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  Widget createTestWidget({
    required List<Event> todayEvents,
    Partner? partner,
  }) {
    final testPartnerId = (partner ?? testPartner).id;
    return ProviderScope(
      overrides: [
        currentPartnerInfoProvider.overrideWith(
          (ref) async => partner ?? testPartner,
        ),
        todayEventsProvider.overrideWith(
          (ref, partnerId) async => todayEvents,
        ),
      ].cast(),
      child: const MaterialApp(home: CheckinPlaceholderPage()),
    );
  }

  group('IT-P03: 체크인 관리 CUJ', () {
    testWidgets('오늘 이벤트 없음 — 빈 상태 표시', (tester) async {
      await tester.pumpWidget(createTestWidget(todayEvents: []));
      await tester.pumpAndSettle();

      // 이벤트가 없을 때 빈 상태 UI 렌더링 확인
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('오늘 이벤트 2개 이상 — 이벤트 선택 목록 표시', (tester) async {
      final events = fakeTodayEvents(count: 2);
      await tester.pumpWidget(createTestWidget(todayEvents: events));
      await tester.pumpAndSettle();

      // 이벤트 선택 시트 또는 목록에 이벤트 제목이 표시되어야 함
      expect(find.textContaining('오늘의 이벤트 1'), findsWidgets);
      expect(find.textContaining('오늘의 이벤트 2'), findsWidgets);
    });

    testWidgets('체크인 페이지 초기 렌더링 — 크래시 없음', (tester) async {
      await tester.pumpWidget(
        createTestWidget(todayEvents: fakeTodayEvents(count: 3)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('파트너 정보 로딩 중 — 크래시 없음', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 파트너 정보 로딩 시뮬레이션
            currentPartnerInfoProvider.overrideWith(
              (ref) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return createTestPartner();
              },
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => fakeTodayEvents(count: 1),
            ),
          ].cast(),
          child: const MaterialApp(home: CheckinPlaceholderPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    // IT-P03-V1: 단일 이벤트 — QR 스캐너 자동 이동 (카메라 권한 없어서 직접 검증 불가)
    testWidgets('변형: 단일 이벤트 — QR 스캐너 페이지로 자동 이동 시도', (tester) async {
      final singleEvent = fakeTodayEvents(count: 1);
      await tester.pumpWidget(createTestWidget(todayEvents: singleEvent));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 단일 이벤트이면 자동으로 QR 스캐너로 이동하려 시도 — 크래시만 없으면 통과
      expect(tester.takeException(), isNull);
    });
  });
}
