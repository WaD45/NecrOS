#!/bin/sh

# ============================================================================
#  NecrOS Toolbox - Reverse Engineering
#  "Déconstruire pour comprendre"
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
    echo "  🔬 NecrOS Reverse Engineering Toolbox"
    echo "  ======================================"
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

install_debuggers() {
    log "Installation des debuggers..."
    
    # GDB - Le classique
    apk add --no-cache \
        gdb \
        gdb-doc 2>/dev/null || warn "GDB non disponible"
    
    # GEF (GDB Enhanced Features)
    if [ -f "/root/.gdbinit" ]; then
        cp /root/.gdbinit /root/.gdbinit.bak
    fi
    
    wget -q "https://raw.githubusercontent.com/hugsy/gef/main/gef.py" -O /root/.gef.py 2>/dev/null && {
        echo "source ~/.gef.py" > /root/.gdbinit
        log "GEF installé"
    } || warn "GEF non installé"
    
    # strace & ltrace
    apk add --no-cache \
        strace \
        ltrace 2>/dev/null || warn "strace/ltrace non disponibles"
    
    log "Debuggers installés"
}

install_disassemblers() {
    log "Installation des désassembleurs..."
    
    # Radare2 - Framework de reverse engineering
    apk add --no-cache radare2 2>/dev/null || {
        warn "Radare2 non dans les dépôts, installation depuis git..."
        cd /tmp
        git clone --depth 1 https://github.com/radareorg/radare2.git 2>/dev/null && {
            cd radare2
            ./sys/install.sh 2>/dev/null
        } || warn "Radare2 non installé"
    }
    
    # Cutter (GUI pour radare2) - seulement si pas en mode léger
    if [ "$LIGHT_MODE" -eq 0 ]; then
        apk add --no-cache cutter 2>/dev/null || warn "Cutter non disponible"
    fi
    
    # objdump et binutils
    apk add --no-cache \
        binutils \
        elfutils 2>/dev/null
    
    log "Désassembleurs installés"
}

install_hex_editors() {
    log "Installation des éditeurs hexadécimaux..."
    
    # xxd (vient avec vim)
    apk add --no-cache vim 2>/dev/null
    
    # hexedit
    apk add --no-cache hexedit 2>/dev/null || warn "hexedit non disponible"
    
    # hexyl (visualiseur hex moderne)
    apk add --no-cache hexyl 2>/dev/null || warn "hexyl non disponible"
    
    log "Éditeurs hex installés"
}

install_binary_analysis() {
    log "Installation des outils d'analyse binaire..."
    
    # file, strings, nm
    apk add --no-cache \
        file \
        coreutils 2>/dev/null
    
    # checksec (vérification des protections)
    pip3 install --break-system-packages checksec.py 2>/dev/null || {
        # Installation manuelle checksec
        curl -sL "https://raw.githubusercontent.com/slimm609/checksec.sh/master/checksec" -o /usr/local/bin/checksec
        chmod +x /usr/local/bin/checksec
    }
    
    # ROPgadget
    pip3 install --break-system-packages ROPgadget 2>/dev/null || warn "ROPgadget non installé"
    
    # one_gadget (pour libc)
    apk add --no-cache ruby ruby-dev 2>/dev/null && {
        gem install one_gadget 2>/dev/null || warn "one_gadget non installé"
    }
    
    log "Outils d'analyse binaire installés"
}

install_decompilers() {
    log "Installation des décompilateurs..."
    
    # Ghidra est trop lourd pour 32-bit, on propose des alternatives
    if [ "$LIGHT_MODE" -eq 1 ]; then
        warn "Ghidra non recommandé en mode 32-bit"
        warn "Utiliser: radare2 avec pdg (plugin décompilateur)"
    else
        # Note: Ghidra nécessite Java et ~2GB RAM
        TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        TOTAL_MEM_MB=$((TOTAL_MEM / 1024))
        
        if [ "$TOTAL_MEM_MB" -gt 2048 ]; then
            warn "Ghidra nécessite installation manuelle (Java + ~2GB RAM)"
            warn "Télécharger depuis: https://ghidra-sre.org/"
            
            # Installer Java si souhaité
            apk add --no-cache openjdk17-jre 2>/dev/null || warn "Java non installé"
        else
            warn "RAM insuffisante pour Ghidra (<2GB)"
        fi
    fi
    
    # RetDec (décompilateur open source) - plus léger
    warn "RetDec: installation manuelle recommandée depuis https://retdec.com/"
    
    log "Configuration décompilateurs terminée"
}

install_python_re() {
    log "Installation des bibliothèques Python RE..."
    
    pip3 install --break-system-packages \
        pwntools \
        capstone \
        keystone-engine \
        unicorn \
        angr 2>/dev/null || warn "Certaines libs non installées (angr est volumineux)"
    
    # Binwalk pour analyse de firmware
    pip3 install --break-system-packages binwalk 2>/dev/null || warn "binwalk non installé"
    
    log "Bibliothèques Python RE installées"
}

install_forensics_basic() {
    log "Installation des outils de forensics basiques..."
    
    apk add --no-cache \
        foremost \
        sleuthkit \
        testdisk \
        photorec 2>/dev/null || warn "Certains outils forensics non disponibles"
    
    # Volatility (analyse mémoire)
    pip3 install --break-system-packages volatility3 2>/dev/null || warn "Volatility3 non installé"
    
    log "Outils forensics basiques installés"
}

create_re_scripts() {
    log "Création des scripts d'aide RE..."
    
    mkdir -p /usr/local/necros/re
    
    # Script d'analyse rapide de binaire
    cat > /usr/local/bin/necros-bininfo << 'SCRIPT'
#!/bin/sh
# NecrOS - Binary Quick Analysis

if [ -z "$1" ]; then
    echo "Usage: necros-bininfo <binary>"
    exit 1
fi

BIN="$1"

if [ ! -f "$BIN" ]; then
    echo "[!] Fichier non trouvé: $BIN"
    exit 1
fi

echo ""
echo "  🔬 NecrOS Binary Analysis"
echo "  ========================="
echo "  Fichier: $BIN"
echo ""

# Type de fichier
echo "[+] Type:"
file "$BIN"
echo ""

# Hashes
echo "[+] Hashes:"
echo "  MD5:    $(md5sum "$BIN" | cut -d' ' -f1)"
echo "  SHA256: $(sha256sum "$BIN" | cut -d' ' -f1)"
echo ""

# Taille
echo "[+] Taille: $(ls -lh "$BIN" | awk '{print $5}')"
echo ""

# ELF Headers (si applicable)
if file "$BIN" | grep -q "ELF"; then
    echo "[+] ELF Headers:"
    readelf -h "$BIN" 2>/dev/null | grep -E "Class|Machine|Entry"
    echo ""
    
    # Sections
    echo "[+] Sections:"
    readelf -S "$BIN" 2>/dev/null | grep -E "\[Nr\]|\.text|\.data|\.rodata|\.bss" | head -10
    echo ""
    
    # Protections
    echo "[+] Protections:"
    if command -v checksec >/dev/null 2>&1; then
        checksec --file="$BIN" 2>/dev/null
    else
        readelf -l "$BIN" 2>/dev/null | grep -E "GNU_STACK|GNU_RELRO" || echo "  checksec non disponible"
    fi
    echo ""
    
    # Shared libraries
    echo "[+] Libraries dynamiques:"
    ldd "$BIN" 2>/dev/null || readelf -d "$BIN" 2>/dev/null | grep NEEDED | head -10
    echo ""
    
    # Symbols intéressants
    echo "[+] Symboles intéressants:"
    nm -D "$BIN" 2>/dev/null | grep -E "system|exec|gets|strcpy|printf|scanf|malloc|free" | head -15
fi

# Strings intéressants
echo ""
echo "[+] Strings intéressants (URLs, IPs, paths):"
strings "$BIN" 2>/dev/null | grep -E "http|https|ftp|/etc/|/bin/|password|secret|key|flag" | head -20

echo ""
echo "[✓] Analyse terminée"
SCRIPT
    chmod +x /usr/local/bin/necros-bininfo
    
    # Script de décompilation rapide avec radare2
    cat > /usr/local/bin/necros-disasm << 'SCRIPT'
#!/bin/sh
# NecrOS - Quick Disassembly

if [ -z "$1" ]; then
    echo "Usage: necros-disasm <binary> [function]"
    echo ""
    echo "Exemples:"
    echo "  necros-disasm ./binary          # Ouvre dans r2"
    echo "  necros-disasm ./binary main     # Désassemble main"
    echo "  necros-disasm ./binary 0x401000 # Désassemble à l'adresse"
    exit 1
fi

BIN="$1"
FUNC="${2:-}"

if [ ! -f "$BIN" ]; then
    echo "[!] Fichier non trouvé: $BIN"
    exit 1
fi

if ! command -v r2 >/dev/null 2>&1; then
    echo "[!] Radare2 non installé"
    echo "[*] Utilisation d'objdump..."
    objdump -d "$BIN" | less
    exit 0
fi

if [ -z "$FUNC" ]; then
    # Mode interactif
    echo "[+] Ouverture de $BIN dans Radare2..."
    echo "[*] Commandes utiles: aaa (analyse), pdf @ main (désassemble main), VV (visual mode)"
    r2 "$BIN"
else
    # Désassembler une fonction spécifique
    echo "[+] Désassemblage de $FUNC dans $BIN..."
    r2 -q -c "aaa; pdf @ $FUNC" "$BIN" 2>/dev/null || {
        echo "[!] Fonction $FUNC non trouvée"
        echo "[*] Fonctions disponibles:"
        r2 -q -c "aaa; afl" "$BIN" 2>/dev/null | head -20
    }
fi
SCRIPT
    chmod +x /usr/local/bin/necros-disasm
    
    # Script de recherche de gadgets ROP
    cat > /usr/local/bin/necros-rop << 'SCRIPT'
#!/bin/sh
# NecrOS - ROP Gadget Finder

if [ -z "$1" ]; then
    echo "Usage: necros-rop <binary> [pattern]"
    echo ""
    echo "Exemples:"
    echo "  necros-rop ./binary             # Tous les gadgets"
    echo "  necros-rop ./binary 'pop rdi'   # Gadgets spécifiques"
    echo "  necros-rop ./binary 'syscall'   # Syscalls"
    exit 1
fi

BIN="$1"
PATTERN="${2:-}"

if [ ! -f "$BIN" ]; then
    echo "[!] Fichier non trouvé: $BIN"
    exit 1
fi

echo "[+] Recherche de gadgets ROP dans $BIN..."
echo ""

if command -v ROPgadget >/dev/null 2>&1; then
    if [ -z "$PATTERN" ]; then
        ROPgadget --binary "$BIN" | head -50
        echo ""
        echo "[*] Limité à 50 résultats. Utiliser directement ROPgadget pour plus."
    else
        ROPgadget --binary "$BIN" | grep -i "$PATTERN"
    fi
elif command -v r2 >/dev/null 2>&1; then
    echo "[*] ROPgadget non disponible, utilisation de radare2..."
    r2 -q -c "aaa; /R" "$BIN" 2>/dev/null | head -50
else
    echo "[!] Aucun outil de recherche ROP disponible"
    echo "[*] Installer: pip3 install ROPgadget"
fi
SCRIPT
    chmod +x /usr/local/bin/necros-rop
    
    # Script pwntools template
    cat > /usr/local/necros/re/pwn_template.py << 'SCRIPT'
#!/usr/bin/env python3
"""
NecrOS - Template pwntools pour exploitation
Usage: python3 pwn_template.py [REMOTE]

Exemples:
  python3 pwn_template.py             # Local
  python3 pwn_template.py REMOTE      # Remote
"""

from pwn import *

# Configuration
BINARY = "./vulnerable"
HOST = "target.com"
PORT = 1337

# Context
context.binary = BINARY
context.log_level = 'info'  # debug, info, warning, error
# context.arch = 'amd64'    # ou 'i386'

# ELF analysis
elf = ELF(BINARY)
# libc = ELF("./libc.so.6")  # Si libc fournie
# rop = ROP(elf)

def exploit():
    global p
    
    # Connexion
    if args.REMOTE:
        p = remote(HOST, PORT)
    else:
        p = process(BINARY)
        # p = gdb.debug(BINARY, '''
        #     break main
        #     continue
        # ''')
    
    # === EXPLOITATION ===
    
    # Exemple: Buffer overflow simple
    padding = b'A' * 64
    saved_rbp = b'B' * 8
    ret_addr = p64(0xdeadbeef)
    
    payload = padding + saved_rbp + ret_addr
    
    # Envoyer le payload
    p.sendline(payload)
    
    # Récupérer le shell
    p.interactive()

if __name__ == '__main__':
    exploit()
SCRIPT
    chmod +x /usr/local/necros/re/pwn_template.py
    
    log "Scripts RE créés"
}

configure_gdb() {
    log "Configuration avancée de GDB..."
    
    # Si GEF n'est pas installé, créer une config basique
    if [ ! -f "/root/.gef.py" ]; then
        cat > /root/.gdbinit << 'EOF'
# NecrOS GDB Configuration

# Affichage
set disassembly-flavor intel
set print pretty on
set print array on

# Historique
set history save on
set history filename ~/.gdb_history
set history size 10000

# Follow fork
set follow-fork-mode child

# Pagination off (pour les scripts)
set pagination off

# Breakpoints
# set breakpoint pending on

# Aliases utiles
define xxd
    dump binary memory /tmp/gdb_dump.bin $arg0 $arg1
    shell xxd /tmp/gdb_dump.bin
end

define cls
    shell clear
end

echo \n
echo [NecrOS GDB loaded]\n
echo Commands: xxd <start> <end>, cls\n
echo \n
EOF
    fi
    
    log "GDB configuré"
}

# Main
main() {
    banner
    detect_arch
    
    install_debuggers
    install_disassemblers
    install_hex_editors
    install_binary_analysis
    install_decompilers
    install_python_re
    install_forensics_basic
    create_re_scripts
    configure_gdb
    
    echo ""
    log "🔬 Toolbox Reverse Engineering installée!"
    echo ""
    echo "  Commandes NecrOS:"
    echo "  • necros-bininfo <binary>        - Analyse rapide"
    echo "  • necros-disasm <binary> [func]  - Désassemblage"
    echo "  • necros-rop <binary> [pattern]  - Recherche ROP"
    echo ""
    echo "  Outils installés:"
    echo "  • gdb (avec GEF), strace, ltrace"
    echo "  • radare2 (r2), objdump"
    echo "  • hexedit, xxd"
    echo "  • binwalk, checksec"
    echo "  • pwntools, ROPgadget"
    echo ""
    echo "  Template pwn: /usr/local/necros/re/pwn_template.py"
    echo ""
}

main "$@"
