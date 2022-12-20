#!/bin/bash

sleep 1 && curl -s https://raw.githubusercontent.com/cryptology-nodes/main/main/logo.sh |  bash && sleep 2

wget https://get.gear.rs/gear-nightly-linux-x86_64.tar.xz &>/dev/null
tar xvf gear-nightly-linux-x86_64.tar.xz &>/dev/null
rm gear-nightly-linux-x86_64.tar.xz
chmod +x $HOME/gear &>/dev/null

sudo systemctl restart gear &>/dev/null

echo -e '\n\e[42mUpgrade completed\e[0m\n' && sleep 1
