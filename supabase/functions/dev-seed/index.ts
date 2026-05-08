// Fix #1413: dev-seed EF는 이미지 업로드만 담당.
// 유저/파트너 시딩은 seed.dev.sql + psql 직접 실행으로 전환됨.
// Fix #2184 (Batch 9): migrate to minglitEdgeFunction wrapper — public caller, dev-only
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { log } from "../_shared/logger.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const FN = "dev-seed";

// Partner owner that already exists via seed.dev.sql (used for authed storage upload)
const SEED_IMAGE_OWNER_EMAIL = "partner_owner_1@test.com";
const SEED_IMAGE_PASSWORD = "password1234!";

async function uploadSeedImages(supabase: SupabaseClient): Promise<string[]> {
  const imageFiles = [
    "party_cafe_warm.jpg",
    "party_lounge_bright.jpg",
    "party_premium_lounge.jpg",
  ];
  const urls: string[] = [];

  // Check if images already exist in storage (uploaded externally or by a previous run)
  // Use listV2 (cursor-based pagination) over deprecated list() — see #445
  const { data: existing } = await supabase.storage.from("party-assets").listV2(
    { prefix: "seed-images/", limit: 10 },
  );
  const existingNames = new Set(
    (existing?.objects ?? []).map((f: { name: string }) =>
      f.name.replace("seed-images/", "")
    ),
  );

  // If all images already exist, just return their public URLs
  const allExist = imageFiles.every((f) => existingNames.has(f));
  if (allExist) {
    for (const filename of imageFiles) {
      const { data } = supabase.storage.from("party-assets").getPublicUrl(
        `seed-images/${filename}`,
      );
      urls.push(data.publicUrl);
    }
    return urls;
  }

  // Sign in as the first partner owner so storage trigger can set minglit_files.owner_id
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!anonKey) {
    log({ function: FN, level: "error", message: "SUPABASE_ANON_KEY not set — skipping authed image upload" });
    return urls;
  }
  const { data: authData, error: authError } = await supabase.auth
    .signInWithPassword({
      email: SEED_IMAGE_OWNER_EMAIL,
      password: SEED_IMAGE_PASSWORD,
    });
  if (authError || !authData.session) {
    log({ function: FN, level: "error", message: "Failed to sign in as partner owner for image upload", metadata: { detail: authError?.message } });
    return urls;
  }

  const authedClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: { Authorization: `Bearer ${authData.session.access_token}` },
    },
  });

  for (const filename of imageFiles) {
    try {
      const fileUrl = new URL(`./assets/${filename}`, import.meta.url);
      const bytes = await Deno.readFile(fileUrl);
      const path = `seed-images/${filename}`;

      const { error } = await authedClient.storage
        .from("party-assets")
        .upload(path, bytes, { contentType: "image/jpeg", upsert: true });

      if (error) {
        log({ function: FN, level: "error", message: `Failed to upload ${filename}`, metadata: { detail: error.message } });
        continue;
      }

      const { data } = supabase.storage.from("party-assets").getPublicUrl(path);
      urls.push(data.publicUrl);
    } catch (err) {
      log({ function: FN, level: "error", message: `Error uploading ${filename}`, metadata: { detail: (err as Error).message } });
    }
  }

  return urls;
}

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  const url = new URL(req.url);
  const mode = url.searchParams.get("mode") ?? "images-only";

  if (mode !== "images-only") {
    return errorResponse(
      `Invalid mode: "${mode}". Use seed.dev.sql for data seeding.`,
      400,
    );
  }

  try {
    const imageUrls = await uploadSeedImages(ctx.supabase);
    return successResponse({ mode, image_urls: imageUrls });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
};

minglitEdgeFunction(handler);
