import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockSocialRepository mockSocialRepo;

  setUp(() {
    mockSocialRepo = MockSocialRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(mockSocialRepo),
      ],
      child: const MaterialApp(
        home: BlockedPartnersPage(),
      ),
    );
  }

  group('BlockedPartnersPage — Fix #270 회귀 테스트', () {
    testWidgets('network failure shows snackbar and stops loading', (
      tester,
    ) async {
      when(
        () => mockSocialRepo.getBlockedPartners(),
      ).thenAnswer((_) async => throw Exception('Network error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(); // initState → _load()
      await tester.pump(); // Future completes with error
      await tester.pump(); // SnackBar animation

      // SnackBar 표시 확인
      expect(find.text('차단 목록을 불러오지 못했습니다'), findsOneWidget);

      // 로딩 인디케이터가 더 이상 표시되지 않아야 함
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('successful load renders partner list', (tester) async {
      when(() => mockSocialRepo.getBlockedPartners()).thenAnswer(
        (_) async => [
          {
            'id': 'p1',
            'name': 'Blocked Partner',
            'profile_image_url': null,
          },
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Blocked Partner'), findsOneWidget);
      expect(find.text('차단 해제'), findsOneWidget);
    });
  });
}
