// Ref #1317: IT-P07 — QR 스캔 체크인 CUJ 통합 테스트
//
// 검증 포인트:
// 1. 단일 이벤트 — CheckinPlaceholderPage → QRScannerScreen 직행
// 2. 복수 이벤트 — 이벤트 선택 목록에 참가자 카운트 표시
// 3. QRScannerScreen AppBar에 이벤트 제목 표시
// 4. 체크인 성공 오버레이 — "체크인 완료" 텍스트 + 참가자 이름
// 5. 체크인 실패 오버레이 — "입장 제한" 텍스트 + 에러 메시지
// 6. Controller-UI 연동 — processQR 성공 → 성공 오버레이 렌더링
// 7. Controller-UI 연동 — processQR 실패 → 실패 오버레이 렌더링
// 8. Controller-UI 연동 — malformed QR → 실패 오버레이 렌더링
//
// 참고:
// - processQR 단위 동작(상태 전이)은 checkin_controller_test.dart에서 커버됨.
// - QRScannerScreen 기본 렌더링은 checkin_smoke_test.dart에서 커버됨.
// - 이 테스트는 Controller↔UI 연동, 오버레이 텍스트 내용, CUJ 진입 흐름을 검증한다.
//
// ignore_for_file: lines_longer_than_80_chars
// MobileScanner async dispose → pumpAndSettle 사용 시 flaky (ref #1009).
// QRScannerScreen을 포함한 테스트는 pump()만 사용한다.
import 'dart:async';
import 'dart:convert';

import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';

/// 최소한의 유효한 TicketToken JSON을 생성한다.
String _makeQrPayload({
  String ticketId = 'ticket-001',
  String eventId = 'event-001',
  String userId = 'user-abcd',
  String signature = 'sig',
  DateTime? expiresAt,
}) {
  final exp = (expiresAt ?? DateTime.now().add(const Duration(days: 7)))
      .toIso8601String();
  return jsonEncode({
    'ticketId': ticketId,
    'eventId': eventId,
    'userId': userId,
    'signature': signature,
    'expiresAt': exp,
  });
}

/// 테스트용 더미 Ed25519 공개키 (crypto 연산은 mock으로 처리).
final _fakePublicKey = SimplePublicKey(
  List.filled(32, 0),
  type: KeyPairType.ed25519,
);

/// CheckinController 상태를 고정하는 Fake — UI 렌더링 테스트용.
class _FakeCheckinController extends CheckinController {
  _FakeCheckinController(this._fixedState);
  final CheckinState _fixedState;

  @override
  CheckinState build() => _fixedState;

  @override
  Future<void> processQR(String rawData) async {}
}

void main() {
  late MockCheckinRepository mockRepo;

  // Fix #1317: TicketToken 및 SimplePublicKey에 대한 mocktail fallback 등록.
  setUpAll(() {
    registerFallbackValue(_fakePublicKey);
    registerFallbackValue(
      TicketToken.fromJson(
        jsonDecode(_makeQrPayload()) as Map<String, dynamic>,
      ),
    );
  });

  setUp(() {
    mockRepo = MockCheckinRepository();
    when(
      () => mockRepo.fetchServerPublicKey(),
    ).thenAnswer((_) async => _fakePublicKey);
  });

  Event makeEvent(
    String id, {
    String? title,
    int currentParticipants = 5,
    int maxParticipants = 20,
    DateTime? now,
  }) {
    final base = now ?? DateTime(2026, 4, 13, 18);
    return Event(
      id: id,
      partyId: 'party-1',
      title: title ?? '테스트 이벤트 $id',
      startTime: base.subtract(const Duration(minutes: 30)),
      endTime: base.add(const Duration(hours: 3)),
      createdAt: base,
      updatedAt: base,
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
    );
  }

  const testPartner = Partner(id: 'partner-p07', name: 'P07 Partner');

  // ── 헬퍼: QRScannerScreen 빌드 (pre-set 상태) ────────────────────────────
  Widget buildScannerWithState(Event event, CheckinState state) {
    return ProviderScope(
      overrides: [
        checkinControllerProvider.overrideWith(
          () => _FakeCheckinController(state),
        ),
      ],
      child: MaterialApp(home: QRScannerScreen(event: event)),
    );
  }

  // ── 헬퍼: QRScannerScreen 빌드 (실제 Controller + Mock Repository) ──────
  Widget buildScannerWithRepo(Event event) {
    return ProviderScope(
      overrides: [checkinRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(home: QRScannerScreen(event: event)),
    );
  }

  group('IT-P07: QR 스캔 체크인 CUJ', () {
    // ── 1. CheckinPlaceholderPage 이벤트 진입 흐름 ───────────────────────────

    group('이벤트 선택 → QR 스캔 진입', () {
      testWidgets(
        '단일 이벤트 — CheckinPlaceholderPage가 QRScannerScreen으로 직행한다',
        (tester) async {
          final event = makeEvent('ev-single', title: '단독 파티');

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentPartnerInfoProvider.overrideWith(
                  (ref) async => testPartner,
                ),
                todayEventsProvider.overrideWith(
                  (ref, _) async => [event],
                ),
                checkinRepositoryProvider.overrideWithValue(mockRepo),
              ],
              child: const MaterialApp(home: CheckinPlaceholderPage()),
            ),
          );
          // FutureProvider가 완료될 때까지 pump (pumpAndSettle 회피 — ref #1009)
          await tester.pump();
          await tester.pump();
          await tester.pump();

          // QRScannerScreen이 렌더링됨 (단일 이벤트 → direct entry)
          expect(find.byType(QRScannerScreen), findsOneWidget);
          expect(find.text('티켓 스캔'), findsOneWidget);
          expect(find.text('단독 파티'), findsOneWidget);
        },
      );

      testWidgets('복수 이벤트 — 이벤트 선택 목록에 참가자 카운트(현재/최대)가 표시된다', (tester) async {
        final event1 = makeEvent(
          'ev-a',
          title: '파티 A',
          currentParticipants: 8,
          maxParticipants: 30,
        );
        final event2 = makeEvent(
          'ev-b',
          title: '파티 B',
          currentParticipants: 12,
          maxParticipants: 50,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentPartnerInfoProvider.overrideWith(
                (ref) async => testPartner,
              ),
              todayEventsProvider.overrideWith(
                (ref, _) async => [event1, event2],
              ),
            ],
            child: const MaterialApp(home: CheckinPlaceholderPage()),
          ),
        );
        await tester.pumpAndSettle();

        // 이벤트 선택 화면 표시
        expect(find.text('이벤트를 선택하세요'), findsOneWidget);

        // 각 이벤트의 참가자 카운트가 "현재/최대명" 형식으로 표시
        expect(find.text('8/30명'), findsOneWidget);
        expect(find.text('12/50명'), findsOneWidget);
      });
    });

    // ── 2. QRScannerScreen AppBar 렌더링 ────────────────────────────────────

    group('QRScannerScreen 렌더링', () {
      testWidgets('이벤트 제목이 AppBar에 표시된다', (tester) async {
        final event = makeEvent('ev-scan', title: '새해맞이 파티');

        await tester.pumpWidget(
          buildScannerWithState(
            event,
            const CheckinState(result: CheckinResult.idle),
          ),
        );
        await tester.pump();

        expect(find.text('티켓 스캔'), findsOneWidget);
        expect(find.text('새해맞이 파티'), findsOneWidget);
      });
    });

    // ── 3. 체크인 결과 오버레이 텍스트 검증 (FakeCheckinController 사용) ─────

    group('체크인 결과 오버레이', () {
      testWidgets(
        '체크인 성공 — "체크인 완료" 텍스트와 참가자 이름이 오버레이에 표시된다',
        (tester) async {
          final event = makeEvent('ev-success');

          await tester.pumpWidget(
            buildScannerWithState(
              event,
              const CheckinState(
                result: CheckinResult.success,
                userName: 'User abcd',
              ),
            ),
          );
          await tester.pump();

          expect(find.text('체크인 완료'), findsOneWidget);
          expect(find.text('User abcd'), findsOneWidget);
          // 성공 아이콘 표시
          expect(find.byIcon(Icons.check_circle), findsOneWidget);
        },
      );

      testWidgets(
        '체크인 실패 — "입장 제한" 텍스트와 에러 메시지가 오버레이에 표시된다',
        (tester) async {
          final event = makeEvent('ev-fail');

          await tester.pumpWidget(
            buildScannerWithState(
              event,
              const CheckinState(
                result: CheckinResult.invalid,
                message: '유효하지 않은 티켓입니다.',
              ),
            ),
          );
          await tester.pump();

          expect(find.text('입장 제한'), findsOneWidget);
          expect(find.text('유효하지 않은 티켓입니다.'), findsOneWidget);
          // 에러 아이콘 표시
          expect(find.byIcon(Icons.error), findsOneWidget);
        },
      );

      testWidgets(
        'idle 상태 — 오버레이 없이 스캔 뷰만 표시된다',
        (tester) async {
          final event = makeEvent('ev-idle');

          await tester.pumpWidget(
            buildScannerWithState(
              event,
              const CheckinState(result: CheckinResult.idle),
            ),
          );
          await tester.pump();

          expect(find.text('체크인 완료'), findsNothing);
          expect(find.text('입장 제한'), findsNothing);
        },
      );
    });

    // ── 4. Controller-UI 연동 (실제 CheckinController + Mock Repository) ────

    group('Controller-UI 연동', () {
      testWidgets(
        'processQR 성공 — 성공 오버레이("체크인 완료" + userName)가 렌더링된다',
        (tester) async {
          when(
            () => mockRepo.verifyAndCheckin(
              token: any(named: 'token'),
              serverPublicKey: any(named: 'serverPublicKey'),
            ),
          ).thenAnswer((_) async => true);

          final event = makeEvent('ev-e2e-ok');
          await tester.pumpWidget(buildScannerWithRepo(event));
          await tester.pump();

          final container = ProviderScope.containerOf(
            tester.element(find.byType(QRScannerScreen)),
          );

          // Fix #1317: processQR는 3초 딜레이를 포함하므로 tester.runAsync 사용.
          // pump() 호출로 성공 상태 후 UI 재빌드를 트리거한다.
          await tester.runAsync(() async {
            unawaited(
              container
                  .read(checkinControllerProvider.notifier)
                  .processQR(_makeQrPayload(userId: 'user-abcd1234')),
            );
            // 짧은 딜레이로 async 흐름이 성공 상태까지 진행되도록 대기
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();

          expect(find.text('체크인 완료'), findsOneWidget);
          // userId 앞 4글자: 'user'
          expect(find.text('User user'), findsOneWidget);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      testWidgets(
        'processQR 실패 — 실패 오버레이("입장 제한" + 메시지)가 렌더링된다',
        (tester) async {
          when(
            () => mockRepo.verifyAndCheckin(
              token: any(named: 'token'),
              serverPublicKey: any(named: 'serverPublicKey'),
            ),
          ).thenAnswer((_) async => false);

          final event = makeEvent('ev-e2e-fail');
          await tester.pumpWidget(buildScannerWithRepo(event));
          await tester.pump();

          final container = ProviderScope.containerOf(
            tester.element(find.byType(QRScannerScreen)),
          );

          await tester.runAsync(() async {
            unawaited(
              container
                  .read(checkinControllerProvider.notifier)
                  .processQR(_makeQrPayload()),
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();

          expect(find.text('입장 제한'), findsOneWidget);
          expect(find.text('유효하지 않은 티켓입니다.'), findsOneWidget);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      testWidgets(
        'malformed QR — 파싱 실패 시 실패 오버레이("입장 제한")가 렌더링된다',
        (tester) async {
          final event = makeEvent('ev-e2e-malformed');
          await tester.pumpWidget(buildScannerWithRepo(event));
          await tester.pump();

          final container = ProviderScope.containerOf(
            tester.element(find.byType(QRScannerScreen)),
          );

          await tester.runAsync(() async {
            unawaited(
              container
                  .read(checkinControllerProvider.notifier)
                  .processQR('not-valid-json{{{'),
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();

          expect(find.text('입장 제한'), findsOneWidget);
          expect(find.text('티켓 데이터를 읽을 수 없습니다.'), findsOneWidget);

          // Fix #1317: malformed QR는 repo를 호출하지 않아야 한다.
          verifyNever(() => mockRepo.fetchServerPublicKey());
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );
    });
  });
}
