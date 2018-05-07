function ConvertFrom-MemoryStreamToBase64
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [ValidateSet('ASCII','BigEndianUnicode','Default','Unicode','UTF32','UTF7','UTF8')]
        [String]
        $Encoding = 'UTF8'
    )
    
    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    Process
    {
        foreach ($m in $MemoryStream)
        {
            try
            {
                $string = ConvertFrom-MemoryStreamToString -MemoryStream $m
                ConvertFrom-StringToBase64 -String $string -Encoding $Encoding
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
