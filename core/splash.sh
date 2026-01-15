#!/sbin/openrc-run
# ============================================================================
#  NecrOS SPLASH - Boot Animation
#  Service OpenRC pour afficher le splash au démarrage
# ============================================================================

description="NecrOS Boot Splash"

depend() {
    after localmount
    before agetty
}

# Couleurs
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_CYAN='\033[1;36m'
C_YELLOW='\033[1;33m'
C_NC='\033[0m'

start() {
    clear
    
    # ASCII Art NecrOS
    echo -e "${C_GREEN}"
    cat << 'SKULL'

                            ....
                          .'   ':.
                         :       ::
                        :         :
                        :         :
                        ::.......::
                      .'           '.
                     :    .....     :
                    :   .:     :.    :
                   :   :  O   O  :   :
                   :   :    _    :   :
                    :   :  \_/  :   :
                     :   '.....'   :
                      '.         .'
                        '::....::'
                       ::.      .:
                      :   '.  .'  :
                     :      ''     :
                     :             :
                     :   NECROS   :
                      :           :
                       ':.......:'

SKULL

    echo -e "${C_CYAN}"
    cat << 'BANNER'
    ███╗   ██╗███████╗ ██████╗██████╗  ██████╗ ███████╗
    ████╗  ██║██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔════╝
    ██╔██╗ ██║█████╗  ██║     ██████╔╝██║   ██║███████╗
    ██║╚██╗██║██╔══╝  ██║     ██╔══██╗██║   ██║╚════██║
    ██║ ╚████║███████╗╚██████╗██║  ██║╚██████╔╝███████║
    ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
BANNER

    echo -e "${C_NC}"
    echo ""
    echo -e "    ${C_RED}\"Resurrecting the Silicon Dead\"${C_NC}"
    echo -e "    ${C_YELLOW}Version 0.3 Alpha - Le Kali du 32-bits${C_NC}"
    echo ""
    
    # Barre de progression simulée
    echo -n "    ["
    for i in $(seq 1 30); do
        echo -n "${C_GREEN}█${C_NC}"
        sleep 0.05
    done
    echo "] ${C_GREEN}OK${C_NC}"
    
    echo ""
    echo -e "    ${C_CYAN}Initializing systems...${C_NC}"
    sleep 0.3
    echo -e "    ${C_GREEN}[✓]${C_NC} Kernel loaded"
    sleep 0.2
    echo -e "    ${C_GREEN}[✓]${C_NC} Network stack ready"
    sleep 0.2
    echo -e "    ${C_GREEN}[✓]${C_NC} Security modules active"
    sleep 0.2
    echo -e "    ${C_GREEN}[✓]${C_NC} Toolbox available"
    echo ""
    echo -e "    ${C_YELLOW}Type 'startx' to enter the abyss...${C_NC}"
    echo ""
    sleep 1
}

stop() {
    return 0
}

# Mode standalone (si exécuté directement)
case "$1" in
    start|"")
        start
        ;;
    test)
        # Test du splash sans OpenRC
        start
        ;;
esac
