# NecrOS 💀

## "Resurrecting the Silicon Dead"

**Le Kali du 32-bits** — Un OS de pentest ultra-léger basé sur Alpine Linux, conçu pour faire revivre les vieilles machines et offrir un environnement de hacking complet sur du matériel limité.

---

## 🎯 Philosophie

NecrOS est né d'un constat simple : les distributions de sécurité modernes (Kali, Parrot, BlackArch) sont devenues des usines à gaz qui ne tournent plus sur du matériel ancien. NecrOS ramène le hacking à ses racines : léger, efficace, terminal-first.

**Caractéristiques :**
- ✅ Support x86 (32-bit), x86_64 et ARM64
- ✅ Fonctionne avec 256MB de RAM (512MB recommandé)
- ✅ Moins de 2GB d'espace disque pour l'installation de base
- ✅ Interface i3wm ultra-légère (pas de GNOME/KDE)
- ✅ Hardened by default (Alpine Linux)
- ✅ Outils modulaires via toolboxes

---

## 🚀 Installation

### Prérequis

- Machine cible (physique ou VM) avec :
  - CPU : x86, x86_64, ou ARM64
  - RAM : 256MB minimum, 512MB recommandé
  - Disque : 2GB minimum, 5GB recommandé
- ISO Alpine Linux "Standard" téléchargée depuis [alpinelinux.org](https://alpinelinux.org/downloads/)

### Étape 1 : Installer Alpine Linux

1. Booter sur l'ISO Alpine
2. Login : `root` (pas de mot de passe)
3. Lancer l'installation : `setup-alpine`
4. Suivre les instructions (mode "sys" pour installation sur disque)
5. Redémarrer

### Étape 2 : Installer NecrOS

```bash
# Télécharger le script
wget https://raw.githubusercontent.com/your-repo/necros/main/necro_install.sh

# Ou copier le script manuellement
vi necro_install.sh
# (coller le contenu)

# Rendre exécutable et lancer
chmod +x necro_install.sh
sh necro_install.sh
```

### Étape 3 : Premier lancement

```bash
# Lancer l'interface graphique
startx

# Raccourcis i3 de base
# Super+Enter    → Terminal
# Super+D        → Menu applications
# Super+Shift+Q  → Fermer fenêtre
# Super+1-9      → Changer de workspace
```

---

## 🛠️ Toolboxes

NecrOS utilise un système de toolboxes modulaires. Installez uniquement ce dont vous avez besoin :

```bash
# Lancer le gestionnaire de toolbox
necros-toolbox

# Ou installer directement une catégorie
necros-toolbox wifi      # WiFi/Radio Hacking
necros-toolbox web       # Web Pentest
necros-toolbox reverse   # Reverse Engineering
necros-toolbox blue      # Blue Team / Défense
necros-toolbox all       # Tout installer
```

### 📡 Toolbox WiFi/Radio

Outils pour l'audit de réseaux sans fil et radio.

**Outils inclus :**
- aircrack-ng, aireplay-ng, airodump-ng
- reaver, macchanger, hostapd
- rtl-sdr (Software Defined Radio)
- Bluetooth tools

**Commandes NecrOS :**
```bash
necros-monitor wlan0 start   # Activer mode monitor
necros-monitor wlan0 stop    # Désactiver mode monitor
necros-wifiscan              # Scanner les réseaux
necros-deauth                # Deauthentication (légal uniquement!)
```

### 🌐 Toolbox Web Pentest

Outils pour le test d'intrusion d'applications web.

**Outils inclus :**
- mitmproxy, proxychains, tor
- nikto, whatweb, sqlmap
- ffuf, wfuzz, gobuster, dirb
- hydra, john

**Commandes NecrOS :**
```bash
necros-webrecon https://target.com    # Reconnaissance rapide
necros-dirscan https://target.com     # Scan de répertoires
necros-sqli "http://target.com?id=1"  # Test SQL injection
necros-xss http://target.com param    # Test XSS
```

**Wordlists :** `/usr/share/wordlists/`

### 🔬 Toolbox Reverse Engineering

Outils pour l'analyse et la rétro-ingénierie de binaires.

**Outils inclus :**
- gdb (avec GEF), strace, ltrace
- radare2 (r2), objdump
- hexedit, xxd, hexyl
- binwalk, checksec
- pwntools, ROPgadget

**Commandes NecrOS :**
```bash
necros-bininfo ./binary           # Analyse rapide d'un binaire
necros-disasm ./binary main       # Désassembler la fonction main
necros-rop ./binary "pop rdi"     # Chercher des gadgets ROP
```

**Template pwntools :** `/usr/local/necros/re/pwn_template.py`

### 🛡️ Toolbox Blue Team

Outils de défense, monitoring et réponse aux incidents.

**Outils inclus :**
- suricata, fail2ban
- lynis, rkhunter, chkrootkit
- clamav, yara
- volatility3
- iftop, nethogs, goaccess

**Commandes NecrOS :**
```bash
necros-seccheck        # Check sécurité rapide
necros-bluewatch net   # Monitoring réseau live
necros-bluewatch logs  # Suivre les logs en temps réel
necros-audit           # Audit de sécurité complet
```

---

## ⌨️ Raccourcis i3

| Raccourci | Action |
|-----------|--------|
| `Super+Enter` | Ouvrir un terminal |
| `Super+D` | Menu applications (rofi) |
| `Super+Space` | Menu applications (dmenu) |
| `Super+Shift+Q` | Fermer la fenêtre active |
| `Super+H/J/K/L` | Navigation entre fenêtres |
| `Super+Shift+H/J/K/L` | Déplacer les fenêtres |
| `Super+1-9` | Changer de workspace |
| `Super+Shift+1-9` | Déplacer vers workspace |
| `Super+F` | Plein écran |
| `Super+V` | Split vertical |
| `Super+B` | Split horizontal |
| `Super+R` | Mode redimensionnement |
| `Super+Escape` | Verrouiller l'écran |
| `Super+Shift+E` | Quitter i3 |

---

## 🎨 Personnalisation

### Thème Terminal

Le thème par défaut est "The Necromancer" : vert néon sur noir profond. Pour modifier :

```bash
vim ~/.Xresources
# Modifier les couleurs
xrdb -merge ~/.Xresources
```

### Configuration i3

```bash
vim ~/.config/i3/config
# Après modification :
# Super+Shift+R pour recharger
```

### Aliases utiles

Les aliases sont dans `~/.zshrc` :

```bash
# Hacking
scan       # nmap -sV -sC
fastscan   # nmap -F
fullscan   # nmap -p- -sV -sC
listen     # nc -lvnp
serve      # python3 -m http.server
sniff      # tcpdump -i any -w
myip       # Affiche l'IP publique
localip    # Affiche l'IP locale
```

---

## 📁 Structure des fichiers

```
/usr/local/necros/
├── toolbox/          # Scripts d'installation des toolboxes
├── wifi/             # Scripts WiFi
├── web/              # Scripts Web pentest
├── re/               # Scripts et templates Reverse Engineering
└── blue/             # Scripts Blue Team et règles YARA

/usr/share/wordlists/ # Wordlists pour fuzzing et bruteforce

/root/
├── .config/i3/       # Configuration i3
├── .Xresources       # Configuration terminal
└── .zshrc            # Configuration shell
```

---

## 🔧 Dépannage

### Pas de réseau après installation

```bash
# Vérifier les interfaces
ip link

# Configurer l'interface
setup-interfaces

# Redémarrer le réseau
rc-service networking restart
```

### L'interface graphique ne se lance pas

```bash
# Vérifier Xorg
cat /var/log/Xorg.0.log | grep EE

# Réinstaller les drivers
apk add xf86-video-vesa  # Driver générique
```

### Problèmes de permissions

```bash
# Ajouter un utilisateur au groupe wheel
adduser monuser wheel

# Vérifier doas
cat /etc/doas.conf
# Doit contenir : permit persist :wheel
```

### Mode monitor WiFi ne fonctionne pas

```bash
# Vérifier que l'interface supporte le mode monitor
iw list | grep monitor

# Certaines cartes nécessitent des drivers spécifiques
# Chipsets recommandés : Atheros, Ralink
```

---

## ⚠️ Avertissement légal

NecrOS est un outil éducatif destiné aux professionnels de la sécurité informatique. L'utilisation des outils fournis sur des systèmes ou réseaux sans autorisation explicite est **illégale**.

**Utilisez NecrOS uniquement sur :**
- Vos propres systèmes
- Des environnements de lab
- Des systèmes pour lesquels vous avez une autorisation écrite

Les créateurs de NecrOS déclinent toute responsabilité pour une utilisation malveillante.

---

## 🤝 Contribuer

NecrOS est un projet communautaire. Contributions bienvenues :

- Signaler des bugs
- Proposer de nouveaux outils
- Améliorer la documentation
- Créer des scripts personnalisés

---

## 📜 Licence

NecrOS est distribué sous licence MIT. Les outils inclus conservent leurs licences respectives.

---

## 🏴‍☠️ Crédits

- **Base :** Alpine Linux Team
- **Inspiration :** Kali Linux, BlackArch, Parrot OS
- **Philosophie :** "Keep it simple, keep it light, keep it powerful"

---

*"Dans les cendres du silicium oublié, le Nécromancien trouve sa puissance."* 💀
