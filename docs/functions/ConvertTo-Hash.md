---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-Hash/
schema: 2.0.0
---

# ConvertTo-Hash

## SYNOPSIS

Converts a string to a hash.

## SYNTAX

```powershell
ConvertTo-Hash [-String <String>] [-Algorithm <String>] [<CommonParameters>]
```

## DESCRIPTION

Converts a string to a hash.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-Hash -String 'MyString'
38F92FF0761E08356B7C51C5A1ED88602882C2768F37C2DCC3F0AC6EE3F950F5
```

## PARAMETERS

### -String

A string to convert.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Algorithm

The hashing algorithm to use.
Defaults to 'SHA256'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: SHA256
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

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Hash/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Hash/)
