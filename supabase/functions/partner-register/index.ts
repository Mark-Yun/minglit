// partner-register — Partner application (save draft, submit, update)
// Issue #311: RLS write strategy 전환

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import {
  requireNonEmpty,
  validateBizNumber,
  validateBizType,
  validateEmail,
  validatePhone,
  type ValidationError,
} from "../_shared/validation_utils.ts";

// Fields allowed in save_draft / update actions
const DRAFT_FIELDS = [
  "brand_name",
  "introduction",
  "address",
  "contact_phone",
  "contact_email",
  "biz_type",
  "biz_name",
  "biz_number",
  "representative_name",
  "bank_name",
  "account_number",
  "account_holder",
  "tax_email",
  "biz_registration_path",
  "bankbook_path",
  "profile_image_path",
  "current_step",
] as const;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    return await handleRequest(req);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
});

async function handleRequest(req: Request): Promise<Response> {
  // 1. Environment check
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing server configuration", 500);
  }

  // 2. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 3. Parse body
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

  // 4. Supabase client (service role)
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // ─── save_draft ───
  if (action === "save_draft") {
    const applicationId = body.application_id as string | undefined;

    // Build record — only allow whitelisted fields
    const record: Record<string, unknown> = {};
    for (const field of DRAFT_FIELDS) {
      if (body.data && typeof body.data === "object" && (body.data as Record<string, unknown>)[field] !== undefined) {
        record[field] = (body.data as Record<string, unknown>)[field];
      }
    }
    record.status = "draft";

    if (applicationId) {
      // UPDATE existing draft — verify ownership + status guard
      const { data: app, error: fetchError } = await supabase
        .from("partner_applications")
        .select("id, user_id, status")
        .eq("id", applicationId)
        .maybeSingle();
      if (fetchError) return errorResponse("Failed to load application", 500);
      if (!app) return errorResponse("Application not found", 404);
      if (app.user_id !== userId) {
        return errorResponse("Forbidden: not your application", 403);
      }
      // Fix #311: pending/approved 신청서는 save_draft로 되돌릴 수 없음
      if (app.status !== "draft" && app.status !== "needs_correction") {
        return errorResponse("Application cannot be updated in current status", 400);
      }

      const { error: updateError } = await supabase
        .from("partner_applications")
        .update(record)
        .eq("id", applicationId);

      if (updateError) {
        return errorResponse(`Failed to update draft: ${updateError.message}`, 500);
      }

      return successResponse({ success: true, application_id: applicationId });
    } else {
      // INSERT new draft
      record.user_id = userId;

      const { data, error: insertError } = await supabase
        .from("partner_applications")
        .insert(record)
        .select("id")
        .single();

      if (insertError) {
        return errorResponse(`Failed to create draft: ${insertError.message}`, 500);
      }

      return successResponse({ success: true, application_id: data.id });
    }
  }

  // ─── submit ───
  if (action === "submit") {
    const applicationId = body.application_id;
    if (typeof applicationId !== "string" || !applicationId) {
      return errorResponse("Missing application_id", 400);
    }

    // Fetch application
    const { data: app, error: fetchError } = await supabase
      .from("partner_applications")
      .select("*")
      .eq("id", applicationId)
      .maybeSingle();

    if (fetchError) {
      return errorResponse("Failed to load application", 500);
    }
    if (!app) {
      return errorResponse("Application not found", 404);
    }

    // Fix #311: 본인 신청서만 제출 가능
    if (app.user_id !== userId) {
      return errorResponse("Forbidden: not your application", 403);
    }

    // Fix #311: draft/needs_correction 상태만 제출 가능
    if (app.status !== "draft" && app.status !== "needs_correction") {
      return errorResponse("Application cannot be submitted in current status", 400);
    }

    // Server-side validation
    const errors: ValidationError[] = [];

    const nonEmptyChecks: Array<[unknown, string, string]> = [
      [app.brand_name, "brand_name", "브랜드명"],
      [app.biz_name, "biz_name", "사업자명"],
      [app.representative_name, "representative_name", "대표자명"],
      [app.bank_name, "bank_name", "은행명"],
      [app.account_number, "account_number", "계좌번호"],
      [app.account_holder, "account_holder", "예금주"],
    ];

    for (const [value, field, label] of nonEmptyChecks) {
      const err = requireNonEmpty(value, field, label);
      if (err) errors.push(err);
    }

    const bizTypeErr = validateBizType(app.biz_type);
    if (bizTypeErr) errors.push(bizTypeErr);

    const bizNumErr = validateBizNumber(app.biz_number);
    if (bizNumErr) errors.push(bizNumErr);

    const phoneErr = validatePhone(app.contact_phone);
    if (phoneErr) errors.push(phoneErr);

    const emailErr = validateEmail(app.contact_email);
    if (emailErr) errors.push(emailErr);

    // Storage file existence checks
    const fileChecks: Array<[unknown, string, string]> = [
      [app.biz_registration_path, "biz_registration_path", "사업자등록증 파일이 업로드되지 않았습니다"],
      [app.bankbook_path, "bankbook_path", "통장사본 파일이 업로드되지 않았습니다"],
    ];

    for (const [path, field, message] of fileChecks) {
      if (typeof path !== "string" || path.trim().length === 0) {
        errors.push({ field, message });
        continue;
      }
      // Fix #311: 파일 경로가 본인 디렉토리인지 검증
      if (!path.startsWith(`${userId}/`)) {
        return errorResponse("Forbidden file path", 403);
      }

      const folder = path.substring(0, path.lastIndexOf("/"));
      const filename = path.substring(path.lastIndexOf("/") + 1);

      // Verify file exists in storage
      const { data: fileData, error: fileError } = await supabase.storage
        .from("partner-proofs")
        .list(folder, { search: filename });

      if (fileError) {
        return errorResponse("Failed to verify uploaded files", 500);
      }

      if (!fileData.some((file) => file.name === filename)) {
        errors.push({ field, message });
      }
    }

    if (errors.length > 0) {
      return errorResponse("validation_failed", 400, errors);
    }

    // Transition to pending
    const { error: updateError } = await supabase
      .from("partner_applications")
      .update({ status: "pending" })
      .eq("id", applicationId);

    if (updateError) {
      return errorResponse(`Failed to submit application: ${updateError.message}`, 500);
    }

    return successResponse({ success: true });
  }

  // ─── update ───
  if (action === "update") {
    const applicationId = body.application_id;
    if (typeof applicationId !== "string" || !applicationId) {
      return errorResponse("Missing application_id", 400);
    }

    // Fetch to check ownership and status
    const { data: app, error: fetchError } = await supabase
      .from("partner_applications")
      .select("id, user_id, status")
      .eq("id", applicationId)
      .maybeSingle();

    if (fetchError) {
      return errorResponse("Failed to load application", 500);
    }
    if (!app) {
      return errorResponse("Application not found", 404);
    }

    // Fix #311: 본인 신청서만 수정 가능
    if (app.user_id !== userId) {
      return errorResponse("Forbidden: not your application", 403);
    }

    // Fix #311: draft/needs_correction 상태만 수정 가능
    if (app.status !== "draft" && app.status !== "needs_correction") {
      return errorResponse("Application cannot be updated in current status", 400);
    }

    // Build update record — only allow whitelisted fields
    const updates: Record<string, unknown> = {};
    for (const field of DRAFT_FIELDS) {
      if (body.data && typeof body.data === "object" && (body.data as Record<string, unknown>)[field] !== undefined) {
        updates[field] = (body.data as Record<string, unknown>)[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return errorResponse("No fields to update", 400);
    }

    const { error: updateError } = await supabase
      .from("partner_applications")
      .update(updates)
      .eq("id", applicationId);

    if (updateError) {
      return errorResponse(`Failed to update application: ${updateError.message}`, 500);
    }

    return successResponse({ success: true, application_id: applicationId });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
}

