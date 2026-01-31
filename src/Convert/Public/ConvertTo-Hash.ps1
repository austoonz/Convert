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
    https://austoonz.github.io/Convert/functions/ConvertTo-Hash/
#>
function ConvertTo-Hash {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'String', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$String,

        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'SHA256',

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
        # Default to UTF8 if no encoding specified
        if ([string]::IsNullOrEmpty($Encoding)) {
            $Encoding = 'UTF8'
        }
    }

    process {
        foreach ($s in $String) {
            try {
                $ptr = $nullPtr
                try {
                    $ptr = [ConvertCoreInterop]::compute_hash($s, $Algorithm, $Encoding)
                    
                    if ($ptr -eq $nullPtr) {
                        $errorMsg = GetRustError -DefaultMessage "Hash computation failed for algorithm '$Algorithm' with encoding '$Encoding'"
                        throw $errorMsg
                    }
                    
                    ConvertPtrToString -Ptr $ptr
                } finally {
                    if ($ptr -ne $nullPtr) {
                        [ConvertCoreInterop]::free_string($ptr)
                    }
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
