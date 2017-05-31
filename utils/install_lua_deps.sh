#!/bin/bash
rocks=(luasocket logroll moses classic cwrap paths nn cutorch cunn luafilesystem penlight sys xlua image env qtlua qttorch nngraph luaposix nninit rnn tds socket.core underscore)

for rock in ${rocks[*]}; do
	echo "===== Installing rock ${rock} ====="
	luarocks install "$rock"
done
