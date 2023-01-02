Describe -Name 'Module Manifest' -Fixture {
    It -Name 'Has a valid base version' -Test {
        $moduleName = 'Convert'
        $pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")

        $sut = Get-Item -Path $pathToManifest

        $version = (Test-ModuleManifest -Path $sut.FullName).Version
        $version.ToString().Split('.') | Should -HaveCount 3
    }
}
