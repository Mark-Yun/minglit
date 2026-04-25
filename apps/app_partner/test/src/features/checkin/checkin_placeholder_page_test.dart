import 'dart:async';

import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:app_partner/src/features/checkin/stats/checkin_stats_controller.dart'
    show CheckinStats, CheckinStatsController, checkinStatsControllerProvider;
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Fake platform implementation for MobileScanner.
///
/// Prevents real camera platform channel calls during widget tests. Required
/// because MobileScannerController initialises asynchronously and its dispose
/// fires platform calls that outlive the test frame — see Fix #1072.
// Fix #1097: widget test에서 MobileScannerPlatform을 스텁해 카메라 채널 호출을 막는다.
class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size.zero,
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Future<Set<CameraLensType>> getSupportedLenses() async => {};

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async => null;
}

/// Fake CheckinStatsController that returns empty stats without network calls.
// Fix #1817: pumpAndSettle 타임아웃 방지 — QRScannerScreen이 stats를 로드할 때
// 실제 Supabase 연결을 시도하지 않도록 한다.
class _FakeCheckinStatsController extends CheckinStatsController {
  @override
  Future<CheckinStats> build(String eventId) async =>
      const CheckinStats(total: 0, checkedIn: 0);
}

void main() {
  group('CheckinPlaceholderPage', () {
    late MobileScannerPlatform originalPlatform;

    setUp(() {
      originalPlatform = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = _FakeMobileScannerPlatform();
    });

    tearDown(() {
      MobileScannerPlatform.instance = originalPlatform;
    });

    const testPartner = Partner(
      id: 'partner-1',
      name: 'Test Partner',
      contactEmail: 'test@partner.com',
    );

    final now = DateTime.now();
    final testEvent = Event(
      id: 'event-1',
      partyId: 'party-1',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      title: 'Test Event',
    );

    Widget buildWidget({required List<dynamic> overrides}) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: const MaterialApp(home: CheckinPlaceholderPage()),
      );
    }

    testWidgets('shows loading indicator when partner info is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) => Completer<Partner?>().future,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when partner info fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) => Future<Partner?>.error('Network error'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('shows message when partner info is null', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => null,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('파트너 정보를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('shows empty state when 0 events today', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => <Event>[],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 예정된 이벤트가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('auto-routes to QRScannerScreen when exactly 1 event today', (
      tester,
    ) async {
      // Fix #1097: Previously disabled due to mobile_scanner async dispose
      // (tracked in #1009). Fix #1072 applied unawaited() to _scannerController
      // .dispose(); _FakeMobileScannerPlatform stubs out platform calls so the
      // test runs without a camera and teardown is deterministic.
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => [testEvent],
            ),
            // Fix #1817: checkinStatsControllerProvider를 모킹해
            // pumpAndSettle이 네트워크 요청을 기다리지 않도록 한다.
            checkinStatsControllerProvider.overrideWith(
              _FakeCheckinStatsController.new,
            ),
          ],
        ),
      );
      // Fix #1817: MobileScanner 내부 비동기 초기화로 pumpAndSettle이 타임아웃됨.
      // (smoke test 참고: #1009). provider가 완료될 시간을 주고 렌더링만 검증한다.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(QRScannerScreen), findsOneWidget);
    });

    testWidgets('shows event selection when 2+ events today', (
      tester,
    ) async {
      final event2 = Event(
        id: 'event-2',
        partyId: 'party-1',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 3)),
        createdAt: now,
        updatedAt: now,
        title: 'Second Event',
      );

      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) async => [testEvent, event2],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 선택하세요'), findsOneWidget);
      expect(find.text('오늘 2개 이벤트가 진행됩니다'), findsOneWidget);
      expect(find.text('Test Event'), findsOneWidget);
      expect(find.text('Second Event'), findsOneWidget);
    });

    // Fix #1742: event.title이 null일 때 party.title을 표시하는 회귀 테스트
    testWidgets(
      'Fix #1742: shows party title when event.title is null',
      (tester) async {
        final party = Party(
          id: 'party-1',
          partnerId: 'partner-1',
          title: '파티 이름',
          createdAt: now,
          updatedAt: now,
        );
        final eventNullTitle = Event(
          id: 'event-null',
          partyId: 'party-1',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
          createdAt: now,
          updatedAt: now,
          party: party,
        );
        final event2 = Event(
          id: 'event-2',
          partyId: 'party-1',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 3)),
          createdAt: now,
          updatedAt: now,
          title: 'Second Event',
        );

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              currentPartnerInfoProvider.overrideWith(
                (ref) async => testPartner,
              ),
              todayEventsProvider.overrideWith(
                (ref, partnerId) async => [eventNullTitle, event2],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Party title shown instead of empty string
        expect(find.text('파티 이름'), findsOneWidget);
        expect(find.text('Second Event'), findsOneWidget);
      },
    );

    testWidgets('shows loading indicator when events are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) => Completer<List<Event>>().future,
            ),
          ],
        ),
      );
      // Pump twice: once for partner resolve, once for events loading state
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error when events fail to load', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          overrides: [
            currentPartnerInfoProvider.overrideWith(
              (ref) async => testPartner,
            ),
            todayEventsProvider.overrideWith(
              (ref, partnerId) =>
                  Future<List<Event>>.error('Events load failed'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이벤트를 불러올 수 없습니다'), findsOneWidget);
    });
  });
}
