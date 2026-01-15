#!/bin/sh
# NecrOS ISO Builder - "The Phylactery Forge"

set -e

# 1. Installer les outils de construction
echo "[+] Installation du kit de forge (alpine-sdk)..."
apk add alpine-sdk build-base apk-tools alpine-conf xorriso syslinux

# 2. Préparer l'utilisateur 'builder' (nécessaire pour mkimage)
if ! id "builder" >/dev/null 2>&1; then
    adduser -D builder
    addgroup builder abuild
    # Générer les clés de signature temporaires
    su - builder -c "abuild-keygen -a -i -n"
fi

# 3. Créer la structure de l'ISO
echo "[+] Préparation des fichiers NecrOS..."
MKIMG_DIR="/home/builder/necros-iso"
mkdir -p "$MKIMG_DIR/etc/apk"

# Copier les dépôts
cp /etc/apk/repositories "$MKIMG_DIR/etc/apk/"

# Créer un script de "genapkovl" (C'est ce qui définit tes fichiers persos)
# Pour faire simple : on va copier tes scripts actuels dans l'ISO
cat > "$MKIMG_DIR/genapkovl-necros.sh" << 'EOF'
#!/bin/sh
# Ce script génère l'overlay (les fichiers customs de NecrOS)
HOSTNAME="necros-live"
PROJECT="necros"

cleanup() {
    rm -rf "$tmp"
}

trap cleanup EXIT
tmp="$(mktemp -d)"
mkdir -p "$tmp"

# --- INJECTION DES FICHIERS ---
# On recrée l'arborescence /etc, /usr/local/bin, etc.
mkdir -p "$tmp/etc"
mkdir -p "$tmp/usr/local/bin"
mkdir -p "$tmp/etc/init.d"
mkdir -p "$tmp/root"

# Config de base
echo "$HOSTNAME" > "$tmp/etc/hostname"
echo "127.0.0.1    localhost $HOSTNAME" > "$tmp/etc/hosts"

# ICI : On injecterait tes scripts NecrOS (vanish, payload, install...)
# Pour l'exemple, on suppose que les sources sont dans /usr/local/bin sur la machine host
# cp -r /usr/local/bin/necros-* "$tmp/usr/local/bin/"

# Activer les services au boot du Live CD
mkdir -p "$tmp/etc/runlevels/default"
ln -s /etc/init.d/networking "$tmp/etc/runlevels/default/"

# Création de l'archive tar.gz (le calque)
tar -c -C "$tmp" . | gzip -9n > $1
EOF

chmod +x "$MKIMG_DIR/genapkovl-necros.sh"

# 4. Lancer la compilation de l'ISO
echo "[+] Forge de l'ISO en cours..."
# Cette commande est complexe, elle appelle le script officiel alpine-make-vm-image
# Note: C'est ici que ça devient technique. Pour un Vibe Coder, 
# la méthode la plus simple est souvent d'utiliser un Dockerfile.

echo "⚠️  NOTE : La compilation ISO nécessite un profil complet."
echo "Pour l'instant, le plus simple est de distribuer le script 'necro_install.sh'."
echo "Si tu veux vraiment l'ISO, il faut configurer 'mkimg' avec un profil custom."
