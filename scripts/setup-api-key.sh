#!/bin/bash

# Setup API Key Script
# Securely configure API keys for LLM testing in ClawSandbox

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SECRETS_DIR="$HOME/.clawsandbox-secrets"
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

# Function to set API key securely
setup_key() {
  local provider=$1
  local key=$2
  
  case "$provider" in
    gemini)
      echo -n "$key" > "$SECRETS_DIR/gemini.key"
      chmod 600 "$SECRETS_DIR/gemini.key"
      echo -e "${GREEN}✓${NC} GEMINI_API_KEY configured"
      echo "export GEMINI_API_KEY=\"$key\"" >> ~/.bashrc
      export GEMINI_API_KEY="$key"
      ;;
    openai)
      echo -n "$key" > "$SECRETS_DIR/openai.key"
      chmod 600 "$SECRETS_DIR/openai.key"
      echo -e "${GREEN}✓${NC} OPENAI_API_KEY configured"
      echo "export OPENAI_API_KEY=\"$key\"" >> ~/.bashrc
      export OPENAI_API_KEY="$key"
      ;;
    anthropic)
      echo -n "$key" > "$SECRETS_DIR/anthropic.key"
      chmod 600 "$SECRETS_DIR/anthropic.key"
      echo -e "${GREEN}✓${NC} ANTHROPIC_API_KEY configured"
      echo "export ANTHROPIC_API_KEY=\"$key\"" >> ~/.bashrc
      export ANTHROPIC_API_KEY="$key"
      ;;
    *)
      echo -e "${RED}✗${NC} Unknown provider: $provider"
      echo "Supported: gemini, openai, anthropic"
      exit 1
      ;;
  esac
}

# Function to load API keys from storage
load_keys() {
  if [ -f "$SECRETS_DIR/gemini.key" ]; then
    export GEMINI_API_KEY=$(cat "$SECRETS_DIR/gemini.key")
  fi
  if [ -f "$SECRETS_DIR/openai.key" ]; then
    export OPENAI_API_KEY=$(cat "$SECRETS_DIR/openai.key")
  fi
  if [ -f "$SECRETS_DIR/anthropic.key" ]; then
    export ANTHROPIC_API_KEY=$(cat "$SECRETS_DIR/anthropic.key")
  fi
}

# Function to show usage
usage() {
  cat << EOF
${YELLOW}ClawSandbox API Key Setup${NC}

Usage:
  $(basename $0) <provider> [api-key]
  $(basename $0) load
  $(basename $0) list
  $(basename $0) unset <provider>

Providers:
  - gemini    (Google Gemini API)
  - openai    (OpenAI API)
  - anthropic (Anthropic API)

Examples:
  # Set Gemini API key
  $(basename $0) gemini "your-gemini-key-here"
  
  # Load all configured keys
  $(basename $0) load
  
  # List configured providers
  $(basename $0) list
  
  # Remove OpenAI key
  $(basename $0) unset openai

EOF
}

# Main logic
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

case "$1" in
  load)
    load_keys
    echo -e "${GREEN}✓${NC} API keys loaded"
    ;;
  list)
    echo -e "${YELLOW}Configured API Keys:${NC}"
    [ -f "$SECRETS_DIR/gemini.key" ] && echo "  • GEMINI_API_KEY"
    [ -f "$SECRETS_DIR/openai.key" ] && echo "  • OPENAI_API_KEY"
    [ -f "$SECRETS_DIR/anthropic.key" ] && echo "  • ANTHROPIC_API_KEY"
    ;;
  unset)
    if [ -z "$2" ]; then
      echo -e "${RED}✗${NC} Provider not specified"
      exit 1
    fi
    case "$2" in
      gemini|openai|anthropic)
        rm -f "$SECRETS_DIR/$2.key"
        echo -e "${GREEN}✓${NC} $2 key removed"
        ;;
      *)
        echo -e "${RED}✗${NC} Unknown provider: $2"
        exit 1
        ;;
    esac
    ;;
  *)
    if [ -z "$2" ]; then
      echo -e "${RED}✗${NC} API key not provided"
      echo "Usage: $(basename $0) <provider> <api-key>"
      exit 1
    fi
    setup_key "$1" "$2"
    ;;
esac
