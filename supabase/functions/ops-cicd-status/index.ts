import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";

const DEFAULT_REPO = "Mark-Yun/minglit";
const GITHUB_API = "https://api.github.com";
const ACTIVE_RC_BRANCH_PATTERN = /^rc\/[0-9]{4}-W[0-9]{2}$/;

type DashboardState = "success" | "warning" | "failure" | "running" | "unknown";

interface WorkflowDefinition {
  key: string;
  file: string;
  branch: "dev-staging" | "dev" | "rc" | "main";
  lane: "pr-gate" | "health" | "cut-gate" | "cut" | "deploy";
  label: string;
}

interface WorkflowRun {
  id: number;
  name: string | null;
  html_url: string;
  status: string | null;
  conclusion: string | null;
  head_branch: string | null;
  head_sha: string;
  event: string;
  created_at: string;
  updated_at: string;
}

interface GitHubWorkflow {
  id: number;
  name: string;
  path: string;
  state: string;
}

interface GitHubBranch {
  name: string;
  commit: { sha: string; url: string };
  protected?: boolean;
}

interface GitHubStatus {
  state: string;
  statuses: Array<{
    context: string;
    state: string;
    description: string | null;
    target_url: string | null;
    updated_at: string;
  }>;
}

interface GitHubIssue {
  number: number;
  title: string;
  state: string;
  html_url: string;
  labels: Array<{ name: string } | string>;
  updated_at: string;
}

interface GitHubClient {
  get<T>(
    path: string,
    params?: Record<string, string | number | undefined>,
  ): Promise<T>;
}

interface WorkflowSnapshot {
  key: string;
  file: string;
  lane: WorkflowDefinition["lane"];
  label: string;
  state: DashboardState;
  status: string | null;
  conclusion: string | null;
  run_id: number | null;
  run_url: string | null;
  updated_at: string | null;
}

interface BranchSnapshot {
  key: WorkflowDefinition["branch"];
  branch_name: string | null;
  head_sha: string | null;
  state: DashboardState;
  workflows: WorkflowSnapshot[];
  commit_statuses: Array<{
    context: string;
    state: string;
    description: string | null;
    target_url: string | null;
    updated_at: string;
  }>;
}

const WORKFLOWS: WorkflowDefinition[] = [
  {
    key: "dev-staging-pr-gate",
    file: "dev-staging-pr-gate.yml",
    branch: "dev-staging",
    lane: "pr-gate",
    label: "dev-staging PR Gate",
  },
  {
    key: "monitor-dev-staging-health",
    file: "monitor-dev-staging-health.yml",
    branch: "dev-staging",
    lane: "health",
    label: "Dev Staging Health",
  },
  {
    key: "dev-staging-dev-cut-gate",
    file: "dev-staging-dev-cut-gate.yml",
    branch: "dev-staging",
    lane: "cut-gate",
    label: "dev-staging → dev Gate",
  },
  {
    key: "dev-staging-dev-cut",
    file: "dev-staging-dev-cut.yml",
    branch: "dev-staging",
    lane: "cut",
    label: "dev-staging → dev Cut",
  },
  {
    key: "dev-pr-gate",
    file: "dev-pr-gate.yml",
    branch: "dev",
    lane: "pr-gate",
    label: "dev PR Gate",
  },
  {
    key: "dev-deploy",
    file: "dev-deploy.yml",
    branch: "dev",
    lane: "deploy",
    label: "dev Deploy",
  },
  {
    key: "dev-rc-cut-gate",
    file: "dev-rc-cut-gate.yml",
    branch: "dev",
    lane: "cut-gate",
    label: "dev → rc Gate",
  },
  {
    key: "dev-rc-cut",
    file: "dev-rc-cut.yml",
    branch: "dev",
    lane: "cut",
    label: "dev → rc Cut",
  },
  {
    key: "rc-pr-gate",
    file: "rc-pr-gate.yml",
    branch: "rc",
    lane: "pr-gate",
    label: "rc PR Gate",
  },
  {
    key: "rc-deploy",
    file: "rc-deploy.yml",
    branch: "rc",
    lane: "deploy",
    label: "rc Deploy",
  },
  {
    key: "rc-main-cut-gate",
    file: "rc-main-cut-gate.yml",
    branch: "rc",
    lane: "cut-gate",
    label: "rc → main Gate",
  },
  {
    key: "rc-main-cut",
    file: "rc-main-cut.yml",
    branch: "rc",
    lane: "cut",
    label: "rc → main Cut",
  },
  {
    key: "main-pr-gate",
    file: "main-pr-gate.yml",
    branch: "main",
    lane: "pr-gate",
    label: "main PR Gate",
  },
  {
    key: "main-deploy",
    file: "main-deploy.yml",
    branch: "main",
    lane: "deploy",
    label: "main Deploy",
  },
];

export function createGitHubClient(
  fetchFn: typeof fetch = fetch,
): GitHubClient {
  const token = Deno.env.get("GITHUB_ACCESS_TOKEN");
  if (!token) {
    throw new Error("GITHUB_ACCESS_TOKEN is not set");
  }

  const repository = Deno.env.get("GITHUB_REPOSITORY") ?? DEFAULT_REPO;
  const headers = {
    Accept: "application/vnd.github+json",
    Authorization: `Bearer ${token}`,
    "User-Agent": "minglit-ops-cicd-status",
    "X-GitHub-Api-Version": "2022-11-28",
  };

  return {
    async get<T>(
      path: string,
      params: Record<string, string | number | undefined> = {},
    ) {
      const url = new URL(`${GITHUB_API}/repos/${repository}${path}`);
      for (const [key, value] of Object.entries(params)) {
        if (value !== undefined) url.searchParams.set(key, String(value));
      }
      const response = await fetchFn(url, { headers });
      if (!response.ok) {
        throw new Error(
          `GitHub API ${path} failed: ${response.status} ${response.statusText}`,
        );
      }
      return await response.json() as T;
    },
  };
}

async function requireSuperAdmin(ctx: EFContext): Promise<Response | null> {
  if (ctx.auth.type !== "user") return errorResponse("Unauthorized", 401);

  const { data, error } = await ctx.supabase
    .from("app_roles")
    .select("role")
    .eq("user_id", ctx.auth.userId)
    .eq("role", "super_admin")
    .maybeSingle();

  if (error) {
    return errorResponse("Failed to verify admin role", 500, error.message);
  }
  if (!data) return errorResponse("Forbidden", 403);
  return null;
}

async function getBranch(
  client: GitHubClient,
  branch: WorkflowDefinition["branch"],
): Promise<GitHubBranch | null> {
  if (branch !== "rc") {
    try {
      return await client.get<GitHubBranch>(
        `/branches/${encodeURIComponent(branch)}`,
      );
    } catch {
      return null;
    }
  }

  const branches: GitHubBranch[] = [];
  for (let page = 1; page <= 10; page += 1) {
    const items = await client.get<GitHubBranch[]>("/branches", {
      per_page: 100,
      page,
    });
    branches.push(...items);
    if (items.length < 100) break;
  }

  return branches
    .filter((item) => ACTIVE_RC_BRANCH_PATTERN.test(item.name))
    .sort((a, b) => b.name.localeCompare(a.name))[0] ?? null;
}

function workflowFileName(path: string): string {
  return path.split("/").pop() ?? path;
}

function normalizeRunState(run: WorkflowRun | null): DashboardState {
  if (!run) return "unknown";
  if (run.status !== "completed") return "running";
  if (run.conclusion === "success") return "success";
  if (run.conclusion === "skipped" || run.conclusion === "neutral") {
    return "warning";
  }
  return "failure";
}

function normalizeCommitStatusState(state: string): DashboardState {
  if (state === "success") return "success";
  if (state === "pending") return "running";
  if (state === "error" || state === "failure") return "failure";
  return "unknown";
}

function aggregate(states: DashboardState[]): DashboardState {
  if (states.includes("failure")) return "failure";
  if (states.includes("running")) return "running";
  if (states.includes("warning")) return "warning";
  if (states.includes("unknown")) return "unknown";
  return "success";
}

async function buildWorkflowSnapshot(
  client: GitHubClient,
  def: WorkflowDefinition,
  workflowByFile: Map<string, GitHubWorkflow>,
  branchName: string | null,
): Promise<WorkflowSnapshot> {
  const workflow = workflowByFile.get(def.file);
  let latest: WorkflowRun | null = null;
  if (workflow && branchName) {
    const runs = await client.get<{ workflow_runs: WorkflowRun[] }>(
      `/actions/workflows/${workflow.id}/runs`,
      { branch: branchName, per_page: 1 },
    );
    latest = runs.workflow_runs[0] ?? null;
  }

  return {
    key: def.key,
    file: def.file,
    lane: def.lane,
    label: def.label,
    state: normalizeRunState(latest),
    status: latest?.status ?? (workflow ? null : "missing_workflow"),
    conclusion: latest?.conclusion ?? null,
    run_id: latest?.id ?? null,
    run_url: latest?.html_url ?? null,
    updated_at: latest?.updated_at ?? null,
  };
}

export async function buildDashboardSnapshot(client: GitHubClient) {
  const repository = Deno.env.get("GITHUB_REPOSITORY") ?? DEFAULT_REPO;
  const workflows = await client.get<{ workflows: GitHubWorkflow[] }>(
    "/actions/workflows",
    {
      per_page: 100,
    },
  );
  const workflowByFile = new Map(
    workflows.workflows.map((
      workflow,
    ) => [workflowFileName(workflow.path), workflow]),
  );

  const branchKeys = ["dev-staging", "dev", "rc", "main"] as const;
  const branches: BranchSnapshot[] = [];

  for (const key of branchKeys) {
    const branch = await getBranch(client, key);
    const defs = WORKFLOWS.filter((workflow) => workflow.branch === key);
    const snapshots = await Promise.all(
      defs.map((def) =>
        buildWorkflowSnapshot(client, def, workflowByFile, branch?.name ?? null)
      ),
    );

    let statuses: GitHubStatus["statuses"] = [];
    if (branch) {
      const status = await client.get<GitHubStatus>(
        `/commits/${branch.commit.sha}/status`,
      );
      statuses = status.statuses.filter((item) =>
        item.context.startsWith(`${key}-`) ||
        item.context.startsWith("dev-staging-health/") ||
        item.context.startsWith("dev-soak/") ||
        item.context.startsWith("rc-soak/")
      );
    }

    branches.push({
      key,
      branch_name: branch?.name ?? null,
      head_sha: branch?.commit.sha ?? null,
      state: aggregate([
        ...snapshots.map((item) => item.state),
        ...statuses.map((item) => normalizeCommitStatusState(item.state)),
      ]),
      workflows: snapshots,
      commit_statuses: statuses,
    });
  }

  const issues = await client.get<GitHubIssue[]>("/issues", {
    state: "open",
    labels: "ci-failure",
    per_page: 25,
  });

  return {
    success: true,
    generated_at: new Date().toISOString(),
    repository,
    branches,
    issues: issues.map((issue) => ({
      number: issue.number,
      title: issue.title,
      state: issue.state,
      url: issue.html_url,
      labels: issue.labels.map((label) =>
        typeof label === "string" ? label : label.name
      ),
      updated_at: issue.updated_at,
    })),
  };
}

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "GET" && req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const forbidden = await requireSuperAdmin(ctx);
  if (forbidden) return forbidden;

  try {
    return successResponse(await buildDashboardSnapshot(createGitHubClient()));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = message.includes("GITHUB_ACCESS_TOKEN") ? 500 : 502;
    return errorResponse(message, status);
  }
};

minglitEdgeFunction(handler);
