#!/usr/bin/env python3

from sys import argv


ofs = int(argv[2].split(".")[-3], 16)

with open(argv[1], "rb") as input:
    with open(argv[2], "wb") as output:
        output.write(bytes(((byte + ofs) % 256  for byte in input.read())))
