#!/bin/bash
# Печатает yes, если Bluetooth можно использовать: установлен демон bluetoothd (пакет bluez)
# и в системе есть адаптер. Иначе печатает no. Без пакета bluez вкладка Bluetooth бесполезна.

daemon=0
for f in /usr/lib/bluetooth/bluetoothd /usr/libexec/bluetooth/bluetoothd /usr/sbin/bluetoothd /usr/bin/bluetoothd; do
    [ -x "$f" ] && daemon=1
done

if [ $daemon -eq 1 ] && ls /sys/class/bluetooth 2>/dev/null | grep -q .; then
    echo yes
else
    echo no
fi
