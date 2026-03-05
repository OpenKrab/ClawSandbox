# Contributing to ClawSandbox

Thank you for your interest in contributing to ClawSandbox! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and inclusive in all interactions. We're building a secure ecosystem for AI agents.

## Getting Started

1. **Fork the repository**
   ```bash
   # On GitHub: https://github.com/OpenKrab/ClawSandbox
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/ClawSandbox.git
   cd ClawSandbox
   ```

3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Adding New Test Categories

1. Create a new directory under `tests/`:
   ```bash
   mkdir -p tests/NN-your-test-name
   ```

2. Create test script with shebang and error handling:
   ```bash
   #!/bin/bash
   set -e
   
   RESULTS_FILE="/tmp/results/NN-your-test-name-results.txt"
   mkdir -p /tmp/results
   
   # Your tests here...
   ```

3. Make it executable:
   ```bash
   chmod +x tests/NN-your-test-name/*.sh
   ```

4. Update `tests/run-all.sh` to include your category

### Updating Docker Image

Edit `docker/Dockerfile`:
- Only add necessary tools
- Use minimal base image (node:22-slim)
- Clean up package lists: `apt-get clean && rm -rf /var/lib/apt/lists/*`
- Maintain non-root user `openclaw` (UID 999)

### Adding New Scripts

Place utility scripts in `scripts/`:
```bash
#!/bin/bash
# Add header comments explaining purpose

# Implementation...

# Make executable
chmod +x scripts/your-script.sh
```

## Testing Your Changes

### Local Testing

```bash
# Build image
cd docker
docker compose build

# Run all tests
docker compose up -d
docker exec -it ClawSandbox bash /home/openclaw/tests/run-all.sh

# Check results
docker exec ClawSandbox find /tmp/results -type f
```

### Test Coverage

- Aim for 80%+ test pass rate
- Cover both positive (passes) and negative (fails) cases
- Document expected behavior in comments

## Code Style Guidelines

### Bash Scripts

```bash
#!/bin/bash

# Use strict mode
set -e

# Comment significant sections
# Variable names: UPPER_CASE for constants, lower_case for variables

RESULTS_DIR="/tmp/results"
mkdir -p "$RESULTS_DIR"

# Functions with descriptive names
test_security_feature() {
  local test_name="$1"
  # Implementation
}

# Proper error handling
if ! command -v tool &> /dev/null; then
  echo "Error: tool not found"
  exit 1
fi
```

### Dockerfile

```dockerfile
# Comments explain each layer
FROM node:22-slim

# Group related operations
RUN apt-get update && apt-get install -y --no-install-recommends \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*

# Use labels
LABEL description="Clear description"
```

### Documentation (Markdown)

- Use clear headings
- Include code examples
- Link to related resources
- Keep lines <80 characters where possible

## Pull Request Process

1. **Update documentation**
   - Update README.md if needed
   - Add entries to SETUP.md if adding features
   - Include examples for new functionality

2. **Commit messages**
   ```
   feat: Add new test category for X
   fix: Correct permission check in dockerfile
   docs: Update SETUP instructions
   ```

3. **Create Pull Request**
   - Include description of changes
   - Reference related issues
   - Request review from maintainers

4. **Respond to feedback**
   - Be open to suggestions
   - Ask questions if unclear
   - Push additional commits to same branch

## Reporting Issues

When reporting issues, include:

1. **Environment**
   ```
   - Docker Desktop version
   - OS (macOS/Linux/Windows)
   - Docker Compose version
   ```

2. **Reproduction steps**
   ```
   1. Build image with `docker compose build`
   2. Start sandbox with `docker compose up -d`
   3. Run tests with `./run-all.sh`
   ```

3. **Expected vs actual behavior**
   - What should happen
   - What actually happened
   - Error messages

4. **Logs**
   ```bash
   docker logs ClawSandbox
   ```

## Security Considerations

- Never commit API keys or secrets
- Test security changes thoroughly
- Consider implications of every modification
- Security issues: email security@openkrab.dev instead of GitHub issues

## Maintenance

Regular maintenance tasks:

```bash
# Update base image
# Edit: docker/Dockerfile
# Review: Node.js LTS versions

# Update dependencies
# Update package.json if any

# Test on multiple platforms
# macOS, Linux, Windows (WSL2)
```

## Documentation Standards

Every feature should have:

1. **Code comments** - Explain the "why"
2. **README section** - User-facing documentation
3. **SETUP.md entry** - Integration guide
4. **Example** - Show how to use it

## Getting Help

- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Security**: security@openkrab.dev
- **Community**: Join OpenKrab Discord

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- GitHub releases
- Project documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see LICENSE file).

---

Thank you for helping make ClawSandbox better! 🦞🔒
