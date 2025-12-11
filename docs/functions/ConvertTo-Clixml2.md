---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml2/
schema: 2.0.0
---

# ConvertTo-Clixml2

## SYNOPSIS

Converts an object to Clixml.

## SYNTAX

```powershell
ConvertTo-Clixm2 [-InputObject] <PSObject> [[-Depth] <Int32>] [<CommonParameters>]
```

## DESCRIPTION

Converts an object to Clixml.

## EXAMPLES

### EXAMPLE 1

```powershell
$string = 'A string'
ConvertTo-Clixml2 -InputObject $string

\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>A string\</S\>
\</Objs\>
```

### EXAMPLE 2

```powershell
$string = 'A string'
$string | ConvertTo-Clixml2

\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>A string\</S\>
\</Objs\>
```

### EXAMPLE 3

```powershell
$string1 = 'A string'
$string2 = 'Another string'
ConvertTo-Clixml2 -InputObject $string1,$string2

\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>A string\</S\>
\</Objs\>
\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>Another string\</S\>
\</Objs\>
```

### EXAMPLE 4

```powershell
$string1 = 'A string'
$string2 = 'Another string'
$string1,$string2 | ConvertTo-Clixml2

\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>A string\</S\>
\</Objs\>
\<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"\>
\<S\>Another string\</S\>
\</Objs\>
```

## PARAMETERS

### -InputObject

The input object to serialize

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

### -Depth

The depth of the members to serialize

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml2/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml2/)
