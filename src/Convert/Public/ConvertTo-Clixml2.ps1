<#
    .SYNOPSIS
        Converts an object to Clixml.

    .DESCRIPTION
        Converts an object to Clixml.

    .PARAMETER InputObject
        The input object to serialize

    .PARAMETER Depth
        The depth of the members to serialize

    .EXAMPLE
        $string = 'A string'
        ConvertTo-Clixml2 -InputObject $string

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>

    .EXAMPLE
        $string = 'A string'
        $string | ConvertTo-Clixml2

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        ConvertTo-Clixml2 -InputObject $string1,$string2

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        $string1,$string2 | ConvertTo-Clixml2

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml2/
#>
function ConvertTo-Clixml2 {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml2/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $InputObject,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]
        $Depth = 1
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        foreach ($io in $InputObject) {
            try {
                [System.Management.Automation.PSSerializer]::Serialize($io, $Depth)
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
