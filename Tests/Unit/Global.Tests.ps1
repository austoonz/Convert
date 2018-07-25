Describe -Name 'Module Manifest' -Fixture {
    $sut = Get-Item -Path "$PSScriptRoot\..\..\Convert\Convert.psd1"
    It -Name 'Has a valid base version' -Test {

        $version = (Test-ModuleManifest -Path $sut.FullName).Version
        $version.ToString().Split('.') | Should -HaveCount 4
    }
}