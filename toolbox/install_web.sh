#!/bin/sh
echo "[*] Web Tools..."
apk add --no-cache nmap nikto proxychains-ng tor
pip3 install --break-system-packages sqlmap
