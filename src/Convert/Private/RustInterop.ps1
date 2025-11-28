# RustInterop.ps1
# Platform interop layer for Rust convert_core library
# This file handles both development/testing and built module scenarios

$ErrorActionPreference = 'Stop'

# Detect architecture (x64, ARM64, or x86)
$runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$architecture = switch ($runtimeArch) {
    ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
    ([System.Runtime.InteropServices.Architecture]::Arm64) { 'ARM64' }
    ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
    ([System.Runtime.InteropServices.Architecture]::Arm) { 'ARM' }
    default { throw "Unsupported architecture: $runtimeArch" }
}

# Determine library filename based on platform
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

# Determine library path based on context
# Development: $PSScriptRoot = src/Convert/Private, library at src/Convert/bin/<arch>/
# Built module: $PSScriptRoot = <ModuleRoot>, library at <ModuleRoot>/bin/<arch>/
$isDevelopment = [System.IO.Directory]::Exists([System.IO.Path]::Combine($PSScriptRoot, '..', 'Public'))

if ($isDevelopment) {
    # Development/testing: library is in parent directory's bin folder
    $moduleRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..'))
    $libraryPath = [System.IO.Path]::Combine($moduleRoot, 'bin', $architecture, $libraryFileName)
} else {
    # Built module: library is in module root's bin folder
    $libraryPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', $architecture, $libraryFileName)
}

# Validate library file exists
if (-not [System.IO.File]::Exists($libraryPath)) {
    if ($isDevelopment) {
        throw @"
Rust library not found at: $libraryPath

This is the development/testing module loader. The Rust library must be built before running tests.

Detected platform: $($PSVersionTable.Platform ?? 'Windows')
Detected architecture: $architecture

To build the Rust library:
1. Install Rust from https://rustup.rs
2. Run from repository root:
   cargo build --release --manifest-path lib/Cargo.toml
3. Copy the library to: $libraryPath

Or use the build script:
   .\Convert.build.ps1

Expected library location: $libraryPath
"@
    } else {
        throw @"
Rust library not found at: $libraryPath

The Convert module requires the Rust library to be present in the module directory.

Detected platform: $($PSVersionTable.Platform ?? 'Windows')
Detected architecture: $architecture
Expected filename: $libraryFileName

If you installed this module from the PowerShell Gallery, please report this as a bug.
If you're building from source, ensure you run the build script to compile the Rust library.

For more information, see: https://github.com/austoonz/Convert
"@
    }
}

# Load the Rust library via Add-Type with DllImport declarations
# Check if the type is already loaded (can happen in test scenarios)
$typeLoaded = $null -ne ([System.Management.Automation.PSTypeName]'ConvertCoreInterop').Type

if (-not $typeLoaded) {
    try {
        # Escape backslashes for C# string literal in DllImport
        $escapedPath = $libraryPath.Replace('\', '\\')
        
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ConvertCoreInterop {
    // Base64 operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr string_to_base64(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_string(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr bytes_to_base64(IntPtr bytes, UIntPtr length);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_bytes(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        out UIntPtr length);

    // Encoding operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr string_to_bytes(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding,
        out UIntPtr length);

    // Hash operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hash(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string algorithm,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hmac(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        IntPtr key,
        UIntPtr keyLength,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string algorithm);

    // Compression operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compress_string(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding,
        out UIntPtr length);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr decompress_string(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    // URL operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_encode([MarshalAs(UnmanagedType.LPUTF8Str)] string input);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_decode([MarshalAs(UnmanagedType.LPUTF8Str)] string input);

    // Time conversions
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern long to_unix_time(
        int year, uint month, uint day,
        uint hour, uint minute, uint second,
        bool milliseconds);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl, EntryPoint = "from_unix_time_ffi")]
    public static extern bool from_unix_time(
        long timestamp, bool milliseconds,
        out int year, out uint month, out uint day,
        out uint hour, out uint minute, out uint second);

    // Temperature conversions
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern double fahrenheit_to_celsius(double fahrenheit);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern double celsius_to_fahrenheit(double celsius);

    // Memory management
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern void free_string(IntPtr ptr);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern void free_bytes(IntPtr ptr);

    // Error reporting
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr get_last_error();
}
"@
    } catch {
        throw "Failed to load Rust library from '$libraryPath': $_"
    }
}
