$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $Expected = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $Expected
    }

    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding = 'ASCII'
            Base64   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'BigEndianUnicode'
            Base64   = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            Encoding = 'Default'
            Base64   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'Unicode'
            Base64   = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            Encoding = 'UTF32'
            Base64   = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            Encoding = 'UTF7'
            Base64   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            Encoding = 'UTF8'
            Base64   = 'VGhpc0lzTXlTdHJpbmc='
        }
    ) -Fixture {
        It -Name "Converts a <Encoding> Encoded string to a string" -Test {
            $splat = @{
                String   = $Base64
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-Base64ToString @splat
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = $Base64 | ConvertFrom-Base64ToString -Encoding $Encoding
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports EAP SilentlyContinue' -Test {
            $splat = @{
                String   = 'a'
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-Base64ToString @splat -ErrorAction SilentlyContinue
            $assertion | Should -BeNullOrEmpty
        }

        It -Name 'Supports EAP Stop' -Test {
            $splat = @{
                String   = 'a'
                Encoding = $Encoding
            }
            { ConvertFrom-Base64ToString @splat -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Supports EAP Continue' -Test {
            $splat = @{
                String   = 'a'
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-Base64ToString @splat -ErrorAction Continue 2>&1

            $exception = @(
                'Invalid length for a Base-64 char array or string.',
                'The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.'
            )
            $assertion.Exception.InnerException.Message | Should -BeIn $exception
        }
    }
}


