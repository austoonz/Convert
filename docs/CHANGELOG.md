# Changelog

## Version v2.0.4-alpha

### Breaking Changes

* **Rust Migration**: Module internals have been completely rewritten in Rust for improved performance and memory safety
* **Removed Functions**:
  * `ConvertFrom-Clixml` - Moved to the `ConvertClixml` module
  * `ConvertTo-Clixml` - Moved to the `ConvertClixml` module
* **Removed Aliases**:
  * `Get-Hash` - Use `ConvertTo-Hash` directly instead

### New Features

* **Added `-Encoding` parameter** to `ConvertFrom-MemoryStreamToString` (Issue #21)
* **Added `-Encoding` parameter** to `ConvertFrom-MemoryStreamToSecureString` (Issue #21)
* **Added pipeline support** to `ConvertFrom-Base64ToByteArray` (Issue #16)
* **Added pipeline support** to `ConvertFrom-ByteArrayToMemoryStream` (Issue #16)

### Changed

* **Consolidated `-MemoryStream` parameter** into `-Stream` for `ConvertFrom-MemoryStreamToString` and `ConvertTo-String` (Issue #17)
  * `-MemoryStream` is now an alias for `-Stream` for backward compatibility

### Fixed

* `ConvertFrom-MemoryStream` now correctly passes `-Encoding` parameter to `ConvertFrom-MemoryStreamToString` for consistent behavior
* `ConvertFrom-Base64ToString` and `ConvertTo-String` now handle binary data correctly (Issue #14)

## Version v1.5.0 (2023-03-17)

* **New Functions**:
  * `ConvertFrom-HashTable`

## Version v1.4.0 (2023-02-27)

### ConvertFrom-ByteArrayToBase64

* Added support for compressing the ByteArray

## Version v1.3.1 (2023-03-01)

* Module Changes:
  * Minor spelling corrections throughout
* Build Changes:
  * Minor spelling corrections throughout
  * CHANGELOG improvements:
    * Updated CHANGELOG to pass markdown linter, remove duplicate titles, and increase readability
    * Removed duplicate copy of additional CHANGELOG that contained outdated information
    * Placed CHANGELOG in correct location so that Read the docs can correctly display the correct CHANGELOG
  * Improved Read the docs integration by moving to Python 3 based build

## Version v1.3.0 (2023-02-15)

* **New Functions**:
  * `ConvertTo-Hash`

## Version v1.2.1 (2023-02-04)

* **Fixes**:
  * Fixes default in `ConvertFrom-Base64`
  * Added parameter sets for `ConvertFrom-Base64`

## Version v1.2.0 (2023-01-31)

* **New Functions**:
  * `ConvertFrom-EscapedUrl`
  * `ConvertTo-EscapedUrl`
  * `ConvertTo-TitleCase`

## Version v1.1.0 (2023-01-25)

* **New Functions**:
  * `ConvertFrom-UnixTime`
  * `ConvertTo-UnixTime`
  * `Get-UnixTime`

## Version v1.0.0 (2023-01-18)

### Breaking Changes

* `ConvertFrom-MemoryStreamToBase64`: removed the Encoding parameter and changed the logic to use a ByteArray as an intermediate format. This fixes support for handling the memory stream objects required when using the AWS Key Management Service cmdlets.
* **New Functions**:
  * `ConvertFrom-Base64ToMemoryStream`
  * `ConvertFrom-MemoryStreamToByteArray`

## Version v0.6.0 (2020-05-25)

* **Fixes**:
  * Fixed Compression when using ConvertTo-Base64 with a MemoryStream.
* **Formatting**:
  * Formatting updates to resolve Script Analyzer errors

## Version v0.5.0 (2020-04-01)

* **New Functions**:
  * `ConvertFrom-Base64ToByteArray`
  * `ConvertFrom-ByteArrayToMemoryStream`
  * `ConvertFrom-MemoryStreamToString`
* **New Aliases**:
  * `ConvertFrom-Base64StringToByteArray` -> `ConvertFrom-Base64ToByteArray`
  * `ConvertFrom-Base64StringToString` -> `ConvertFrom-Base64ToString`
  * `ConvertFrom-ByteArrayToBase64String` -> `ConvertFrom-ByteArrayToBase64`

## Version v0.4.1 (2020-04-01)

* `ConvertTo-CliXml`
  * Fixed support for a single string that contains multiple Clixml records.

## Version v0.4.0 (2019-04-27)

* **Manifest Updates**:
  * Updated CompatiblePSEditions
  * Added PrivateData Tags to indicate platform compatibility

## Version v0.3.5 (2019-03-07)

* `ConvertTo-CliXml`:
  * Added Depth parameter to "ConvertTo-CliXml"

## Version v0.2.1.x (2018-08-30)

* `ConvertFrom-Base64` - Initial Release
* `ConvertFrom-MemoryStream` - Initial Release

## Version v0.2.0.x (2018-07-24)

* `ConvertFrom-CompressedByteArrayToString` - Initial Release
* `ConvertFrom-MemoryStreamToString`
  * Added "System.IO.Stream" support
  * Added the alias "ConvertFrom-StreamToString"
* `ConvertFrom-StringToByteArray` - Initial Release
* `ConvertFrom-StringToMemoryStream`
  * Added compression support
* `ConvertTo-MemoryStream`
  * Added compression support
* `ConvertTo-String`
  * Added "System.IO.Stream" support

## Version 0.1.1.x (2018-05-29)

* `ConvertFrom-Base64ToString`:
  * Added "-Decompress" support
* `ConvertFrom-ByteArrayToBase64`:
  * Initial Release
* `ConvertFrom-CompressedByteArrayToString`
  * Initial Release
* `ConvertFrom-StringToBase64`
  * Added "-Compress" support
* `ConvertFrom-StringToCompressedByteArray`
  * Initial Release
* `ConvertTo-Base64`
  * Added "-Compress" support
* `ConvertTo-String`
  * Added "-Decompress" support

## Version 0.1.0.0 (2018-05-07)

* `ConvertFrom-Base64ToString` - Initial Release
* `ConvertFrom-Clixml` - Initial Release
* `ConvertFrom-MemoryStreamToBase64` - Initial Release
* `ConvertFrom-MemoryStreamToString` - Initial Release
* `ConvertFrom-StringToBase64` - Initial Release
* `ConvertFrom-StringToMemoryStream` - Initial Release
* `ConvertTo-Base64` - Initial Release
* `ConvertTo-Clixml` - Initial Release
* `ConvertTo-MemoryStream` - Initial Release
* `ConvertTo-String` - Initial Release
