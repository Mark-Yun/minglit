// MDS screen: deletion_verify_page
// 대응 MDS: apps/mds/docs/public/specs/deletion_verify_page/
//
// 출력: docs/infra/mds-emulator-render/deletion_verify_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<DeletionVerifyPageBuilder>(
  screen: 'deletion_verify_page',
  mdsSpec: 'apps/mds/docs/public/specs/deletion_verify_page/',
  builder: DeletionVerifyPageBuilder.new,
  states: [
    // 이메일 유저: 비밀번호 입력 필드 노출
    MdsState('state-email-user', (b) => b.asEmailUser(), mdsIndex: 1),
    // 소셜 유저: 재인증 안내 카드 노출
    MdsState('state-social-user', (b) => b.asSocialUser(), mdsIndex: 2),
    MdsState('state-email-user-dark', (b) => b.asEmailUser().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
