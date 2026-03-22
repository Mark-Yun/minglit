import { createClient } from "@supabase/supabase-js";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-submit-verification";

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { action } = reqBody as { action?: string };
    if (!action) {
      return errorResponse("Missing required field: action", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    switch (action) {
      case "submit": {
        const { partner_id, verification_id, application_id } = reqBody as {
          partner_id?: string;
          verification_id?: string;
          application_id?: string;
        };

        if (!partner_id) {
          return errorResponse("Missing required field: partner_id", 400);
        }
        if (!verification_id) {
          return errorResponse("Missing required field: verification_id", 400);
        }

        // 1. Fetch user's verification data (snapshot source)
        const { data: userVerification, error: uvError } = await withSpan(
          "db.select.user_verifications", "db.select",
          () => supabase
            .from("user_verifications")
            .select("data")
            .eq("user_id", userId)
            .eq("verification_id", verification_id)
            .maybeSingle(),
        );

        if (uvError) {
          log({ function: FN, level: "error", message: "Failed to fetch user verification", metadata: { detail: uvError } });
          return errorResponse("Failed to fetch user verification data", 500);
        }
        if (!userVerification) {
          return errorResponse("No verification data found. Save your data first.", 400);
        }

        const now = new Date().toISOString();
        const snapshotEntry = {
          submitted_at: now,
          data: userVerification.data,
          result: null,
          reviewed_by: null,
          reviewed_at: null,
          comments: [],
        };

        // 2. Check for existing submission
        const { data: existing, error: existError } = await withSpan(
          "db.select.verification_submissions", "db.select",
          () => supabase
            .from("verification_submissions")
            .select("id, snapshot_data")
            .eq("user_id", userId)
            .eq("partner_id", partner_id)
            .eq("verification_id", verification_id)
            .maybeSingle(),
        );

        if (existError) {
          log({ function: FN, level: "error", message: "Failed to check existing submission", metadata: { detail: existError } });
          return errorResponse("Failed to check existing submission", 500);
        }

        let submissionId: string;

        if (existing) {
          // Append to existing snapshot_data array, reset status to pending
          const snapshotArray = Array.isArray(existing.snapshot_data)
            ? [...existing.snapshot_data, snapshotEntry]
            : [snapshotEntry];

          const { error: updateError } = await withSpan(
            "db.update.verification_submissions", "db.update",
            () => supabase
              .from("verification_submissions")
              .update({
                snapshot_data: snapshotArray,
                status: "pending",
                reviewed_at: null,
                reviewed_by: null,
              })
              .eq("id", existing.id),
          );

          if (updateError) {
            log({ function: FN, level: "error", message: "Failed to update submission", metadata: { detail: updateError } });
            return errorResponse("Failed to update submission", 500);
          }
          submissionId = existing.id;
        } else {
          // Create new submission
          const insertData: Record<string, unknown> = {
            partner_id,
            user_id: userId,
            verification_id,
            status: "pending",
            snapshot_data: [snapshotEntry],
          };
          if (application_id) {
            insertData.application_id = application_id;
          }

          const { data: inserted, error: insertError } = await withSpan(
            "db.insert.verification_submissions", "db.insert",
            () => supabase
              .from("verification_submissions")
              .insert(insertData)
              .select("id")
              .single(),
          );

          if (insertError) {
            log({ function: FN, level: "error", message: "Failed to create submission", metadata: { detail: insertError } });
            return errorResponse("Failed to create submission", 500);
          }
          submissionId = inserted.id;
        }

        logStatsigEvent(userId, "verification_submitted", undefined, {
          partner_id,
          verification_id,
          is_resubmit: String(!!existing),
        }).catch(() => {});

        return successResponse({ success: true, submission_id: submissionId });
      }

      case "comment": {
        const { submission_id, text } = reqBody as {
          submission_id?: string;
          text?: string;
        };

        if (!submission_id) {
          return errorResponse("Missing required field: submission_id", 400);
        }
        if (!text || typeof text !== "string" || text.trim().length === 0) {
          return errorResponse("Missing required field: text", 400);
        }

        // Fetch submission and verify ownership
        const { data: submission, error: fetchError } = await withSpan(
          "db.select.verification_submissions", "db.select",
          () => supabase
            .from("verification_submissions")
            .select("id, user_id, snapshot_data")
            .eq("id", submission_id)
            .maybeSingle(),
        );

        if (fetchError) {
          log({ function: FN, level: "error", message: "Failed to fetch submission", metadata: { detail: fetchError } });
          return errorResponse("Failed to fetch submission", 500);
        }
        if (!submission) {
          return errorResponse("Submission not found", 404);
        }
        if (submission.user_id !== userId) {
          return errorResponse("Forbidden: not your submission", 403);
        }

        // Append comment to the last snapshot entry
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

        const { error: updateError } = await withSpan(
          "db.update.verification_submissions", "db.update",
          () => supabase
            .from("verification_submissions")
            .update({ snapshot_data: snapshotArray })
            .eq("id", submission_id),
        );

        if (updateError) {
          log({ function: FN, level: "error", message: "Failed to add comment", metadata: { detail: updateError } });
          return errorResponse("Failed to add comment", 500);
        }

        logStatsigEvent(userId, "verification_comment_added", undefined, {
          submission_id,
        }).catch(() => {});

        return successResponse({ success: true });
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400);
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Error in ${FN}: ${message}` });
    return errorResponse(message, 500);
  }
}));
