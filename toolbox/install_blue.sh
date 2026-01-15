#!/bin/sh

# ============================================================================
#  NecrOS Toolbox - Blue Team / Défense
#  "La meilleure attaque est une bonne défense"
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${GREEN}[+]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
error() { printf "${RED}[✗]${NC} %s\n" "$1"; exit 1; }

[ "$(id -u)" -ne 0 ] && error "Exécuter en tant que root"

banner() {
    echo ""
    echo "  🛡️ NecrOS Blue Team Toolbox"
    echo "  ============================"
    echo ""
}

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        i686|i386|i486|i586|armv7l|armv6l)
            LIGHT_MODE=1
            warn "Mode léger activé (32-bit)"
            ;;
        *)
            LIGHT_MODE=0
            ;;
    esac
}

install_ids_ips() {
    log "Installation des IDS/IPS..."
    apk add --no-cache suricata fail2ban 2>/dev/null || warn "Certains IDS non disponibles"
    log "IDS/IPS installés"
}

install_log_analysis() {
    log "Installation des outils d'analyse de logs..."
    apk add --no-cache logrotate goaccess lnav 2>/dev/null || warn "Certains outils non disponibles"
    log "Outils de logs installés"
}

install_network_monitoring() {
    log "Installation des outils de monitoring réseau..."
    apk add --no-cache iftop nethogs iptraf-ng nload vnstat tcpflow 2>/dev/null || warn "Certains outils non disponibles"
    log "Outils monitoring installés"
}

install_forensics() {
    log "Installation des outils forensics..."
    apk add --no-cache sleuthkit foremost testdisk yara 2>/dev/null || warn "Certains outils non disponibles"
    pip3 install --break-system-packages yara-python volatility3 2>/dev/null || warn "Python tools non installés"
    log "Outils forensics installés"
}

install_malware_analysis() {
    log "Installation des outils d'analyse malware..."
    apk add --no-cache clamav 2>/dev/null || warn "ClamAV non disponible"
    freshclam 2>/dev/null || warn "Mise à jour ClamAV échouée"
    pip3 install --break-system-packages pefile oletools python-magic 2>/dev/null || true
    log "Outils malware installés"
}

install_hardening_tools() {
    log "Installation des outils de hardening..."
    apk add --no-cache rkhunter chkrootkit 2>/dev/null || warn "Certains outils non disponibles"
    
    # Lynis
    if [ ! -d "/opt/lynis" ]; then
        cd /opt && git clone --depth 1 https://github.com/CISOfy/lynis.git 2>/dev/null
        ln -sf /opt/lynis/lynis /usr/local/bin/lynis 2>/dev/null
    fi
    log "Outils hardening installés"
}

create_blue_scripts() {
    log "Création des scripts Blue Team..."
    mkdir -p /usr/local/necros/blue

    # Security check script
    cat > /usr/local/bin/necros-seccheck << 'EOF'
#!/bin/sh
echo "🛡️ NecrOS Security Check"
echo "========================"
echo ""
echo "[+] Utilisateurs UID 0:"
awk -F: '$3 == 0 {print "  - " $1}' /etc/passwd
echo ""
echo "[+] Ports en écoute:"
ss -tuln | grep LISTEN | head -10
echo ""
echo "[+] Fichiers SUID:"
find /usr/bin /bin -perm -4000 2>/dev/null | head -10
echo ""
echo "[+] Dernières connexions:"
last -n 5 2>/dev/null
echo ""
echo "[✓] Check terminé"
EOF
    chmod +x /usr/local/bin/necros-seccheck

    # Monitor script
    cat > /usr/local/bin/necros-bluewatch << 'EOF'
#!/bin/sh
case "${1:-basic}" in
    net) iftop 2>/dev/null || nethogs 2>/dev/null || watch -n1 'ss -tuln' ;;
    proc) htop 2>/dev/null || top ;;
    logs) tail -f /var/log/messages /var/log/auth.log 2>/dev/null ;;
    *) watch -n2 'echo "=== CPU ===" && top -bn1 | head -5 && echo "" && echo "=== NET ===" && ss -tuln | head -8' ;;
esac
EOF
    chmod +x /usr/local/bin/necros-bluewatch

    # Audit script
    cat > /usr/local/bin/necros-audit << 'EOF'
#!/bin/sh
OUT="/tmp/necros_audit_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
echo "🛡️ NecrOS Audit -> $OUT"

echo "[+] System info..." && uname -a > "$OUT/system.txt" && cat /etc/passwd >> "$OUT/system.txt"
echo "[+] Network..." && ss -tunapl > "$OUT/network.txt" && ip addr >> "$OUT/network.txt"
echo "[+] Processes..." && ps auxf > "$OUT/processes.txt"
echo "[+] SUID files..." && find / -perm -4000 -type f 2>/dev/null > "$OUT/suid.txt"
echo "[+] Cron..." && cat /etc/crontab > "$OUT/cron.txt" 2>/dev/null

if command -v lynis >/dev/null 2>&1; then
    echo "[+] Lynis audit..."
    lynis audit system --quick --no-colors > "$OUT/lynis.txt" 2>&1
fi

tar czf "${OUT}.tar.gz" -C /tmp "$(basename $OUT)"
echo "[✓] Audit: ${OUT}.tar.gz"
EOF
    chmod +x /usr/local/bin/necros-audit

    log "Scripts Blue Team créés"
}

# Main
main() {
    banner
    detect_arch
    
    install_ids_ips
    install_log_analysis
    install_network_monitoring
    install_forensics
    install_malware_analysis
    install_hardening_tools
    create_blue_scripts
    
    echo ""
    log "🛡️ Toolbox Blue Team installée!"
    echo ""
    echo "  Commandes:"
    echo "  • necros-seccheck       - Check sécurité rapide"
    echo "  • necros-bluewatch      - Monitoring live"
    echo "  • necros-audit          - Audit complet"
    echo ""
    echo "  Outils: suricata, fail2ban, lynis, clamav, yara"
    echo ""
}

main "$@"
