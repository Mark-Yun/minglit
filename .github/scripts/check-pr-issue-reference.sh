#!/usr/bin/env bash
set -euo pipefail

stage="${PR_GATE_STAGE:-}"
if [ "$stage" != "dev-staging" ]; then
  echo "Stage is '${stage:-unset}', not dev-staging; skipping PR issue reference check."
  exit 0
fi

if [ -z "${GITHUB_EVENT_PATH:-}" ] || [ ! -f "$GITHUB_EVENT_PATH" ]; then
  echo "GITHUB_EVENT_PATH is unavailable; skipping PR issue reference check."
  exit 0
fi

if ! jq -e '.pull_request.number' "$GITHUB_EVENT_PATH" >/dev/null 2>&1; then
  echo "Not a pull_request payload; skipping PR issue reference check."
  exit 0
fi

base_ref=$(jq -r '.pull_request.base.ref // ""' "$GITHUB_EVENT_PATH")
if [ "$base_ref" != "dev-staging" ]; then
  echo "PR base is '$base_ref', not dev-staging; skipping PR issue reference check."
  exit 0
fi

draft=$(jq -r '.pull_request.draft // false' "$GITHUB_EVENT_PATH")
if [ "$draft" = "true" ]; then
  echo "Draft PR; skipping PR issue reference check until ready for review."
  exit 0
fi

author=$(jq -r '.pull_request.user.login // ""' "$GITHUB_EVENT_PATH")
author_type=$(jq -r '.pull_request.user.type // ""' "$GITHUB_EVENT_PATH")
title=$(jq -r '.pull_request.title // ""' "$GITHUB_EVENT_PATH")
body=$(jq -r '.pull_request.body // ""' "$GITHUB_EVENT_PATH")

if [ "$author_type" = "Bot" ]; then
  echo "Bot-authored PR by $author (type=$author_type); skipping PR issue reference check."
  exit 0
fi

case "$author" in
  dependabot[bot]|minglit-release-bot[bot])
    echo "Bot-authored PR by $author; skipping PR issue reference check."
    exit 0
    ;;
esac

if printf '%s\n' "$title" | grep -Eiq '^ci\(rc-backport\): backport rc hotfix #[0-9]+ to dev-staging$'; then
  echo "Release-bot RC hotfix backport PR title; skipping PR issue reference check."
  exit 0
fi

issue_ref='((#[0-9]+)|([[:alnum:]_.-]+/[[:alnum:]_.-]+#[0-9]+)|(https://github[.]com/[^[:space:]]+/issues/[0-9]+))'
keyword_separator='([[:space:]]+|[[:space:]]*:[[:space:]]*)'

if printf '%s\n' "$body" | grep -Eiq "(^|[^[:alnum:]_-])(close[sd]?|fix(e[sd])?|resolve[sd]?)${keyword_separator}${issue_ref}"; then
  echo "PR body contains a closing issue keyword."
  exit 0
fi

has_refs=false
if printf '%s\n' "$body" | grep -Eiq "(^|[^[:alnum:]_-])(refs?|references?)${keyword_separator}${issue_ref}"; then
  has_refs=true
fi

has_nonclosing_reason=false
if printf '%s\n' "$body" | grep -Eiq '(partial|partially|follow-?up|umbrella|parent|tracking|one feature per PR|not close|no close|close[[:space:]]+금지|닫지[[:space:]]*않|부분|일부|후속|상위|추적)'; then
  has_nonclosing_reason=true
fi

if [ "$has_refs" = "true" ] && [ "$has_nonclosing_reason" = "true" ]; then
  echo "PR body uses Refs with an explicit non-closing reason."
  exit 0
fi

if printf '%s\n' "$body" | grep -Eiq '(^|[[:space:]])No linked issue:[[:space:]].{10,}'; then
  echo "PR body declares an explicit no-linked-issue reason."
  exit 0
fi

cat <<'MSG'
::error::dev-staging PR body must declare issue lifecycle intent.

Add one of:
- `Closes #123` / `Fixes #123` / `Resolves #123` when this PR fully resolves the issue.
- `Refs #123` plus a clear non-closing reason when this is partial work, an umbrella issue, or a follow-up tracker.
- `No linked issue: <reason>` only for exceptional PRs that genuinely have no issue.

This prevents agent PRs from merging without closing the issue they completed.
MSG
exit 1
