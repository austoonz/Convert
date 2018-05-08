function ConvertTo-MemoryStream
{
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
        $String
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'String'
            {
                $InputObject = $String
                $Function = 'ConvertFrom-StringToMemoryStream'
                break
            }

            default
            {
                Write-Error -Message 'Invalid ParameterSetName' -ErrorAction $userErrorActionPreference
                break
            }
        }

        if ($InputObject)
        {
            $InputObject | & $Function -ErrorAction $userErrorActionPreference
        }
    }
}
