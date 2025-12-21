<#
    .SYNOPSIS
        Converts MemoryStream to a byte array.

    .DESCRIPTION
        Converts MemoryStream to a byte array.

    .PARAMETER MemoryStream
        A System.IO.MemoryStream object for conversion.

    .PARAMETER Stream
        A System.IO.Stream object for conversion.

    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        ConvertFrom-MemoryStreamToByteArray -MemoryStream $stream

    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        $stream | ConvertFrom-MemoryStreamToByteArray

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        ConvertFrom-MemoryStreamToByteArray -MemoryStream $stream1,$stream2

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        $stream1,$stream2 | ConvertFrom-MemoryStreamToByteArray

    .OUTPUTS
        [Byte[]]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-MemoryStreamToByteArray/
#>
function ConvertFrom-MemoryStreamToByteArray {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-MemoryStreamToByteArray/')]
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
        $Stream
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
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
                if ($PSCmdlet.ParameterSetName -eq 'MemoryStream') {
                    $object.Position = 0
                }
                $object.ToArray()
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
