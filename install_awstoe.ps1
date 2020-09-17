$region = 'us-west-2'
$destination = [System.IO.Path]::Combine($env:SystemRoot, 'System32', 'awstoe.exe')
$source = "https://awstoe-$region.s3.$region.amazonaws.com/latest/windows/amd64/awstoe.exe"
(New-Object -TypeName 'System.Net.WebClient').DownloadFile($source, $destination)
