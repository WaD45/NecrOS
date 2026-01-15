#!/sbin/openrc-run
description="NecrOS Splash"
depend() { after localmount; before agetty; }
start() {
    clear
    echo -e "\033[1;32m"
    cat << 'EOF'
      NO SYSTEM IS SAFE.
          .
        .n                   .
  .   .dP                  dP
 4    qXb         .       dX
dX.    9Xb      .dXb    __
9XXb._       _.dXXXXb dXXXXbo.
 9XXXXXXXXXXXXXXXXXXXVXXXXXXXXOo.
  `9XXXXXXXXXXXXXXXXXXXXX'~   ~`OOO8b
    `9XXXXXXXXXXXP' `9XX'   DIE
EOF
    echo -e "\033[0;36m"
    echo "      Initializing NecrOS v0.3..."
    echo -e "\033[0m"
    sleep 2
}
