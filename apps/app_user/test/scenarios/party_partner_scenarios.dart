import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:app_user/src/features/party/logic/party_coordinator.dart';
import 'package:app_user/src/features/party/party_curation_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../goldens/golden_test_helpers.dart'
    show MockPartnerCoordinator, MockPartyCoordinator;
import 'screenshot_scenario.dart';

class PartyPartnerScenarios {
  static final _baseTime = DateTime(2026, 4, 2, 19);

  static Location get _location => Location(
    id: 'location-1',
    partnerId: 'partner-with-events',
    name: '밍글릿 라운지',
    address: '서울 강남구 테헤란로 1',
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );

  static const _featuredPartner = Partner(
    id: 'partner-with-events',
    name: '밍글릿 소셜 클럽',
    introduction: '프리미엄 네트워킹 이벤트와 소셜 파티를 운영합니다.',
    address: '서울 강남구 테헤란로 1',
    bizName: '밍글릿 소셜 클럽',
    representativeName: '김민지',
    bizNumber: '123-45-67890',
    contactEmail: 'host@minglit.com',
    contactPhone: '02-1234-5678',
  );

  static List<Event> get _curationEvents => [
    Event(
      id: 'event-1',
      partyId: 'party-1',
      title: '신규 네트워킹 나이트',
      startTime: _baseTime.add(const Duration(days: 7)),
      endTime: _baseTime.add(const Duration(days: 7, hours: 3)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      location: _location,
      tickets: [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          name: '얼리버드',
          price: 35000,
          quantity: 40,
          soldCount: 18,
          createdAt: _baseTime,
          updatedAt: _baseTime,
        ),
      ],
    ),
    Event(
      id: 'event-2',
      partyId: 'party-2',
      title: '성수 소셜 믹서',
      startTime: _baseTime.add(const Duration(days: 10)),
      endTime: _baseTime.add(const Duration(days: 10, hours: 4)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      location: _location,
      tickets: [
        Ticket(
          id: 'ticket-2',
          eventId: 'event-2',
          name: '일반 입장',
          price: 42000,
          quantity: 60,
          soldCount: 24,
          createdAt: _baseTime,
          updatedAt: _baseTime,
        ),
      ],
    ),
  ];

  static List<Event> get _partnerEvents => [
    Event(
      id: 'partner-event-1',
      partyId: 'partner-party-1',
      title: '프라이빗 디너 밋업',
      startTime: _baseTime.add(const Duration(days: 5)),
      endTime: _baseTime.add(const Duration(days: 5, hours: 2)),
      createdAt: _baseTime,
      updatedAt: _baseTime,
      location: _location,
      tickets: [
        Ticket(
          id: 'partner-ticket-1',
          eventId: 'partner-event-1',
          name: '초대권',
          price: 55000,
          quantity: 30,
          soldCount: 8,
          createdAt: _baseTime,
          updatedAt: _baseTime,
        ),
      ],
    ),
  ];

  static Partner _partnerById(String partnerId) {
    if (partnerId == 'partner-with-events') {
      return _featuredPartner;
    }
    return _featuredPartner.copyWith(
      id: 'partner-no-events',
      name: '밍글릿 프라이빗 살롱',
      introduction: null,
      address: '서울 성동구 연무장길 20',
    );
  }

  static List<Event> _eventsByPartnerId(String partnerId) {
    return partnerId == 'partner-with-events' ? _partnerEvents : <Event>[];
  }

  static List<Event> _curationByType(EventFeedType type) {
    return type == EventFeedType.newArrivals ? _curationEvents : <Event>[];
  }

  static List<dynamic> _partyCurationOverrides(EventFeedType type) => [
    partyCoordinatorProvider.overrideWithValue(MockPartyCoordinator()),
    eventFeedProvider.overrideWith((ref, args) async {
      return _curationByType(args.type);
    }),
  ];

  static List<dynamic> _partnerDetailOverrides(String partnerId) => [
    partnerCoordinatorProvider.overrideWithValue(MockPartnerCoordinator()),
    partnerDetailProvider.overrideWith((ref, id) async => _partnerById(id)),
    partnerEventsProvider.overrideWith(
      (ref, id) async => _eventsByPartnerId(id),
    ),
  ];

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'party_curation_with_events',
      page: const PartyCurationPage(type: EventFeedType.newArrivals),
      overrides: _partyCurationOverrides(EventFeedType.newArrivals),
    ),
    ScreenshotScenario(
      name: 'party_curation_empty_state',
      page: const PartyCurationPage(type: EventFeedType.closingSoon),
      overrides: _partyCurationOverrides(EventFeedType.closingSoon),
    ),
    ScreenshotScenario(
      name: 'partner_detail_with_upcoming_event',
      page: const PartnerDetailPage(partnerId: 'partner-with-events'),
      overrides: _partnerDetailOverrides('partner-with-events'),
    ),
    ScreenshotScenario(
      name: 'partner_detail_empty_events',
      page: const PartnerDetailPage(partnerId: 'partner-no-events'),
      overrides: _partnerDetailOverrides('partner-no-events'),
    ),
  ];
}
