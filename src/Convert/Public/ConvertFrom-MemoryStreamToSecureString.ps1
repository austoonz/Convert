<#
    .SYNOPSIS
    Converts a Memory Stream to a Secure String

    .DESCRIPTION
    This cmdlet converts a Memory Stream to a Secure String using a Stream Reader object.

    .PARAMETER MemoryStream
    A System.IO.MemoryStream object for conversion.

    .PARAMETER Stream
    A System.IO.Stream object for conversion.

    .PARAMETER Encoding
    The encoding to use for conversion.
    Defaults to UTF8.
    Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .EXAMPLE
    $string = 'My Super Secret Value'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $memoryStream = [System.IO.MemoryStream]::new($bytes, 0, $bytes.Length)
    $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $memoryStream
    $credential = [PSCredential]::new('MyValue', $secure)

    Converts the provided MemoryStream to a SecureString.

    .LINK
    https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx

    .NOTES
    Additional information:
    https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
    https://msdn.microsoft.com/en-us/library/system.security.securestring%28v=vs.110%29.aspx
#>
function ConvertFrom-MemoryStreamToSecureString {
    [CmdletBinding(DefaultParameterSetName = 'MemoryStream')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Stream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream[]]
        $Stream,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        # Default to UTF8 if no encoding specified
        if ([string]::IsNullOrEmpty($Encoding)) {
            $Encoding = 'UTF8'
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'MemoryStream' {
                $inputObject = $MemoryStream
            }
            'Stream' {
                $inputObject = $Stream
            }
        }

        foreach ($object in $inputObject) {
            try {
                $secureString = [System.Security.SecureString]::new()
                $enc = [System.Text.Encoding]::$Encoding
                $reader = [System.IO.StreamReader]::new($object, $enc)

                while ($reader.Peek() -ge 0) {
                    $secureString.AppendChar($reader.Read())
                }
                $secureString.MakeReadOnly()

                $secureString
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            } finally {
                $reader.Dispose()
            }
        }
    }
}
