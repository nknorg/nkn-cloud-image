#! /bin/bash

ulimit -n 4096
ulimit -c unlimited

source $HOME/.bash_profile
export GOTRACEBACK=crash

function start () {
    WALLET_PASSWD=$(cat ./wallet.pswd)
    ./nknd --no-nat <<EOF
${WALLET_PASSWD}
${WALLET_PASSWD}
EOF
}

git fetch
LATEST_TAG=$(git tag --sort=-creatordate | head -1)
git checkout ${LATEST_TAG}
make

mkdir -p ./Log
start 1>./Log/nohup.out.$(date +%F_%T) 2>&1
