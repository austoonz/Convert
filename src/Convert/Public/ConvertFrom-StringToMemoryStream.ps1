<#
    .SYNOPSIS
        Converts a string to a MemoryStream object.

    .DESCRIPTION
        Converts a string to a MemoryStream object.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $stream = ConvertFrom-StringToMemoryStream -String 'A string'
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $stream = 'A string' | ConvertFrom-StringToMemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $streams = ConvertFrom-StringToMemoryStream -String 'A string','Another string'
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $streams = 'A string','Another string' | ConvertFrom-StringToMemoryStream
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values'
        $stream.Length

        33

        $stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values' -Compress
        $stream.Length

        10

    .OUTPUTS
        [System.IO.MemoryStream[]]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-StringToMemoryStream/
#>
function ConvertFrom-StringToMemoryStream {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-StringToMemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding,

        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        # Default to UTF8 if no encoding specified
        if ([string]::IsNullOrEmpty($Encoding)) {
            $Encoding = 'UTF8'
        }
    }

    process {
        foreach ($s in $String) {
            try {
                # Use Rust for string-to-bytes conversion (consistent encoding behavior)
                $lengthPtr = [UIntPtr]::Zero
                $bytesPtr = [ConvertCoreInterop]::string_to_bytes($s, $Encoding, [ref]$lengthPtr)
                
                if ($bytesPtr -eq [IntPtr]::Zero) {
                    $errorMsg = GetRustError -DefaultMessage "Failed to convert string to bytes with encoding '$Encoding'"
                    throw $errorMsg
                }
                
                try {
                    # Copy bytes from Rust memory to managed array
                    $byteArray = [byte[]]::new([int]$lengthPtr.ToUInt64())
                    [System.Runtime.InteropServices.Marshal]::Copy($bytesPtr, $byteArray, 0, $byteArray.Length)
                    
                    [System.IO.MemoryStream]$stream = [System.IO.MemoryStream]::new()
                    if ($Compress) {
                        # Use leaveOpen: true to keep the MemoryStream open after GzipStream is disposed
                        $gzipStream = [System.IO.Compression.GzipStream]::new($stream, ([IO.Compression.CompressionMode]::Compress), $true)
                        $gzipStream.Write($byteArray, 0, $byteArray.Length)
                        $gzipStream.Close()
                        $stream.Position = 0
                    } else {
                        $stream.Write($byteArray, 0, $byteArray.Length)
                        $stream.Position = 0
                    }
                    $stream
                } finally {
                    # Free Rust-allocated memory
                    [ConvertCoreInterop]::free_bytes($bytesPtr)
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}