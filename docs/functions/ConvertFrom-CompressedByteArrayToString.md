---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/
schema: 2.0.0
---

# ConvertFrom-CompressedByteArrayToString

## SYNOPSIS
Converts a string to a byte array object.

## SYNTAX

```
ConvertFrom-CompressedByteArrayToString [-ByteArray] <Byte[]> [[-Encoding] <String>] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a byte array object.

## EXAMPLES

### EXAMPLE 1
```
$bytes = ConvertFrom-CompressedByteArrayToString -String 'A string
$bytes.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

$bytes\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Byte                                     System.ValueType

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [Byte[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/)

