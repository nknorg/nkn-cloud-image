#!/bin/bash

sudo chown -R miner:miner /home/miner || exit $?
sudo -u miner mkdir -p /home/miner/supervisor_log || exit $?
sudo -u miner mkdir -p /home/miner/go/src/github.com/nknorg/ || exit $?
cd /home/miner/go/src/github.com/nknorg/ || exit $?
sudo -u miner git clone https://github.com/nknorg/nkn.git || exit $?

#. /etc/profile.d/golang_env.sh
cd /home/miner/go/src/github.com/nknorg/nkn || exit $?

LATEST_TAG=$(git tag --sort=-creatordate | head -1)
sudo -u miner git checkout ${LATEST_TAG} || exit $?
sudo -u miner bash -c "source /home/miner/.bash_profile &&  make" || exit $?
sudo -u miner bash -c "cd /home/miner/go/src/github.com/nknorg/nkn && ./test/create_testbed.sh 1 ./testbed " || exit $?
