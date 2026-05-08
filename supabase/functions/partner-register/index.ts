// partner-register — Partner application (save draft, submit, update)
// Issue #311: RLS write strategy 전환

import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
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

// Fields that are nullable in partner_applications and can be explicitly cleared
// (setting to null removes a previously stored value).
const CLEARABLE_FIELDS: ReadonlySet<string> = new Set([
  "introduction",
  "tax_email",
  "profile_image_path",
]);

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  // wrapper guarantees type === "user" per auth-manifest callers: ["user"]
  const userId = (ctx.auth as { type: "user"; userId: string }).userId;

  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;

  // ─── save_draft ───
  if (action === "save_draft") {
    const applicationId = body.application_id as string | undefined;

    // Build record — only allow whitelisted fields; skip null to avoid NOT NULL violations.
    // Fix #1599: null means "not filled yet" — omit rather than insert null.
    // Exception: CLEARABLE_FIELDS are nullable in the DB and can be explicitly cleared.
    const record: Record<string, unknown> = {};
    for (const field of DRAFT_FIELDS) {
      if (body.data && typeof body.data === "object") {
        const val = (body.data as Record<string, unknown>)[field];
        if (
          val !== undefined && (val !== null || CLEARABLE_FIELDS.has(field))
        ) {
          record[field] = val;
        }
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
        return errorResponse(
          "Application cannot be updated in current status",
          400,
        );
      }

      // Fix #311: 상태 조건을 UPDATE WHERE에 포함하여 원자적 검사
      const { error: updateError } = await supabase
        .from("partner_applications")
        .update(record)
        .eq("id", applicationId)
        .eq("user_id", userId)
        .in("status", ["draft", "needs_correction"]);

      if (updateError) {
        return errorResponse(
          `Failed to update draft: ${updateError.message}`,
          500,
        );
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
        return errorResponse(
          `Failed to create draft: ${insertError.message}`,
          500,
        );
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
      return errorResponse(
        "Application cannot be submitted in current status",
        400,
      );
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
      [
        app.biz_registration_path,
        "biz_registration_path",
        "사업자등록증 파일이 업로드되지 않았습니다",
      ],
      [
        app.bankbook_path,
        "bankbook_path",
        "통장사본 파일이 업로드되지 않았습니다",
      ],
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

    // Fix #311: 상태 조건을 UPDATE WHERE에 포함하여 원자적 검사
    const { error: updateError } = await supabase
      .from("partner_applications")
      .update({ status: "pending" })
      .eq("id", applicationId)
      .eq("user_id", userId)
      .in("status", ["draft", "needs_correction"]);

    if (updateError) {
      return errorResponse(
        `Failed to submit application: ${updateError.message}`,
        500,
      );
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
      return errorResponse(
        "Application cannot be updated in current status",
        400,
      );
    }

    // Build update record — only allow whitelisted fields; skip null for non-clearable fields.
    // Fix #1599: CLEARABLE_FIELDS can be explicitly set to null to clear existing DB values.
    const updates: Record<string, unknown> = {};
    for (const field of DRAFT_FIELDS) {
      if (body.data && typeof body.data === "object") {
        const val = (body.data as Record<string, unknown>)[field];
        if (
          val !== undefined && (val !== null || CLEARABLE_FIELDS.has(field))
        ) {
          updates[field] = val;
        }
      }
    }

    if (Object.keys(updates).length === 0) {
      return errorResponse("No fields to update", 400);
    }

    // Fix #311: 상태 조건을 UPDATE WHERE에 포함하여 원자적 검사
    const { error: updateError } = await supabase
      .from("partner_applications")
      .update(updates)
      .eq("id", applicationId)
      .eq("user_id", userId)
      .in("status", ["draft", "needs_correction"]);

    if (updateError) {
      return errorResponse(
        `Failed to update application: ${updateError.message}`,
        500,
      );
    }

    return successResponse({ success: true, application_id: applicationId });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
};

minglitEdgeFunction(handler);
