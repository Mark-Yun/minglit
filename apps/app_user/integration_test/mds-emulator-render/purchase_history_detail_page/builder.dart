// PurchaseHistoryDetailPageBuilder
// — purchase_history_detail_page 전용 fluent API.

import 'dart:async';

import 'package:app_user/src/features/payment/logic/purchase_history_detail_controller.dart';
import 'package:app_user/src/features/payment/ui/purchase_history_detail_page.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const String _applicationId = 'render-app-1';
final DateTime _base = DateTime(2026, 5, 20, 10);

EventApplication _application({
  required String status,
  required String refundStatus,
  required DateTime eventStartTime,
  required String paymentId,
  required int paymentAmount,
}) {
  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '강남 밍글 클럽',
    createdAt: _base,
    updatedAt: _base,
  );

  final location = Location(
    id: 'loc-1',
    partnerId: 'partner-1',
    name: '밍글 강남점',
    address: '서울 강남구 테헤란로 101',
    createdAt: _base,
    updatedAt: _base,
  );

  final event = Event(
    id: 'event-1',
    partyId: party.id,
    title: '강남 네트워킹 나이트',
    startTime: eventStartTime,
    endTime: eventStartTime.add(const Duration(hours: 3)),
    createdAt: _base,
    updatedAt: _base,
    party: party,
    location: location,
  );

  return EventApplication(
    id: _applicationId,
    eventId: event.id,
    ticketId: 'ticket-1',
    userId: 'user-render-1',
    status: status,
    refundStatus: refundStatus,
    paymentAmount: paymentAmount,
    paymentId: paymentId.isEmpty ? null : paymentId,
    paidAt: _base,
    createdAt: _base,
    updatedAt: _base,
    event: event,
    ticket: Ticket(
      id: 'ticket-1',
      name: '일반 1인권',
      price: paymentAmount,
      createdAt: _base,
      updatedAt: _base,
    ),
  );
}

final EventApplication _defaultApplication = _application(
  status: 'paid',
  refundStatus: 'none',
  eventStartTime: DateTime.now().add(const Duration(days: 3)),
  paymentId: 'pay-render-1',
  paymentAmount: 29000,
);

final EventApplication _disabledCancelApplication = _application(
  status: 'paid',
  refundStatus: 'none',
  eventStartTime: DateTime.now().subtract(const Duration(days: 1)),
  paymentId: 'pay-render-2',
  paymentAmount: 29000,
);

final EventApplication _refundedApplication = _application(
  status: 'cancelled',
  refundStatus: 'completed',
  eventStartTime: DateTime.now().add(const Duration(days: 3)),
  paymentId: 'pay-render-3',
  paymentAmount: 29000,
);

final EventApplication _paymentFailedApplication = _application(
  status: 'payment_failed',
  refundStatus: 'none',
  eventStartTime: DateTime.now().add(const Duration(days: 3)),
  paymentId: '',
  paymentAmount: 29000,
);

class PurchaseHistoryDetailPageBuilder
    extends MdsScreenBuilder<PurchaseHistoryDetailPage> {
  PurchaseHistoryDetailPageBuilder()
    : super(
        page: const PurchaseHistoryDetailPage(applicationId: _applicationId),
      );

  void _withApplication(EventApplication? application) {
    addOverride(
      purchaseHistoryDetailProvider(
        _applicationId,
      ).overrideWith((_) async => application),
    );
  }

  /// 기본 상태: 환불 가능한 결제 내역.
  void withDefault() => _withApplication(_defaultApplication);

  /// 환불 불가 상태: 이벤트 시작 이후로 취소 버튼 disabled.
  void withCancelDisabled() => _withApplication(_disabledCancelApplication);

  /// 환불 완료 상태: 환불 정보 카드 노출.
  void withRefunded() => _withApplication(_refundedApplication);

  /// 결제 실패 상태.
  void withPaymentFailed() => _withApplication(_paymentFailedApplication);

  /// 로딩 상태.
  void withLoading() {
    addOverride(
      purchaseHistoryDetailProvider(
        _applicationId,
      ).overrideWith((_) => Completer<EventApplication?>().future),
    );
  }

  /// 에러 상태.
  void withError() {
    addOverride(
      purchaseHistoryDetailProvider(
        _applicationId,
      ).overrideWith((_) async => throw Exception('render: forced error')),
    );
  }
}
