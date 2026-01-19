import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// TODO: 실제 운영 환경에서는 아래 값들을 Supabase Vault 또는 환경 변수로 관리해야 합니다.
// 현재는 테스트를 위해 하드코딩하며, 추후 GitHub Secrets를 통해 주입하도록 설정할 예정입니다.
const PORTONE_API_KEY = "e94DAc1YxTkGSPuznRBcLwyQlYHmK59gu7mJaFQrUnnxbkWfsmtqW469rSKYBScQWDYT1NNZeweMzsmX";
const PORTONE_API_URL = "https://api.portone.io";

serve(async (req) => {
  try {
    const { identity_verification_id } = await req.json();

    if (!identity_verification_id) {
      return new Response(JSON.stringify({ error: "Missing identity_verification_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1. 포트원 V2 API를 통해 인증 정보 조회
    const response = await fetch(`${PORTONE_API_URL}/identity-verifications/${identity_verification_id}`, {
      method: "GET",
      headers: {
        "Authorization": `PortOne ${PORTONE_API_KEY}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error("Portone V2 API Error:", errorData);
      return new Response(JSON.stringify({ error: "Failed to fetch verification info", details: errorData }), {
        status: response.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    const verification = await response.json();

    if (verification.status !== "VERIFIED") {
      return new Response(JSON.stringify({ error: "Identity not verified", status: verification.status }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const customer = verification.verifiedCustomer;
    if (!customer) {
      return new Response(JSON.stringify({ error: "Verified customer data missing" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
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
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { error: updateError } = await supabase
      .from("user_profiles")
      .update({
        name: customer.name,
        birth_date: customer.birthDate,
        gender: customer.gender.toLowerCase(),
        phone_number: customer.phoneNumber,
        ci: customer.ci,
        di: customer.di,
        is_verified: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId);

    if (updateError) {
      console.error("DB Update Error:", updateError);
      return new Response(JSON.stringify({ error: "Failed to update user profile" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, user: userId }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (e) {
    console.error("Error in verify-identity:", e);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});