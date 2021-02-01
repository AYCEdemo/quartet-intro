#!/bin/bash

cut -d ';' -f 2- "$1" | while read line; do
	addr=$(cut -d ' ' -f 1 <<<"$line")
	name=$(cut -d ' ' -f 2 <<<"$line")
	if [[ -n "$name" ]]; then
		bank=",BANK[$((0x$(cut -d ':' -f 1 <<<"$addr")))]"
		addr=$((0x$(cut -d ':' -f 2 <<<"$addr")))
		if [[ $addr -lt 0x8000 ]]; then
			bank=
			type=ROM0
		elif [[ $addr -lt 0xa000 ]]; then
			bank=
			type=VRAM
		elif [[ $addr -lt 0xc000 ]]; then
			type=SRAM
		elif [[ $addr -lt 0xe000 ]]; then
			bank=
			type=WRAM0
		else
			bank=
			type=HRAM
		fi
		cat <<EOF
SECTION "$name", $type[$addr]$bank
Q_${name/./_}:
EOF
	fi
done
