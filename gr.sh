#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}

service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
function setupVars {
if [ ! $NODENAME_GEAR ]; then
		read -p "Enter node Name: " NODENAME_GEAR
	fi
echo 'Your node Name: ' $NODENAME_GEAR
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile

	sleep 1
}



function installDeps {
	echo -e '\n\e[42mPreparing to install\e[0m\n' && sleep 1
	cd $HOME
	sudo apt update
  sudo apt install curl make clang pkg-config libssl-dev build-essential git mc jq unzip wget -y < "/dev/null"
	sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
	source $HOME/.cargo/env
  sleep 1
	sudo apt install --fix-broken -y &>/dev/null
  sudo apt install nano mc git mc clang curl jq htop net-tools libssl-dev llvm libudev-dev -y &>/dev/null
  source $HOME/.profile &>/dev/null
  source $HOME/.bashrc &>/dev/null
  source $HOME/.cargo/env &>/dev/null
  sleep 1
}

function installSoftware {
  echo -e '\n\e[42mInstall node\e[0m\n' && sleep 1
	wget https://get.gear.rs/gear-nightly-linux-x86_64.tar.xz &>/dev/null
  tar xvf gear-nightly-linux-x86_64.tar.xz &>/dev/null
  rm gear-nightly-linux-x86_64.tar.xz
  chmod +x $HOME/gear &>/dev/null
	cd $HOME
}
function backup {
	 ironfish testnet
	}
function quest {
	wget -O mbs.sh https://raw.githubusercontent.com/mgpwnz/ironfish/main/mbs.sh && \
	chmod u+x mbs.sh
	printf "SHELL=/bin/bash
	PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
	10 0,4,8,12,16,20 * * * bash /root/mbs.sh "$MAIL" >> /root/mbs.log
	" > /etc/cron.d/mbs
  }

function updateSoftware {
	sudo systemctl stop ironfishd
	cd $HOME
	npm update -g ironfish
	sudo systemctl restart ironfishd
	sleep 2
	if [[ `service ironfishd status | grep active` =~ "running" ]]; then
          echo -e "Your IronFish node \e[32mupgraded and works\e[39m!"
          echo -e "You can check node status by the command \e[7mservice ironfishd status\e[0m"
          echo -e "Press \e[7mQ\e[0m for exit from status menu"
        else
          echo -e "Your IronFish node \e[31mwas not upgraded correctly\e[39m, please reinstall."
        fi
	 . $HOME/.bash_profile
}

function installService {
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1
echo "[Unit]
Description=IronFish Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ironfish) start
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/ironfishd.service
sudo mv $HOME/ironfishd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl enable ironfishd
sudo systemctl restart ironfishd
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service ironfishd status | grep active` =~ "running" ]]; then
  echo -e "Your IronFish node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice ironfishd status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
 echo -e "Your IronFish node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
. $HOME/.bash_profile
}

function deleteIronfish {
	sudo systemctl disable ironfishd
	sudo systemctl stop ironfishd
	sudo rm -rf $HOME/ironfish $HOME/.ironfish $(which ironfish)
}
function deletequest {
	sudo rm $HOME/mbs.sh /etc/cron.d/mbs
	#Old file#
	sudo rm /etc/cron.d/afish $HOME/faucet.sh
}

PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Only_Quest" "Upgrade" "Delete" "Delete_Quest" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
 		echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			installDeps
			installSoftware
			connect
			installService
			quest
			echo -e '\n\e[33mNode with quest install!\e[0m\n' && sleep 1
			break
            ;;
	    "Only_Quest")
            echo -e '\n\e[33mYou choose upgrade...\e[0m\n' && sleep 1
	    		setupVars
			quest
			echo -e '\n\e[33mQuest install!\e[0m\n' && sleep 1
			break
            ;;
	"Upgrade")
            echo -e '\n\e[33mYou choose upgrade...\e[0m\n' && sleep 1
			updateSoftware
			connect
			quest
			echo -e '\n\e[33mYour node was upgraded!\e[0m\n' && sleep 1
			break
            ;;
	    "Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deleteIronfish
			deletequest
			echo -e '\n\e[42mIronfish was deleted!\e[0m\n' && sleep 1
			break
            ;;
		"Delete_Quest")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deletequest
			echo -e '\n\e[42mIronfish was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
