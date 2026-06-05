// MDS screen: signup_consent_page
// 대응 MDS: apps/mds/docs/public/specs/signup_consent_page/
//
// 출력: docs/infra/mds-emulator-render/signup_consent_page/state-*.png
//
// State 4 (Submitting) — _isSubmitting 은 로컬 state, 버튼 tap 필요 → 제외.
// State 5 (Error) — showMinglitError snackbar 의존 → 제외.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<SignupConsentPageBuilder>(
  screen: 'signup_consent_page',
  mdsSpec: 'apps/mds/docs/public/specs/signup_consent_page/',
  builder: SignupConsentPageBuilder.new,
  states: [
    // Loading on entry — 동의 정보 로딩 중 스피너
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 6,
      infiniteAnimation: true,
    ),
    // State 1 — Default: 체크박스 없음, CTA 비활성
    MdsState('state-default', (b) => b.noneSelected(), mdsIndex: 1),
    // State 2 — 필수만 토글: CTA 활성
    MdsState('state-required-only', (b) => b.requiredOnly(), mdsIndex: 2),
    // State 3 — 전체 토글: 모든 체크박스 checked
    MdsState('state-all', (b) => b.allSelected(), mdsIndex: 3),
    // Dark variant
    MdsState('state-dark', (b) => b.noneSelected().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
