// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";
// Fix #763: Portone 에러 응답에 PII 포함 가능 — JSON 문자열 내 PII 마스킹
import { maskJsonString } from "../_shared/pii_masker.ts";

const FN = "identity-verify";

const PORTONE_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;
  try {
    const { identity_verification_id } = await req.json();

    if (!identity_verification_id) {
      return errorResponse("Missing identity_verification_id", 400);
    }

    // 1. 포트원 V2 API를 통해 인증 정보 조회
    const portone = new PortoneV2Client(PORTONE_API_KEY);
    let verification: Record<string, unknown>;
    try {
      verification = await portone.getIdentityVerification(identity_verification_id);
    } catch (fetchError) {
      // Fix #763: Portone 에러에 이름/전화번호 등 PII 포함 가능.
      // JSON 파싱 시도하여 필드 단위 마스킹, 실패 시 상세 내용 로깅하지 않음.
      const rawMsg = fetchError instanceof Error ? fetchError.message : String(fetchError);
      const maskedMsg = maskJsonString(rawMsg);
      log({ function: FN, level: "error", message: "Portone V2 API Error", metadata: { detail: maskedMsg } });
      return errorResponse("Failed to fetch verification info", 502, maskedMsg);
    }

    if (verification.status !== "VERIFIED") {
      return errorResponse("Identity not verified", 400, { status: verification.status });
    }

    const customer = verification.verifiedCustomer as Record<string, unknown> | undefined;
    if (!customer) {
      return errorResponse("Verified customer data missing", 500);
    }

    // 3. Supabase DB 업데이트 — update_user_identity RPC로 암호화 저장
    // Fix #809: ci/di 평문 컬럼 제거 후 ci_encrypted/di_encrypted/di_hash로 전환
    const supabase = createServiceClient();

    const gender = typeof customer.gender === "string" ? customer.gender.toLowerCase() : undefined;

    const { error: updateError } = await supabase.rpc("update_user_identity", {
      p_user_id: userId,
      p_ci: customer.ci as string,
      p_di: customer.di as string,
      p_name: (customer.name as string) ?? null,
      p_birth_date: (customer.birthDate as string) ?? null,
      p_gender: gender ?? null,
      p_phone_number: (customer.phoneNumber as string) ?? null,
    });

    if (updateError) {
      log({ function: FN, level: "error", message: "DB Update Error", metadata: { detail: updateError } });
      return errorResponse("Failed to update user profile", 500);
    }

    return successResponse({ success: true, user: userId });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: "Error in verify-identity", metadata: { detail: message } });
    return errorResponse(message, 500);
  }
}));
