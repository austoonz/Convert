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
        ConvertFrom-Clixml -String $xml

        ThisIsMyString

    .EXAMPLE
        $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        $xml | ConvertFrom-Clixml

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
        ConvertFrom-Clixml -String $xml,$xml2

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
        $xml,$xml2 | ConvertFrom-Clixml

        ThisIsMyString
        This is another string

    .OUTPUTS
        [Object[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml/
#>
function ConvertFrom-Clixml
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('CliXml')]
        [String[]]
        $String
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        foreach ($s in $String)
        {
            try
            {
                [System.Management.Automation.PSSerializer]::Deserialize($s)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
