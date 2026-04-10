import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { initSentry, log, withHandler, withSpan } from "../_shared/logger.ts";

const FN = "process-pending-deletions";
const DELETION_GRACE_DAYS = 7;
const BLOCKED_DI_DAYS = 30;
const CONTRACT_RETENTION_YEARS = 5;
const PAYMENT_RETENTION_YEARS = 5;
const DISPUTE_RETENTION_YEARS = 3;
const LOGIN_RETENTION_MONTHS = 3;
const CONSENT_RETENTION_YEARS = 2;

type PendingDeletionUser = {
  id: string;
  deleted_at: string;
  di_hash: string | null;
};

type EventApplicationArchive = {
  id: string;
  event_id: string;
  ticket_id: string;
  status: string;
  payment_id: string | null;
  payment_amount: number | null;
  refund_amount: number | null;
  refund_status: string | null;
  created_at: string;
  updated_at: string;
};

type ReportDetailArchive = {
  id: string;
  target_id: string;
  target_type: string;
  reason: string;
  description: string | null;
  created_at: string;
};

type ArchivedRecordInsert = {
  user_id_hash: string;
  record_type: "contract" | "payment" | "dispute" | "login" | "consent";
  record_data: Record<string, unknown>;
  retention_until: string;
};

type UserResult = {
  user_id: string;
  success: boolean;
  archived_records: number;
  blocked_di: boolean;
  error?: string;
};

await initSentry();

function requireServiceRole(req: Request): Response | null {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!serviceRoleKey) {
    return errorResponse("SUPABASE_SERVICE_ROLE_KEY not configured", 500);
  }
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return errorResponse("Unauthorized", 401);
  }

  return null;
}

function addDays(date: Date, days: number): string {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000).toISOString();
}

function addYears(date: Date, years: number): string {
  return new Date(
    Date.UTC(
      date.getUTCFullYear() + years,
      date.getUTCMonth(),
      date.getUTCDate(),
      date.getUTCHours(),
      date.getUTCMinutes(),
      date.getUTCSeconds(),
      date.getUTCMilliseconds(),
    ),
  ).toISOString();
}

function addMonths(date: Date, months: number): string {
  return new Date(
    Date.UTC(
      date.getUTCFullYear(),
      date.getUTCMonth() + months,
      date.getUTCDate(),
      date.getUTCHours(),
      date.getUTCMinutes(),
      date.getUTCSeconds(),
      date.getUTCMilliseconds(),
    ),
  ).toISOString();
}

async function sha256Hex(value: string): Promise<string> {
  const input = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", input);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function loadPendingUsers(
  cutoffIso: string,
): Promise<PendingDeletionUser[]> {
  const supabase = createServiceClient();
  const { data, error } = await withSpan(
    "db.query.pending_deletion_users",
    "db.query",
    () =>
      supabase
        .from("user_profiles")
        .select("id, deleted_at, di_hash")
        .not("deleted_at", "is", null)
        .lte("deleted_at", cutoffIso),
  );

  if (error) {
    throw new Error(`Failed to load pending deletions: ${error.message}`);
  }

  return (data ?? []) as PendingDeletionUser[];
}

async function loadEventApplications(
  userId: string,
): Promise<EventApplicationArchive[]> {
  const supabase = createServiceClient();
  const { data, error } = await withSpan(
    "db.query.event_applications_for_archive",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select(
          "id, event_id, ticket_id, status, payment_id, payment_amount, refund_amount, refund_status, created_at, updated_at",
        )
        .eq("user_id", userId),
  );

  if (error) {
    throw new Error(`Failed to load event applications: ${error.message}`);
  }

  return (data ?? []) as EventApplicationArchive[];
}

async function loadReportDetails(
  userId: string,
): Promise<ReportDetailArchive[]> {
  const supabase = createServiceClient();
  const { data, error } = await withSpan(
    "db.query.report_details_for_archive",
    "db.query",
    () =>
      supabase
        .from("report_details")
        .select("id, target_id, target_type, reason, description, created_at")
        .eq("user_id", userId),
  );

  if (error) {
    throw new Error(`Failed to load report details: ${error.message}`);
  }

  return (data ?? []) as ReportDetailArchive[];
}

type UserConsentArchive = {
  id: string;
  consent_key: string;
  consented: boolean;
  policy_version: number | null;
  consented_at: string;
  withdrawn_at: string | null;
  created_at: string;
};

async function loadUserConsents(
  userId: string,
): Promise<UserConsentArchive[]> {
  const supabase = createServiceClient();
  const { data, error } = await withSpan(
    "db.query.user_consents_for_archive",
    "db.query",
    () =>
      supabase
        .from("user_consents")
        .select(
          "id, consent_key, consented, policy_version, consented_at, withdrawn_at, created_at",
        )
        .eq("user_id", userId),
  );

  if (error) {
    throw new Error(`Failed to load user consents: ${error.message}`);
  }

  return (data ?? []) as UserConsentArchive[];
}

async function buildArchivedRecords(
  user: PendingDeletionUser,
  archivedRunId: string,
  now: Date,
): Promise<ArchivedRecordInsert[]> {
  const userIdHash = await sha256Hex(user.id);
  const eventApplications = await loadEventApplications(user.id);
  const reportDetails = await loadReportDetails(user.id);
  const userConsents = await loadUserConsents(user.id);
  const supabase = createServiceClient();
  const { data: authUserData, error: authUserError } = await withSpan(
    "auth.admin.get_user_for_archive",
    "auth.admin",
    () => supabase.auth.admin.getUserById(user.id),
  );

  if (authUserError) {
    throw new Error(`Failed to load auth user: ${authUserError.message}`);
  }

  const archivedRecords: ArchivedRecordInsert[] = [];
  const contractRetention = addYears(now, CONTRACT_RETENTION_YEARS);
  const paymentRetention = addYears(now, PAYMENT_RETENTION_YEARS);
  const disputeRetention = addYears(now, DISPUTE_RETENTION_YEARS);
  const loginRetention = addMonths(now, LOGIN_RETENTION_MONTHS);
  const consentRetention = addYears(now, CONSENT_RETENTION_YEARS);

  for (const application of eventApplications) {
    archivedRecords.push({
      user_id_hash: userIdHash,
      record_type: "contract",
      record_data: {
        archived_run_id: archivedRunId,
        source_table: "event_applications",
        application_id: application.id,
        event_id: application.event_id,
        ticket_id: application.ticket_id,
        status: application.status,
        created_at: application.created_at,
        updated_at: application.updated_at,
      },
      retention_until: contractRetention,
    });

    if (
      application.payment_id ||
      application.payment_amount !== null ||
      (application.refund_amount ?? 0) > 0
    ) {
      archivedRecords.push({
        user_id_hash: userIdHash,
        record_type: "payment",
        record_data: {
          archived_run_id: archivedRunId,
          source_table: "event_applications",
          application_id: application.id,
          payment_id: application.payment_id,
          payment_amount: application.payment_amount,
          refund_amount: application.refund_amount,
          refund_status: application.refund_status,
          created_at: application.created_at,
          updated_at: application.updated_at,
        },
        retention_until: paymentRetention,
      });
    }
  }

  for (const reportDetail of reportDetails) {
    archivedRecords.push({
      user_id_hash: userIdHash,
      record_type: "dispute",
      record_data: {
        archived_run_id: archivedRunId,
        source_table: "report_details",
        report_id: reportDetail.id,
        target_id: reportDetail.target_id,
        target_type: reportDetail.target_type,
        reason: reportDetail.reason,
        description: reportDetail.description,
        created_at: reportDetail.created_at,
      },
      retention_until: disputeRetention,
    });
  }

  archivedRecords.push({
    user_id_hash: userIdHash,
    record_type: "login",
    record_data: {
      archived_run_id: archivedRunId,
      source_table: "auth.users",
      auth_user_id: user.id,
      created_at: authUserData.user?.created_at ?? null,
      last_sign_in_at: authUserData.user?.last_sign_in_at ?? null,
      provider: authUserData.user?.app_metadata?.provider ?? null,
      providers: authUserData.user?.app_metadata?.providers ?? [],
      deleted_at: user.deleted_at,
    },
    retention_until: loginRetention,
  });

  for (const consent of userConsents) {
    archivedRecords.push({
      user_id_hash: userIdHash,
      record_type: "consent",
      record_data: {
        archived_run_id: archivedRunId,
        source_table: "user_consents",
        consent_id: consent.id,
        consent_key: consent.consent_key,
        consented: consent.consented,
        policy_version: consent.policy_version,
        consented_at: consent.consented_at,
        withdrawn_at: consent.withdrawn_at,
        created_at: consent.created_at,
      },
      retention_until: consentRetention,
    });
  }

  return archivedRecords;
}

async function insertArchivedRecords(
  records: ArchivedRecordInsert[],
): Promise<number> {
  if (records.length === 0) {
    return 0;
  }

  const supabase = createServiceClient();
  const { error } = await withSpan(
    "db.insert.archived_records",
    "db.insert",
    () => supabase.from("archived_records").insert(records),
  );

  if (error) {
    throw new Error(`Failed to archive records: ${error.message}`);
  }

  return records.length;
}

async function blockedDiExists(diHash: string): Promise<boolean> {
  const supabase = createServiceClient();
  const { data, error } = await withSpan(
    "db.query.blocked_dis_existing",
    "db.query",
    () =>
      supabase
        .from("blocked_dis")
        .select("di_hash")
        .eq("di_hash", diHash)
        .limit(1),
  );

  if (error) {
    throw new Error(`Failed to check blocked_dis: ${error.message}`);
  }

  return (data?.length ?? 0) > 0;
}

async function upsertBlockedDi(diHash: string, blockedUntil: string) {
  const supabase = createServiceClient();
  const { error } = await withSpan(
    "db.upsert.blocked_dis",
    "db.upsert",
    () =>
      supabase
        .from("blocked_dis")
        .upsert({
          di_hash: diHash,
          blocked_until: blockedUntil,
        }, { onConflict: "di_hash" }),
  );

  if (error) {
    throw new Error(`Failed to block di_hash: ${error.message}`);
  }
}

async function deleteAuthUser(userId: string) {
  const supabase = createServiceClient();
  const { error } = await withSpan(
    "auth.admin.delete_user",
    "auth.admin",
    () => supabase.auth.admin.deleteUser(userId),
  );

  if (error) {
    throw new Error(`Failed to delete auth user: ${error.message}`);
  }
}

async function rollbackArchivedRecords(
  userIdHash: string,
  archivedRunId: string,
) {
  const supabase = createServiceClient();
  const { error } = await withSpan(
    "db.rollback.archived_records",
    "db.delete",
    () =>
      supabase
        .from("archived_records")
        .delete()
        .eq("user_id_hash", userIdHash)
        .contains("record_data", { archived_run_id: archivedRunId }),
  );

  if (error) {
    log({
      function: FN,
      level: "error",
      message: "Failed to rollback archived records after delete failure",
      metadata: { userIdHash, archivedRunId, detail: error },
    });
  }
}

async function rollbackBlockedDi(diHash: string) {
  const supabase = createServiceClient();
  const { error } = await withSpan(
    "db.rollback.blocked_dis",
    "db.delete",
    () =>
      supabase
        .from("blocked_dis")
        .delete()
        .eq("di_hash", diHash),
  );

  if (error) {
    log({
      function: FN,
      level: "error",
      message: "Failed to rollback blocked_di after delete failure",
      metadata: { diHash, detail: error },
    });
  }
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }
  if (req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const authError = requireServiceRole(req);
  if (authError) {
    return authError;
  }

  const now = new Date();
  const cutoffIso = addDays(now, -DELETION_GRACE_DAYS);
  const blockedUntil = addDays(now, BLOCKED_DI_DAYS);
  const archivedRunId = crypto.randomUUID();

  try {
    const users = await loadPendingUsers(cutoffIso);
    const results: UserResult[] = [];
    let archivedRecordCount = 0;
    let blockedCount = 0;
    let deletedCount = 0;

    for (const user of users) {
      const userIdHash = await sha256Hex(user.id);
      let shouldRollbackBlockedDi = false;

      try {
        if (!user.di_hash) {
          throw new Error("Missing di_hash for deleted user");
        }

        const records = await buildArchivedRecords(user, archivedRunId, now);
        const archivedRecords = await insertArchivedRecords(records);
        const blockedAlreadyExisted = await blockedDiExists(user.di_hash);

        await upsertBlockedDi(user.di_hash, blockedUntil);
        shouldRollbackBlockedDi = !blockedAlreadyExisted;
        await deleteAuthUser(user.id);

        archivedRecordCount += archivedRecords;
        if (!blockedAlreadyExisted) {
          blockedCount += 1;
        }
        deletedCount += 1;
        results.push({
          user_id: user.id,
          success: true,
          archived_records: archivedRecords,
          blocked_di: true,
        });
      } catch (error) {
        if (user.di_hash && shouldRollbackBlockedDi) {
          await rollbackBlockedDi(user.di_hash);
        }
        await rollbackArchivedRecords(userIdHash, archivedRunId);

        const message = error instanceof Error ? error.message : String(error);
        log({
          function: FN,
          level: "error",
          message: "Failed to process pending deletion user",
          metadata: { userId: user.id, detail: message },
        });
        results.push({
          user_id: user.id,
          success: false,
          archived_records: 0,
          blocked_di: false,
          error: message,
        });
      }
    }

    return successResponse({
      success: true,
      processed_count: users.length,
      deleted_count: deletedCount,
      blocked_count: blockedCount,
      archived_record_count: archivedRecordCount,
      failed_count: results.filter((result) => !result.success).length,
      results,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Unhandled error in process-pending-deletions",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
}));
