#!/bin/bash
# Переносит поток приложения на другое устройство вывода.
# Использование: move-stream.sh <id узла PipeWire> <serial узла (можно пустой)> <имя устройства вывода>
# Коды выхода: 1 — не хватает аргументов, 2 — нет pactl (пакет libpulse), 3 — поток не найден.
id=$1
serial=$2
sink=$3

[ -z "$sink" ] && exit 1
command -v pactl >/dev/null 2>&1 || exit 2

# Номер потока в pactl не совпадает с id узла PipeWire, поэтому ищем поток по его свойствам.
# LC_ALL=C: иначе pactl переводит заголовки («Sink Input») на язык системы
find_index() {
    LC_ALL=C pactl list sink-inputs | awk -v key="$1" -v val="$2" '
        /^Sink Input #/ { idx = substr($3, 2) }
        $1 == key && $2 == "=" && $3 == "\"" val "\"" { print idx; exit }
    '
}

idx=""
[ -n "$serial" ] && idx=$(find_index object.serial "$serial")
[ -z "$idx" ] && [ -n "$id" ] && idx=$(find_index object.id "$id")
[ -z "$idx" ] && [ -n "$id" ] && idx=$(find_index node.id "$id")
[ -z "$idx" ] && exit 3

pactl move-sink-input "$idx" "$sink"
