import type { SimLogEntry, SimSummary } from "./sim_types.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const GITHUB_REPO = "Mark-Yun/minglit";
const BUCKET_NAME = "e2e-test-logs";
const MAX_ISSUE_BODY_BYTES = 60_000;

export class SimLogCollector {
  private entries: SimLogEntry[] = [];

  log(
    level: "info" | "warn" | "error",
    phase: string,
    step: string,
    message: string,
    data?: unknown,
  ): void {
    this.entries.push({
      timestamp: new Date().toISOString(),
      level,
      phase,
      step,
      message,
      data,
    });
  }

  getEntries(): SimLogEntry[] {
    return this.entries;
  }

  formatAsText(): string {
    return this.entries
      .map((e) => {
        const header = `[${e.timestamp}] [${e.level.toUpperCase()}] [${e.phase}:${e.step}] ${e.message}`;
        if (e.data !== undefined) {
          return `${header}\n${JSON.stringify(e.data)}`;
        }
        return header;
      })
      .join("\n");
  }

  getSummaryLines(): string[] {
    const errors = this.entries.filter((e) => e.level === "error");
    const warns = this.entries.filter((e) => e.level === "warn");
    const lines: string[] = [
      `Total log entries: ${this.entries.length}`,
      `Errors: ${errors.length}`,
      `Warnings: ${warns.length}`,
    ];
    if (errors.length > 0) {
      lines.push("--- Recent Errors ---");
      for (const e of errors.slice(-5)) {
        lines.push(`  [${e.phase}:${e.step}] ${e.message}`);
      }
    }
    return lines;
  }
}

export async function simUploadLog(
  supabase: SupabaseClient,
  runId: string,
  logText: string,
): Promise<string | null> {
  try {
    const dateStr = new Date().toISOString().slice(0, 10);
    const path = `${dateStr}/${runId}.log`;

    const encoder = new TextEncoder();
    const bytes = encoder.encode(logText);

    const { error } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(path, bytes, { contentType: "text/plain", upsert: true });

    if (error) {
      console.error("[sim_reporter] Storage upload error:", error.message);
      return null;
    }

    const { data: signedData, error: signErr } = await supabase.storage
      .from(BUCKET_NAME)
      .createSignedUrl(path, 86400);
    if (signErr) {
      console.error("[sim_reporter] Signed URL error:", signErr.message);
      return null;
    }
    return signedData?.signedUrl ?? null;
  } catch (err) {
    console.error("[sim_reporter] simUploadLog exception:", err);
    return null;
  }
}

export async function simCreateGitHubIssue(
  summary: SimSummary,
  logUrl: string | null,
  runId: string,
  logText: string,
): Promise<string | null> {
  if (summary.failed === 0) return null;

  const githubToken = Deno.env.get("GITHUB_ACCESS_TOKEN");
  if (!githubToken) {
    console.error("[sim_reporter] GITHUB_ACCESS_TOKEN is not set");
    return null;
  }

  try {
    const timestamp = new Date().toISOString();
    const title = `[E2E-SIM] ${summary.failed} failures — ${timestamp}`;

    const failedAssertions = summary.assertion_results.filter((r) => !r.passed);
    const assertionLines = failedAssertions
      .map(
        (r) =>
          `- **${r.check_name}**: expected \`${JSON.stringify(r.expected)}\`, got \`${JSON.stringify(r.actual)}\`${r.details ? ` — ${r.details}` : ""}`,
      )
      .join("\n");

    const logSection = logUrl
      ? `[View Full Log](${logUrl})`
      : "No storage log available";

    const encoder = new TextEncoder();
    let truncatedLog = logText;
    const logBytes = encoder.encode(logText);
    if (logBytes.length > MAX_ISSUE_BODY_BYTES) {
      let safeEnd = MAX_ISSUE_BODY_BYTES;
      while (safeEnd > 0 && (logBytes[safeEnd] & 0xc0) === 0x80) {
        safeEnd--;
      }
      truncatedLog = new TextDecoder().decode(logBytes.slice(0, safeEnd)) + "\n...[truncated]";
    }

    const axiomDataset = Deno.env.get("AXIOM_DATASET") ?? "edge-functions";
    const body = `## E2E Simulation Failure Report

**Run ID**: \`${runId}\`
**Failed Checks**: ${summary.failed}/${summary.total_checks}
**Environment**: ${Deno.env.get("ENVIRONMENT") ?? "unknown"}

## Failed Assertions
${assertionLines || "_No assertion details available_"}

## Axiom 디버깅
Edge Function 로그는 Axiom에서 확인할 수 있습니다.

\`\`\`
axiom query "['${axiomDataset}'] | where metadata.runId == '${runId}'"
\`\`\`

또는 Axiom 대시보드에서 dataset \`${axiomDataset}\`를 선택하고 \`metadata.runId == '${runId}'\`로 필터링하세요.

## Log Details
${logSection}

<details>
<summary>📋 Full Log (truncated to 60KB)</summary>

\`\`\`log
${truncatedLog}
\`\`\`

</details>`;

    const response = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/issues`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${githubToken}`,
          "Content-Type": "application/json",
          "User-Agent": "Minglit-E2E-Reporter",
        },
        body: JSON.stringify({
          title,
          body,
          labels: ["e2e-simulation", "automated"],
        }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error("[sim_reporter] GitHub API error:", errorText);
      return null;
    }

    const data = await response.json();
    return data.html_url ?? null;
  } catch (err) {
    console.error("[sim_reporter] simCreateGitHubIssue exception:", err);
    return null;
  }
}
