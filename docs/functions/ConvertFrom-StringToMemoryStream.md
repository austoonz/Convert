---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/
schema: 2.0.0
---

# ConvertFrom-StringToMemoryStream

## SYNOPSIS
Converts a string to a MemoryStream object.

## SYNTAX

```
ConvertFrom-StringToMemoryStream [-String] <String[]> [[-Encoding] <String>] [-Compress] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a MemoryStream object.

## EXAMPLES

### EXAMPLE 1
```
$stream = ConvertFrom-StringToMemoryStream -String 'A string'
$stream.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 2
```
$stream = 'A string' | ConvertFrom-StringToMemoryStream
$stream.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 3
```
$streams = ConvertFrom-StringToMemoryStream -String 'A string','Another string'
$streams.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

$streams\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 4
```
$streams = 'A string','Another string' | ConvertFrom-StringToMemoryStream
$streams.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

$streams\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 5
```
$stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values'
$stream.Length
```

33

$stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values' -Compress
$stream.Length

10

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

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/)

