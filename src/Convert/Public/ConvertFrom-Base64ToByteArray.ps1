<#
    .SYNOPSIS
    Converts a Base 64 Encoded String to a Byte Array

    .DESCRIPTION
    Converts a Base 64 Encoded String to a Byte Array.

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
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToByteArray/')]
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
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($s in $String) {
            $ptr = $nullPtr
            try {
                $length = [UIntPtr]::Zero
                $ptr = [ConvertCoreInterop]::base64_to_bytes($s, [ref]$length)
                
                if ($ptr -eq $nullPtr) {
                    $errorMsg = GetRustError -DefaultMessage "Base64 to byte array conversion failed"
                    throw $errorMsg
                }
                
                $byteArray = New-Object byte[] $length.ToUInt64()
                [System.Runtime.InteropServices.Marshal]::Copy($ptr, $byteArray, 0, $byteArray.Length)
                
                # Output the byte array (use comma to prevent PowerShell from unrolling)
                ,$byteArray
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            } finally {
                if ($ptr -ne $nullPtr) {
                    [ConvertCoreInterop]::free_bytes($ptr)
                }
            }
        }
    }
}
