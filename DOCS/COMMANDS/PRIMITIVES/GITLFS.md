# INSTALL_GITLFS — Install Git Large File Storage

**Version:** 1.0.0

## Purpose

Install Git LFS (Large File Storage) for handling large binary files like build caches. This is optional but recommended for development environments.

---

## Prerequisites

- Linux (Ubuntu/Debian-based) or macOS
- Git installed
- Internet connection
- Sudo access (for system-wide installation)

---

## Quick Installation

### Linux (Ubuntu/Debian)

```bash
# Install Git LFS
sudo apt update
sudo apt install -y git-lfs

# Initialize Git LFS for current user
git lfs install

# Verify installation
git lfs version
```

**Expected output:**
```
git-lfs/3.4.1 (GitHub; linux amd64; go 1.21.1)
```

### macOS

```bash
# Using Homebrew
brew install git-lfs

# Initialize Git LFS
git lfs install

# Verify installation
git lfs version
```

---

## What Git LFS Does

Git LFS replaces large files with text pointers in Git, while storing the actual file contents on a remote server.

**Benefits:**
- ✅ Keeps repository size small
- ✅ Faster clones and fetches
- ✅ Handles files >100MB (GitHub limit)
- ✅ Efficient binary file versioning

**Use cases in Hyperprompt:**
- Build caches (`caches/*.tar.gz`)
- Large test fixtures
- Binary assets

---

## Configuration

### Repository Setup

After installation, Git LFS is automatically configured for tracked files:

```bash
# Files are tracked via .gitattributes
cat .gitattributes
# Output: caches/*.tar.gz filter=lfs diff=lfs merge=lfs -text

# Check LFS-tracked files
git lfs ls-files

# Check LFS status
git lfs status
```

### Disable LFS Locking (if server doesn't support it)

```bash
git config lfs.$(git config --get remote.origin.url).locksverify false
```

---

## Usage

### Clone Repository with LFS

```bash
# Standard clone (downloads LFS files)
git clone <repository-url>

# Fast clone (skip LFS files initially)
GIT_LFS_SKIP_SMUDGE=1 git clone <repository-url>
cd <repository>
git lfs pull  # Download LFS files when needed
```

### Add LFS Files

```bash
# Files matching .gitattributes patterns are automatically handled
git add caches/build-cache.tar.gz
git commit -m "Add build cache"
git push
```

### Restore Build Cache from LFS

```bash
# If LFS files weren't downloaded during clone
git lfs pull

# Restore specific cache
./.github/scripts/restore-build-cache.sh
```

---

## Troubleshooting

### "git: 'lfs' is not a git command"

**Solution:**
```bash
# Linux
sudo apt install git-lfs
git lfs install

# macOS
brew install git-lfs
git lfs install
```

### "batch response: Fatal error: Server error"

**Cause:** Git LFS server is unavailable or not configured.

**Solution:**
- Use local build cache (already created)
- Wait for LFS server to become available
- Or use alternative storage (S3, Azure, etc.)

### "This repository is over its data quota"

**Cause:** LFS bandwidth/storage limit exceeded.

**Solution:**
- Use local cache: `./.github/scripts/create-build-cache.sh`
- Contact repository administrator
- Clean old LFS objects: `git lfs prune`

### Files Not Tracked by LFS

**Check tracking:**
```bash
git lfs track
# Should show: caches/*.tar.gz

# If not tracked, add:
git lfs track "caches/*.tar.gz"
git add .gitattributes
git commit -m "Track build caches with LFS"
```

---

## Verification

Test Git LFS installation:

```bash
# 1. Check Git LFS is installed
git lfs version

# 2. Check Git LFS is initialized
git lfs env | grep "git config filter.lfs"

# 3. Check tracked files
git lfs track

# 4. Check LFS files in repository
git lfs ls-files
```

**Expected output for Hyperprompt:**
```
git lfs ls-files
5ba5dd8071 * caches/swift-build-cache-linux-x86_64.tar.gz
```

---

## When to Skip Git LFS

Git LFS is **optional** if:
- ❌ LFS server unavailable
- ❌ Repository doesn't have LFS files yet
- ❌ Using local build cache only

Git LFS is **recommended** if:
- ✅ Sharing build cache across team
- ✅ Repository contains files >100MB
- ✅ Need fast clones with large binaries

---

## Reference

- Official documentation: https://git-lfs.github.com/
- Hyperprompt build cache: `caches/` directory
- Cache scripts:
  - Create: `./.github/scripts/create-build-cache.sh`
  - Restore: `./.github/scripts/restore-build-cache.sh`

---

## Notes

- **Installation time:** ~1-2 minutes
- **Disk space:** ~10-20 MB for Git LFS client
- **Network usage:** Only when pushing/pulling LFS files
- **One-time setup** per development environment
- **Works with existing git commands** - no workflow changes needed
