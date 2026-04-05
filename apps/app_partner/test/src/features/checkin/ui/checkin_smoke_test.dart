// Ref #1072: P0 Smoke — QRScannerScreen 화면 진입 테스트
//
// QR 스캔 화면이 크래시 없이 렌더링됨을 검증한다.
//
// TODO #1009: MobileScanner 플러그인의 async dispose 동작으로 인해
// pumpAndSettle 사용 시 flaky 가능성이 있다.
// pump()만 호출하여 최초 렌더링만 검증한다.
// 참고: apps/app_partner/test/src/features/checkin/checkin_placeholder_page_test.dart
import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 4, 5, 19);
  final testEvent = Event(
    id: 'event-scan-1',
    partyId: 'party-1',
    startTime: now,
    endTime: now.add(const Duration(hours: 3)),
    createdAt: now,
    updatedAt: now,
    title: '소셜 파티',
  );

  Widget buildWidget({CheckinState? state}) {
    return ProviderScope(
      overrides: [
        // Fix #1072: overrideWith() 사용 — overrideWithValue()는 .notifier 접근 시 타입 에러.
        checkinControllerProvider.overrideWith(
          () => _FakeCheckinController(
            state ?? const CheckinState(result: CheckinResult.idle),
          ),
        ),
      ],
      child: MaterialApp(home: QRScannerScreen(event: testEvent)),
    );
  }

  group('QRScannerScreen smoke', () {
    testWidgets('idle 상태에서 "티켓 스캔" AppBar 제목이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      // pump()만 사용 — pumpAndSettle 생략 (TODO #1009: mobile_scanner async dispose)
      await tester.pump();

      expect(find.text('티켓 스캔'), findsOneWidget);
      expect(find.text(testEvent.title!), findsOneWidget);
    });

    testWidgets('success 상태에서 결과 오버레이가 렌더링된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const CheckinState(result: CheckinResult.success),
        ),
      );
      await tester.pump();

      // 성공 오버레이(_ResultFeedbackOverlay)가 크래시 없이 렌더링됨
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

class _FakeCheckinController extends CheckinController {
  _FakeCheckinController(this._initialState);
  final CheckinState _initialState;

  @override
  CheckinState build() => _initialState;

  @override
  Future<void> processQR(String rawData) async {}
}
