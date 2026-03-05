#!/bin/bash

# ClawSandbox - Master Test Runner
# Executes all 8 security benchmark categories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Results directory
RESULTS_DIR="/tmp/results"
mkdir -p "$RESULTS_DIR"

# Test categories
declare -a CATEGORIES=(
  "01-recon:Reconnaissance"
  "02-privilege-escalation:Privilege Escalation"
  "03-data-exfiltration:Data Exfiltration"
  "04-prompt-injection:Prompt Injection"
  "05-general-audit:General Audit"
  "06-network-security:Network Security"
  "07-file-integrity:File Integrity"
  "08-memory-poisoning:Memory Poisoning"
)

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  ClawSandbox - Security Benchmark Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

PASSED=0
FAILED=0
TOTAL=${#CATEGORIES[@]}

# Run each category
for category in "${CATEGORIES[@]}"; do
  IFS=':' read -r category_name category_label <<< "$category"
  
  echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} Running: ${BLUE}${category_label}${NC}"
  
  SCRIPT_PATH="/home/openclaw/tests/${category_name}/*.sh"
  
  if [[ -f "${SCRIPT_PATH%/*}"/run.sh ]]; then
    if bash "${SCRIPT_PATH%/*}"/run.sh >> "$RESULTS_DIR/${category_name}.log" 2>&1; then
      echo -e "${GREEN}✓ PASSED${NC}: ${category_label}"
      ((PASSED++))
    else
      echo -e "${RED}✗ FAILED${NC}: ${category_label}"
      ((FAILED++))
    fi
  elif [[ -f "${SCRIPT_PATH%/*}"/*.sh ]]; then
    # Run first .sh script found in category
    if bash "${SCRIPT_PATH}" >> "$RESULTS_DIR/${category_name}.log" 2>&1; then
      echo -e "${GREEN}✓ PASSED${NC}: ${category_label}"
      ((PASSED++))
    else
      echo -e "${RED}✗ FAILED${NC}: ${category_label}"
      ((FAILED++))
    fi
  else
    echo -e "${YELLOW}⊘ SKIP${NC}: No test script found for ${category_label}"
  fi
  
  echo ""
done

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Results Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "Total Tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo -e "Success Rate: $((PASSED * 100 / TOTAL))%"
echo ""
echo -e "Results saved to: ${RESULTS_DIR}"
echo ""

# List all results files
echo -e "${YELLOW}Test logs:${NC}"
find "$RESULTS_DIR" -type f -name "*.log" -exec basename {} \; | sed 's/^/  - /'

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

# Exit with failure if any tests failed
if [ $FAILED -gt 0 ]; then
  exit 1
fi

exit 0
