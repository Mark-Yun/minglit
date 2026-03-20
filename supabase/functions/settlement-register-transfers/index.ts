import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "settlement-register-transfers";

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_V2_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

initSentry();

const CHUNK_SIZE = 500;

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: pendingItems, error: fetchError } = await supabase
      .from("settlement_items")
      .select("id, source_id, partner_id, gross_amount")
      .eq("status", "PENDING")
      .is("portone_transfer_id", null);

    if (fetchError) {
      log({ function: FN, level: "error", message: `Failed to fetch pending settlement items: ${fetchError.message}` });
      return errorResponse("Failed to fetch pending items", 500);
    }

    if (!pendingItems || pendingItems.length === 0) {
      return successResponse({ processed: 0, succeeded: 0, failed: 0 });
    }

    const portone = new PortoneV2Client(PORTONE_V2_API_KEY);
    let succeeded = 0;
    let failed = 0;

    for (let i = 0; i < pendingItems.length; i += CHUNK_SIZE) {
      const chunk = pendingItems.slice(i, i + CHUNK_SIZE);

      for (const item of chunk) {
        try {
          const { data: partner, error: partnerError } = await supabase
            .from("partners")
            .select("portone_partner_id")
            .eq("id", item.partner_id)
            .single();

          if (partnerError || !partner?.portone_partner_id) {
            log({ function: FN, level: "error", message: `Partner not found or not synced for item ${item.id}` });
            failed++;
            continue;
          }

          const { data: applications, error: appError } = await supabase
            .from("event_applications")
            .select("id, payment_id, total_amount")
            .eq("event_id", item.source_id)
            .not("payment_id", "is", null)
            .in("payment_status", ["paid", "approved"]);

          if (appError || !applications || applications.length === 0) {
            log({ function: FN, level: "error", message: `No paid applications found for item ${item.id}` });
            failed++;
            continue;
          }

          let itemSucceeded = false;
          for (const app of applications) {
            if (!app.payment_id) continue;

            try {
              const transfer = await portone.createOrderTransfer({
                partnerId: partner.portone_partner_id,
                paymentId: app.payment_id,
                orderDetail: { orderAmount: app.total_amount ?? item.gross_amount },
              });

              if (transfer.transfer?.id) {
                await supabase
                  .from("settlement_items")
                  .update({ portone_transfer_id: transfer.transfer.id })
                  .eq("id", item.id);
                itemSucceeded = true;
              }
            } catch (e) {
              const message = e instanceof Error ? e.message : String(e);
              log({ function: FN, level: "error", message: `createOrderTransfer failed for item ${item.id}, app ${app.id}: ${message}` });
            }
          }

          if (itemSucceeded) {
            succeeded++;
          } else {
            failed++;
          }
        } catch (e) {
          const message = e instanceof Error ? e.message : String(e);
          log({ function: FN, level: "error", message: `Error processing item ${item.id}: ${message}` });
          failed++;
        }
      }
    }

    return successResponse({
      processed: pendingItems.length,
      succeeded,
      failed,
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Error in settlement-register-transfers: ${message}` });
    return errorResponse(message, 500);
  }
}));
