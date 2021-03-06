$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {

    $expected = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding' = 'ASCII'
            'Base64'   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'BigEndianUnicode'
            'Base64'   = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            'Encoding' = 'Default'
            'Base64'   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'Unicode'
            'Base64'   = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            'Encoding' = 'UTF32'
            'Base64'   = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            'Encoding' = 'UTF7'
            'Base64'   = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'UTF8'
            'Base64'   = 'VGhpc0lzTXlTdHJpbmc='
        }
    )

    foreach ($encoding in $encodings)
    {
        Context -Name $encoding.Encoding -Fixture {
            It -Name "Converts a $($encoding.Encoding) Encoded string to a string" -Test {
                $splat = @{
                    String   = $encoding.Base64
                    Encoding = $encoding.Encoding
                }
                $assertion = ConvertFrom-Base64ToString @splat
                $assertion | Should -BeExactly $expected
            }

            It -Name 'Supports the Pipeline' -Test {
                $assertion = $encoding.Base64 | ConvertFrom-Base64ToString -Encoding $encoding.Encoding
                $assertion | Should -BeExactly $expected
            }

            It -Name 'Supports EAP SilentlyContinue' -Test {
                $splat = @{
                    String   = 'a'
                    Encoding = $encoding.Encoding
                }
                $assertion = ConvertFrom-Base64ToString @splat -ErrorAction SilentlyContinue
                $assertion | Should -BeNullOrEmpty
            }

            It -Name 'Supports EAP Stop' -Test {
                $splat = @{
                    String   = 'a'
                    Encoding = $encoding.Encoding
                }
                { ConvertFrom-Base64ToString @splat -ErrorAction Stop } | Should -Throw
            }

            It -Name 'Supports EAP Continue' -Test {
                $splat = @{
                    String   = 'a'
                    Encoding = $encoding.Encoding
                }
                $assertion = ConvertFrom-Base64ToString @splat -ErrorAction Continue 2>&1

                $expected = @(
                    'Invalid length for a Base-64 char array or string.',
                    'The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters.'
                )

                $assertion.Exception.InnerException.Message | Should -BeIn $expected
            }
        }
    }
}


