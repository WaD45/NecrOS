#!/bin/sh

# ============================================================================
#  ███╗   ██╗███████╗ ██████╗██████╗  ██████╗ ███████╗
#  ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔════╝
#  ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║███████╗
#  ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║╚════██║
#  ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝███████║
#  ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
#  
#  "Resurrecting the silicon dead"
#  Le Kali du 32-bits - Version 0.2 Alpha
# ============================================================================

set -e  # Exit on error

VERSION="0.2-alpha"
LOG_FILE="/var/log/necros_install.log"

# Couleurs pour le terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    printf "${GREEN}[+]${NC} %s\n" "$1"
}

warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" >> "$LOG_FILE"
    printf "${YELLOW}[!]${NC} %s\n" "$1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
    printf "${RED}[✗]${NC} %s\n" "$1"
    exit 1
}

banner() {
    printf "${CYAN}"
    cat << 'EOF'

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   💀 N E C R O S   I N S T A L L E R   💀                ║
    ║                                                           ║
    ║   "Le Kali du 32-bits - Ressusciter les morts"           ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
    printf "${NC}"
}

# ============================================================================
# DÉTECTION SYSTÈME
# ============================================================================

detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        i686|i386|i486|i586)
            ARCH_TYPE="x86"
            ARCH_BITS="32"
            log "Architecture détectée: x86 (32-bit) - Mode économique activé"
            ;;
        x86_64|amd64)
            ARCH_TYPE="x86_64"
            ARCH_BITS="64"
            log "Architecture détectée: x86_64 (64-bit)"
            ;;
        aarch64|arm64)
            ARCH_TYPE="aarch64"
            ARCH_BITS="64"
            log "Architecture détectée: ARM64 (64-bit)"
            ;;
        armv7l|armv6l)
            ARCH_TYPE="arm"
            ARCH_BITS="32"
            log "Architecture détectée: ARM (32-bit) - Mode économique activé"
            ;;
        *)
            error "Architecture non supportée: $ARCH"
            ;;
    esac
}

check_memory() {
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_MB=$((TOTAL_MEM / 1024))
    
    if [ "$TOTAL_MEM_MB" -lt 256 ]; then
        error "Mémoire insuffisante: ${TOTAL_MEM_MB}MB (minimum 256MB requis)"
    elif [ "$TOTAL_MEM_MB" -lt 512 ]; then
        warn "Mémoire faible: ${TOTAL_MEM_MB}MB - Mode ultra-léger recommandé"
        LOW_MEM_MODE=1
    else
        log "Mémoire RAM: ${TOTAL_MEM_MB}MB"
        LOW_MEM_MODE=0
    fi
}

check_disk() {
    DISK_FREE=$(df / | tail -1 | awk '{print $4}')
    DISK_FREE_MB=$((DISK_FREE / 1024))
    
    if [ "$DISK_FREE_MB" -lt 500 ]; then
        error "Espace disque insuffisant: ${DISK_FREE_MB}MB (minimum 500MB requis)"
    else
        log "Espace disque disponible: ${DISK_FREE_MB}MB"
    fi
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Ce script doit être exécuté en tant que root"
    fi
}

# ============================================================================
# INSTALLATION DES COMPOSANTS
# ============================================================================

setup_repositories() {
    log "Configuration des dépôts Alpine..."
    
    # Backup de l'original
    cp /etc/apk/repositories /etc/apk/repositories.bak
    
    # Activer community et testing pour les outils de hacking
    cat > /etc/apk/repositories << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
    
    apk update
}

install_core() {
    log "Installation du noyau système..."
    
    # Outils de base
    apk add --no-cache \
        build-base \
        git \
        curl \
        wget \
        python3 \
        py3-pip \
        doas \
        htop \
        neofetch \
        tmux \
        vim \
        nano \
        file \
        tree \
        jq \
        openssh \
        rsync
    
    # Configuration de doas (remplace sudo)
    echo "permit persist :wheel" > /etc/doas.conf
    chmod 600 /etc/doas.conf
    
    log "Noyau système installé"
}

install_gui() {
    log "Installation de l'interface graphique minimale..."
    
    # Setup X.org
    setup-xorg-base
    
    # Gestionnaire de fenêtres et terminal
    apk add --no-cache \
        i3wm \
        i3status \
        i3lock \
        dmenu \
        rofi \
        rxvt-unicode \
        xorg-server \
        xf86-input-evdev \
        xf86-input-libinput \
        xinit \
        xrandr \
        xset \
        xsetroot \
        feh \
        terminus-font \
        ttf-dejavu \
        font-noto
    
    # Polices supplémentaires pour le terminal
    apk add --no-cache \
        font-terminus-nerd || warn "Nerd Fonts non disponibles"
    
    log "Interface graphique installée"
}

install_shell() {
    log "Configuration du shell..."
    
    apk add --no-cache \
        zsh \
        zsh-vcs \
        shadow
    
    # Installer Oh My Zsh pour root
    if [ ! -d "/root/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || warn "Oh My Zsh installation échouée"
    fi
    
    # Changer le shell par défaut
    sed -i 's|root:/bin/ash|root:/bin/zsh|' /etc/passwd
    
    log "Shell configuré"
}

install_networking() {
    log "Installation des outils réseau de base..."
    
    apk add --no-cache \
        nmap \
        nmap-scripts \
        netcat-openbsd \
        tcpdump \
        wireshark \
        tshark \
        iptables \
        ip6tables \
        iproute2 \
        bind-tools \
        whois \
        traceroute \
        mtr \
        net-tools \
        ethtool \
        socat \
        hping3 \
        masscan
    
    log "Outils réseau installés"
}

install_python_tools() {
    log "Installation des bibliothèques Python pour le hacking..."
    
    # Installer pip packages de sécurité
    pip3 install --break-system-packages \
        scapy \
        requests \
        beautifulsoup4 \
        lxml \
        pwntools \
        impacket \
        paramiko \
        colorama \
        tabulate 2>/dev/null || warn "Certains packages Python n'ont pas pu être installés"
    
    log "Bibliothèques Python installées"
}

# ============================================================================
# CONFIGURATION VISUELLE
# ============================================================================

configure_theme() {
    log "Application du thème NecrOS..."
    
    # Configuration Xresources (urxvt)
    cat > /root/.Xresources << 'EOF'
! ============================================
!  NecrOS Terminal Theme - "The Necromancer"
! ============================================

URxvt.scrollBar: false
URxvt.scrollBar_right: false
URxvt.font: xft:Terminus:size=12:antialias=true
URxvt.boldFont: xft:Terminus:bold:size=12:antialias=true
URxvt.letterSpace: 0
URxvt.lineSpace: 0
URxvt.cursorBlink: true
URxvt.cursorUnderline: false
URxvt.saveline: 10000
URxvt.urgentOnBell: true

! Fond noir profond avec texte vert néon
URxvt*background: #0a0a0a
URxvt*foreground: #00ff41
URxvt*cursorColor: #00ff41
URxvt*cursorColor2: #0a0a0a

! Palette de couleurs NecrOS
! Noirs et gris
URxvt*color0:  #0a0a0a
URxvt*color8:  #3d3d3d

! Rouges (erreurs, warnings)
URxvt*color1:  #ff5c57
URxvt*color9:  #ff6e67

! Verts (succès, prompt)
URxvt*color2:  #00ff41
URxvt*color10: #5af78e

! Jaunes (warnings)
URxvt*color3:  #f3f99d
URxvt*color11: #f4f99d

! Bleus (info)
URxvt*color4:  #57c7ff
URxvt*color12: #57c7ff

! Magentas (spécial)
URxvt*color5:  #ff6ac1
URxvt*color13: #ff6ac1

! Cyans (liens, paths)
URxvt*color6:  #9aedfe
URxvt*color14: #9aedfe

! Blancs
URxvt*color7:  #c7c7c7
URxvt*color15: #ffffff

! Extensions
URxvt.perl-ext-common: default,matcher
URxvt.url-launcher: /usr/bin/xdg-open
URxvt.matcher.button: 1
EOF

    # Configuration i3
    mkdir -p /root/.config/i3
    cat > /root/.config/i3/config << 'EOF'
# ============================================
#  NecrOS i3 Configuration
# ============================================

# Modifier = Super (touche Windows)
set $mod Mod4

# Police
font pango:Terminus 10

# Couleurs NecrOS
set $bg-color            #0a0a0a
set $inactive-bg-color   #1a1a1a
set $text-color          #00ff41
set $inactive-text-color #666666
set $urgent-bg-color     #ff5c57

# Bordures de fenêtres
client.focused          $bg-color $bg-color $text-color #00ff41
client.unfocused        $inactive-bg-color $inactive-bg-color $inactive-text-color #1a1a1a
client.focused_inactive $inactive-bg-color $inactive-bg-color $inactive-text-color #1a1a1a
client.urgent           $urgent-bg-color $urgent-bg-color $text-color #ff5c57

# Pas de bordures de titre
default_border pixel 2
default_floating_border pixel 2

# Gaps (si supporté)
gaps inner 5
gaps outer 2

# Terminal
bindsym $mod+Return exec urxvt

# Fermer une fenêtre
bindsym $mod+Shift+q kill

# Lanceur d'applications
bindsym $mod+d exec --no-startup-id rofi -show run -theme /root/.config/rofi/necros.rasi
bindsym $mod+space exec --no-startup-id dmenu_run -nb '#0a0a0a' -nf '#00ff41' -sb '#00ff41' -sf '#0a0a0a'

# Navigation
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Déplacer les fenêtres
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Split horizontal/vertical
bindsym $mod+b split h
bindsym $mod+v split v

# Fullscreen
bindsym $mod+f fullscreen toggle

# Layouts
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Floating
bindsym $mod+Shift+space floating toggle
bindsym $mod+Button1 floating toggle

# Workspaces
set $ws1 "1:💀"
set $ws2 "2:🔍"
set $ws3 "3:🛡️"
set $ws4 "4:⚔️"
set $ws5 "5:🌐"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# Reload/Restart
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Quitter NecrOS?' -B 'Oui' 'i3-msg exit'"

# Lock screen
bindsym $mod+Escape exec i3lock -c 0a0a0a

# Screenshots
bindsym Print exec scrot ~/screenshots/%Y-%m-%d_%H-%M-%S.png

# Volume (si audio)
bindsym XF86AudioRaiseVolume exec amixer set Master 5%+
bindsym XF86AudioLowerVolume exec amixer set Master 5%-
bindsym XF86AudioMute exec amixer set Master toggle

# Resize mode
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# Bar
bar {
    status_command i3status -c /root/.config/i3/i3status.conf
    position top
    colors {
        background #0a0a0a
        statusline #00ff41
        separator  #3d3d3d
        
        focused_workspace  #00ff41 #00ff41 #0a0a0a
        active_workspace   #1a1a1a #1a1a1a #00ff41
        inactive_workspace #0a0a0a #0a0a0a #666666
        urgent_workspace   #ff5c57 #ff5c57 #ffffff
    }
}

# Autostart
exec --no-startup-id xrdb -merge ~/.Xresources
exec --no-startup-id xsetroot -solid '#0a0a0a'
EOF

    # Configuration i3status
    cat > /root/.config/i3/i3status.conf << 'EOF'
general {
    colors = true
    color_good = "#00ff41"
    color_degraded = "#f3f99d"
    color_bad = "#ff5c57"
    interval = 5
}

order += "wireless _first_"
order += "ethernet _first_"
order += "disk /"
order += "cpu_usage"
order += "memory"
order += "tztime local"

wireless _first_ {
    format_up = "📡 %essid %quality"
    format_down = "📡 down"
}

ethernet _first_ {
    format_up = "🔌 %ip"
    format_down = "🔌 down"
}

disk "/" {
    format = "💾 %avail"
}

cpu_usage {
    format = "🔥 %usage"
}

memory {
    format = "🧠 %used"
    threshold_degraded = "10%"
}

tztime local {
    format = "📅 %Y-%m-%d %H:%M"
}
EOF

    # Configuration rofi
    mkdir -p /root/.config/rofi
    cat > /root/.config/rofi/necros.rasi << 'EOF'
* {
    background: #0a0a0a;
    foreground: #00ff41;
    border-color: #00ff41;
    selected-background: #00ff41;
    selected-foreground: #0a0a0a;
}

window {
    background-color: @background;
    border: 2px;
    border-color: @border-color;
    padding: 10px;
}

mainbox {
    children: [inputbar, listview];
}

inputbar {
    children: [prompt, entry];
    background-color: @background;
}

prompt {
    background-color: @background;
    text-color: @foreground;
    padding: 5px;
}

entry {
    background-color: @background;
    text-color: @foreground;
    padding: 5px;
}

listview {
    background-color: @background;
    columns: 1;
}

element {
    background-color: @background;
    text-color: @foreground;
    padding: 5px;
}

element selected {
    background-color: @selected-background;
    text-color: @selected-foreground;
}
EOF

    # xinitrc
    cat > /root/.xinitrc << 'EOF'
#!/bin/sh
# NecrOS X11 Startup

# Charger les ressources
xrdb -merge ~/.Xresources

# Fond noir
xsetroot -solid '#0a0a0a'

# Désactiver le screensaver
xset s off
xset -dpms

# Démarrer i3
exec i3
EOF
    chmod +x /root/.xinitrc

    log "Thème NecrOS appliqué"
}

configure_zshrc() {
    log "Configuration du prompt ZSH..."
    
    cat > /root/.zshrc << 'EOF'
# ============================================
#  NecrOS ZSH Configuration
# ============================================

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
    git
    sudo
    docker
    history
    colored-man-pages
)

source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# Prompt personnalisé NecrOS (fallback si pas oh-my-zsh)
if [ ! -d "$ZSH" ]; then
    autoload -U colors && colors
    PROMPT='%{$fg[green]%}💀 %{$fg[cyan]%}%n%{$reset_color%}@%{$fg[red]%}necros%{$reset_color%}:%{$fg[yellow]%}%~%{$reset_color%}
%{$fg[green]%}❯%{$reset_color%} '
fi

# Aliases NecrOS
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Aliases Hacking
alias scan='nmap -sV -sC'
alias fastscan='nmap -F'
alias fullscan='nmap -p- -sV -sC'
alias listen='nc -lvnp'
alias serve='python3 -m http.server'
alias sniff='tcpdump -i any -w'
alias myip='curl -s ifconfig.me'
alias localip='ip addr show | grep "inet " | grep -v 127.0.0.1'

# Variables d'environnement
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export TERM=xterm-256color

# Historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Options ZSH
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT

# Banner au démarrage
echo ""
echo "  💀 NecrOS v${NECROS_VERSION:-0.2} - \"Resurrecting the silicon dead\""
echo "  Architecture: $(uname -m) | Kernel: $(uname -r)"
echo ""
EOF

    log "Configuration ZSH terminée"
}

# ============================================================================
# CRÉATION DES SCRIPTS DE TOOLBOX
# ============================================================================

create_toolbox_scripts() {
    log "Création des scripts de toolbox..."
    
    mkdir -p /usr/local/necros/toolbox
    
    # Créer le wrapper principal
    cat > /usr/local/bin/necros-toolbox << 'EOF'
#!/bin/sh
# NecrOS Toolbox Manager

show_menu() {
    echo ""
    echo "  💀 NecrOS Toolbox Manager"
    echo "  ========================="
    echo ""
    echo "  [1] 📡 Radio/WiFi Hacking"
    echo "  [2] 🌐 Web Pentest"
    echo "  [3] 🔬 Reverse Engineering"
    echo "  [4] 🛡️  Blue Team / Défense"
    echo "  [5] 📦 Installer tout"
    echo "  [0] Quitter"
    echo ""
    printf "  Choix: "
}

case "$1" in
    wifi|1)
        /usr/local/necros/toolbox/install_wifi.sh
        ;;
    web|2)
        /usr/local/necros/toolbox/install_web.sh
        ;;
    reverse|re|3)
        /usr/local/necros/toolbox/install_reverse.sh
        ;;
    blue|4)
        /usr/local/necros/toolbox/install_blue.sh
        ;;
    all|5)
        /usr/local/necros/toolbox/install_wifi.sh
        /usr/local/necros/toolbox/install_web.sh
        /usr/local/necros/toolbox/install_reverse.sh
        /usr/local/necros/toolbox/install_blue.sh
        ;;
    *)
        show_menu
        read choice
        case $choice in
            1) exec $0 wifi ;;
            2) exec $0 web ;;
            3) exec $0 reverse ;;
            4) exec $0 blue ;;
            5) exec $0 all ;;
            0) exit 0 ;;
            *) echo "Option invalide"; exit 1 ;;
        esac
        ;;
esac
EOF
    chmod +x /usr/local/bin/necros-toolbox
    
    log "Scripts de toolbox créés"
}

# ============================================================================
# FINALISATION
# ============================================================================

create_welcome_script() {
    cat > /etc/profile.d/necros-welcome.sh << 'EOF'
#!/bin/sh
# NecrOS Welcome Message

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    clear
    cat << 'BANNER'

    ███╗   ██╗███████╗ ██████╗██████╗  ██████╗ ███████╗
    ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔════╝
    ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║███████╗
    ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║╚════██║
    ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝███████║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
    
    "Resurrecting the silicon dead"
    
    💀 Commandes rapides:
       startx          - Lancer l'interface graphique
       necros-toolbox  - Installer des outils supplémentaires
       neofetch        - Informations système
    
BANNER
    echo ""
fi
EOF
    chmod +x /etc/profile.d/necros-welcome.sh
}

cleanup() {
    log "Nettoyage..."
    apk cache clean 2>/dev/null || true
    rm -rf /tmp/* 2>/dev/null || true
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    banner
    
    # Vérifications
    check_root
    detect_arch
    check_memory
    check_disk
    
    log "Début de l'installation NecrOS v${VERSION}"
    
    # Installation
    setup_repositories
    install_core
    install_gui
    install_shell
    install_networking
    install_python_tools
    
    # Configuration
    configure_theme
    configure_zshrc
    create_toolbox_scripts
    create_welcome_script
    
    # Finalisation
    cleanup
    
    # Message de fin
    printf "${GREEN}"
    cat << 'EOF'

    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   💀 INSTALLATION TERMINÉE !                             ║
    ║                                                           ║
    ║   Commandes:                                              ║
    ║   • startx              - Lancer l'interface              ║
    ║   • necros-toolbox      - Ajouter des outils              ║
    ║                                                           ║
    ║   Raccourcis i3:                                          ║
    ║   • Super+Enter         - Terminal                        ║
    ║   • Super+D             - Menu applications               ║
    ║   • Super+Shift+Q       - Fermer fenêtre                  ║
    ║   • Super+1-9           - Workspaces                      ║
    ║                                                           ║
    ║   Bienvenue dans l'abysse, Necromancien.                  ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝

EOF
    printf "${NC}"
    
    log "Installation NecrOS v${VERSION} terminée avec succès"
}

# Exécution
main "$@"
