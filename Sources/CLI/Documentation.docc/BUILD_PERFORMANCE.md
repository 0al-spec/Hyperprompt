# Build Performance Analysis & Optimization Guide

**Date:** 2025-12-09
**Project:** Hyperprompt v0.1
**Environment:** x86_64-unknown-linux-gnu, Swift 6.2-dev

---

## Executive Summary

**Current Build Performance:**
- Full clean build: **~82 seconds** (1m 22s)
- Incremental build: **~5-10 seconds**
- Build artifacts size: **480 MB**

**Main Bottleneck:** swift-crypto dependency compiles **366 files** (123 assembly + 243 C++) on every clean build, accounting for ~60-70% of total build time.

---

## Build Time Breakdown

### Dependency Compilation Analysis

| Dependency | Files | Size | Estimated Build Time |
|------------|-------|------|---------------------|
| **swift-crypto** | ~366 (assembly + C++) | 32 MB | **~50-60 seconds** (60-70%) |
| swift-syntax | Swift | 8.5 MB | ~10-15 seconds (12-18%) |
| swift-argument-parser | Swift | 1.9 MB | ~3-5 seconds (4-6%) |
| swift-asn1 | Swift | 972 KB | ~2-3 seconds (2-4%) |
| SpecificationCore | Swift | 337 KB | ~1-2 seconds (1-2%) |
| **Hyperprompt (own code)** | Swift | - | ~5-8 seconds (6-10%) |

**Total:** ~82 seconds

### Why swift-crypto is Slow

1. **BoringSSL Integration**: 243 C++ files from Google's BoringSSL
2. **Platform-specific Assembly**: 123 assembly files (.S) for optimized crypto operations
   - Multiple architectures: x86_64, ARM, ARMv7, ARMv8
   - Multiple platforms: Linux, Apple, Windows
3. **No Pre-compilation**: SPM compiles from source every time
4. **C/C++ Build**: Slower than Swift compilation

---

## Optimization Strategies

### Strategy 1: Use Pre-built Binary Dependencies ⭐ **RECOMMENDED**

**Approach:** Cache compiled `.build` directory

**Implementation:**

1. **Create `.build` cache after first successful build**
   ```bash
   # After first successful build
   tar -czf swift-build-cache.tar.gz .build/
   ```

2. **Store outside the repository**
   ```bash
   mkdir -p .build-cache
   tar -czf .build-cache/swift-build-cache-linux-x86_64.tar.gz .build/
   # Upload the archive to actions/cache, S3/R2/GCS, Releases, Packages,
   # or a shared network drive. Do not commit it or track it with Git LFS.
   ```

3. **Restore on fresh clone**
   ```bash
   # In CI/CD or fresh environment
   # Download the matching archive from the shared location first.
   tar -xzf .build-cache/swift-build-cache-linux-x86_64.tar.gz
   swift build  # Will use cached dependencies
   ```

**Pros:**
- ✅ Reduces clean build time from 82s to ~5-10s (8-16x faster!)
- ✅ Works with existing SPM workflow
- ✅ No code changes required
- ✅ Simple to implement

**Cons:**
- ❌ Large file size (~100-150 MB compressed)
- ❌ Platform-specific (need separate caches for macOS/Linux/Windows)
- ❌ Needs update when dependencies change
- ❌ Storage and bandwidth costs if using a remote object store

**Best For:** CI/CD pipelines, team development

---

### Strategy 2: Swift Package Cache Directory

**Approach:** Cache SPM's global cache directory

**Implementation:**

1. **Identify cache location**
   ```bash
   # SPM cache is at:
   # macOS: ~/Library/Caches/org.swift.swiftpm/
   # Linux: ~/.cache/org.swift.swiftpm/ or $XDG_CACHE_HOME/org.swift.swiftpm/
   ```

2. **Cache in CI/CD** (GitHub Actions example)
   ```yaml
   - name: Cache SPM dependencies
     uses: actions/cache@v3
     with:
       path: |
         .build
         ~/.cache/org.swift.swiftpm
       key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
       restore-keys: |
         ${{ runner.os }}-spm-
   ```

**Pros:**
- ✅ Built into CI/CD systems
- ✅ Automatic invalidation on dependency changes
- ✅ No manual maintenance

**Cons:**
- ❌ Only helps in CI/CD, not for developers
- ❌ Still ~50-60s on cache miss

**Best For:** CI/CD only

---

### Strategy 3: Reduce swift-crypto Usage

**Approach:** Minimize crypto dependency footprint

**Options:**

#### Option A: Use Only Required Crypto Algorithms
```swift
// Instead of importing all of Crypto
import Crypto

// Import only what you need
import struct Crypto.SHA256
```

**Analysis:**
- ❌ SPM doesn't support selective module compilation
- ❌ swift-crypto compiles entire BoringSSL regardless
- **Not viable with current SPM**

#### Option B: Replace with Pure-Swift Crypto
```swift
// Replace swift-crypto with pure Swift alternative
.package(url: "https://github.com/...pure-swift-crypto", from: "1.0.0")
```

**Pros:**
- ✅ Much faster compilation (pure Swift)
- ✅ Potentially smaller binary

**Cons:**
- ❌ Slower runtime performance (no assembly optimizations)
- ❌ Less battle-tested than BoringSSL
- ❌ May not have all algorithms

**Verdict:** Not recommended for production (security concerns)

---

### Strategy 4: Docker with Pre-built Image

**Approach:** Create Docker image with pre-compiled dependencies

**Implementation:**

1. **Create Dockerfile with build cache**
   ```dockerfile
   FROM swift:6.2

   WORKDIR /app
   COPY Package.swift Package.resolved ./

   # Pre-compile dependencies
   RUN swift package resolve
   RUN swift build --build-tests

   # Add source code (will use cached deps)
   COPY . .
   RUN swift build -c release
   ```

2. **Build and push image**
   ```bash
   docker build -t hyperprompt-dev:latest .
   docker push hyperprompt-dev:latest
   ```

3. **Use in development**
   ```bash
   docker run -v $(pwd):/app hyperprompt-dev:latest swift build
   ```

**Pros:**
- ✅ Consistent environment
- ✅ Fast incremental builds
- ✅ Shareable across team

**Cons:**
- ❌ Docker overhead
- ❌ Not native development experience
- ❌ Large image size (~1-2 GB)

**Best For:** CI/CD, containerized deployments

---

### Strategy 5: ccache for C/C++ Compilation

**Approach:** Use compiler cache for BoringSSL

**Implementation:**

1. **Install ccache**
   ```bash
   # Linux
   sudo apt install ccache

   # macOS
   brew install ccache
   ```

2. **Configure SPM to use ccache**
   ```bash
   export CC="ccache clang"
   export CXX="ccache clang++"
   swift build
   ```

**Pros:**
- ✅ Speeds up C/C++ compilation (swift-crypto)
- ✅ Works automatically after first build
- ✅ No Git LFS needed

**Cons:**
- ❌ Requires ccache installation
- ❌ Still slow on first build
- ❌ ~50% improvement at best

**Expected Improvement:** 82s → 40-50s

---

## Recommended Solution

### For CI/CD Pipelines

**Use Strategy 2: GitHub Actions cache**

```yaml
# .github/workflows/build.yml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Cache SPM dependencies
        uses: actions/cache@v3
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}

      - name: Build
        run: swift build

      - name: Test
        run: swift test
```

**Expected Build Time:**
- Cache hit: **5-10 seconds** ⚡
- Cache miss: **82 seconds**
- Full clean build: **82 seconds**

---

### For Local Development

**Use Strategy 1: Manual Cache**

1. **Create cache after first build**
   ```bash
   # One-time setup
   swift build
   tar -czf ~/.swiftpm-cache/hyperprompt-build.tar.gz .build/
   ```

2. **Restore on fresh clone**
   ```bash
   tar -xzf ~/.swiftpm-cache/hyperprompt-build.tar.gz
   ```

3. **Update cache when dependencies change**
   ```bash
   # After Package.swift or Package.resolved changes
   rm -rf .build
   swift build
   tar -czf ~/.swiftpm-cache/hyperprompt-build.tar.gz .build/
   ```

**Expected Build Time:**
- First build: **82 seconds**
- With cache: **5-10 seconds** ⚡
- Incremental: **2-5 seconds** ⚡⚡

---

## External Cache Implementation Guide

### Step 1: Create a local cache archive

```bash
swift build
./.github/scripts/create-build-cache.sh
```

### Step 2: Upload the archive outside Git

```bash
# Examples:
aws s3 cp .build-cache/swift-build-cache-linux-x86_64.tar.gz s3://mybucket/hyperprompt-caches/
gh release upload cache-seed .build-cache/swift-build-cache-linux-x86_64.tar.gz
```

### Step 3: Restore in a fresh environment

```bash
# Download the matching platform archive into .build-cache/ first.
./.github/scripts/restore-build-cache.sh
swift build
```

The repository intentionally ignores `.build-cache/` and `caches/*.tar.gz`, so these archives cannot accidentally consume Git LFS bandwidth.

---

## Storage Cost Analysis

### External Cache Storage

| Platform | Files | Compressed Size | Uncompressed Size |
|----------|-------|----------------|-------------------|
| Linux x86_64 | 1 cache | ~120 MB | ~480 MB |
| macOS Intel | 1 cache | ~130 MB | ~500 MB |
| macOS ARM64 | 1 cache | ~125 MB | ~490 MB |

**Total:** ~375 MB compressed outside Git

**Recommendation:** Use GitHub Actions cache for CI. For team sharing, use object storage or Releases/Packages with explicit retention and access controls.

---

## Cache Invalidation Strategy

### When to Update Cache

1. **Package.resolved changes** (dependency updates)
2. **Swift version upgrade** (toolchain change)
3. **Platform/OS updates** (ABI changes)

### Automatic Invalidation

```bash
# Generate cache key from dependencies and Swift version
CACHE_KEY="$(cat Package.resolved | shasum -a 256 | cut -d' ' -f1)-$(swift --version | head -1 | shasum -a 256 | cut -d' ' -f1)"
CACHE_FILE="swift-build-cache-${CACHE_KEY}.tar.gz"

if [ ! -f "$CACHE_FILE" ]; then
    echo "Cache miss, building from scratch..."
    swift build
    tar -czf "$CACHE_FILE" .build/
fi
```

---

## Performance Comparison

| Scenario | Time | Speedup |
|----------|------|---------|
| Clean build (no cache) | 82s | 1x baseline |
| With LFS cache | 5-10s | **8-16x faster** ⚡ |
| Incremental build | 2-5s | **16-41x faster** ⚡⚡ |
| With ccache (first) | 82s | 1x |
| With ccache (subsequent) | 40-50s | 1.6-2x faster |
| Docker cached layers | 10-15s | 5-8x faster |

---

## Recommendations by Use Case

### Solo Developer
**Use:** Manual cache (Strategy 1)
- Simple, no infrastructure needed
- Save cache locally in `~/.swiftpm-cache/`

### Small Team (2-5 developers)
**Use:** External cache archive (Strategy 1)
- Share pre-built cache via object storage, Releases, Packages, or a network share
- Update cache monthly or on dependency changes

### CI/CD Pipeline
**Use:** GitHub Actions cache (Strategy 2)
- Built-in, automatic
- No maintenance needed

### Large Team/Enterprise
**Use:** Artifactory or custom cache server
- Centralized binary cache
- Version-controlled, automated updates

---

## Implementation Checklist

- [ ] Create initial build cache: `swift build && ./.github/scripts/create-build-cache.sh`
- [ ] Confirm `.build-cache/` and `caches/*.tar.gz` are ignored by Git
- [ ] Upload cache archive to external storage or rely on GitHub Actions cache
- [ ] Test cache restoration on fresh clone
- [ ] Update CI/CD workflow to use cache
- [ ] Document cache update procedure for team
- [ ] Set up cache invalidation on dependency updates

---

## Monitoring Build Performance

### Measure Build Times

```bash
# Track build time
time swift build 2>&1 | tee build.log

# Analyze compilation bottlenecks
grep "Compiling" build.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -20
```

### CI/CD Metrics

Track in GitHub Actions:
- Total build time
- Cache hit rate
- Dependency resolution time

---

## Alternative: Consider Removing swift-crypto

**Question:** Do you really need SHA256 from swift-crypto?

**Analysis:**
```swift
// Current usage in FileLoader.swift
import Crypto  // Brings in entire BoringSSL!

func computeHash(_ data: Data) -> String {
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

**Alternative:** Use CommonCrypto (built into macOS/iOS) or pure Swift hash

```swift
// Option 1: CommonCrypto (macOS/iOS only, no compilation needed)
import CommonCrypto

// Option 2: Pure Swift (cross-platform, fast compilation)
// https://github.com/krzyzanowskim/CryptoSwift (pure Swift, ~5s compile time)
```

**Trade-off:**
- Removes 60-70% of build time
- Loses cross-platform cryptographic security guarantees
- May need different implementation per platform

**Recommendation:** Keep swift-crypto for security, use caching strategy

---

## Conclusion

**Fastest Local Solution:** External cache archive (Strategy 1)
- **Implementation time:** 30 minutes
- **Build time improvement:** 82s → 5-10s (8-16x faster)
- **Cost:** Depends on chosen storage; no Git LFS bandwidth

**Quick Win:** CI cache (Strategy 2)
- **Implementation time:** 10 minutes
- **Build time improvement:** 50-70% on subsequent builds
- **Cost:** Free

**Best Long-term:** Combine CI cache with external team cache
- **Implementation time:** 1 hour
- **Build time improvement:** 82s → 5-10s consistently
- **Cost:** Controlled by external storage retention and access policy

---

## Next Steps

1. **Immediate:** Add CI cache to GitHub Actions workflow
2. **Short-term:** Create external cache archive for Linux x86_64
3. **Future:** Consider Docker image with pre-built dependencies for releases

Would you like me to implement any of these strategies?
