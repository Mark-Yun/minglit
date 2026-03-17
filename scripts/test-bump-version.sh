#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUMP_SCRIPT="$SCRIPT_DIR/bump-version.sh"

TESTS_PASSED=0
TESTS_FAILED=0

assert_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

assert_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

setup_test_dir() {
    local test_num="$1"
    local test_dir="/tmp/bump_version_test_$test_num"
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
    cd "$test_dir" || {
        echo -e "${RED}✗ FAIL: unable to enter test dir: $test_dir${NC}"
        exit 1
    }
    
    mkdir -p apps/app_user apps/app_partner shared/packages/minglit_kit shared/packages/minglit_lints shared/packages/minglit_iamport_v1 apps/landing_user apps/landing_partner
    
    cat > apps/app_user/pubspec.yaml << 'EOF'
name: app_user
version: 1.0.0+1
EOF

    cat > apps/app_partner/pubspec.yaml << 'EOF'
name: app_partner
version: 1.0.0+1
EOF

    cat > shared/packages/minglit_kit/pubspec.yaml << 'EOF'
name: minglit_kit
version: 0.0.1
EOF

    cat > shared/packages/minglit_lints/pubspec.yaml << 'EOF'
name: minglit_lints
version: 0.1.0
EOF

    cat > shared/packages/minglit_iamport_v1/pubspec.yaml << 'EOF'
name: minglit_iamport_v1
version: 0.0.1
EOF

    cat > apps/landing_user/package.json << 'EOF'
{
  "name": "landing_user",
  "version": "0.1.0"
}
EOF

    cat > apps/landing_partner/package.json << 'EOF'
{
  "name": "landing_partner",
  "version": "0.1.0"
}
EOF

    cat > package.json << 'EOF'
{
  "name": "minglit-root",
  "version": "1.0.0"
}
EOF
}

echo -e "${YELLOW}Starting bump-version.sh test suite${NC}"
echo ""

echo -e "${BLUE}TEST 1: Normal version bump (25.03.1)${NC}"
setup_test_dir 1
bash "$BUMP_SCRIPT" 25.03.1 > /dev/null 2>&1
if grep -q "version: 25.03.1+25030001" apps/app_user/pubspec.yaml; then assert_pass "app_user versionCode"; else assert_fail "app_user versionCode"; fi
if grep -q "version: 25.03.1+25030001" apps/app_partner/pubspec.yaml; then assert_pass "app_partner versionCode"; else assert_fail "app_partner versionCode"; fi
if grep -q "version: 25.03.1" shared/packages/minglit_kit/pubspec.yaml; then assert_pass "minglit_kit version"; else assert_fail "minglit_kit version"; fi
if grep -q "version: 25.03.1" shared/packages/minglit_lints/pubspec.yaml; then assert_pass "minglit_lints version"; else assert_fail "minglit_lints version"; fi
if grep -q "version: 25.03.1" shared/packages/minglit_iamport_v1/pubspec.yaml; then assert_pass "minglit_iamport_v1 version"; else assert_fail "minglit_iamport_v1 version"; fi
if grep -q '"version": "25.03.1"' apps/landing_user/package.json; then assert_pass "landing_user version"; else assert_fail "landing_user version"; fi
if grep -q '"version": "25.03.1"' apps/landing_partner/package.json; then assert_pass "landing_partner version"; else assert_fail "landing_partner version"; fi
if grep -q '"version": "25.03.1"' package.json; then assert_pass "root version"; else assert_fail "root version"; fi
echo ""

echo -e "${BLUE}TEST 2: Dev suffix version bump (25.03.1-dev)${NC}"
setup_test_dir 2
bash "$BUMP_SCRIPT" 25.03.1-dev > /dev/null 2>&1
if grep -q "version: 25.03.1-dev+25030001" apps/app_user/pubspec.yaml; then assert_pass "app_user dev version"; else assert_fail "app_user dev version"; fi
if grep -q "version: 25.03.1-dev" shared/packages/minglit_kit/pubspec.yaml; then assert_pass "minglit_kit dev version"; else assert_fail "minglit_kit dev version"; fi
if grep -q '"version": "25.03.1-dev"' apps/landing_user/package.json; then assert_pass "landing_user version (with -dev)"; else assert_fail "landing_user version (with -dev)"; fi
if grep -q '"version": "25.03.1-dev"' apps/landing_partner/package.json; then assert_pass "landing_partner version (with -dev)"; else assert_fail "landing_partner version (with -dev)"; fi
if grep -q '"version": "25.03.1-dev"' package.json; then assert_pass "root version (with -dev)"; else assert_fail "root version (with -dev)"; fi
echo ""

echo -e "${BLUE}TEST 3: versionCode calculation (26.12.99 → 26120099)${NC}"
setup_test_dir 3
bash "$BUMP_SCRIPT" 26.12.99 > /dev/null 2>&1
if grep -q "version: 26.12.99+26120099" apps/app_user/pubspec.yaml; then assert_pass "versionCode 26120099"; else assert_fail "versionCode 26120099"; fi
echo ""

echo -e "${BLUE}TEST 4: Invalid input rejection - wrong format (1.0.0)${NC}"
setup_test_dir 4
if bash "$BUMP_SCRIPT" 1.0.0 > /dev/null 2>&1; then
    assert_fail "Invalid format rejected"
else
    assert_pass "Invalid format rejected"
fi
echo ""

echo -e "${BLUE}TEST 5: Invalid input rejection - invalid month (25.13.1)${NC}"
setup_test_dir 5
if bash "$BUMP_SCRIPT" 25.13.1 > /dev/null 2>&1; then
    assert_fail "Invalid month rejected"
else
    assert_pass "Invalid month rejected"
fi
echo ""

echo -e "${BLUE}TEST 6: Empty input rejection${NC}"
setup_test_dir 6
if bash "$BUMP_SCRIPT" > /dev/null 2>&1; then
    assert_fail "Empty input rejected"
else
    assert_pass "Empty input rejected"
fi
echo ""

echo -e "${BLUE}TEST 7: Idempotency - same version twice (25.03.1)${NC}"
setup_test_dir 7
bash "$BUMP_SCRIPT" 25.03.1 > /dev/null 2>&1
FIRST_HASH=$(md5 -q apps/app_user/pubspec.yaml)
bash "$BUMP_SCRIPT" 25.03.1 > /dev/null 2>&1
SECOND_HASH=$(md5 -q apps/app_user/pubspec.yaml)
if [ "$FIRST_HASH" = "$SECOND_HASH" ]; then
    assert_pass "Idempotency verified"
else
    assert_fail "Idempotency failed"
fi
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
fi
