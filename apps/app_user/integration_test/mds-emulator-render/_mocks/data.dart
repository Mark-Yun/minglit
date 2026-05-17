// Mock 데이터 팩토리. builder fluent 메서드들이 사용.
//
// 시간 의존 데이터는 [now] 파라미터로 주입 가능 — 매 호출 시 동일 시점 사용 시
// 캡처 PNG 의 D-1/D-2 같은 라벨이 시간 따라 변하지 않도록 한다.

import 'package:minglit_kit/minglit_kit.dart';

/// 결정적 캡처를 위한 기준 시간. 다른 값을 원하면 mock 메서드 호출 시 명시.
final DateTime mockEventsBaseTime = DateTime.utc(2026, 5, 17, 19);

/// [count] 개의 mock Event 를 [now] 기준으로 [count] 일 동안 생성.
/// [now] 미지정 시 [mockEventsBaseTime] 사용 (시간 freeze — 결정적 캡처).
List<Event> mockEvents({int count = 3, DateTime? now}) {
  final base = now ?? mockEventsBaseTime;
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
