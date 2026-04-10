// Ref #1072: P0 Smoke — EventApplicationManagePage 화면 진입 테스트
//
// 신청 관리 화면이 크래시 없이 렌더링됨을 검증한다.
// 이미 event_application_manage_page_test.dart에 종합 테스트가 있으므로,
// 이 파일은 Smoke 관점에서 핵심 렌더링 경로만 빠르게 확인한다.
import 'dart:async';

import 'package:app_partner/src/features/application/event_application_manage_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  const testPartner = Partner(id: 'partner-smoke', name: 'Smoke Partner');

  Widget buildWidget({
    Partner? partner,
    Object? partnerError,
    Map<Event, List<EventApplication>> pendingGrouped = const {},
  }) {
    return ProviderScope(
      overrides: [
        currentPartnerInfoProvider.overrideWith((ref) async {
          if (partnerError != null) throw partnerError;
          return partner ?? testPartner;
        }),
        eventApplicationsGroupedProvider.overrideWith(
          (ref, _) async => pendingGrouped,
        ),
      ].cast(),
      child: const MaterialApp(home: EventApplicationManagePage()),
    );
  }

  group('EventApplicationManagePage smoke', () {
    testWidgets('정상 렌더링 — "신청관리" 제목과 3개 탭이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('대기중'), findsOneWidget);
      expect(find.text('승인됨'), findsOneWidget);
      expect(find.text('거절됨'), findsOneWidget);
    });

    testWidgets('파트너 정보 로딩 중에는 인디케이터가 표시된다', (tester) async {
      // Completer로 영구 pending — Future.delayed는 테스트 종료 후에도 timer가 남아 오류 발생
      final completer = Completer<Partner?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) => completer.future,
            ),
            eventApplicationsGroupedProvider.overrideWith(
              (ref, _) async => <Event, List<EventApplication>>{},
            ),
          ].cast(),
          child: const MaterialApp(home: EventApplicationManagePage()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('파트너 null일 때 에러 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentPartnerInfoProvider.overrideWith((ref) async => null),
          ].cast(),
          child: const MaterialApp(home: EventApplicationManagePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
    });
  });
}
