# ConvertFrom-StringToCompressedByteArray

## SYNOPSIS
Converts a string to a compressed byte array object.

## SYNTAX

```
ConvertFrom-StringToCompressedByteArray [-String] <String[]> [[-Encoding] <String>] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a compressed byte array object.

## EXAMPLES

### EXAMPLE 1
```
$bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
$bytes.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Byte[]                                   System.Array

$bytes[0].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Byte                                     System.ValueType
```

## PARAMETERS

### -String
A string object for conversion.

```yaml
Type: String[]
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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.Collections.Generic.List[Byte[]]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/)

