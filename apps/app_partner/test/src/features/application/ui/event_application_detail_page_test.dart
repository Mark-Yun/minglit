import 'package:app_partner/src/features/application/event_application_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  final now = DateTime(2026, 5, 30, 12);

  EventApplication makePendingApplication() {
    return EventApplication(
      id: 'app_pending',
      eventId: 'event_1',
      ticketId: 'ticket_1',
      userId: 'user_1',
      status: 'pending_review',
      createdAt: now,
      updatedAt: now,
      user: const UserProfile(
        id: 'user_1',
        name: '테스트유저',
        username: 'test_user',
        gender: 'female',
        birthYear: 1999,
      ),
    );
  }

  Widget buildPage({
    required EventRepository eventRepository,
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(eventRepository),
      ],
      child: const MaterialApp(
        home: EventApplicationDetailPage(applicationId: 'app_pending'),
      ),
    );
  }

  testWidgets(
    'Fix #1316: dialog open state에서 route teardown 시 예외가 발생하지 않는다',
    (tester) async {
      final eventRepository = MockEventRepository();
      when(
        () => eventRepository.getApplicationById('app_pending'),
      ).thenAnswer((_) async => makePendingApplication());

      await tester.pumpWidget(buildPage(eventRepository: eventRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '거절'));
      await tester.pumpAndSettle();
      expect(find.text('거절 사유'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
