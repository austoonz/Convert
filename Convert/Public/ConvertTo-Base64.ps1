function ConvertTo-Base64
{
    [CmdletBinding(
        DefaultParameterSetName = 'String',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/')]
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

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
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
                $Function = 'ConvertFrom-StringToBase64'
                $splat = @{
                    Encoding = $Encoding
                }
                break
            }

            'MemoryStream'
            {
                $InputObject = $MemoryStream
                $Function = 'ConvertFrom-MemoryStreamToBase64'
                $splat = @{
                    Encoding = $Encoding
                }
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
            $InputObject | & $Function @splat -ErrorAction $userErrorActionPreference
        }
    }
}
