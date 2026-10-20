#!/bin/bash
# Сопрягает устройство по адресу, делает его доверенным и подключает.
# Quickshell сам не умеет подтверждать сопряжение (у него нет агента BlueZ), поэтому на время
# сопряжения запускается bluetoothctl с агентом NoInputNoOutput: он подходит для колонок и наушников.
# Устройствам, которым нужен PIN или ввод пароля (клавиатуры), этого агента недостаточно.
# Код выхода 0: устройство сопряжено.

mac=$1
[ -z "$mac" ] && exit 1
command -v bluetoothctl >/dev/null 2>&1 || exit 2

{
    echo "agent NoInputNoOutput"
    echo "default-agent"
    sleep 1
    echo "pair $mac"
    # ждём сопряжения до 30 секунд
    for _ in $(seq 30); do
        sleep 1
        bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes" && break
    done
    echo "trust $mac"
    echo "connect $mac"
    sleep 5
    echo "quit"
} | bluetoothctl >/dev/null 2>&1

bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes"
