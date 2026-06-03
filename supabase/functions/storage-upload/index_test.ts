// storage-upload/index_test.ts — handler unit tests for signed upload flow.

import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  makeCtx,
  readJson,
  runHandler,
  type Handler,
} from "../_shared/_testing/mod.ts";
import { importHandlerWithStubbedServe } from "../_test_utils/mock_http.ts";

let _handler: Handler | null = null;
async function getHandler(): Promise<Handler> {
  if (_handler) return _handler;
  _handler = await importHandlerWithStubbedServe<Handler>(
    new URL("./index.ts", import.meta.url),
  );
  return _handler!;
}

type RpcResult = {
  data: Record<string, unknown> | null;
  error: { message?: string } | null;
};

function makeStorageUploadSupabase(opts: {
  rpcResults: RpcResult[];
  signedError?: { message: string } | null;
}) {
  const calls: Array<{
    type: string;
    name?: string;
    args?: unknown;
    bucket?: string;
    paths?: string[];
  }> = [];
  const rpcResults = [...opts.rpcResults];

  const supabase = {
    rpc(name: string, args: Record<string, unknown>) {
      calls.push({ type: "rpc", name, args });
      return {
        single: () => Promise.resolve(rpcResults.shift() ?? {
          data: null,
          error: { message: `no fake rpc result for ${name}` },
        }),
      };
    },
    storage: {
      from(bucket: string) {
        calls.push({ type: "storage.from", bucket });
        return {
          createSignedUploadUrl(path: string) {
            calls.push({
              type: "storage.createSignedUploadUrl",
              bucket,
              args: { path },
            });
            if (opts.signedError) {
              return Promise.resolve({ data: null, error: opts.signedError });
            }
            return Promise.resolve({
              data: {
                path,
                token: "signed-token",
                signedUrl: `https://storage.test/${bucket}/${path}?token=signed-token`,
              },
              error: null,
            });
          },
          getPublicUrl(path: string) {
            calls.push({
              type: "storage.getPublicUrl",
              bucket,
              args: { path },
            });
            return {
              data: {
                publicUrl: `https://storage.test/object/public/${bucket}/${path}`,
              },
            };
          },
          remove(paths: string[]) {
            calls.push({ type: "storage.remove", bucket, paths });
            return Promise.resolve({ data: paths, error: null });
          },
        };
      },
    },
  };

  return { supabase, calls };
}

Deno.test("presign creates reservation and signed upload token", async () => {
  const handler = await getHandler();
  const { supabase, calls } = makeStorageUploadSupabase({
    rpcResults: [{
      data: {
        upload_id: "upload-1",
        object_path: "partner-1/generated.jpg",
        max_file_size_bytes: 52428800,
        public_bucket: true,
      },
      error: null,
    }],
  });

  const response = await runHandler(handler, {
    method: "POST",
    body: {
      action: "presign",
      bucket: "party-assets",
      path_prefix: "partner-1",
      declared_size: 1024,
      mime: "image/jpeg",
      extension: ".jpg",
    },
    ctx: makeCtx({ supabase: supabase as never, userId: "user-1" }),
  });
  const payload = await readJson(response);

  assertEquals(response.status, 200);
  assertEquals(payload.upload_id, "upload-1");
  assertEquals(payload.path, "partner-1/generated.jpg");
  assertEquals(payload.token, "signed-token");
  assertEquals(
    payload.public_url,
    "https://storage.test/object/public/party-assets/partner-1/generated.jpg",
  );

  const reserve = calls.find((call) => call.name === "reserve_storage_upload");
  assertEquals(reserve?.type, "rpc");
  const reserveArgs = reserve?.args as Record<string, unknown>;
  assertEquals(reserveArgs.p_user_id, "user-1");
  assertEquals(reserveArgs.p_bucket_id, "party-assets");
  assertStringIncludes(reserveArgs.p_object_path as string, "partner-1/");
  assertEquals(reserveArgs.p_declared_size, 1024);
  assertEquals(reserveArgs.p_mime_type, "image/jpeg");
});

Deno.test("presign rejects unsupported buckets before RPC", async () => {
  const handler = await getHandler();
  const { supabase, calls } = makeStorageUploadSupabase({ rpcResults: [] });

  const response = await runHandler(handler, {
    method: "POST",
    body: {
      action: "presign",
      bucket: "bug-report-attachments",
      declared_size: 1024,
      mime: "image/png",
      extension: ".png",
    },
    ctx: makeCtx({ supabase: supabase as never, userId: "user-1" }),
  });
  const payload = await readJson(response);

  assertEquals(response.status, 400);
  assertEquals(payload.error, "unsupported_storage_bucket");
  assertEquals(calls.length, 0);
});

Deno.test("complete removes object when DB reconcile rejects it", async () => {
  const handler = await getHandler();
  const { supabase, calls } = makeStorageUploadSupabase({
    rpcResults: [{
      data: {
        upload_id: "upload-1",
        bucket_id: "partner-proofs",
        object_path: "user-1/mismatch.jpg",
        status: "rejected",
        actual_size: 2000,
        rejection_reason: "actual_size_exceeds_declared_size",
        public_bucket: false,
      },
      error: null,
    }],
  });

  const response = await runHandler(handler, {
    method: "POST",
    body: {
      action: "complete",
      upload_id: "upload-1",
    },
    ctx: makeCtx({ supabase: supabase as never, userId: "user-1" }),
  });
  const payload = await readJson(response);

  assertEquals(response.status, 200);
  assertEquals(payload.status, "rejected");
  assertEquals(payload.rejection_reason, "actual_size_exceeds_declared_size");
  assertEquals(
    calls.some((call) =>
      call.type === "storage.remove" &&
      call.bucket === "partner-proofs" &&
      call.paths?.[0] === "user-1/mismatch.jpg"
    ),
    true,
  );
});

Deno.test("presign aborts reservation when signed URL creation fails", async () => {
  const handler = await getHandler();
  const { supabase, calls } = makeStorageUploadSupabase({
    rpcResults: [
      {
        data: {
          upload_id: "upload-1",
          object_path: "user-1/file.jpg",
          max_file_size_bytes: 10485760,
          public_bucket: false,
        },
        error: null,
      },
      {
        data: {
          upload_id: "upload-1",
          bucket_id: "partner-proofs",
          object_path: "user-1/file.jpg",
          status: "aborted",
        },
        error: null,
      },
    ],
    signedError: { message: "storage unavailable" },
  });

  const response = await runHandler(handler, {
    method: "POST",
    body: {
      action: "presign",
      bucket: "partner-proofs",
      path_prefix: "user-1",
      declared_size: 1024,
      mime: "image/jpeg",
      extension: ".jpg",
    },
    ctx: makeCtx({ supabase: supabase as never, userId: "user-1" }),
  });
  const payload = await readJson(response);

  assertEquals(response.status, 500);
  assertEquals(payload.error, "storage unavailable");
  assertEquals(
    calls.some((call) => call.name === "abort_storage_upload"),
    true,
  );
});
