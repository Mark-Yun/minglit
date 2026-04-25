import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_bottom_sheet.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DataController extends EntryGroupCheckinStatsController {
  _DataController(this._groups);
  final List<EntryGroupCheckinStats> _groups;

  @override
  Future<List<EntryGroupCheckinStats>> build(String eventId) async => _groups;
}

Widget _wrapData(
  Widget child, {
  required String eventId,
  required List<EntryGroupCheckinStats> groups,
}) {
  return ProviderScope(
    overrides: [
      entryGroupCheckinStatsControllerProvider(eventId).overrideWith(
        () => _DataController(groups),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
    ),
  );
}

void main() {
  group('EntryGroupBottomSheet', () {
    testWidgets('빈 그룹 — SizedBox.shrink() 렌더링', (tester) async {
      await tester.pumpWidget(
        _wrapData(
          const EntryGroupBottomSheet(eventId: 'event-1'),
          eventId: 'event-1',
          groups: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byType(EntryGroupRow), findsNothing);
    });

    testWidgets('그룹 있음 — DraggableScrollableSheet 표시', (tester) async {
      const groups = [
        EntryGroupCheckinStats(
          id: 'g1',
          label: '남 20대 초반',
          total: 14,
          checkedIn: 13,
        ),
        EntryGroupCheckinStats(
          id: 'g2',
          label: '여 20대 초반',
          total: 14,
          checkedIn: 5,
        ),
      ];

      await tester.pumpWidget(
        _wrapData(
          const EntryGroupBottomSheet(eventId: 'event-2'),
          eventId: 'event-2',
          groups: groups,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('엔트리 그룹별 현황'), findsOneWidget);
    });

    testWidgets('그룹 정렬 — 완충률 ≥90% 그룹이 먼저 노출', (tester) async {
      // g1: 5/20 = 25% (low), g2: 13/14 ≈ 93% (high)
      // 정렬 후 g2(남 20대 초반)가 먼저, g1(여 30대)이 나중에 와야 함
      const groups = [
        EntryGroupCheckinStats(
          id: 'g1',
          label: '여 30대',
          total: 20,
          checkedIn: 5,
        ),
        EntryGroupCheckinStats(
          id: 'g2',
          label: '남 20대 초반',
          total: 14,
          checkedIn: 13,
        ),
      ];

      await tester.pumpWidget(
        _wrapData(
          const EntryGroupBottomSheet(eventId: 'event-3'),
          eventId: 'event-3',
          groups: groups,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      // 서브타이틀: 완충률 높은 g2(남 20대 초반)가 먼저
      expect(
        find.text('남 20대 초반 13/14 · 여 30대 5/20'),
        findsOneWidget,
      );
    });

    testWidgets('에러 상태 — "불러오기 실패" 서브타이틀 표시', (tester) async {
      // _DataController로 먼저 초기화한 뒤, state setter로 AsyncError를 주입.
      // (async throw path는 handleValue 경로에서 Riverpod test 환경에서 동작 불안정)
      final container = ProviderContainer(
        overrides: [
          entryGroupCheckinStatsControllerProvider('event-err').overrideWith(
            () => _DataController([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 정상 초기화 대기
      await container.read(
        entryGroupCheckinStatsControllerProvider('event-err').future,
      );

      // AsyncError 상태 직접 주입
      container
          .read(
            entryGroupCheckinStatsControllerProvider('event-err').notifier,
          )
          .state = AsyncError(
        Exception('network error'),
        StackTrace.empty,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [EntryGroupBottomSheet(eventId: 'event-err')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('불러오기 실패 · 다시 시도'), findsOneWidget);
    });
  });
}
