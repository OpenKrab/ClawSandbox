# 🚀 ClawSandbox Quick Start

Get running in 5 minutes.

## Prerequisites (1 min)

```bash
# Check if Docker is installed
docker --version
docker compose --version

# Install if needed: https://www.docker.com/products/docker-desktop
```

## Build (5 min)

```bash
# Clone and enter repo
git clone https://github.com/OpenKrab/ClawSandbox.git
cd ClawSandbox

# Build Docker image
cd docker
docker compose build
cd ..
```

## Run Tests (2 min)

```bash
# Start sandbox
cd docker
docker compose up -d

# Enter container
docker exec -it ClawSandbox bash

# Run all tests
cd /home/openclaw/tests
./run-all.sh

# View results
cat /tmp/results/*.txt
```

## View Results (1 min)

```bash
# From another terminal, copy results to host
docker cp ClawSandbox:/tmp/results ./local-results

# Read results
cat local-results/*.txt
```

## Stop (1 min)

```bash
docker compose down
```

---

## Next Steps

- **Full Guide**: See [SETUP.md](SETUP.md)
- **Configuration**: See [README.md](README.md)
- **Help**: Run `./scripts/sandbox-cli.sh` for commands
- **API Testing**: See SETUP.md section "API Configuration"
- **Custom Skills**: See SETUP.md section "Testing Custom Skills"

---

## Cheat Sheet

```bash
# Using helper script
./scripts/sandbox-cli.sh build              # Build image
./scripts/sandbox-cli.sh start              # Start sandbox
./scripts/sandbox-cli.sh enter              # Enter shell
./scripts/sandbox-cli.sh test               # Run all tests
./scripts/sandbox-cli.sh test-category recon  # Run specific test
./scripts/sandbox-cli.sh results            # Show results
./scripts/sandbox-cli.sh stop               # Stop sandbox

# Manual commands
docker compose up -d                        # Start
docker exec -it ClawSandbox bash            # Enter
docker logs -f ClawSandbox                  # View logs
docker compose down                         # Stop
docker cp ClawSandbox:/tmp/results ./local-results  # Copy results
```

---

**Questions?** Check [SETUP.md](SETUP.md) or open an issue! 🦞🔒
