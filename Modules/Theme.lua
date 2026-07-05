--[[
    Project1 - Тема / Палитра (Modules/Theme.lua)

    Тут живут все цвета интерфейса:
    - Theme.Palettes    — готовые пресеты палитры (можно добавлять свои)
    - Theme.Current     — активная (текущая) палитра
    - Theme.reg(...)    — регистрирует UI-элемент, чтобы он красился автоматически
    - Theme.Apply()     — перекрашивает всё зарегистрированное
    - Theme.SetPalette(name) — переключает на готовый пресет
]]

local Theme = {}

-- ===================== ГОТОВЫЕ ПАЛИТРЫ =====================
-- Добавляй сюда новые палитры — они сразу появятся в Settings
Theme.Palettes = {
    {
        Name = "Indigo",
        Colors = {
            Background = Color3.fromRGB(22, 22, 26),
            Secondary  = Color3.fromRGB(30, 30, 36),
            Elevated   = Color3.fromRGB(38, 38, 45),
            Stroke     = Color3.fromRGB(48, 48, 56),
            Accent     = Color3.fromRGB(114, 137, 255),
            Text       = Color3.fromRGB(235, 235, 240),
            SubText    = Color3.fromRGB(150, 150, 162),
        },
    },
    {
        Name = "Изумруд",
        Colors = {
            Background = Color3.fromRGB(16, 24, 22),
            Secondary  = Color3.fromRGB(22, 32, 29),
            Elevated   = Color3.fromRGB(30, 42, 38),
            Stroke     = Color3.fromRGB(40, 56, 50),
            Accent     = Color3.fromRGB(80, 210, 150),
            Text       = Color3.fromRGB(230, 240, 235),
            SubText    = Color3.fromRGB(140, 165, 155),
        },
    },
    {
        Name = "Пламя",
        Colors = {
            Background = Color3.fromRGB(26, 20, 20),
            Secondary  = Color3.fromRGB(35, 27, 27),
            Elevated   = Color3.fromRGB(46, 35, 35),
            Stroke     = Color3.fromRGB(60, 45, 45),
            Accent     = Color3.fromRGB(240, 110, 80),
            Text       = Color3.fromRGB(240, 232, 230),
            SubText    = Color3.fromRGB(165, 150, 148),
        },
    },
    {
        Name = "Монохром",
        Colors = {
            Background = Color3.fromRGB(18, 18, 18),
            Secondary  = Color3.fromRGB(26, 26, 26),
            Elevated   = Color3.fromRGB(34, 34, 34),
            Stroke     = Color3.fromRGB(50, 50, 50),
            Accent     = Color3.fromRGB(230, 230, 230),
            Text       = Color3.fromRGB(240, 240, 240),
            SubText    = Color3.fromRGB(150, 150, 150),
        },
    },
    {
        Name = "Электро",
        Colors = {
            Background = Color3.fromRGB(14, 18, 26),
            Secondary  = Color3.fromRGB(19, 25, 36),
            Elevated   = Color3.fromRGB(26, 34, 48),
            Stroke     = Color3.fromRGB(36, 46, 64),
            Accent     = Color3.fromRGB(80, 200, 255),
            Text       = Color3.fromRGB(230, 240, 250),
            SubText    = Color3.fromRGB(140, 160, 180),
        },
    },
}

-- порядок и подписи для ручной настройки в Settings
Theme.KeysOrder = {
    {key = "Background", label = "Фон"},
    {key = "Secondary",   label = "Панели"},
    {key = "Elevated",    label = "Кнопки"},
    {key = "Stroke",      label = "Обводка"},
    {key = "Accent",      label = "Акцент"},
    {key = "Text",        label = "Текст"},
    {key = "SubText",     label = "Текст (второй план)"},
}

-- активная тема — копия первого пресета
Theme.Current = {}
for k, v in pairs(Theme.Palettes[1].Colors) do
    Theme.Current[k] = v
end

Theme.Registry = {}
Theme.RefreshCallbacks = {}

-- регистрирует свойство инстанса, чтобы оно перекрашивалось при смене темы
function Theme.reg(inst, prop, key)
    table.insert(Theme.Registry, {inst = inst, prop = prop, key = key})
    inst[prop] = Theme.Current[key]
    return inst
end

-- перекрашивает всё зарегистрированное + зовёт коллбеки перерисовки
function Theme.Apply()
    for _, e in ipairs(Theme.Registry) do
        pcall(function()
            e.inst[e.prop] = Theme.Current[e.key]
        end)
    end
    for _, cb in ipairs(Theme.RefreshCallbacks) do
        pcall(cb)
    end
end

-- переключает на готовый пресет по имени
function Theme.SetPalette(paletteName)
    for _, p in ipairs(Theme.Palettes) do
        if p.Name == paletteName then
            for k, v in pairs(p.Colors) do
                Theme.Current[k] = v
            end
            Theme.Apply()
            return true
        end
    end
    return false
end

-- регистрирует функцию, которая вызовется после каждого Theme.Apply()
-- (например, чтобы перерисовать активную вкладку)
function Theme.OnRefresh(cb)
    table.insert(Theme.RefreshCallbacks, cb)
end

return Theme
