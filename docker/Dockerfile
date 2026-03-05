# ClawSandbox - Hardened Docker Sandbox for OpenKrab Skills Testing
# Based on Node.js 22-slim with 7 security layers

FROM node:22-slim

# Labels
LABEL maintainer="OpenKrab Security Team"
LABEL description="Hardened Docker sandbox for testing OpenKrab skill security"
LABEL version="1.0.0"

# Set working directory
WORKDIR /home/openclaw

# Update system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    git \
    bash \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user (UID 999) - SECURITY LAYER 1
RUN useradd -m -u 999 -s /bin/bash openclaw && \
    mkdir -p /home/openclaw/tests && \
    mkdir -p /home/openclaw/skills && \
    mkdir -p /home/openclaw/.config && \
    mkdir -p /tmp/results && \
    chown -R openclaw:openclaw /home/openclaw && \
    chown -R openclaw:openclaw /tmp/results

# Install OpenClaw CLI
RUN npm install -g @claw-ai/openclaw@latest

# Copy test scripts and setup utilities
COPY --chown=openclaw:openclaw tests/ /home/openclaw/tests/
COPY --chown=openclaw:openclaw scripts/ /home/openclaw/scripts/

# Make test scripts executable
RUN chmod +x /home/openclaw/tests/**/*.sh && \
    chmod +x /home/openclaw/scripts/*.sh

# Switch to non-root user
USER openclaw

# Set environment variables
ENV HOME=/home/openclaw \
    NODE_ENV=production \
    NODE_NO_WARNINGS=1 \
    PATH="/home/openclaw/.bin:$PATH"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD openclaw --version || exit 1

# Default command
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "cd /home/openclaw/tests && echo 'ClawSandbox ready. Run: ./run-all.sh'"]
