import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { initSentry, withSentry } from "../_shared/sentry_utils.ts";

const GITHUB_TOKEN = Deno.env.get("GITHUB_ACCESS_TOKEN");
const GITHUB_REPO = "Mark-Yun/minglit";

export const ALERT_LABELS: Record<string, string[]> = {
  performance: ["metrics-alert", "auto-generated", "performance"],
  business: ["metrics-alert", "auto-generated", "business-metrics"],
  infra: ["metrics-alert", "auto-generated", "infrastructure"],
  report: ["metrics-alert", "auto-generated", "report"],
};

initSentry();

Deno.serve(withSentry(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceRoleKey) {
    return errorResponse("SUPABASE_SERVICE_ROLE_KEY not configured", 500);
  }
  const authHeader = req.headers.get("Authorization") ?? "";
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return errorResponse("Unauthorized", 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { type, title, body: alertBody } = body as {
    type?: string;
    title?: string;
    body?: string;
  };

  if (!type || !title || !alertBody) {
    return errorResponse("Missing required fields: type, title, body", 400);
  }

  if (!GITHUB_TOKEN) {
    return errorResponse("GITHUB_ACCESS_TOKEN not configured", 500);
  }

  const labels = ALERT_LABELS[type] ?? ["metrics-alert", "auto-generated"];

  const searchUrl = `https://api.github.com/search/issues?q=${encodeURIComponent(
    `repo:${GITHUB_REPO} is:issue is:open label:metrics-alert "${title}" in:title`,
  )}`;

  const searchRes = await fetch(searchUrl, {
    headers: {
      "Authorization": `Bearer ${GITHUB_TOKEN}`,
      "Accept": "application/vnd.github.v3+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });

  if (!searchRes.ok) {
    await searchRes.body?.cancel();
    return errorResponse("GitHub API search failed", 502);
  }

  const searchData = await searchRes.json();
  const existingIssue = searchData.items?.[0];

  if (existingIssue) {
    const commentRes = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/issues/${existingIssue.number}/comments`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${GITHUB_TOKEN}`,
          "Accept": "application/vnd.github.v3+json",
          "Content-Type": "application/json",
          "X-GitHub-Api-Version": "2022-11-28",
        },
        body: JSON.stringify({ body: alertBody }),
      },
    );
    if (!commentRes.ok) {
      const errorText = await commentRes.text();
      return errorResponse(`GitHub API comment failed: ${errorText}`, 502);
    }
    await commentRes.body?.cancel();
    return successResponse({ action: "commented", issue_number: existingIssue.number });
  }

  const createRes = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/issues`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${GITHUB_TOKEN}`,
      "Accept": "application/vnd.github.v3+json",
      "Content-Type": "application/json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
    body: JSON.stringify({ title, body: alertBody, labels }),
  });

  if (!createRes.ok) {
    const errorText = await createRes.text();
    return errorResponse(`GitHub API failed: ${errorText}`, 502);
  }

  const issue = await createRes.json();
  return successResponse({ action: "created", issue_number: issue.number, url: issue.html_url });
}));
