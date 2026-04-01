@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:app_user/src/features/party/logic/party_coordinator.dart';
import 'package:app_user/src/features/party/party_curation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 4, 2, 19);
  final location = Location(
    id: 'location-1',
    partnerId: 'partner-with-events',
    name: '밍글릿 라운지',
    address: '서울 강남구 테헤란로 1',
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  final curationEvents = [
    Event(
      id: 'event-1',
      partyId: 'party-1',
      title: '신규 네트워킹 나이트',
      startTime: baseTime.add(const Duration(days: 7)),
      endTime: baseTime.add(const Duration(days: 7, hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      location: location,
      tickets: [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          name: '얼리버드',
          price: 35000,
          quantity: 40,
          soldCount: 18,
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ],
    ),
    Event(
      id: 'event-2',
      partyId: 'party-2',
      title: '성수 소셜 믹서',
      startTime: baseTime.add(const Duration(days: 10)),
      endTime: baseTime.add(const Duration(days: 10, hours: 4)),
      createdAt: baseTime,
      updatedAt: baseTime,
      location: location,
      tickets: [
        Ticket(
          id: 'ticket-2',
          eventId: 'event-2',
          name: '일반 입장',
          price: 42000,
          quantity: 60,
          soldCount: 24,
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ],
    ),
  ];

  const featuredPartner = Partner(
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

  final quietPartner = featuredPartner.copyWith(
    id: 'partner-no-events',
    name: '밍글릿 프라이빗 살롱',
    introduction: null,
    address: '서울 성동구 연무장길 20',
  );

  final partnerEvents = [
    Event(
      id: 'partner-event-1',
      partyId: 'partner-party-1',
      title: '프라이빗 디너 밋업',
      startTime: baseTime.add(const Duration(days: 5)),
      endTime: baseTime.add(const Duration(days: 5, hours: 2)),
      createdAt: baseTime,
      updatedAt: baseTime,
      location: location,
      tickets: [
        Ticket(
          id: 'partner-ticket-1',
          eventId: 'partner-event-1',
          name: '초대권',
          price: 55000,
          quantity: 30,
          soldCount: 8,
          createdAt: baseTime,
          updatedAt: baseTime,
        ),
      ],
    ),
  ];

  setUpAll(() async {
    await initGoldenDeps();
  });

  goldenTest(
    'Party and partner pages',
    fileName: 'party_partner_pages',
    pumpBeforeTest: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'party curation with events',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PartyCurationPage(type: EventFeedType.newArrivals),
              overrides: [
                partyCoordinatorProvider.overrideWithValue(
                  MockPartyCoordinator(),
                ),
                eventFeedProvider.overrideWith((ref, args) async {
                  return args.type == EventFeedType.newArrivals
                      ? curationEvents
                      : <Event>[];
                }),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'party curation empty state',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PartyCurationPage(type: EventFeedType.closingSoon),
              overrides: [
                partyCoordinatorProvider.overrideWithValue(
                  MockPartyCoordinator(),
                ),
                eventFeedProvider.overrideWith((ref, args) async {
                  return args.type == EventFeedType.newArrivals
                      ? curationEvents
                      : <Event>[];
                }),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'partner detail with upcoming event',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PartnerDetailPage(partnerId: 'partner-with-events'),
              overrides: [
                partnerCoordinatorProvider.overrideWithValue(
                  MockPartnerCoordinator(),
                ),
                partnerDetailProvider.overrideWith((ref, partnerId) async {
                  return partnerId == 'partner-with-events'
                      ? featuredPartner
                      : quietPartner;
                }),
                partnerEventsProvider.overrideWith((ref, partnerId) async {
                  return partnerId == 'partner-with-events'
                      ? partnerEvents
                      : <Event>[];
                }),
              ],
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'partner detail empty events',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const PartnerDetailPage(partnerId: 'partner-no-events'),
              overrides: [
                partnerCoordinatorProvider.overrideWithValue(
                  MockPartnerCoordinator(),
                ),
                partnerDetailProvider.overrideWith((ref, partnerId) async {
                  return partnerId == 'partner-with-events'
                      ? featuredPartner
                      : quietPartner;
                }),
                partnerEventsProvider.overrideWith((ref, partnerId) async {
                  return partnerId == 'partner-with-events'
                      ? partnerEvents
                      : <Event>[];
                }),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
