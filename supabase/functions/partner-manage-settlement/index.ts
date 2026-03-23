// partner-manage-settlement — Manage partner settlement bank account
// Issue #312: RLS write strategy 전환

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

// Fields allowed in upsert_bank_account action
const UPSERT_FIELDS = [
  "bank_name",
  "account_holder",
  "account_number",
] as const;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  // 1. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 2. Parse body
  let body: Record<string, unknown>;
  try {
    const parsed = await req.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return errorResponse("Request body must be a JSON object", 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const action = body.action as string | undefined;
  if (typeof action !== "string" || !action) return errorResponse("Missing action", 400);

  // 3. Supabase client (service role)
  const supabase = createServiceClient();

  // ─── upsert_bank_account ───
  if (action === "upsert_bank_account") {
    const partnerId = body.partner_id;
    if (typeof partnerId !== "string" || !partnerId) {
      return errorResponse("Missing partner_id", 400);
    }

    // Validate required fields
    const bankName = body.bank_name;
    if (typeof bankName !== "string" || !bankName) {
      return errorResponse("Missing bank_name", 400);
    }

    const accountHolder = body.account_holder;
    if (typeof accountHolder !== "string" || !accountHolder) {
      return errorResponse("Missing account_holder", 400);
    }

    const accountNumber = body.account_number;
    if (typeof accountNumber !== "string" || !accountNumber) {
      return errorResponse("Missing account_number", 400);
    }

    // Check partner permission
    const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
    if (permCheck instanceof Response) return permCheck;

    // Build upsert record — only allow whitelisted fields
    const record: Record<string, unknown> = { partner_id: partnerId };
    for (const field of UPSERT_FIELDS) {
      if (body[field] !== undefined) {
        record[field] = body[field];
      }
    }

    const { error: upsertError } = await supabase
      .from("partner_settlements")
      .upsert(record, { onConflict: "partner_id" });

    if (upsertError) {
      return errorResponse(`Failed to upsert bank account: ${upsertError.message}`, 500);
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
});

// ─── Helper: check partner permission ───
async function checkPartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
): Promise<void | Response> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("permissions")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  // Fix #312: SETTLEMENT_EDIT 권한 또는 owner 권한 확인
  const hasPermission = (perm?.permissions as string[] | null)?.includes("SETTLEMENT_EDIT") ?? false;
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
