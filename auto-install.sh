#/bin/bash
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BOLD='\033[1m'
STEPS=10

COINDOWNLOADLINK1=https://github.com/FilokOfficial/filok/releases/download/v1.0/filokd
COINDOWNLOADLINK2=https://github.com/FilokOfficial/filok/releases/download/v1.0/filok-cli
COINDOWNLOADLINK3=https://github.com/FilokOfficial/filok/releases/download/v1.0/filok-tx
COINPORT=11721
COINRPCPORT=18291
COINDAEMON=filokd
COINDAEMONCLI=filok-cli
COINDAEMONTX=filok-tx
COINCORE=.filok
COINCONFIG=filok.conf

checkForUbuntuVersion() {
   echo
   echo "[1/${STEPS}] Checking Ubuntu version..."
    if [[ `cat /etc/issue.net`  == *16.04* ]]; then
        echo -e "${GREEN}* You are running `cat /etc/issue.net` . Setup will continue.${NONE}";
    else
        echo -e "${RED}* You are not running Ubuntu 16.04.X. You are running `cat /etc/issue.net` ${NONE}";
        echo && echo "Installation cancelled" && echo;
        exit;
    fi
}

updateAndUpgrade() {
    echo
    echo "[2/${STEPS}] Running update and upgrade. This may take a minute..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}";
}

installDependencies() {
    echo
    echo -e "[3/${STEPS}] Installing dependecies. This will take a few minutes..."
    sudo apt-get install bc git nano rpl wget python-virtualenv -qq -y > /dev/null 2>&1
    sudo apt-get install build-essential libtool automake autoconf -qq -y > /dev/null 2>&1
    sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -qq -y > /dev/null 2>&1
    sudo apt-get install software-properties-common python-software-properties -qq -y > /dev/null 2>&1
    sudo add-apt-repository ppa:bitcoin/bitcoin -y > /dev/null 2>&1
    sudo apt-get update -qq -y > /dev/null 2>&1
    sudo apt-get upgrade -qq -y > /dev/null 2>&1
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libminiupnpc-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libzmq5 -qq -y > /dev/null 2>&1
    sudo apt-get install virtualenv -qq -y > /dev/null 2>&1
    sudo apt-get update -qq -y > /dev/null 2>&1
    sudo apt-get upgrade -qq -y > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

setupSwap() {
    swapspace=$(free -h | grep Swap | cut -c 16-18);
    if [ $(echo "$swapspace < 1.0" | bc) -ne 0 ]; then

    echo a; else echo b; fi

    echo -e "${BOLD}"
    read -e -p "Add swap space? (Recommended for VPS that have 1GB of RAM) [Y/n] :" add_swap
    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        swap_size="4G"
    else
        echo -e "${NONE}[4/${STEPS}] Swap space not created."
    fi

    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        echo && echo -e "${NONE}[4/${STEPS}] Adding swap space...${YELLOW}"
        sudo fallocate -l $swap_size /swapfile
        sleep 2
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo -e "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Done${NONE}";
    fi
}

installFail2Ban() {
    echo
    echo -e "[5/${STEPS}] Installing fail2ban..."
    sudo apt-get -y install fail2ban > /dev/null 2>&1
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installFirewall() {
    echo
    echo -e "[6/${STEPS}] Installing firewall..."
    sudo apt-get -y install ufw > /dev/null 2>&1
    sudo ufw allow OpenSSH > /dev/null 2>&1
    sudo ufw allow $COINPORT > /dev/null 2>&1
    sudo ufw allow $COINRPCPORT > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

downloadWallet() {
    echo
    echo -e "[7/${STEPS}] Downloading wallet..."

    wget $COINDOWNLOADLINK1 $COINDOWNLOADLINK2 $COINDOWNLOADLINK3 > /dev/null 2>&1
    chmod 755 $COINDAEMON $COINDAEMONCLI $COINDAEMONTX > /dev/null 2>&1

    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installWallet() {
    echo
    echo -e "[8/${STEPS}] Installing wallet..."
    strip $COINDAEMON $COINDAEMONCLI $COINDAEMONTX > /dev/null 2>&1
    sudo mv -t /usr/bin $COINDAEMON $COINDAEMONCLI $COINDAEMONTX > /dev/null 2>&1
    cd
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

configureWallet() {
    echo
    echo -e "[9/${STEPS}] Configuring wallet..."
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 10
    $COINDAEMONCLI stop > /dev/null 2>&1
    sleep 5

    mnip=$(curl --silent ipinfo.io/ip)
    rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1" > ~/$COINCORE/$COINCONFIG

    $COINDAEMON > /dev/null 2>&1
    sleep 10

    read -e -p "Enter your Masternode Private Key: " mnkey
    port=$(echo "$COINPORT")
    rpcport=$(echo "$COINRPCPORT")

    $COINDAEMONCLI stop > /dev/null 2>&1
    sleep 5

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowip=127.0.0.1\nport=${port}\nrpcport=${rpcport}\ndaemon=1\nserver=1\nlisten=1\nlogtimestamps=1\nmaxconnections=256\nmasternode=1\nexternalip=${mnip}\nmasternodeprivkey=${mnkey}" > ~/$COINCORE/$COINCONFIG

    echo -e "${NONE}${GREEN}* Done${NONE}";
}

startWallet() {
    echo
    echo -e "[10/${STEPS}] Starting wallet daemon..."
    $COINDAEMON > /dev/null 2>&1
    sleep 5
    echo -e "${GREEN}* Done${NONE}";
}

clear
cd

echo
echo -e "------------------------------------------------------------"
echo -e "|                                                          |"
echo -e "|        ${BOLD}---- Filok masternode installer ----${NONE}        |"
echo -e "|                                                          |"
echo -e "------------------------------------------------------------"

echo -e "${BOLD}"
read -p "This script will install a Filok masternode wallet on your VPS. Do you wish to continue? (y/n)?" response
echo -e "${NONE}"

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    checkForUbuntuVersion
    updateAndUpgrade
    installDependencies
    setupSwap
    downloadWallet
    installWallet
    configureWallet
    startWallet

    echo && echo -e "${BOLD}The VPS wallet for your masternode has been successfully created. The following data needs to be recorded in your local masternode configuration file:${NONE}"
    echo && echo -e "${BOLD}${YELLOW} 1) Masternode_IP: ${mnip}:${COINPORT}${NONE}"
    echo && echo -e "${BOLD}${YELLOW} 2) Masternode_Private_Key: ${mnkey}${NONE}"
    echo && echo -e "${BOLD}${GREEN}Copy the above two yellow outputs into the text document you created earlier. Then logout and close this terminal console and continue with the rest of the masternode setup guide${NONE}" && echo
else
    echo && echo "Installation aborted" && echo
fi
