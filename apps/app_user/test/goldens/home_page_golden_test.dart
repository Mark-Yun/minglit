@Tags(['golden'])
library;

import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'golden_test_helpers.dart';

void main() {
  final baseTime = DateTime(2026, 5, 10, 19);

  List<dynamic> buildOverrides({
    List<Event> events = const [],
    bool hasMore = false,
  }) {
    final mockHome = MockHomeCoordinator();

    return [
      homeCoordinatorProvider.overrideWithValue(mockHome),
      activeFiltersProvider.overrideWith(NoFiltersNotifier.new),
      recommendationFeedProvider.overrideWith(
        () => _FakeRecommendationFeedNotifier(
          events: events,
          hasMore: hasMore,
        ),
      ),
    ];
  }

  goldenTest(
    'HomePage empty feed',
    fileName: 'home_page_empty',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File('test/goldens/home_page_empty.render.txt').writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty feed',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const HomePage(),
              overrides: buildOverrides(),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'HomePage with events',
    fileName: 'home_page_with_events',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File(
        'test/goldens/home_page_with_events.render.txt',
      ).writeAsStringSync(dump);
    },
    builder: () {
      final events = List.generate(
        3,
        (i) => Event(
          id: 'e$i',
          partyId: 'p1',
          startTime: baseTime.add(Duration(days: i + 1)),
          endTime: baseTime.add(Duration(days: i + 1, hours: 2)),
          createdAt: baseTime,
          updatedAt: baseTime,
          title: '이벤트 ${i + 1}',
          currentParticipants: (i + 1) * 5,
        ),
      );
      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with events',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const HomePage(),
                overrides: buildOverrides(events: events),
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'HomePage empty feed (dark)',
    fileName: 'home_page_empty_dark',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File(
        'test/goldens/home_page_empty_dark.render.txt',
      ).writeAsStringSync(dump);
    },
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'empty feed (dark)',
          child: SizedBox(
            width: 390,
            height: 844,
            child: GoldenPageWrapper(
              page: const HomePage(),
              overrides: buildOverrides(),
              brightness: Brightness.dark,
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'HomePage with events (dark)',
    fileName: 'home_page_with_events_dark',
    pumpBeforeTest: (tester) async {
      await initGoldenDeps();
      await tester.pumpAndSettle();
      final dump = tester.binding.renderViews.first.toStringDeep();
      File(
        'test/goldens/home_page_with_events_dark.render.txt',
      ).writeAsStringSync(dump);
    },
    builder: () {
      final events = List.generate(
        3,
        (i) => Event(
          id: 'e$i',
          partyId: 'p1',
          startTime: baseTime.add(Duration(days: i + 1)),
          endTime: baseTime.add(Duration(days: i + 1, hours: 2)),
          createdAt: baseTime,
          updatedAt: baseTime,
          title: '이벤트 ${i + 1}',
          currentParticipants: (i + 1) * 5,
        ),
      );
      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'with events (dark)',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const HomePage(),
                overrides: buildOverrides(events: events),
                brightness: Brightness.dark,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _FakeRecommendationFeedNotifier extends RecommendationFeedNotifier {
  _FakeRecommendationFeedNotifier({
    required List<Event> events,
    required bool hasMore,
  }) : _events = events,
       _hasMore = hasMore;

  final List<Event> _events;
  final bool _hasMore;

  @override
  Future<RecommendationFeedState> build() async => RecommendationFeedState(
    events: _events,
    serverOffset: 0,
    hasMore: _hasMore,
  );
}
