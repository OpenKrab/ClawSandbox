#!/bin/bash

# ClawSandbox Helper Utilities
# Common commands for sandbox management

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
  cat << EOF
${BLUE}ClawSandbox Helper Utilities${NC}

Usage:
  $(basename $0) <command> [options]

Commands:
  build               Build the Docker image
  start               Start sandbox in isolated mode
  start-internet      Start sandbox with internet access
  stop                Stop the sandbox
  enter               Open interactive shell in sandbox
  logs                View sandbox logs
  results             Show test results
  clean               Remove containers and images
  status              Show sandbox status
  test                Run all tests
  test-category       Run specific test category

Examples:
  # Build image
  $(basename $0) build
  
  # Start sandbox
  $(basename $0) start
  
  # Run tests
  $(basename $0) test
  
  # View results
  $(basename $0) results
  
  # Run specific test
  $(basename $0) test-category recon

EOF
}

# Build image
build_image() {
  echo -e "${BLUE}Building ClawSandbox image...${NC}"
  cd docker
  docker compose build
  cd -
  echo -e "${GREEN}✓${NC} Image built successfully"
}

# Start sandbox (isolated)
start_sandbox() {
  echo -e "${BLUE}Starting ClawSandbox (isolated mode)...${NC}"
  cd docker
  docker compose up -d
  cd -
  echo -e "${GREEN}✓${NC} Sandbox started"
  sleep 2
  docker exec -it ClawSandbox bash -c 'echo "Ready for testing"'
}

# Start with internet
start_internet() {
  echo -e "${YELLOW}Warning: Starting with internet access${NC}"
  echo -e "This disables network isolation. Be cautious!${NC}"
  echo ""
  echo "To properly enable internet mode, you need to:"
  echo "1. Edit docker/docker-compose.yml"
  echo "2. Change network configuration"
  echo "3. Restart container"
  echo ""
  # For now, just start as-is
  cd docker
  docker compose down
  docker compose up -d
  cd -
  echo -e "${GREEN}✓${NC} Sandbox started (check docker-compose.yml for network settings)"
}

# Stop sandbox
stop_sandbox() {
  echo -e "${BLUE}Stopping ClawSandbox...${NC}"
  cd docker
  docker compose down
  cd -
  echo -e "${GREEN}✓${NC} Sandbox stopped"
}

# Enter sandbox shell
enter_sandbox() {
  docker exec -it ClawSandbox bash
}

# Show container logs
show_logs() {
  docker logs -f ClawSandbox
}

# Show test results
show_results() {
  echo -e "${BLUE}Test Results:${NC}"
  echo ""
  docker exec ClawSandbox bash -c 'find /tmp/results -type f -name "*.txt" -exec echo "=== {} ===" \; -exec cat {} \; -exec echo "" \;'
}

# Copy results to host
copy_results() {
  echo -e "${BLUE}Copying results to ./local-results...${NC}"
  docker cp ClawSandbox:/tmp/results ./local-results 2>/dev/null || echo "No results yet"
  echo -e "${GREEN}✓${NC} Results copied"
}

# Clean up
clean_sandbox() {
  echo -e "${YELLOW}⚠ Cleaning up containers and images...${NC}"
  cd docker
  docker compose down -v
  docker rmi clawsandbox_clawsandbox 2>/dev/null || true
  cd -
  echo -e "${GREEN}✓${NC} Cleanup complete"
}

# Show status
show_status() {
  echo -e "${BLUE}ClawSandbox Status:${NC}"
  if docker ps | grep -q ClawSandbox; then
    echo -e "${GREEN}✓${NC} Running"
    docker ps | grep ClawSandbox
  else
    echo -e "${YELLOW}○${NC} Stopped"
  fi
  echo ""
  echo -e "${BLUE}Image Status:${NC}"
  if docker images | grep -q clawsandbox_clawsandbox; then
    docker images | grep clawsandbox_clawsandbox
  else
    echo "Image not built yet"
  fi
}

# Run all tests
run_tests() {
  echo -e "${BLUE}Running ClawSandbox benchmark tests...${NC}"
  docker exec ClawSandbox bash /home/openclaw/tests/run-all.sh
}

# Run specific test category
run_test_category() {
  category=$1
  case $category in
    recon)
      docker exec ClawSandbox bash /home/openclaw/tests/01-recon/recon.sh
      ;;
    privesc)
      docker exec ClawSandbox bash /home/openclaw/tests/02-privilege-escalation/privesc.sh
      ;;
    exfil)
      docker exec ClawSandbox bash /home/openclaw/tests/03-data-exfiltration/exfil.sh
      ;;
    injection)
      docker exec ClawSandbox bash /home/openclaw/tests/04-prompt-injection/run-via-openclaw.sh
      ;;
    audit)
      docker exec ClawSandbox bash /home/openclaw/tests/05-general-audit/audit.sh
      ;;
    network)
      docker exec ClawSandbox bash /home/openclaw/tests/06-network-security/network.sh
      ;;
    integrity)
      docker exec ClawSandbox bash /home/openclaw/tests/07-file-integrity/integrity.sh
      ;;
    memory-offline)
      docker exec ClawSandbox bash /home/openclaw/tests/08-memory-poisoning/memory-poison-offline.sh
      ;;
    memory-api)
      docker exec ClawSandbox bash /home/openclaw/tests/08-memory-poisoning/memory-poison-api.sh
      ;;
    *)
      echo -e "${RED}✗${NC} Unknown category: $category"
      echo "Available: recon, privesc, exfil, injection, audit, network, integrity, memory-offline, memory-api"
      exit 1
      ;;
  esac
}

# Main
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  build)
    build_image
    ;;
  start)
    start_sandbox
    ;;
  start-internet)
    start_internet
    ;;
  stop)
    stop_sandbox
    ;;
  enter)
    enter_sandbox
    ;;
  logs)
    show_logs
    ;;
  results)
    show_results
    copy_results
    ;;
  status)
    show_status
    ;;
  clean)
    clean_sandbox
    ;;
  test)
    run_tests
    ;;
  test-category)
    if [ -z "$2" ]; then
      echo -e "${RED}✗${NC} Specify test category"
      exit 1
    fi
    run_test_category "$2"
    ;;
  *)
    echo -e "${RED}✗${NC} Unknown command: $1"
    usage
    exit 1
    ;;
esac
