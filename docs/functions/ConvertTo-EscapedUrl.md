---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertTo-EscapedUrl/
schema: 2.0.0
---

# ConvertTo-EscapedUrl

## SYNOPSIS
Converts a URL to an escaped Url.

## SYNTAX

```
ConvertTo-EscapedUrl [[-Url] <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts a URL to an escaped Url.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-EscapedUrl -Url 'http://test.com?value=my value'
```

Returns the string \`http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20value\`.

## PARAMETERS

### -Url
The URL to escape.

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

### [string]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertTo-EscapedUrl/](https://austoonz.github.io/Convert/functions/ConvertTo-EscapedUrl/)

