// EventCardBuilder — event_card 전용 fluent API.
//
// MDS child spec(4 visible states: normal/today/soldOut/ended)를
// deterministic fixture(demoEvents)로 재현한다.

import 'package:flutter/material.dart';
import 'package:minglit_demo/minglit_demo.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

final Event _baseEvent = demoEvents.first;

class _EventCardRenderConfig {
  const _EventCardRenderConfig({
    required this.event,
    required this.currentTime,
  });

  final Event event;
  final DateTime currentTime;
}

final DateTime _normalNow = DemoWorld.now;

final DateTime _todayNow = DateTime(
  _baseEvent.startTime.year,
  _baseEvent.startTime.month,
  _baseEvent.startTime.day,
  _baseEvent.startTime.hour,
  _baseEvent.startTime.minute,
);

final DateTime _endedNow = _baseEvent.startTime.add(const Duration(days: 1));

final _EventCardRenderConfig _normalConfig = _EventCardRenderConfig(
  event: _baseEvent,
  currentTime: _normalNow,
);

final _EventCardRenderConfig _todayConfig = _EventCardRenderConfig(
  event: _baseEvent,
  currentTime: _todayNow,
);

final _EventCardRenderConfig _soldOutConfig = _EventCardRenderConfig(
  event: _baseEvent.copyWith(currentParticipants: _baseEvent.maxParticipants),
  currentTime: _normalNow,
);

final _EventCardRenderConfig _endedConfig = _EventCardRenderConfig(
  event: _baseEvent,
  currentTime: _endedNow,
);

final _eventCardRenderConfigProvider = Provider<_EventCardRenderConfig>(
  (_) => _normalConfig,
);

class _EventCardRenderPage extends ConsumerWidget {
  const _EventCardRenderPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(_eventCardRenderConfigProvider);

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 343,
          child: MinglitEventCard(
            event: config.event,
            currentTime: config.currentTime,
          ),
        ),
      ),
    );
  }
}

class EventCardBuilder extends MdsScreenBuilder<_EventCardRenderPage> {
  EventCardBuilder() : super(page: const _EventCardRenderPage());

  void _apply(_EventCardRenderConfig config) {
    addOverride(
      _eventCardRenderConfigProvider.overrideWith((_) => config),
    );
  }

  /// 기본 상태: 미래 이벤트 + 수용 인원 여유.
  void normal() => _apply(_normalConfig);

  /// 당일 상태: D-Day label 이 "오늘"로 바뀌는 케이스.
  void today() => _apply(_todayConfig);

  /// 마감 상태: currentParticipants >= maxParticipants.
  void soldOut() => _apply(_soldOutConfig);

  /// 종료 상태: currentTime 이 startTime 이후.
  void ended() => _apply(_endedConfig);

  /// 다크 모드.
  void dark() => useDarkTheme();
}
