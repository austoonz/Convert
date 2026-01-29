<#
    .SYNOPSIS
    Converts a Byte Array to a MemoryStream

    .DESCRIPTION
    Converts a Byte Array to a MemoryStream

    .PARAMETER ByteArray
    The Byte Array to be converted

    .EXAMPLE
    ConvertFrom-ByteArrayToMemoryStream -ByteArray ([Byte[]] (,0xFF * 100))

    .EXAMPLE
    $bytes = [Byte[]]@(72, 101, 108, 108, 111)
    ,$bytes | ConvertFrom-ByteArrayToMemoryStream

    .OUTPUTS
    [System.IO.MemoryStream[]]

    .LINK
    https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToMemoryStream/
#>
function ConvertFrom-ByteArrayToMemoryStream {
    [CmdletBinding()]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Bytes')]
        [System.Byte[]]
        $ByteArray
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        try {
            [System.IO.MemoryStream]::new($ByteArray, 0, $ByteArray.Length)
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}
