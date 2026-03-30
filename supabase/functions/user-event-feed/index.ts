// user-event-feed/index.ts — Server-side event feed with sorting, filtering & cursor pagination (#614)

import { createServiceClient } from "../_shared/supabase_client.ts";
import { corsResponse, errorResponse, successResponse } from "../_shared/response_utils.ts";
import { optionalAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "user-event-feed";

const VALID_SORT_BY = ["recommended", "closing_soon", "nearest_date"] as const;
type SortBy = typeof VALID_SORT_BY[number];

initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  // Optional auth — anonymous users get a basic feed
  const userId = await optionalAuth(req);

  let reqBody: Record<string, unknown>;
  try {
    reqBody = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const {
    sort_by = "recommended",
    filters = {},
    limit: rawLimit = 20,
    cursor = null,
  } = reqBody as {
    sort_by?: string;
    filters?: Record<string, unknown>;
    limit?: number;
    cursor?: { sort_key: string; id: string } | null;
  };

  // Validate sort_by
  if (!VALID_SORT_BY.includes(sort_by as SortBy)) {
    return errorResponse(
      `Invalid sort_by: "${sort_by}". Must be one of: ${VALID_SORT_BY.join(", ")}`,
      400,
    );
  }

  // Validate & clamp limit
  const limit = Math.min(Math.max(Number(rawLimit) || 20, 1), 50);

  // Validate cursor
  if (cursor !== null && cursor !== undefined) {
    if (
      typeof cursor !== "object" ||
      typeof cursor.sort_key !== "string" ||
      typeof cursor.id !== "string"
    ) {
      return errorResponse("Invalid cursor: must be {sort_key: string, id: string}", 400);
    }
  }

  // Extract filters
  const {
    has_remaining_slots = false,
    eligible_only = false,
    nearby = null,
  } = filters as {
    has_remaining_slots?: boolean;
    eligible_only?: boolean;
    nearby?: { lat: number; lng: number; radius_km: number } | null;
  };

  const supabase = createServiceClient();

  // Call the RPC function
  const rpcParams: Record<string, unknown> = {
    p_user_id: userId,
    p_sort_by: sort_by,
    p_eligible_only: eligible_only,
    p_has_remaining_slots: has_remaining_slots,
    p_lat: nearby?.lat ?? null,
    p_lng: nearby?.lng ?? null,
    p_radius_km: nearby?.radius_km ?? null,
    p_limit: limit,
    p_cursor_sort_key: cursor?.sort_key ?? null,
    p_cursor_id: cursor?.id ?? null,
  };

  log({
    function: FN,
    level: "info",
    message: "Fetching event feed",
    metadata: {
      sort_by,
      limit,
      has_cursor: cursor !== null,
      authenticated: userId !== null,
      has_remaining_slots,
      eligible_only,
      has_nearby: nearby !== null,
    },
  });

  const { data, error } = await supabase.rpc("user_event_feed", rpcParams);

  if (error) {
    log({ function: FN, level: "error", message: "RPC error", metadata: { detail: error.message } });
    return errorResponse("Failed to fetch event feed", 500, error.message);
  }

  const result = data as {
    events: unknown[];
    has_more: boolean;
    next_cursor: { sort_key: string; id: string } | null;
  };

  log({
    function: FN,
    level: "info",
    message: "Feed fetched",
    metadata: { count: result.events?.length ?? 0, has_more: result.has_more },
  });

  return successResponse({
    events: result.events ?? [],
    has_more: result.has_more ?? false,
    next_cursor: result.next_cursor ?? null,
    sort_by,
    limit,
  });
}));
