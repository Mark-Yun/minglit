#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import pathlib
import unittest


SCRIPT_PATH = pathlib.Path(__file__).with_name("filter-advisor-findings.py")
SPEC = importlib.util.spec_from_file_location("filter_advisor_findings", SCRIPT_PATH)
assert SPEC is not None
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class FilterAdvisorFindingsTest(unittest.TestCase):
    def split(self, findings, rules, *, advisor_type="security", env="dev"):
        return MODULE.split_findings(
            findings,
            rules,
            advisor_type=advisor_type,
            env=env,
        )

    def test_legacy_name_only_rule_still_suppresses_all_matching_findings(self):
        findings = [
            {"name": "auth_leaked_password_protection", "cache_key": "a"},
            {"name": "auth_leaked_password_protection", "cache_key": "b"},
            {"name": "extension_in_public", "cache_key": "c"},
        ]
        rules = [{"name": "auth_leaked_password_protection", "type": "security"}]

        accepted, unsuppressed = self.split(findings, rules)

        self.assertEqual([finding["cache_key"] for finding in accepted], ["a", "b"])
        self.assertEqual([finding["cache_key"] for finding in unsuppressed], ["c"])

    def test_cache_key_scoped_rule_only_suppresses_exact_object(self):
        findings = [
            {"name": "extension_in_public", "cache_key": "extensions_public_postgis"},
            {"name": "extension_in_public", "cache_key": "extensions_public_pgroonga"},
        ]
        rules = [
            {
                "name": "extension_in_public",
                "type": "security",
                "cache_key": "extensions_public_postgis",
            }
        ]

        accepted, unsuppressed = self.split(findings, rules)

        self.assertEqual(
            [finding["cache_key"] for finding in accepted],
            ["extensions_public_postgis"],
        )
        self.assertEqual(
            [finding["cache_key"] for finding in unsuppressed],
            ["extensions_public_pgroonga"],
        )

    def test_metadata_scoped_rule_matches_metadata_fields(self):
        findings = [
            {
                "name": "anon_security_definer_function_executable",
                "metadata": {
                    "schema": "public",
                    "name": "get_events_within_radius",
                    "arguments": "lat double precision, lng double precision",
                },
            },
            {
                "name": "anon_security_definer_function_executable",
                "metadata": {
                    "schema": "public",
                    "name": "is_super_admin",
                    "arguments": "",
                },
            },
        ]
        rules = [
            {
                "name": "anon_security_definer_function_executable",
                "type": "security",
                "metadata": {
                    "schema": "public",
                    "name": "get_events_within_radius",
                    "arguments": "lat double precision, lng double precision",
                },
            }
        ]

        accepted, unsuppressed = self.split(findings, rules)

        self.assertEqual(
            [finding["metadata"]["name"] for finding in accepted],
            ["get_events_within_radius"],
        )
        self.assertEqual(
            [finding["metadata"]["name"] for finding in unsuppressed],
            ["is_super_admin"],
        )

    def test_type_and_env_must_match_before_object_scope(self):
        findings = [
            {"name": "extension_in_public", "cache_key": "extensions_public_postgis"}
        ]
        rules = [
            {
                "name": "extension_in_public",
                "type": "performance",
                "envs": ["main"],
                "cache_key": "extensions_public_postgis",
            }
        ]

        accepted, unsuppressed = self.split(
            findings,
            rules,
            advisor_type="security",
            env="dev",
        )

        self.assertEqual(accepted, [])
        self.assertEqual(unsuppressed, findings)


if __name__ == "__main__":
    unittest.main()
