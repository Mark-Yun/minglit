#!/usr/bin/env python3
"""Validate dev soak monitor and RC cut gate workflow contracts."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
MONITOR_DISTRIBUTED = ROOT / ".github/workflows/monitor-event-flow-distributed.yml"
DEPLOY_DEV_EVENT_FLOW_CRON = ROOT / ".github/workflows/deploy-dev-event-flow-cron.yml"
DEV_RC_CUT_GATE = ROOT / ".github/workflows/dev-rc-cut-gate.yml"
SHARED_SOAK_GATE = ROOT / ".github/workflows/shared-soak-gate.yml"


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

    script_path = ROOT / ".github/scripts/install-dev-event-flow-cron.sh"
    script = script_path.read_text(encoding="utf-8")
    required_fragments = [
        "dev-event-flow-simulator",
        "*/5 * * * *",
        "'targetRef', 'dev'",
        "'targetSha', '${target_sha_esc}'",
        "public.ef_auth_manifest",
    ]
    for fragment in required_fragments:
        if fragment not in script:
            fail(f"install-dev-event-flow-cron.sh missing contract fragment: {fragment}")


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
    if "24" not in min_soak_hours:
        fail("dev-rc-cut-gate minimum soak must default to 24 hours")

    raw_required_runs = str(with_config.get("required_runs_json", "")).strip()
    try:
        required_runs = json.loads(raw_required_runs)
    except Exception as exc:  # noqa: BLE001 - contract failure should show parse detail.
        fail(f"dev-rc-cut-gate required_runs_json is invalid JSON: {exc}")
    if not isinstance(required_runs, list) or len(required_runs) != 1:
        fail("dev-rc-cut-gate must define exactly one required run contract")
    run = required_runs[0]
    if not isinstance(run, dict):
        fail("dev-rc-cut-gate required run contract must be an object")

    expected = {
        "workflow": "deploy-dev-event-flow-cron.yml",
        "branch": "dev",
        "min_success": 1,
        "match_head_sha": True,
    }
    for key, value in expected.items():
        if run.get(key) != value:
            fail(f"dev-rc-cut-gate required run {key} must be {value!r}")
    if int(run.get("run_limit", 0)) < int(run["min_success"]):
        fail("dev-rc-cut-gate run_limit must be >= min_success")


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
    assert_dev_rc_cut_gate_contract()
    assert_shared_soak_gate_contract()
    print("Dev soak workflow contract OK")


if __name__ == "__main__":
    main()
