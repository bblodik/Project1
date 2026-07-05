--[[
    Project1 - Настройки (Modules/Settings.lua)
    Готовые палитры + ручная настройка RGB + сохранение/загрузка конфига.
]]

local HttpService = game:GetService("HttpService")

local Settings = {}

local CONFIG_FILE = "Project1_Config.json"

local function fileIOAvailable()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function clampByte(n)
    n = tonumber(n)
    if not n then return nil end
    return math.clamp(math.floor(n), 0, 255)
end

-- ctx = {Page = ScrollingFrame, Theme = Theme, UI = UI}
function Settings.Build(ctx)
    local Page, Theme, UI = ctx.Page, ctx.Theme, ctx.UI
    local order = 1

    local Hint = Instance.new("TextLabel")
    Hint.BackgroundTransparency = 1
    Hint.Size = UDim2.new(1, 0, 0, 30)
    Hint.Text = "Выбери готовую палитру или настрой цвета вручную"
    Hint.Font = Enum.Font.Gotham
    Hint.TextSize = 12
    Hint.TextWrapped = true
    Hint.TextXAlignment = Enum.TextXAlignment.Left
    Hint.LayoutOrder = order
    Hint.Parent = Page
    Theme.reg(Hint, "TextColor3", "SubText")
    order += 1

    ------------------------------------------------------------
    -- ГОТОВЫЕ ПАЛИТРЫ
    ------------------------------------------------------------
    local PaletteTitle = Instance.new("TextLabel")
    PaletteTitle.BackgroundTransparency = 1
    PaletteTitle.Size = UDim2.new(1, 0, 0, 22)
    PaletteTitle.Text = "Готовые палитры"
    PaletteTitle.Font = Enum.Font.GothamBold
    PaletteTitle.TextSize = 13
    PaletteTitle.TextXAlignment = Enum.TextXAlignment.Left
    PaletteTitle.LayoutOrder = order
    PaletteTitle.Parent = Page
    Theme.reg(PaletteTitle, "TextColor3", "Text")
    order += 1

    local PaletteGrid = Instance.new("Frame")
    PaletteGrid.Size = UDim2.new(1, 0, 0, 44)
    PaletteGrid.BackgroundTransparency = 1
    PaletteGrid.LayoutOrder = order
    PaletteGrid.Parent = Page
    order += 1

    local GridLayout = Instance.new("UIListLayout")
    GridLayout.FillDirection = Enum.FillDirection.Horizontal
    GridLayout.Padding = UDim.new(0, 8)
    GridLayout.Parent = PaletteGrid

    for _, palette in ipairs(Theme.Palettes) do
        local Swatch = Instance.new("TextButton")
        Swatch.Size = UDim2.new(0, 74, 0, 44)
        Swatch.Text = ""
        Swatch.AutoButtonColor = false
        Swatch.BorderSizePixel = 0
        Swatch.BackgroundColor3 = palette.Colors.Accent
        Swatch.Parent = PaletteGrid
        UI.corner(Swatch, 8)

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -6, 1, 0)
        Label.Position = UDim2.new(0, 3, 0, 0)
        Label.Text = palette.Name
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 11
        Label.TextWrapped = true
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.Parent = Swatch

        Swatch.MouseButton1Click:Connect(function()
            Theme.SetPalette(palette.Name)
        end)
    end

    ------------------------------------------------------------
    -- РУЧНАЯ НАСТРОЙКА RGB
    ------------------------------------------------------------
    local ManualTitle = Instance.new("TextLabel")
    ManualTitle.BackgroundTransparency = 1
    ManualTitle.Size = UDim2.new(1, 0, 0, 22)
    ManualTitle.Text = "Ручная настройка"
    ManualTitle.Font = Enum.Font.GothamBold
    ManualTitle.TextSize = 13
    ManualTitle.TextXAlignment = Enum.TextXAlignment.Left
    ManualTitle.LayoutOrder = order
    ManualTitle.Parent = Page
    Theme.reg(ManualTitle, "TextColor3", "Text")
    order += 1

    local function createColorRow(label, key)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 40)
        Row.BackgroundTransparency = 1
        Row.LayoutOrder = order
        Row.Parent = Page
        order += 1

        local Swatch = Instance.new("Frame")
        Swatch.Size = UDim2.new(0, 26, 0, 26)
        Swatch.Position = UDim2.new(0, 0, 0.5, -13)
        Swatch.BorderSizePixel = 0
        Swatch.Parent = Row
        Theme.reg(Swatch, "BackgroundColor3", key)
        UI.corner(Swatch, 6)
        UI.stroke(Swatch, Theme, "Stroke", 1)

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(0, 130, 1, 0)
        Label.Position = UDim2.new(0, 36, 0, 0)
        Label.Text = label
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Row
        Theme.reg(Label, "TextColor3", "Text")

        local function makeBox(xOffset, placeholder)
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(0, 44, 0, 26)
            Box.Position = UDim2.new(0, xOffset, 0.5, -13)
            Box.PlaceholderText = placeholder
            Box.Text = ""
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 12
            Box.ClearTextOnFocus = false
            Box.Parent = Row
            Theme.reg(Box, "BackgroundColor3", "Elevated")
            Theme.reg(Box, "TextColor3", "Text")
            UI.corner(Box, 6)
            return Box
        end

        local RBox = makeBox(170, "R")
        local GBox = makeBox(218, "G")
        local BBox = makeBox(266, "B")

        local function applyColor()
            local c = Theme.Current[key]
            local r = clampByte(RBox.Text) or math.floor(c.R * 255)
            local g = clampByte(GBox.Text) or math.floor(c.G * 255)
            local b = clampByte(BBox.Text) or math.floor(c.B * 255)
            Theme.Current[key] = Color3.fromRGB(r, g, b)
            Theme.Apply()
        end

        RBox.FocusLost:Connect(applyColor)
        GBox.FocusLost:Connect(applyColor)
        BBox.FocusLost:Connect(applyColor)
    end

    for _, entry in ipairs(Theme.KeysOrder) do
        createColorRow(entry.label, entry.key)
    end

    ------------------------------------------------------------
    -- КОНФИГИ
    ------------------------------------------------------------
    local ConfigRow = Instance.new("Frame")
    ConfigRow.Size = UDim2.new(1, 0, 0, 36)
    ConfigRow.BackgroundTransparency = 1
    ConfigRow.LayoutOrder = order
    ConfigRow.Parent = Page
    order += 1

    local ConfigStatus = Instance.new("TextLabel")
    ConfigStatus.BackgroundTransparency = 1
    ConfigStatus.Size = UDim2.new(1, 0, 0, 18)
    ConfigStatus.Text = ""
    ConfigStatus.Font = Enum.Font.Gotham
    ConfigStatus.TextSize = 12
    ConfigStatus.TextXAlignment = Enum.TextXAlignment.Left
    ConfigStatus.LayoutOrder = order
    ConfigStatus.Parent = Page
    order += 1

    local function configBtn(parent, xOffset, text)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 110, 0, 32)
        Btn.Position = UDim2.new(0, xOffset, 0, 0)
        Btn.Text = text
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Btn.AutoButtonColor = false
        Btn.Parent = parent
        Theme.reg(Btn, "BackgroundColor3", "Elevated")
        Theme.reg(Btn, "TextColor3", "Text")
        UI.corner(Btn, 6)
        UI.stroke(Btn, Theme, "Stroke", 1)
        return Btn
    end

    local SaveBtn = configBtn(ConfigRow, 0, "Сохранить")
    local LoadBtn = configBtn(ConfigRow, 120, "Загрузить")
    local ResetBtn = configBtn(ConfigRow, 240, "Сброс")

    SaveBtn.MouseButton1Click:Connect(function()
        if not fileIOAvailable() then
            ConfigStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
            ConfigStatus.Text = "Файловые функции недоступны в этом экзекьюторе"
            return
        end
        local data = {}
        for _, entry in ipairs(Theme.KeysOrder) do
            local c = Theme.Current[entry.key]
            data[entry.key] = {math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)}
        end
        local ok = pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        end)
        ConfigStatus.TextColor3 = ok and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(255, 90, 90)
        ConfigStatus.Text = ok and "Конфиг сохранён!" or "Ошибка при сохранении"
    end)

    LoadBtn.MouseButton1Click:Connect(function()
        if not fileIOAvailable() or not isfile(CONFIG_FILE) then
            ConfigStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
            ConfigStatus.Text = "Сохранённый конфиг не найден"
            return
        end
        local ok = pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for key, rgb in pairs(decoded) do
                if Theme.Current[key] then
                    Theme.Current[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
                end
            end
        end)
        if ok then
            Theme.Apply()
            ConfigStatus.TextColor3 = Color3.fromRGB(120, 220, 140)
            ConfigStatus.Text = "Конфиг загружен!"
        else
            ConfigStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
            ConfigStatus.Text = "Ошибка при загрузке"
        end
    end)

    ResetBtn.MouseButton1Click:Connect(function()
        Theme.SetPalette(Theme.Palettes[1].Name)
        ConfigStatus.TextColor3 = Color3.fromRGB(120, 220, 140)
        ConfigStatus.Text = "Тема сброшена до стандартной"
    end)
end

return Settings
