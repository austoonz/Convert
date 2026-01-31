---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToString/
schema: 2.0.0
---

# ConvertFrom-ByteArrayToString

## SYNOPSIS
Converts a byte array to a string using the specified encoding.

## SYNTAX

```
ConvertFrom-ByteArrayToString [-ByteArray] <Byte[]> [[-Encoding] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Converts a byte array to a string using the specified encoding.
This is the inverse operation of ConvertFrom-StringToByteArray.

When the -Encoding parameter is not specified, the function uses lenient mode:
it first attempts to decode the bytes as UTF-8, and if that fails (due to invalid
byte sequences), it falls back to Latin-1 (ISO-8859-1) encoding which can represent
any byte value.
This is useful when the source encoding is unknown.

When -Encoding is explicitly specified, the function uses strict mode and will
return an error if the bytes are not valid for the specified encoding.

## EXAMPLES

### EXAMPLE 1
```
$bytes = [byte[]]@(72, 101, 108, 108, 111)
ConvertFrom-ByteArrayToString -ByteArray $bytes
```

Hello

### EXAMPLE 2
```
$bytes = ConvertFrom-StringToByteArray -String 'Hello, World!'
ConvertFrom-ByteArrayToString -ByteArray $bytes
```

Hello, World!

### EXAMPLE 3
```
$bytes1, $bytes2 | ConvertFrom-ByteArrayToString -Encoding 'UTF8'
```

Converts multiple byte arrays from the pipeline to strings.

## PARAMETERS

### -ByteArray
The array of bytes to convert.

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

[https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToString/](https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToString/)

