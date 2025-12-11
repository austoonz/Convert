<#
    .SYNOPSIS
    Converts a string to a hash.

    .DESCRIPTION
    Converts a string to a hash.

    .PARAMETER String
    A string to convert.

    .PARAMETER Algorithm
    The hashing algorithm to use. Defaults to 'SHA256'.

    .EXAMPLE
    ConvertTo-Hash -String 'MyString'
    38F92FF0761E08356B7C51C5A1ED88602882C2768F37C2DCC3F0AC6EE3F950F5

    .OUTPUTS
    [String[]]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertTo-Hash/
#>
function ConvertTo-Hash {
    [CmdletBinding()]
    #[Alias('Get-Hash')]
    param (
        [Parameter(ParameterSetName='String', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$String,

        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'SHA256',

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
    )

    begin {
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    }

    process {
        foreach ($s in $String) {
            $sb = [System.Text.StringBuilder]::new()
            $hashAlgorithm.ComputeHash([System.Text.Encoding]::$Encoding.GetBytes($s)) | ForEach-Object {
                $null = $sb.Append('{0:X2}' -f $_)
            }
            $sb.ToString()
        }
    }

    end {
        if ($hashAlgorithm) {$hashAlgorithm.Dispose()}
        if ($sb) {$null = $sb.Clear()}
    }
}
