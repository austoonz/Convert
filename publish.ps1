Import-Module -Name AWS.Tools.CodeBuild
Set-DefaultAWSRegion -Region 'us-west-2'
$buildStatus = foreach ($project in @('austoonz-Convert-Linux','austoonz-Convert-Windows')) {
    $builds = (Get-CBBuildIdListForProject -ProjectName $project | Select-Object -First 1| Get-CBBuildBatch).Builds
    foreach ($build in $builds) {
        [PSCustomObject]([ordered]@{
            Project = $project
            ResolvedSourceVersion = $build.ResolvedSourceVersion
            BuildStatus = $build.BuildStatus
        })
    }
}

if (($buildStatus.ResolvedSourceVersion | Select-Object -Unique).Count -ne 1) {
    Write-Host 'Found to many build versions. Failing...'
}

$uniqueBuildStatus = ($buildStatus.BuildStatus | Select-Object -Unique).Value
if ($uniqueBuildStatus.Count -ne 1 -and $uniqueBuildStatus -ne 'SUCCEEDED') {
    Write-Host 'At least one build failed. Failing...'
}

Write-Host 'We had a succesful build. Finding output artifact...'
