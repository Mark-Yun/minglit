// MdsState — 선언적 state 정의.
//
// catalog 의 states list 에 등록되는 단위. setup 함수가 builder 에 적용되어
// 그 state 의 렌더링 결과를 만든다.

import 'builder.dart';

/// builder 에 state 셋업을 적용하는 함수.
typedef MdsStateSetup<B extends MdsScreenBuilder<dynamic>> =
    B Function(
      B builder,
    );

/// 한 화면의 한 state.
///
/// 예:
/// ```dart
/// MdsState('state-empty', (b) => b.empty(), mdsIndex: 1)
/// MdsState('state-with-events', (b) => b.withEvents(3), mdsIndex: 2)
/// MdsState('state-dark', (b) => b.dark())   // mdsIndex null = orphan
/// MdsState('state-pulse', (b) => b.pulse(), infiniteAnimation: true)
/// ```
///
/// - [name]: kebab-case, `state-<label>` 권장. screenshot name 의 후반부.
/// - [setup]: builder fluent 호출 chain. 반드시 builder 반환.
/// - [mdsIndex]: 페어되는 MDS `state_N.png` 의 N. orphan (디자인 없음) 이면 null.
/// - [tags]: 필터링 / 분류용. 예: `['smoke', 'edge', 'a11y']`.
/// - [infiniteAnimation]: true이면 runner가 `pumpAndSettle()` 대신 고정 pump를
///   사용한다. `repeat()` 애니메이션처럼 settle되지 않는 state에 필수.
class MdsState<B extends MdsScreenBuilder<dynamic>> {
  const MdsState(
    this.name,
    this.setup, {
    this.mdsIndex,
    this.tags = const [],
    this.infiniteAnimation = false,
  });

  final String name;
  final MdsStateSetup<B> setup;
  final int? mdsIndex;
  final List<String> tags;
  // Fix #2590: pumpAndSettle이 settle하지 않는 무한 반복 애니메이션 state용.
  final bool infiniteAnimation;
}
