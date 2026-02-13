#!/bin/bash
# =============================================================================
# Smoke Test Script - Verify AI CLI Tools Start
# Run after Docker build to ensure all tools are functional
# =============================================================================

set -u
FAILED=0
PASSED=0
TIMEOUT=10

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "========================================================================"
echo "                    AI CLI Tools Smoke Tests"
echo "========================================================================"
echo ""

test_tool() {
    local tool=$1
    local cmd=$2

    echo -n "Testing $tool... "

    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}SKIPPED${NC} (not installed)"
        return 0
    fi

    if timeout $TIMEOUT bash -c "$cmd" &>/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Command: $cmd"
        ((FAILED++))
        return 1
    fi
}

echo "=== Core CLI Tools ==="
test_tool "claude" "claude --version"
test_tool "opencode" "opencode --version"
test_tool "codex" "codex --version"
test_tool "agent" "agent --version"

echo ""
echo "=== Supporting Tools ==="
test_tool "gh" "gh --version"
test_tool "git" "git --version"
test_tool "node" "node --version"

echo ""
echo "========================================================================"
echo -e "Results: ${GREEN}${PASSED} passed${NC}, ${RED}${FAILED} failed${NC}"
echo "========================================================================"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
