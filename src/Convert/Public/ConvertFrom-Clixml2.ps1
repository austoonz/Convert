<#
    .SYNOPSIS
        Converts Clixml to an object.

    .DESCRIPTION
        Converts Clixml to an object.

    .PARAMETER String
        Clixml as a string object.

    .EXAMPLE
        $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        ConvertFrom-Clixml2 -String $xml

        ThisIsMyString

    .EXAMPLE
        $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        $xml | ConvertFrom-Clixml2

        ThisIsMyString

    .EXAMPLE
        $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        $xml2 = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>This is another string</S>
</Objs>
"@
        ConvertFrom-Clixml2 -String $xml,$xml2

        ThisIsMyString
        This is another string

    .EXAMPLE
        $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        $xml2 = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>This is another string</S>
</Objs>
"@
        $xml,$xml2 | ConvertFrom-Clixml2

        ThisIsMyString
        This is another string

    .OUTPUTS
        [Object[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml2/
#>
function ConvertFrom-Clixml2 {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml2/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        Set-Variable -Name 'SPLIT' -Value '(?<!^)(?=<Objs)' -Option 'Constant'
    }

    process {
        foreach ($s in $String) {
            try {
                foreach ($record in ($s -split $SPLIT)) {
                    [System.Management.Automation.PSSerializer]::Deserialize($record)
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
