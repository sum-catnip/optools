#requires -version 3

<#
.SYNOPSIS
    Name: Add-Ssh
    adds your 1password ssh keys (documents) to a running ssh agent

.DESCRIPTION
    Uses the one password cli tool (https://1password.com/downloads/command-line/)
    and ssh-add to add your ssh keys stored in your 1password vault as documents to a running ssh agent.
    You need to manually sign in once so the cli client is allowed to log into your account.
    Manually signing in works like this: https://support.1password.com/command-line/.
    ssh-add and op need to either be in your path or the current working directory.
    ssh-add also needs to be alive and running. For windows10 i recommend just enabling OpenSSH.
    By default all documents with tag "ssh" wil be added, this can be changed with the tag param.
    the downloaded ssh keys will be deleted after adding them to the ssh agent

.PARAMETER Subdomain
    Your accounts subdomain (required), mose likely also your username. this_part.1password.com

.PARAMETER Tag
    Add all ssh keys with the specified tag ("ssh" if unspecified)

.PARAMETER Vault
    Only add keys from this vault. If omitted all vaults are used

.EXAMPLE
    Add all documents with tag 'ssh' in account with signin address 'yourname.1password.com':
    ./Add-Ssh yourname

.EXAMPLE
    Add all documents with tag 'xyz' and signin address 'yourname.1password.com':
    ./Add-Ssh yourname xyz
#>

[CmdletBinding()]

PARAM (
    [string]$Subdomain = $(throw "-Subdomain is required."),
    [string]$Tag = 'ssh',
    [string]$Vault = $null
)

function RestrictFilePermissions($file) {
    # calling cmd cuz icacls is big dum in powershell
    # stolen from:
    # https://superuser.com/questions/1296024/windows-ssh-permissions-for-private-key-are-too-open/1329702#1329702
    cmd /c icacls $file /c /t /inheritance:d
    cmd /c icacls $file /c /t /grant %username%:F
    cmd /c icacls $file  /c /t /remove Administrator "Authenticated Users" BUILTIN\Administrators BUILTIN Everyone System Users
}

$env:Path += ";."
Invoke-Expression $(op signin $Subdomain)
if ($null -eq $Vault) { $keys = (op list documents) }
else { $keys = (op list documents --vault=$Vault) }
# $keys = Where-Object -InputObject $keys {$_.overview.tags -contains $Tag}
foreach ($key in (ConvertFrom-Json $keys)) {
    if(-Not $key.overview.tags -contains $Tag) { continue }
    Write-Host "[+] adding key $($key.overview.title)"
    New-Item $key.uuid > $null
    RestrictFilePermissions $key.uuid > $null
    $content = op get document $key.uuid

    # powershell < 6 has no UTF8NoBOM so ima just use ASCII
    Out-File -FilePath $key.uuid -Encoding ASCII -InputObject $content
    ssh-add $key.uuid
    Remove-Item $key.uuid
}
op signout
