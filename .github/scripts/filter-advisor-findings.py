#!/usr/bin/env python3
"""Split Supabase advisor findings into accepted and unsuppressed lists."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


DEFAULT_ENVS = ["dev", "main"]


def normalize_items(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        items = payload
    elif isinstance(payload, dict):
        items = payload.get("lints") or payload.get("data") or []
    else:
        items = []
    return [item for item in items if isinstance(item, dict)]


def finding_name(finding: dict[str, Any]) -> str:
    return str(finding.get("name") or finding.get("title") or finding.get("code") or "")


def finding_cache_key(finding: dict[str, Any]) -> str:
    return str(finding.get("cache_key") or finding.get("cacheKey") or "")


def metadata_value(finding: dict[str, Any], key: str) -> Any:
    metadata = finding.get("metadata")
    if isinstance(metadata, dict) and key in metadata:
        return metadata[key]
    return finding.get(key)


def metadata_matches(finding: dict[str, Any], expected: dict[str, Any]) -> bool:
    for key, expected_value in expected.items():
        if metadata_value(finding, key) != expected_value:
            return False
    return True


def rule_accepts_finding(
    rule: dict[str, Any],
    finding: dict[str, Any],
    *,
    advisor_type: str,
    env: str,
) -> bool:
    if rule.get("type") is not None and rule["type"] != advisor_type:
        return False
    rule_envs = rule.get("envs", DEFAULT_ENVS)
    if rule_envs is None:
        rule_envs = DEFAULT_ENVS
    if env not in rule_envs:
        return False
    if rule.get("name") != finding_name(finding):
        return False

    if "cache_key" in rule and rule["cache_key"] != finding_cache_key(finding):
        return False

    expected_metadata = rule.get("metadata")
    if expected_metadata is not None:
        if not isinstance(expected_metadata, dict):
            return False
        if not metadata_matches(finding, expected_metadata):
            return False

    return True


def split_findings(
    findings: list[dict[str, Any]],
    rules: list[dict[str, Any]],
    *,
    advisor_type: str,
    env: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    accepted: list[dict[str, Any]] = []
    unsuppressed: list[dict[str, Any]] = []

    for finding in findings:
        if any(
            rule_accepts_finding(rule, finding, advisor_type=advisor_type, env=env)
            for rule in rules
            if isinstance(rule, dict)
        ):
            accepted.append(finding)
        else:
            unsuppressed.append(finding)

    return accepted, unsuppressed


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8") as file:
        json.dump(payload, file, indent=2, sort_keys=True)
        file.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--accepted-file", required=True, type=Path)
    parser.add_argument("--type", required=True)
    parser.add_argument("--env", required=True)
    parser.add_argument("--accepted-output", required=True, type=Path)
    parser.add_argument("--unsuppressed-output", required=True, type=Path)
    args = parser.parse_args()

    findings = normalize_items(load_json(args.input, []))
    rules = load_json(args.accepted_file, [])
    accepted, unsuppressed = split_findings(
        findings,
        rules if isinstance(rules, list) else [],
        advisor_type=args.type,
        env=args.env,
    )

    write_json(args.accepted_output, accepted)
    write_json(args.unsuppressed_output, unsuppressed)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
