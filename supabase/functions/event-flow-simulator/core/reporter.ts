// core/reporter.ts — Cascade 실패 시 GH 이슈 자동 생성

import type { Trace } from "./trace.ts";
import type { InvariantViolation } from "../invariant/_registry.ts";

const GITHUB_REPO = "Mark-Yun/minglit";
const MAX_ISSUE_BODY_BYTES = 60_000;

export interface ReporterInput {
  runId: string;
  trace: Trace;
  violations: InvariantViolation[];
}

export function summarizeTrace(trace: Trace) {
  const total = trace.length;
  const ok = trace.filter((e) => e.ok).length;
  const failed = total - ok;
  return { total, ok, failed };
}

/**
 * trace 실패 또는 invariant 위반 시 GH 이슈 생성.
 * 양쪽 모두 0 이면 null 반환 (이슈 생성 안 함).
 */
export async function reportFailure(input: ReporterInput): Promise<string | null> {
  const { runId, trace, violations } = input;
  const summary = summarizeTrace(trace);

  if (summary.failed === 0 && violations.length === 0) return null;

  const githubToken = Deno.env.get("GITHUB_ACCESS_TOKEN");
  if (!githubToken) {
    console.error("[reporter] GITHUB_ACCESS_TOKEN is not set");
    return null;
  }

  const timestamp = new Date().toISOString();
  const title =
    `[CASCADE] ${summary.failed} action fails + ${violations.length} invariant violations — ${timestamp}`;

  const failedTraceLines = trace
    .filter((e) => !e.ok)
    .map(
      (e) =>
        `- tick ${e.tick} | ${e.actorId} | ${e.action.type} (${e.action.ef ?? "direct"}) ` +
        `→ status ${e.status}${e.error ? ` (${e.error})` : ""}`,
    )
    .join("\n");

  const violationLines = violations
    .map((v) => `- **${v.invariant}**: ${JSON.stringify(v.details)}`)
    .join("\n");

  const axiomDataset = Deno.env.get("AXIOM_DATASET") ?? "edge-functions";
  const fullTraceJson = JSON.stringify(trace, null, 2);
  const encoder = new TextEncoder();
  let truncatedTrace = fullTraceJson;
  const traceBytes = encoder.encode(fullTraceJson);
  if (traceBytes.length > MAX_ISSUE_BODY_BYTES) {
    let safeEnd = MAX_ISSUE_BODY_BYTES;
    while (safeEnd > 0 && (traceBytes[safeEnd] & 0xc0) === 0x80) safeEnd--;
    truncatedTrace = new TextDecoder().decode(traceBytes.slice(0, safeEnd)) + "\n...[truncated]";
  }

  const body = `## Stochastic Cascade Failure Report

**Run ID**: \`${runId}\`
**Trace**: ${summary.ok}/${summary.total} actions ok, ${summary.failed} failed
**Invariant violations**: ${violations.length}
**Environment**: ${Deno.env.get("ENVIRONMENT") ?? "unknown"}

## Failed Actions
${failedTraceLines || "_none_"}

## Invariant Violations
${violationLines || "_none_"}

## Axiom 디버깅
\`\`\`
axiom query "['${axiomDataset}'] | where metadata.runId == '${runId}'"
\`\`\`

<details>
<summary>📋 Full Trace (truncated to 60KB)</summary>

\`\`\`json
${truncatedTrace}
\`\`\`

</details>`;

  try {
    const response = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/issues`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${githubToken}`,
          "Content-Type": "application/json",
          "User-Agent": "Minglit-Cascade-Reporter",
        },
        body: JSON.stringify({
          title,
          body,
          labels: ["e2e-simulation", "automated"],
        }),
      },
    );

    if (!response.ok) {
      console.error("[reporter] GitHub API error:", await response.text());
      return null;
    }

    const data = await response.json();
    return (data as { html_url?: string }).html_url ?? null;
  } catch (err) {
    console.error("[reporter] reportFailure exception:", err);
    return null;
  }
}
