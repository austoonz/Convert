---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/
schema: 2.0.0
---

# ConvertTo-MemoryStream

## SYNOPSIS
Converts an object to a MemoryStream object.

## SYNTAX

```
ConvertTo-MemoryStream -String <String[]> [-Encoding <String>] [-Compress] [<CommonParameters>]
```

## DESCRIPTION
Converts an object to a MemoryStream object.

## EXAMPLES

### EXAMPLE 1
```
$string = 'A string'
$stream = ConvertTo-MemoryStream -String $string
$stream.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 2
```
$string = 'A string'
$stream = $string | ConvertTo-MemoryStream
$stream.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 3
```
$string1 = 'A string'
$string2 = 'Another string'
```

$streams = ConvertTo-MemoryStream -String $string1,$string2
$streams.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

$streams\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 4
```
$string1 = 'A string'
$string2 = 'Another string'
```

$streams = $string1,$string2 | ConvertTo-MemoryStream
$streams.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

$streams\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

## PARAMETERS

### -String
A string object for conversion.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
Position: Named
Default value: UTF8
Accept pipeline input: False
Accept wildcard characters: False
```

### -Compress
If supplied, the output will be compressed using Gzip.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.IO.MemoryStream[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/)

