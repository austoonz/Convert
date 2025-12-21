# Convert

[![CI](https://github.com/austoonz/Convert/actions/workflows/ci.yml/badge.svg)](https://github.com/austoonz/Convert/actions/workflows/ci.yml)
[![Documentation](https://github.com/austoonz/Convert/actions/workflows/docs.yml/badge.svg)](https://github.com/austoonz/Convert/actions/workflows/docs.yml)
[![Minimum Supported PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Convert.svg)](https://www.powershellgallery.com/packages/Convert)

A PowerShell module that simplifies object conversions by exposing common requirements as PowerShell functions.

## Overview

Convert provides a comprehensive set of functions for converting between different data formats and types. Built with high-performance Rust libraries for optimal speed, it handles:

- Base64 encoding/decoding with multiple text encodings
- Byte array and memory stream conversions
- String compression and decompression
- Hash generation (MD5, SHA1, SHA256, SHA384, SHA512, HMAC)
- URL encoding/decoding
- Temperature conversions (Celsius/Fahrenheit)
- Unix timestamp conversions
- CLIXML serialization
- Case conversions (Title Case)

## Installation

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/Convert):

```powershell
# Install for current user
Install-Module -Name Convert -Scope CurrentUser

# Install for all users (requires admin)
Install-Module -Name Convert -Scope AllUsers
```

## Quick Start

### Base64 Encoding

```powershell
# Convert string to Base64
'Hello, World!' | ConvertTo-Base64
# Output: SGVsbG8sIFdvcmxkIQ==

# Convert from Base64
'SGVsbG8sIFdvcmxkIQ==' | ConvertFrom-Base64
# Output: Hello, World!
```

### Hash Generation

```powershell
# Generate SHA256 hash
'Hello, World!' | ConvertTo-Hash -Algorithm SHA256
# Output: dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f

# Generate HMAC-SHA256
'Hello, World!' | ConvertTo-HmacHash -Algorithm SHA256 -Key 'secret'
```

### Memory Stream Operations

```powershell
# Convert string to memory stream
$stream = 'Hello, World!' | ConvertTo-MemoryStream

# Convert memory stream back to string
$stream | ConvertFrom-MemoryStream
```

## Functions

| Category | Functions |
|----------|-----------|
| **Base64** | [ConvertTo-Base64](functions/ConvertTo-Base64.md), [ConvertFrom-Base64](functions/ConvertFrom-Base64.md), [ConvertFrom-Base64ToString](functions/ConvertFrom-Base64ToString.md), [ConvertFrom-Base64ToByteArray](functions/ConvertFrom-Base64ToByteArray.md), [ConvertFrom-Base64ToMemoryStream](functions/ConvertFrom-Base64ToMemoryStream.md) |
| **Byte Arrays** | [ConvertFrom-ByteArrayToBase64](functions/ConvertFrom-ByteArrayToBase64.md), [ConvertFrom-ByteArrayToMemoryStream](functions/ConvertFrom-ByteArrayToMemoryStream.md) |
| **Strings** | [ConvertFrom-StringToBase64](functions/ConvertFrom-StringToBase64.md), [ConvertFrom-StringToByteArray](functions/ConvertFrom-StringToByteArray.md), [ConvertFrom-StringToMemoryStream](functions/ConvertFrom-StringToMemoryStream.md), [ConvertFrom-StringToCompressedByteArray](functions/ConvertFrom-StringToCompressedByteArray.md), [ConvertTo-String](functions/ConvertTo-String.md), [ConvertTo-TitleCase](functions/ConvertTo-TitleCase.md) |
| **Memory Streams** | [ConvertTo-MemoryStream](functions/ConvertTo-MemoryStream.md), [ConvertFrom-MemoryStream](functions/ConvertFrom-MemoryStream.md), [ConvertFrom-MemoryStreamToBase64](functions/ConvertFrom-MemoryStreamToBase64.md), [ConvertFrom-MemoryStreamToByteArray](functions/ConvertFrom-MemoryStreamToByteArray.md), [ConvertFrom-MemoryStreamToString](functions/ConvertFrom-MemoryStreamToString.md), [ConvertFrom-MemoryStreamToSecureString](functions/ConvertFrom-MemoryStreamToSecureString.md) |
| **Compression** | [ConvertFrom-CompressedByteArrayToString](functions/ConvertFrom-CompressedByteArrayToString.md) |
| **Hashing** | [ConvertTo-Hash](functions/ConvertTo-Hash.md), [ConvertTo-HmacHash](functions/ConvertTo-HmacHash.md) |
| **URLs** | [ConvertTo-EscapedUrl](functions/ConvertTo-EscapedUrl.md), [ConvertFrom-EscapedUrl](functions/ConvertFrom-EscapedUrl.md) |
| **Temperature** | [ConvertTo-Celsius](functions/ConvertTo-Celsius.md), [ConvertTo-Fahrenheit](functions/ConvertTo-Fahrenheit.md) |
| **Time** | [ConvertTo-UnixTime](functions/ConvertTo-UnixTime.md), [ConvertFrom-UnixTime](functions/ConvertFrom-UnixTime.md), [Get-UnixTime](functions/Get-UnixTime.md) |
| **CLIXML** | [ConvertTo-Clixml](functions/ConvertTo-Clixml.md), [ConvertFrom-Clixml](functions/ConvertFrom-Clixml.md) |
| **Hashtables** | [ConvertFrom-HashTable](functions/ConvertFrom-HashTable.md) |

## Requirements

- Windows PowerShell 5.1 or PowerShell 7.x
- Supported platforms: Windows (x64, ARM64), Linux (x64, ARM64, ARM), macOS (x64, ARM64)

## Performance

Convert uses high-performance Rust libraries for core operations, providing significant speed improvements over pure PowerShell implementations, especially for:

- Large string/binary conversions
- Cryptographic operations
- Compression/decompression
- Memory-intensive operations

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](https://github.com/austoonz/Convert/blob/main/CONTRIBUTING.md) guide for details.

```powershell
# Clone the repository
git clone https://github.com/austoonz/Convert.git
cd Convert

# Install dependencies
.\install_modules.ps1

# Build the module (includes Rust compilation)
.\build.ps1 -Build

# Run tests
.\build.ps1 -Test
```

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/austoonz/Convert/blob/main/LICENSE) file for details.
