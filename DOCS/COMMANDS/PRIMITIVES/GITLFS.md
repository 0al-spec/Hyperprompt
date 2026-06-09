# GITLFS - Git LFS Guardrails

**Version:** 2.0.0

## Purpose

Git LFS is intentionally not used for Hyperprompt build caches.

Build cache archives are large, frequently downloaded, platform-specific artifacts. When stored in GitHub LFS, every checkout, `git lfs pull`, source archive download, fork clone, or automation fetch can consume metered LFS bandwidth.

Use Git LFS only for durable binary assets that must be versioned with source history. Do not use it for `.build` archives, CI caches, temporary compiler outputs, or package manager caches.

---

## Current Policy

Build cache archives must stay outside Git:

```bash
.build-cache/
caches/*.tar.gz
```

Expected repository state:

```bash
git lfs ls-files
# No Hyperprompt build cache archives should be listed.

git check-ignore .build-cache/swift-build-cache-linux-x86_64.tar.gz
git check-ignore caches/swift-build-cache-linux-x86_64.tar.gz
```

The only tracked file allowed under `caches/` is:

```text
caches/.gitkeep
```

---

## Recommended Build Cache Options

### CI

Use GitHub Actions cache:

```yaml
- name: Cache Swift dependencies
  uses: actions/cache@v4
  with:
    path: |
      .build
      .swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

### Local Development

Use ignored local archives:

```bash
swift build
./.github/scripts/create-build-cache.sh
./.github/scripts/restore-build-cache.sh
```

By default, these scripts use `.build-cache/`, which is ignored by Git.

### Team Sharing

Use object storage or release/package artifacts with retention:

- S3, R2, GCS, or Azure Blob
- GitHub Releases artifact
- GitHub Packages
- Shared network drive

Use lifecycle policies and short retention windows for build caches.

---

## If Git LFS Is Accidentally Reintroduced

1. Remove the tracking rule:

   ```bash
   git lfs untrack "caches/*.tar.gz"
   git add .gitattributes
   ```

2. Remove build cache archives from the Git index while keeping local files:

   ```bash
   git rm --cached caches/*.tar.gz
   ```

3. Confirm the archive is ignored:

   ```bash
   git check-ignore caches/swift-build-cache-linux-x86_64.tar.gz
   ```

4. Commit the cleanup:

   ```bash
   git commit -m "Remove build caches from Git LFS"
   ```

---

## When Git LFS Is Still Acceptable

Git LFS may still be appropriate for assets that are:

- Durable and source-versioned
- Required for tests or product behavior
- Infrequently downloaded
- Covered by an explicit storage and bandwidth budget

Examples: stable binary fixtures, golden image assets, or signed release inputs.

Build caches do not meet that bar.
