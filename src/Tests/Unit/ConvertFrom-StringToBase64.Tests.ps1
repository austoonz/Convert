$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context -Name 'Input/Output' -ForEach @(
        @{
            Encoding = 'ASCII'
            Expected = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'BigEndianUnicode'
            Expected = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            Encoding = 'Default'
            Expected = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'Unicode'
            Expected = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            Encoding = 'UTF32'
            Expected = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            Encoding = 'UTF7'
            Expected = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'UTF8'
            Expected = 'VGhpc0lzTXlTdHJpbmc='
        }
    ) -Fixture {
        Context -Name '<Encoding>' -Fixture {
            It -Name 'Converts a string to a <Encoding> Encoded string' -Test {
                $splat = @{
                    String   = $String
                    Encoding = $Encoding
                }
                $assertion = ConvertFrom-StringToBase64 @splat
                $assertion | Should -BeExactly $Expected
            }
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -BeExactly 'VGhpc0lzTXlTdHJpbmc='
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = @($String, $String) | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -HaveCount 2
        }
    }
}
