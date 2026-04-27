// Fix #72 회귀 방지: visibility=null 전달 시 크래시 방어
// 회귀 경계: DB에서 visibility=null인 Party → Party.fromJson → PartyStatusEditSheet 전달부.
// Party.visibility의 @Default('public')이 제거되면 아래 모델 단위 테스트와
// end-to-end 위젯 테스트가 실패하여 회귀를 감지한다.
import 'package:app_partner/src/features/party/widgets/party_status_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget wrap({
    String currentStatus = 'active',
    ValueChanged<String>? onStatusSelected,
    String currentVisibility = 'public',
    ValueChanged<String>? onVisibilityChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PartyStatusEditSheet(
          currentStatus: currentStatus,
          onStatusSelected: onStatusSelected ?? (_) {},
          currentVisibility: currentVisibility,
          onVisibilityChanged: onVisibilityChanged,
        ),
      ),
    );
  }

  // Fix #72 회귀 경계: DB에서 visibility=null로 로드된 Party가
  // PartyStatusEditSheet에 전달되는 경로를 직접 재현한다.
  // Party.visibility의 @Default('public')이 제거되면 아래 두 테스트가 실패한다.
  group('Party 모델 — visibility null 정규화 (#72)', () {
    test(
      'DB에서 visibility=null인 파티 → Party.fromJson → visibility는 "public"으로 정규화됨',
      () {
        // 실제 크래시 경계: visibility 컬럼이 null인 기존 DB 레코드.
        // @Default('public')이 제거되면 party.visibility가 null이 되어
        // 이후 PartyStatusEditSheet 전달부에서 Null check operator 에러 발생.
        final party = Party.fromJson({
          'id': 'p-test-1',
          'partner_id': 'partner-1',
          'title': '테스트 파티',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'visibility': null, // DB에 null이 저장된 경우
        });
        expect(
          party.visibility,
          equals('public'),
          reason: 'Party.visibility @Default("public")이 null 레코드를 정규화해야 한다.',
        );
      },
    );

    testWidgets('DB에서 visibility=null인 파티 → PartyStatusEditSheet 크래시 없이 렌더', (
      tester,
    ) async {
      final party = Party.fromJson({
        'id': 'p-test-1',
        'partner_id': 'partner-1',
        'title': '테스트 파티',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
        'visibility': null,
      });

      // party.visibility가 정규화(public)되어야만 non-nullable currentVisibility에 전달 가능.
      // @Default('public')이 없으면 party.visibility가 null이 되어 타입 에러 또는 크래시 발생.
      await tester.pumpWidget(wrap(currentVisibility: party.visibility));
      await tester.pump();

      expect(find.text('운영 상태 변경'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });

  group('PartyStatusEditSheet — Fix #72 regression', () {
    testWidgets('기본값(public) visibility로 크래시 없이 렌더', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('운영 상태 변경'), findsOneWidget);
      expect(find.text('비공개'), findsOneWidget);
    });

    testWidgets('visibility=public → 비공개 스위치 OFF', (tester) async {
      await tester.pumpWidget(
        wrap(),
      );
      await tester.pump();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('visibility=private → 비공개 스위치 ON', (tester) async {
      await tester.pumpWidget(
        wrap(currentVisibility: 'private'),
      );
      await tester.pump();

      final switchFinder = find.byType(Switch);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });
  });

  group('PartyStatusEditSheet — 상태 선택', () {
    testWidgets('active 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          currentStatus: 'draft',
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('운영중 (공개)'));
      await tester.pump();

      expect(selected, 'active');
    });

    testWidgets('draft 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('임시저장 (비공개)'));
      await tester.pump();

      expect(selected, 'draft');
    });

    testWidgets('closed 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('종료됨'));
      await tester.pump();

      expect(selected, 'closed');
    });
  });

  group('PartyStatusEditSheet — 공개 범위 변경', () {
    testWidgets('스위치 ON → onVisibilityChanged("private") 호출', (tester) async {
      String? changedTo;
      await tester.pumpWidget(
        wrap(
          onVisibilityChanged: (v) => changedTo = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changedTo, 'private');
    });

    testWidgets('스위치 OFF → onVisibilityChanged("public") 호출', (tester) async {
      String? changedTo;
      await tester.pumpWidget(
        wrap(
          currentVisibility: 'private',
          onVisibilityChanged: (v) => changedTo = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changedTo, 'public');
    });
  });
}
