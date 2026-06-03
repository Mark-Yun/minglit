#!/usr/bin/env python3
"""Validate Android deploy release archive workflow contracts."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
SHARED_ANDROID_DEPLOY = ROOT / ".github/workflows/shared-android-deploy.yml"
SHARED_VERSION_METADATA = ROOT / ".github/workflows/shared-version-metadata.yml"
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


def run_command(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=cwd,
        env=env,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def workflow_call_config(workflow: dict[str, Any]) -> dict[str, Any]:
    # PyYAML 1.1 treats the plain scalar key "on" as boolean True.
    on_config = workflow.get("on", workflow.get(True, {}))
    if not isinstance(on_config, dict):
        fail("workflow 'on' block did not parse as a mapping")
    workflow_call = on_config.get("workflow_call", {})
    if not isinstance(workflow_call, dict):
        fail("workflow_call block did not parse as a mapping")
    return workflow_call


def shared_version_metadata_script() -> str:
    workflow = load_workflow(SHARED_VERSION_METADATA)
    jobs = workflow.get("jobs", {})
    metadata = jobs.get("metadata", {}) if isinstance(jobs, dict) else {}
    steps = metadata.get("steps", []) if isinstance(metadata, dict) else []
    if not isinstance(steps, list):
        fail("shared-version-metadata steps did not parse as a list")

    for step in steps:
        if not isinstance(step, dict):
            continue
        if step.get("name") == "Compute version metadata":
            run = step.get("run", "")
            if isinstance(run, str):
                return run

    fail("shared-version-metadata is missing 'Compute version metadata' run script")


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


def assert_main_build_number_monotonic_contract() -> None:
    script = shared_version_metadata_script()

    required_snippets = [
        "if [ \"${CHANNEL}\" = \"main\" ]; then",
        "if [ \"${SNAPSHOT_BUILD_INT}\" -lt 100000 ]; then",
        "LEGACY_SEED=$((10#${YY} * 1000000 + 10#${MM} * 10000))",
        "BUILD_NUMBER=$((LEGACY_SEED + SNAPSHOT_BUILD_INT))",
        "BUILD_NUMBER_RULE=\"snapshot_build_number\"",
        "echo \"build_number=${BUILD_NUMBER}\"",
        "echo \"snapshot_build=${SNAPSHOT_BUILD}\"",
    ]
    for snippet in required_snippets:
        if snippet not in script:
            fail(
                "shared-version-metadata must preserve main monotonic build_number contract; "
                f"missing snippet: {snippet}"
            )


def assert_version_metadata_merge_parent_snapshot_contract() -> None:
    script = shared_version_metadata_script()

    with tempfile.TemporaryDirectory(prefix="minglit-version-metadata-") as tmp:
        repo = Path(tmp) / "repo"
        repo.mkdir()

        def git(*args: str) -> str:
            result = run_command(["git", *args], cwd=repo)
            return result.stdout.strip()

        git("init")
        git("config", "user.email", "ci@example.invalid")
        git("config", "user.name", "CI")
        git("checkout", "-b", "dev")

        (repo / "package.json").write_text('{"version":"26.06.03-dev-staging"}\n')
        git("add", "package.json")
        git("commit", "-m", "chore: initialize version metadata test")

        git("checkout", "-b", "cut/dev-staging-dev/test")
        (repo / "snapshot.txt").write_text("snapshot\n")
        git("add", "snapshot.txt")
        git("commit", "-m", "chore: bump version to v26.06.03+26060301-dev-staging")
        snapshot_sha = git("rev-parse", "HEAD")
        git("tag", "v26.06.03+26060301-dev-staging")

        git("checkout", "dev")
        (repo / "dev.txt").write_text("first-parent-only commit\n")
        git("add", "dev.txt")
        git("commit", "-m", "chore: dev first-parent commit without snapshot tag")
        git("merge", "--no-ff", "cut/dev-staging-dev/test", "-m", "Merge promotion snapshot")
        source_sha = git("rev-parse", "HEAD")
        git("remote", "add", "origin", str(repo))

        output_path = repo / "github-output.txt"
        summary_path = repo / "github-summary.md"
        env = os.environ.copy()
        env.update(
            {
                "CHANNEL": "dev",
                "SOURCE_REF": "HEAD",
                "GITHUB_OUTPUT": str(output_path),
                "GITHUB_STEP_SUMMARY": str(summary_path),
                "GITHUB_REPOSITORY": "local/minglit",
                "GH_TOKEN": "dummy-token",
            }
        )
        run_command(["bash", "-c", script], cwd=repo, env=env)

        outputs = dict(
            line.split("=", 1)
            for line in output_path.read_text(encoding="utf-8").splitlines()
            if "=" in line
        )
        if outputs.get("source_sha") != source_sha:
            fail("shared-version-metadata test did not inspect the merge commit source SHA")
        if outputs.get("snapshot_build") != "26060301":
            fail(
                "shared-version-metadata must find v*-dev-staging snapshot tags "
                "reachable through a promotion merge parent"
            )
        if outputs.get("build_number") != "26060301":
            fail("shared-version-metadata must use snapshot build as dev build_number")

        summary = summary_path.read_text(encoding="utf-8")
        if f"| revision_sha | {snapshot_sha} |" not in summary:
            fail("shared-version-metadata summary must report the snapshot revision SHA")


def main() -> None:
    assert_shared_android_deploy_contract()
    assert_android_callers_do_not_pass_pat()
    assert_main_build_number_monotonic_contract()
    assert_version_metadata_merge_parent_snapshot_contract()
    print("Android deploy release archive workflow contract OK")


if __name__ == "__main__":
    main()
