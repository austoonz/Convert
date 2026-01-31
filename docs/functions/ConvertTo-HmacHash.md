---
external help file: Convert-help.xml
Module Name: Convert
online version: https://en.wikipedia.org/wiki/HMAC
schema: 2.0.0
---

# ConvertTo-HmacHash

## SYNOPSIS
Computes a Hash-based Message Authentication Code (HMAC).

## SYNTAX

### ProvidedKey (Default)
```
ConvertTo-HmacHash -InputObject <Object> -Key <Byte[]> [-Algorithm <String>] [-Encoding <String>]
 [-OutputFormat <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### GenerateKey
```
ConvertTo-HmacHash -InputObject <Object> [-GenerateKey] [-KeySize <Int32>] [-Algorithm <String>]
 [-Encoding <String>] [-OutputFormat <String>] [-ReturnGeneratedKey] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-HmacHash function computes a Hash-based Message Authentication Code (HMAC) using the specified algorithm.
It supports various input types (string, byte array, memory stream), different hash algorithms, and multiple output formats.

This function uses a high-performance Rust implementation for HMAC computation, providing significant performance
improvements over pure .NET implementations while maintaining full backward compatibility.

## EXAMPLES

### EXAMPLE 1
```
$key = [byte[]]@(1..32)
ConvertTo-HmacHash -InputObject "Hello, World!" -Key $key
```

Computes the HMACSHA256 hash of the string "Hello, World!" using the provided key and returns it as a hexadecimal string.

### EXAMPLE 2
```
$key = [byte[]]@(1..32)
"Hello, World!" | ConvertTo-HmacHash -Key $key -OutputFormat Base64
```

Computes the HMACSHA256 hash of the string "Hello, World!" using the provided key and returns it as a Base64-encoded string.

### EXAMPLE 3
```
$key = [byte[]]@(1..32)
$data = [System.Text.Encoding]::UTF8.GetBytes("Hello, World!")
ConvertTo-HmacHash -InputObject $data -Key $key -Algorithm HMACSHA512
```

Computes the HMACSHA512 hash of the byte array representation of "Hello, World!" and returns it as a hexadecimal string.

### EXAMPLE 4
```
$stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes("Hello, World!"))
ConvertTo-HmacHash -InputObject $stream -Key $key -OutputFormat ByteArray
```

Computes the HMACSHA256 hash of the memory stream containing "Hello, World!" and returns it as a byte array.

### EXAMPLE 5
```
$result = ConvertTo-HmacHash -InputObject "Hello, World!" -GenerateKey -ReturnGeneratedKey
$result.Hash   # The computed hash
$result.Key    # The generated key
```

Generates a secure random key, computes the HMACSHA256 hash of "Hello, World!", and returns both the hash and the generated key.

## PARAMETERS

### -InputObject
The data for which to compute the HMAC.
Can be a string, byte array, or memory stream.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Key
The secret key to use for HMAC generation.
Must be a byte array.

```yaml
Type: Byte[]
Parameter Sets: ProvidedKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GenerateKey
Switch to automatically generate a cryptographically secure key.
If specified, the Key parameter is not required.

```yaml
Type: SwitchParameter
Parameter Sets: GenerateKey
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeySize
The size in bytes of the key to generate when using the GenerateKey switch.
Defaults to 32 bytes (256 bits).

```yaml
Type: Int32
Parameter Sets: GenerateKey
Aliases:

Required: False
Position: Named
Default value: 32
Accept pipeline input: False
Accept wildcard characters: False
```

### -Algorithm
The HMAC algorithm to use.
Defaults to 'HMACSHA256'.
Valid options: 'HMACSHA256', 'HMACSHA384', 'HMACSHA512'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: HMACSHA256
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding
The text encoding to use when converting string inputs to bytes.
Defaults to 'UTF8'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFormat
The format in which to return the hash.
'Hex' (default): Returns the hash as a hexadecimal string.
'Base64': Returns the hash as a Base64-encoded string.
'ByteArray': Returns the hash as a byte array.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Hex
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnGeneratedKey
When used with GenerateKey, also returns the generated key along with the hash.

```yaml
Type: SwitchParameter
Parameter Sets: GenerateKey
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String] or [Byte[]] or [PSCustomObject]
### Returns a string (hex or Base64) or byte array depending on the OutputFormat parameter.
### If ReturnGeneratedKey is specified with GenerateKey, returns a PSCustomObject with Hash and Key properties.
## NOTES
Performance: This function uses a Rust-based implementation that provides significant performance improvements
for HMAC computation, especially with large inputs or batch processing scenarios.

For security-sensitive applications:
- HMACSHA256 is recommended for most applications
- Use a key length of at least 32 bytes (256 bits) for HMACSHA256
- Use a key length of at least 48 bytes (384 bits) for HMACSHA384
- Use a key length of at least 64 bytes (512 bits) for HMACSHA512
- Store keys securely and never hardcode them in scripts

## RELATED LINKS

[https://en.wikipedia.org/wiki/HMAC](https://en.wikipedia.org/wiki/HMAC)

