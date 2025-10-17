#!/bin/bash

set -e

# DevContainer configuration
IMAGE_NAME="ai-devcontainer"
CONTAINER_NAME="ai-devcontainer-shell"
DOCKERFILE_PATH=".devcontainer/Dockerfile"
WORKSPACE_DIR="/workspace"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "Error: $DOCKERFILE_PATH not found"
    exit 1
fi

# Check if image exists, if not build it
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo -e "${YELLOW}Building DevContainer image...${NC}"
    docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" .
    echo -e "${GREEN}Build complete!${NC}"
fi

# Get the absolute path of the current directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}Starting DevContainer shell...${NC}"
echo -e "${YELLOW}Project root: ${PROJECT_ROOT}${NC}"
echo ""

# Run the container interactively with zsh (fallback to sh if zsh not available)
docker run -it --rm \
    --name "$CONTAINER_NAME" \
    -v "$PROJECT_ROOT:$WORKSPACE_DIR" \
    -w "$WORKSPACE_DIR" \
    "$IMAGE_NAME" \
    sh -c "if command -v zsh > /dev/null; then zsh; else sh; fi"
