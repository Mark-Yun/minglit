// Ref #1339: IT-P09 — 반복 이벤트 통합 테스트
//
// 검증 포인트:
// TC-P09-001: 반복 규칙 설정 UI 상태 — toggle ON, pattern 선택, 요일 선택
// TC-P09-002: RecurrenceManagementScreen — active 상태 → pause → paused 상태 전환
// TC-P09-003: RecurrenceManagementScreen — cancel 다이얼로그 → "취소하기" 탭 → cancel() 호출
// TC-P09-004: RecurrenceManagementScreen — paused 상태 → resume → active 상태 복귀
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';

class _MockRecurrenceRuleRepository extends Mock
    implements RecurrenceRuleRepository {}

const _partyId = 'party-p09';
const _ruleId = 'rule-p09';

RecurrenceRule _makeRule({
  RecurrenceStatus status = RecurrenceStatus.active,
  RecurrencePattern pattern = RecurrencePattern.weekly,
  List<int> daysOfWeek = const [1, 3],
}) {
  final now = DateTime(2026, 4, 13);
  return RecurrenceRule(
    id: _ruleId,
    partyId: _partyId,
    pattern: pattern,
    startTime: '19:00',
    endTime: '21:00',
    createdAt: now,
    updatedAt: now,
    daysOfWeek: daysOfWeek,
    status: status,
  );
}

Widget _buildApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: child,
    ),
  );
}

void main() {
  late _MockRecurrenceRuleRepository mockRepo;

  setUp(() {
    mockRepo = _MockRecurrenceRuleRepository();
  });

  group('IT-P09: 반복 이벤트', () {
    // ----------------------------------------------------------------
    // TC-P09-001: 반복 규칙 설정 UI 상태
    // ----------------------------------------------------------------
    group('TC-P09-001: 반복 규칙 설정 상태 관리', () {
      test('toggle ON 시 isEnabled가 true가 된다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          recurrenceSettingsControllerProvider.notifier,
        );

        expect(
          container.read(recurrenceSettingsControllerProvider).isEnabled,
          isFalse,
        );

        notifier.toggle();

        expect(
          container.read(recurrenceSettingsControllerProvider).isEnabled,
          isTrue,
        );
      });

      test('pattern을 monthly로 변경하면 daysOfWeek가 빈 목록이 된다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          recurrenceSettingsControllerProvider.notifier,
        );

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.monthly);

        final state = container.read(recurrenceSettingsControllerProvider);
        expect(state.pattern, RecurrencePattern.monthly);
        expect(state.daysOfWeek, isEmpty);
      });

      test('weekly 패턴에서 요일 선택/해제 시 daysOfWeek가 정렬된 상태로 업데이트된다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          recurrenceSettingsControllerProvider.notifier,
        );

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.weekly);

        // 초기 daysOfWeek: [1] (기본값)
        notifier.toggleDay(3); // 추가 → [1, 3]
        notifier.toggleDay(5); // 추가 → [1, 3, 5]

        var state = container.read(recurrenceSettingsControllerProvider);
        expect(state.daysOfWeek, [1, 3, 5]);

        notifier.toggleDay(1); // 제거 → [3, 5]
        state = container.read(recurrenceSettingsControllerProvider);
        expect(state.daysOfWeek, [3, 5]);
      });

      test('endDate 설정 후 previewDates는 endDate 이후 날짜를 반환하지 않는다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          recurrenceSettingsControllerProvider.notifier,
        );

        notifier.toggle();
        notifier.setPattern(RecurrencePattern.weekly);
        // 월요일(1) 선택
        // endDate를 오늘 기준 7일 후로 설정
        final endDate = DateTime.now().add(const Duration(days: 7));
        final endDateStr =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        notifier.setEndDate(endDateStr);

        final dates = notifier.previewDates(count: 10);
        // endDate 이후 날짜는 없어야 한다
        for (final date in dates) {
          expect(date.isAfter(endDate), isFalse);
        }
      });

      test('비활성 상태에서 previewDates는 빈 목록을 반환한다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          recurrenceSettingsControllerProvider.notifier,
        );
        // toggle 없이 (기본 isEnabled = false)
        final dates = notifier.previewDates();
        expect(dates, isEmpty);
      });
    });

    // ----------------------------------------------------------------
    // TC-P09-002: RecurrenceManagementScreen — active → pause
    // ----------------------------------------------------------------
    testWidgets('TC-P09-002: active 규칙 — 일시 정지 버튼 탭 → pause() 호출', (
      tester,
    ) async {
      final activeRule = _makeRule(status: RecurrenceStatus.active);

      when(() => mockRepo.pause(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.getByPartyId(any()),
      ).thenAnswer((_) async => activeRule);

      await tester.pumpWidget(
        _buildApp(
          RecurrenceManagementScreen(partyId: _partyId),
          overrides: [
            recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
            partyRecurrenceRuleProvider(_partyId).overrideWith(
              (ref) async => activeRule,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // active 상태 chip 확인
      expect(find.text('활성'), findsOneWidget);

      // 일시 정지 버튼 확인 및 탭
      expect(find.text('일시 정지'), findsOneWidget);
      await tester.tap(find.text('일시 정지'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.pause(_ruleId)).called(1);
    });

    // ----------------------------------------------------------------
    // TC-P09-003: 반복 규칙 취소 확인 다이얼로그 → "취소하기" 탭 → cancel() 호출
    // ----------------------------------------------------------------
    testWidgets('TC-P09-003: active 규칙 — 규칙 취소 탭 → 다이얼로그 확인 → cancel() 호출', (
      tester,
    ) async {
      final activeRule = _makeRule(status: RecurrenceStatus.active);

      when(() => mockRepo.cancel(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.getByPartyId(any()),
      ).thenAnswer((_) async => activeRule);

      await tester.pumpWidget(
        _buildApp(
          RecurrenceManagementScreen(partyId: _partyId),
          overrides: [
            recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
            partyRecurrenceRuleProvider(_partyId).overrideWith(
              (ref) async => activeRule,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 규칙 취소 버튼 탭
      expect(find.text('규칙 취소'), findsOneWidget);
      await tester.tap(find.text('규칙 취소'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 표시 확인
      expect(find.text('반복 규칙 취소'), findsOneWidget);
      expect(find.text('반복 규칙을 취소하면 되돌릴 수 없습니다. 계속하시겠습니까?'), findsOneWidget);

      // "취소하기" 버튼 탭
      await tester.tap(find.text('취소하기'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.cancel(_ruleId)).called(1);
    });

    testWidgets('TC-P09-003-V: 다이얼로그에서 "아니오" 탭 시 cancel() 호출되지 않음', (
      tester,
    ) async {
      final activeRule = _makeRule(status: RecurrenceStatus.active);

      when(
        () => mockRepo.getByPartyId(any()),
      ).thenAnswer((_) async => activeRule);

      await tester.pumpWidget(
        _buildApp(
          RecurrenceManagementScreen(partyId: _partyId),
          overrides: [
            recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
            partyRecurrenceRuleProvider(_partyId).overrideWith(
              (ref) async => activeRule,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('규칙 취소'));
      await tester.pumpAndSettle();

      expect(find.text('반복 규칙 취소'), findsOneWidget);

      await tester.tap(find.text('아니오'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.cancel(any()));
    });

    // ----------------------------------------------------------------
    // TC-P09-004: paused 규칙 → resume → active 상태 복귀
    // ----------------------------------------------------------------
    testWidgets('TC-P09-004: paused 규칙 — resume 버튼 탭 → resume() 호출', (
      tester,
    ) async {
      final pausedRule = _makeRule(status: RecurrenceStatus.paused);

      when(() => mockRepo.resume(any())).thenAnswer((_) async {});
      when(
        () => mockRepo.getByPartyId(any()),
      ).thenAnswer((_) async => pausedRule);

      await tester.pumpWidget(
        _buildApp(
          RecurrenceManagementScreen(partyId: _partyId),
          overrides: [
            recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
            partyRecurrenceRuleProvider(_partyId).overrideWith(
              (ref) async => pausedRule,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // paused 상태 chip 확인
      expect(find.text('일시 정지'), findsWidgets);

      // resume 버튼 확인 및 탭
      expect(find.text('재개'), findsOneWidget);
      await tester.tap(find.text('재개'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.resume(_ruleId)).called(1);
    });

    testWidgets('TC-P09-004-V: cancelled 규칙은 버튼을 표시하지 않는다', (tester) async {
      final cancelledRule = _makeRule(status: RecurrenceStatus.cancelled);

      await tester.pumpWidget(
        _buildApp(
          RecurrenceManagementScreen(partyId: _partyId),
          overrides: [
            recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
            partyRecurrenceRuleProvider(_partyId).overrideWith(
              (ref) async => cancelledRule,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('취소됨'), findsOneWidget);
      expect(find.text('취소된 규칙은 재활성화할 수 없습니다.'), findsOneWidget);

      // pause/resume/cancel 버튼이 없어야 함
      expect(find.text('일시 정지'), findsNothing);
      expect(find.text('재개'), findsNothing);
      expect(find.text('규칙 취소'), findsNothing);
    });
  });
}
