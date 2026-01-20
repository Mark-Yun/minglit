import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";

const IMP_KEY = "3353907223007704";
const IMP_SECRET = "Qs5lIRl4bQs6Waiavkcc6hBVhj4V2LSTdYeWPz01qs7mDqx8LJlS0XOigSdjE6cR4qNU0OWrh4NUuk3f";

serve(async (req) => {
  try {
    const { imp_uid, merchant_uid } = await req.json();

    if (!imp_uid || !merchant_uid) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 0. Supabase Client 초기화
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. DB에서 주문 정보 조회 (금액 확인)
    const { data: order, error: orderError } = await supabase
      .from("event_applications")
      .select("payment_amount, status")
      .eq("id", merchant_uid)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 이미 처리된 주문인지 확인
    if (order.status === 'approved' || order.status === 'paid') {
       return new Response(JSON.stringify({ success: true, message: "Already processed" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Iamport V1 API 조회
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const payment = await client.getPayment(imp_uid);

    // 3. 결제 상태 및 금액 검증
    if (payment.status !== "paid") {
      return new Response(JSON.stringify({ error: "Payment not completed", status: payment.status }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (payment.amount !== order.payment_amount) {
      // TODO: 금액 위변조 시 결제 취소 API 자동 호출 로직 추가 가능
      return new Response(JSON.stringify({ 
        error: "Amount mismatch", 
        expected: order.payment_amount, 
        actual: payment.amount 
      }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Supabase DB 업데이트 (티켓 발권 및 신청 상태 변경)
    // ... rest of the logic ...
    
    // Note: We used service role key so auth check via header is optional but good practice if we want to link user.
    // But since we have merchant_uid which is unique, we can just update.
    
    const { error: updateError } = await supabase
      .from("event_applications")
      .update({
        status: "approved",
        payment_id: imp_uid,
        updated_at: new Date().toISOString(),
      })
      .eq("id", merchant_uid);

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
