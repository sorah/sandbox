#!/bin/bash

echo -n 'name? '
read name
echo -n 'email? '
read email
echo -n 'gpg key name? '
read gpg_key_name

gpg_key_id=$(gpg --list-key $gpg_key_name |grep pub|cut -d'/' -f 2|cut -d' ' -f 1)
echo "-> ${gpg_key_id}"

gpg --armor --export-secret-keys "${gpg_key_id}"| vagrant ssh -c 'gpg --import'

vagrant ssh -c "echo -e \"export DEBSIGN_KEYID=0x${gpg_key_id}\nexport EMAIL='${email}'\nexport DEBFULLNAME='${name}'\" > /home/vagrant/.bashrc.personal"
vagrant ssh -c 'echo -e "DEBSIGN_KEYID=0x${gpg_key_id}"
