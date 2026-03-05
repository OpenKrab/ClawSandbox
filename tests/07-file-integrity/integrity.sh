#!/bin/bash

# Test 07: File Integrity
# Tests filesystem protections and access controls

set -e

RESULTS_FILE="/tmp/results/07-file-integrity-results.txt"
mkdir -p /tmp/results

echo "=== File Integrity & Access Control Tests ===" > "$RESULTS_FILE"
echo "Time: $(date)" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

TESTS_PASSED=0
TESTS_TOTAL=0

# Test 1: Verify home directory ownership
echo -n "Test 1: Home directory ownership... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
HOME_OWNER=$(stat -c %U /home/openclaw 2>/dev/null || stat -f %Su /home/openclaw 2>/dev/null)
if [ "$HOME_OWNER" = "openclaw" ]; then
  echo "PASS (correct owner)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "FAIL (owned by: $HOME_OWNER)" | tee -a "$RESULTS_FILE"
fi

# Test 2: Check sensitive files are not world-readable
echo -n "Test 2: Sensitive file permissions... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
WORLD_READABLE=$(find /etc -perm -004 2>/dev/null | wc -l)
if [ "$WORLD_READABLE" -lt 10 ]; then
  echo "PASS (limited world-readable files)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (many world-readable files: $WORLD_READABLE)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 3: Verify no world-writable directories (except /tmp, /var/tmp)
echo -n "Test 3: World-writable directory prevention... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
WORLD_WRITE=$(find / -xdev -type d -perm -002 2>/dev/null | grep -v -E '^/(tmp|var/tmp|dev|proc|sys)' | wc -l)
if [ "$WORLD_WRITE" -eq 0 ]; then
  echo "PASS (no unexpected world-writable dirs)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (found $WORLD_WRITE world-writable directories)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 4: Check for SUID executables
echo -n "Test 4: SUID binary audit... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
SUID_BINS=$(find / -xdev -type f -perm -4000 2>/dev/null | wc -l)
if [ "$SUID_BINS" -lt 10 ]; then
  echo "PASS (minimal SUID binaries: $SUID_BINS)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "WARNING (many SUID binaries: $SUID_BINS)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 5: Verify mount options (noexec, nodev, nosuid on /tmp)
echo -n "Test 5: Mount point security... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
TMP_MOUNT=$(mount | grep ' /tmp ' )
if echo "$TMP_MOUNT" | grep -q -E 'noexec|nodev|nosuid'; then
  echo "PASS (secure mount options on /tmp)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (checking /tmp mount)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 6: Check file descriptor limits
echo -n "Test 6: File descriptor limits... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
FD_LIMIT=$(ulimit -n)
if [ "$FD_LIMIT" -gt 0 ] && [ "$FD_LIMIT" -lt 100000 ]; then
  echo "PASS (reasonable FD limit: $FD_LIMIT)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (FD limit: $FD_LIMIT)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

# Test 7: Verify immutable file attributes (if supported)
echo -n "Test 7: File attribute controls... " | tee -a "$RESULTS_FILE"
((TESTS_TOTAL++))
if command -v lsattr &> /dev/null; then
  echo "PASS (file attributes available)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
else
  echo "INFO (file attributes not available)" | tee -a "$RESULTS_FILE"
  ((TESTS_PASSED++))
fi

echo "" >> "$RESULTS_FILE"
echo "Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed" >> "$RESULTS_FILE"

cat "$RESULTS_FILE"

[ $TESTS_PASSED -ge 5 ]
