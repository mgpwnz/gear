#!/bin/bash
# Default variables
function="install"
# Options
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
        case "$1" in
        -in|--install)
            function="install"
            shift
            ;;
        *|--)
    break
	;;
	esac
done
install() {
echo 1
read -p "Enter node Name: " NODENAME_GEAR

echo 'Your node Name: ' $NODENAME_GEAR
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
sleep 1

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
	--rpc-port 9953 \
	--ws-port 9954 \
	--no-private-ipv4 \
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

sleep 2
echo adv    
systemctl restart subspace-node.service &>/dev/null
systemctl restart subspace-farmer.service &>/dev/null
#pulsar

systemctl restart subspace  &>/dev/null
echo docker 
if [-f $HOME/subspace/docker-compose.yml ]; then
docker compose -f $HOME/subspace/docker-compose.yml restart
fi
}
# Actions
sudo apt install wget -y &>/dev/null
cd
$function