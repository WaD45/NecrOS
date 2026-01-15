#!/bin/sh
# NecrOS VANISH
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

[ "$(id -u)" -ne 0 ] && echo "Root required." && exit 1

echo "${RED}💀 VANISH PROTOCOL${NC}"

echo -n "Logs... "
for log in /var/log/messages /var/log/syslog /var/log/auth.log /var/log/wtmp; do
    [ -f "$log" ] && > "$log"
done
echo "${GREEN}OK${NC}"

echo -n "History... "
find /root /home/* -name ".*_history" -exec rm -f {} \;
unset HISTFILE
export HISTSIZE=0
echo "${GREEN}OK${NC}"

echo -n "RAM... "
sync; echo 3 > /proc/sys/vm/drop_caches
echo "${GREEN}OK${NC}"

echo "${GREEN}Ghost mode active.${NC}"
