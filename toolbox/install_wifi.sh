#!/bin/sh

# ============================================================================
#  NecrOS Toolbox - WiFi/Radio Hacking
#  "Les ondes sont nos alliées"
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { printf "${GREEN}[+]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
error() { printf "${RED}[✗]${NC} %s\n" "$1"; exit 1; }

# Vérifier root
[ "$(id -u)" -ne 0 ] && error "Exécuter en tant que root"

banner() {
    echo ""
    echo "  📡 NecrOS WiFi/Radio Toolbox"
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

install_wifi_tools() {
    log "Installation des outils WiFi..."
    
    # Outils WiFi de base
    apk add --no-cache \
        aircrack-ng \
        iw \
        wireless-tools \
        wpa_supplicant \
        hostapd \
        macchanger \
        reaver 2>/dev/null || warn "Certains outils WiFi non disponibles"
    
    # Hashcat pour le cracking (si 64-bit et assez de RAM)
    if [ "$LIGHT_MODE" -eq 0 ]; then
        TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        TOTAL_MEM_MB=$((TOTAL_MEM / 1024))
        
        if [ "$TOTAL_MEM_MB" -gt 1024 ]; then
            apk add --no-cache hashcat 2>/dev/null || warn "Hashcat non disponible"
        else
            warn "RAM insuffisante pour Hashcat (>1GB recommandé)"
        fi
    fi
    
    log "Outils WiFi installés"
}

install_bluetooth_tools() {
    log "Installation des outils Bluetooth..."
    
    apk add --no-cache \
        bluez \
        bluez-utils \
        bluez-deprecated 2>/dev/null || warn "Certains outils Bluetooth non disponibles"
    
    log "Outils Bluetooth installés"
}

install_sdr_tools() {
    log "Installation des outils SDR (Software Defined Radio)..."
    
    if [ "$LIGHT_MODE" -eq 1 ]; then
        warn "Mode léger: installation SDR minimale"
        apk add --no-cache \
            rtl-sdr 2>/dev/null || warn "RTL-SDR non disponible"
    else
        apk add --no-cache \
            rtl-sdr \
            gnuradio \
            gqrx 2>/dev/null || warn "Certains outils SDR non disponibles"
    fi
    
    # Règles udev pour RTL-SDR
    if [ -d "/etc/udev/rules.d" ]; then
        cat > /etc/udev/rules.d/20-rtlsdr.rules << 'EOF'
# RTL-SDR rules
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE:="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"
EOF
        log "Règles udev RTL-SDR configurées"
    fi
    
    log "Outils SDR installés"
}

install_python_wireless() {
    log "Installation des bibliothèques Python wireless..."
    
    pip3 install --break-system-packages \
        scapy \
        wifite 2>/dev/null || warn "Wifite non installé"
    
    log "Bibliothèques Python wireless installées"
}

create_wifi_scripts() {
    log "Création des scripts d'aide WiFi..."
    
    mkdir -p /usr/local/necros/wifi
    
    # Script de mise en mode monitor
    cat > /usr/local/bin/necros-monitor << 'EOF'
#!/bin/sh
# NecrOS - Mode Monitor Helper

show_help() {
    echo "Usage: necros-monitor <interface> [start|stop]"
    echo ""
    echo "Exemples:"
    echo "  necros-monitor wlan0 start    # Activer mode monitor"
    echo "  necros-monitor wlan0 stop     # Désactiver mode monitor"
    echo ""
}

if [ $# -lt 2 ]; then
    show_help
    exit 1
fi

IFACE="$1"
ACTION="$2"

case "$ACTION" in
    start)
        echo "[+] Activation mode monitor sur $IFACE..."
        ip link set "$IFACE" down
        iw dev "$IFACE" set type monitor
        ip link set "$IFACE" up
        echo "[+] Mode monitor activé"
        ;;
    stop)
        echo "[+] Désactivation mode monitor sur $IFACE..."
        ip link set "$IFACE" down
        iw dev "$IFACE" set type managed
        ip link set "$IFACE" up
        echo "[+] Mode managed restauré"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
EOF
    chmod +x /usr/local/bin/necros-monitor
    
    # Script de scan rapide
    cat > /usr/local/bin/necros-wifiscan << 'EOF'
#!/bin/sh
# NecrOS - WiFi Scanner

IFACE="${1:-wlan0}"

echo "[+] Scan WiFi sur $IFACE..."
echo "[!] Appuyer sur Ctrl+C pour arrêter"
echo ""

# Vérifier si en mode monitor
MODE=$(iw dev "$IFACE" info 2>/dev/null | grep type | awk '{print $2}')

if [ "$MODE" != "monitor" ]; then
    echo "[!] Interface pas en mode monitor. Utiliser: necros-monitor $IFACE start"
    echo "[*] Scan passif avec iw..."
    iw dev "$IFACE" scan 2>/dev/null | grep -E "SSID|signal|BSS"
else
    airodump-ng "$IFACE"
fi
EOF
    chmod +x /usr/local/bin/necros-wifiscan
    
    # Script de deauth
    cat > /usr/local/bin/necros-deauth << 'EOF'
#!/bin/sh
# NecrOS - Deauth Helper (À utiliser légalement uniquement!)

show_help() {
    cat << 'HELP'
Usage: necros-deauth <interface> <bssid> [client_mac] [count]

⚠️  AVERTISSEMENT LÉGAL ⚠️
Ce script ne doit être utilisé que sur des réseaux dont vous
avez l'autorisation explicite de tester. L'utilisation non
autorisée est ILLÉGALE.

Exemples:
  necros-deauth wlan0mon AA:BB:CC:DD:EE:FF              # Deauth broadcast
  necros-deauth wlan0mon AA:BB:CC:DD:EE:FF 11:22:33:44:55:66  # Deauth ciblé
  necros-deauth wlan0mon AA:BB:CC:DD:EE:FF FF:FF:FF:FF:FF:FF 100  # 100 packets

HELP
}

if [ $# -lt 2 ]; then
    show_help
    exit 1
fi

IFACE="$1"
BSSID="$2"
CLIENT="${3:-FF:FF:FF:FF:FF:FF}"
COUNT="${4:-0}"

echo "[!] ATTENTION: Utilisation légale uniquement!"
echo "[+] Interface: $IFACE"
echo "[+] BSSID cible: $BSSID"
echo "[+] Client: $CLIENT"
echo ""
read -p "Confirmer? (y/N) " confirm
[ "$confirm" != "y" ] && exit 0

aireplay-ng -0 "$COUNT" -a "$BSSID" -c "$CLIENT" "$IFACE"
EOF
    chmod +x /usr/local/bin/necros-deauth
    
    log "Scripts WiFi créés"
}

# Main
main() {
    banner
    detect_arch
    
    install_wifi_tools
    install_bluetooth_tools
    install_sdr_tools
    install_python_wireless
    create_wifi_scripts
    
    echo ""
    log "📡 Toolbox WiFi/Radio installée!"
    echo ""
    echo "  Commandes disponibles:"
    echo "  • necros-monitor <iface> start/stop  - Mode monitor"
    echo "  • necros-wifiscan [iface]            - Scanner WiFi"
    echo "  • necros-deauth                      - Deauth (légal!)"
    echo "  • aircrack-ng, airodump-ng, etc."
    echo ""
}

main "$@"
