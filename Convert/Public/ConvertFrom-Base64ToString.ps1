<#
    .SYNOPSIS
        Converts a base64 encoded string to a string.
    
    .DESCRIPTION
        Converts a base64 encoded string to a string.
    
    .PARAMETER String
        A Base64 Encoded String
    
    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.
    
    .EXAMPLE
        PS C:\> ConvertFrom-Base64ToString -String 'QSBzdHJpbmc='
        A string
    
    .EXAMPLE
        PS C:\> ConvertTo-Base64 -String 'A string','Another string'
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=
    
    .EXAMPLE
        PS C:\> 'QSBzdHJpbmc=' | ConvertFrom-Base64ToString
        A string

    .EXAMPLE
        PS C:\> 'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToString
        A string
        Another string
    
    .EXAMPLE
        PS C:\> ConvertTo-Base64 -String 'A string' -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        
    .OUTPUTS
        String
#>
function ConvertFrom-Base64ToString
{
    [CmdletBinding()]
    [OutputType('String')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String] $Encoding = 'UTF8'
    )
    
    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    Process
    {
        foreach ($s in $String)
        {
            try
            {
                $bytes = [System.Convert]::FromBase64String($s)
                [System.Text.Encoding]::$Encoding.GetString($bytes)    
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
