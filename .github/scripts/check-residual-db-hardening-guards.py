#!/usr/bin/env python3
"""Validate drift-tolerant guards in residual DB hardening migrations."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase/migrations/20260604003000_residual_db_hardening_execute_grants.sql"
LEGACY_TRIGGER_SIGNATURE = "public.handle_partner_application_approved()"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    text = MIGRATION.read_text(encoding="utf-8")

    if f"to_regprocedure('{LEGACY_TRIGGER_SIGNATURE}')" not in text:
        fail(f"{LEGACY_TRIGGER_SIGNATURE} hardening must be guarded with to_regprocedure")

    guard_pattern = re.compile(
        r"IF\s+to_regprocedure\('public\.handle_partner_application_approved\(\)'\)"
        r"\s+IS\s+NOT\s+NULL\s+THEN(?P<body>.*?)END\s+IF;",
        re.IGNORECASE | re.DOTALL,
    )
    match = guard_pattern.search(text)
    if match is None:
        fail(f"{LEGACY_TRIGGER_SIGNATURE} guard block is missing or malformed")

    body = match.group("body")
    required_fragments = [
        "REVOKE EXECUTE ON FUNCTION public.handle_partner_application_approved()",
        "GRANT EXECUTE ON FUNCTION public.handle_partner_application_approved()",
    ]
    for fragment in required_fragments:
        if fragment not in body:
            fail(f"{LEGACY_TRIGGER_SIGNATURE} guard block missing: {fragment}")

    unguarded = re.compile(
        r"(?<!EXECUTE ')(REVOKE|GRANT)\s+EXECUTE\s+ON\s+FUNCTION\s+"
        r"public\.handle_partner_application_approved\(\)",
        re.IGNORECASE,
    )
    if unguarded.search(text):
        fail(f"{LEGACY_TRIGGER_SIGNATURE} must not be referenced by unguarded GRANT/REVOKE")

    print("Residual DB hardening guard contract OK")


if __name__ == "__main__":
    main()
