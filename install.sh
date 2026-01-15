#!/bin/sh
# NecrOS Quick Install
# Usage: curl -sL [url]/install.sh | sh

set -e
echo "💀 NecrOS Quick Install"

# Vérifier root
[ "$(id -u)" -ne 0 ] && echo "Exécuter en root!" && exit 1

# Télécharger et exécuter
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/necro_install.sh" ]; then
    sh "$SCRIPT_DIR/necro_install.sh"
else
    echo "Fichier necro_install.sh non trouvé"
    exit 1
fi
