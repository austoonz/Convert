---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/
schema: 2.0.0
---

# ConvertFrom-ByteArrayToBase64

## SYNOPSIS
Converts a byte array to a base64 encoded string.

## SYNTAX

```
ConvertFrom-ByteArrayToBase64 [-ByteArray] <Byte[]> [[-Encoding] <String>] [<CommonParameters>]
```

## DESCRIPTION
Converts a byte array to a base64 encoded string.

## EXAMPLES

### EXAMPLE 1
```
$bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
ConvertFrom-ByteArrayToBase64 -ByteArray $bytes
```

H4sIAAAAAAAAC3NUKC4pysxLBwCMN9RgCAAAAA==

## PARAMETERS

### -ByteArray
A byte array object for conversion.

```yaml
Type: Byte[]
Parameter Sets: (All)
Aliases: Bytes

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Encoding
The encoding to use for conversion.
Defaults to UTF8.
Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: UTF8
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/)

