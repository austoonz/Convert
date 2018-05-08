<#
    .SYNOPSIS
        Converts a string to a base64 encoded string.
    
    .DESCRIPTION
        Converts a string to a base64 encoded string.
    
    .PARAMETER String
        A string object for conversion.
    
    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.
    
    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> ConvertFrom-StringToBase64 -String $string
        QSBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $string | ConvertFrom-StringToBase64
        QSBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> ConvertFrom-StringToBase64 -String $string -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $string | ConvertFrom-StringToBase64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        PS C:\> ConvertFrom-StringToBase64 -String $string1,$string2
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        PS C:\> $string1,$string2 | ConvertFrom-StringToBase64
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        PS C:\> ConvertFrom-StringToBase64 -String $string1,$string2 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        PS C:\> $string1,$string2 | ConvertFrom-StringToBase64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToBase64/
#>
function ConvertFrom-StringToBase64
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToBase64/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    process
    {
        foreach ($s in $String)
        {
            try
            {
                $bytes = [System.Text.Encoding]::$Encoding.GetBytes($s)
                [System.Convert]::ToBase64String($bytes)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
