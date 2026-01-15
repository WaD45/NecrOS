#!/bin/sh
# ============================================================================
#  NecrOS VANISH - "Leave No Trace"
#  Mode Fantôme & Effacement d'Urgence
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VERSION="1.0"

[ "$(id -u)" -ne 0 ] && echo "${RED}[!] Root requis${NC}" && exit 1

banner() {
    echo ""
    echo "${RED}    ██╗   ██╗ █████╗ ███╗   ██╗██╗███████╗██╗  ██╗${NC}"
    echo "${RED}    ██║   ██║██╔══██╗████╗  ██║██║██╔════╝██║  ██║${NC}"
    echo "${RED}    ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║╚════██║██╔══██║${NC}"
    echo "${RED}     ╚████╔╝ ██║  ██║██║ ╚████║██║███████║██║  ██║${NC}"
    echo ""
    echo "${CYAN}    \"Dans l'ombre, nous disparaissons\"${NC}"
    echo ""
}

show_help() {
    echo "Usage: necros-vanish [MODE]"
    echo ""
    echo "Modes:"
    echo "  ghost     Mode fantôme (défaut) - Efface logs et history"
    echo "  stealth   Mode furtif - Ghost + connexions + cache"
    echo "  nuclear   Mode nucléaire - Destruction totale (DANGER!)"
    echo "  status    Affiche ce qui sera effacé"
    echo ""
    echo "Options:"
    echo "  -y, --yes    Pas de confirmation"
    echo "  -h, --help   Affiche cette aide"
}

clear_logs() {
    echo -n "${YELLOW}[*]${NC} Logs système... "
    for log in /var/log/messages /var/log/syslog /var/log/auth.log /var/log/secure /var/log/wtmp /var/log/btmp /var/log/lastlog; do
        [ -f "$log" ] && > "$log" 2>/dev/null
    done
    journalctl --rotate 2>/dev/null; journalctl --vacuum-time=1s 2>/dev/null
    echo "${GREEN}OK${NC}"
}

clear_history() {
    echo -n "${YELLOW}[*]${NC} Historiques shell... "
    find /root /home -maxdepth 2 \( -name ".*_history" -o -name ".lesshst" -o -name ".viminfo" \) -delete 2>/dev/null
    unset HISTFILE; export HISTSIZE=0 HISTFILESIZE=0 SAVEHIST=0
    echo "${GREEN}OK${NC}"
}

clear_connections() {
    echo -n "${YELLOW}[*]${NC} Traces de connexions... "
    find /root /home -maxdepth 3 -name "known_hosts" -delete 2>/dev/null
    > /var/log/lastlog 2>/dev/null; > /var/log/wtmp 2>/dev/null; > /var/run/utmp 2>/dev/null
    echo "${GREEN}OK${NC}"
}

clear_cache() {
    echo -n "${YELLOW}[*]${NC} Cache et temp... "
    sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    rm -rf /tmp/* /var/tmp/* 2>/dev/null
    apk cache clean 2>/dev/null
    rm -rf /root/.cache 2>/dev/null
    echo "${GREEN}OK${NC}"
}

clear_network_traces() {
    echo -n "${YELLOW}[*]${NC} Traces réseau... "
    ip neigh flush all 2>/dev/null
    conntrack -F 2>/dev/null
    echo "${GREEN}OK${NC}"
}

nuclear_mode() {
    echo "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo "${RED}║  ⚠️  NUCLEAR MODE - DESTRUCTION TOTALE  ⚠️            ║${NC}"
    echo "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    
    if [ "$FORCE" != "1" ]; then
        echo -n "${YELLOW}Tapez 'VANISH' pour confirmer: ${NC}"
        read confirm
        [ "$confirm" != "VANISH" ] && echo "${RED}Annulé.${NC}" && exit 1
    fi
    
    echo "${RED}[NUCLEAR] Initialisation...${NC}"
    clear_logs; clear_history; clear_connections; clear_cache; clear_network_traces
    
    echo -n "${YELLOW}[*]${NC} Suppression sécurisée... "
    find /tmp -type f -exec shred -u -z -n 1 {} \; 2>/dev/null
    dd if=/dev/zero of=/tmp/.wipe bs=1M count=50 2>/dev/null; rm -f /tmp/.wipe
    echo "${GREEN}OK${NC}"
    
    echo "${RED}[NUCLEAR] Protocole terminé.${NC}"
}

ghost_mode() {
    echo "${CYAN}[GHOST MODE]${NC}"
    clear_logs; clear_history
    echo "${GREEN}[✓] Mode fantôme activé${NC}"
}

stealth_mode() {
    echo "${CYAN}[STEALTH MODE]${NC}"
    clear_logs; clear_history; clear_connections; clear_cache; clear_network_traces
    echo "${GREEN}[✓] Mode furtif activé${NC}"
}

status_mode() {
    echo "${CYAN}[STATUS] Éléments qui seront effacés:${NC}"
    echo "Logs:"; ls -la /var/log/*.log /var/log/messages 2>/dev/null | head -5
    echo "History:"; find /root /home -maxdepth 2 -name ".*_history" 2>/dev/null
    echo "Cache: $(du -sh /tmp 2>/dev/null | cut -f1)"
}

# Parse arguments
MODE="ghost"; FORCE=0
while [ $# -gt 0 ]; do
    case "$1" in
        ghost|stealth|nuclear|status) MODE="$1" ;;
        -y|--yes) FORCE=1 ;;
        -h|--help) show_help; exit 0 ;;
    esac
    shift
done

banner
case "$MODE" in
    ghost) ghost_mode ;; stealth) stealth_mode ;; nuclear) nuclear_mode ;; status) status_mode ;;
esac
echo "${CYAN}💀 NecrOS VANISH v${VERSION}${NC}"
