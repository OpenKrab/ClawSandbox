# ClawSandbox Full Setup Guide

> Complete implementation guide for **ClawSandbox v1.0** for OpenKrab  
> Hardened Docker sandbox for testing AI agent security before ClawHub publication

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Building the Image](#building-the-image)
4. [Running Tests](#running-tests)
5. [API Configuration](#api-configuration)
6. [Customization](#customization)
7. [Results & Analysis](#results--analysis)
8. [ClawFlow Integration](#clawflow-integration)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required
- **Docker Desktop** (v20.10+) with Compose v2.0+
  - macOS: [Download](https://www.docker.com/products/docker-desktop/)
  - Windows: WSL 2 backend recommended
  - Linux: `docker-ce` + `docker-compose`

- **Git** (v2.30+)
  - macOS: `brew install git`
  - Ubuntu/Debian: `apt-get install git`
  - Windows: [Git for Windows](https://git-scm.com/download/win)

### Optional
- API keys for LLM testing (setup after installation):
  - **Google Gemini**: https://aistudio.google.com/apikey
  - **OpenAI**: https://platform.openai.com/account/api-keys
  - **Anthropic**: https://console.anthropic.com/account/keys

---

## Installation

### Step 1: Clone the Repository

```bash
# Clone OpenKrab's ClawSandbox fork
git clone https://github.com/OpenKrab/ClawSandbox.git
cd ClawSandbox
```

### Step 2: Verify Directory Structure

```bash
# Should see:
ls -la
# docker/
# tests/
# scripts/
# README.md
```

---

## Building the Image

### Option A: Using Docker Compose (Recommended)

```bash
cd docker
docker compose build
```

**Build output** (~5-10 min on first run):
- Downloads `node:22-slim` base image
- Installs utilities (curl, git, jq, etc.)
- Creates non-root user `openclaw`
- Installs OpenClaw CLI
- Sets up security hardening

### Option B: Using Manual Docker Build

```bash
cd docker
docker build -t clawsandbox_clawsandbox:latest .
```

### Verify Build Success

```bash
docker images | grep clawsandbox_clawsandbox
# Should show: clawsandbox_clawsandbox   latest   <IMAGE_ID>   <SIZE>
```

---

## Running Tests

### Quick Start: All Tests

```bash
# Start the sandbox
cd docker
docker compose up -d

# Enter the container
docker exec -it ClawSandbox bash

# Run all 8 test categories
cd /home/openclaw/tests
./run-all.sh
```

**Expected output**:
```
═══════════════════════════════════════════════════════
  ClawSandbox - Security Benchmark Test Suite
═══════════════════════════════════════════════════════

[HH:MM:SS] Running: Reconnaissance
✓ PASSED: Reconnaissance
...
═══════════════════════════════════════════════════════
  Results Summary
═══════════════════════════════════════════════════════
Total Tests: 8
Passed: 7-8
Failed: 0-1
Success Rate: 87-100%
```

### Run Individual Test Categories

```bash
# Inside container (/home/openclaw/tests)
./01-recon/recon.sh
./02-privilege-escalation/privesc.sh
./03-data-exfiltration/exfil.sh
./04-prompt-injection/run-via-openclaw.sh
./05-general-audit/audit.sh
./06-network-security/network.sh
./07-file-integrity/integrity.sh
./08-memory-poisoning/memory-poison-offline.sh
```

### Using Helper Script (Recommended)

From the host machine:

```bash
# Make script executable
chmod +x scripts/sandbox-cli.sh

# Run all tests
./scripts/sandbox-cli.sh test

# Run specific category
./scripts/sandbox-cli.sh test-category recon

# View results
./scripts/sandbox-cli.sh results
```

---

## API Configuration

### Configure LLM API Keys

The sandbox supports testing with live LLM APIs. To enable:

#### Step 1: Set Up API Key

```bash
# Inside container
bash scripts/setup-api-key.sh gemini "YOUR_GEMINI_API_KEY"
# or
bash scripts/setup-api-key.sh openai "YOUR_OPENAI_API_KEY"
```

#### Step 2: Enable Internet Mode

By default, the sandbox runs in **isolated mode** (no outbound network). To test with APIs:

1. Edit `docker/docker-compose.yml`
2. Modify the `networks` section to enable outbound:
   ```yaml
   networks:
     clawsandbox-isolated:
       driver: bridge
   ```

3. Restart the container:
   ```bash
   docker compose down
   docker compose up -d
   ```

#### Step 3: Run API Tests

```bash
# Inside container
./08-memory-poisoning/memory-poison-api.sh
./04-prompt-injection/run-via-openclaw.sh  # With API
```

### Secure API Key Storage

Keys are stored in `~/.clawsandbox-secrets/` with restricted permissions:
- File permissions: `600` (owner read/write only)
- Directory permissions: `700` (owner-only access)
- Never committed to git

---

## Customization

### Testing Custom Skills

Mount your skill into the sandbox:

#### Step 1: Update docker-compose.yml

```yaml
# docker/docker-compose.yml
volumes:
  # ... existing volumes ...
  - ../src/skills/your-skill:/home/openclaw/skills/your-skill
```

#### Step 2: Rebuild and Restart

```bash
docker compose down
docker compose build
docker compose up -d
```

#### Step 3: Run Relevant Tests

```bash
# For memory-aware skills
docker exec -it ClawSandbox bash /home/openclaw/tests/08-memory-poisoning/memory-poison-offline.sh

# For prompt injection vulnerable skills
docker exec -it ClawSandbox bash /home/openclaw/tests/04-prompt-injection/run-via-openclaw.sh
```

### Customizing Test Scripts

Edit individual test files to add skill-specific checks:

```bash
# Example: tests/04-prompt-injection/run-via-openclaw.sh
SYSTEM_PROMPT="You are a Krab agent from OpenKrab ecosystem..."
# Add custom injection tests for your skill
```

### Integrating with Krab

Replace OpenClaw references with Krab:

1. In `docker/Dockerfile`:
   ```dockerfile
   # Install Krab CLI instead of OpenClaw
   RUN npm install -g @openkrab/krab@latest
   ```

2. In test scripts, update prompts:
   ```bash
   AGENT_CLI="krab"  # instead of "openclaw"
   ```

---

## Results & Analysis

### View Test Results

#### Inside Container

```bash
# Find all result files
find /tmp/results -type f -name "*.txt"

# View specific category results
cat /tmp/results/01-recon-results.txt
```

#### Copy to Host

```bash
# From host machine
docker cp ClawSandbox:/tmp/results ./local-results
cat local-results/*.txt
```

### Interpreting Results

#### Success Metrics

| Test | Pass Threshold | What It Tests |
|------|----------------|---------------|
| Reconnaissance | 5/5 | System info doesn't leak |
| Privilege Escalation | 5/5 | Can't escalate privileges |
| Data Exfiltration | 5/5 | Network isolation holds |
| Prompt Injection | 4/5 | API/input handling secure |
| General Audit | 5/7 | Container hardening intact |
| Network Security | 5/6 | Network restrictions work |
| File Integrity | 5/7 | Filesystem permissions OK |
| Memory Poisoning | 5/7 | Process isolation effective |

#### Example Result Output

```
=== Reconnaissance Security Tests ===
Test 1: Information Disclosure (/etc/passwd)... PASS
Test 2: /sys filesystem access... PASS
Test 3: Hostname modification prevention... PASS
Test 4: Environment variable isolation... PASS
Test 5: Process namespace isolation... PASS

Summary: 5/5 tests passed
```

### Creating Custom Reports

```bash
#!/bin/bash
# Create markdown report
{
  echo "# ClawSandbox Security Report"
  echo "## Date: $(date)"
  echo ""
  
  for test in /tmp/results/*.txt; do
    echo "## $(basename $test)"
    cat "$test"
    echo ""
  done
} > security-report.md
```

---

## ClawFlow Integration

Add ClawSandbox as a security gate in ClawFlow:

### Step 1: Create ClawFlow Task

```yaml
# your-clawflow.yml
tasks:
  - name: Security Test
    run: |
      docker compose -f docker/docker-compose.yml up -d
      docker exec ClawSandbox bash /home/openclaw/tests/run-all.sh
      docker cp ClawSandbox:/tmp/results ./results
      docker compose down
```

### Step 2: Gate Skill Publication

```yaml
# Gate publication on test success
if-success:
  - publish-to-clawdhub
  - add-security-badge
  
if-fail:
  - block-publication
  - report-vulnerabilities
```

### Step 3: Add Badge to Skill

```markdown
[![ClawSandbox Passed](https://img.shields.io/badge/ClawSandbox-Passed-green)]()
```

---

## Troubleshooting

### Issue: "Docker daemon not running"

**Solution**:
```bash
# macOS
open /Applications/Docker.app

# Linux
sudo systemctl start docker

# Windows
Start Docker Desktop app
```

### Issue: "Cannot connect to Docker daemon"

**Solution** (Linux):
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: "Permission denied while building"

**Solution**:
```bash
# Ensure proper file permissions
chmod +x docker/Dockerfile
chmod +x tests/**/*.sh
chmod +x scripts/*.sh
```

### Issue: "No space left on device"

**Solution**:
```bash
# Clean up old images and containers
docker system prune -a
docker volume prune

# Check disk space
df -h
```

### Issue: "Tests timing out"

**Solution**:
```bash
# Increase timeout in run-all.sh
# or run individual tests with more time
timeout 120 ./01-recon/recon.sh
```

### Issue: "OpenClaw not found in container"

**Solution**:
```bash
# Verify installation
docker exec ClawSandbox openclaw --version

# If missing, rebuild
docker compose build --no-cache
```

### Issue: "API keys not working"

**Solution**:
```bash
# Verify keys are set
docker exec ClawSandbox env | grep API_KEY

# Re-set using script
docker exec -it ClawSandbox bash scripts/setup-api-key.sh gemini "YOUR_KEY"

# Enable internet mode (see API Configuration section)
```

### Debug Mode

Run container with verbose logging:

```bash
docker compose logs -f ClawSandbox
```

Enter debug shell:

```bash
docker exec -it ClawSandbox bash -x /home/openclaw/tests/run-all.sh
```

---

## Architecture Overview

```
ClawSandbox Container (node:22-slim)
│
├── User: openclaw (UID 999, non-root)
├── Capabilities: NONE (all dropped)
├── Filesystem: read-only root + tmpfs
│
├── Security Layers (7 total):
│   ├── Non-root user execution
│   ├── Dropped Linux capabilities
│   ├── Read-only root filesystem
│   ├── no-new-privileges flag
│   ├── Resource limits (2 CPU, 2GB RAM)
│   ├── Network isolation (default)
│   └── Named volumes only (no host mounts)
│
└── Test Suite (8 categories):
    ├── 01-recon (System information leakage)
    ├── 02-privilege-escalation (Privilege abuse)
    ├── 03-data-exfiltration (Data exfil prevention)
    ├── 04-prompt-injection (AI agent robustness)
    ├── 05-general-audit (Comprehensive audit)
    ├── 06-network-security (Network isolation)
    ├── 07-file-integrity (Filesystem protections)
    └── 08-memory-poisoning (Memory corruption)
```

---

## Next Steps

1. **Run your first test suite**: `./scripts/sandbox-cli.sh test`
2. **Test your skill**: Configure custom skill mounting
3. **Set up API testing**: Configure LLM API keys (optional)
4. **Integrate with ClawFlow**: Add security gates to your pipeline
5. **Publish to ClawHub**: Add security badge when all tests pass

---

## Support & Contributing

- **Issues**: [GitHub Issues](https://github.com/OpenKrab/ClawSandbox/issues)
- **Documentation**: https://docs.molt.bot/clawsandbox
- **Original Repo**: [deduu/ClawSandbox](https://github.com/deduu/ClawSandbox)

---

<p align="center">🦞 <strong>Secure Your Krab Skills with ClawSandbox</strong> 🔒</p>
