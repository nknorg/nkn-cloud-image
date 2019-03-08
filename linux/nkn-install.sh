#!/bin/bash

getBeneficiaryAddr() {
    BENEFICIARY_ADDR=$1

    if [ "N" != "${BENEFICIARY_ADDR:0:1}" ]
    then
        echo "Usage: ./nkn-install.sh YOUR_CORRECT_NKN_ADDRESS [1]"
        echo "       [1] means download the latest nkn chain data"
        exit 0
    fi
    if [ ${#BENEFICIARY_ADDR} -ne 34 ]
    then
        echo "Usage: ./nkn-install.sh YOUR_CORRECT_NKN_ADDRESS [1]"
        echo "       [1] means download the latest nkn chain data"
        exit 0
    fi
}

initSomething() {
    CURRENT_DIR=$(pwd)
    NKN_MINE_USER_NAME="nkn-mine"
    GO_VERSION="go1.11"
    GLIDE_VERSION="v0.13.2"

    CHAIN_DATA_DIST_NAME=Chain_634205
}

delNKNMineUser() {
    userdel $NKN_MINE_USER_NAME
    rm -rf /home/$NKN_MINE_USER_NAME
}

initArch() {
    ARCH=$(uname -m)
    case $ARCH in
        armv5*) ARCH="armv5";;
        armv6*) ARCH="armv6";;
        armv7*) ARCH="armv7";;
        aarch64) ARCH="arm64";;
        x86) ARCH="386";;
        x86_64) ARCH="amd64";;
        i686) ARCH="386";;
        i386) ARCH="386";;
    esac
    echo "ARCH=$ARCH"
}

initOS() {
    OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')
    case "$OS" in
        # Minimalist GNU for Windows
        mingw*) OS='windows';;
        msys*) OS='windows';;
    esac
    echo "OS=$OS"
    if [ "linux" != "$OS" ]
    then
        echo "this script just support for linux"
        exit 0
    fi
}

initTools() {
    if [[ ! -f /etc/redhat-release ]]
    then
        sudo apt-get update
        sudo apt-get install -y jq make unzip psmisc git curl wget
    else
        sudo yum install -y jq make unzip psmisc git curl wget
    fi
}

createNKNMineUser() {
    NKN_MINE_USER_SEARCH=`cat /etc/passwd | grep $NKN_MINE_USER_NAME`
    if [ -z "$NKN_MINE_USER_SEARCH" ]
    then
        rm -rf /home/$NKN_MINE_USER_NAME
        sudo useradd $NKN_MINE_USER_NAME -m
    fi
}

downloadGO() {
    GO_DIST="$GO_VERSION.$OS-$ARCH.tar.gz"

    GO_DOWNLOAD_URL=https://dl.google.com/go/$GO_DIST

    sudo -u $NKN_MINE_USER_NAME wget $GO_DOWNLOAD_URL -O /home/$NKN_MINE_USER_NAME/$GO_DIST
    sudo -u $NKN_MINE_USER_NAME tar zxf /home/$NKN_MINE_USER_NAME/$GO_DIST -C /home/$NKN_MINE_USER_NAME

    sudo cat <<EOF > /home/$NKN_MINE_USER_NAME/.bash_profile
export HOME=/home/$NKN_MINE_USER_NAME
export GOROOT=\$HOME/go
export GOPATH=\$HOME/go
export PATH=\$GOROOT/bin:\$PATH
export PATH=\$HOME/glide:\$PATH
export NKN_HOME=\$HOME/go/src/github.com/nknorg/nkn
EOF
    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME /home/$NKN_MINE_USER_NAME/.bash_profile
}

downloadGlide() {
    GLIDE_DIST="glide-$GLIDE_VERSION-$OS-$ARCH.tar.gz"
    GLIDE_DOWNLOAD_URL="https://github.com/Masterminds/glide/releases/download/$GLIDE_VERSION/$GLIDE_DIST"

    sudo -u $NKN_MINE_USER_NAME wget $GLIDE_DOWNLOAD_URL -O /home/$NKN_MINE_USER_NAME/$GLIDE_DIST
    sudo -u $NKN_MINE_USER_NAME tar zxf /home/$NKN_MINE_USER_NAME/$GLIDE_DIST -C /home/$NKN_MINE_USER_NAME

    sudo -u $NKN_MINE_USER_NAME mv /home/$NKN_MINE_USER_NAME/$OS-$ARCH /home/$NKN_MINE_USER_NAME/glide

}

downloadNKNSource() {
    sudo -u $NKN_MINE_USER_NAME mkdir -p /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/
    cd /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/
    sleep 1
    sudo -u $NKN_MINE_USER_NAME git clone https://github.com/nknorg/nkn.git
    sleep 1
}

buildNKN() {

    cd /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn
    
    sudo -u $NKN_MINE_USER_NAME git fetch
    
    LATEST_TAG=$(git tag | tail -1)

    sudo -u $NKN_MINE_USER_NAME git checkout ${LATEST_TAG}

    sudo -u $NKN_MINE_USER_NAME bash -c "source /home/$NKN_MINE_USER_NAME/.bash_profile && make"

}

initNKNConf() {

    sudo cat <<EOF > /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.user.json
{
  "BeneficiaryAddr": "$BENEFICIARY_ADDR",
  "SyncBatchWindowSize": 128,
  "LogLevel": 2
}
EOF

    sudo jq -n \
            --argfile c1 /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.testnet.json \
            --argfile c2 /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.user.json '$c1 + $c2' > /tmp/config.json.merged

    sudo mv /tmp/config.json.merged /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.json

    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.user.json
    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/config.json

}

initNKNWallet() {
    cd /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/

    RANDOM_PASSWD=$(head -c 1024 /dev/urandom | shasum -a 512 -b | xxd -r -p | base64 | head -c 32)
    sudo ./nknc wallet -c <<EOF
${RANDOM_PASSWD}
${RANDOM_PASSWD}
EOF
    sudo echo ${RANDOM_PASSWD} > ./wallet.pswd
    sudo chmod 0400 wallet.dat wallet.pswd
    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME wallet.dat
    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME wallet.pswd

    cd $CURRENT_DIR
}

downNKNChainData() {
    cd /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/
    sudo -u $NKN_MINE_USER_NAME wget -N https://storage.googleapis.com/nkn-testnet-snapshot/$CHAIN_DATA_DIST_NAME.zip
    sleep 1
    sudo -u $NKN_MINE_USER_NAME unzip $CHAIN_DATA_DIST_NAME.zip 
    sleep 1
    sudo rm $CHAIN_DATA_DIST_NAME.zip
    cd $CURRENT_DIR
}

addNKNCrontab() {
    cd /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/
    sudo wget -N https://raw.githubusercontent.com/nkn-dev/nkn-cloud-image/master/linux/nkn-monitor.sh
    sudo chmod +x nkn-monitor.sh
    sudo chown $NKN_MINE_USER_NAME:$NKN_MINE_USER_NAME nkn-monitor.sh
    sudo -u $NKN_MINE_USER_NAME echo "# nkn mine crontab" > conf
    sudo -u $NKN_MINE_USER_NAME echo "* * * * * /home/$NKN_MINE_USER_NAME/go/src/github.com/nknorg/nkn/nkn-monitor.sh &" >> conf
    sudo -u $NKN_MINE_USER_NAME crontab conf
    sudo rm -f conf
    cd $CURRENT_DIR
}

getBeneficiaryAddr $1

initSomething

delNKNMineUser

initArch
initOS
initTools
createNKNMineUser
downloadGO
downloadGlide

downloadNKNSource
buildNKN

initNKNConf

initNKNWallet

if [ "$2" == "1" ]
then
    downNKNChainData
fi

addNKNCrontab
