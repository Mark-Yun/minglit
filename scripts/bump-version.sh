#!/bin/bash

# bump-version.sh - Update version across all project files
# Usage: bash scripts/bump-version.sh <version>
# Examples:
#   bash scripts/bump-version.sh 26.03.1
#   bash scripts/bump-version.sh 26.03.1-dev

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input
if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Missing version argument${NC}"
    echo "Usage: bash scripts/bump-version.sh <version>"
    echo "Examples:"
    echo "  bash scripts/bump-version.sh 26.03.1"
    echo "  bash scripts/bump-version.sh 26.03.1-dev"
    exit 1
fi

VERSION_INPUT="$1"

# Regex validation: YY.MM.PR#[-dev]
# Format: 26.03.1 or 26.03.1-dev
# Month must be 01-12
if ! [[ "$VERSION_INPUT" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]+(-dev)?$ ]]; then
    echo -e "${RED}Error: Invalid version format: $VERSION_INPUT${NC}"
    echo "Expected format: YY.MM.PR# or YY.MM.PR#-dev"
    echo "Examples: 26.03.1, 26.03.1-dev, 26.12.99"
    exit 1
fi

# Extract YY, MM, PR# from version
YY=$(echo "$VERSION_INPUT" | cut -d. -f1)
MM=$(echo "$VERSION_INPUT" | cut -d. -f2)
PR_AND_SUFFIX=$(echo "$VERSION_INPUT" | cut -d. -f3)

# Extract PR# (remove -dev suffix if present)
PR=$(echo "$PR_AND_SUFFIX" | sed 's/-dev$//')

# Validate month (01-12)
if [ "$MM" -lt 1 ] || [ "$MM" -gt 12 ]; then
    echo -e "${RED}Error: Invalid month: $MM (must be 01-12)${NC}"
    exit 1
fi

# Calculate versionCode: YYMM * 10000 + PR#
VERSION_CODE=$((YY * 100 * 10000 + MM * 10000 + PR))

# Extract base version (without -dev)
BASE_VERSION=$(echo "$VERSION_INPUT" | sed 's/-dev$//')

echo -e "${YELLOW}Bumping version to: $VERSION_INPUT${NC}"
echo "  YY=$YY, MM=$MM, PR#=$PR"
echo "  versionCode=$VERSION_CODE"
echo "  baseVersion=$BASE_VERSION"
echo ""

# Define target files
FLUTTER_APP_USER="apps/app_user/pubspec.yaml"
FLUTTER_APP_PARTNER="apps/app_partner/pubspec.yaml"
SHARED_MINGLIT_KIT="shared/packages/minglit_kit/pubspec.yaml"
SHARED_MINGLIT_LINTS="shared/packages/minglit_lints/pubspec.yaml"
SHARED_MINGLIT_IAMPORT="shared/packages/minglit_iamport_v1/pubspec.yaml"
NPM_LANDING_USER="apps/landing_user/package.json"
NPM_LANDING_PARTNER="apps/landing_partner/package.json"
NPM_ROOT="package.json"

# Array of files to update
declare -a FILES=(
    "$FLUTTER_APP_USER"
    "$FLUTTER_APP_PARTNER"
    "$SHARED_MINGLIT_KIT"
    "$SHARED_MINGLIT_LINTS"
    "$SHARED_MINGLIT_IAMPORT"
    "$NPM_LANDING_USER"
    "$NPM_LANDING_PARTNER"
    "$NPM_ROOT"
)

# Update Flutter pubspec.yaml files (with versionCode)
echo -e "${YELLOW}Updating Flutter app pubspec.yaml files...${NC}"
for file in "$FLUTTER_APP_USER" "$FLUTTER_APP_PARTNER"; do
    if [ -f "$file" ]; then
        sed -i.bak "s/^version: .*/version: ${VERSION_INPUT}+${VERSION_CODE}/" "$file"
        rm -f "${file}.bak"
        echo -e "${GREEN}✓ Updated: $file${NC}"
    else
        echo -e "${RED}✗ File not found: $file${NC}"
        exit 1
    fi
done

# Update shared package pubspec.yaml files (without versionCode)
echo -e "${YELLOW}Updating shared package pubspec.yaml files...${NC}"
for file in "$SHARED_MINGLIT_KIT" "$SHARED_MINGLIT_LINTS" "$SHARED_MINGLIT_IAMPORT"; do
    if [ -f "$file" ]; then
        sed -i.bak "s/^version: .*/version: ${VERSION_INPUT}/" "$file"
        rm -f "${file}.bak"
        echo -e "${GREEN}✓ Updated: $file${NC}"
    else
        echo -e "${RED}✗ File not found: $file${NC}"
        exit 1
    fi
done

# Update npm package.json files
echo -e "${YELLOW}Updating npm package.json files...${NC}"
for file in "$NPM_LANDING_USER" "$NPM_LANDING_PARTNER" "$NPM_ROOT"; do
    if [ -f "$file" ]; then
        # Use Python for safe JSON manipulation (cross-platform compatible)
        python3 << EOF
import json
import sys

try:
    with open('$file', 'r') as f:
        data = json.load(f)
    
    data['version'] = '$BASE_VERSION'
    
    with open('$file', 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')  # Add trailing newline
    
    print('✓ Updated: $file')
except Exception as e:
    print(f'✗ Error updating $file: {e}', file=sys.stderr)
    sys.exit(1)
EOF
        if [ $? -ne 0 ]; then
            exit 1
        fi
    else
        echo -e "${RED}✗ File not found: $file${NC}"
        exit 1
    fi
done

echo ""
echo -e "${GREEN}✓ Version bump completed successfully!${NC}"
echo "  Updated 8 files with version: $VERSION_INPUT"
echo "  versionCode: $VERSION_CODE"
