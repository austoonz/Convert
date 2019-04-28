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

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string'
        QSBzdHJpbmc=

    .EXAMPLE
        'A string' | ConvertFrom-StringToBase64
        QSBzdHJpbmc=

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string' -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        'A string' | ConvertFrom-StringToBase64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string','Another string'
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        'A string','Another string' | ConvertFrom-StringToBase64
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string','Another string' -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        'A string','Another string' | ConvertFrom-StringToBase64 -Encoding Unicode
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
        $Encoding = 'UTF8',

        [Parameter(Mandatory = $false)]
        [Switch]
        $Compress
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
                if ($Compress)
                {
                    $bytes = ConvertFrom-StringToCompressedByteArray -String $s -Encoding $Encoding
                }
                else
                {
                    $bytes = [System.Text.Encoding]::$Encoding.GetBytes($s)
                }

                [System.Convert]::ToBase64String($bytes)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
