Get-ChildItem .\Archive | ForEach-Object { Push-AppveyorArtifact $_.FullName -FileName $_.Name }

"Branch: $($env:APPVEYOR_REPO_BRANCH)"
if ($env:APPVEYOR_REPO_BRANCH -eq 'master') {
    git config --global credential.helper store
    Add-Content "$HOME\.git-credentials" "https://$($env:GitHubKey):x-oauth-basic@github.com`n"
    git config --global user.name "Andrew Pearce"
    git config --global user.email "andrew@austoonz.net"
    git checkout master
    Copy-Item -Path .\Artifact\Convert.psd1 -Destination .\Convert\Convert.psd1
    git add .\Convert\Convert.psd1
    git commit -m "Module Manifest updated (skip ci)"
    git push
}