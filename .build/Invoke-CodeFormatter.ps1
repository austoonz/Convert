param(
    [Parameter(Mandatory)]
    [string]$RepositoryRoot,
    
    [Parameter(Mandatory)]
    [string]$SourcePath
)

Import-Module PSScriptAnalyzer -ErrorAction Stop

$formatterSettings = @{
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $true
            IgnoreOneLineBlock = $true
            NewLineAfter = $false
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }
    }
}

$files = [System.IO.Directory]::GetFiles($SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
$modifiedFiles = @()

foreach ($file in $files) {
    $contentBefore = [System.IO.File]::ReadAllText($file)
    
    $result = Invoke-Formatter -ScriptDefinition $contentBefore -Settings $formatterSettings
    
    if ($result -ne $contentBefore) {
        $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
        [System.IO.File]::WriteAllText($file, $result, $utf8WithBom)
        $relativePath = $file.Replace($RepositoryRoot, '').TrimStart('\', '/')
        $modifiedFiles += $relativePath
        Write-Host "  Modified: $relativePath" -ForegroundColor Gray
    }
}

if ($modifiedFiles.Count -eq 0) {
    Write-Host 'All files already formatted correctly.' -ForegroundColor Green
} else {
    Write-Host "Formatted $($modifiedFiles.Count) file(s)." -ForegroundColor Green
}

exit 0
