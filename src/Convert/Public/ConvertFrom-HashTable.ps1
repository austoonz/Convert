<#
    .SYNOPSIS
    Converts HashTable objects to PSCustomObject objects.

    .DESCRIPTION
    Converts HashTable objects to PSCustomObject objects.

    .PARAMETER HashTable
    A list of HashTable objects to convert

    .EXAMPLE
    PS> ConvertFrom-HashTable -HashTable @{'foo'='bar'}

    Returns a PSCustomObject with the property 'foo' with value 'bar'.

    .EXAMPLE
    PS> @{'foo'='bar'} | ConvertFrom-HashTable

    Returns a PSCustomObject with the property 'foo' with value 'bar'.

    .OUTPUTS
    [PSCustomObject[]]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertFrom-HashTable/
#>
function ConvertFrom-HashTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [HashTable[]]$HashTable
    )

    process {
        foreach ($h in $HashTable) {
            [PSCustomObject]$h
        }
    }
}
