// storage-upload — EF-issued signed upload URL flow.
// Fix #2993: Storage quota, byte-rate, concurrency, and reconcile pipeline.

import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";

const COVERED_BUCKETS = new Set([
  "verification-proofs",
  "partner-proofs",
  "party-assets",
]);

const EXTENSION_BY_MIME: Record<string, string> = {
  "image/jpeg": ".jpg",
  "image/png": ".png",
  "image/webp": ".webp",
  "application/pdf": ".pdf",
};

type RpcSingleResult<T> = {
  data: T | null;
  error: { message?: string } | null;
};

type StorageResult<T> = {
  data: T | null;
  error: { message?: string } | null;
};

type ReserveUploadRow = {
  upload_id: string;
  bucket_id: string;
  object_path: string;
  upload_bucket_id: string;
  upload_object_path: string;
  max_file_size_bytes: number;
  public_bucket: boolean;
};

type CompleteUploadRow = {
  upload_id: string;
  bucket_id: string;
  object_path: string;
  upload_bucket_id: string;
  upload_object_path: string;
  status: string;
  actual_size: number | null;
  rejection_reason: string | null;
  mime_type: string;
  public_bucket: boolean;
};

type AbortUploadRow = {
  upload_id: string;
  bucket_id: string;
  object_path: string;
  status: string;
};

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);
  if (ctx.auth.type !== "user") {
    return errorResponse("Unexpected auth type", 500);
  }

  const result = await parseAction(req);
  if (result instanceof Response) return result;

  const { action, body } = result;
  switch (action) {
    case "presign":
      return presignUpload(body, ctx);
    case "complete":
      return completeUpload(body, ctx);
    case "abort":
      return abortUpload(body, ctx);
    default:
      return errorResponse(`Unknown action: ${action}`, 400);
  }
};

async function presignUpload(
  body: Record<string, unknown>,
  ctx: EFContext,
): Promise<Response> {
  const bucket = readString(body, "bucket");
  const declaredSize = readPositiveInteger(body, "declared_size");
  const mimeType = readString(body, "mime");
  const pathPrefix = normalizePathPrefix(
    readOptionalString(body, "path_prefix"),
  );

  if (bucket instanceof Response) return bucket;
  if (declaredSize instanceof Response) return declaredSize;
  if (mimeType instanceof Response) return mimeType;
  if (pathPrefix instanceof Response) return pathPrefix;

  const extension = normalizeExtension(
    readOptionalString(body, "extension"),
    mimeType,
  );
  if (extension instanceof Response) return extension;

  if (!COVERED_BUCKETS.has(bucket)) {
    return errorResponse("unsupported_storage_bucket", 400);
  }

  const objectPath = buildObjectPath(pathPrefix ?? ctx.auth.userId, extension);
  const reserve = await ctx.supabase
    .rpc("reserve_storage_upload", {
      p_user_id: ctx.auth.userId,
      p_bucket_id: bucket,
      p_object_path: objectPath,
      p_declared_size: declaredSize,
      p_mime_type: mimeType,
    })
    .single() as RpcSingleResult<ReserveUploadRow>;

  if (reserve.error || !reserve.data) {
    return errorResponse(
      reserve.error?.message ?? "storage_upload_reserve_failed",
      400,
    );
  }

  const signed = await ctx.supabase.storage
    .from(reserve.data.upload_bucket_id)
    .createSignedUploadUrl(reserve.data.upload_object_path);

  if (signed.error || !signed.data) {
    await abortUploadId(ctx, reserve.data.upload_id);
    return errorResponse(
      signed.error?.message ?? "storage_signed_url_failed",
      500,
    );
  }

  return successResponse({
    upload_id: reserve.data.upload_id,
    bucket: reserve.data.bucket_id,
    path: reserve.data.upload_object_path,
    upload_bucket: reserve.data.upload_bucket_id,
    upload_path: reserve.data.upload_object_path,
    final_path: reserve.data.object_path,
    token: signed.data.token,
    signed_url: signed.data.signedUrl,
    public_url: null,
    max_file_size_bytes: reserve.data.max_file_size_bytes,
  });
}

async function completeUpload(
  body: Record<string, unknown>,
  ctx: EFContext,
): Promise<Response> {
  const uploadId = readString(body, "upload_id");
  if (uploadId instanceof Response) return uploadId;

  const result = await ctx.supabase
    .rpc("complete_storage_upload", {
      p_upload_id: uploadId,
      p_user_id: ctx.auth.userId,
    })
    .single() as RpcSingleResult<CompleteUploadRow>;

  if (result.error || !result.data) {
    return errorResponse(
      result.error?.message ?? "storage_upload_complete_failed",
      400,
    );
  }

  let upload = result.data;

  if (upload.status === "rejected") {
    const cleanup = await removeStorageObject(
      ctx,
      upload.upload_bucket_id,
      upload.upload_object_path,
      "storage_rejected_object_cleanup_failed",
    );
    if (cleanup) return cleanup;
  }

  if (upload.status === "publishing") {
    const published = await publishPublicUpload(ctx, upload);
    if (published instanceof Response) return published;
    upload = published;
  }

  return uploadResponse(ctx, upload);
}

async function abortUpload(
  body: Record<string, unknown>,
  ctx: EFContext,
): Promise<Response> {
  const uploadId = readString(body, "upload_id");
  if (uploadId instanceof Response) return uploadId;

  const result = await abortUploadId(ctx, uploadId);
  if (result.error || !result.data) {
    return errorResponse(
      result.error?.message ?? "storage_upload_abort_failed",
      400,
    );
  }

  return successResponse({
    upload_id: result.data.upload_id,
    bucket: result.data.bucket_id,
    path: result.data.object_path,
    status: result.data.status,
  });
}

function abortUploadId(
  ctx: EFContext,
  uploadId: string,
): Promise<RpcSingleResult<AbortUploadRow>> {
  return ctx.supabase
    .rpc("abort_storage_upload", {
      p_upload_id: uploadId,
      p_user_id: ctx.auth.type === "user" ? ctx.auth.userId : "",
    })
    .single() as Promise<RpcSingleResult<AbortUploadRow>>;
}

async function publishPublicUpload(
  ctx: EFContext,
  upload: CompleteUploadRow,
): Promise<CompleteUploadRow | Response> {
  const downloaded = await ctx.supabase.storage
    .from(upload.upload_bucket_id)
    .download(upload.upload_object_path) as StorageResult<Blob>;
  if (downloaded.error || !downloaded.data) {
    return errorResponse(
      downloaded.error?.message ?? "storage_staging_download_failed",
      500,
    );
  }

  const publishedObject = await ctx.supabase.storage
    .from(upload.bucket_id)
    .upload(upload.object_path, downloaded.data, {
      contentType: upload.mime_type,
      upsert: false,
    }) as StorageResult<unknown>;
  if (publishedObject.error) {
    return errorResponse(
      publishedObject.error.message ?? "storage_public_publish_failed",
      500,
    );
  }

  const published = await ctx.supabase
    .rpc("publish_storage_upload", {
      p_upload_id: upload.upload_id,
      p_user_id: ctx.auth.type === "user" ? ctx.auth.userId : "",
    })
    .single() as RpcSingleResult<CompleteUploadRow>;

  if (published.error || !published.data) {
    await ctx.supabase.storage
      .from(upload.bucket_id)
      .remove([upload.object_path]);
    return errorResponse(
      published.error?.message ?? "storage_upload_publish_failed",
      500,
    );
  }

  await ctx.supabase.storage
    .from(upload.upload_bucket_id)
    .remove([upload.upload_object_path]);

  return published.data;
}

async function removeStorageObject(
  ctx: EFContext,
  bucket: string,
  path: string,
  errorCode: string,
): Promise<Response | null> {
  const removed = await ctx.supabase.storage
    .from(bucket)
    .remove([path]) as StorageResult<unknown>;
  if (removed.error) {
    return errorResponse(removed.error.message ?? errorCode, 500);
  }
  return null;
}

function uploadResponse(ctx: EFContext, upload: CompleteUploadRow): Response {
  const publicUrl = upload.public_bucket && upload.status === "completed"
    ? ctx.supabase.storage.from(upload.bucket_id)
      .getPublicUrl(upload.object_path).data.publicUrl
    : null;

  return successResponse({
    upload_id: upload.upload_id,
    bucket: upload.bucket_id,
    path: upload.object_path,
    upload_bucket: upload.upload_bucket_id,
    upload_path: upload.upload_object_path,
    status: upload.status,
    actual_size: upload.actual_size,
    rejection_reason: upload.rejection_reason,
    public_url: publicUrl,
  });
}

function readString(
  body: Record<string, unknown>,
  field: string,
): string | Response {
  const value = body[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    return errorResponse(`Missing or invalid field: ${field}`, 400);
  }
  return value.trim();
}

function readOptionalString(
  body: Record<string, unknown>,
  field: string,
): string | null | Response {
  const value = body[field];
  if (value === undefined || value === null) return null;
  if (typeof value !== "string") {
    return errorResponse(`Invalid field: ${field}`, 400);
  }
  return value;
}

function readPositiveInteger(
  body: Record<string, unknown>,
  field: string,
): number | Response {
  const value = body[field];
  if (!Number.isSafeInteger(value) || (value as number) <= 0) {
    return errorResponse(`Missing or invalid field: ${field}`, 400);
  }
  return value as number;
}

function normalizePathPrefix(
  value: string | null | Response,
): string | null | Response {
  if (value instanceof Response || value === null) return value;
  const trimmed = value.trim().replace(/^\/+|\/+$/g, "");
  if (
    trimmed.length === 0 ||
    trimmed.length > 400 ||
    trimmed.includes("..") ||
    trimmed.includes("//")
  ) {
    return errorResponse("Invalid field: path_prefix", 400);
  }
  return trimmed;
}

function normalizeExtension(
  value: string | null | Response,
  mimeType: string,
): string | Response {
  if (value instanceof Response) return value;
  const fallback = EXTENSION_BY_MIME[mimeType];
  const raw = (value ?? fallback ?? "").trim().toLowerCase();
  if (!raw) return errorResponse("Missing or invalid field: extension", 400);
  const ext = raw.startsWith(".") ? raw : `.${raw}`;
  if (!/^\.[a-z0-9]{1,8}$/.test(ext)) {
    return errorResponse("Invalid field: extension", 400);
  }
  return ext === ".jpeg" ? ".jpg" : ext;
}

function buildObjectPath(pathPrefix: string, extension: string): string {
  return `${pathPrefix}/${crypto.randomUUID()}${extension}`;
}

minglitEdgeFunction(handler);
