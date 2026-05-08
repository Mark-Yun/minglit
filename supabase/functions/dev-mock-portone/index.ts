// Fix #2184 (Batch 9): migrate to minglitEdgeFunction wrapper — public caller, dev-only
import { parseJsonBody } from "../_shared/request_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export const handler = async (req: Request, _ctx: EFContext): Promise<Response> => {
  const url = new URL(req.url);
  const path = url.pathname;

  // Strip function prefix if present (e.g. /functions/v1/dev-mock-portone/users/getToken)
  const apiPath = path.replace(/^.*\/dev-mock-portone/, "") || "/";

  // POST /users/getToken
  if (req.method === "POST" && apiPath === "/users/getToken") {
    return json({
      code: 0,
      response: { access_token: "mock-token-for-testing" },
    });
  }

  // GET /payments/:imp_uid
  const paymentsGetMatch = apiPath.match(/^\/payments\/([^/]+)$/);
  if (req.method === "GET" && paymentsGetMatch) {
    const impUid = paymentsGetMatch[1];
    if (impUid.startsWith("imp_fail_")) {
      return json({ code: 0, response: { status: "failed" } });
    }
    return json({
      code: 0,
      response: {
        status: "paid",
        amount: 15000,
        merchant_uid: "order-test-123",
        imp_uid: impUid,
      },
    });
  }

  // POST /payments/cancel
  if (req.method === "POST" && apiPath === "/payments/cancel") {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;
    const impUid = body.imp_uid as string;
    return json({
      code: 0,
      response: {
        imp_uid: impUid,
        status: "cancelled",
        cancel_amount: 15000,
      },
    });
  }

  return json({ error: "Not found" }, 404);
};

minglitEdgeFunction(handler);
