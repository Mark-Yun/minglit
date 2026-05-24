// MDS screen: identity_verification_screen
// 대응 MDS: apps/mds/docs/public/specs/identity_verification_screen/
//
// 출력: docs/infra/mds-emulator-render/identity_verification_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<IdentityVerificationScreenBuilder>(
  screen: 'identity_verification_screen',
  mdsSpec: 'apps/mds/docs/public/specs/identity_verification_screen/',
  builder: IdentityVerificationScreenBuilder.new,
  states: [
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    MdsState('state-consent-sheet', (b) => b.withConsentSheet(), mdsIndex: 2),
    MdsState('state-error-retry', (b) => b.errorRetry(), mdsIndex: 3),
    MdsState('state-dark', (b) => b.errorRetry().dark(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
