$moduleName = 'Convert'

Get-ChildItem .\Archive | ForEach-Object { Push-AppveyorArtifact $_.FullName -FileName $_.Name }

"Working on GIT branch: $($env:APPVEYOR_REPO_BRANCH)"
if ($env:APPVEYOR_REPO_BRANCH -eq 'master')
{
    $ErrorActionPreference = 'SilentlyContinue'
    
    'Setting git credentials'
    git config --global credential.helper store
    Add-Content "$HOME\.git-credentials" "https://$($env:GitHubKey):x-oauth-basic@github.com`n"
    git config --global user.name "AppVeyorCI"
    git config --global user.email "appveyorci-does-not-exist@austoonz.net"

    # Set up a path to the git.exe cmd, import posh-git to give us control over git, and then push changes to GitHub
    # Note that "update version" is included in the appveyor.yml file's "skip a build" regex to avoid a loop
    $env:Path += ";$env:ProgramFiles\Git\cmd"
    Import-Module posh-git -ErrorAction Stop

    'Checking out master'
    git checkout master

    'Adding new Module Manifest'
    $manifestSource = ".\Artifact\$moduleName.psd1"
    $manifestTarget = ".\$moduleName\$moduleName.psd1"
    Copy-Item -Path $manifestSource -Destination $manifestTarget
    
    git add $manifestTarget
    git status

    # Retrieve the new Module Version
    $manifestVersion = (Test-ModuleManifest -Path $manifestTarget).Version.ToString()
    git commit -s -m "Module Version bumped to $manifestVersion [skip ci]"

    'Adding generated docs'
    Copy-Item -Path '.\CHANGELOG.md' -Destination '.\docs\CHANGELOG.md' -Force
    Copy-Item -Path '.\RELEASE.md' -Destination '.\docs\RELEASE.md' -Force
    git add .\docs
    git commit -s -m "Added newly generated docs [skip ci]"

    git push origin master
}