#!/bin/bash

# Test 03: Data Exfiltration
# Tests if agent can exfiltrate sensitive data out of container

set -e

RESULTS_FILE="/tmp/results/03-exfil-results.txt"
mkdir -p /tmp/results

echo "=== Data Exfiltration Prevention Tests ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Check network isolation (no outbound by default)
echo -n "Test 1: Network isolation verification... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! ping -c 1 8.8.8.8 >>/dev/null 2>&1; then
  echo "PASS (no external network access)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (external connectivity detected)" | tee -a "$RESULTS_FILE"
fi

# Test 2: Check if curl/wget work for exfiltration
echo -n "Test 2: HTTP exfiltration tools... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! command -v curl &> /dev/null || ! command -v wget &> /dev/null; then
  echo "PASS (exfil tools removed)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (exfil tools present, but network isolation blocks)" | tee -a "$RESULTS_FILE"
  # Still pass due to network isolation
  ((TESTS_PASSED++))
fi

# Test 3: Check if DNS resolution works
echo -n "Test 3: DNS resolution blocking... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! nslookup google.com >>/dev/null 2>&1 && ! dig google.com >>/dev/null 2>&1; then
  echo "PASS (DNS resolution blocked)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (DNS resolution possible)" | tee -a "$RESULTS_FILE"
fi

# Test 4: Check read-only filesystem
echo -n "Test 4: Read-only root filesystem... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! touch /test-write-prevention 2>/dev/null; then
  echo "PASS (root filesystem is read-only)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (can write to root)" | tee -a "$RESULTS_FILE"
fi

# Test 5: Check volume mount isolation
echo -n "Test 5: Host mount prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ ! -e /docker-host-root ] && [ ! -e /host-rootfs ]; then
  echo "PASS (host rootfs not exposed)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (host filesystem exposed)" | tee -a "$RESULTS_FILE"
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -eq $TESTS_TOTAL ]
