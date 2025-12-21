# Contributing to Convert

Thank you for your interest in contributing to the Convert PowerShell module! This guide will help you get started with local development and understand our CI/CD workflow.

## Prerequisites

### Required Tools

- **Rust Toolchain**: Install from [rustup.rs](https://rustup.rs)
  - Verify: `cargo --version`
- **PowerShell**: Version 5.1 or PowerShell 7.x
  - Verify: `$PSVersionTable.PSVersion`
- **Git**: For version control

### Optional Tools

- **Visual Studio Code**: Recommended editor with PowerShell and Rust extensions
- **cargo-audit**: For security scanning (`cargo install cargo-audit`)
- **Miri**: For deep Rust analysis (requires nightly toolchain)

## Local Development

### Initial Setup

1. Clone the repository:
   ```powershell
   git clone https://github.com/austoonz/Convert.git
   cd Convert
   ```

2. Install PowerShell dependencies:
   ```powershell
   .\install_nuget.ps1
   .\install_modules.ps1
   ```

### Building the Module

The Convert module uses a unified `build.ps1` script with parameter-driven workflows:

```powershell
# Build Rust library
.\build.ps1 -Rust -Build

# Build PowerShell module
.\build.ps1 -PowerShell -Build

# Build both (default if no language specified)
.\build.ps1 -Build
```

### Running Tests

```powershell
# Run PowerShell tests
.\build.ps1 -PowerShell -Test

# Run Rust tests
.\build.ps1 -Rust -Test

# Run all tests
.\build.ps1 -Test
```

**Important**: Tests automatically run in separate PowerShell processes to avoid DLL locking issues. The build script handles this automatically.

### Code Analysis

```powershell
# Analyze PowerShell code (PSScriptAnalyzer)
.\build.ps1 -PowerShell -Analyze

# Analyze Rust code (clippy, fmt, check)
.\build.ps1 -Rust -Analyze

# Analyze both
.\build.ps1 -Analyze
```

### Auto-Formatting

```powershell
# Format PowerShell code
.\build.ps1 -PowerShell -Fix

# Format Rust code
.\build.ps1 -Rust -Fix

# Format both
.\build.ps1 -Fix
```

### Complete Workflow

Run the full build pipeline (clean, analyze, test, build, package):

```powershell
.\build.ps1 -Full
```

### Cleaning Build Artifacts

```powershell
# Clean PowerShell artifacts
.\build.ps1 -PowerShell -Clean

# Clean Rust artifacts
.\build.ps1 -Rust -Clean

# Clean everything
.\build.ps1 -Clean
```

## Development Workflow

### Typical Development Cycle

1. **Create a feature branch**:
   ```powershell
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** to Rust or PowerShell code

3. **Run tests frequently**:
   ```powershell
   .\build.ps1 -Test
   ```

4. **Format and analyze code**:
   ```powershell
   .\build.ps1 -Fix
   .\build.ps1 -Analyze
   ```

5. **Run full build before committing**:
   ```powershell
   .\build.ps1 -Full
   ```

6. **Commit your changes**:
   ```powershell
   git add .
   git commit -m "Description of changes"
   ```

7. **Push to your fork**:
   ```powershell
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request** on GitHub

## GitHub Actions CI/CD

### Workflow Overview

The Convert module uses GitHub Actions for continuous integration across multiple platforms:

- **Platforms**: Windows, Linux, macOS
- **PowerShell Versions**: 
  - Windows: PowerShell 5.1 and PowerShell 7.x (LTS)
  - Linux/macOS: PowerShell 7.x (LTS)
- **Architectures Tested**:
  - Windows x64
  - Linux x64
  - macOS x64 (Intel)
  - macOS arm64 (Apple Silicon)
- **Workflow File**: `.github/workflows/ci.yml`

### What Happens on Push

When you push to any branch in the main repository:

1. **Rust Analysis**: Code quality checks (clippy, fmt, security audit)
2. **Platform Builds**: Parallel builds for Windows, Linux, and macOS targets
3. **Artifact Assembly**: Combines all platform binaries into a universal module
4. **Platform Testing**: Tests run on each platform/architecture:
   - Windows x64 (PowerShell 5.1 + Core)
   - Linux x64
   - macOS x64 (Intel)
   - macOS arm64 (Apple Silicon)
5. **Release Package** (main branch only): Creates versioned ZIP for distribution

### Pull Request Process for External Contributors

**Important**: For security reasons, pull requests from external forks require manual approval before workflows run.

#### First-Time Contributors

1. **Create a fork** of the repository
2. **Make your changes** in your fork
3. **Create a Pull Request** from your fork to the main repository
4. **Wait for approval**: A repository maintainer will review your PR code
5. **Manual workflow approval**: After code review, a maintainer will manually approve the workflow run
6. **Workflow runs**: Once approved, the CI workflow will execute

#### Subsequent Updates to Your PR

**Each time you push new commits to your PR, the workflow requires re-approval**:

1. Push new commits to your PR branch
2. Wait for maintainer to review the new changes
3. Maintainer manually approves the workflow run again
4. Workflow executes with the latest changes

This security measure prevents malicious code from running automatically in the repository's context.

#### Why This Process Exists

- **Security**: Prevents unauthorized code execution in the main repository
- **Resource Protection**: Prevents abuse of GitHub Actions minutes
- **Code Quality**: Ensures all external contributions are reviewed before testing

### Viewing Workflow Results

- **Build Status**: Check the GitHub Actions badge in the README
- **Detailed Results**: Click the badge or visit the "Actions" tab in the repository
- **Test Reports**: View test results in the workflow summary
- **Artifacts**: Download platform-specific or deployment artifacts from completed workflow runs

### Workflow Documentation

For detailed information about the GitHub Actions workflow architecture, see:
- [Migration Design](.kiro/specs/github-actions-migration/design.md)

## Testing Guidelines

### Test Coverage Requirements

- **Minimum Coverage**: 85% code coverage for PowerShell code
- **Test Framework**: Pester 5.3.0+
- **Test Location**: `src/Tests/Unit/`

### Writing Tests

Follow the [Pester Testing Standards](.kiro/steering/pester-testing-standards.md) for comprehensive test coverage:

- **Encoding/Format Support**: Test all supported encodings
- **Pipeline Support**: Test single and array pipeline input
- **Edge Cases**: Test empty, null, special characters, Unicode, large inputs
- **Error Handling**: Test error conditions and ErrorAction behavior
- **Performance**: Test batch processing and large inputs
- **Data Integrity**: Test round-trip conversions and consistency

### Running Tests in Isolation

**Critical**: Always run tests in a new PowerShell process to avoid DLL caching issues:

```powershell
# Correct - tests run in fresh process
pwsh -NoProfile -Command "Invoke-Pester -Path src\Tests\Unit\"

# Or use the build script (handles isolation automatically)
.\build.ps1 -PowerShell -Test
```

**Never** run tests in the same session where you've imported the module manually.

## Code Style

### PowerShell

- Follow [PowerShell Coding Standards](.kiro/steering/powershell-coding-standards.md)
- Use single quotes for static strings
- Use double quotes for variable expansion
- Prefer .NET methods over cmdlets for performance
- Always use named parameters for clarity

### Rust

- Follow standard Rust conventions
- Run `cargo fmt` before committing
- Address all `cargo clippy` warnings
- Add SAFETY comments to all unsafe blocks
- Document public APIs with doc comments

## Commit Guidelines

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in present tense (Add, Fix, Update, Remove)
- Reference issue numbers when applicable

**Examples**:
```
Add support for UTF-16 encoding in Base64 conversion
Fix memory leak in string_to_base64 function
Update README with GitHub Actions badge
Remove deprecated CodeBuild configuration
```

### Before Committing

Always run the full build to ensure quality:

```powershell
.\build.ps1 -Full
```

This runs:
1. Clean - Remove old artifacts
2. Analyze - Check code quality
3. Test - Run all tests
4. Build - Compile and assemble
5. Package - Create deployment artifact

## Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/austoonz/Convert/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/austoonz/Convert/discussions)
- **Documentation**: Read the [online documentation](https://austoonz.github.io/Convert/)

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to build great software together.

## License

By contributing to Convert, you agree that your contributions will be licensed under the same license as the project.
