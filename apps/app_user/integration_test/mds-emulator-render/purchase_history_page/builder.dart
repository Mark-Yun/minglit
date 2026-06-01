// PurchaseHistoryPageBuilder — purchase_history_page 전용 fluent API.

import 'dart:async';

import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_page.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class _FixedPurchaseHistoryController extends PurchaseHistoryController {
  _FixedPurchaseHistoryController(this._history);
  final List<EventApplication> _history;

  @override
  FutureOr<List<EventApplication>> build() async => _history;
}

class _LoadingPurchaseHistoryController extends PurchaseHistoryController {
  @override
  FutureOr<List<EventApplication>> build() =>
      Completer<List<EventApplication>>().future;
}

class _ErrorPurchaseHistoryController extends PurchaseHistoryController {
  @override
  FutureOr<List<EventApplication>> build() async =>
      throw Exception('render: forced error');
}

final _base = DateTime(2026, 5, 20, 10);

EventApplication _application({
  required String id,
  required String title,
  required String ticketName,
  required String status,
  required int amount,
  required DateTime startTime,
}) {
  final event = Event(
    id: 'event-$id',
    partyId: 'party-$id',
    title: title,
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 2)),
    createdAt: _base,
    updatedAt: _base,
    location: Location(
      id: 'loc-$id',
      partnerId: 'partner-$id',
      name: '강남 밍글홀',
      address: '서울 강남구 테헤란로 101',
      createdAt: _base,
      updatedAt: _base,
    ),
  );

  return EventApplication(
    id: id,
    eventId: event.id,
    ticketId: 'ticket-$id',
    userId: 'user-render-1',
    status: status,
    paymentAmount: amount,
    paymentId: 'pay-$id',
    paidAt: _base,
    createdAt: _base,
    updatedAt: _base,
    event: event,
    ticket: Ticket(
      id: 'ticket-$id',
      name: ticketName,
      price: amount,
      createdAt: _base,
      updatedAt: _base,
    ),
  );
}

final _defaultHistory = <EventApplication>[
  _application(
    id: 'app-1',
    title: '강남 소셜 밍글',
    ticketName: '얼리버드 1인',
    status: 'paid',
    amount: 29000,
    startTime: DateTime(2026, 5, 18, 19),
  ),
  _application(
    id: 'app-2',
    title: '홍대 프라이데이 파티',
    ticketName: '스탠다드 1인',
    status: 'cancelled',
    amount: 15000,
    startTime: DateTime(2026, 5, 12, 20),
  ),
];

class PurchaseHistoryPageBuilder extends MdsScreenBuilder<PurchaseHistoryPage> {
  PurchaseHistoryPageBuilder() : super(page: const PurchaseHistoryPage());

  /// 기본 상태: 구매 이력 2건 표시.
  void withDefault() {
    addOverride(
      purchaseHistoryControllerProvider.overrideWith(
        () => _FixedPurchaseHistoryController(_defaultHistory),
      ),
    );
  }

  /// 빈 상태.
  void withEmpty() {
    addOverride(
      purchaseHistoryControllerProvider.overrideWith(
        () => _FixedPurchaseHistoryController(const []),
      ),
    );
  }

  /// 로딩 상태.
  void withLoading() {
    addOverride(
      purchaseHistoryControllerProvider.overrideWith(
        _LoadingPurchaseHistoryController.new,
      ),
    );
  }

  /// 에러 상태.
  void withError() {
    addOverride(
      purchaseHistoryControllerProvider.overrideWith(
        _ErrorPurchaseHistoryController.new,
      ),
    );
  }
}
