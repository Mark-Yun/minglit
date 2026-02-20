import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";

const GITHUB_TOKEN = Deno.env.get("GITHUB_ACCESS_TOKEN");
const GITHUB_REPO = "Mark-Yun/minglit";

serve(async (req) => {
  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { title, description, logs, timestamp, platform } = reqBody as {
      title?: string;
      description?: string;
      logs?: string;
      timestamp?: string;
      platform?: string;
    };

    if (!title || !description) {
      return errorResponse("Missing required fields: title, description", 400);
    }

    if (!GITHUB_TOKEN) {
      throw new Error("GITHUB_ACCESS_TOKEN is not set");
    }

    const body = `
### 🐞 Bug Report

**Description:**
${description}

**Environment:**
- Platform: ${platform ?? 'Unknown'}
- Timestamp: ${timestamp}

<details>
<summary>📋 Logs</summary>

\`\`\`log
${logs}
\`\`\`

</details>
`;

    const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/issues`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GITHUB_TOKEN}`,
        "Content-Type": "application/json",
        "User-Agent": "Minglit-Bug-Reporter"
      },
      body: JSON.stringify({
        title: `[Bug Report] ${title}`,
        body: body,
        labels: ["bug-report", "from-app"]
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("GitHub API Error:", errorText);
      throw new Error(`GitHub API Error: ${response.status}`);
    }

    const data = await response.json();

    return successResponse({ success: true, url: data.html_url });

  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("Internal Error:", message);
    return errorResponse(message, 500);
  }
});
