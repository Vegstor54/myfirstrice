#!/bin/bash
# Печатает суммарные счётчики принятых и отправленных байт физических сетевых карт: "rx tx".
# Скорость считает SysState.qml по разнице между двумя опросами.
# Физические карты имеют каталог device (как в net-status.sh); lo, docker, veth, tun не считаются.

rx=0
tx=0
for d in /sys/class/net/*; do
    [ -e "$d/device" ] || continue
    r=$(cat "$d/statistics/rx_bytes" 2>/dev/null) || continue
    t=$(cat "$d/statistics/tx_bytes" 2>/dev/null) || continue
    rx=$((rx + r))
    tx=$((tx + t))
done
echo "$rx $tx"
