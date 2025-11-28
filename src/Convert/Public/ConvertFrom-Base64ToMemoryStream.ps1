<#
    .SYNOPSIS
        Converts a base64 encoded string to a MemoryStream.

    .DESCRIPTION
        Converts a base64 encoded string to a MemoryStream.

    .PARAMETER String
        A Base64 Encoded String

    .EXAMPLE
        ConvertFrom-Base64ToMemoryStream -String 'QSBzdHJpbmc='

    .EXAMPLE
        ConvertFrom-Base64ToMemoryStream -String 'A string','Another string'

    .EXAMPLE
        'QSBzdHJpbmc=' | ConvertFrom-Base64ToMemoryStream

    .EXAMPLE
        'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToMemoryStream

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64ToMemoryStream/
#>
function ConvertFrom-Base64ToMemoryStream {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64ToMemoryStream/')]
    [OutputType('System.IO.MemoryStream')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Base64String')]
        [String[]]
        $String
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        foreach ($s in $String) {
            try {
                $byteArray = ConvertFrom-Base64ToByteArray -String $s
                ConvertFrom-ByteArrayToMemoryStream -ByteArray $byteArray
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
