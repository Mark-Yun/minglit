// github-stats-sync — Fetch GitHub issue/PR stats and store in analytics.github_daily_stats
// Triggered daily via pg_cron

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";

const REPO = "Mark-Yun/minglit";
const GITHUB_API = "https://api.github.com";

interface GitHubItem {
  created_at: string;
  closed_at: string | null;
  merged_at?: string | null;
  state: string;
  pull_request?: { merged_at: string | null };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const githubToken = Deno.env.get("GITHUB_ACCESS_TOKEN");

  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY", 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const headers: Record<string, string> = {
    Accept: "application/vnd.github.v3+json",
    "User-Agent": "minglit-stats-sync",
  };
  if (githubToken) {
    headers.Authorization = `Bearer ${githubToken}`;
  }

  try {
    // Fetch all issues (includes PRs) from last 90 days
    const since = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
    const items: GitHubItem[] = [];
    let page = 1;

    while (page <= 10) {
      const url = `${GITHUB_API}/repos/${REPO}/issues?state=all&since=${since}&per_page=100&page=${page}`;
      const res = await fetch(url, { headers });
      if (!res.ok) {
        return errorResponse(`GitHub API error: ${res.status} ${res.statusText}`, 502);
      }
      const data = (await res.json()) as GitHubItem[];
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
    // Use raw SQL via supabase.rpc or direct insert
    for (const row of rows) {
      const { error } = await supabase.rpc("upsert_github_daily_stat", {
        p_date: row.date,
        p_metric: row.metric,
        p_count: row.count,
      });
      if (error) {
        console.error(`Failed to upsert ${row.date}/${row.metric}: ${error.message}`);
      }
    }

    return successResponse({
      success: true,
      dates: stats.size,
      total_rows: rows.length,
      issues: issues.length,
      prs: prs.length,
    });
  } catch (err) {
    return errorResponse(`Unexpected error: ${(err as Error).message}`, 500);
  }
});
