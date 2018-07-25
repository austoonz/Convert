$scriptPath = Split-Path $MyInvocation.MyCommand.Path
try
{
    $subFolders = Get-ChildItem -Path $scriptPath -Attributes D
    $files = Get-ChildItem -Path $subFolders.FullName | Where-Object {$_.Extension -eq '.ps1'}
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
