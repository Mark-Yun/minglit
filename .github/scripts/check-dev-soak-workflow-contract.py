#!/usr/bin/env python3
"""Validate dev health monitor and RC cut gate workflow contracts."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
MONITOR_DISTRIBUTED = ROOT / ".github/workflows/monitor-event-flow-distributed.yml"
MONITOR_DEV_STAGING_HEALTH = ROOT / ".github/workflows/monitor-dev-staging-health.yml"
MONITOR_DEV_CUJ = ROOT / ".github/workflows/monitor-dev-cuj.yml"
DEPLOY_DEV_EVENT_FLOW_CRON = ROOT / ".github/workflows/deploy-dev-event-flow-cron.yml"
SET_DEV_SOAK_STATUS = ROOT / ".github/workflows/set-dev-soak-status.yml"
DEV_RC_CUT_GATE = ROOT / ".github/workflows/dev-rc-cut-gate.yml"
SHARED_SOAK_GATE = ROOT / ".github/workflows/shared-soak-gate.yml"
PR_GATE = ROOT / ".github/workflows/pr-gate.yml"
DEV_PR_GATE = ROOT / ".github/workflows/dev-pr-gate.yml"
RC_PR_GATE = ROOT / ".github/workflows/rc-pr-gate.yml"
MAIN_PR_GATE = ROOT / ".github/workflows/main-pr-gate.yml"
RUN_USER_CUJ = ROOT / ".github/scripts/run-user-cuj.sh"
RUN_PARTNER_CUJ = ROOT / ".github/scripts/run-partner-cuj.sh"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_workflow(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)
    if not isinstance(data, dict):
        fail(f"{path} did not parse as a mapping")
    return data


def on_config(workflow: dict[str, Any]) -> dict[str, Any]:
    # PyYAML 1.1 treats the plain scalar key "on" as boolean True.
    config = workflow.get("on", workflow.get(True, {}))
    if not isinstance(config, dict):
        fail("workflow 'on' block did not parse as a mapping")
    return config


def jobs_config(workflow: dict[str, Any], path: Path) -> dict[str, Any]:
    jobs = workflow.get("jobs", {})
    if not isinstance(jobs, dict):
        fail(f"{path} jobs block did not parse as a mapping")
    return jobs


def run_block(job: dict[str, Any], step_name: str) -> str:
    steps = job.get("steps", [])
    if not isinstance(steps, list):
        fail(f"{step_name} job steps did not parse as a list")
    for step in steps:
        if isinstance(step, dict) and step.get("name") == step_name:
            script = step.get("run", "")
            if not isinstance(script, str):
                fail(f"{step_name} run block did not parse as text")
            return script
    fail(f"missing step: {step_name}")


def assert_distributed_monitor_contract() -> None:
    workflow = load_workflow(MONITOR_DISTRIBUTED)
    config = on_config(workflow)

    if "schedule" in config:
        fail("monitor-event-flow-distributed must not use GitHub schedule")

    dispatch = config.get("workflow_dispatch", {})
    inputs = dispatch.get("inputs", {}) if isinstance(dispatch, dict) else {}
    if "target_ref" in inputs:
        fail("monitor-event-flow-distributed must not expose target_ref while rc cron is disabled")

    jobs = jobs_config(workflow, MONITOR_DISTRIBUTED)
    resolve_target = jobs.get("resolve-target", {})
    if not isinstance(resolve_target, dict):
        fail("monitor-event-flow-distributed must define resolve-target job")
    script = run_block(resolve_target, "Resolve dev ref")
    if 'GITHUB_REF' not in script or 'refs/heads/dev' not in script:
        fail("manual distributed monitor must require --ref dev")


def assert_dev_cron_deploy_contract() -> None:
    workflow = load_workflow(DEPLOY_DEV_EVENT_FLOW_CRON)
    config = on_config(workflow)
    push = config.get("push", {})
    branches = push.get("branches", []) if isinstance(push, dict) else []
    if branches != ["dev"]:
        fail("deploy-dev-event-flow-cron must run only on push to dev")

    jobs = jobs_config(workflow, DEPLOY_DEV_EVENT_FLOW_CRON)
    install = jobs.get("install", {})
    if not isinstance(install, dict):
        fail("deploy-dev-event-flow-cron must define install job")
    if install.get("if") != "github.ref == 'refs/heads/dev'":
        fail("deploy-dev-event-flow-cron install job must guard github.ref == refs/heads/dev")

    wait_script = run_block(install, "Wait for deploy-supabase on dev SHA")
    required_wait_fragments = [
        'wait_for_deploy="false"',
        "changed_files=",
        "grep -Eq",
        '<<< "${changed_files}"',
        "supabase/(migrations|functions)",
        "Skipping deploy-supabase wait.",
    ]
    for fragment in required_wait_fragments:
        if fragment not in wait_script:
            fail(f"deploy-dev-event-flow-cron wait step missing fragment: {fragment}")

    smoke_script = run_block(install, "Verify event-flow simulator tick")
    required_smoke_fragments = [
        "event-flow-simulator",
        "targetRef: \"dev\"",
        "targetSha: env.TARGET_SHA",
        "jq -e '.success == true'",
    ]
    for fragment in required_smoke_fragments:
        if fragment not in smoke_script:
            fail(f"deploy-dev-event-flow-cron smoke step missing fragment: {fragment}")

    script_path = ROOT / ".github/scripts/install-dev-event-flow-cron.sh"
    script = script_path.read_text(encoding="utf-8")
    required_fragments = [
        "dev-event-flow-simulator",
        "*/5 * * * *",
        "GITHUB_ACCESS_TOKEN is required for event-flow-simulator failure reporting",
        "'targetRef', 'dev'",
        "'targetSha', '${target_sha_esc}'",
        "public.ef_auth_manifest",
    ]
    for fragment in required_fragments:
        if fragment not in script:
            fail(f"install-dev-event-flow-cron.sh missing contract fragment: {fragment}")


def assert_set_dev_soak_status_contract() -> None:
    workflow = load_workflow(SET_DEV_SOAK_STATUS)
    config = on_config(workflow)
    dispatch = config.get("workflow_dispatch", {})
    inputs = dispatch.get("inputs", {}) if isinstance(dispatch, dict) else {}
    signal = inputs.get("signal", {}) if isinstance(inputs, dict) else {}
    options = signal.get("options", []) if isinstance(signal, dict) else []
    required_signals = [
        "backend-simulator",
        "cuj-user",
        "cuj-partner",
        "real-device",
        "app-ai-review",
    ]
    for item in required_signals:
        if item not in options:
            fail(f"set-dev-soak-status workflow_dispatch signal options missing {item}")

    jobs = jobs_config(workflow, SET_DEV_SOAK_STATUS)
    mapper = jobs.get("map-dev-soak-status", {})
    if not isinstance(mapper, dict):
        fail("set-dev-soak-status must define map-dev-soak-status job")
    script = run_block(mapper, "Map dev soak signal to status context")
    required_fragments = [
        "backend-simulator) CONTEXT=\"dev-soak/backend-simulator\"",
        "cuj-user) CONTEXT=\"dev-soak/cuj-user\"",
        "cuj-partner) CONTEXT=\"dev-soak/cuj-partner\"",
        "real-device) CONTEXT=\"dev-soak/real-device\"",
        "app-ai-review) CONTEXT=\"dev-soak/app-ai-review\"",
    ]
    for fragment in required_fragments:
        if fragment not in script:
            fail(f"set-dev-soak-status mapping missing fragment: {fragment}")


def assert_dev_staging_health_contract() -> None:
    workflow = load_workflow(MONITOR_DEV_STAGING_HEALTH)
    jobs = jobs_config(workflow, MONITOR_DEV_STAGING_HEALTH)
    forbidden_jobs = {
        "cuj-user",
        "cuj-partner",
        "status-cuj-user",
        "status-cuj-partner",
    }
    for job in forbidden_jobs:
        if job in jobs:
            fail(f"monitor-dev-staging-health must not define {job}; CUJ belongs to monitor-dev-cuj")
    text = MONITOR_DEV_STAGING_HEALTH.read_text(encoding="utf-8")
    if "dev-staging-health/cuj-" in text or "shared-cuj-integration.yml" in text:
        fail("monitor-dev-staging-health must not run or write CUJ health statuses")


def assert_monitor_dev_cuj_contract() -> None:
    workflow = load_workflow(MONITOR_DEV_CUJ)
    config = on_config(workflow)
    push = config.get("push", {})
    branches = push.get("branches", []) if isinstance(push, dict) else []
    if branches != ["dev"]:
        fail("monitor-dev-cuj must run only on push to dev")

    jobs = jobs_config(workflow, MONITOR_DEV_CUJ)
    plan = jobs.get("plan", {})
    if not isinstance(plan, dict):
        fail("monitor-dev-cuj must define plan job")
    plan_script = run_block(plan, "Resolve dev CUJ candidate")
    required_plan_fragments = [
        "git fetch origin dev",
        "EVENT_NAME",
        "PUSH_SHA",
        "INPUT_CANDIDATE_SHA",
        "candidate_sha must be a full 40-character commit SHA",
        "git merge-base --is-ancestor",
        "candidate_sha must be reachable from origin/dev",
    ]
    for fragment in required_plan_fragments:
        if fragment not in plan_script:
            fail(f"monitor-dev-cuj plan step missing fragment: {fragment}")

    expected_cuj_jobs = {
        "cuj-user": ("user", "cuj-user", "status-cuj-user", "notify-cuj-user-failure"),
        "cuj-partner": ("partner", "cuj-partner", "status-cuj-partner", "notify-cuj-partner-failure"),
    }
    for job_name, (app_name, signal, status_job, notify_job) in expected_cuj_jobs.items():
        job = jobs.get(job_name, {})
        if not isinstance(job, dict) or job.get("uses") != "./.github/workflows/shared-cuj-integration.yml":
            fail(f"monitor-dev-cuj {job_name} must call shared-cuj-integration")
        with_config = job.get("with", {})
        if not isinstance(with_config, dict) or with_config.get("app-name") != app_name:
            fail(f"monitor-dev-cuj {job_name} must use app-name={app_name}")

        status = jobs.get(status_job, {})
        if not isinstance(status, dict) or status.get("uses") != "./.github/workflows/set-dev-soak-status.yml":
            fail(f"monitor-dev-cuj {status_job} must call set-dev-soak-status")
        status_with = status.get("with", {})
        if not isinstance(status_with, dict) or status_with.get("signal") != signal:
            fail(f"monitor-dev-cuj {status_job} must write signal={signal}")

        notify = jobs.get(notify_job, {})
        if not isinstance(notify, dict) or notify.get("uses") != "./.github/workflows/shared-notify.yml":
            fail(f"monitor-dev-cuj {notify_job} must call shared-notify")
        notify_with = notify.get("with", {})
        if not isinstance(notify_with, dict):
            fail(f"monitor-dev-cuj {notify_job} with block did not parse as a mapping")
        if notify_with.get("stage") != "dev-soak" or notify_with.get("signal") != signal:
            fail(f"monitor-dev-cuj {notify_job} must notify stage=dev-soak signal={signal}")
        if "blocks_rc_cut" not in notify_with:
            fail(f"monitor-dev-cuj {notify_job} must set blocks_rc_cut")


def assert_cuj_runner_contract() -> None:
    for path in [RUN_USER_CUJ, RUN_PARTNER_CUJ]:
        script = path.read_text(encoding="utf-8")
        required_fragments = [
            "DART_DEFINE_FILE=\"${MINGLIT_CUJ_DART_DEFINE_FILE:-",
            "failed=0",
            "failures=()",
            "if ! flutter test",
            "failures+=(\"$f\")",
            "printf ' - %s\\n' \"${failures[@]}\"",
        ]
        for fragment in required_fragments:
            if fragment not in script:
                fail(f"{path.name} must aggregate CUJ failures; missing fragment: {fragment}")


def assert_dev_rc_cut_gate_contract() -> None:
    workflow = load_workflow(DEV_RC_CUT_GATE)
    jobs = jobs_config(workflow, DEV_RC_CUT_GATE)
    evaluate = jobs.get("evaluate-dev-soak", {})
    if not isinstance(evaluate, dict):
        fail("dev-rc-cut-gate must define evaluate-dev-soak job")
    if evaluate.get("uses") != "./.github/workflows/shared-soak-gate.yml":
        fail("dev-rc-cut-gate evaluate-dev-soak must call shared-soak-gate")

    with_config = evaluate.get("with", {})
    if not isinstance(with_config, dict):
        fail("evaluate-dev-soak with block did not parse as a mapping")
    if with_config.get("candidate_ref") != "dev":
        fail("dev-rc-cut-gate must evaluate origin/dev")
    min_soak_hours = str(with_config.get("min_soak_hours", ""))
    if "0" not in min_soak_hours or "24" in min_soak_hours:
        fail("dev-rc-cut-gate minimum dev soak must default to 0 hours")

    raw_required_runs = str(with_config.get("required_runs_json", "")).strip()
    try:
        required_runs = json.loads(raw_required_runs)
    except Exception as exc:  # noqa: BLE001 - contract failure should show parse detail.
        fail(f"dev-rc-cut-gate required_runs_json is invalid JSON: {exc}")
    if not isinstance(required_runs, list) or len(required_runs) != 2:
        fail("dev-rc-cut-gate must define deploy-dev-event-flow-cron and monitor-dev-cuj required run contracts")
    runs_by_workflow = {
        item.get("workflow"): item
        for item in required_runs
        if isinstance(item, dict)
    }

    expected_runs = {
        "deploy-dev-event-flow-cron.yml": {
            "branch": "dev",
            "min_success": 1,
            "match_head_sha": True,
        },
        "monitor-dev-cuj.yml": {
            "branch": "dev",
            "min_success": 1,
            "match_head_sha": True,
        },
    }
    for workflow_name, expected in expected_runs.items():
        run = runs_by_workflow.get(workflow_name)
        if not isinstance(run, dict):
            fail(f"dev-rc-cut-gate missing required run contract for {workflow_name}")
        for key, value in expected.items():
            if run.get(key) != value:
                fail(f"dev-rc-cut-gate {workflow_name} required run {key} must be {value!r}")
        if int(run.get("run_limit", 0)) < int(run["min_success"]):
            fail(f"dev-rc-cut-gate {workflow_name} run_limit must be >= min_success")

    failure_contexts = str(with_config.get("failure_contexts", ""))
    success_contexts = str(with_config.get("success_contexts", ""))
    required_contexts = [
        "dev-soak/backend-simulator",
        "dev-soak/cuj-user",
        "dev-soak/cuj-partner",
    ]
    for context in required_contexts:
        if context not in failure_contexts:
            fail(f"dev-rc-cut-gate failure_contexts missing {context}")
        if context not in success_contexts:
            fail(f"dev-rc-cut-gate success_contexts missing {context}")

    if with_config.get("pass_context") != "dev-rc-cut-pass":
        fail("dev-rc-cut-gate pass_context must be dev-rc-cut-pass")


def assert_pr_gate_cuj_contract() -> None:
    pr_gate = load_workflow(PR_GATE)
    config = on_config(pr_gate)
    workflow_call = config.get("workflow_call", {})
    inputs = workflow_call.get("inputs", {}) if isinstance(workflow_call, dict) else {}
    run_cuj = inputs.get("run_cuj_integration", {}) if isinstance(inputs, dict) else {}
    if not isinstance(run_cuj, dict) or run_cuj.get("default") is not False:
        fail("pr-gate run_cuj_integration must default to false")

    for path in [DEV_PR_GATE, RC_PR_GATE, MAIN_PR_GATE]:
        workflow = load_workflow(path)
        jobs = jobs_config(workflow, path)
        core = jobs.get("pr-gate-core", {})
        if not isinstance(core, dict):
            fail(f"{path.name} must define pr-gate-core")
        with_config = core.get("with", {})
        if not isinstance(with_config, dict) or with_config.get("run_cuj_integration") is not False:
            fail(f"{path.name} must pass run_cuj_integration=false")


def assert_shared_soak_gate_contract() -> None:
    workflow_text = SHARED_SOAK_GATE.read_text(encoding="utf-8")
    required_fragments = [
        "run_limit = int(item.get",
        "run_limit < min_success",
        '--created ">=${COMMIT_ISO}"',
        '--limit "${run_limit}"',
    ]
    for fragment in required_fragments:
        if fragment not in workflow_text:
            fail(f"shared-soak-gate missing contract fragment: {fragment}")


def main() -> None:
    assert_distributed_monitor_contract()
    assert_dev_cron_deploy_contract()
    assert_set_dev_soak_status_contract()
    assert_dev_staging_health_contract()
    assert_monitor_dev_cuj_contract()
    assert_cuj_runner_contract()
    assert_dev_rc_cut_gate_contract()
    assert_pr_gate_cuj_contract()
    assert_shared_soak_gate_contract()
    print("Dev health workflow contract OK")


if __name__ == "__main__":
    main()
