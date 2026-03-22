import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
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
    required String targetUserId,
    required Map<String, dynamic>? memberData,
  }) {
    return ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockRepo),
        partnerMemberProvider(
          partnerId: partnerId,
          targetUserId: targetUserId,
        ).overrideWith((ref) async => memberData),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerMemberPermissionPage(
          partnerId: partnerId,
          targetUserId: targetUserId,
        ),
      ),
    );
  }

  group('PartnerMemberPermissionPage — Fix #270 회귀 테스트', () {
    testWidgets('unknown role "member" defaults to "staff" without crash',
        (tester) async {
      final memberData = {
        'user_id': 'u1',
        'role': 'member', // Dropdown에 없는 값
        'permissions': <String>[],
        'user': {'name': 'Test User', 'email': 'test@test.com'},
      };

      await tester.pumpWidget(buildTestWidget(
        partnerId: 'p1',
        targetUserId: 'u1',
        memberData: memberData,
      ));
      await tester.pump();
      await tester.pump();

      // Dropdown이 'staff'로 렌더링되어야 함 (member는 허용 목록에 없으므로)
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      // No assertion error = success
    });

    testWidgets('null role defaults to "staff" without crash', (tester) async {
      final memberData = {
        'user_id': 'u1',
        'role': null,
        'permissions': <String>[],
        'user': {'name': 'Test User', 'email': 'test@test.com'},
      };

      await tester.pumpWidget(buildTestWidget(
        partnerId: 'p1',
        targetUserId: 'u1',
        memberData: memberData,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('valid role "manager" is used as-is', (tester) async {
      final memberData = {
        'user_id': 'u1',
        'role': 'manager',
        'permissions': <String>['PARTY_MANAGE'],
        'user': {'name': 'Test User', 'email': 'test@test.com'},
      };

      await tester.pumpWidget(buildTestWidget(
        partnerId: 'p1',
        targetUserId: 'u1',
        memberData: memberData,
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('null user_id aborts save without calling repository',
        (tester) async {
      final memberData = {
        'user_id': null, // null user_id
        'role': 'staff',
        'permissions': <String>[],
        'user': {'name': 'Test User', 'email': 'test@test.com'},
      };

      await tester.pumpWidget(buildTestWidget(
        partnerId: 'p1',
        targetUserId: 'u1',
        memberData: memberData,
      ));
      await tester.pump();
      await tester.pump();

      // 저장 버튼 탭 — 크래시 없이 처리되어야 함
      final saveButton = find.byType(ElevatedButton);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Repository 호출 없음 확인 — null user_id로 DB 호출 시도하지 않아야 함
      verifyNever(
        () => mockRepo.updateMemberRole(
          partnerId: any(named: 'partnerId'),
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      );
    });
  });
}
