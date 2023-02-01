---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-EscapedUrl/
schema: 2.0.0
---

# ConvertFrom-EscapedUrl

## SYNOPSIS

Converts an escaped URL back to a standard Url.

## SYNTAX

```powershell
ConvertFrom-EscapedUrl [[-Url] <String[]>] [<CommonParameters>]
```

## DESCRIPTION

Converts an escaped URL back to a standard Url.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-EscapedUrl -Url 'http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20value'

Returns the string \`http://test.com?value=my value\`.
```

## PARAMETERS

### -Url

The escaped URL to convert.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [string]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-EscapedUrl/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-EscapedUrl/)
