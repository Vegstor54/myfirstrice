.pragma library

// Логика страницы «Дисплеи» (DisplaysTab): чистый JS без зависимостей от Quickshell.
//
// Монитор в модели: { name, desc, enabled, w, h, hz, x, y, scale, transform, modes: [{ w, h, hz }] }
// w, h — физическое разрешение, x, y — положение в логических координатах Hyprland
// (логический размер = физический / scale, при повороте на 90/270 ширина и высота меняются местами).

function round2(v) { return Math.round(v * 100) / 100 }

function sameHz(a, b) { return Math.abs(a - b) < 0.02 }

// "1920x1080@60.00Hz" -> { w, h, hz }
function parseMode(s) {
    const m = /^(\d+)x(\d+)@([\d.]+)/.exec(String(s))
    return m ? { w: parseInt(m[1]), h: parseInt(m[2]), hz: round2(parseFloat(m[3])) } : null
}

// Имя монитора, который m зеркалирует, или "". В hyprctl поле mirrorOf — id монитора или "none".
function mirrorSource(m, list) {
    const v = m.mirrorOf
    if (v === undefined || v === null || v === "none" || v === "" || v === -1) return ""
    for (let i = 0; i < list.length; i++) {
        if (list[i].name !== m.name && (String(list[i].id) === String(v) || list[i].name === v)) return list[i].name
    }
    return ""
}

// Из JSON `hyprctl monitors all -j` в модель страницы
function fromHyprctl(list) {
    const out = []
    for (let i = 0; i < list.length; i++) {
        const m = list[i]
        const modes = []
        const avail = m.availableModes || []
        for (let j = 0; j < avail.length; j++) {
            const p = parseMode(avail[j])
            if (p && !modes.some(q => q.w === p.w && q.h === p.h && sameHz(q.hz, p.hz))) modes.push(p)
        }
        let w = m.width || 0
        let h = m.height || 0
        let hz = round2(m.refreshRate || 0)
        if (w === 0 || h === 0) {
            // выключенный монитор: размер берём из предпочтительного режима (он первый в списке)
            if (modes.length > 0) { w = modes[0].w; h = modes[0].h; hz = modes[0].hz }
        } else if (!modes.some(q => q.w === w && q.h === h && sameHz(q.hz, hz))) {
            modes.push({ w: w, h: h, hz: hz })
        }
        out.push({
            name: m.name,
            desc: m.description || ((m.make || "") + " " + (m.model || "")).trim(),
            enabled: !m.disabled,
            w: w, h: h, hz: hz,
            x: m.x || 0, y: m.y || 0,
            scale: m.scale || 1,
            transform: m.transform || 0,
            mirror: m.disabled ? "" : mirrorSource(m, list),
            modes: modes
        })
    }
    // Зеркало стоит там же, где его источник; источник выключен или пропал — зеркала нет
    for (let i = 0; i < out.length; i++) {
        if (!out[i].mirror) continue
        const src = out.find(o => o.name === out[i].mirror)
        if (src && src.enabled && !src.mirror) { out[i].x = src.x; out[i].y = src.y }
        else out[i].mirror = ""
    }
    return out
}

// Логический размер монитора с учётом масштаба и поворота
function logicalSize(m) {
    const swap = (m.transform & 1) === 1
    const s = m.scale > 0 ? m.scale : 1
    return {
        w: Math.round((swap ? m.h : m.w) / s),
        h: Math.round((swap ? m.w : m.h) / s)
    }
}

// Монитор занимает место в раскладке: включён и не является зеркалом другого
function active(m) { return m.enabled && !m.mirror }

// Уникальные разрешения по убыванию площади
function resolutions(modes) {
    const seen = {}
    const out = []
    for (let i = 0; i < modes.length; i++) {
        const key = modes[i].w + "x" + modes[i].h
        if (!seen[key]) { seen[key] = true; out.push({ w: modes[i].w, h: modes[i].h }) }
    }
    out.sort((a, b) => b.w * b.h - a.w * a.h || b.w - a.w)
    return out
}

// Частоты, доступные для разрешения, по убыванию
function refreshes(modes, w, h) {
    return modes.filter(m => m.w === w && m.h === h).map(m => m.hz).sort((a, b) => b - a)
}

function closestHz(list, hz) {
    let best = list[0]
    for (let i = 0; i < list.length; i++)
        if (Math.abs(list[i] - hz) < Math.abs(best - hz)) best = list[i]
    return best
}

// 60 -> "60", 59.88 -> "59.88"
function fmtHz(hz) { return String(round2(hz)) }

function fmtScale(s) { return String(round2(s)) }

// Рамка вокруг включённых мониторов в логических координатах
function bounds(mons) {
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
    for (let i = 0; i < mons.length; i++) {
        const m = mons[i]
        if (!active(m)) continue
        const s = logicalSize(m)
        x0 = Math.min(x0, m.x); y0 = Math.min(y0, m.y)
        x1 = Math.max(x1, m.x + s.w); y1 = Math.max(y1, m.y + s.h)
    }
    if (x0 === Infinity) return { x: 0, y: 0, w: 0, h: 0 }
    return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
}

// Параметры превью: масштаб k и смещение (ox, oy) логических координат в пиксели области
// размером width x height. Вокруг мониторов оставляется поле в полмонитора, чтобы было куда тянуть.
function viewParams(mons, width, height) {
    const b = bounds(mons)
    if (b.w <= 0 || width <= 0 || height <= 0) return { k: 0.05, ox: 0, oy: 0 }
    let maxW = 0, maxH = 0
    for (let i = 0; i < mons.length; i++) {
        if (!active(mons[i])) continue
        const s = logicalSize(mons[i])
        maxW = Math.max(maxW, s.w); maxH = Math.max(maxH, s.h)
    }
    const padX = maxW / 2, padY = maxH / 2
    const W = b.w + 2 * padX, H = b.h + 2 * padY
    const k = Math.min(width / W, height / H)
    return {
        k: k,
        ox: (width - W * k) / 2 + (padX - b.x) * k,
        oy: (height - H * k) / 2 + (padY - b.y) * k
    }
}

// Пары включённых мониторов, которые перекрываются (касание краями не считается)
function overlapPairs(mons) {
    const res = []
    for (let i = 0; i < mons.length; i++) {
        for (let j = i + 1; j < mons.length; j++) {
            const a = mons[i], b = mons[j]
            if (!active(a) || !active(b)) continue
            const sa = logicalSize(a), sb = logicalSize(b)
            if (a.x < b.x + sb.w && b.x < a.x + sa.w && a.y < b.y + sb.h && b.y < a.y + sa.h)
                res.push([a.name, b.name])
        }
    }
    return res
}

// Притягивает монитор i, поставленный в (x, y), к краям остальных, если ближе thr
function snap(mons, i, x, y, thr) {
    const s = logicalSize(mons[i])
    let bx = x, by = y, dx = thr + 1, dy = thr + 1
    for (let j = 0; j < mons.length; j++) {
        if (j === i || !active(mons[j])) continue
        const o = mons[j]
        const os = logicalSize(o)
        const xs = [o.x + os.w, o.x - s.w, o.x, o.x + os.w - s.w]
        const ys = [o.y + os.h, o.y - s.h, o.y, o.y + os.h - s.h]
        for (let c = 0; c < 4; c++) {
            if (Math.abs(xs[c] - x) < dx) { dx = Math.abs(xs[c] - x); bx = xs[c] }
            if (Math.abs(ys[c] - y) < dy) { dy = Math.abs(ys[c] - y); by = ys[c] }
        }
    }
    return { x: dx <= thr ? bx : x, y: dy <= thr ? by : y }
}

// Монитор i изменил логический размер (режим, масштаб, поворот), old — размер до этого.
// Соседей справа и снизу сдвигаем, чтобы они не наползали и не появлялась щель.
function resized(mons, i, old) {
    const m = mons[i]
    if (!active(m)) return
    const s = logicalSize(m)
    const dw = s.w - old.w, dh = s.h - old.h
    for (let j = 0; j < mons.length; j++) {
        if (j === i || !active(mons[j])) continue
        const o = mons[j]
        const os = logicalSize(o)
        const vOverlap = o.y < m.y + old.h && m.y < o.y + os.h
        const hOverlap = o.x < m.x + old.w && m.x < o.x + os.w
        if (vOverlap && o.x >= m.x + old.w - 1) o.x += dw
        else if (hOverlap && o.y >= m.y + old.h - 1) o.y += dh
    }
}

// Включаемый монитор i ставим справа от остальных, верхним краем вровень с ними
function placeRight(mons, i) {
    let right = 0, top = Infinity
    for (let j = 0; j < mons.length; j++) {
        if (j === i || !active(mons[j])) continue
        right = Math.max(right, mons[j].x + logicalSize(mons[j]).w)
        top = Math.min(top, mons[j].y)
    }
    mons[i].x = right
    mons[i].y = top === Infinity ? 0 : top
}

// Копия, сдвинутая так, чтобы левый верхний угол всех включённых мониторов был в (0, 0)
function normalized(mons) {
    const b = bounds(mons)
    const out = mons.map(m => {
        const c = Object.assign({}, m)
        if (active(m)) { c.x = Math.round(m.x - b.x); c.y = Math.round(m.y - b.y) }
        return c
    })
    // Зеркало записываем с теми же координатами, что у источника
    for (let i = 0; i < out.length; i++) {
        if (!out[i].enabled || !out[i].mirror) continue
        const src = out.find(o => o.name === out[i].mirror)
        if (src) { out[i].x = src.x; out[i].y = src.y }
    }
    return out
}

// Текст hypr/conf/monitors.lua. primary — монитор, на который при старте ставится фокус и курсор.
function toLua(mons, primary) {
    const n = normalized(mons)
    const L = []
    L.push("------------------")
    L.push("---- MONITORS ----")
    L.push("------------------")
    L.push("")
    L.push("-- Файл переписывает панель quickshell (Displays), руками можно править,")
    L.push("-- но панель при применении запишет его заново.")
    L.push("-- Раскладку применяет kanshi: профиль в ~/.config/kanshi/config, панель пишет его тем же действием.")
    L.push("-- Этот файл — fallback, если kanshi не установлен или не запущен.")
    L.push("-- primary — монитор, на который при старте Hyprland ставятся фокус и курсор (см. autostart.lua).")
    L.push("-- See https://wiki.hypr.land/Configuring/Basics/Monitors/")
    L.push("")
    let primaryOk = false
    for (let i = 0; i < n.length; i++) {
        const m = n[i]
        const name = JSON.stringify(m.name)
        if (!m.enabled) {
            L.push("hl.monitor({ output = " + name + ", disabled = true })")
            L.push("")
            continue
        }
        if (m.name === primary && !m.mirror) primaryOk = true
        L.push("hl.monitor({")
        L.push("    output   = " + name + ",")
        L.push("    mode     = \"" + m.w + "x" + m.h + "@" + fmtHz(m.hz) + "\",")
        L.push("    position = \"" + m.x + "x" + m.y + "\",")
        L.push("    scale    = " + fmtScale(m.scale) + ",")
        if (m.transform) L.push("    transform = " + m.transform + ",")
        if (m.mirror) L.push("    mirror   = " + JSON.stringify(m.mirror) + ",")
        L.push("})")
        L.push("")
    }
    L.push("-- fallback для любых других мониторов")
    L.push("hl.monitor({")
    L.push("    output   = \"\",")
    L.push("    mode     = \"preferred\",")
    L.push("    position = \"auto\",")
    L.push("    scale    = \"auto\",")
    L.push("})")
    L.push("")
    L.push(primaryOk ? "return { primary = " + JSON.stringify(primary) + " }" : "return {}")
    return L.join("\n")
}

// ---- Профиль kanshi (~/.config/kanshi/config) ----

// Имя профиля, который пишет панель: оно же показывается в нижней строке страницы
const KANSHI_PROFILE = "auto-custom"

// Значение для kanshi transform: 0 — normal, 1/2/3 — повороты, 4–7 — с отражением
function kanshiTransform(t) {
    const names = ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
    return names[t & 7] ?? "normal"
}

// Имя выхода в кавычках, если в нём есть пробелы или служебные символы kanshi
function kanshiName(name) {
    return /^[\w.:+-]+$/.test(name) ? name : JSON.stringify(name)
}

// Текст ~/.config/kanshi/config для текущего набора мониторов.
// kanshi выбирает профиль, только когда число выходов в профиле равно числу подключённых,
// поэтому в профиль попадают все мониторы, а не только включённые.
// Зеркало kanshi не умеет: такой монитор включается без геометрии, её задаёт Hyprland (monitors.lua).
function toKanshi(mons, name) {
    const n = normalized(mons)
    const prof = name && name !== "" ? name : KANSHI_PROFILE
    const L = []
    L.push("# ~/.config/kanshi/config — файл создаёт панель quickshell (Displays -> «Применить»).")
    L.push("# Руками править можно, но панель перезапишет файл при следующем применении.")
    L.push("# Профиль описывает тот набор мониторов, который подключён сейчас:")
    L.push("# kanshi берёт профиль, только когда число выходов в нём равно числу подключённых.")
    L.push("# Раскладка продублирована в hypr/conf/monitors.lua — она остаётся fallback без kanshi.")
    L.push("")
    L.push("profile " + prof + " {")
    for (let i = 0; i < n.length; i++) {
        const m = n[i]
        if (!m.enabled) {
            L.push("\toutput " + kanshiName(m.name) + " disable")
            continue
        }
        if (m.mirror) {
            // Комментарий отдельной строкой: kanshi читает «#» только в начале токена
            L.push("\t# зеркало kanshi не умеет: геометрию зеркала задаёт Hyprland (monitors.lua)")
            L.push("\toutput " + kanshiName(m.name) + " enable")
            continue
        }
        let line = "\toutput " + kanshiName(m.name) + " enable"
            + " mode " + m.w + "x" + m.h + "@" + fmtHz(m.hz) + "Hz"
            + " position " + m.x + "," + m.y
            + " scale " + fmtScale(m.scale)
        if (m.transform) line += " transform " + kanshiTransform(m.transform)
        L.push(line)
    }
    L.push("}")
    return L.join("\n") + "\n"
}

// ---- Пресеты раскладки (ряд карточек «Только основной / Расширить / Зеркало / Кроме основного») ----

function isBuiltin(name) { return /^(eDP|LVDS|DSI)/i.test(String(name)) }

// Базовый монитор пресетов: встроенный экран ноутбука, иначе основной при старте, иначе первый включённый
function baseIndex(mons, primary) {
    let i = mons.findIndex(m => isBuiltin(m.name))
    if (i < 0) i = mons.findIndex(m => m.name === primary)
    if (i < 0) i = mons.findIndex(m => m.enabled)
    return i < 0 ? 0 : i
}

// Четыре пресета. На ноутбуке они называются как в Windows-стиле («Только ноутбук», «Только внешний»),
// на десктопе то же самое относительно основного монитора. Пока монитор один, пресеты недоступны.
function presetList(mons) {
    const laptop = mons.some(m => isBuiltin(m.name))
    const many = mons.length >= 2
    return [
        { id: "single", label: laptop ? "Только ноутбук" : "Только основной", ok: many },
        { id: "extend", label: "Расширить", ok: many },
        { id: "mirror", label: "Зеркало", ok: many },
        { id: "others", label: laptop ? "Только внешний" : "Кроме основного", ok: many }
    ]
}

// Ставит мониторы из списка индексов в ряд слева направо, верхним краем в 0
function arrangeRow(arr, idx) {
    let x = 0
    for (let k = 0; k < idx.length; k++) {
        const m = arr[idx[k]]
        m.enabled = true
        m.mirror = ""
        m.x = x
        m.y = 0
        x += logicalSize(m).w
    }
}

// Применяет пресет к копии списка мониторов (base — индекс базового монитора, см. baseIndex)
function applyPreset(mons, id, base) {
    const arr = mons.map(m => Object.assign({}, m))
    if (arr.length < 2 || base < 0 || base >= arr.length) return arr
    // порядок слева направо по текущему положению (у выключенных осталось прежнее), при равенстве по списку
    const order = arr.map((m, i) => i).sort((a, b) => arr[a].x !== arr[b].x ? arr[a].x - arr[b].x : a - b)
    const b = arr[base]
    if (id === "single") {
        for (let i = 0; i < arr.length; i++) { arr[i].mirror = ""; arr[i].enabled = i === base }
        b.x = 0; b.y = 0
    } else if (id === "extend") {
        arrangeRow(arr, order)
    } else if (id === "mirror") {
        arrangeRow(arr, [base])
        for (let i = 0; i < arr.length; i++) {
            if (i === base) continue
            arr[i].enabled = true
            arr[i].mirror = b.name
            arr[i].x = b.x
            arr[i].y = b.y
        }
    } else if (id === "others") {
        b.enabled = false
        b.mirror = ""
        arrangeRow(arr, order.filter(i => i !== base))
    }
    return arr
}

// Какой пресет соответствует текущему состоянию мониторов ("" — свои настройки)
function detectPreset(mons, base) {
    const n = mons.length
    if (n < 2 || base < 0 || base >= n) return ""
    const on = mons.filter(m => m.enabled)
    const b = mons[base]
    if (on.length === 1 && b.enabled) return "single"
    if (!b.enabled && on.length === n - 1 && on.every(m => !m.mirror)) return "others"
    if (b.enabled && on.length === n) {
        if (on.some(m => m.mirror)) return on.every(m => m.name === b.name || m.mirror === b.name) ? "mirror" : ""
        return "extend"
    }
    return ""
}
