<#
    .SYNOPSIS
        Converts an object to a MemoryStream object.

    .DESCRIPTION
        Converts an object to a MemoryStream object.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $string = 'A string'
        $stream = ConvertTo-MemoryStream -String $string
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string = 'A string'
        $stream = $string | ConvertTo-MemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'

        $streams = ConvertTo-MemoryStream -String $string1,$string2
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'

        $streams = $string1,$string2 | ConvertTo-MemoryStream
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .OUTPUTS
        [System.IO.MemoryStream[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/
#>
function ConvertTo-MemoryStream {
    [CmdletBinding(
        DefaultParameterSetName = 'String',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $eaSplat = @{
            ErrorAction = $userErrorActionPreference
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'String' {
                foreach ($s in $string) {
                    $params = @{
                        String   = $s
                        Encoding = $Encoding
                    }

                    if ($Compress) {
                        ConvertFrom-StringToMemoryStream @params -Compress @eaSplat
                    } else {
                        ConvertFrom-StringToMemoryStream @params @eaSplat
                    }
                }
                break
            }

            default {
                Write-Error -Message 'Invalid ParameterSetName' @eaSplat
                break
            }
        }
    }
}
