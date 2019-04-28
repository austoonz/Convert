$moduleName = 'Convert'

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}

Describe -Name 'Module Manifest' -Fixture {
    $sut = Get-Item -Path $pathToManifest

    It -Name 'Has a valid base version' -Test {

        $version = (Test-ModuleManifest -Path $sut.FullName).Version
        $version.ToString().Split('.') | Should -HaveCount 3
    }
}