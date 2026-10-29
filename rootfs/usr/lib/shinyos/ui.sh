# /usr/lib/shinyos/ui.sh — funções de interface das ferramentas da ShinyOS
# Uso: . /usr/lib/shinyos/ui.sh

ui_hi=$(printf '\033[1;35m')
ui_ok=$(printf '\033[1;32m')
ui_err=$(printf '\033[1;31m')
ui_dim=$(printf '\033[2m')
ui_b=$(printf '\033[1m')
ui_off=$(printf '\033[0m')

# Título de tela: limpa e mostra uma faixa
ui_title() {
    clear
    printf '\n  %s✦ %s%s\n' "$ui_hi" "$1" "$ui_off"
    printf '  %s%s%s\n\n' "$ui_dim" "────────────────────────────────────────────" "$ui_off"
}

ui_say()  { printf '  %s✦%s %s\n' "$ui_hi" "$ui_off" "$*"; }
ui_ok()   { printf '  %s✔%s %s\n' "$ui_ok" "$ui_off" "$*"; }
ui_warn() { printf '  %s!%s %s\n' "$ui_err" "$ui_off" "$*"; }
ui_step() { printf '\n  %s[%s]%s %s\n' "$ui_hi" "$1" "$ui_off" "$2"; }

# ui_ask "pergunta" [padrão] -> $REPLY
ui_ask() {
    if [ -n "${2:-}" ]; then
        printf '  %s?%s %s %s[%s]%s ' "$ui_hi" "$ui_off" "$1" "$ui_dim" "$2" "$ui_off"
    else
        printf '  %s?%s %s ' "$ui_hi" "$ui_off" "$1"
    fi
    read -r REPLY || REPLY=
    [ -n "$REPLY" ] || REPLY=${2:-}
}

# ui_yesno "pergunta" [s|n] -> retorna 0 para sim
ui_yesno() {
    def=${2:-s}
    while :; do
        if [ "$def" = s ]; then ui_ask "$1 (S/n)"; else ui_ask "$1 (s/N)"; fi
        case ${REPLY:-$def} in
            s|S|sim|Sim|SIM|y|Y) return 0 ;;
            n|N|não|nao|Não|NAO|NÃO) return 1 ;;
        esac
    done
}

# ui_menu "pergunta" "opção 1" "opção 2" ... -> $REPLY = número escolhido
ui_menu() {
    q=$1; shift
    i=1
    for o in "$@"; do
        printf '    %s%2d)%s %s\n' "$ui_hi" "$i" "$ui_off" "$o"
        i=$((i + 1))
    done
    echo
    while :; do
        ui_ask "$q"
        case $REPLY in
            ''|*[!0-9]*) ;;
            *) [ "$REPLY" -ge 1 ] && [ "$REPLY" -le $# ] && return 0 ;;
        esac
        ui_warn "Digite um número de 1 a $#."
    done
}

ui_pause() {
    printf '\n  %sAperte Enter para continuar...%s' "$ui_dim" "$ui_off"
    read -r _ || true
}

ui_need_root() {
    [ "$(id -u)" -eq 0 ] && return 0
    ui_warn "Isto precisa ser feito como root. Use: su -c '$*'"
    exit 1
}

# Fusos horários (strings POSIX, o BusyBox não usa zoneinfo)
UI_TZ_NAMES="Brasília (BRT, UTC-3)|Amazonas (AMT, UTC-4)|Acre (ACT, UTC-5)|Fernando de Noronha (UTC-2)|Portugal (WET/WEST)|UTC"
UI_TZ_VALUES="BRT3 AMT4 ACT5 FNT2 WET0WEST,M3.5.0/1,M10.5.0 UTC0"

UI_KEYMAP_NAMES="Português do Brasil (ABNT2)|Inglês EUA (us)|Português de Portugal|Espanhol|Alemão|Francês|Inglês Reino Unido"
UI_KEYMAP_VALUES="br-abnt2 us pt-latin1 es de fr uk"

# ui_pick_list "pergunta" "nome1|nome2" "valor1 valor2" -> $REPLY = valor
ui_pick_list() {
    q=$1 names=$2 values=$3
    old_ifs=$IFS; IFS='|'; set -- $names; IFS=$old_ifs
    ui_menu "$q" "$@"
    set -- $values
    eval REPLY=\${$REPLY}
}

# ui_rcconf_set <variável> <valor> [arquivo] — grava uma opção no rc.conf
ui_rcconf_set() {
    f=${3:-/etc/rc.conf}
    if grep -q "^$1=" "$f"; then
        sed -i "s|^$1=.*|$1=\"$2\"|" "$f"
    else
        echo "$1=\"$2\"" >> "$f"
    fi
}
