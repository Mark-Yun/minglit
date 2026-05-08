// user-event-feed/index.ts — Server-side event feed with sorting, filtering & cursor pagination (#614)
// Fix #2185 (Batch 5): migrate to minglitEdgeFunction wrapper — auth via manifest (user + public callers)

import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";

const FN = "user-event-feed";

const VALID_SORT_BY = ["recommended", "closing_soon", "nearest_date"] as const;
type SortBy = typeof VALID_SORT_BY[number];

// Fix #1748: nearby 분당 최대 요청 수
const NEARBY_RATE_LIMIT_PER_MINUTE = 30;

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  const userId: string | null = ctx.auth.type === "user" ? ctx.auth.userId : null;
  const { supabase } = ctx;

  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const {
    sort_by = "recommended",
    filters = {},
    limit: rawLimit = 20,
    cursor = null,
  } = body as {
    sort_by?: string;
    filters?: Record<string, unknown>;
    limit?: number;
    cursor?: { sort_key: string; id: string } | null;
  };

  // Extract filters early — nearby presence determines auth requirement
  const {
    has_remaining_slots = false,
    eligible_only = false,
    nearby = null,
  } = filters as {
    has_remaining_slots?: boolean;
    eligible_only?: boolean;
    nearby?: Record<string, unknown> | null;
  };

  // Fix #1748: nearby requires authentication — unauthenticated nearby would
  // insert user_id=NULL into location_access_log, polluting the §16 legal log.
  if (nearby !== null && userId === null) {
    return errorResponse("Unauthorized", 401);
  }

  // Validate sort_by
  if (!VALID_SORT_BY.includes(sort_by as SortBy)) {
    return errorResponse(
      `Invalid sort_by: "${sort_by}". Must be one of: ${
        VALID_SORT_BY.join(", ")
      }`,
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
      return errorResponse(
        "Invalid cursor: must be {sort_key: string, id: string}",
        400,
      );
    }
  }

  // Fix #1748: validate nearby shape before any DB access
  let nearbyTyped: { lat: number; lng: number; radius_km: number } | null =
    null;
  if (nearby !== null) {
    const { lat, lng, radius_km } = nearby as Record<string, unknown>;
    if (
      typeof lat !== "number" || !Number.isFinite(lat) || lat < -90 ||
      lat > 90 ||
      typeof lng !== "number" || !Number.isFinite(lng) || lng < -180 ||
      lng > 180 ||
      typeof radius_km !== "number" || !Number.isFinite(radius_km) ||
      radius_km <= 0 || radius_km > 50
    ) {
      return errorResponse(
        "Invalid nearby filter: lat [-90,90], lng [-180,180], radius_km (0, 50]",
        400,
      );
    }
    nearbyTyped = { lat, lng, radius_km };
  }

  // Fix #1748: rate limit — max NEARBY_RATE_LIMIT_PER_MINUTE requests/minute/user.
  // Fails open: a DB hiccup logs a warning but does not block the request.
  if (nearbyTyped !== null && userId !== null) {
    const since = new Date(Date.now() - 60_000).toISOString();
    const { count, error: countError } = await supabase
      .from("location_access_log")
      .select("*", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("purpose", "nearby_search")
      .gte("accessed_at", since);

    if (countError) {
      log({
        function: FN,
        level: "warn",
        message: "rate limit check failed — proceeding",
        metadata: { detail: countError.message },
      });
    } else if ((count ?? 0) >= NEARBY_RATE_LIMIT_PER_MINUTE) {
      return errorResponse(
        `Rate limit exceeded: max ${NEARBY_RATE_LIMIT_PER_MINUTE} nearby searches per minute`,
        429,
      );
    }
  }

  // Call the RPC function
  const rpcParams: Record<string, unknown> = {
    p_user_id: userId,
    p_sort_by: sort_by,
    p_eligible_only: eligible_only,
    p_has_remaining_slots: has_remaining_slots,
    p_lat: nearbyTyped?.lat ?? null,
    p_lng: nearbyTyped?.lng ?? null,
    p_radius_km: nearbyTyped?.radius_km ?? null,
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
      has_nearby: nearbyTyped !== null,
    },
  });

  // 위치정보법 §16: 주변 검색 요청 1건 = 1 row 기록 (GPS 좌표 저장 금지)
  // INSERT 실패 시 요청 거부 — 기록 없이 위치 검색을 허용하면 법적 의무 미이행
  if (nearbyTyped !== null) {
    const { error: logError } = await supabase
      .from("location_access_log")
      .insert({ user_id: userId, purpose: "nearby_search" });
    if (logError) {
      log({
        function: FN,
        level: "error",
        message: "location_access_log INSERT failed",
        metadata: { detail: logError.message },
      });
      return errorResponse(
        "Failed to record location access log",
        500,
        logError.message,
      );
    }
  }

  const { data, error } = await supabase.rpc("user_event_feed", rpcParams);

  if (error) {
    log({
      function: FN,
      level: "error",
      message: "RPC error",
      metadata: { detail: error.message },
    });
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
};

minglitEdgeFunction(handler);
