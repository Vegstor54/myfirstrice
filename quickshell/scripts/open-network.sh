#!/bin/bash
# Открывает программу управления сетью: берётся первая найденная.
# Код выхода 2: ничего подходящего не установлено.

here="$(dirname "$0")"

if command -v nm-connection-editor >/dev/null 2>&1; then
    exec nm-connection-editor
elif command -v impala >/dev/null 2>&1; then
    exec "$here/run-in-terminal.sh" impala
elif command -v nmtui >/dev/null 2>&1; then
    exec "$here/run-in-terminal.sh" nmtui
fi
exit 2
