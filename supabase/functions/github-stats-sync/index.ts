// github-stats-sync — Fetch GitHub issue/PR stats and store in analytics.github_daily_stats
// Triggered daily via pg_cron

import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
// Fix #1121: requireServiceRole로 통일 (auth_utils 마이그레이션) → now handled by minglitEdgeFunction wrapper
import { log } from "../_shared/logger.ts";

const REPO = "Mark-Yun/minglit";
const GITHUB_API = "https://api.github.com";

interface GitHubItem {
  created_at: string;
  closed_at: string | null;
  merged_at?: string | null;
  state: string;
  pull_request?: { merged_at: string | null };
}

export const handler = async (req: Request, { supabase }: EFContext): Promise<Response> => {
  if (req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const githubToken = Deno.env.get("GITHUB_ACCESS_TOKEN");

  const headers: Record<string, string> = {
    Accept: "application/vnd.github.v3+json",
    "User-Agent": "minglit-stats-sync",
  };
  if (githubToken) {
    headers.Authorization = `Bearer ${githubToken}`;
  }

  // Fetch all issues (includes PRs) from last 90 days
  const since = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
  const items: GitHubItem[] = [];
  let page = 1;

  while (page <= 10) {
    const url = `${GITHUB_API}/repos/${REPO}/issues?state=all&since=${since}&per_page=100&page=${page}`;
    let data: GitHubItem[];
    try {
      const res = await fetch(url, { headers });
      if (!res.ok) {
        return errorResponse(`GitHub API error: ${res.status} ${res.statusText}`, 502);
      }
      data = (await res.json()) as GitHubItem[];
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return errorResponse(`GitHub API request failed: ${message}`, 502);
    }
    if (data.length === 0) break;
    items.push(...data);
    page++;
  }

  // Separate issues and PRs
  const issues = items.filter((i) => !i.pull_request);
  const prs = items.filter((i) => i.pull_request);

  // Aggregate by date
  const stats = new Map<string, Record<string, number>>();

  const ensure = (date: string) => {
    if (!stats.has(date)) {
      stats.set(date, {
        issues_opened: 0,
        issues_closed: 0,
        prs_opened: 0,
        prs_merged: 0,
      });
    }
    return stats.get(date)!;
  };

  for (const issue of issues) {
    const created = issue.created_at.slice(0, 10);
    ensure(created).issues_opened++;
    if (issue.closed_at) {
      const closed = issue.closed_at.slice(0, 10);
      ensure(closed).issues_closed++;
    }
  }

  for (const pr of prs) {
    const created = pr.created_at.slice(0, 10);
    ensure(created).prs_opened++;
    if (pr.pull_request?.merged_at) {
      const merged = pr.pull_request.merged_at.slice(0, 10);
      ensure(merged).prs_merged++;
    }
  }

  // Upsert into analytics.github_daily_stats
  const rows: { date: string; metric: string; count: number }[] = [];
  for (const [date, metrics] of stats) {
    for (const [metric, count] of Object.entries(metrics)) {
      rows.push({ date, metric, count });
    }
  }

  // Batch upsert via RPC (analytics schema not exposed via REST)
  for (const row of rows) {
    const { error } = await supabase.rpc("upsert_github_daily_stat", {
      p_date: row.date,
      p_metric: row.metric,
      p_count: row.count,
    });
    if (error) {
      log({ function: "github-stats-sync", level: "error", message: `Failed to upsert ${row.date}/${row.metric}`, metadata: { detail: error.message } });
    }
  }

  return successResponse({
    success: true,
    dates: stats.size,
    total_rows: rows.length,
    issues: issues.length,
    prs: prs.length,
  });
};

minglitEdgeFunction(handler);
