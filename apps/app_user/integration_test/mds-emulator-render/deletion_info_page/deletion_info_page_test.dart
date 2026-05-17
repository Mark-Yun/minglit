// MDS screen: deletion_info_page
// 대응 MDS: apps/mds/docs/public/specs/deletion_info_page/
//
// 출력: docs/infra/mds-emulator-render/deletion_info_page/state-*.png
//
// 주의: reasonCode/reasonText 를 넘기는 "사유 있음" 변형은 constructor param 이므로
// 별도 builder 인스턴스 없이 단일 catalog 로 커버하기 어려워 제외.
// 기본 화면(사유 없음)으로 공통 레이아웃·정보 섹션을 커버함.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<DeletionInfoPageBuilder>(
  screen: 'deletion_info_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_info_page/',
  builder: DeletionInfoPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b, mdsIndex: 1),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
