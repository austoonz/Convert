# GitHub Actions Workflows

## Overview

This directory contains GitHub Actions workflows for the Convert PowerShell module. The workflows provide automated building, testing, and artifact generation across Windows, Linux, and macOS platforms.

## Workflows

### CI Workflow (`ci.yml`)

The primary continuous integration workflow that builds and tests the module on all supported platforms.

**Triggers:**
- Push to any branch (repository owner only)
- Pull requests (with approval required for external forks)
- Manual workflow dispatch
- Release creation

**Jobs:**
1. `build-and-test` - Builds and tests on all platforms
2. `merge-artifacts` - Combines platform-specific artifacts into unified deployment package

## Matrix Build Strategy

The workflow uses a matrix strategy to build and test across multiple platforms in parallel:

```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - os: windows-latest
        platform: windows
      - os: ubuntu-latest
        platform: linux
      - os: macos-latest
        platform: macos
```

**Key Features:**
- `fail-fast: false` ensures all platforms complete even if one fails
- Each platform builds its own Rust library (`.dll`, `.so`, or `.dylib`)
- Windows tests both PowerShell 5.1 and PowerShell 7+
- Linux and macOS test PowerShell 7+ only

**Build Steps per Platform:**
1. Checkout code
2. Setup Rust toolchain (with caching)
3. Install PowerShell modules (with caching)
4. Build Rust library: `.\build.ps1 -Rust -Build`
5. Build PowerShell module: `.\build.ps1 -PowerShell -Build`
6. Run tests (PowerShell 7+): `.\build.ps1 -PowerShell -Test`
7. Run tests (Windows PowerShell 5.1, Windows only): `.\build.ps1 -PowerShell -Test`
8. Upload platform artifact
9. Upload test results

## Artifact Merging Process

After all platform builds complete successfully, the `merge-artifacts` job combines them into a single deployment artifact.

**Process:**
1. Download all platform artifacts (`module-windows`, `module-linux`, `module-macos`)
2. Create merged directory structure:
   ```
   Convert/
   ├── Convert.psd1
   ├── Convert.psm1
   ├── bin/
   │   ├── windows/
   │   │   └── convert_core.dll
   │   ├── linux/
   │   │   └── libconvert_core.so
   │   └── macos/
   │       └── libconvert_core.dylib
   └── en-US/
       └── Convert-help.xml
   ```
3. Copy base files (manifest, module, help) from any platform (identical across platforms)
4. Copy platform-specific libraries to respective `bin/<platform>/` directories
5. Extract version from module manifest
6. Create deployment ZIP: `Convert_<version>.zip`
7. Upload deployment artifact (main branch only)

**Artifact Retention:**
- Platform artifacts: 90 days
- Test results: 90 days
- Deployment artifact: 90 days

## Required Repository Settings

### Actions Permissions

Navigate to **Settings → Actions → General**:

1. **Workflow permissions:**
   - Set to "Read repository contents and packages permissions"
   - Enable "Allow GitHub Actions to create and approve pull requests" (optional)

2. **Fork pull request workflows:**
   - Enable "Require approval for all outside collaborators"
   - This is **critical for security** - see Fork Protection section below

### Branch Protection (Optional but Recommended)

Navigate to **Settings → Branches → Branch protection rules**:

1. Add rule for `main` branch:
   - Require status checks to pass before merging
   - Select "CI / build-and-test (windows)" check
   - Select "CI / build-and-test (linux)" check
   - Select "CI / build-and-test (macos)" check

## Security Settings

### Fork Protection Rationale

The workflow uses `pull_request_target` trigger, which runs in the context of the base repository and has access to repository secrets. This is necessary for writing test results and uploading artifacts, but creates a security risk if untrusted code runs automatically.

**Security Measures:**

1. **Conditional Execution:**
   ```yaml
   if: github.event.pull_request.head.repo.full_name == github.repository || github.event_name != 'pull_request_target'
   ```
   This prevents automatic execution for PRs from external forks.

2. **Manual Approval Requirement:**
   - Settings → Actions → General → "Require approval for all outside collaborators"
   - Repository owners must manually approve workflow runs from external contributors
   - **Each new commit requires re-approval** - prevents malicious code injection after initial review

3. **Minimal Permissions:**
   ```yaml
   permissions:
     contents: read   # Read repository code
     actions: read    # Read workflow artifacts
     checks: write    # Write test results
   ```

**Why This Matters:**
- Prevents malicious PRs from accessing secrets
- Prevents unauthorized consumption of GitHub Actions minutes
- Protects against compromised contributor accounts
- Ensures code review before execution

### Manual Approval Process

When an external contributor opens a PR:

1. **PR is created** - Workflow does not run automatically
2. **Owner reviews code** - Check for malicious changes, security issues
3. **Owner approves** - Click "Approve and run" in Actions tab
4. **Workflow runs** - Builds and tests the PR code
5. **New commit pushed** - Workflow requires re-approval (go back to step 2)

**Important:** Never approve workflows without reviewing the code changes first. Malicious code could:
- Exfiltrate repository secrets
- Modify repository contents
- Consume GitHub Actions minutes
- Attack other systems

## Caching Strategy

The workflow uses aggressive caching to minimize build times:

### Rust Build Cache

**Cached Paths:**
- `~/.cargo/registry` - Cargo package registry
- `~/.cargo/git` - Git dependencies
- `lib/target` - Compiled Rust artifacts

**Cache Key:**
```yaml
key: ${{ runner.os }}-rust-${{ hashFiles('lib/Cargo.lock') }}
```

**Impact:** Reduces Rust build time from ~5 minutes to ~1 minute on cache hit.

### PowerShell Module Cache

**Cached Paths:**
- `~/.local/share/powershell/Modules` (Linux/macOS)
- `~/Documents/PowerShell/Modules` (Windows)

**Cache Key:**
```yaml
key: ${{ runner.os }}-psmodules-${{ hashFiles('install_modules.ps1') }}
```

**Impact:** Reduces module installation time from ~2 minutes to ~10 seconds on cache hit.

## Test Reporting

Test results are automatically published to the workflow summary using the `dorny/test-reporter` action.

**Features:**
- JUnit XML format test results
- Per-platform test reporting
- Test count and pass/fail status
- Direct links to failed tests
- Coverage reporting (uploaded as artifact)

**Test Result Artifacts:**
- `test-results-windows` - Windows test results
- `test-results-linux` - Linux test results
- `test-results-macos` - macOS test results

Each artifact contains:
- `test_report.xml` - PowerShell 7+ test results
- `test_report_build.xml` - Windows PowerShell 5.1 test results (Windows only)
- `coverage.xml` - Code coverage data

## Local Development

To run the same build steps locally:

```powershell
# Build Rust library
.\build.ps1 -Rust -Build

# Build PowerShell module
.\build.ps1 -PowerShell -Build

# Run tests
.\build.ps1 -PowerShell -Test

# Full workflow (clean, analyze, test, build, package)
.\build.ps1 -Full
```

See [build-system.md](../../.kiro/steering/build-system.md) for complete build system documentation.

## Troubleshooting

### Workflow Not Running on Fork PR

**Symptom:** Workflow doesn't run automatically for external contributor PR.

**Cause:** This is expected behavior for security. See Fork Protection section.

**Solution:** Repository owner must manually approve the workflow run.

### Platform Build Failure

**Symptom:** One platform fails while others succeed.

**Cause:** Platform-specific compilation or test issue.

**Solution:**
1. Check workflow logs for specific error
2. Reproduce locally on the failing platform
3. Fix platform-specific issue
4. Push fix and re-run workflow

### Cache Not Working

**Symptom:** Build takes full time even though dependencies haven't changed.

**Cause:** Cache key mismatch or cache eviction.

**Solution:**
1. Check cache key matches between runs
2. Verify `Cargo.lock` or `install_modules.ps1` hasn't changed
3. Cache may have been evicted (7-day inactivity or 10 GB limit)
4. Cache will rebuild automatically

### Artifact Merge Failure

**Symptom:** Merge job fails to create deployment artifact.

**Cause:** Platform artifact structure mismatch or missing files.

**Solution:**
1. Check all platform builds completed successfully
2. Verify artifact structure matches expected layout
3. Check merge script for path issues
4. Download platform artifacts and inspect manually

## Migration Notes

This workflow replaces the previous AWS CodeBuild infrastructure. Key differences:

**CodeBuild:**
- Separate projects for Windows and Linux
- Sequential builds
- Artifacts uploaded to S3
- Manual configuration in AWS Console

**GitHub Actions:**
- Single workflow file
- Parallel matrix builds (Windows, Linux, macOS)
- Artifacts stored in GitHub
- Configuration as code in repository

**Benefits:**
- Faster builds (parallel execution)
- Better integration with GitHub (PR checks, status badges)
- No AWS infrastructure to maintain
- Easier for contributors to understand and debug

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Build System Documentation](../../.kiro/steering/build-system.md)
- [Migration Design Document](../../.kiro/specs/github-actions-migration/design.md)
