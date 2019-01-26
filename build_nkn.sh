#!/bin/bash

sudo chown -R nkn:nkn /home/nkn || exit $?
sudo -u nkn mkdir -p /home/nkn/supervisor_log || exit $?
sudo -u nkn mkdir -p /home/nkn/go/src/github.com/nknorg/ || exit $?

cd /home/nkn/go/src/github.com/nknorg/ || exit $?
sudo -u nkn git clone https://github.com/nknorg/nkn.git || exit $?

cd nkn || exit $?
sudo -u nkn git fetch || exit $?
LATEST_TAG=$(git tag --sort=-creatordate | head -1) || exit $?
sudo -u nkn git checkout ${LATEST_TAG} || exit $?
sudo -u nkn bash -c "source /home/nkn/.bash_profile && make" || exit $?
sudo -u nkn bash -c "cp config.testnet.json config.json" || exit $?

RANDOM_PASSWD=$(head -c 1024 /dev/urandom | shasum -a 512 -b | xxd -r -p | base64 | head -c 32) || exit $?
sudo -u nkn bash -c "./nknc wallet -c" <<EOF
${RANDOM_PASSWD}
${RANDOM_PASSWD}
EOF
[ $? -eq 0 ] || exit $?

sudo -u nkn bash -c "echo ${RANDOM_PASSWD} > wallet.pswd" || exit $?
sudo -u nkn bash -c "chmod 0400 wallet.pswd" || exit $?
