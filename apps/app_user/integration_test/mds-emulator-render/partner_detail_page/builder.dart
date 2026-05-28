// PartnerDetailPageBuilder — partner_detail_page 전용 fluent API.

import 'dart:async';

import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

const _partnerId = 'partner-detail-render-1';
final _base = DateTime(2026, 5, 20, 18);

Partner _mockPartner(String id) => Partner(
  id: id,
  name: '밍글릿 라운지',
  introduction: '강남에서 운영하는 소셜 라운지입니다.',
  address: '서울 강남구 테헤란로 123',
  contactPhone: '02-555-1234',
  contactEmail: 'hello@minglit.kr',
  representativeName: '김대표',
  bizName: '밍글릿 라운지',
  bizNumber: '123-45-67890',
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

class PartnerDetailPageBuilder extends MdsScreenBuilder<PartnerDetailPage> {
  PartnerDetailPageBuilder()
    : super(
        page: const PartnerDetailPage(partnerId: _partnerId),
        base: [
          partnerCoordinatorProvider.overrideWithValue(
            MockPartnerCoordinator(),
          ),
        ],
      );

  /// 기본 상태: 파트너 + 진행중 이벤트 노출.
  PartnerDetailPageBuilder withDefault() {
    addOverride(
      partnerDetailProvider.overrideWith(
        (ref, partnerId) async => _mockPartner(partnerId),
      ),
    );
    addOverride(
      partnerEventsProvider.overrideWith(
        (ref, partnerId) async => _defaultEvents,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 로딩 상태: partner fetch pending.
  PartnerDetailPageBuilder withLoading() {
    addOverride(
      partnerDetailProvider.overrideWith(
        (ref, partnerId) => Completer<Partner?>().future,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 에러 상태.
  PartnerDetailPageBuilder withError() {
    addOverride(
      partnerDetailProvider.overrideWith(
        (ref, partnerId) async => throw Exception('render: forced error'),
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 존재하지 않는 파트너 상태.
  PartnerDetailPageBuilder withNotFound() {
    addOverride(
      partnerDetailProvider.overrideWith((ref, partnerId) async => null),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 파트너는 정상, 진행중 이벤트 없음.
  PartnerDetailPageBuilder withEmptyEvents() {
    addOverride(
      partnerDetailProvider.overrideWith(
        (ref, partnerId) async => _mockPartner(partnerId),
      ),
    );
    addOverride(
      partnerEventsProvider.overrideWith((ref, partnerId) async => const []),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }
}
