# ClawSandbox for OpenKrab – Secure Benchmark for Krab Skills & Agents 🦞🔒

> Hardened Docker sandbox สำหรับ test security ของ skill OpenKrab ก่อนใช้งานจริง  
> A hardened Docker sandbox for testing OpenKrab skill security before production deployment.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![Security](https://img.shields.io/badge/Security-Hardened-green)](https://github.com/OpenKrab/ClawSandbox)
[![OpenKrab](https://img.shields.io/badge/OpenKrab-Ecosystem-orange)](https://github.com/OpenKrab)

## 🎯 Overview

ClawSandbox is a security-focused testing environment forked from [deduu/ClawSandbox](https://github.com/deduu/ClawSandbox) and customized for the **OpenKrab** ecosystem. It provides:

- **8 Security Benchmark Categories** for comprehensive AI agent testing
- **Docker Hardening** with 7 security layers
- **Local-First Testing** before publishing to ClawHub
- **ClawFlow Integration** for automated security pipelines

---

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (latest version, Compose enabled)
- [Git](https://git-scm.com/)
- (Optional) API keys for LLM testing (Gemini, OpenAI, Ollama)

### Installation

```bash
# Clone the repository
git clone https://github.com/OpenKrab/ClawSandbox.git
cd ClawSandbox

# Build the hardened Docker image
cd docker
docker compose build

# Start the sandbox (isolated mode)
docker compose up -d
```

---

## 🧪 Running Benchmark Tests

### Enter the Container

```bash
docker exec -it ClawSandbox bash
```

### Run All Automated Tests

```bash
cd /home/openclaw/tests
./run-all.sh
```

### Run Specific Categories

| Category | Command |
|----------|---------|
| Reconnaissance | `./01-recon/recon.sh` |
| Privilege Escalation | `./02-privilege-escalation/privesc.sh` |
| Data Exfiltration | `./03-data-exfiltration/exfil.sh` |
| Prompt Injection | See below |
| General Audit | `./05-general-audit/audit.sh` |
| Memory Poisoning (Offline) | `./08-memory-poisoning/memory-poison-offline.sh` |

### Prompt Injection Tests (AI Agent Security)

1. Set up your API key:
   ```bash
   export GEMINI_API_KEY="your-key-here"
   # OR
   scripts/setup-api-key.sh gemini YOUR_KEY
   ```

2. Run the test:
   ```bash
   bash /home/openclaw/tests/04-prompt-injection/run-via-openclaw.sh
   ```

### Memory Poisoning (API Mode - requires internet)

```bash
# Enable internet mode in docker-compose.yml first
bash /home/openclaw/tests/08-memory-poisoning/memory-poison-api.sh
```

---

## 🛡️ Security Layers

ClawSandbox implements **7 security layers** by default:

1. **Non-root user** - Runs as `openclaw` (UID 999)
2. **Drop all Linux capabilities** - Minimal privileges
3. **Read-only root FS** + tmpfs for writable directories
4. **No new privileges** - Prevents privilege escalation
5. **Resource limits** - 2 CPU cores / 2GB RAM
6. **Isolated network** - No outbound connections by default
7. **No host mounts** - Named volumes only

---

## 📊 Viewing Results

Results are stored in `/tmp/results/` (tmpfs, cleared on restart):

```bash
# Inside container
find /tmp/results -type f

# Copy to host
docker cp ClawSandbox:/tmp/results ./local-results
```

Results show attack success/failure rates (e.g., "7/9 tests passed").

---

## 🔧 Customization for OpenKrab

### 1. Integrate with Krab Agent

Edit `tests/04-prompt-injection/run-via-openclaw.sh` to:
- Point API calls to Krab CLI or gateway
- Update system prompts to match Krab:
  ```bash
  SYSTEM_PROMPT="You are Krab agent from OpenKrab..."
  ```

### 2. Test Specific Skills

Mount your skill into the container:

```yaml
# docker/docker-compose.yml
volumes:
  - ../your-skill-folder:/home/openclaw/skills/claw-graph
```

Then run relevant tests (e.g., memory poisoning for ClawMemory skills).

### 3. ClawFlow Integration

Add to your ClawFlow:

```bash
clawflow security-test <skill-name>
```

This will:
1. Spin up ClawSandbox container
2. Install the skill
3. Run subset tests (recon + prompt injection)
4. Return security report

---

## 🧹 Cleanup

```bash
# Stop and remove containers
docker compose down

# Remove image (for fresh start)
docker rmi clawsandbox_clawsandbox
```

---

## 🔐 Best Practices

- **Run on isolated VM** - Use Clawbox for macOS or a separate VPS
- **Use frontier models** - Test with Claude 4, Gemini 3+ for realistic results
- **Badge your skills** - Add "Passed ClawSandbox" badge to ClawHub listings
- **Regular testing** - Re-run benchmarks after skill updates

---

## 📁 Project Structure

```
ClawSandbox/
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── .dockerignore
├── tests/
│   ├── 01-recon/
│   ├── 02-privilege-escalation/
│   ├── 03-data-exfiltration/
│   ├── 04-prompt-injection/
│   ├── 05-general-audit/
│   ├── 06-network-security/
│   ├── 07-file-integrity/
│   ├── 08-memory-poisoning/
│   └── run-all.sh
├── scripts/
│   └── setup-api-key.sh
├── results/          # Local results storage
└── README.md
```

---

## 🤝 Contributing

This project is forked from [deduu/ClawSandbox](https://github.com/deduu/ClawSandbox) and customized for the OpenKrab ecosystem.

---

## 📜 License

MIT License - See LICENSE file for details.

---

## 🔗 Links

- [OpenKrab Organization](https://github.com/OpenKrab)
- [Original ClawSandbox](https://github.com/deduu/ClawSandbox)
- [ClawHub](https://clawhub.example) (Skill Registry)
- [ClawFlow](https://clawflow.example) (Automation Platform)

---

<p align="center">🦞 <strong>Secure Your Krab Skills with ClawSandbox</strong> 🔒</p>
