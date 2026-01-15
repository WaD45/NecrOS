#!/bin/sh

# NecrOS v0.3 - Phantom Edition
set -e
LOG_FILE="/var/log/necros_install.log"

log() { echo "[+] $1"; echo "$1" >> "$LOG_FILE"; }

# 1. Base System
log "Installation de la base..."
# Fix repos
[ ! -f /etc/apk/repositories.bak ] && cp /etc/apk/repositories /etc/apk/repositories.bak
cat > /etc/apk/repositories << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
apk update
apk add --no-cache build-base git curl wget python3 py3-pip doas htop neofetch tmux vim nano file tree jq openssh rsync dialog coreutils nmap netcat-openbsd

echo "permit persist :wheel" > /etc/doas.conf

# 2. GUI (i3)
log "Installation Interface..."
setup-xorg-base
apk add --no-cache i3wm i3status i3lock dmenu rofi rxvt-unicode xorg-server xf86-input-libinput xinit xrandr xset xsetroot feh terminus-font ttf-dejavu font-noto xf86-video-vesa xf86-video-fbdev

# 3. Shell (ZSH)
log "Config Shell..."
apk add --no-cache zsh shadow
sed -i 's|root:/bin/ash|root:/bin/zsh|' /etc/passwd
cat > /root/.zshrc << 'EOF'
export TERM=xterm-256color
autoload -U colors && colors
PROMPT='%{$fg[green]%}💀 %{$fg[cyan]%}%n%{$reset_color%}@%{$fg[red]%}necros%{$reset_color%}:%{$fg[yellow]%}%~%{$reset_color%}
%{$fg[green]%}❯%{$reset_color%} '
alias ll='ls -la --color=auto'
alias scan='nmap -sV -sC'
alias vanish='necros-vanish'
alias forge='necros-payload'
EOF

# 4. Core Features
log "Installation Core..."
cp core/vanish.sh /usr/local/bin/necros-vanish
cp core/payload.sh /usr/local/bin/necros-payload
chmod +x /usr/local/bin/necros-vanish /usr/local/bin/necros-payload

mkdir -p /usr/local/necros/toolbox
cp toolbox/*.sh /usr/local/necros/toolbox/
chmod +x /usr/local/necros/toolbox/*.sh

# Toolbox Wrapper
cat > /usr/local/bin/necros-toolbox << 'EOF'
#!/bin/sh
echo "💀 NecrOS Toolbox"
echo "[1] WiFi [2] Web [3] Reverse [4] Blue [5] All"
read -p "> " c
case $c in
  1) /usr/local/necros/toolbox/install_wifi.sh ;;
  2) /usr/local/necros/toolbox/install_web.sh ;;
  3) /usr/local/necros/toolbox/install_reverse.sh ;;
  4) /usr/local/necros/toolbox/install_blue.sh ;;
  5) for i in /usr/local/necros/toolbox/*.sh; do $i; done ;;
esac
EOF
chmod +x /usr/local/bin/necros-toolbox

# 5. Splash Screen
log "Installation Splash..."
cp core/splash.sh /etc/init.d/necro-splash
chmod +x /etc/init.d/necro-splash
rc-update add necro-splash default

# 6. Theme
log "Application Theme..."
cat > /root/.Xresources << 'EOF'
URxvt.scrollBar: false
URxvt.font: xft:Terminus:size=12
URxvt*background: #0a0a0a
URxvt*foreground: #00ff41
URxvt*cursorColor: #00ff41
EOF

mkdir -p /root/.config/i3
cat > /root/.config/i3/config << 'EOF'
set $mod Mod4
font pango:Terminus 10
exec --no-startup-id xrdb -merge ~/.Xresources
exec --no-startup-id xsetroot -solid '#0a0a0a'
bindsym $mod+Return exec urxvt
bindsym $mod+d exec dmenu_run
bindsym $mod+Shift+q kill
bindsym $mod+Shift+e exec "i3-msg exit"
bar { status_command i3status position top colors { background #0a0a0a statusline #00ff41 } }
client.focused #00ff41 #00ff41 #000000 #00ff41
EOF
echo "exec i3" > /root/.xinitrc

echo "💀 INSTALLATION TERMINÉE. Reboot required."
