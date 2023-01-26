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
	if [ ! f &HOME/gear ]; then
	return 1 2>/dev/null; exit 1
	fi
}
function firewall {
sudo ufw allow 22:65535/tcp
sudo ufw allow 22:65535/udp
sudo ufw deny out from any to 10.0.0.0/8
sudo ufw deny out from any to 192.168.0.0/16
sudo ufw deny out from any to 100.64.0.0/10
sudo ufw deny out from any to 198.18.0.0/15
sudo ufw deny out from any to 169.254.0.0/16
sudo ufw --force enable
}
function backup {
	if [ ! -d $HOME/gearbackup/ ]; then
  		mkdir $HOME/gearbackup
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v5/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V5 
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v4/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V4
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v3/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V3 
	 fi
	 if [  -d $HOME/.local/share/gear/chains/gear_staging_testnet_v5/ ]; then
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v5/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V5  
	 fi
	 if [  -d $HOME/.local/share/gear/chains/gear_staging_testnet_v4/ ]; then
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v4/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V4  
	 fi
	 if [  -d $HOME/.local/share/gear/chains/gear_staging_testnet_v3/ ]; then
		cp $HOME/.local/share/gear/chains/gear_staging_testnet_v3/network/secret_ed25519 $HOME/gearbackup/secret_ed25519_V3  
	 fi
	 echo -e "BackUp ready \e[39m!"
	}
function restore {
	if [ -d $HOME/.local/share/gear/chains/gear_staging_testnet_v6 ]; then
	cp $HOME/gearbackup/secret_ed25519_V5 $HOME/.local/share/gear/chains/gear_staging_testnet_v6/network/secret_ed25519 
	fi
	sudo systemctl restart gear
	
  }

function updateSoftware {
	sudo systemctl stop gear
	/root/gear purge-chain -y
	sudo systemctl start gear
	sleep 2
	if [[ `service gear status | grep active` =~ "running" ]]; then
          echo -e "Your gear node \e[32mupgraded and works\e[39m!"
          echo -e "You can check node status by the command \e[7mservice gear status\e[0m"
        else
          echo -e "Your gear node \e[31mwas not upgraded correctly\e[39m, please reinstall."
        fi
	 . $HOME/.bash_profile
}

function installService {
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald

sudo tee <<EOF >/dev/null /etc/systemd/system/gear.service
[Unit]
Description=Gear Node
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/gear \
        --name $NODENAME_GEAR \
        --execution wasm \
	--port 31333 \
        --telemetry-url 'ws://telemetry-backend-shard.gear-tech.io:32001/submit 0' \
	--telemetry-url 'wss://telemetry.postcapitalist.io/submit 0'
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl restart systemd-journald &>/dev/null
sudo systemctl daemon-reload &>/dev/null
sudo systemctl enable gear &>/dev/null
sudo systemctl restart gear &>/dev/null

}

function deletegear {
		systemctl stop gear
		systemctl disable gear
		rm -rf $HOME/.local/share/gear/chains/staging_testnet/db
}


PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Upgrade" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
 		echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			installDeps
			firewall
			installSoftware
			installService 
			echo -e '\n\e[33mNode install!\e[0m\n' && sleep 1
			break
            ;;
	    "Upgrade")
            echo -e '\n\e[33mYou choose upgrade...\e[0m\n' && sleep 1
			backup
			updateSoftware
			restore
			echo -e '\n\e[33mYour node was upgraded!\e[0m\n' && sleep 1
			break
            ;;
	    "Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deletegear
			echo -e '\n\e[42mGear was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
