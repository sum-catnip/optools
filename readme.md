# OP Tools
## sum nice command line tools for 1password

currently includes:

# Add-Ssh.ps1
# add-ssh.sh

Powershell and bash script to add your ssh keys stored as documents (in 1password) to your running ssh agent.
```
Uses the one password cli tool (https://1password.com/downloads/command-line/)
and ssh-add to add your ssh keys stored in your 1password vault as documents to a running ssh agent.
You need to manually sign in once so the cli client is allowed to log into your account.
Manually signing in works like this: https://support.1password.com/command-line/.
ssh-add and op need to either be in your path or the current working directory.
ssh-add also needs to be alive and running. For windows10 i recommend just enabling OpenSSH.
By default all documents with tag "ssh" wil be added, this can be changed with the tag param.
the downloaded ssh keys will be deleted after adding them to the ssh agent
```
examples:
```
Add all documents with tag 'xyz' and signin address 'yourname.1password.com':
./Add-Ssh yourname xyz

Add all documents with tag 'ssh' in account with signin address 'yourname.1password.com':
./Add-Ssh yourname
```
