# ConvertTo-Clixml

## SYNOPSIS
Converts an object to Clixml.

## SYNTAX

```
ConvertTo-Clixml [-InputObject] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
Converts an object to Clixml.

## EXAMPLES

### EXAMPLE 1
```
$string = 'A string'

ConvertTo-Clixml -InputObject $string

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
```

### EXAMPLE 2
```
$string = 'A string'

$string | ConvertTo-Clixml

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
```

### EXAMPLE 3
```
$string1 = 'A string'

$string2 = 'Another string'
ConvertTo-Clixml -InputObject $string1,$string2

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>
```

### EXAMPLE 4
```
$string1 = 'A string'

$string2 = 'Another string'
$string1,$string2 | ConvertTo-Clixml

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>
```

## PARAMETERS

### -InputObject
An object for conversion.

```yaml
Type: PSObject
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

### [String[]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml/)

