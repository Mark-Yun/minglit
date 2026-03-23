// partner-review-submission — Review verification submissions (approve/reject + comment)
// Issue #309: RLS write strategy 전환

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

const VALID_RESULTS = ["approved", "rejected"];

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

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

  // ─── review ───
  if (action === "review") {
    const submissionId = body.submission_id;
    if (typeof submissionId !== "string" || !submissionId) {
      return errorResponse("Missing submission_id", 400);
    }

    const result = body.result;
    if (typeof result !== "string" || !VALID_RESULTS.includes(result)) {
      return errorResponse("Invalid result. Must be 'approved' or 'rejected'", 400);
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
    const permCheck = await checkPartnerPermission(supabase, submission.partner_id, userId);
    if (permCheck instanceof Response) return permCheck;

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
      const comments = Array.isArray(lastEntry.comments) ? [...lastEntry.comments] : [];
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
        snapshot_data: snapshotArray,
      })
      .eq("id", submissionId);

    if (updateError) {
      return errorResponse(`Failed to update submission: ${updateError.message}`, 500);
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
    const permCheck = await checkPartnerPermission(supabase, submission.partner_id, userId);
    if (permCheck instanceof Response) return permCheck;

    // Append comment to last snapshot entry
    const snapshotArray = Array.isArray(submission.snapshot_data)
      ? [...submission.snapshot_data]
      : [];

    if (snapshotArray.length === 0) {
      return errorResponse("No submission history found", 400);
    }

    const lastEntry = { ...snapshotArray[snapshotArray.length - 1] };
    const comments = Array.isArray(lastEntry.comments) ? [...lastEntry.comments] : [];
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
      return errorResponse(`Failed to add comment: ${updateError.message}`, 500);
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
});

// ─── Helper: check partner permission ───
async function checkPartnerPermission(
  supabase: ReturnType<typeof createClient>,
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

  const hasPermission = (perm?.permissions as string[] | null)?.includes("VERIFY_REVIEW") ?? false;
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
