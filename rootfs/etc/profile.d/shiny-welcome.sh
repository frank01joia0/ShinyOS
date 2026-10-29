# Modo live: abre o menu de boas-vindas no primeiro login do tty1
if [ -e /etc/shinyos/live ] && [ -z "${SHINY_WELCOMED:-}" ] && [ "$(tty)" = /dev/tty1 ]; then
    export SHINY_WELCOMED=1
    shiny
fi
