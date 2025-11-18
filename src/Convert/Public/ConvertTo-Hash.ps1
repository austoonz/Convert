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
    [Alias('Get-Hash')]
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
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($s in $String) {
            $ptr = $nullPtr
            try {
                # Call Rust implementation for hash computation
                $ptr = [ConvertCoreInterop]::compute_hash($s, $Algorithm, $Encoding)
                
                if ($ptr -eq $nullPtr) {
                    $errorMsg = GetRustError -DefaultMessage "Hash computation failed for algorithm '$Algorithm' with encoding '$Encoding'"
                    throw $errorMsg
                }
                
                # Marshal the result back to PowerShell
                [System.Runtime.InteropServices.Marshal]::PtrToStringUTF8($ptr)
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            } finally {
                # Always free the allocated memory
                if ($ptr -ne $nullPtr) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }
    }
}
