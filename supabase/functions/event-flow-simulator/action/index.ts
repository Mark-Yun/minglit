// action/index.ts — 모든 액션 일괄 등록 (single import 로 registry 채움)
//
// side-effect import — 각 파일이 module load 시 registerAction() 호출
import "./apply.ts";
import "./refund.ts";
import "./checkin.ts";
import "./discover.ts";
import "./vote.ts";
import "./block.ts";
import "./partner_approve.ts";
import "./partner_reject.ts";
import "./partner_create_event.ts";
