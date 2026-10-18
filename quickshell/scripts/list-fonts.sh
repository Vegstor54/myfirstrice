#!/bin/bash
# Печатает JSON-массив установленных семейств шрифтов.
# Использование: list-fonts.sh ui|mono
#   ui   - все семейства
#   mono - только моноширинные (spacing=mono и dual, как у многих Nerd Font)

command -v fc-list >/dev/null 2>&1 || { echo "[]"; exit 0; }

# -f с шаблоном отдаёт имя как есть (обычный вывод fc-list экранирует "-" и ",")
fmt='%{family[0]}\n'

case $1 in
    mono) { fc-list -f "$fmt" :spacing=mono; fc-list -f "$fmt" :spacing=dual; } ;;
    ui)   fc-list -f "$fmt" : ;;
    *)    echo "[]"; exit 0 ;;
esac 2>/dev/null |
    grep -v '^[[:space:]]*$' |
    grep -v '^\.' |
    sort -fu |
    awk 'BEGIN { printf "[" }
         { gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "%s\"%s\"", (NR > 1 ? "," : ""), $0 }
         END { print "]" }'
