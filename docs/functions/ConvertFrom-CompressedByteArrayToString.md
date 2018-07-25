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

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object[]                                 System.Array

$bytes[0].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Byte                                     System.ValueType
```

## PARAMETERS

### -ByteArray
{{Fill ByteArray Description}}

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
{{Fill Encoding Description}}

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

### [Byte[]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/)

