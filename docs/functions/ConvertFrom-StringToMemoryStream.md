# ConvertFrom-StringToMemoryStream

## SYNOPSIS
Converts a string to a MemoryStream object.

## SYNTAX

```
ConvertFrom-StringToMemoryStream [-String] <String[]> [<CommonParameters>]
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

```
$streams[0].GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 4
```
'A string','Another string'
$streams = 'A string','Another string' | ConvertFrom-StringToMemoryStream
$streams.GetType()
```

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object[]                                 System.Array

```
$streams[0].GetType()
```

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
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

