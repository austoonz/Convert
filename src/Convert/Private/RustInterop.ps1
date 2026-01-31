# RustInterop.ps1
# Platform interop layer for Rust convert_core library
# This file handles both development/testing and built module scenarios

$ErrorActionPreference = 'Stop'

# Detect architecture (x64, ARM64, or x86)
# Try RuntimeInformation first, fall back to environment/pointer size for older systems
$architecture = $null

$runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
if ($null -ne $runtimeArch) {
    $architecture = switch ($runtimeArch) {
        ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
        ([System.Runtime.InteropServices.Architecture]::Arm64) { 'arm64' }
        ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
        ([System.Runtime.InteropServices.Architecture]::Arm) { 'arm' }
    }
}

# Fallback detection when RuntimeInformation is unavailable or returns null
if ($null -eq $architecture) {
    $processorArch = $env:PROCESSOR_ARCHITECTURE
    if ($processorArch -eq 'AMD64') {
        $architecture = 'x64'
    } elseif ($processorArch -eq 'ARM64') {
        $architecture = 'arm64'
    } elseif ($processorArch -eq 'x86') {
        $architecture = 'x86'
    } elseif ($processorArch -eq 'ARM') {
        $architecture = 'arm'
    } else {
        # Last resort: use pointer size to distinguish 32-bit vs 64-bit
        if ([IntPtr]::Size -eq 8) {
            $architecture = 'x64'
        } elseif ([IntPtr]::Size -eq 4) {
            $architecture = 'x86'
        } else {
            throw "Unable to detect architecture. PROCESSOR_ARCHITECTURE='$processorArch', IntPtr.Size=$([IntPtr]::Size)"
        }
    }
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

# Library is always in $PSScriptRoot/bin/<arch>/
# Development: $PSScriptRoot = src/Convert/Private
# Built module: $PSScriptRoot = Artifacts (combined .psm1)
$libraryPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', $architecture, $libraryFileName)

# Validate library file exists
if (-not [System.IO.File]::Exists($libraryPath)) {
    $detectedPlatform = if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) { 'Windows' }
        elseif ($IsLinux) { 'Linux' }
        elseif ($IsMacOS) { 'macOS' }
        else { 'Unknown' }
    } else {
        'Windows'
    }
    
    throw @"
Rust library not found at: $libraryPath

Detected platform: $detectedPlatform
Detected architecture: $architecture
Expected filename: $libraryFileName

To build the Rust library:
1. Install Rust from https://rustup.rs
2. Run: .\build.ps1 -Rust -Build

For more information, see: https://github.com/austoonz/Convert
"@
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
    public static extern IntPtr base64_to_string_lenient(
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

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr bytes_to_string(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr bytes_to_string_lenient(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    // Hash operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hash(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string algorithm,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hmac_with_encoding(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        IntPtr key,
        UIntPtr keyLength,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string algorithm,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hmac_bytes(
        IntPtr inputBytes,
        UIntPtr inputLength,
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

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr decompress_string_lenient(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    // Combined Base64 decode + decompress operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_decompressed_string(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_decompressed_string_lenient(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string input,
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

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr string_to_bytes_copy(IntPtr ptr, out UIntPtr length);

    // Error reporting
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr get_last_error();
}
"@
    } catch {
        throw "Failed to load Rust library from '$libraryPath': $_"
    }
}
