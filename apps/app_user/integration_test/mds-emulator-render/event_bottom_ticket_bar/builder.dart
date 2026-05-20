// EventBottomTicketBarBuilder — event_bottom_ticket_bar 전용 fluent API.
//
// EventDetailPage 하단에 고정되는 admission CTA bar.
// Scaffold bottomSheet 으로 마운트하여 실제 사용 환경을 재현한다.
//
// Refs #2588: mds-render-coverage event-operation 카탈로그 등록

import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_bottom_ticket_bar.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

// ---------------------------------------------------------------------------
// Fake controller — no Supabase / network in render context
// ---------------------------------------------------------------------------

class _FixedAdmissionController extends EventAdmissionController {
  _FixedAdmissionController(this._state);
  final AdmissionState _state;

  @override
  FutureOr<AdmissionState> build(Event event) => _state;
}

// Never completes — simulates async loading state.
class _LoadingAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) =>
      Completer<AdmissionState>().future;
}

// Throws immediately — simulates async error state.
class _ErrorAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) =>
      throw Exception('render: forced error');
}

// ---------------------------------------------------------------------------
// Fixed render event
// ---------------------------------------------------------------------------

final _base = DateTime(2026, 5, 18, 18);

final _renderEvent = Event(
  id: 'render-event-1',
  partyId: 'render-party-1',
  title: '강남 밍릿파티',
  startTime: _base,
  endTime: _base.add(const Duration(hours: 2)),
  createdAt: _base,
  updatedAt: _base,
  tickets: [
    Ticket(
      id: 'ticket-1',
      eventId: 'render-event-1',
      name: '일반 입장권',
      price: 20000,
      quantity: 100,
      soldCount: 0,
      createdAt: _base,
      updatedAt: _base,
    ),
  ],
);

// ---------------------------------------------------------------------------
// Builder
// ---------------------------------------------------------------------------

class EventBottomTicketBarBuilder extends MdsScreenBuilder<Scaffold> {
  EventBottomTicketBarBuilder()
    : super(
        page: Scaffold(
          body: const SizedBox.expand(),
          bottomSheet: EventBottomTicketBar(event: _renderEvent),
        ),
        base: [],
      );

  void _applyAdmission(AdmissionState state) {
    addOverride(
      eventAdmissionControllerProvider(_renderEvent).overrideWith(
        () => _FixedAdmissionController(state),
      ),
    );
  }

  /// CUJ 메인 — 구매 가능 상태 ("참가 신청하기").
  void eligible() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.eligible),
  );

  /// 비로그인 상태 ("로그인하고 신청하기").
  void guest() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.guest),
  );

  /// 본인인증 필요 상태 ("본인인증 후 신청하기").
  void identityRequired() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.identityRequired),
  );

  /// 파트너 심사 필요 상태 ("신청하기").
  void qualificationRequired() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.qualificationRequired),
  );

  /// 참여 조건 미달 상태 ("성별 조건이 맞지 않습니다.").
  void notEligible() => _applyAdmission(
    AdmissionState(
      status: EventAdmissionStatus.notEligible,
      ineligibleReason: '성별 조건이 맞지 않습니다.',
    ),
  );

  /// 정원 마감 / 매진 상태 ("마감된 이벤트").
  void soldOut() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.fullOrSoldOut),
  );

  /// 결제 미완료 — 이어하기 상태 ("결제 계속하기").
  void pendingPayment() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.pendingPayment),
  );

  /// 이미 신청 완료 상태 ("이미 신청한 이벤트").
  void applied() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.applied),
  );

  /// 심사 반려 상태 — destructive 버튼.
  void rejected() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.rejected),
  );

  /// 이벤트 종료 + 미참여 상태 ("종료된 이벤트").
  void eventEnded() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.eventEnded),
  );

  /// 이벤트 종료 + 매칭 결과 도착 ("매칭 결과 보기").
  void eventEndedWithResults() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.eventEndedWithResults),
  );

  /// 이벤트 종료 + 참여 완료 ("참여 완료").
  void eventEndedParticipated() => _applyAdmission(
    AdmissionState(status: EventAdmissionStatus.eventEndedParticipated),
  );

  /// admission 로딩 중 — 스피너 표시.
  void loading() {
    addOverride(
      eventAdmissionControllerProvider(_renderEvent).overrideWith(
        _LoadingAdmissionController.new,
      ),
    );
  }

  /// admission 조회 실패 — "오류 발생" errorContainer.
  void error() {
    addOverride(
      eventAdmissionControllerProvider(_renderEvent).overrideWith(
        _ErrorAdmissionController.new,
      ),
    );
  }

  /// 다크 모드 토글.
  void dark() => useDarkTheme();
}
