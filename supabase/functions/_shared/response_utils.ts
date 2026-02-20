const jsonHeaders = {
  "Content-Type": "application/json",
};

export function successResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: jsonHeaders });
}

export function errorResponse(error: string, status = 400, details?: unknown): Response {
  const body: Record<string, unknown> = { error };
  if (details !== undefined) body.details = details;
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
