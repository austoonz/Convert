# RustInterop.ps1
# Platform interop layer for Rust convert_core library
# This file will be compiled into the built module's .psm1 file

# This code assumes the Rust library is already in the correct location
# relative to the module root (handled by the build process)

$ErrorActionPreference = 'Stop'

# Detect architecture (x64, ARM64, or x86)
# RuntimeInformation is available in both PowerShell Core and Windows PowerShell 5.1+
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
    # Windows PowerShell (5.1 and earlier)
    $libraryFileName = "$libraryName.dll"
} else {
    # PowerShell Core (6.0+) - cross-platform
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

# In the built module, the library should be in: <ModuleRoot>/bin/<architecture>/<libraryFileName>
# After build, all .ps1 files are combined into a single .psm1, so $PSScriptRoot is the module root
$libraryPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', $architecture, $libraryFileName)

# Validate library file exists
if (-not [System.IO.File]::Exists($libraryPath)) {
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

# Load the Rust library via Add-Type with DllImport declarations
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
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_string(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr bytes_to_base64(IntPtr bytes, UIntPtr length);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr base64_to_bytes(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        out UIntPtr length);

    // Hash operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hash(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string algorithm,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compute_hmac(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        IntPtr key,
        UIntPtr keyLength,
        [MarshalAs(UnmanagedType.LPStr)] string algorithm);

    // Compression operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr compress_string(
        [MarshalAs(UnmanagedType.LPStr)] string input,
        [MarshalAs(UnmanagedType.LPStr)] string encoding,
        out UIntPtr length);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr decompress_string(
        IntPtr bytes,
        UIntPtr length,
        [MarshalAs(UnmanagedType.LPStr)] string encoding);

    // URL operations
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_encode([MarshalAs(UnmanagedType.LPStr)] string input);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr url_decode([MarshalAs(UnmanagedType.LPStr)] string input);

    // Time conversions
    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
    public static extern long to_unix_time(
        int year, uint month, uint day,
        uint hour, uint minute, uint second,
        bool milliseconds);

    [DllImport("$escapedPath", CallingConvention = CallingConvention.Cdecl)]
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
