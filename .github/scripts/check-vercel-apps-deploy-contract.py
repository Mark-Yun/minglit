#!/usr/bin/env python3
"""Validate Vercel web app deploy workflow contracts."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
DEPLOY_NEXTJS_ACTION = ROOT / ".github/actions/deploy-nextjs-app/action.yml"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_action(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)
    if not isinstance(data, dict):
        fail(f"{path} did not parse as a mapping")
    return data


def named_step(action: dict[str, Any], step_name: str) -> dict[str, Any]:
    runs = action.get("runs", {})
    if not isinstance(runs, dict):
        fail("deploy-nextjs action runs block did not parse as a mapping")
    steps = runs.get("steps", [])
    if not isinstance(steps, list):
        fail("deploy-nextjs action steps did not parse as a list")
    for step in steps:
        if isinstance(step, dict) and step.get("name") == step_name:
            return step
    fail(f"deploy-nextjs action missing step: {step_name}")


def assert_nextjs_deploy_runs_from_repo_root() -> None:
    action = load_action(DEPLOY_NEXTJS_ACTION)
    deploy = named_step(action, "Deploy to Vercel")

    if "working-directory" in deploy:
        fail("Deploy to Vercel must run from the repository root, not the app subdirectory")

    env = deploy.get("env", {})
    if not isinstance(env, dict) or env.get("APP_DIR") != "${{ inputs.working-directory }}":
        fail("Deploy to Vercel must pass inputs.working-directory through APP_DIR")

    run = deploy.get("run", "")
    if not isinstance(run, str):
        fail("Deploy to Vercel run block did not parse as text")

    required_fragments = [
        'APP_DIR="${APP_DIR#./}"',
        '[[ ! -f "$APP_DIR/package.json" ]]',
        'WORKSPACE_NAME="$(node -e',
        'npm ci --workspace "$WORKSPACE_NAME" --include-workspace-root',
        'npm install --workspace "$WORKSPACE_NAME" --include-workspace-root',
        'npx --yes vercel@latest build --token=$VERCEL_TOKEN --yes',
        'npx --yes vercel@latest deploy --prebuilt --archive=tgz --token=$VERCEL_TOKEN --yes',
    ]
    for fragment in required_fragments:
        if fragment not in run:
            fail(f"deploy-nextjs action run block missing fragment: {fragment}")

    forbidden_fragments = [
        "cd $APP_DIR",
        "cd \"$APP_DIR\"",
        "--cwd",
    ]
    for fragment in forbidden_fragments:
        if fragment in run:
            fail(f"deploy-nextjs action must not invoke Vercel from the app subdirectory: {fragment}")


def main() -> None:
    assert_nextjs_deploy_runs_from_repo_root()
    print("Vercel apps deploy contract OK")


if __name__ == "__main__":
    main()
