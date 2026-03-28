#!/bin/bash
# Generate docs/env-reference.md from env-manifest.json
# Usage: bash scripts/generate-env-docs.sh

set -euo pipefail

MANIFEST="env-manifest.json"
OUTPUT="docs/env-reference.md"

if [ ! -f "$MANIFEST" ]; then
  echo "Error: $MANIFEST not found (run from repo root)" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

python3 -c "
import json, sys

m = json.load(open('$MANIFEST'))

lines = []
lines.append('# Environment Variable Reference')
lines.append('')
lines.append('> Auto-generated from \`env-manifest.json\`. Do not edit manually.')
lines.append(f'> Manifest version: {m[\"version\"]}')
lines.append('')

def table(keys_obj, required_label):
    rows = []
    for k, v in keys_obj.items():
        rows.append(f'| \`{k}\` | {v[\"desc\"]} | {required_label} |')
    return rows

# Flutter
lines.append('## Flutter')
lines.append('')
lines.append('| Key | Description | Required |')
lines.append('|-----|-------------|----------|')
lines.extend(table(m['flutter']['required'], 'Yes'))
lines.extend(table(m['flutter']['optional'], 'No'))
lines.append('')

# Edge Functions — common
lines.append('## Edge Functions (common)')
lines.append('')
lines.append('| Key | Description | Required |')
lines.append('|-----|-------------|----------|')
lines.extend(table(m['edge_functions']['common']['required'], 'Yes'))
lines.extend(table(m['edge_functions']['common']['optional'], 'No'))
lines.append('')

# Edge Functions — per-function
for fn, cfg in m['edge_functions']['functions'].items():
    req = cfg.get('required', {})
    opt = cfg.get('optional', {})
    if req or opt:
        lines.append(f'### {fn}')
        lines.append('')
        lines.append('| Key | Description | Required |')
        lines.append('|-----|-------------|----------|')
        if req:
            lines.extend(table(req, 'Yes'))
        if opt:
            lines.extend(table(opt, 'No'))
        lines.append('')

# Next.js
for app in ['landing_user', 'landing_partner']:
    cfg = m['nextjs'][app]
    lines.append(f'## Next.js ({app})')
    lines.append('')
    lines.append('| Key | Description | Required |')
    lines.append('|-----|-------------|----------|')
    lines.extend(table(cfg['required'], 'Yes'))
    lines.extend(table(cfg.get('optional', {}), 'No'))
    lines.append('')

# GitHub Secrets
lines.append('## GitHub Secrets')
lines.append('')
lines.append('| Key | Description | Required |')
lines.append('|-----|-------------|----------|')
lines.extend(table(m['github_secrets']['required'], 'Yes'))
lines.extend(table(m['github_secrets']['optional'], 'No'))
lines.append('')

# Vault
lines.append('## Vault')
lines.append('')
lines.append('| Key | Description | Required |')
lines.append('|-----|-------------|----------|')
lines.extend(table(m['vault']['required'], 'Yes'))
lines.append('')

print('\n'.join(lines))
" > "$OUTPUT"

echo "Generated $OUTPUT"
