// Ref #1311: QR 티켓 → 입장 통합 테스트
//
// CUJ: 내 티켓 목록 → QR 코드 표시 → QR 검증 → 입장 확인
//
// 이 테스트는 티켓 지갑(TicketWalletRepository)과
// 구매 내역(PurchaseHistoryController), QR 화면(TicketQRScreen)의
// 상태 전이를 Level 2-3 깊이로 검증한다.

import 'dart:convert';

import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_data.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/test_utils.dart';

// ---------------------------------------------------------------------------
// Local Mocks
// ---------------------------------------------------------------------------

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockTicketTokenService extends Mock implements TicketTokenService {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 4, 12, 15);

/// A paid [EventApplication] with a matching event and ticket, representing
/// a successfully purchased ticket the user should see in their wallet.
EventApplication _makePaidApplication({
  String id = 'app_1',
  String eventId = 'event_1',
  String ticketId = 'ticket_1',
  String userId = 'user_1',
}) {
  return EventApplication(
    id: id,
    eventId: eventId,
    ticketId: ticketId,
    userId: userId,
    status: 'paid',
    createdAt: _now,
    updatedAt: _now,
    paymentAmount: 20000,
    paymentId: 'imp_001',
    event: Event(
      id: eventId,
      partyId: 'party_1',
      startTime: _now.add(const Duration(days: 7)),
      endTime: _now.add(const Duration(days: 7, hours: 2)),
      createdAt: _now,
      updatedAt: _now,
      title: '봄 파티',
    ),
    ticket: Ticket(
      id: ticketId,
      name: '일반 티켓',
      createdAt: _now,
      updatedAt: _now,
      price: 20000,
    ),
  );
}

/// A valid [TicketToken] that has not yet expired.
TicketToken _makeValidToken({
  String ticketId = 'ticket_1',
  String eventId = 'event_1',
  String userId = 'user_1',
}) {
  return TicketToken(
    ticketId: ticketId,
    eventId: eventId,
    userId: userId,
    signature: 'valid_sig_$ticketId',
    expiresAt: _now.add(const Duration(days: 7)),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // 1. 내 티켓 목록 — PurchaseHistoryController
  // -------------------------------------------------------------------------
  group('내 티켓 목록', () {
    late MockEventRepository mockEventRepository;
    late MockUser mockUser;

    setUp(() {
      mockEventRepository = MockEventRepository();
      mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user_1');
    });

    test('구매한 티켓이 목록에 표시된다', () async {
      final applications = [
        _makePaidApplication(),
        _makePaidApplication(id: 'app_2', ticketId: 'ticket_2'),
      ];
      when(
        () => mockEventRepository.getMyPurchaseHistory('user_1'),
      ).thenAnswer((_) async => applications);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith(
            (ref) => mockEventRepository,
          ),
        ],
      );

      final result = await container.read(
        purchaseHistoryControllerProvider.future,
      );

      expect(result, hasLength(2));
      expect(result.first.ticketId, 'ticket_1');
      expect(result.first.status, 'paid');
    });

    test('미로그인 상태에서는 빈 목록을 반환한다', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          eventRepositoryProvider.overrideWith(
            (ref) => mockEventRepository,
          ),
        ],
      );

      final result = await container.read(
        purchaseHistoryControllerProvider.future,
      );

      expect(result, isEmpty);
      verifyNever(
        () => mockEventRepository.getMyPurchaseHistory(any()),
      );
    });

    test('isActiveTicket — paid/approved는 활성 티켓으로 판정한다', () async {
      when(
        () => mockEventRepository.getMyPurchaseHistory('user_1'),
      ).thenAnswer((_) async => [_makePaidApplication()]);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          eventRepositoryProvider.overrideWith(
            (ref) => mockEventRepository,
          ),
        ],
      );

      await container.read(purchaseHistoryControllerProvider.future);
      final controller = container.read(
        purchaseHistoryControllerProvider.notifier,
      );

      expect(
        controller.isActiveTicket(_makePaidApplication(id: 'x')),
        isTrue,
      );
      expect(
        controller.isActiveTicket(
          _makePaidApplication(id: 'y').copyWith(status: 'approved'),
        ),
        isTrue,
      );
      expect(
        controller.isActiveTicket(
          _makePaidApplication(id: 'z').copyWith(status: 'cancelled'),
        ),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // 2. QR 코드 — TicketWalletRepository 상태 전이
  // -------------------------------------------------------------------------
  group('QR 티켓 저장소', () {
    late MockSecureStorage mockStorage;
    late TicketWalletRepository repository;

    setUp(() {
      mockStorage = MockSecureStorage();
      repository = TicketWalletRepository(mockStorage);
    });

    test('티켓 저장 후 조회 시 동일한 token_code를 반환한다', () async {
      final token = _makeValidToken();
      final jsonStr = jsonEncode(token.toJson());

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.read(key: 'ticket_ticket_1'),
      ).thenAnswer((_) async => jsonStr);

      await repository.saveTicket(token);
      final retrieved = await repository.getTicket('ticket_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.ticketId, token.ticketId);
      expect(retrieved.eventId, token.eventId);
      expect(retrieved.userId, token.userId);
      expect(retrieved.signature, token.signature);
    });

    test('QR 데이터에 올바른 ticket_code(signature)가 인코딩된다', () async {
      // TicketQRViewer는 jsonEncode(token.toJson())을 QR 데이터로 사용한다.
      // signature 값이 QR payload에 포함되는지 검증.
      final token = _makeValidToken(ticketId: 'ticket_abc');
      final qrPayload = jsonEncode(token.toJson());
      final decoded = jsonDecode(qrPayload) as Map<String, dynamic>;

      // JSON 키는 camelCase (generated by json_serializable)
      expect(decoded['ticketId'], 'ticket_abc');
      expect(decoded['signature'], 'valid_sig_ticket_abc');
      expect(decoded['eventId'], 'event_1');
      expect(decoded['userId'], 'user_1');
    });

    test('존재하지 않는 ticketId 조회 시 null을 반환한다', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await repository.getTicket('nonexistent');
      expect(result, isNull);
    });

    test('이미 입장한 티켓 삭제 후 재조회 시 null을 반환한다 — 중복 입장 방지', () async {
      // 입장 완료 후 wallet에서 제거하면 중복 입장이 방지된다.
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.read(key: 'ticket_ticket_1'),
      ).thenAnswer((_) async => null);

      await repository.deleteTicket('ticket_1');
      final result = await repository.getTicket('ticket_1');

      verify(() => mockStorage.delete(key: 'ticket_ticket_1')).called(1);
      expect(result, isNull);
    });

    test('만료된 토큰도 저장/조회는 가능하다 — 만료 판정은 호출자 책임', () async {
      // TicketWalletRepository는 만료 여부를 판단하지 않는다.
      // verifyAndCheckin 같은 상위 레이어에서 expiresAt 검사를 수행한다.
      final expiredToken = TicketToken(
        ticketId: 'ticket_expired',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'sig_expired',
        expiresAt: _now.subtract(const Duration(days: 1)), // 이미 만료
      );
      final jsonStr = jsonEncode(expiredToken.toJson());

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.read(key: 'ticket_ticket_expired'),
      ).thenAnswer((_) async => jsonStr);

      await repository.saveTicket(expiredToken);
      final retrieved = await repository.getTicket('ticket_expired');

      expect(retrieved, isNotNull);
      expect(retrieved!.expiresAt.isBefore(_now), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // 3. QR 화면 위젯 — TicketQRScreen
  // -------------------------------------------------------------------------
  group('QR 티켓 화면', () {
    late MockTicketTokenService mockService;

    setUp(() {
      mockService = MockTicketTokenService();
    });

    Widget buildQRScreen(String ticketId) {
      return ProviderScope(
        overrides: [
          ticketTokenServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(
          home: TicketQRScreen(ticketId: ticketId),
        ),
      );
    }

    testWidgets('유효한 티켓 → QR 코드가 표시되고 안내 문구가 노출된다', (tester) async {
      final token = _makeValidToken();
      when(
        () => mockService.getToken('ticket_1'),
      ).thenAnswer((_) async => token);

      await tester.pumpWidget(buildQRScreen('ticket_1'));
      await tester.pump(); // FutureProvider 시작
      await tester.pump(); // Future 완료
      await tester.pump(); // 위젯 렌더

      expect(find.text('내 티켓'), findsOneWidget);
      expect(find.text('입장 시 파트너에게 이 화면을 보여주세요'), findsOneWidget);
    });

    testWidgets('저장된 티켓 없음 → 오류 메시지 표시', (tester) async {
      when(
        () => mockService.getToken('ticket_nonexistent'),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(buildQRScreen('ticket_nonexistent'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('티켓 정보를 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('서비스 예외 발생 → AsyncError 에러 상태가 렌더된다', (tester) async {
      // TicketTokenService.getToken()이 예외를 던지는 상황 시뮬레이션
      when(
        () => mockService.getToken('ticket_error'),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(buildQRScreen('ticket_error'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // MinglitAsyncValueWidget은 AsyncError 상태에서 에러 위젯을 렌더한다
      // null 데이터 경로('티켓 정보를 찾을 수 없습니다.')가 아닌 에러 경로가 활성화된다
      expect(find.text('티켓 정보를 찾을 수 없습니다.'), findsNothing);
      // AppBar는 항상 렌더됨
      expect(find.text('내 티켓'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // 4. TicketToken JSON 인코딩 — QR 검증 필드 보장
  // -------------------------------------------------------------------------
  group('TicketToken QR 인코딩 계약', () {
    test('toJson/fromJson 왕복 후 모든 필드가 보존된다', () {
      final original = _makeValidToken();
      final roundTripped = TicketToken.fromJson(original.toJson());

      expect(roundTripped.ticketId, original.ticketId);
      expect(roundTripped.eventId, original.eventId);
      expect(roundTripped.userId, original.userId);
      expect(roundTripped.signature, original.signature);
      // DateTime 비교는 millisecondsSinceEpoch로 한다 (timezone 무관)
      expect(
        roundTripped.expiresAt.millisecondsSinceEpoch,
        original.expiresAt.millisecondsSinceEpoch,
      );
    });

    test('QR payload에 검증에 필요한 모든 키가 존재한다', () {
      final token = _makeValidToken();
      final payload =
          jsonDecode(jsonEncode(token.toJson())) as Map<String, dynamic>;

      // 입장 검증 시 파트너 앱이 읽어야 하는 필드 (camelCase — json_serializable 기본값)
      expect(payload.containsKey('ticketId'), isTrue);
      expect(payload.containsKey('eventId'), isTrue);
      expect(payload.containsKey('userId'), isTrue);
      expect(payload.containsKey('signature'), isTrue);
      expect(payload.containsKey('expiresAt'), isTrue);
    });
  });
}
