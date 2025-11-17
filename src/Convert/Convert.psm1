# This file is used for development and testing only
# The build process (Invoke-Build) compiles all .ps1 files into a single .psm1

$ErrorActionPreference = 'Stop'
$scriptPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

# For development/testing, we need to locate the Rust library in the source tree
# The library should be at: src/Convert/bin/<architecture>/<libraryFileName>

# Detect architecture
$runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$architecture = switch ($runtimeArch) {
    ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
    ([System.Runtime.InteropServices.Architecture]::Arm64) { 'ARM64' }
    ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
    ([System.Runtime.InteropServices.Architecture]::Arm) { 'ARM' }
    default { throw "Unsupported architecture: $runtimeArch" }
}

# Determine library filename and path
$libraryName = 'convert_core'
if ($PSVersionTable.PSVersion.Major -lt 6) {
    $libraryFileName = "$libraryName.dll"
} else {
    if ($IsWindows) {
        $libraryFileName = "$libraryName.dll"
    } elseif ($IsLinux) {
        $libraryFileName = "lib$libraryName.so"
    } elseif ($IsMacOS) {
        $libraryFileName = "lib$libraryName.dylib"
    } else {
        throw 'Unsupported platform. Supported platforms: Windows, Linux, macOS'
    }
}

$libraryPath = [System.IO.Path]::Combine($scriptPath, 'bin', $architecture, $libraryFileName)

# Validate library exists (required for development/testing)
if (-not [System.IO.File]::Exists($libraryPath)) {
    throw @"
Rust library not found at: $libraryPath

This is the development/testing module loader. The Rust library must be built before running tests.

Detected platform: $($PSVersionTable.Platform ?? 'Windows')
Detected architecture: $architecture

To build the Rust library:
1. Install Rust from https://rustup.rs
2. Run from repository root:
   cargo build --release --manifest-path lib/Cargo.toml
3. Copy the library to: $scriptPath\bin\$architecture\

Or use the build script:
   .\build.ps1 -Configuration Release

Expected library location: $libraryPath
"@
}

# Load the Rust library via Add-Type with DllImport declarations
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ConvertCoreInterop {
    // Base64 operations
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr string_to_base64(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_string(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr bytes_to_base64(IntPtr bytes, UIntPtr length);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_bytes(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        out UIntPtr length);

    // Hash operations
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hash(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string algorithm,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hmac(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        IntPtr key,
        UIntPtr keyLength,
        [MarshalAs(UnmanagedType.LPStr)] string algorithm);

    // Compression operations
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compress_string(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding,
        out UIntPtr length);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr decompress_string(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    // URL operations
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_encode([MarshalAs(UnmanagedType.LPStr)] string input);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_decode([MarshalAs(UnmanagedType.LPStr)] string input);

    // Time conversions
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern long to_unix_time(
        int year, uint month, uint day,
        uint hour, uint minute, uint second,
        bool milliseconds);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern bool from_unix_time(
        long timestamp, bool milliseconds,
        out int year, out uint month, out uint day,
        out uint hour, out uint minute, out uint second);

    // Temperature conversions
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern double fahrenheit_to_celsius(double fahrenheit);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern double celsius_to_fahrenheit(double celsius);

    // Memory management
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern void free_string(IntPtr ptr);

    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern void free_bytes(IntPtr ptr);

    // Error reporting
    [DllImport("$libraryPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr get_last_error();
}
"@
} catch {
    throw "Failed to load Rust library from '$libraryPath': $_"
}

# Dot-source all other .ps1 files (Public and Private functions)
# Note: Skip RustInterop.ps1 since the interop code is embedded above for development/testing
try {
    $allFiles = [System.IO.Directory]::GetFiles($scriptPath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    foreach ($file in $allFiles) {
        $fileName = [System.IO.Path]::GetFileName($file)
        if ($fileName -ne 'Convert.psm1' -and $fileName -ne 'RustInterop.ps1') {
            . $file
        }
    }
} catch {
    Write-Warning -Message ('{0}: {1}' -f $Function, $_.Exception.Message)
    throw
}
