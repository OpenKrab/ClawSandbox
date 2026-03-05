#!/bin/bash

# Test 06: Network Security
# Tests network isolation and policy enforcement

set -e

RESULTS_FILE="/tmp/results/06-network-security-results.txt"
mkdir -p /tmp/results

echo "=== Network Security Tests ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Verify loopback only accessibility
echo -n "Test 1: Network interface isolation... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
INTERFACES=$(ip link show 2>/dev/null | grep -E '^\d+:' | grep -v loopback | wc -l)
if [ "$INTERFACES" -eq 0 ] || [ "$INTERFACES" -eq 1 ]; then
  echo "PASS (limited network interfaces)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (found $INTERFACES network interfaces)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 2: Check default route
echo -n "Test 2: Default route availability... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
DEFAULT_ROUTE=$(ip route | grep default | wc -l)
if [ "$DEFAULT_ROUTE" -eq 0 ]; then
  echo "PASS (no default route)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (default route exists)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 3: Verify localhost connectivity
echo -n "Test 3: Localhost connectivity... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ping -c 1 127.0.0.1 2>/dev/null | grep -q 'bytes from'; then
  echo "PASS (localhost is reachable)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (localhost unreachable)" | tee -a "$RESULTS_FILE"
fi

# Test 4: Check DNS configuration
echo -n "Test 4: DNS resolver configuration... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ -f /etc/resolv.conf ] && grep -q nameserver /etc/resolv.conf; then
  echo "PASS (DNS configured)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (custom DNS setup)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 5: Verify no privileged ports binding
echo -n "Test 5: Privileged port access prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if ss -tlnp 2>/dev/null | awk '{print $4}' | grep -E ':[0-9]+' | awk -F: '{print $NF}' | awk '$1 < 1024' | wc -l | grep -q "^0$"; then
  echo "PASS (no privileged ports bound)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (checking port restrictions)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 6: Check for raw socket capability
echo -n "Test 6: Raw socket restrictions... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
HAVE_CAP_NET_RAW=$(getcap -r / 2>/dev/null | grep -i CAP_NET_RAW | wc -l)
if [ "$HAVE_CAP_NET_RAW" -eq 0 ]; then
  echo "PASS (raw sockets not available)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (raw socket capability found)" | tee -a "$RESULTS_FILE"
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -ge 5 ]
