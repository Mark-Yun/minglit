#!/usr/bin/env python3
"""Validate dev-staging-dev-cut and shared-notify workflow contracts."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[2]
DEV_STAGING_DEV_CUT = ROOT / ".github/workflows/dev-staging-dev-cut.yml"
SHARED_NOTIFY = ROOT / ".github/workflows/shared-notify.yml"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_workflow(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file)
    if not isinstance(data, dict):
        fail(f"{path} did not parse as a mapping")
    return data


def jobs_config(workflow: dict[str, Any], path: Path) -> dict[str, Any]:
    jobs = workflow.get("jobs", {})
    if not isinstance(jobs, dict):
        fail(f"{path} jobs block did not parse as a mapping")
    return jobs


def assert_dev_staging_dev_cut_contract() -> None:
    workflow = load_workflow(DEV_STAGING_DEV_CUT)
    jobs = jobs_config(workflow, DEV_STAGING_DEV_CUT)
    create_dev_cut_pr = jobs.get("create-dev-cut-pr", {})
    if not isinstance(create_dev_cut_pr, dict):
        fail("dev-staging-dev-cut must define create-dev-cut-pr job")

    steps = create_dev_cut_pr.get("steps", [])
    if not isinstance(steps, list):
        fail("dev-staging-dev-cut create-dev-cut-pr steps did not parse as a list")
    if not steps:
        fail("dev-staging-dev-cut create-dev-cut-pr must have steps")

    checkout = steps[0]
    if not isinstance(checkout, dict):
        fail("dev-staging-dev-cut first step must be a mapping")
    if checkout.get("uses") != "actions/checkout@v6":
        fail("dev-staging-dev-cut first step must use actions/checkout@v6")

    with_config = checkout.get("with", {})
    if not isinstance(with_config, dict):
        fail("dev-staging-dev-cut checkout with block did not parse as a mapping")
    if str(with_config.get("fetch-depth")) != "0":
        fail("dev-staging-dev-cut checkout fetch-depth must be 0")


def assert_shared_notify_contract() -> None:
    text = SHARED_NOTIFY.read_text(encoding="utf-8")
    expected = 'gh run view "${GITHUB_RUN_ID}" --repo "${GITHUB_REPOSITORY}" --log-failed'
    if expected not in text:
        fail("shared-notify must call gh run view with explicit --repo context")


def main() -> None:
    assert_dev_staging_dev_cut_contract()
    assert_shared_notify_contract()
    print("Dev cut workflow contract OK")


if __name__ == "__main__":
    main()
