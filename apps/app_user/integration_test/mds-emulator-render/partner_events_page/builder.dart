// PartnerEventsPageBuilder — partner_events_page 전용 fluent API.

import 'dart:async';

import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/detail/partner_events_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

const _partnerId = 'partner-render-1';
final _base = DateTime(2026, 5, 20, 18);

Partner _mockPartner(String id) => Partner(
  id: id,
  name: '밍글릿 라운지',
  introduction: '강남에서 운영하는 소셜 라운지입니다.',
  address: '서울 강남구 테헤란로 123',
);

Event _mockEvent({
  required String id,
  required String title,
  required DateTime startTime,
  required String status,
  int currentParticipants = 18,
}) {
  return Event(
    id: id,
    partyId: 'party-$id',
    title: title,
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 2)),
    createdAt: _base,
    updatedAt: _base,
    currentParticipants: currentParticipants,
    status: status,
    location: Location(
      id: 'location-$id',
      partnerId: _partnerId,
      name: '밍글릿 강남홀',
      address: '서울 강남구 테헤란로 123',
      createdAt: _base,
      updatedAt: _base,
    ),
  );
}

final _defaultEvents = <Event>[
  _mockEvent(
    id: 'event-1',
    title: '강남 프라이데이 밍글',
    startTime: DateTime(2026, 6, 1, 19),
    status: 'scheduled',
  ),
  _mockEvent(
    id: 'event-2',
    title: '위켄드 소셜 나이트',
    startTime: DateTime(2026, 6, 2, 20),
    status: 'sold_out',
    currentParticipants: 40,
  ),
];

class PartnerEventsPageBuilder extends MdsScreenBuilder<PartnerEventsPage> {
  PartnerEventsPageBuilder()
    : super(
        page: const PartnerEventsPage(partnerId: _partnerId),
        base: [
          partnerCoordinatorProvider.overrideWithValue(
            MockPartnerCoordinator(),
          ),
        ],
      );

  void _withPartner() {
    addOverride(
      partnerDetailProvider.overrideWith(
        (ref, partnerId) async => _mockPartner(partnerId),
      ),
    );
  }

  /// 기본 상태: 이벤트 카드 리스트 노출.
  PartnerEventsPageBuilder withDefault() {
    _withPartner();
    addOverride(
      partnerEventsProvider.overrideWith(
        (ref, partnerId) async => _defaultEvents,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 이벤트 없음 상태.
  PartnerEventsPageBuilder withEmpty() {
    _withPartner();
    addOverride(
      partnerEventsProvider.overrideWith((ref, partnerId) async => const []),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 로딩 상태.
  PartnerEventsPageBuilder withLoading() {
    _withPartner();
    addOverride(
      partnerEventsProvider.overrideWith(
        (ref, partnerId) => Completer<List<Event>>().future,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 에러 상태.
  PartnerEventsPageBuilder withError() {
    _withPartner();
    addOverride(
      partnerEventsProvider.overrideWith(
        (ref, partnerId) async => throw Exception('render: forced error'),
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }
}
