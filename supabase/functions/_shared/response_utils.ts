export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json",
};

/** Handle CORS preflight (OPTIONS) requests. */
export function corsResponse(): Response {
  return new Response("ok", { headers: corsHeaders });
}

export function successResponse(
  data: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(data), { status, headers: jsonHeaders });
}

export function errorResponse(
  error: string,
  status = 400,
  details?: unknown,
): Response {
  const body: Record<string, unknown> = { error };
  if (details !== undefined) body.details = details;
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
