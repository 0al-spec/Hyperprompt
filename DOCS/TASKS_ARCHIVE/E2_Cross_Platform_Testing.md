# Task E2 — Cross-Platform Testing

**Task ID:** E2
**Task Name:** Cross-Platform Testing
**Priority:** P1 (High)
**Phase:** Phase 8 — Testing & Quality Assurance
**Estimated Effort:** 4 hours
**Dependencies:** E1 (Test Corpus Implementation ✅)
**Status:** Selected for Implementation

---

## 1. Objective

Verify that the Hyperprompt compiler produces byte-for-byte identical, deterministic output across multiple platforms (macOS Intel, macOS Apple Silicon, Ubuntu 22.04) with consistent LF line endings. Ensure no platform-specific bugs or behavioral differences exist in the compiled binary.

**Primary Deliverable:** Test execution report confirming identical compiler behavior across platforms with evidence of deterministic output validation.

**Success Criteria:**
- ✅ Identical outputs (byte-for-byte match) for all test cases on each platform
- ✅ LF line endings verified on all platforms (no CRLF, CR, or mixed)
- ✅ No platform-specific compilation differences
- ✅ Test results documented with platform information

---

## 2. Scope and Intent

### 2.1 In Scope

**Platform Coverage (P1 Priority):**
- macOS Intel (x86_64) — Latest stable Xcode toolchain
- macOS Apple Silicon (M1/M2/M3) — Latest stable Xcode toolchain
- Ubuntu 22.04 x86_64 — Swift 6.0.3 via `swift-actions/setup-swift`

**Test Validation (P0 Priority - Critical):**
- Run E1 test corpus (V01-V14, I01-I10) on each platform
- Compare output files byte-for-byte
- Verify deterministic output (same input → same output, always)
- Validate LF-only line endings in compiled output

**Documentation:**
- Test execution log with platform info (OS, Swift version, architecture)
- Comparison results showing identical/different outputs
- Platform-specific notes if any deviations found

### 2.2 Out of Scope

**P2 Priority (Deferred to v0.1.1):**
- Ubuntu 22.04 ARM64 testing
- Windows 10+ native testing
- Windows WSL2 testing
- Performance profiling across platforms

**Documentation:**
- Platform-specific optimization guides
- Architecture-specific tuning advice

---

## 3. Functional Requirements

### 3.1 Test Execution

**Per Platform:**
1. Set up Swift/Xcode toolchain appropriate for platform
2. Build Hyperprompt compiler from source
3. Execute E1 test corpus (all 24 test cases)
4. Capture output files and exit codes
5. Document Swift version, OS version, architecture

**Output Collection:**
- Markdown output files (compiled `.md`)
- Manifest files (JSON)
- Exit codes for each test
- Build timestamps and environment info

### 3.2 Determinism Verification

**Byte-for-Byte Comparison:**
```
For each test case (V01-V14):
  - Run compilation on Platform A → Output A
  - Run compilation on Platform A again → Output A' (repeated 3x)
  - Verify: Output A == Output A' (deterministic on same platform)

For each test case (V01-V14):
  - Run compilation on Platform A → Output A
  - Run compilation on Platform B → Output B
  - Verify: Output A == Output B (cross-platform identical)
```

**Line Ending Validation:**
```
For each output file (markdown and JSON):
  - Check: No CRLF sequences found
  - Check: No bare CR found (only LF used as line separator)
  - Check: File ends with exactly one LF
```

### 3.3 Error Handling

**Invalid Tests (I01-I10):**
- Verify exit codes match expected error category (1, 2, 3, or 4)
- Exit codes must be identical across platforms
- Error messages may vary slightly (platform-specific paths) — acceptable if structure consistent

---

## 4. Implementation Plan

### Phase 1: Setup & Validation (1 hour)

**Task 1.1: Platform Setup (30 mins)**
- [ ] Verify macOS Intel environment (if available locally)
  - Check: `swift --version` returns 6.0.3 or compatible
  - Check: Xcode command-line tools installed (`xcode-select -p`)
  - Note: May require `sudo xcode-select --install`
- [ ] Verify macOS Apple Silicon environment (if available locally)
  - Check: `swift --version` returns 6.0.3 or compatible
  - Check: Native ARM64 architecture (`uname -m` returns `arm64`)
- [ ] Verify Ubuntu 22.04 environment
  - Check: Swift installed and accessible
  - May use local Linux machine or Docker container

**Task 1.2: Build Verification (30 mins)**
- [ ] Clone/checkout Hyperprompt repository on each platform
- [ ] Build compiler: `swift build -c release`
- [ ] Verify build succeeds on all platforms
- [ ] Note build times for comparison
- [ ] Verify executable is present and executable (`ls -la .build/release/hyperprompt`)

### Phase 2: Test Execution (1.5 hours)

**Task 2.1: Prepare Test Environment (15 mins)**
- [ ] Copy E1 test corpus to each platform
- [ ] Create output directory structure for results
- [ ] Document test execution environment:
  ```
  Platform:     macOS / Linux
  OS Version:   (from `uname -a`)
  Swift:        (from `swift --version`)
  Architecture: (from `uname -m`)
  Date/Time:    (ISO 8601)
  ```

**Task 2.2: Execute Test Cases (1 hour)**
- [ ] For each valid test (V01-V14):
  ```bash
  hyperprompt <input> -o output.md -m manifest.json
  ```
  - Capture exit code
  - Store output files with naming: `V{ID}_platform-{name}.md`, `V{ID}_manifest-{name}.json`
  - Record execution time

- [ ] For each invalid test (I01-I10):
  ```bash
  hyperprompt <input> -o /dev/null 2>&1
  ```
  - Verify exit code matches expected (1, 2, 3, or 4)
  - No need to capture output (errors expected)

**Task 2.3: Determinism Verification (15 mins)**
- [ ] Repeat execution of 3 randomly selected valid tests on same platform
  - V03, V07, V09 (or similar diverse set)
  - Verify outputs are byte-identical to first run
  - Use: `diff <(hexdump -C output1.md) <(hexdump -C output1_rerun.md)`

### Phase 3: Comparison & Validation (1 hour)

**Task 3.1: Cross-Platform Comparison (30 mins)**
- [ ] For each valid test V01-V14:
  ```bash
  diff macOS_Intel/V{ID}.md Linux/V{ID}.md
  ```
  - If differences found, document and investigate
  - Expected: No differences (byte-identical)

**Task 3.2: Line Ending Validation (15 mins)**
- [ ] For each output file (all platforms, all valid tests):
  ```bash
  file output.md  # Verify "ASCII text, with very long lines, with LF line terminators"
  hexdump -C output.md | grep -E "0d 0a|0d 0d"  # Verify no CRLF or CR-only
  tail -c 1 output.md | hexdump -C  # Verify ends with 0a (LF)
  ```

**Task 3.3: Manifest Validation (15 mins)**
- [ ] Compare manifest JSON files across platforms (should be identical)
- [ ] Verify JSON is deterministic (keys sorted alphabetically)
- [ ] Validate timestamps are correct (ISO 8601 format)

### Phase 4: Documentation (0.5 hours)

**Task 4.1: Test Report (30 mins)**
- [ ] Create summary report: `DOCS/INPROGRESS/E2-test-results.md`
  ```markdown
  # E2 Cross-Platform Testing Results

  ## Summary
  - Platforms tested: macOS Intel, macOS Apple Silicon, Ubuntu 22.04
  - Total tests: 24 (V01-V14 valid + I01-I10 invalid)
  - Result: ✅ All tests PASSED (deterministic, identical across platforms)

  ## Platform Details
  | Platform | Swift | OS Version | Architecture | Status |
  |---|---|---|---|---|
  | macOS Intel | 6.0.3 | Monterey+ | x86_64 | ✅ |
  | macOS ARM64 | 6.0.3 | Monterey+ | arm64 | ✅ |
  | Ubuntu 22.04 | 6.0.3 | 22.04 LTS | x86_64 | ✅ |

  ## Determinism Verification
  - V03, V07, V09 re-executed 3x each
  - Result: ✅ Byte-identical across runs

  ## Cross-Platform Comparison
  - All V01-V14 outputs: ✅ Byte-identical
  - All I01-I10 exit codes: ✅ Consistent

  ## Line Ending Validation
  - Markdown files: ✅ LF-only
  - JSON files: ✅ LF-only
  - No CRLF detected: ✅

  ## Conclusion
  Hyperprompt compiler produces deterministic, platform-independent output.
  ```

**Task 4.2: Evidence Archiving (Optional)**
- [ ] Archive test output files (optional, can be large)
- [ ] Create checksums: `sha256sum V*.md > checksums.txt`
- [ ] Commit to repository under `DOCS/INPROGRESS/E2-results/`

---

## 5. Acceptance Criteria

✅ **MUST HAVE:**
1. All E1 test cases (V01-V14) execute successfully on all three platforms
2. Markdown and manifest outputs are byte-identical across all platforms
3. Exit codes for error tests (I01-I10) are consistent across platforms
4. All output files use LF-only line endings (no CRLF)
5. Test execution documented with platform/version information
6. Determinism verified: same input on same platform produces identical output
7. Report created at `DOCS/INPROGRESS/E2-test-results.md`

✅ **SHOULD HAVE:**
- Performance metrics documented (build time, test execution time per platform)
- Any platform-specific behavioral notes or warnings
- Checksums of output files archived

---

## 6. Related Task: CI-10

**Integration Note:** While this task documents manual cross-platform testing, the related CI task **CI-10 (Enable required status checks)** sets up automated GitHub Actions CI with branch protection. Future work (**CI-11/CI-12**) can extend CI to include macOS runners, allowing automated cross-platform testing on every PR.

**Current E2 Approach:**
- Manual verification of determinism and platform consistency
- Confirms compiler is production-ready for release

**Future Enhancement (post-E2):**
- CI-11: Add macOS runners to GitHub Actions matrix
- CI-12: Add Windows runners to GitHub Actions matrix
- E2 can be automated in CI pipeline for regression testing

---

## 7. Testing & Validation

### Local Testing Procedure

**macOS (Intel or Apple Silicon):**
```bash
cd /path/to/Hyperprompt
swift build -c release
cd /tmp
cp -r /path/to/E1_test_corpus .
.../Hyperprompt/.build/release/hyperprompt E1_test_corpus/V01_single_root_node/input.hc -o output.md
diff expected_output.md output.md
```

**Ubuntu 22.04:**
```bash
cd /path/to/Hyperprompt
swift build -c release
# (same test procedure as macOS)
```

**Comparison:**
```bash
# Side-by-side comparison across platforms
diff /tmp/macOS_Intel/output.md /tmp/Ubuntu/output.md
```

### Rollback Plan

If cross-platform differences detected:
1. Document specific failing test case(s)
2. Isolate platform-specific behavior (file handling, Swift stdlib differences, etc.)
3. File bug report with detailed reproduction steps
4. Revert compiler changes if introduced recently
5. Retest to confirm fix

---

## 8. Notes

- E2 is marked **P1 (required for v0.1)** but Ubuntu ARM64, Windows are **P2 (deferred)**
- This task validates the **critical P0 acceptance criteria**: deterministic, platform-independent output
- Test corpus (E1) provides pre-built test cases and golden files for comparison
- LF line ending validation is critical for release compatibility (Unix/Linux/macOS use LF; Windows CRLF can cause issues if not handled properly)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-10 | Claude | Initial PRD for cross-platform testing |

---

**Archived:** 2025-12-11
