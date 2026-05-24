#!/usr/bin/env python3
"""Scan generated build artifacts for server-side Supabase secrets.

The script intentionally reports only rule ids and artifact locations. It never
prints the matched token, so CI logs stay useful without becoming a new leak.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Rule:
    rule_id: str
    description: str
    pattern: re.Pattern[bytes]


@dataclass(frozen=True)
class Finding:
    rule_id: str
    location: str


RULES: tuple[Rule, ...] = (
    Rule(
        "supabase-service-role-secret",
        "Supabase sb_secret service-role key",
        re.compile(rb"sb_secret_[A-Za-z0-9_-]+"),
    ),
    Rule(
        "supabase-legacy-jwt",
        "Supabase legacy JWT",
        re.compile(
            rb"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\."
            rb"[A-Za-z0-9_-]{60,}\.[A-Za-z0-9_-]{40,}"
        ),
    ),
)


def iter_files(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for path in paths:
        if not path.exists():
            raise FileNotFoundError(f"scan target does not exist: {path}")
        if path.is_file():
            files.append(path)
            continue
        for root, _, names in os.walk(path):
            for name in names:
                candidate = Path(root) / name
                if candidate.is_file() and not candidate.is_symlink():
                    files.append(candidate)
    return files


def scan_bytes(data: bytes, location: str) -> list[Finding]:
    findings: list[Finding] = []
    for rule in RULES:
        if rule.rule_id == "supabase-legacy-jwt":
            if any(is_service_role_jwt(match.group(0)) for match in rule.pattern.finditer(data)):
                findings.append(Finding(rule.rule_id, location))
            continue
        if rule.pattern.search(data):
            findings.append(Finding(rule.rule_id, location))
    return findings


def is_service_role_jwt(token: bytes) -> bool:
    parts = token.split(b".")
    if len(parts) != 3:
        return False
    try:
        payload = parts[1]
        padded = payload + b"=" * (-len(payload) % 4)
        decoded = base64.urlsafe_b64decode(padded)
        claims = json.loads(decoded.decode("utf-8"))
    except (ValueError, UnicodeDecodeError, json.JSONDecodeError):
        return False
    return isinstance(claims, dict) and claims.get("role") == "service_role"


def scan_file(path: Path) -> list[Finding]:
    if zipfile.is_zipfile(path):
        return scan_zip(path)
    try:
        return scan_bytes(path.read_bytes(), str(path))
    except OSError as exc:
        raise RuntimeError(f"failed to read {path}: {exc}") from exc


def scan_zip(path: Path) -> list[Finding]:
    findings: list[Finding] = []
    try:
        with zipfile.ZipFile(path) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                with archive.open(info) as member:
                    data = member.read()
                findings.extend(scan_bytes(data, f"{path}!{info.filename}"))
    except zipfile.BadZipFile as exc:
        raise RuntimeError(f"failed to inspect zip artifact {path}: {exc}") from exc
    return findings


def scan_paths(paths: list[Path]) -> list[Finding]:
    findings: list[Finding] = []
    for path in iter_files(paths):
        findings.extend(scan_file(path))
    return findings


def github_escape(value: str) -> str:
    return value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def report_findings(findings: list[Finding]) -> None:
    if not findings:
        print("Build artifact secret scan passed.")
        return

    print(f"Build artifact secret scan found {len(findings)} finding(s).")
    for finding in findings:
        location = github_escape(finding.location)
        rule_id = github_escape(finding.rule_id)
        print(
            "::error title=Build artifact secret detected::"
            f"{rule_id} matched in {location}; token redacted"
        )


def run_self_test() -> int:
    def fake_jwt(role: str) -> bytes:
        header = base64.urlsafe_b64encode(b'{"alg":"HS256","typ":"JWT"}').rstrip(b"=")
        claims = {"role": role, "iss": "supabase", "ref": "artifact-scan-self-test"}
        payload = base64.urlsafe_b64encode(json.dumps(claims).encode("utf-8")).rstrip(b"=")
        signature = b"B" * 40
        return b".".join([header, payload, signature])

    fake_secret = b"sb_" + b"secret_FAKE_ARTIFACT_SCAN_SHOULD_FAIL_1234567890"

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        plain = root / "plain.txt"
        plain.write_bytes(b"prefix " + fake_secret + b" suffix")

        archive = root / "app.apk"
        with zipfile.ZipFile(archive, "w") as zf:
            zf.writestr("assets/config.txt", b"jwt=" + fake_jwt("service_role"))

        clean = root / "clean.next"
        clean.mkdir()
        (clean / "chunk.js").write_bytes(b"public_jwt=" + fake_jwt("anon"))

        findings = scan_paths([plain, archive, clean])
        rule_ids = {finding.rule_id for finding in findings}
        if rule_ids != {"supabase-service-role-secret", "supabase-legacy-jwt"}:
            print(f"self-test failed: unexpected findings {findings}", file=sys.stderr)
            return 1

    print("Build artifact secret scan self-test passed.")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Scan build artifacts for Supabase service-role secrets."
    )
    parser.add_argument("paths", nargs="*", type=Path, help="Files or directories to scan.")
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the built-in fake secret fixture test.",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.self_test:
        return run_self_test()
    if not args.paths:
        print("at least one scan path is required", file=sys.stderr)
        return 2

    findings = scan_paths(args.paths)
    report_findings(findings)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
