// Mock 데이터 팩토리. builder fluent 메서드들이 사용.

import 'package:minglit_kit/minglit_kit.dart';

/// [count] 개의 mock Event 를 생성. 기준 시간은 2026-05-17 19:00.
List<Event> mockEvents({int count = 3}) {
  final base = DateTime(2026, 5, 17, 19);
  return List.generate(
    count,
    (i) => Event(
      id: 'mock-event-$i',
      partyId: 'mock-party-1',
      startTime: base.add(Duration(days: i + 1)),
      endTime: base.add(Duration(days: i + 1, hours: 2)),
      createdAt: base,
      updatedAt: base,
      title: 'Mock 이벤트 ${i + 1}',
      currentParticipants: (i + 1) * 5,
    ),
  );
}
