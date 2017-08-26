#!/bin/bash

# Install required dependencies
sudo apt-get install libboost-all-dev libpython2.7 openjdk-8-jdk lua5.1 libxerces-c3.1 liblua5.1-0-dev ffmpeg python-tk python-imaging-tk
sudo update-ca-certificates -f

# Install torch
git clone https://github.com/torch/distro.git ~/torch --recursive
cd ~/torch; bash install-deps;
TORCH_LUA_VERSION=LUA51 ./install.sh
source ~/.bashrc


# Install all required lua rocks
rocks=(luasocket logroll moses classic cwrap paths nn cutorch cunn luafilesystem penlight sys xlua image env qtlua qttorch nngraph luaposix nninit rnn tds socket.core underscore)

for rock in ${rocks[*]}; do
	echo "===== Installing rock ${rock} ====="
	luarocks install "$rock"
done
