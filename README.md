# Convert

[![Minimum Supported PowerShell Version][powershell-minimum]][powershell-github]
[![PowerShell Gallery][psgallery-img]][psgallery-site]

[powershell-minimum]: https://img.shields.io/badge/PowerShell-5.1+-blue.svg
[powershell-github]:  https://github.com/PowerShell/PowerShell
[psgallery-img]:      https://img.shields.io/powershellgallery/dt/Convert.svg
[psgallery-site]:     https://www.powershellgallery.com/packages/Convert

Branch      | CodeBuild (Windows)           | CodeBuild (Linux)           | Read the Docs              |
---         | ---                           | ---                         | ---                        |
master      | ![Build Status][cb-m-windows] | ![Build Status][cb-m-linux] | [![rtd-image][]][rtd-site] |
development | ![Build Status][cb-d-windows] | ![Build Status][cb-d-linux] | ---                        |

[cb-m-windows]:        https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoidFJnVXpTYzFvTEJwdWlmbmIyRmduRktWSVVCeldLQzJqYURuOUpYV0tkK2w1eS9KQXJ4K2Y5TWd4VFF1R1RJOWE2S0JXLzZ3MmhLMEV6R083NTAwUTk0PSIsIml2UGFyYW1ldGVyU3BlYyI6IjE1eVJ6bkcrOFhtUk04aFIiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master
[cb-m-linux]:          https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiRTN4QUhPbkdFWTZnSEcvNXRhQ21CU0grbVZJcFNKMktUZnhieUNPZkM5ay9ZYVhlU09MbVZWRXdySlM3M21nczFqemd6Tmt2OXg0SW9oRTZHTUpsaS9FPSIsIml2UGFyYW1ldGVyU3BlYyI6IjFPWWRaSWpENlZjQVZRbEsiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master
[cb-d-windows]:   https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoidFJnVXpTYzFvTEJwdWlmbmIyRmduRktWSVVCeldLQzJqYURuOUpYV0tkK2w1eS9KQXJ4K2Y5TWd4VFF1R1RJOWE2S0JXLzZ3MmhLMEV6R083NTAwUTk0PSIsIml2UGFyYW1ldGVyU3BlYyI6IjE1eVJ6bkcrOFhtUk04aFIiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=development
[cb-d-linux]:     https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiRTN4QUhPbkdFWTZnSEcvNXRhQ21CU0grbVZJcFNKMktUZnhieUNPZkM5ay9ZYVhlU09MbVZWRXdySlM3M21nczFqemd6Tmt2OXg0SW9oRTZHTUpsaS9FPSIsIml2UGFyYW1ldGVyU3BlYyI6IjFPWWRaSWpENlZjQVZRbEsiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=development

[rtd-image]:             https://readthedocs.org/projects/convert/badge/?version=latest
[rtd-site]:              https://readthedocs.org/projects/convert/

## Overview

Convert is a comprehensive PowerShell module that simplifies object conversions by providing a consistent, intuitive interface for common data transformation tasks. Whether you're working with Base64 encoding, memory streams, byte arrays, hash functions, or time conversions, this module eliminates the need to remember complex .NET methods or write custom conversion logic.

### Key Benefits:

- **Simplified Syntax**: Convert complex .NET operations into simple, memorable PowerShell commands
- **Cross-Platform**: Works seamlessly across Windows, Linux, and macOS
- **Pipeline Support**: Most functions accept pipeline input for easy integration into larger scripts

## Installation

### PowerShell Gallery

Install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/Convert):

```powershell
# Install for current user
Install-Module -Name Convert -Scope CurrentUser

# Install for all users (requires admin)
Install-Module -Name Convert -Scope AllUsers
```

### Verification

Verify the module is installed correctly:

```powershell
Get-Command -Module Convert
```

## Function Categories

### Base64 Operations
- `ConvertFrom-Base64` - Converts a Base64 encoded string to the specified output type
- `ConvertFrom-Base64ToByteArray` - Converts a Base64 encoded string to a byte array
- `ConvertFrom-Base64ToMemoryStream` - Converts a Base64 encoded string to a MemoryStream object
- `ConvertFrom-Base64ToString` - Converts a Base64 encoded string to a string
- `ConvertFrom-ByteArrayToBase64` - Converts a byte array to a Base64 encoded string
- `ConvertFrom-StringToBase64` - Converts a string to a Base64 encoded string
- `ConvertTo-Base64` - Converts an object to a Base64 encoded string

### Memory Stream Operations
- `ConvertFrom-ByteArrayToMemoryStream` - Converts a byte array to a MemoryStream object
- `ConvertFrom-MemoryStream` - Converts a MemoryStream to the specified output type
- `ConvertFrom-MemoryStreamToBase64` - Converts a MemoryStream to a Base64 encoded string
- `ConvertFrom-MemoryStreamToByteArray` - Converts a MemoryStream to a byte array
- `ConvertFrom-MemoryStreamToSecureString` - Converts a MemoryStream to a SecureString object
- `ConvertFrom-MemoryStreamToString` - Converts a MemoryStream to a string
- `ConvertFrom-StringToMemoryStream` - Converts a string to a MemoryStream object
- `ConvertTo-MemoryStream` - Converts an object to a MemoryStream object

### String & Byte Array Operations
- `ConvertFrom-StringToByteArray` - Converts a string to a byte array
- `ConvertFrom-StringToCompressedByteArray` - Converts a string to a compressed byte array
- `ConvertFrom-CompressedByteArrayToString` - Converts a compressed byte array to a string
- `ConvertTo-String` - Converts an object to a string
- `ConvertTo-TitleCase` - Converts a string to title case

### Hash Functions
- `ConvertTo-Hash` - Computes a hash from the input data
- `ConvertTo-HmacHash` - Computes a Hash-based Message Authentication Code (HMAC)

### Time Conversions
- `ConvertFrom-UnixTime` - Converts a Unix timestamp to a DateTime object
- `ConvertTo-UnixTime` - Converts a DateTime object to a Unix timestamp
- `Get-UnixTime` - Gets the current Unix timestamp

### URL Encoding
- `ConvertFrom-EscapedUrl` - Converts an escaped URL to a normal URL
- `ConvertTo-EscapedUrl` - Converts a URL to an escaped URL

### Temperature Conversions
- `ConvertTo-Celsius` - Converts a temperature from Fahrenheit to Celsius
- `ConvertTo-Fahrenheit` - Converts a temperature from Celsius to Fahrenheit

### Other Utilities
- `ConvertFrom-Clixml` - Converts a CliXml string to an object
- `ConvertTo-Clixml` - Converts an object to a CliXml string
- `ConvertFrom-HashTable` - Converts a hashtable to a custom object

## Requirements

### System Requirements
- PowerShell 5.1 or PowerShell 7.x
- Compatible with both PowerShell 7.x and Windows PowerShell 5.1
- Cross-platform support:
  - Windows
  - Linux
  - macOS

## Documentation

### Online Documentation
- [Convert Module Documentation](https://convert.readthedocs.io/)
- [Function Reference](https://convert.readthedocs.io/en/latest/functions/Convert/)

### Local Help
```powershell
# View module help
Get-Help Convert

# View help for a specific function
Get-Help ConvertTo-Base64 -Full
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup and prerequisites
- Module architecture and build process
- Coding standards and best practices
- Testing guidelines
- How to submit pull requests

### Quick Start for Contributors

```powershell
# Clone the repository
git clone https://github.com/austoonz/Convert.git
cd Convert

# Install Rust (required for building native library)
# Visit: https://rustup.rs

# Build the module
Invoke-Build

# Run tests
Invoke-Build -Task Test
```
