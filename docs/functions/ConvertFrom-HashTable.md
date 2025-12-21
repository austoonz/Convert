---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-HashTable/
schema: 2.0.0
---

# ConvertFrom-HashTable

## SYNOPSIS
Converts HashTable objects to PSCustomObject objects.

## SYNTAX

```
ConvertFrom-HashTable [[-HashTable] <Hashtable[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts HashTable objects to PSCustomObject objects.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-HashTable -HashTable @{'foo'='bar'}
```

Returns a PSCustomObject with the property 'foo' with value 'bar'.

### EXAMPLE 2
```
@{'foo'='bar'} | ConvertFrom-HashTable
```

Returns a PSCustomObject with the property 'foo' with value 'bar'.

## PARAMETERS

### -HashTable
A list of HashTable objects to convert

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSCustomObject[]]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertFrom-HashTable/](https://austoonz.github.io/Convert/functions/ConvertFrom-HashTable/)

