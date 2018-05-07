function ConvertFrom-MemoryStreamToString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream
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
                $reader = [System.IO.StreamReader]::new($m)
                $m.Position = 0
                $reader.ReadToEnd()
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
            finally
            {
                if ($reader)
                {
                    $reader.Dispose()
                }
            }
        }
    }
}
