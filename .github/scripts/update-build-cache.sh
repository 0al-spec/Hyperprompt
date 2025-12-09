#!/bin/bash
#
# Update build cache for Hyperprompt project
#
# This script updates the build cache when dependencies change.
# Run this after modifying Package.swift or Package.resolved.
#
# Usage:
#   ./update-build-cache.sh [cache-name]
#
# Example:
#   ./update-build-cache.sh
#   ./update-build-cache.sh swift-build-cache-linux-x86_64
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default cache name
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
CACHE_NAME="${1:-swift-build-cache-${OS}-${ARCH}}"
CACHE_DIR="${BUILD_CACHE_DIR:-.build-cache}"

echo -e "${BLUE}=== Build Cache Update ===${NC}"
echo ""

# Step 1: Check if cache exists
if [ -f "${CACHE_DIR}/${CACHE_NAME}.tar.gz" ]; then
    CACHE_DATE=$(stat -f "%Sm" "${CACHE_DIR}/${CACHE_NAME}.tar.gz" 2>/dev/null || stat -c %y "${CACHE_DIR}/${CACHE_NAME}.tar.gz" 2>/dev/null)
    CACHE_SIZE=$(du -sh "${CACHE_DIR}/${CACHE_NAME}.tar.gz" | cut -f1)
    echo -e "${YELLOW}Existing cache found:${NC}"
    echo "  File: ${CACHE_DIR}/${CACHE_NAME}.tar.gz"
    echo "  Size: ${CACHE_SIZE}"
    echo "  Date: ${CACHE_DATE}"
    echo ""
fi

# Step 2: Clean and rebuild
echo -e "${YELLOW}Step 1: Cleaning build directory...${NC}"
swift package clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

echo -e "${YELLOW}Step 2: Rebuilding from scratch...${NC}"
START_TIME=$(date +%s)
swift build
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
echo -e "${GREEN}✓ Build complete (${BUILD_TIME}s)${NC}"
echo ""

# Step 3: Run tests to ensure everything works
echo -e "${YELLOW}Step 3: Running tests to verify build...${NC}"
swift test --filter ManifestGeneratorTests >/dev/null 2>&1 || {
    echo -e "${RED}✗ Tests failed${NC}"
    echo "Fix issues before updating cache"
    exit 1
}
echo -e "${GREEN}✓ Tests passed${NC}"
echo ""

# Step 4: Create new cache
echo -e "${YELLOW}Step 4: Creating updated cache...${NC}"
./.github/scripts/create-build-cache.sh "$CACHE_NAME"
echo -e "${GREEN}✓ Cache updated${NC}"
echo ""

# Step 5: Show cache info
NEW_CACHE_SIZE=$(du -sh "${CACHE_DIR}/${CACHE_NAME}.tar.gz" | cut -f1)
echo -e "${BLUE}=== Update Complete ===${NC}"
echo "  Cache: ${CACHE_DIR}/${CACHE_NAME}.tar.gz"
echo "  Size: ${NEW_CACHE_SIZE}"
echo "  Build time: ${BUILD_TIME}s"
echo ""
echo "To distribute this cache:"
echo "  1. Commit ${CACHE_DIR}/${CACHE_NAME}.tar.gz to Git LFS (if configured)"
echo "  2. Or upload to a shared location for team access"
echo "  3. Or store in CI/CD artifacts"
