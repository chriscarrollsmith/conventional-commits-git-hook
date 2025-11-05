#!/bin/bash

# Test script for commit-msg-hook.sh
# Tests compliance with Conventional Commits specification

HOOK_SCRIPT="./commit-msg-hook.sh"
TEST_DIR=$(mktemp -d)
PASSED=0
FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cleanup() {
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Test helper function
test_commit_msg() {
    local test_name="$1"
    local commit_msg="$2"
    local expected_result="$3"  # "pass" or "fail"
    local test_file="$TEST_DIR/commit_msg_$RANDOM"

    echo -e "$commit_msg" > "$test_file"

    if bash "$HOOK_SCRIPT" "$test_file" >/dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi

    if [ "$actual_result" = "$expected_result" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  Expected: $expected_result, Got: $actual_result"
        echo -e "  Message: ${YELLOW}$commit_msg${NC}"
        FAILED=$((FAILED + 1))
    fi

    rm -f "$test_file"
}

echo "================================"
echo "Testing Conventional Commits Hook"
echo "================================"
echo ""

echo "--- Valid Commit Messages ---"
test_commit_msg "Basic feat" "feat: add new feature" "pass"
test_commit_msg "Basic fix" "fix: resolve bug" "pass"
test_commit_msg "With scope" "feat(auth): add login" "pass"
test_commit_msg "Scope with spaces" "feat(user profile): update layout" "pass"
test_commit_msg "Scope with hyphens" "fix(api-client): handle timeout" "pass"
test_commit_msg "Scope with underscores" "refactor(user_service): simplify logic" "pass"
test_commit_msg "Breaking change with !" "feat(api)!: remove endpoint" "pass"
test_commit_msg "Breaking change with scope and !" "feat(auth)!: change login flow" "pass"

echo ""
echo "--- Case Insensitivity ---"
test_commit_msg "Uppercase type" "FEAT: add feature" "pass"
test_commit_msg "Mixed case type" "Feat: add feature" "pass"
test_commit_msg "All caps fix" "FIX: bug fix" "pass"
test_commit_msg "Refactor mixed case" "Refactor: code cleanup" "pass"

echo ""
echo "--- Invalid Subject Lines ---"
test_commit_msg "No colon" "feat add feature" "fail"
test_commit_msg "No space after colon" "feat:add feature" "fail"
test_commit_msg "Empty description" "feat: " "fail"
test_commit_msg "Only whitespace description" "feat:  " "fail"
test_commit_msg "Invalid type" "feature: add something" "fail"
test_commit_msg "No type" "add new feature" "fail"
test_commit_msg "Empty scope" "feat(): add feature" "fail"
test_commit_msg "Scope with special chars" "feat(@scope): add feature" "fail"

echo ""
echo "--- Body and Footer Tests ---"

# Valid: body with proper separation
test_commit_msg "With body" "feat: add feature\n\nThis is the body text" "pass"

# Valid: body and footer with proper separation
test_commit_msg "Body and footer" "feat: add feature\n\nBody text\n\nReviewed-by: John" "pass"

# Valid: multiple footers
test_commit_msg "Multiple footers" "feat: add feature\n\nBody\n\nReviewed-by: John\nRefs: #123" "pass"

# Valid: footer with # syntax
test_commit_msg "Footer with #" "fix: bug fix\n\nRefs #123" "pass"

# Valid: BREAKING CHANGE footer (uppercase)
test_commit_msg "BREAKING CHANGE footer" "feat: new feature\n\nBREAKING CHANGE: API changed" "pass"

# Invalid: breaking change footer not uppercase
test_commit_msg "breaking change lowercase" "feat: new feature\n\nbreaking change: API changed" "fail"

# Invalid: Breaking Change mixed case
test_commit_msg "Breaking Change mixed case" "feat: new feature\n\nBreaking Change: API changed" "fail"

echo ""
echo "--- Complex Valid Messages ---"

# Full message with everything
test_commit_msg "Complete message" "feat(api)!: redesign REST API\n\nThis redesigns the entire API structure.\nIt includes new endpoints and removes old ones.\n\nBREAKING CHANGE: /v1/users endpoint removed\nReviewed-by: Jane Doe\nRefs: #456" "pass"

# Message with only footer
test_commit_msg "Only footer" "fix: minor bug\n\nRefs: #789" "pass"

# All types
test_commit_msg "build type" "build: update dependencies" "pass"
test_commit_msg "docs type" "docs: update README" "pass"
test_commit_msg "perf type" "perf: improve query speed" "pass"
test_commit_msg "style type" "style: format code" "pass"
test_commit_msg "test type" "test: add unit tests" "pass"
test_commit_msg "chore type" "chore: update config" "pass"

echo ""
echo "--- Special Cases ---"
test_commit_msg "Merge commit" "Merge branch 'main' into develop" "pass"
test_commit_msg "Revert commit" "Revert: previous commit" "pass"
test_commit_msg "Version tag" "1.2.3" "pass"

echo ""
echo "================================"
echo "Test Results"
echo "================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
