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
$string = 'A string'
```

PS C:\\\> $stream = ConvertFrom-StringToMemoryStream -String $string
PS C:\\\> $stream.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 2
```
$string = 'A string'
```

PS C:\\\> $stream = $string | ConvertFrom-StringToMemoryStream
PS C:\\\> $stream.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 3
```
$string1 = 'A string'
```

PS C:\\\> $string2 = 'Another string'

PS C:\\\> $streams = ConvertFrom-StringToMemoryStream -String $string1,$string2
PS C:\\\> $streams.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

PS C:\\\> $streams\[0\].GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     MemoryStream                             System.IO.Stream

### EXAMPLE 4
```
$string1 = 'A string'
```

PS C:\\\> $string2 = 'Another string'

PS C:\\\> $streams = $string1,$string2 | ConvertFrom-StringToMemoryStream
PS C:\\\> $streams.GetType()

IsPublic IsSerial Name                                     BaseType
-------- -------- ----                                     --------
True     True     Object\[\]                                 System.Array

PS C:\\\> $streams\[0\].GetType()

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

