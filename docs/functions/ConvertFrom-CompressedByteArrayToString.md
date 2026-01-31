---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-CompressedByteArrayToString/
schema: 2.0.0
---

# ConvertFrom-CompressedByteArrayToString

## SYNOPSIS
Decompresses a Gzip-compressed byte array and converts it to a string.

## SYNTAX

```
ConvertFrom-CompressedByteArrayToString [-ByteArray] <Byte[]> [[-Encoding] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Decompresses a Gzip-compressed byte array and converts the result to a string
using the specified encoding.
This is the inverse operation of
ConvertFrom-StringToCompressedByteArray.

When the -Encoding parameter is not specified, the function uses lenient mode:
it first attempts to decode the decompressed bytes as UTF-8, and if that fails
(due to invalid byte sequences), it falls back to Latin-1 (ISO-8859-1) encoding
which can represent any byte value.
This is useful when the source encoding is unknown.

When -Encoding is explicitly specified, the function uses strict mode and will
return an error if the decompressed bytes are not valid for the specified encoding.

## EXAMPLES

### EXAMPLE 1
```
$compressedBytes = ConvertFrom-StringToCompressedByteArray -String 'Hello, World!'
ConvertFrom-CompressedByteArrayToString -ByteArray $compressedBytes
```

Hello, World!

## PARAMETERS

### -ByteArray
The Gzip-compressed byte array to decompress and convert to a string.

```yaml
Type: Byte[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Encoding
The encoding to use for conversion.
Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

When not specified, the function attempts UTF-8 decoding with automatic fallback
to Latin-1 for invalid byte sequences.
When specified, strict decoding is used
and an error is returned if the bytes are invalid for the chosen encoding.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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

### [String]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertFrom-CompressedByteArrayToString/](https://austoonz.github.io/Convert/functions/ConvertFrom-CompressedByteArrayToString/)

