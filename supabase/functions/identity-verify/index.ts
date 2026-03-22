// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createClient } from "@supabase/supabase-js";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

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
      const msg = fetchError instanceof Error ? fetchError.message : String(fetchError);
      log({ function: FN, level: "error", message: "Portone V2 API Error", metadata: { detail: msg } });
      return errorResponse("Failed to fetch verification info", 502, msg);
    }

    if (verification.status !== "VERIFIED") {
      return errorResponse("Identity not verified", 400, { status: verification.status });
    }

    const customer = verification.verifiedCustomer as Record<string, unknown> | undefined;
    if (!customer) {
      return errorResponse("Verified customer data missing", 500);
    }

    // 3. Supabase DB 업데이트
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const gender = typeof customer.gender === "string" ? customer.gender.toLowerCase() : undefined;

    const { error: updateError } = await supabase
      .from("user_profiles")
      .update({
        name: customer.name,
        birth_date: customer.birthDate,
        gender,
        phone_number: customer.phoneNumber,
        ci: customer.ci,
        di: customer.di,
        is_verified: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

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