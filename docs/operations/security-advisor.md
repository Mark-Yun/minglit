# Supabase Security Advisor

Minglit runs `.github/workflows/monitor-security-advisor.yml` against Supabase
Management API advisor endpoints and opens issues for unsuppressed security or
performance findings.

## Accepted Findings

Accepted advisor findings are tracked in
`.github/advisor-accepted-findings.json`. This is a repo-side suppression list;
Supabase's public docs describe advisor/password-security controls, but do not
document a source-controlled advisor finding dismiss/suppress API.

Each accepted finding must include:

| Field | Meaning |
|---|---|
| `name` | Advisor finding name from Supabase, for example `auth_leaked_password_protection`. |
| `type` | `security` or `performance`. |
| `envs` | Environments where the finding is accepted. |
| `issue` | GitHub issue that records the decision. |
| `reason` | Short operational rationale. |

Rules may also include object scope:

| Field | Meaning |
|---|---|
| `cache_key` | Exact Supabase Advisor `cache_key` to suppress for this finding name. |
| `metadata` | Exact metadata key/value constraints, such as `schema`, `name`, and `arguments`. Values are matched against Advisor `metadata` first, then top-level finding fields. |

Use name-only rules only for findings that are intrinsically environment-level.
For object-level findings such as `extension_in_public`,
`rls_enabled_no_policy`, or `*_security_definer_function_executable`, include
`cache_key` or `metadata` so future unreviewed objects remain unsuppressed.

## Password Auth Posture

Minglit production auth does not support email/password signup or login.
Password-backed users are limited to dev/test seed users and simulator flows.

Supabase's leaked password protection checks password values through the
HaveIBeenPwned Pwned Passwords API and is available on Pro Plan and above. That
control is not applicable to the production auth model while password auth
remains unsupported.

The `auth_leaked_password_protection` advisor finding is therefore accepted for
`dev` and `main` under #2756. If production password auth is introduced later,
remove that accepted finding, enable leaked-password protection in Supabase Auth
settings, and verify the advisor finding disappears.

## References

- Supabase password security:
  https://supabase.com/docs/guides/auth/password-security
- Supabase Management API reference:
  https://supabase.com/docs/reference/api/introduction
