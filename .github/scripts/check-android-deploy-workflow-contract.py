#!/usr/bin/env python3
"""Validate Android deploy release archive workflow contracts."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
SHARED_ANDROID_DEPLOY = ROOT / ".github/workflows/shared-android-deploy.yml"
CALLERS = [
    ROOT / ".github/workflows/deploy-android-user.yml",
    ROOT / ".github/workflows/deploy-android-partner.yml",
]
EXPECTED_TOKEN = "${{ steps.release-bot.outputs.token }}"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_workflow(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)
    if not isinstance(data, dict):
        fail(f"{path} did not parse as a mapping")
    return data


def workflow_call_config(workflow: dict[str, Any]) -> dict[str, Any]:
    # PyYAML 1.1 treats the plain scalar key "on" as boolean True.
    on_config = workflow.get("on", workflow.get(True, {}))
    if not isinstance(on_config, dict):
        fail("workflow 'on' block did not parse as a mapping")
    workflow_call = on_config.get("workflow_call", {})
    if not isinstance(workflow_call, dict):
        fail("workflow_call block did not parse as a mapping")
    return workflow_call


def assert_no_gh_pat_secret_contract(workflow: dict[str, Any], path: Path) -> None:
    workflow_call = workflow_call_config(workflow)
    secrets = workflow_call.get("secrets", {})
    if isinstance(secrets, dict) and "GH_PAT_VERSION_BUMP" in secrets:
        fail(f"{path} still declares GH_PAT_VERSION_BUMP as a workflow_call secret")


def assert_shared_android_deploy_contract() -> None:
    workflow = load_workflow(SHARED_ANDROID_DEPLOY)
    assert_no_gh_pat_secret_contract(workflow, SHARED_ANDROID_DEPLOY)

    jobs = workflow.get("jobs", {})
    build = jobs.get("build", {}) if isinstance(jobs, dict) else {}
    permissions = build.get("permissions", {}) if isinstance(build, dict) else {}
    if not isinstance(permissions, dict) or permissions.get("contents") != "write":
        fail("shared Android deploy build job must grant permissions.contents: write")

    steps = build.get("steps", []) if isinstance(build, dict) else []
    if not isinstance(steps, list):
        fail("shared Android deploy build steps did not parse as a list")

    publish_steps = {
        step.get("name"): step
        for step in steps
        if isinstance(step, dict)
        and step.get("name") in {"Publish APK/AAB to Releases (Dev)", "Publish AAB to Releases (Main)"}
    }
    for name in ("Publish APK/AAB to Releases (Dev)", "Publish AAB to Releases (Main)"):
        step = publish_steps.get(name)
        if step is None:
            fail(f"missing release archive step: {name}")

        env = step.get("env", {})
        if not isinstance(env, dict) or env.get("GH_TOKEN") != EXPECTED_TOKEN:
            fail(f"{name} must set GH_TOKEN to release-bot output token ({EXPECTED_TOKEN})")

        script = step.get("run", "")
        if not isinstance(script, str):
            fail(f"{name} run block did not parse as text")
        if "GH_PAT_VERSION_BUMP" in script:
            fail(f"{name} still references GH_PAT_VERSION_BUMP")
        for command in ("gh release view", "gh release create", "gh release delete"):
            if command not in script:
                fail(f"{name} must exercise `{command}` in the release archive path")


def assert_android_callers_do_not_pass_pat() -> None:
    for path in CALLERS:
        workflow = load_workflow(path)
        jobs = workflow.get("jobs", {})
        deploy = jobs.get("deploy", {}) if isinstance(jobs, dict) else {}
        secrets = deploy.get("secrets", {}) if isinstance(deploy, dict) else {}
        if isinstance(secrets, dict) and "GH_PAT_VERSION_BUMP" in secrets:
            fail(f"{path} still passes GH_PAT_VERSION_BUMP to shared-android-deploy")


def main() -> None:
    assert_shared_android_deploy_contract()
    assert_android_callers_do_not_pass_pat()
    print("Android deploy release archive workflow contract OK")


if __name__ == "__main__":
    main()
