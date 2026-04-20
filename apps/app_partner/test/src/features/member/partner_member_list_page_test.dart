import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockPartnerRepository mockRepo;

  setUp(() {
    mockRepo = MockPartnerRepository();
  });

  Widget buildTestWidget({
    required String partnerId,
    required List<Map<String, dynamic>> members,
  }) {
    when(
      () => mockRepo.getPartnerMembers(any()),
    ).thenAnswer((_) async => members);

    return ProviderScope(
      overrides: [partnerRepositoryProvider.overrideWithValue(mockRepo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerMemberListPage(partnerId: partnerId),
      ),
    );
  }

  group('PartnerMemberListPage — Fix #1662 회귀 테스트', () {
    testWidgets(
      'owner role은 빈 괄호 없이 "소유자" 배지로 렌더링된다',
      (tester) async {
        // Fix #1662: RPC가 email을 반환하지 않아 "owner ()" 빈 괄호가 보였던 케이스
        final members = [
          {
            'user_id': 'u1',
            'role': 'owner',
            'user': {'name': 'Alice', 'email': ''},
          },
        ];

        await tester.pumpWidget(
          buildTestWidget(partnerId: 'p1', members: members),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alice'), findsOneWidget);
        expect(find.text('소유자'), findsOneWidget);
        // 빈 괄호 또는 legacy "역할:" 접두사가 노출되면 안 됨
        expect(find.textContaining('()'), findsNothing);
        expect(find.textContaining('역할:'), findsNothing);
        expect(find.byType(MinglitBadge), findsOneWidget);
      },
    );

    testWidgets('manager role은 "매니저" 배지로 렌더링된다', (tester) async {
      final members = [
        {
          'user_id': 'u1',
          'role': 'manager',
          'user': {'name': 'Bob', 'email': ''},
        },
      ];

      await tester.pumpWidget(
        buildTestWidget(partnerId: 'p1', members: members),
      );
      await tester.pumpAndSettle();

      expect(find.text('매니저'), findsOneWidget);
      expect(find.byType(MinglitBadge), findsOneWidget);
    });

    testWidgets(
      'unknown role은 "직원" 배지로 폴백된다 (크래시 방지)',
      (tester) async {
        final members = [
          {
            'user_id': 'u1',
            'role': 'member', // 허용 목록 외 값
            'user': {'name': 'Charlie', 'email': ''},
          },
        ];

        await tester.pumpWidget(
          buildTestWidget(partnerId: 'p1', members: members),
        );
        await tester.pumpAndSettle();

        expect(find.text('직원'), findsOneWidget);
      },
    );

    testWidgets(
      '긴 이름은 한 줄로 ellipsis 처리되어 배지 정렬이 흔들리지 않는다',
      (tester) async {
        // Fix #1662: maxLines/overflow 없으면 긴 이름이 줄바꿈되어
        // trailing MinglitBadge + chevron_right 정렬이 깨졌던 케이스
        const longName = '김매우길고길고길고길고길고길고긴이름테스트';
        final members = [
          {
            'user_id': 'u1',
            'role': 'owner',
            'user': {'name': longName, 'email': ''},
          },
        ];

        await tester.pumpWidget(
          buildTestWidget(partnerId: 'p1', members: members),
        );
        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text(longName));
        expect(titleText.maxLines, 1);
        expect(titleText.overflow, TextOverflow.ellipsis);
      },
    );
  });
}
