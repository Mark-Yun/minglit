// partner-review-submission — Review verification submissions (approve/reject + comment)
// Issue #309: RLS write strategy 전환

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";

initSentry();

const VALID_RESULTS = ["approved", "rejected"];

Deno.serve(withHandler(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    return await handleRequest(req);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
}));

async function handleRequest(req: Request): Promise<Response> {
  // 1. Environment check (handled by createServiceClient)

  // 2. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 3. Parse body
  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  if (!action) return errorResponse("Missing action", 400);

  // 4. Supabase client (service role)
  const supabase = createServiceClient();

  // ─── review ───
  if (action === "review") {
    const submissionId = body.submission_id;
    if (typeof submissionId !== "string" || !submissionId) {
      return errorResponse("Missing submission_id", 400);
    }

    const result = body.result;
    if (typeof result !== "string" || !VALID_RESULTS.includes(result)) {
      return errorResponse(
        "Invalid result. Must be 'approved' or 'rejected'",
        400,
      );
    }

    // Fetch submission
    const { data: submission, error: fetchError } = await supabase
      .from("verification_submissions")
      .select("id, partner_id, status, snapshot_data")
      .eq("id", submissionId)
      .maybeSingle();

    if (fetchError) {
      return errorResponse("Failed to load submission", 500);
    }
    if (!submission) {
      return errorResponse("Submission not found", 404);
    }

    // Fix #309: 이미 심사 완료된 submission은 재심사 불가
    if (submission.status !== "pending") {
      return errorResponse("Submission is already reviewed", 409);
    }

    // Check partner permission
    const permCheck = await requirePartnerPermission(supabase, submission.partner_id, userId, ["VERIFY_REVIEW"]);
    if (permCheck) return permCheck;

    // Update snapshot_data last entry with review result
    const snapshotArray = Array.isArray(submission.snapshot_data)
      ? [...submission.snapshot_data]
      : [];

    if (snapshotArray.length === 0) {
      return errorResponse("No submission history found", 400);
    }

    const now = new Date().toISOString();
    const lastEntry = { ...snapshotArray[snapshotArray.length - 1] };
    lastEntry.result = result;
    lastEntry.reviewed_by = userId;
    lastEntry.reviewed_at = now;

    // Fix #309: review action에 comment가 있으면 함께 기록
    const comment = body.comment;
    if (typeof comment === "string" && comment.trim().length > 0) {
      const comments = Array.isArray(lastEntry.comments)
        ? [...lastEntry.comments]
        : [];
      comments.push({
        author: userId,
        at: now,
        text: comment.trim(),
      });
      lastEntry.comments = comments;
    }

    snapshotArray[snapshotArray.length - 1] = lastEntry;

    const { error: updateError } = await supabase
      .from("verification_submissions")
      .update({
        status: result,
        reviewed_at: now,
        reviewed_by: userId,
        // Fix #2099: 심사 시작 시점 기록 — 단일 submit flow에서 시작=종료 시각 동일
        review_started_at: now,
        snapshot_data: snapshotArray,
      })
      .eq("id", submissionId);

    if (updateError) {
      return errorResponse(
        `Failed to update submission: ${updateError.message}`,
        500,
      );
    }

    return successResponse({ success: true });
  }

  // ─── comment ───
  if (action === "comment") {
    const submissionId = body.submission_id;
    if (typeof submissionId !== "string" || !submissionId) {
      return errorResponse("Missing submission_id", 400);
    }

    const text = body.text;
    if (typeof text !== "string" || text.trim().length === 0) {
      return errorResponse("Missing text", 400);
    }

    // Fetch submission
    const { data: submission, error: fetchError } = await supabase
      .from("verification_submissions")
      .select("id, partner_id, snapshot_data")
      .eq("id", submissionId)
      .maybeSingle();

    if (fetchError) {
      return errorResponse("Failed to load submission", 500);
    }
    if (!submission) {
      return errorResponse("Submission not found", 404);
    }

    // Check partner permission
    const permCheck = await requirePartnerPermission(supabase, submission.partner_id, userId, ["VERIFY_REVIEW"]);
    if (permCheck) return permCheck;

    // Append comment to last snapshot entry
    const snapshotArray = Array.isArray(submission.snapshot_data)
      ? [...submission.snapshot_data]
      : [];

    if (snapshotArray.length === 0) {
      return errorResponse("No submission history found", 400);
    }

    const lastEntry = { ...snapshotArray[snapshotArray.length - 1] };
    const comments = Array.isArray(lastEntry.comments)
      ? [...lastEntry.comments]
      : [];
    comments.push({
      author: userId,
      at: new Date().toISOString(),
      text: text.trim(),
    });
    lastEntry.comments = comments;
    snapshotArray[snapshotArray.length - 1] = lastEntry;

    const { error: updateError } = await supabase
      .from("verification_submissions")
      .update({ snapshot_data: snapshotArray })
      .eq("id", submissionId);

    if (updateError) {
      return errorResponse(
        `Failed to add comment: ${updateError.message}`,
        500,
      );
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
}
