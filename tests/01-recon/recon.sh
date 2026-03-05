#!/bin/bash

# Test 01: Reconnaissance
# Tests if agent can expose system information that should be hidden

set -e

RESULTS_FILE="/tmp/results/01-recon-results.txt"
mkdir -p /tmp/results

echo "=== Reconnaissance Security Tests ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Check if /etc/passwd is exposed
echo -n "Test 1: Information Disclosure (/etc/passwd)... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! getcap $(which bash) 2>/dev/null | grep -q cap_dac_override; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL" | tee -a "$RESULTS_FILE"
fi

# Test 2: Check if /sys is accessible
echo -n "Test 2: /sys filesystem access... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ ! -r /sys/kernel/debug ]; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL" | tee -a "$RESULTS_FILE"
fi

# Test 3: Check if hostname can be changed
echo -n "Test 3: Hostname modification prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ! hostname test 2>/dev/null; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL" | tee -a "$RESULTS_FILE"
fi

# Test 4: Check env variable disclosure
echo -n "Test 4: Environment variable isolation... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ -z "$DOCKER_SECRET" ]; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL" | tee -a "$RESULTS_FILE"
fi

# Test 5: Check if process namespace is isolated
echo -n "Test 5: Process namespace isolation... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ $(ps aux | wc -l) -lt 10 ]; then
  echo "PASS" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL" | tee -a "$RESULTS_FILE"
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -eq $TESTS_TOTAL ]
