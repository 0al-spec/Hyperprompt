#!/bin/bash
#
# Restore build cache for Hyperprompt project
#
# This script restores a previously created build cache to speed up compilation.
#
# Usage:
#   ./restore-build-cache.sh [cache-file]
#
# Example:
#   ./restore-build-cache.sh swift-build-cache-linux-x86_64.tar.gz
#   ./restore-build-cache.sh .build-cache/swift-build-cache-linux-x86_64.tar.gz
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Determine cache file
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
CACHE_DIR="${BUILD_CACHE_DIR:-.build-cache}"
DEFAULT_CACHE="${CACHE_DIR}/swift-build-cache-${OS}-${ARCH}.tar.gz"
CACHE_FILE="${1:-$DEFAULT_CACHE}"

echo -e "${GREEN}Restoring build cache...${NC}"
echo "  Cache file: ${CACHE_FILE}"

# Check if cache file exists
if [ ! -f "$CACHE_FILE" ]; then
    echo -e "${RED}Error: Cache file not found: ${CACHE_FILE}${NC}"
    echo ""
    echo "Available caches in ${CACHE_DIR}:"
    ls -lh "${CACHE_DIR}"/*.tar.gz 2>/dev/null || echo "  (none)"
    echo ""
    echo "To create a cache, run:"
    echo "  swift build"
    echo "  ./.github/scripts/create-build-cache.sh"
    exit 1
fi

# Check if .build already exists
if [ -d ".build" ]; then
    echo -e "${YELLOW}Warning: .build directory already exists${NC}"
    read -p "Do you want to overwrite it? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    echo "Removing existing .build directory..."
    rm -rf .build
fi

# Extract cache
echo -e "${YELLOW}Extracting cache...${NC}"
tar -xzf "$CACHE_FILE"

if [ -d ".build" ]; then
    BUILD_SIZE=$(du -sh .build | cut -f1)
    echo -e "${GREEN}Cache restored successfully!${NC}"
    echo "  Build directory size: ${BUILD_SIZE}"
    echo ""
    echo "Next steps:"
    echo "  Run: swift build"
    echo "  Expected time: 5-10 seconds (vs 82s without cache)"
else
    echo -e "${RED}Error: Failed to restore cache${NC}"
    exit 1
fi
