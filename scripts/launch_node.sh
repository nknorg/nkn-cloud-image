#! /bin/bash

ulimit -n 4096
ulimit -c unlimited

source $HOME/.bash_profile
export GOTRACEBACK=crash

function initWallet () {
  head -c 1024 /dev/urandom | shasum -a 512 -b | xxd -r -p | base64 | head -c 32 > wallet.pswd && echo >> wallet.pswd
  cat wallet.pswd wallet.pswd | ./nknc wallet -c
  chmod 0400 wallet.json wallet.pswd
  return $?
}

function mergeConfig() {
  jq -n --argfile c1 config.json --argfile c2 config.user.json '$c1 + $c2' > /tmp/config.json.merged && mv /tmp/config.json.merged config.json
}

function start () {
  cat wallet.pswd | ./nknd --no-nat
}

git fetch
LATEST_TAG=$(git tag --sort=-creatordate | head -1)
git checkout ${LATEST_TAG}
make

mkdir -p ./Log
[ -s "wallet.json" ] || initWallet || ! echo "Init wallet fails" || exit 1
! [ -s "config.user.json" ] || mergeConfig || ! echo "Merge config fail" || exit 1
start 1>./Log/nohup.out.$(date +%F_%T) 2>&1
