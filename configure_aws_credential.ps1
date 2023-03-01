<#
    .SYNOPSIS
    This script is used in AWS CodeBuild to configure the default AWS
    Credentials for use by the AWS CLI and the AWS Powershell module.

    By default, the AWS PowerShell Module does not know about looking up
    an AWS Container's credentials path, so this works around that issue.
#>
'Configuring AWS credentials'

'  - Retrieving temporary credentials from metadata'
$uri = 'http://169.254.170.2{0}' -f $env:AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
$sts = Invoke-RestMethod -UseBasicParsing -Uri $uri

'  - Setting default AWS Credential'
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('[default]')
$null = $sb.AppendLine('aws_access_key_id={0}' -f $sts.AccessKeyId)
$null = $sb.AppendLine('aws_secret_access_key={0}' -f $sts.SecretAccessKey)
$null = $sb.AppendLine('aws_session_token={0}' -f $sts.Token)

'  - Setting default AWS Region'
$null = $sb.AppendLine('region={0}' -f $env:AWS_DEFAULT_REGION)

$credentialsFile = "$env:HOME\.aws\credentials"
$null = New-Item -Path $credentialsFile -Force
$sb.ToString() | Out-File -FilePath $credentialsFile -Append

'  - AWS credentials configured'
