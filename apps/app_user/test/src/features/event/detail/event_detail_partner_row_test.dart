// Fix #1601: 파트너 프로필 행 탭 시 파트너 상세 화면 미진입 회귀 방지
//
// Root cause: GestureDetector에 behavior: HitTestBehavior.opaque 누락.
// Row 내 여백(SizedBox 등 투명 영역) 탭 시 히트 테스트가 실패해 onTap이 호출되지 않았음.
// 파트너 이름 텍스트 탭 → /partners/:id 네비게이션 동작을 검증한다.
import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../integration/utils/test_app.dart';

class _MockPartnerRepository extends Mock implements PartnerRepository {}

class _DataEventDetailController extends EventDetailController {
  _DataEventDetailController(this._event);
  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

class _GuestAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    return AdmissionState(status: EventAdmissionStatus.guest);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  const partnerId = 'test-partner-id';
  const partnerName = '테스트 파트너';
  final now = DateTime(2026, 4, 19, 10);

  final testEvent = Event(
    id: 'test-event-id',
    partyId: 'test-party-id',
    startTime: now.add(const Duration(days: 7)),
    endTime: now.add(const Duration(days: 7, hours: 3)),
    createdAt: now,
    updatedAt: now,
    party: Party(
      id: 'test-party-id',
      partnerId: partnerId,
      title: '테스트 파티',
      createdAt: now,
      updatedAt: now,
      partner: const Partner(id: partnerId, name: partnerName),
    ),
    tickets: [
      Ticket(
        id: 'test-ticket-1',
        name: 'General',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );

  group('EventDetail 파트너 행 탭 네비게이션', () {
    testWidgets('파트너 이름 탭 시 PartnerDetailPage로 이동한다', (tester) async {
      setKoreanLocale(tester);
      final mockPartnerRepo = _MockPartnerRepository();
      when(() => mockPartnerRepo.getPartnerById(partnerId)).thenAnswer(
        (_) async => const Partner(id: partnerId, name: partnerName),
      );

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/events/test-event-id',
          additionalOverrides: [
            eventDetailControllerProvider(
              'test-event-id',
            ).overrideWith(() => _DataEventDetailController(testEvent)),
            eventAdmissionControllerProvider(
              testEvent,
            ).overrideWith(_GuestAdmissionController.new),
            eventDetailNowProvider.overrideWith(
              (_) =>
                  () => now,
            ),
            partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          ],
        ),
      );

      // pump without pumpAndSettle — EventDetailPage has internal timers
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text(partnerName), findsOneWidget);

      await tester.tap(find.text(partnerName));

      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(find.byType(PartnerDetailPage), findsOneWidget);
    });
  });
}
