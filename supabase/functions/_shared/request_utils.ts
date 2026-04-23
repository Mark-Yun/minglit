import { errorResponse } from "./response_utils.ts";

export async function parseJsonBody(
  req: Request,
): Promise<Record<string, unknown> | Response> {
  try {
    const parsed = await req.json();
    if (
      typeof parsed !== "object" || parsed === null || Array.isArray(parsed)
    ) {
      return errorResponse("Request body must be a JSON object", 400);
    }
    return parsed as Record<string, unknown>;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }
}

export async function parseAction(
  req: Request,
): Promise<{ action: string; body: Record<string, unknown> } | Response> {
  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;
  const action = body.action as string | undefined;
  if (typeof action !== "string") {
    return errorResponse('Missing or invalid "action" field', 400);
  }
  return { action, body };
}
