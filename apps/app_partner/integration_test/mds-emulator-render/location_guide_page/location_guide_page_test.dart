// MDS screen: location_guide_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/location_guide_page/
//
// 출력: docs/infra/mds-emulator-render/location_guide_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<LocationGuidePageBuilder>(
  screen: 'location_guide_page',
  mdsSpec: 'apps/mds/docs/public/specs/location_guide_page/',
  builder: LocationGuidePageBuilder.new,
  states: [
    // Default
    MdsState('state-default', (b) => b, mdsIndex: 1),
    // Loading
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 2,
      infiniteAnimation: true,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
