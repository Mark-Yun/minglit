import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// TODO: 실제 운영 환경에서는 아래 값들을 Supabase Vault 또는 환경 변수로 관리해야 합니다.
// 현재는 테스트를 위해 하드코딩하며, 추후 GitHub Secrets를 통해 주입하도록 설정할 예정입니다.
const PORTONE_API_KEY = "ZUhPSzQzQUpCN1dLa1I0RFd3Y1VuQT09";
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

    // --- MOCK FOR TESTING ---
    if (identity_verification_id === 'TEST_VERIFICATION_ID') {
      console.log("Mock verification triggered.");
      return new Response(JSON.stringify({
        success: true,
        user: "mock_user_id",
        mocked: true 
      }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    // ------------------------

    // 1. 포트원 V2 API를 통해 인증 정보 조회
    // V2 인증 방식: Authorization: PortOne <API_SECRET>
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
      return new Response(JSON.stringify({ error: "Failed to fetch verification info" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const verification = await response.json();

    // 2. 인증 데이터 추출
    // V2 응답 구조 예시: { id, status, verifiedCustomer: { name, birthDate, gender, phoneNumber, ci, di } }
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

    // TODO: 현재 유저 ID를 JWT 또는 파라미터로 받아야 함. 
    // 여기서는 단순 예시로 처리하거나 Auth Header에서 유저 정보를 추출하는 로직이 필요합니다.
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
