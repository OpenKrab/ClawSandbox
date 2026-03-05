# Architecture & Design Documentation

## Overview

ClawSandbox is a **hardened Docker sandbox** designed specifically for testing security of AI agent skills before publishing to ClawHub. It implements 7 security layers and 8 comprehensive test categories.

---

## Core Design Principles

### 1. **Defense in Depth**
Multiple overlapping security controls ensure that even if one fails, others prevent exploitation.

```
Application Layer (tests)
         ↓
Container Runtime (Docker)
         ↓
Kernel Security (seccomp, AppArmor)
         ↓
Host OS (Linux)
```

### 2. **Fail Secure**
Default configuration prioritizes safety over functionality. Features must be explicitly enabled.

### 3. **Minimal Privilege**
- Non-root user execution
- All Linux capabilities dropped
- No SUID binaries
- No host access

### 4. **Isolation by Default**
- Network: Isolated (no outbound by default)
- Storage: Named volumes only (no host mounts)
- Processes: Container namespace isolation
- Memory: Per-container limits

---

## Security Architecture

### Layer 1: User Isolation
```dockerfile
# Non-root user (UID 999)
RUN useradd -m -u 999 -s /bin/bash openclaw
USER openclaw
```

**Effect**: Limits damage if attacker gains code execution
- Can't write to root-owned files
- Can't run as root for privilege escalation

### Layer 2: Linux Capabilities
```yaml
cap_drop:
  - ALL  # Drop all capabilities
```

**Effect**: Restricts kernel-level operations
- No CAP_SYS_ADMIN (system administration)
- No CAP_NET_RAW (raw sockets)
- No CAP_SETUID (privilege escalation)

### Layer 3: Read-Only Root Filesystem
```yaml
read_only_root_filesystem: true
volumes:
  - type: tmpfs
    target: /tmp
```

**Effect**: Prevents filesystem tampering
- System files cannot be modified
- Only /tmp, /var/tmp, /home are writable (tmpfs)
- tmpfs is cleared on container restart

### Layer 4: No New Privileges Flag
```yaml
security_opt:
  - no-new-privileges:true
```

**Effect**: Prevents privilege escalation via:
- SUID binaries
- Setcap operations
- Capability inheritance on exec

### Layer 5: Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

**Effect**: Prevents DoS and resource exhaustion
- CPU limited to 2 cores
- Memory limited to 2GB
- Prevents fork bombs and infinite loops

### Layer 6: Network Isolation
```yaml
network_mode: bridge
# Optional: networks: []  # Complete isolation
```

**Effect**: Prevents data exfiltration
- No outbound internet by default
- Only localhost communication
- DNS resolution disabled unless configured

### Layer 7: Volume Isolation
```yaml
volumes:
  - results_volume:/tmp/results  # Named volume only
  - skills_volume:/home/openclaw/skills
# No bind mounts or host paths
```

**Effect**: Prevents host filesystem access
- All volumes are managed by Docker
- No direct host directory mounting
- Clear data lifecycle

---

## Test Suite Architecture

### Test Category Hierarchy

```
run-all.sh (Master orchestrator)
    │
    ├── 01-recon
    │   └── Tests system information disclosure
    │
    ├── 02-privilege-escalation
    │   └── Tests privilege boundary violations
    │
    ├── 03-data-exfiltration
    │   └── Tests network isolation enforcement
    │
    ├── 04-prompt-injection
    │   └── Tests AI agent robustness
    │
    ├── 05-general-audit
    │   └── Tests container hardening
    │
    ├── 06-network-security
    │   └── Tests network policies
    │
    ├── 07-file-integrity
    │   └── Tests filesystem protections
    │
    └── 08-memory-poisoning
        └── Tests process isolation
```

### Test Execution Flow

```
User runs: ./run-all.sh
    │
    ├─→ Verify directories exist
    ├─→ Create /tmp/results
    │
    ├─→ [Category 1] Run test script
    │   ├─→ Parse test results
    │   ├─→ Log to /tmp/results/{category}.log
    │   ├─→ Print summary
    │   └─→ Increment pass/fail counters
    │
    ├─→ [Category 2-8] ... (repeat)
    │
    └─→ Print final summary:
        - Total tests
        - Passed/Failed breakdown
        - Success percentage
```

### Test Result Format

All tests output to `/tmp/results/{NN-category}-results.txt`:

```
=== Reconnaissance Security Tests ===
Time: Mon Mar  5 10:30:45 UTC 2026

Test 1: Information Disclosure (/etc/passwd)... PASS
Test 2: /sys filesystem access... PASS
...

Summary: 5/5 tests passed
```

---

## Component Architecture

### Dockerfile Components

```dockerfile
Base Image (node:22-slim)
    │
    ├── System Libraries
    │   └── curl, wget, git, jq, ca-certificates
    │
    ├── User Creation
    │   └── openclaw (UID 999)
    │
    ├── OpenClaw Installation
    │   └── npm install -g @claw-ai/openclaw@latest
    │
    └── Test Scripts
        ├── tests/01-recon/recon.sh
        ├── tests/02-privilege-escalation/privesc.sh
        ├── ... (8 categories total)
        └── tests/run-all.sh (master)
```

### Runtime Structure

```
Container Runtime
    │
    ├── Process Namespace
    │   ├── PID 1: init or bash
    │   ├── PID N: test script
    │   └── (isolated from host)
    │
    ├── Network Namespace
    │   ├── lo (loopback): enabled
    │   ├── eth0 (external): isolated
    │   └── DNS: configurable
    │
    ├── Filesystem
    │   ├── / (read-only)
    │   ├── /tmp (tmpfs, 512MB)
    │   └── /tmp/results (tmpfs+volume)
    │
    ├── Resource Cgroups
    │   ├── CPU: 2 cores limit
    │   └── Memory: 2GB limit
    │
    └── User Namespace
        ├── UID 999: openclaw

        └── GID 999: openclaw
```

---

## Data Flow

### Test Execution Data Flow

```
Input
  │
  ├─→ Test Script (*.sh)
  │   ├─→ Probe system state
  │   ├─→ Attempt attack
  │   ├─→ Verify failure/success
  │   └─→ Write result
  │
  ├─→ Result File (/tmp/results/*.txt)
  │
  ├─→ Master Script (run-all.sh)
  │   ├─→ Parse results
  │   ├─→ Aggregate statistics
  │   └─→ Print summary
  │
  └─→ Output
      ├─→ Console (colors, progress)
      ├─→ Summary (pass/fail counts)
      └─→ Log Files (persistent in /tmp/results)
```

### API Testing Data Flow (Optional)

```
User Input
  │
  ├─→ API Key Setup (scripts/setup-api-key.sh)
  │   ├─→ Secure storage: ~/.clawsandbox-secrets/
  │   ├─→ Permission: 600
  │   └─→ Load into container env: EXPORT
  │
  ├─→ API Test Script (memory-poison-api.sh)
  │   ├─→ Read API credential
  │   ├─→ Make API call
  │   ├─→ Analyze response
  │   └─→ Write result
  │
  └─→ Result Analysis
      ├─→ Did agent refuse poison?
      ├─→ Did agent follow instructions?
      └─→ Rate: PASS / FAIL / PARTIAL
```

---

## Security Testing Methodology

### Attack Vectors Tested

| Category | Attack Vector | Goal |
|----------|---|---|
| Recon | Information exposure | Verify no system details leak |
| PrivEsc | Privilege abuse | Verify user isolation |
| Exfil | Data theft | Verify network isolation |
| Injection | Prompt manipulation | Verify input validation |
| Audit | General hardening | Verify security layer integrity |
| Network | Net policy bypass | Verify connectivity restrictions |
| File | Filesystem access | Verify permission enforcement |
| Memory | State corruption | Verify process isolation |

### Expected Attack Scenario

```
Attacker Goal: Escape sandbox and compromise host
                            │
     Attempt 1: Read /etc/passwd ──→ Blocked by:
                 · File permissions (no root access)
                 · User isolation (openclaw ≠ root)
                 Result: FAIL ✓
                            │
     Attempt 2: Escalate privileges ──→ Blocked by:
                 · Dropped capabilities (no CAP_SETUID)
                 · no-new-privileges flag
                 · Missing setuid binaries
                 Result: FAIL ✓
                            │
     Attempt 3: Exfiltrate data ──→ Blocked by:
                 · Network isolation (no outbound)
                 · tmpfs FS (data cleared)
                 · Volume restriction (no host mount)
                 Result: FAIL ✓
                            │
     All attempts blocked = Container escape prevented ✓
```

---

## Extension Points

### Adding New Test Categories

1. **Create directory**: `tests/NN-category-name/`
2. **Implement tests**: `tests/NN-category-name/test-name.sh`
3. **Update run-all.sh**: Add to CATEGORIES array
4. **Document**: Add section to SETUP.md

### Customizing for Specific Skills

1. **Mount skill**: Add volume in docker-compose.yml
2. **Create skill-specific tests**: Copy and modify existing tests
3. **Integrate**: Call from test scripts before assertion

### Extending with External Tools

```dockerfile
# In Dockerfile, add:
RUN apt-get install -y --no-install-recommends \
    your-security-tool \
    && rm -rf /var/lib/apt/lists/*
```

---

## Performance Characteristics

### Build Time
- First build: 5-10 minutes (downloads node:22-slim)
- Subsequent rebuilds: 30-60 seconds (Docker cache)
- Full rebuild (no cache): 5-10 minutes

### Runtime
- Startup: ~2 seconds
- Test suite: 30-90 seconds total
- Per-category: 3-15 seconds
- Memory usage: 150-500MB

### Resource Limits
- CPU: Limited to 2 cores (configurable)
- Memory: Limited to 2GB (configurable)
- Disk: tmpfs + named volumes (container managed)

---

## Failure Modes & Recovery

### Scenario 1: Test Timeout
```bash
# Issue: Test takes too long
# Cause: Host under load or large file operations
# Fix: Increase timeout or reduce dataset

# In run-all.sh, modify:
timeout 120 bash "${SCRIPT_PATH%/*}"/run.sh
```

### Scenario 2: Network Isolation Failures
```bash
# Issue: Container still has outbound access
# Cause: docker-compose.yml network configuration
# Fix: Verify network settings

docker inspect ClawSandbox | grep -A 20 NetworkSettings
```

### Scenario 3: Permission Denied
```bash
# Issue: Can't write to /tmp/results
# Cause: Filesystem is read-only or ownership issue
# Fix: Verify tmpfs mount

docker exec ClawSandbox mount | grep tmpfs
```

---

## Monitoring & Debugging

### Check Container Health

```bash
# View running processes
docker top ClawSandbox

# Check resource usage
docker stats ClawSandbox

# Inspect configuration
docker inspect ClawSandbox | jq '.HostConfig'

# View logs
docker logs ClawSandbox
```

### Debug Test Failures

```bash
# Verbose test execution
docker exec -it ClawSandbox bash -x /home/openclaw/tests/01-recon/recon.sh

# Check environment
docker exec ClawSandbox env | sort

# Verify security features
docker exec ClawSandbox grep Cap /proc/self/status
docker exec ClawSandbox mount | grep "read.only"
```

---

## Roadmap

### Current (v1.0)
- ✅ 8 security test categories
- ✅ 7 Docker security layers
- ✅ API testing support
- ✅ Helper CLI tools

### Future (v1.1+)
- 🔜 Custom test framework
- 🔜 Real-time monitoring dashboard
- 🔜 Integration with ClawFlow
- 🔜 Extended LLM provider support
- 🔜 Automated security scoring

---

## References

- [Docker Security](https://docs.docker.com/engine/security/)
- [Linux Capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Seccomp](https://docs.docker.com/engine/security/seccomp/)
- [OpenKrab Docs](https://docs.molt.bot)

---

<p align="center">🦞 ClawSandbox: Secure by Design 🔒</p>
