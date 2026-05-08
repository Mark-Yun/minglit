// Fix #2184 (Batch 9): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const FN = "bug-report";

const GITHUB_TOKEN = Deno.env.get("GITHUB_ACCESS_TOKEN");
const GITHUB_REPO = "Mark-Yun/minglit";

export const handler = async (req: Request, _ctx: EFContext): Promise<Response> => {
  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const {
      title,
      description,
      logs,
      timestamp,
      platform,
      screenshotUrl,
      environment,
      layoutDumpUrl,
    } = body as {
      title?: string;
      description?: string;
      logs?: string;
      timestamp?: string;
      platform?: string;
      screenshotUrl?: string;
      environment?: Record<string, unknown>;
      layoutDumpUrl?: string;
    };

    if (!title || !description) {
      return errorResponse("Missing required fields: title, description", 400);
    }

    const MAX_BODY_LENGTH = 60000;
    const logsStr = logs ?? "";
    const truncatedLogs = logsStr.length > MAX_BODY_LENGTH
      ? logsStr.substring(0, MAX_BODY_LENGTH) + "\n...[truncated]"
      : logsStr;

    // Screenshot section (only if screenshotUrl is truthy)
    const screenshotSection = screenshotUrl
      ? `\n\n## Screenshot\n![Screenshot](${screenshotUrl})\n`
      : "";

    // Environment section (only if environment is a non-null object)
    const environmentSection = environment && typeof environment === "object"
      ? `\n\n## Environment\n| Key | Value |\n|-----|-------|\n${
        Object.entries(environment)
          .filter(([, v]) => v != null)
          .map(([k, v]) => `| ${k} | ${v} |`)
          .join("\n")
      }\n`
      : "";

    // Layout Dump section (only if layoutDumpUrl is truthy)
    const layoutDumpSection = layoutDumpUrl
      ? `\n\n## Layout Dump\n[📐 View Layout Dump](${layoutDumpUrl})\n`
      : "";

    if (!GITHUB_TOKEN) {
      throw new Error("GITHUB_ACCESS_TOKEN is not set");
    }

    const issueBody = `
### 🐞 Bug Report

**Description:**
${description}

**Environment:**
- Platform: ${platform ?? "Unknown"}
- Timestamp: ${timestamp}

<details>
<summary>📋 Logs</summary>

\`\`\`log
${truncatedLogs}
\`\`\`

</details>
${screenshotSection}${environmentSection}${layoutDumpSection}`;

    const response = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/issues`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${GITHUB_TOKEN}`,
          "Content-Type": "application/json",
          "User-Agent": "Minglit-Bug-Reporter",
        },
        body: JSON.stringify({
          title: `[Bug Report] ${title}`,
          body: issueBody,
          labels: ["bug-report", "from-app"],
        }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      log({
        function: FN,
        level: "error",
        message: "GitHub API Error",
        metadata: { detail: errorText },
      });
      throw new Error(`GitHub API Error: ${response.status}`);
    }

    const data = await response.json();

    return successResponse({ success: true, url: data.html_url });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Internal Error",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
