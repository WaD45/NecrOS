#!/bin/sh
echo "[*] Reverse Tools..."
apk add --no-cache gdb strace ltrace radare2 binutils
pip3 install --break-system-packages pwntools ROPgadget
