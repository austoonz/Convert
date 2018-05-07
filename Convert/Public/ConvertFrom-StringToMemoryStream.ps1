function ConvertFrom-StringToMemoryStream
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String
    )

    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    Process
    {
        foreach ($s in $String)
        {
            try
            {
                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($s)
                $writer.Flush()
                $stream
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}