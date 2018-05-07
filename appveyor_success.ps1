Get-ChildItem .\Archive | ForEach-Object { Push-AppveyorArtifact $_.FullName -FileName $_.Name }

"Working on GIT branch: $($env:APPVEYOR_REPO_BRANCH)"
if ($env:APPVEYOR_REPO_BRANCH -eq 'master')
{
    $ErrorActionPreference = 'Continue'
    
    'Setting git credentials'
    git config --global credential.helper store
    Add-Content "$HOME\.git-credentials" "https://$($env:GitHubKey):x-oauth-basic@github.com`n"
    git config --global user.name "Andrew Pearce"
    git config --global user.email "andrew@austoonz.net"

    # Set up a path to the git.exe cmd, import posh-git to give us control over git, and then push changes to GitHub
    # Note that "update version" is included in the appveyor.yml file's "skip a build" regex to avoid a loop
    $env:Path += ";$env:ProgramFiles\Git\cmd"
    Import-Module posh-git -ErrorAction Stop

    'Checking out master'
    git checkout master

    'Adding new Module Manifest'
    Copy-Item -Path .\Artifact\Convert.psd1 -Destination .\Convert\Convert.psd1
    git add .\Convert\Convert.psd1

    git status
    git commit -s -m "Module Manifest updated (skip ci)"
    git push origin master
}