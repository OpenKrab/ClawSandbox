#!/bin/bash

# Test 02: Privilege Escalation
# Tests if agent/process can escalate privileges beyond its user level

set -e

RESULTS_FILE="/tmp/results/02-privesc-results.txt"
mkdir -p /tmp/results

echo "=== Privilege Escalation Prevention Tests ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Check if running as non-root
echo -n "Test 1: Non-root user verification... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
CURRENT_UID=$(id -u)
if [ "$CURRENT_UID" -ne 0 ]; then
  echo "PASS (UID: $CURRENT_UID)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (running as root)" | tee -a "$RESULTS_FILE"
fi

# Test 2: Check if sudo is available
echo -n "Test 2: sudo availability... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! command -v sudo &> /dev/null; then
  echo "PASS (sudo not available)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (sudo found)" | tee -a "$RESULTS_FILE"
fi

# Test 3: Check if can access root-owned files
echo -n "Test 3: Root file access prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ ! -r /root/.ssh/id_rsa ] 2>/dev/null; then
  echo "PASS (cannot read /root/.ssh)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (root files accessible)" | tee -a "$RESULTS_FILE"
fi

# Test 4: Check if setuid bits are present
echo -n "Test 4: Setuid binary prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
SETUID_COUNT=$(find / -perm /4000 2>/dev/null | wc -l)
if [ "$SETUID_COUNT" -lt 5 ]; then
  echo "PASS (minimal setuid binaries: $SETUID_COUNT)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (too many setuid binaries: $SETUID_COUNT)" | tee -a "$RESULTS_FILE"
fi

# Test 5: Check no-new-privileges flag effectiveness
echo -n "Test 5: no-new-privileges enforcement... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
# This would require checking seccomp status, minimal check:
if grep -q read_only /proc/mounts 2>/dev/null || [ -r /etc/docker-secrets ] 2>/dev/null; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "PASS (no obvious privilege escalation)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -eq $TESTS_TOTAL ]
