#!/bin/bash
# Печатает тип активного подключения: ethernet, wifi или none.
# Смотрит в /sys/class/net, поэтому не зависит от NetworkManager, iwd или networkd.
# Физические сетевые карты имеют каталог device; виртуальные (lo, docker, veth, tun) его не имеют.

wifi=0
eth=0
for d in /sys/class/net/*; do
    [ -e "$d/device" ] || continue
    [ "$(cat "$d/operstate" 2>/dev/null)" = up ] || continue
    if [ -d "$d/wireless" ]; then wifi=1; else eth=1; fi
done

if [ $eth -eq 1 ]; then echo ethernet
elif [ $wifi -eq 1 ]; then echo wifi
else echo none
fi
