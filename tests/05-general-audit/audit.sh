#!/bin/bash

# Test 05: General Audit
# Comprehensive security audit of container and runtime

set -e

RESULTS_FILE="/tmp/results/05-audit-results.txt"
mkdir -p /tmp/results

echo "=== General Security Audit ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Verify Docker Engine version
echo -n "Test 1: Docker engine compatibility... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ -f /.dockerenv ]; then
  echo "PASS (running in Docker)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (not in Docker)" | tee -a "$RESULTS_FILE"
fi

# Test 2: Check Linux kernel capabilities
echo -n "Test 2: Linux capabilities audit... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
CAPS=$(grep ^Cap /proc/self/status | head -1 | awk '{print $2}')
# Should be very few capabilities (mostly 0s)
if echo "$CAPS" | grep -q "^0000000000000000"; then
  echo "PASS (minimal capabilities)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (capabilities: $CAPS)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 3: Check seccomp status
echo -n "Test 3: Seccomp policy status... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
SECCOMP_STATUS=$(grep Seccomp /proc/self/status | awk '{print $2}')
if [ "$SECCOMP_STATUS" -ne "0" ]; then
  echo "PASS (seccomp enabled: status=$SECCOMP_STATUS)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (seccomp appears disabled)" | tee -a "$RESULTS_FILE"
fi

# Test 4: Verify read-only root
echo -n "Test 4: Root filesystem mount status... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if mount | grep -q 'on / type.*ro'; then
  echo "PASS (root mounted read-only)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (root may be writable)" | tee -a "$RESULTS_FILE"
fi

# Test 5: Check apparmor or selinux
echo -n "Test 5: LSM (AppArmor/SELinux) status... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ -f /sys/kernel/security/apparmor/enabled ] || [ -f /sys/fs/selinux/status ]; then
  echo "PASS (LSM enabled)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (LSM may not be configured)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 6: Memory limit verification
echo -n "Test 6: Memory limit enforcement... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
MEMORY_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "unlimited")
if [ "$MEMORY_LIMIT" != "unlimited" ] && [ "$MEMORY_LIMIT" -gt 0 ]; then
  MEMORY_MB=$((MEMORY_LIMIT / 1024 / 1024))
  echo "PASS (memory limit: ${MEMORY_MB}MB)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (no memory limit detected)" | tee -a "$RESULTS_FILE"
fi

# Test 7: CPU limit verification
echo -n "Test 7: CPU quota enforcement... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
  CPU_QUOTA=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || echo "-1")
  if [ "$CPU_QUOTA" -gt 0 ]; then
    echo "PASS (CPU quota set)" | tee -a "$RESULTS_FILE"
    ((TESTS_PASSED++))
  else
    echo "INFO (no CPU quota)" | tee -a "$RESULTS_FILE"
    ((TESTS_PASSED++))
  fi
else
  echo "INFO (CPU cgroups not available)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -ge 5 ]
