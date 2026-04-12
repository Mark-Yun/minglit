// Ref #1318: IT-P08 — 팀원 관리 → 역할 배정 통합 테스트
//
// 검증 포인트:
// 1. 팀원 관리 페이지 진입 — 직원 관리 타이틀 표시
// 2. 팀원 목록 렌더링 — 이름/역할 표시
// 3. 팀원 없을 때 빈 상태 표시
// 4. 초대 버튼 탭 → "준비 중입니다." 스낵바
// 5. 권한 페이지 — 팀원 이름/이메일 표시
// 6. 권한 페이지 — 역할 드롭다운 3가지 항목 표시
// 7. 역할 변경 시 권한 자동 동기화 — owner 선택 시 모든 권한 활성화
// 8. 저장 버튼 탭 → updateMemberRole + updateMemberPermissions 호출
import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';

const _partnerId = 'partner-p08';
const _targetUserId = 'user-target-p08';

void main() {
  Widget buildApp(Widget child, {List<Object> overrides = const []}) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('IT-P08: 팀원 관리 → 역할 배정', () {
    testWidgets('팀원 관리 페이지 진입 — 직원 관리 타이틀 표시', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const PartnerMemberListPage(partnerId: _partnerId),
          overrides: [
            partnerMembersProvider(partnerId: _partnerId).overrideWith(
              (ref) async => [],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('직원 관리'), findsOneWidget);
    });

    testWidgets('팀원 목록 렌더링 — 이름과 역할 표시', (tester) async {
      final members = [
        {
          'user_id': 'u1',
          'role': 'manager',
          'user': {'name': '김철수', 'email': 'kim@example.com'},
        },
        {
          'user_id': 'u2',
          'role': 'staff',
          'user': {'name': '이영희', 'email': 'lee@example.com'},
        },
      ];

      await tester.pumpWidget(
        buildApp(
          const PartnerMemberListPage(partnerId: _partnerId),
          overrides: [
            partnerMembersProvider(partnerId: _partnerId).overrideWith(
              (ref) async => members,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('김철수'), findsOneWidget);
      expect(find.text('이영희'), findsOneWidget);
      expect(find.textContaining('manager'), findsOneWidget);
      expect(find.textContaining('staff'), findsOneWidget);
    });

    testWidgets('팀원 없을 때 빈 상태 메시지 표시', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const PartnerMemberListPage(partnerId: _partnerId),
          overrides: [
            partnerMembersProvider(partnerId: _partnerId).overrideWith(
              (ref) async => [],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('등록된 직원이 없습니다.'), findsOneWidget);
    });

    testWidgets('초대 버튼 탭 — 준비 중 스낵바 표시', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const PartnerMemberListPage(partnerId: _partnerId),
          overrides: [
            partnerMembersProvider(partnerId: _partnerId).overrideWith(
              (ref) async => [],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('직원 추가'));
      await tester.pumpAndSettle();

      expect(find.text('준비 중입니다.'), findsOneWidget);
    });

    testWidgets('권한 페이지 — 팀원 이름과 이메일 표시', (tester) async {
      final memberData = {
        'user_id': _targetUserId,
        'role': 'staff',
        'permissions': <String>[],
        'user': {'name': '박지현', 'email': 'park@example.com'},
      };

      await tester.pumpWidget(
        buildApp(
          const PartnerMemberPermissionPage(
            partnerId: _partnerId,
            targetUserId: _targetUserId,
          ),
          overrides: [
            partnerMemberProvider(
              partnerId: _partnerId,
              targetUserId: _targetUserId,
            ).overrideWith((ref) async => memberData),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('박지현'), findsOneWidget);
      expect(find.text('park@example.com'), findsOneWidget);
    });

    testWidgets('역할 드롭다운 — 3가지 역할 항목 표시', (tester) async {
      final memberData = {
        'user_id': _targetUserId,
        'role': 'staff',
        'permissions': <String>[],
        'user': {'name': '최민준', 'email': 'choi@example.com'},
      };

      await tester.pumpWidget(
        buildApp(
          const PartnerMemberPermissionPage(
            partnerId: _partnerId,
            targetUserId: _targetUserId,
          ),
          overrides: [
            partnerMemberProvider(
              partnerId: _partnerId,
              targetUserId: _targetUserId,
            ).overrideWith((ref) async => memberData),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open the role dropdown
      await tester.tap(find.text('Staff (단순 업무)'));
      await tester.pumpAndSettle();

      expect(find.text('Owner (모든 권한)'), findsOneWidget);
      expect(find.text('Manager (운영 및 심사)'), findsOneWidget);
      expect(find.text('Staff (단순 업무)'), findsWidgets);
    });

    testWidgets('역할 변경 시 권한 자동 동기화 — owner 선택 시 모든 권한 활성화', (tester) async {
      final memberData = {
        'user_id': _targetUserId,
        'role': 'staff',
        'permissions': <String>['VERIFY_LIST_VIEW'],
        'user': {'name': '정수아', 'email': 'jung@example.com'},
      };

      await tester.pumpWidget(
        buildApp(
          const PartnerMemberPermissionPage(
            partnerId: _partnerId,
            targetUserId: _targetUserId,
          ),
          overrides: [
            partnerMemberProvider(
              partnerId: _partnerId,
              targetUserId: _targetUserId,
            ).overrideWith((ref) async => memberData),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Change role to owner
      await tester.tap(find.text('Staff (단순 업무)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Owner (모든 권한)').last);
      await tester.pumpAndSettle();

      // All 9 checkboxes should be checked after owner role sync
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      ).toList();
      expect(checkboxes, hasLength(9));
      expect(checkboxes.every((cb) => cb.value == true), isTrue);
    });

    testWidgets('저장 버튼 탭 — updateMemberRole + updateMemberPermissions 호출', (
      tester,
    ) async {
      final mockRepo = MockPartnerRepository();
      when(
        () => mockRepo.updateMemberRole(
          partnerId: any(named: 'partnerId'),
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepo.updateMemberPermissions(
          partnerId: any(named: 'partnerId'),
          userId: any(named: 'userId'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async {});

      final memberData = {
        'user_id': _targetUserId,
        'role': 'staff',
        'permissions': <String>['VERIFY_LIST_VIEW'],
        'user': {'name': '홍길동', 'email': 'hong@example.com'},
      };

      await tester.pumpWidget(
        buildApp(
          const PartnerMemberPermissionPage(
            partnerId: _partnerId,
            targetUserId: _targetUserId,
          ),
          overrides: [
            partnerRepositoryProvider.overrideWithValue(mockRepo),
            partnerMemberProvider(
              partnerId: _partnerId,
              targetUserId: _targetUserId,
            ).overrideWith((ref) async => memberData),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal the save button if hidden
      await tester.ensureVisible(find.text('변경 사항 저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('변경 사항 저장'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepo.updateMemberRole(
          partnerId: _partnerId,
          userId: _targetUserId,
          role: 'staff',
        ),
      ).called(1);
      verify(
        () => mockRepo.updateMemberPermissions(
          partnerId: _partnerId,
          userId: _targetUserId,
          permissions: any(named: 'permissions'),
        ),
      ).called(1);
    });
  });
}
