import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";

const PORTONE_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

serve(async (req) => {
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
      console.error("Portone V2 API Error:", msg);
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

    const authHeader = req.headers.get("Authorization");
    const userRes = await supabase.auth.getUser(authHeader?.replace("Bearer ", ""));
    const userId = userRes.data.user?.id;

    if (!userId) {
      return errorResponse("Unauthorized", 401);
    }

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
      console.error("DB Update Error:", updateError);
      return errorResponse("Failed to update user profile", 500);
    }

    return successResponse({ success: true, user: userId });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in verify-identity:", message);
    return errorResponse(message, 500);
  }
});