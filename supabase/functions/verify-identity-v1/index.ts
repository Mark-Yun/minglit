import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";

const IMP_KEY = Deno.env.get("PORTONE_IMP_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_IMP_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_IMP_KEY, PORTONE_IMP_SECRET");
}

serve(async (req) => {
  try {
    const { identity_verification_id } = await req.json();

    if (!identity_verification_id) {
      return new Response(JSON.stringify({ error: "Missing identity_verification_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1. Iamport V1 API 조회
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const certification = await client.getCertification(identity_verification_id);

    // 2. 인증 상태 확인
    // Iamport V1 doesn't have a status field in response? Usually "certified" is implied if retrieval succeeds.
    // But we check `certified` boolean if available. Docs say response has `certified`.
    if (certification.certified !== true) {
       return new Response(JSON.stringify({ error: "Identity not certified", details: certification }), {
        status: 400,
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

    // Convert Unix timestamp (seconds) to Date
    // Iamport birth is usually integer (e.g. 19990101)? No, response has `birth` (int/string) or `birthday`.
    // Standard response: `birthday` ("1990-01-01")
    
    const { error: updateError } = await supabase
      .from("user_profiles")
      .update({
        name: certification.name,
        birth_date: certification.birthday, // "YYYY-MM-DD" format expected
        gender: certification.gender, // "male" / "female"
        phone_number: certification.phone,
        ci: certification.unique_key, // CI
        di: certification.unique_in_site, // DI
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
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in verify-identity-v1:", message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
