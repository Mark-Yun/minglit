import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";

const IMP_KEY = "3353907223007704";
const IMP_SECRET = "Qs5lIRl4bQs6Waiavkcc6hBVhj4V2LSTdYeWPz01qs7mDqx8LJlS0XOigSdjE6cR4qNU0OWrh4NUuk3f";

serve(async (req) => {
  try {
    const { imp_uid, merchant_uid, amount } = await req.json();

    if (!imp_uid || !merchant_uid) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1. Iamport V1 API 조회
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const payment = await client.getPayment(imp_uid);

    // 2. 결제 상태 및 금액 검증
    if (payment.status !== "paid") {
      return new Response(JSON.stringify({ error: "Payment not completed", status: payment.status }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (payment.amount !== amount) {
      // TODO: 금액 위변조 시 결제 취소 API 자동 호출 로직 추가 가능
      return new Response(JSON.stringify({ error: "Amount mismatch", expected: amount, actual: payment.amount }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Supabase DB 업데이트 (티켓 발권 및 신청 상태 변경)
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

    // merchant_uid (주문 ID)를 사용하여 DB 상태 업데이트
    // TODO: 결제 완료 처리 로직 (Atomic Transaction)
    // 예: event_applications 테이블의 status를 'approved'로 변경하고 payment_id 저장
    const { error: updateError } = await supabase
      .from("event_applications")
      .update({
        status: "approved",
        payment_id: imp_uid,
        updated_at: new Date().toISOString(),
      })
      .eq("id", merchant_uid)
      .eq("user_id", userId);

    if (updateError) {
      console.error("DB Update Error:", updateError);
      return new Response(JSON.stringify({ error: "Failed to update order status" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, imp_uid }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (e) {
    console.error("Error in verify-payment-v1:", e);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
