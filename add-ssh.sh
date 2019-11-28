#!/usr/bin/env bash

PATH=$PATH:.

if ! command -v jq >/dev/null 2>/dev/null
then
  read -p "jq not installed, do you want me to download it? (type 'y'): " download
  if [ "$download" == "y" ]
  then
    wget "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O jq
    chmod +x jq
  else
    exit 1
  fi
fi

if [ $# -eq 0 ]
then
  echo "add-ssh.sh"
  echo "adds your 1password ssh keys (documents) to a running ssh agent"
  echo
  echo "no arguments!"
  echo
  echo "usage: add-ssh <subdomain> [<tag>] [<vault>]"
  echo "\tsubdomain: your accounts subdomain (required), mose likely also your username. this_part.1password.com"
  echo "\ttag: add all ssh keys with the specified tag ('ssh' if unspecified)"
  echo "\tvault: only add keys from this vault. If omitted all vaults are used"
  echo
  echo "example1: add all documents with tag 'ssh' in account with signin address 'yourname.1password.com':"
  echo "\t./Add-Ssh yourname"
  echo "example2: add all documents with tag 'xyz' and signin address 'yourname.1password.com':"
  echo "\t./Add-Ssh yourname xyz"
  echo
  echo "full description:"
  echo ""
  echo "Uses the one password cli tool (https://1password.com/downloads/command-line/)"
  echo "and ssh-add to add your ssh keys stored in your 1password vault as documents to a running ssh agent."
  echo "You need to manually sign in once so the cli client is allowed to log into your account."
  echo "Manually signing in works like this: https://support.1password.com/command-line/."
  echo "ssh-add and op need to either be in your path or the current working directory."
  echo "ssh-add also needs to be alive and running. For windows10 i recommend just enabling OpenSSH."
  echo "By default all documents with tag 'ssh' wil be added, this can be changed with the tag param."
  echo "the downloaded ssh keys will be deleted after adding them to the ssh agent"
  exit 1
fi

echo "[+] signing into account"
if ! sess=$(op signin $1)
then
  echo "invalid password"
  exit 1
fi

eval $sess

if [ -z "$3" ]
then
  echo "[+] getting documents from all vaults"
  cmd="op list documents"
else
  echo "[+] getting documents from vault $3"
  cmd="op list documents --vault=$3"
fi

if [ -z "$2" ]
then
  tag="ssh"
else
  tag=$2
fi

if ! keys=$($cmd)
then 
  exit 1
fi

for objb64 in $(echo "$keys" | jq -cr '.[] | @base64')
do
  obj=$(echo "$objb64" | base64 -d)
  value() {
    echo "$obj" | jq -cr "$@"
  }
  title=$(value '.overview.title')
  uuid=$(value '.uuid')
  has_tag=$(value ".overview.tags | index(\"$tag\")")
  if [ $has_tag != "null" ]
  then
    echo "[+] adding key $title"
    touch $uuid
    chmod 600 $uuid
    op get document $uuid > $uuid
    ssh-add $uuid
    rm $uuid
  else
    echo "[-] $title doesnt have $tag tag"
  fi
done

#echo $keys
#op list documents
op signout
