<#
    .SYNOPSIS
    Converts a Base 64 Encoded String to a Byte Array

    .DESCRIPTION
    Converts a Base 64 Encoded String to a Byte Array

    .PARAMETER String
    The Base 64 Encoded String to be converted

    .EXAMPLE
    ConvertFrom-Base64ToByteArray -String 'dGVzdA=='

    .EXAMPLE
    'SGVsbG8=' | ConvertFrom-Base64ToByteArray

    .EXAMPLE
    'SGVsbG8=', 'V29ybGQ=' | ConvertFrom-Base64ToByteArray

    .OUTPUTS
    [Byte[]]

    .LINK
    https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToByteArray/
#>
function ConvertFrom-Base64ToByteArray {
    [CmdletBinding()]
    [Alias('ConvertFrom-Base64StringToByteArray')]
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
                [System.Convert]::FromBase64String($s)
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
