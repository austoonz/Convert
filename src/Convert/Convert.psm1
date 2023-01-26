$scriptPath = Split-Path $MyInvocation.MyCommand.Path
try
{
    $files = Get-ChildItem -Path $scriptPath -Recurse | Where-Object {$_.Extension -eq '.ps1'}
    foreach ($file in $files)
    {
        . $file.FullName
    }
}
catch
{
    Write-Warning ('{0}: {1}' -f $Function, $_.Exception.Message)
    continue
}
