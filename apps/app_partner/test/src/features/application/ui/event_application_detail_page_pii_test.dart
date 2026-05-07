// Fix #2250: regression tests — partner application detail page must not render
// actual name (실명), gender (성별), or exact birth date (생년월일) per PM #1141.
//
// These tests verify PIPA §17 compliance: partner-visible fields are limited to
// username (닉네임), age (연령대, from birth_year), and is_verified (인증 정보).

import 'package:app_partner/src/features/application/event_application_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

EventApplication _makeApplication({
  String name = '김철수',
  String username = '닉네임123',
  String? gender = 'male',
  DateTime? birthDate,
  int? birthYear = 1995,
}) {
  final now = DateTime(2026, 5, 7);
  return EventApplication(
    id: 'app_1',
    eventId: 'event_1',
    ticketId: 'ticket_1',
    userId: 'user_1',
    status: 'pending_review',
    createdAt: now,
    updatedAt: now,
    user: UserProfile(
      id: 'user_1',
      name: name,
      username: username,
      gender: gender,
      birthDate: birthDate,
      birthYear: birthYear,
    ),
  );
}

Widget _buildPage(EventApplication application) {
  return ProviderScope(
    overrides: [
      eventApplicationDetailProvider('app_1').overrideWith(
        (ref) async => application,
      ),
    ],
    child: const MaterialApp(
      home: EventApplicationDetailPage(applicationId: 'app_1'),
    ),
  );
}

void main() {
  group('EventApplicationDetailPage — PII compliance (Fix #2250)', () {
    testWidgets('shows username (닉네임) not actual name (실명)', (tester) async {
      final app = _makeApplication(name: '김철수', username: '닉네임123');

      await tester.pumpWidget(_buildPage(app));
      await tester.pump();

      expect(find.text('닉네임123'), findsOneWidget);
      // Fix #2250: actual name must NOT appear
      expect(find.text('김철수'), findsNothing);
    });

    testWidgets('does not show gender (성별 제외 per PM #1141)', (tester) async {
      final app = _makeApplication(gender: 'male');

      await tester.pumpWidget(_buildPage(app));
      await tester.pump();

      // Fix #2250: gender labels must not appear
      expect(find.text('남'), findsNothing);
      expect(find.text('여'), findsNothing);
    });

    testWidgets('does not show exact birth date (생년월일)', (tester) async {
      final app = _makeApplication(
        birthDate: DateTime(1995, 3, 15),
        birthYear: 1995,
      );

      await tester.pumpWidget(_buildPage(app));
      await tester.pump();

      // Fix #2250: exact DOB format must not appear
      expect(find.textContaining('1995.03.15'), findsNothing);
      expect(find.textContaining('1995.3.15'), findsNothing);
    });

    testWidgets('shows age (연령대) derived from birth_year', (tester) async {
      final app = _makeApplication(birthYear: 1995);

      await tester.pumpWidget(_buildPage(app));
      await tester.pump();

      // 2026 - 1995 = 31
      expect(find.text('31세'), findsOneWidget);
    });

    testWidgets('shows fallback when username is empty', (tester) async {
      final app = _makeApplication(username: '');

      await tester.pumpWidget(_buildPage(app));
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      // Fix #2250: still must not show actual name
      expect(find.text('김철수'), findsNothing);
    });
  });
}
