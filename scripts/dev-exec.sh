#!/bin/bash

set -e

# DevContainer configuration
IMAGE_NAME="ai-devcontainer"
DOCKERFILE_PATH=".devcontainer/Dockerfile"
WORKSPACE_DIR="/workspace"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if command is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No command provided${NC}"
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Examples:"
    echo "  $0 npm install"
    echo "  $0 node --version"
    echo "  $0 claude --help"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "Error: $DOCKERFILE_PATH not found"
    exit 1
fi

# Check if image exists, if not build it
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo -e "${YELLOW}Building DevContainer image...${NC}"
    docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" .
fi

# Get the absolute path of the current directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run the command in the container
docker run --rm \
    -v "$PROJECT_ROOT:$WORKSPACE_DIR" \
    -w "$WORKSPACE_DIR" \
    "$IMAGE_NAME" \
    sh -c "$*"
