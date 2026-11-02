#!/bin/bash
# Печатает одну строку «temp <милли-градусы>» с температурой процессора, или «temp -1», если датчик не найден.
# Сначала ищет датчик в /sys/class/hwmon (k10temp и zenpower у AMD, coretemp у Intel, cpu_thermal у ARM),
# затем в /sys/class/thermal (x86_pkg_temp). Если у датчика есть метка Tctl, Tdie или Package, берёт её,
# иначе temp1_input.

root=${CPU_TEMP_ROOT:-/sys/class}
t=""

for h in "$root"/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|zenpower|coretemp|cpu_thermal|cpu-thermal) ;;
        *) continue ;;
    esac
    for l in "$h"/temp*_label; do
        [ -f "$l" ] || continue
        case "$(cat "$l" 2>/dev/null)" in
            Tctl|Tdie|Package*) t=$(cat "${l%_label}_input" 2>/dev/null); break ;;
        esac
    done
    [ -z "$t" ] && t=$(cat "$h/temp1_input" 2>/dev/null)
    [ -n "$t" ] && break
done

if [ -z "$t" ]; then
    for z in "$root"/thermal/thermal_zone*; do
        case "$(cat "$z/type" 2>/dev/null)" in
            x86_pkg_temp|cpu*) t=$(cat "$z/temp" 2>/dev/null) ;;
        esac
        [ -n "$t" ] && break
    done
fi

case "$t" in
    ''|*[!0-9]*) t=-1 ;;
esac
echo "temp $t"
