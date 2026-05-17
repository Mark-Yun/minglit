// MdsCatalog — 한 화면의 모든 state 를 묶는 컨테이너.
//
// runner 가 본 카탈로그를 받아 testWidgets 를 자동 생성하고 PNG 캡처.

import 'builder.dart';
import 'state.dart';

class MdsCatalog<B extends MdsScreenBuilder<dynamic>> {
  const MdsCatalog({
    required this.screen,
    required this.mdsSpec,
    required this.builder,
    required this.states,
  });

  /// MDS spec 디렉토리명과 동일. snake_case.
  /// 예: 'home_page', 'event_application_detail_page'.
  final String screen;

  /// MDS spec 디렉토리 경로 (참고용). 인스펙션 워크플로우의 페어링 단서.
  /// 예: 'apps/mds/docs/public/specs/home_page/'
  final String mdsSpec;

  /// 새 builder 인스턴스 생성 함수.
  /// 각 state 마다 fresh builder 가 만들어져야 override 누적 방지.
  final B Function() builder;

  /// 이 화면의 모든 state.
  final List<MdsState<B>> states;
}
