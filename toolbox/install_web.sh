#!/bin/sh

# ============================================================================
#  NecrOS Toolbox - Web Pentest
#  "Le web est notre terrain de jeu"
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
    echo "  🌐 NecrOS Web Pentest Toolbox"
    echo "  =============================="
    echo ""
}

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        i686|i386|i486|i586|armv7l|armv6l)
            LIGHT_MODE=1
            warn "Mode léger activé (32-bit) - Outils lourds désactivés"
            ;;
        *)
            LIGHT_MODE=0
            ;;
    esac
}

install_proxy_tools() {
    log "Installation des proxies et intercepteurs..."
    
    # mitmproxy est plus léger que Burp Suite
    pip3 install --break-system-packages \
        mitmproxy 2>/dev/null || warn "mitmproxy non installé"
    
    # Proxychains pour anonymisation
    apk add --no-cache \
        proxychains-ng \
        tor 2>/dev/null || warn "Certains outils proxy non disponibles"
    
    log "Proxies installés"
}

install_scanners() {
    log "Installation des scanners web..."
    
    # Nikto - Scanner de vulnérabilités web
    apk add --no-cache nikto 2>/dev/null || {
        warn "Nikto non dans les dépôts, installation manuelle..."
        cd /opt
        git clone https://github.com/sullo/nikto.git 2>/dev/null || warn "Git clone Nikto échoué"
        [ -f "/opt/nikto/program/nikto.pl" ] && ln -sf /opt/nikto/program/nikto.pl /usr/local/bin/nikto
    }
    
    # WhatWeb - Fingerprinting
    apk add --no-cache whatweb 2>/dev/null || {
        warn "WhatWeb non disponible dans les dépôts"
    }
    
    # SQLMap
    pip3 install --break-system-packages sqlmap 2>/dev/null || warn "SQLMap non installé"
    
    log "Scanners web installés"
}

install_fuzzers() {
    log "Installation des fuzzers..."
    
    # ffuf - Fast web fuzzer (Go)
    if [ "$LIGHT_MODE" -eq 0 ]; then
        apk add --no-cache go 2>/dev/null
        go install github.com/ffuf/ffuf/v2@latest 2>/dev/null && \
            mv ~/go/bin/ffuf /usr/local/bin/ 2>/dev/null || warn "ffuf non installé"
    fi
    
    # wfuzz - Python fuzzer (plus léger)
    pip3 install --break-system-packages wfuzz 2>/dev/null || warn "wfuzz non installé"
    
    # dirb
    apk add --no-cache dirb 2>/dev/null || warn "dirb non disponible"
    
    # gobuster alternative légère
    apk add --no-cache gobuster 2>/dev/null || warn "gobuster non disponible"
    
    log "Fuzzers installés"
}

install_exploitation() {
    log "Installation des outils d'exploitation..."
    
    # Hydra - Brute force
    apk add --no-cache hydra 2>/dev/null || warn "Hydra non disponible"
    
    # John the Ripper
    apk add --no-cache john 2>/dev/null || warn "John non disponible"
    
    # Python libraries pour exploitation
    pip3 install --break-system-packages \
        requests \
        beautifulsoup4 \
        lxml \
        pyjwt \
        python-jwt \
        fake-useragent \
        selenium 2>/dev/null || warn "Certaines libs Python non installées"
    
    log "Outils d'exploitation installés"
}

install_wordlists() {
    log "Installation des wordlists..."
    
    mkdir -p /usr/share/wordlists
    
    # SecLists (taille réduite pour 32-bit)
    if [ "$LIGHT_MODE" -eq 1 ]; then
        warn "Mode léger: installation wordlists minimales"
        # Télécharger uniquement les essentiels
        cd /usr/share/wordlists
        curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt" 2>/dev/null
        curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt" 2>/dev/null
        curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt" 2>/dev/null
    else
        # SecLists complet (attention: ~1GB)
        warn "SecLists est volumineux (~1GB). Installation partielle..."
        cd /usr/share/wordlists
        
        # Cloner avec profondeur limitée
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git 2>/dev/null || {
            warn "SecLists non cloné, téléchargement des essentiels..."
            curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
            curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt"
            curl -sLO "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt"
        }
    fi
    
    # Rockyou (optionnel, très gros)
    warn "Rockyou.txt non installé (14GB). Télécharger manuellement si besoin."
    
    log "Wordlists installées dans /usr/share/wordlists/"
}

install_python_web() {
    log "Installation des bibliothèques Python web..."
    
    pip3 install --break-system-packages \
        httpx \
        aiohttp \
        mechanize \
        scrapy \
        pycurl \
        sslyze 2>/dev/null || warn "Certaines libs non installées"
    
    log "Bibliothèques Python web installées"
}

create_web_scripts() {
    log "Création des scripts d'aide Web Pentest..."
    
    mkdir -p /usr/local/necros/web
    
    # Script de recon rapide
    cat > /usr/local/bin/necros-webrecon << 'SCRIPT'
#!/bin/sh
# NecrOS - Web Reconnaissance rapide

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Usage: necros-webrecon <url>"
    echo ""
    echo "Exemples:"
    echo "  necros-webrecon https://example.com"
    echo "  necros-webrecon example.com"
    exit 1
fi

# Ajouter https:// si absent
case "$TARGET" in
    http://*|https://*) ;;
    *) TARGET="https://$TARGET" ;;
esac

DOMAIN=$(echo "$TARGET" | sed -E 's|https?://([^/]+).*|\1|')

echo ""
echo "  🌐 NecrOS Web Recon"
echo "  ==================="
echo "  Cible: $TARGET"
echo "  Domaine: $DOMAIN"
echo ""

# DNS
echo "[+] Résolution DNS..."
host "$DOMAIN" 2>/dev/null || nslookup "$DOMAIN" 2>/dev/null
echo ""

# Headers
echo "[+] Headers HTTP..."
curl -sI "$TARGET" | head -20
echo ""

# Technologies (WhatWeb si dispo)
if command -v whatweb >/dev/null 2>&1; then
    echo "[+] Technologies détectées..."
    whatweb -q "$TARGET" 2>/dev/null
    echo ""
fi

# Certificat SSL
echo "[+] Certificat SSL..."
echo | openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" 2>/dev/null | \
    openssl x509 -noout -dates -subject 2>/dev/null || echo "Pas de SSL ou erreur"
echo ""

# Robots.txt
echo "[+] robots.txt..."
curl -s "$TARGET/robots.txt" | head -20 || echo "Non trouvé"
echo ""

echo "[✓] Recon terminé"
SCRIPT
    chmod +x /usr/local/bin/necros-webrecon
    
    # Script de scan de répertoires
    cat > /usr/local/bin/necros-dirscan << 'SCRIPT'
#!/bin/sh
# NecrOS - Directory Scanner

TARGET="$1"
WORDLIST="${2:-/usr/share/wordlists/common.txt}"

if [ -z "$TARGET" ]; then
    echo "Usage: necros-dirscan <url> [wordlist]"
    echo ""
    echo "Wordlists disponibles:"
    ls /usr/share/wordlists/*.txt 2>/dev/null | head -10
    exit 1
fi

# Vérifier wordlist
if [ ! -f "$WORDLIST" ]; then
    echo "[!] Wordlist non trouvée: $WORDLIST"
    exit 1
fi

echo "[+] Scan de $TARGET avec $WORDLIST"
echo ""

# Utiliser ffuf si disponible, sinon wfuzz, sinon curl
if command -v ffuf >/dev/null 2>&1; then
    ffuf -u "${TARGET}/FUZZ" -w "$WORDLIST" -mc 200,301,302,403 -c
elif command -v wfuzz >/dev/null 2>&1; then
    wfuzz -c -z file,"$WORDLIST" --hc 404 "${TARGET}/FUZZ"
elif command -v gobuster >/dev/null 2>&1; then
    gobuster dir -u "$TARGET" -w "$WORDLIST"
else
    echo "[!] Aucun fuzzer disponible, utilisation de curl..."
    while read -r dir; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "${TARGET}/${dir}")
        case "$response" in
            200) echo "[200] ${TARGET}/${dir}" ;;
            301|302) echo "[${response}] ${TARGET}/${dir} (redirect)" ;;
            403) echo "[403] ${TARGET}/${dir} (forbidden)" ;;
        esac
    done < "$WORDLIST"
fi
SCRIPT
    chmod +x /usr/local/bin/necros-dirscan
    
    # Script SQLi test
    cat > /usr/local/bin/necros-sqli << 'SCRIPT'
#!/bin/sh
# NecrOS - SQLi Quick Test

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Usage: necros-sqli <url_avec_parametre>"
    echo ""
    echo "Exemples:"
    echo '  necros-sqli "http://site.com/page.php?id=1"'
    echo '  necros-sqli "http://site.com/search?q=test"'
    exit 1
fi

echo "[+] Test SQLi sur: $TARGET"
echo ""

if command -v sqlmap >/dev/null 2>&1; then
    sqlmap -u "$TARGET" --batch --level=2 --risk=2
else
    echo "[!] SQLMap non installé"
    echo "[*] Test manuel basique..."
    
    # Tests basiques
    for payload in "'" "\"" "1 OR 1=1" "1' OR '1'='1" "1; DROP TABLE--"; do
        echo "[*] Test: $payload"
        encoded=$(echo "$payload" | sed 's/ /%20/g; s/'"'"'/%27/g; s/"/%22/g')
        curl -s -o /dev/null -w "Response: %{http_code}, Size: %{size_download}\n" "${TARGET}${encoded}"
    done
fi
SCRIPT
    chmod +x /usr/local/bin/necros-sqli
    
    # Script XSS test
    cat > /usr/local/bin/necros-xss << 'SCRIPT'
#!/bin/sh
# NecrOS - XSS Quick Test

TARGET="$1"
PARAM="$2"

if [ -z "$TARGET" ] || [ -z "$PARAM" ]; then
    echo "Usage: necros-xss <url> <parametre>"
    echo ""
    echo "Exemples:"
    echo '  necros-xss "http://site.com/search" "q"'
    echo '  necros-xss "http://site.com/comment" "msg"'
    exit 1
fi

echo "[+] Test XSS sur: $TARGET (param: $PARAM)"
echo ""

# Payloads XSS communs
PAYLOADS="
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
\"><script>alert(1)</script>
'><script>alert(1)</script>
javascript:alert(1)
<body onload=alert(1)>
"

echo "$PAYLOADS" | while read -r payload; do
    [ -z "$payload" ] && continue
    echo "[*] Test: $payload"
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$payload'''))" 2>/dev/null)
    response=$(curl -s "${TARGET}?${PARAM}=${encoded}")
    
    # Vérifier si le payload est reflété
    if echo "$response" | grep -q "$payload"; then
        echo "    [!] POTENTIELLEMENT VULNÉRABLE - Payload reflété!"
    fi
done
SCRIPT
    chmod +x /usr/local/bin/necros-xss
    
    log "Scripts Web Pentest créés"
}

configure_proxychains() {
    log "Configuration de proxychains..."
    
    if [ -f "/etc/proxychains/proxychains.conf" ]; then
        # Backup
        cp /etc/proxychains/proxychains.conf /etc/proxychains/proxychains.conf.bak
        
        # Configuration pour Tor
        cat > /etc/proxychains/proxychains.conf << 'EOF'
# NecrOS Proxychains Configuration
# Usage: proxychains <command>

strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
# Tor
socks5 127.0.0.1 9050
EOF
        log "Proxychains configuré pour Tor"
    fi
}

# Main
main() {
    banner
    detect_arch
    
    install_proxy_tools
    install_scanners
    install_fuzzers
    install_exploitation
    install_wordlists
    install_python_web
    create_web_scripts
    configure_proxychains
    
    echo ""
    log "🌐 Toolbox Web Pentest installée!"
    echo ""
    echo "  Commandes NecrOS:"
    echo "  • necros-webrecon <url>          - Reconnaissance rapide"
    echo "  • necros-dirscan <url> [wordlist] - Scan de répertoires"
    echo "  • necros-sqli <url?param=val>    - Test SQLi"
    echo "  • necros-xss <url> <param>       - Test XSS"
    echo ""
    echo "  Outils installés:"
    echo "  • mitmproxy, proxychains, tor"
    echo "  • nikto, whatweb, sqlmap"
    echo "  • ffuf/wfuzz, dirb, gobuster"
    echo "  • hydra, john"
    echo ""
    echo "  Wordlists: /usr/share/wordlists/"
    echo ""
}

main "$@"
