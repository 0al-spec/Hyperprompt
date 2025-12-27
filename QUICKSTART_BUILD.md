# Quick Start: Fast Builds with Cache

This guide shows how to speed up Hyperprompt builds from **82 seconds to ~30 seconds (first build) or ~2 seconds (incremental)** using build cache.

---

## 🚀 Quick Start (5 minutes)

### First-Time Setup

```bash
# 1. Build the project (takes ~82s first time)
swift build

# 2. Create build cache
./.github/scripts/create-build-cache.sh

# Cache created in: .build-cache/swift-build-cache-linux-x86_64.tar.gz
```

### Using the Cache

```bash
# On a fresh clone or after cleaning:
./.github/scripts/restore-build-cache.sh

# Now build (takes only ~30s first time, then ~2s! ⚡)
swift build
```

**Result:** 8-16x faster builds!

---

## 📊 Performance Comparison

| Scenario | Time | Speedup |
|----------|------|---------|
| Clean build (no cache) | **82 seconds** | 1x baseline |
| First build with cache | **~30 seconds** | **2.7x faster** ⚡ |
| Incremental build | **2-5 seconds** | **16-41x faster** ⚡⚡ |

---

## 🔧 Available Scripts

### `.github/scripts/create-build-cache.sh`
Creates a compressed cache of your `.build` directory.

```bash
# Create cache with default name (platform-specific)
./.github/scripts/create-build-cache.sh

# Create cache with custom name
./.github/scripts/create-build-cache.sh my-custom-cache
```

**Output:** `.build-cache/swift-build-cache-<platform>.tar.gz`

---

### `.github/scripts/restore-build-cache.sh`
Restores a previously created build cache.

```bash
# Restore default cache for your platform
./.github/scripts/restore-build-cache.sh

# Restore specific cache file
./.github/scripts/restore-build-cache.sh .build-cache/swift-build-cache-linux-x86_64.tar.gz
```

---

### `.github/scripts/update-build-cache.sh`
Updates the cache when dependencies change (after modifying `Package.swift`).

```bash
# Clean, rebuild, test, and update cache
./.github/scripts/update-build-cache.sh
```

This script:
1. Cleans `.build` directory
2. Rebuilds from scratch
3. Runs tests to verify
4. Updates the cache

**Run this after:**
- Updating dependencies in `Package.swift`
- Upgrading Swift version
- Major code changes affecting build system

---

## 💡 Usage Scenarios

### Scenario 1: Daily Development

```bash
# Once per day or after dependencies change:
./.github/scripts/update-build-cache.sh

# Then just use normal swift build (fast!)
swift build
```

### Scenario 2: New Team Member Onboarding

```bash
# 1. Clone repo
git clone https://github.com/0al-spec/Hyperprompt
cd Hyperprompt

# 2. Restore cache (if shared via network/Git LFS)
./.github/scripts/restore-build-cache.sh

# 3. Build instantly! ⚡
swift build  # Only ~30 seconds first time, then ~2 seconds
```

### Scenario 3: CI/CD Pipeline

See `.github/workflows/build-with-cache.yml` for automated caching in GitHub Actions.

**Features:**
- Automatic cache restoration on cache hit
- Falls back to full build on cache miss
- Caches based on `Package.resolved` hash
- Shows cache statistics

---

## 📦 What Gets Cached?

The cache contains:
- **Compiled dependencies** (~366 files from swift-crypto)
- **Swift Package Manager artifacts**
- **Build intermediates** (object files, modules)

**Size:** ~120-150 MB compressed, ~480 MB uncompressed

**Excluded:** Your project's source files (always recompiled)

---

## 🔄 Cache Invalidation

Cache is automatically invalidated when:
- `Package.resolved` changes (dependency updates)
- `Package.swift` changes (configuration)
- Swift version upgrades

**Manual invalidation:**
```bash
rm -rf .build-cache/
./.github/scripts/create-build-cache.sh
```

---

## 🌐 Sharing Caches with Team

### Option 1: Network Share

```bash
# Store cache on shared network drive
cp .build-cache/*.tar.gz /mnt/shared/hyperprompt-caches/

# Team members restore from shared location
./.github/scripts/restore-build-cache.sh /mnt/shared/hyperprompt-caches/swift-build-cache-linux-x86_64.tar.gz
```

### Option 2: Cloud Storage (S3, GCS, etc.)

```bash
# Upload to S3
aws s3 cp .build-cache/swift-build-cache-linux-x86_64.tar.gz s3://mybucket/hyperprompt-caches/

# Download and restore
aws s3 cp s3://mybucket/hyperprompt-caches/swift-build-cache-linux-x86_64.tar.gz .build-cache/
./.github/scripts/restore-build-cache.sh
```

### Option 3: Git LFS (Recommended)

See `Sources/Documentation.docc/BUILD_PERFORMANCE.md` for detailed Git LFS setup instructions.

---

## ❓ Troubleshooting

### Cache Restore Fails

```bash
# Check cache file exists and is valid
ls -lh .build-cache/
tar -tzf .build-cache/swift-build-cache-linux-x86_64.tar.gz | head

# Re-create cache
rm -rf .build
swift build
./.github/scripts/create-build-cache.sh
```

### Build Still Slow After Cache Restore

```bash
# Verify cache was actually restored
ls -lh .build/

# If empty, restore again
./.github/scripts/restore-build-cache.sh

# Check Swift version matches
swift --version
```

### Cache Too Large

The cache is large because swift-crypto compiles 366 files from BoringSSL.

**Solutions:**
1. Use cache (recommended) - accept the size
2. Remove swift-crypto (not recommended - security implications)
3. Use ccache for C/C++ compilation (moderate improvement)

---

## 🎯 Best Practices

### For Solo Developers

1. Create cache after first successful build
2. Store cache in `~/.hyperprompt-cache/` for reuse across projects
3. Update cache weekly or after dependency changes

```bash
# One-time setup
mkdir -p ~/.hyperprompt-cache
ln -s ~/.hyperprompt-cache .build-cache

# Update weekly
./.github/scripts/update-build-cache.sh
```

### For Teams

1. Store cache in shared location (network drive, S3, Git LFS)
2. Update cache when merging dependency updates to main
3. Document cache location in team wiki

### For CI/CD

1. Use GitHub Actions cache (automatic, built-in)
2. See `.github/workflows/build-with-cache.yml`
3. Monitor cache hit rate in CI logs

---

## 📚 More Information

- **Full analysis:** `Sources/Documentation.docc/BUILD_PERFORMANCE.md`
- **GitHub Actions workflow:** `.github/workflows/build-with-cache.yml`
- **Cache scripts:** `.github/scripts/`

---

## 🚀 Next Steps

After setting up cache:

1. **Verify speedup:**
   ```bash
   time swift build  # Should be ~30s first, ~2s incremental
   ```

2. **Share with team:**
   Upload cache to shared location

3. **Set up CI/CD:**
   GitHub Actions workflow already included!

4. **Monitor:**
   Check cache size weekly
   Update after dependency changes

---

**Questions?** See `Sources/Documentation.docc/BUILD_PERFORMANCE.md` for detailed analysis and alternative strategies.
