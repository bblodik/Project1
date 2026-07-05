--[[
    Project1 - Key System (main.lua)
    После правильного ключа подгружает menu.lua.

    menu.lua теперь сам подгружает модули из папки Modules/ и
    Modules/Categories/ (тема, UI-хелперы, вкладки, настройки) —
    убедись, что эти файлы лежат в том же репозитории/ветке.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

------------------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------------------
local ValidKeys = {
    ["test"]  = true,
    ["test2"] = true,
    ["vip"]   = true,
}

-- ссылка на файл меню (замени, если у тебя другая ветка/репозиторий)
local MENU_URL = "https://raw.githubusercontent.com/bblodik/Project1/main/menu.lua"

-- ссылка на получение ключа (замени на свой linkvertise/ads сервис, когда будет)
local GETKEY_URL = "https://your-getkey-link.com"
local DISCORD_URL = "https://discord.gg/E6QRa9wv6f"

------------------------------------------------------------
-- УДАЛЯЕМ СТАРЫЙ ИНТЕРФЕЙС (если скрипт запускают повторно)
------------------------------------------------------------
if CoreGui:FindFirstChild("Project1_KeySystem") then
    CoreGui.Project1_KeySystem:Destroy()
end
if CoreGui:FindFirstChild("Project1_Main") then
    CoreGui.Project1_Main:Destroy()
end
if CoreGui:FindFirstChild("Project1_HUD") then
    CoreGui.Project1_HUD:Destroy()
end

------------------------------------------------------------
-- ЦВЕТОВАЯ ТЕМА (только для окна ключа — основная палитра теперь в Modules/Theme.lua)
------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(22, 22, 26),
    Secondary  = Color3.fromRGB(30, 30, 36),
    Elevated   = Color3.fromRGB(38, 38, 45),
    Stroke     = Color3.fromRGB(48, 48, 56),
    Accent     = Color3.fromRGB(114, 137, 255),
    AccentDark = Color3.fromRGB(90, 110, 220),
    Discord    = Color3.fromRGB(88, 101, 242),
    DiscordDark= Color3.fromRGB(70, 82, 200),
    Text       = Color3.fromRGB(235, 235, 240),
    SubText    = Color3.fromRGB(150, 150, 162),
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function squareOff(parent, color, height, fromBottom)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = color
    f.BorderSizePixel = 0
    f.ZIndex = 0
    f.Size = UDim2.new(1, 0, 0, height)
    f.Position = fromBottom and UDim2.new(0, 0, 1, -height) or UDim2.new(0, 0, 0, 0)
    f.Parent = parent
    return f
end

local function makeDraggable(frame, dragHandle)
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- пробуем открыть ссылку в браузере, если нельзя - копируем в буфер обмена
local function openLink(url, statusLabel, okText)
    local opened = false

    pcall(function()
        if typeof(setclipboard) == "function" then
            setclipboard(url)
            opened = true
        end
    end)

    if not opened then
        pcall(function()
            game:GetService("GuiService"):OpenBrowserWindow(url)
            opened = true
        end)
    end

    if statusLabel then
        if opened then
            statusLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
            statusLabel.Text = okText or "Ссылка скопирована в буфер обмена!"
        else
            statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
            statusLabel.Text = "Не удалось открыть ссылку: " .. url
        end
    end
end

------------------------------------------------------------
-- ===================== KEY SYSTEM UI =========================
------------------------------------------------------------
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "Project1_KeySystem"
KeyGui.ResetOnSpawn = false
KeyGui.IgnoreGuiInset = true
KeyGui.Parent = CoreGui

local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Size = UDim2.new(0, 340, 0, 236)
KeyFrame.Position = UDim2.new(0.5, -170, 0.5, -118)
KeyFrame.BackgroundColor3 = Theme.Background
KeyFrame.BorderSizePixel = 0
KeyFrame.Parent = KeyGui
corner(KeyFrame, 12)
stroke(KeyFrame, Theme.Stroke, 1)

local KeyTop = Instance.new("Frame")
KeyTop.Size = UDim2.new(1, 0, 0, 40)
KeyTop.BackgroundColor3 = Theme.Secondary
KeyTop.BorderSizePixel = 0
KeyTop.Parent = KeyFrame
corner(KeyTop, 12)
squareOff(KeyTop, Theme.Secondary, 12, true)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.BackgroundTransparency = 1
KeyTitle.Size = UDim2.new(1, -20, 1, 0)
KeyTitle.Position = UDim2.new(0, 15, 0, 0)
KeyTitle.Text = "Project1 — Key System"
KeyTitle.TextColor3 = Theme.Text
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 16
KeyTitle.TextXAlignment = Enum.TextXAlignment.Left
KeyTitle.Parent = KeyTop

local KeyDesc = Instance.new("TextLabel")
KeyDesc.BackgroundTransparency = 1
KeyDesc.Size = UDim2.new(1, -30, 0, 20)
KeyDesc.Position = UDim2.new(0, 15, 0, 50)
KeyDesc.Text = "Введи ключ, чтобы получить доступ"
KeyDesc.TextColor3 = Theme.SubText
KeyDesc.Font = Enum.Font.Gotham
KeyDesc.TextSize = 13
KeyDesc.TextXAlignment = Enum.TextXAlignment.Left
KeyDesc.Parent = KeyFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -30, 0, 38)
KeyBox.Position = UDim2.new(0, 15, 0, 78)
KeyBox.BackgroundColor3 = Theme.Secondary
KeyBox.BorderSizePixel = 0
KeyBox.Text = ""
KeyBox.PlaceholderText = "Введите ключ (test)"
KeyBox.TextColor3 = Theme.Text
KeyBox.PlaceholderColor3 = Theme.SubText
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = KeyFrame
corner(KeyBox, 8)
stroke(KeyBox, Theme.Stroke, 1)

local KeyStatus = Instance.new("TextLabel")
KeyStatus.BackgroundTransparency = 1
KeyStatus.Size = UDim2.new(1, -30, 0, 16)
KeyStatus.Position = UDim2.new(0, 15, 0, 118)
KeyStatus.Text = ""
KeyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
KeyStatus.Font = Enum.Font.Gotham
KeyStatus.TextSize = 12
KeyStatus.TextXAlignment = Enum.TextXAlignment.Left
KeyStatus.Parent = KeyFrame

-- ==== ряд: Get Key + Discord ====
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.5, -18, 0, 32)
GetKeyBtn.Position = UDim2.new(0, 15, 0, 140)
GetKeyBtn.BackgroundColor3 = Theme.Elevated
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = Theme.Text
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 13
GetKeyBtn.AutoButtonColor = false
GetKeyBtn.Parent = KeyFrame
corner(GetKeyBtn, 8)
stroke(GetKeyBtn, Theme.Stroke, 1)

local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0.5, -18, 0, 32)
DiscordBtn.Position = UDim2.new(0.5, 3, 0, 140)
DiscordBtn.BackgroundColor3 = Theme.Discord
DiscordBtn.BorderSizePixel = 0
DiscordBtn.Text = "Discord"
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.TextSize = 13
DiscordBtn.AutoButtonColor = false
DiscordBtn.Parent = KeyFrame
corner(DiscordBtn, 8)

GetKeyBtn.MouseEnter:Connect(function()
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Secondary}):Play()
end)
GetKeyBtn.MouseLeave:Connect(function()
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Elevated}):Play()
end)
DiscordBtn.MouseEnter:Connect(function()
    TweenService:Create(DiscordBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.DiscordDark}):Play()
end)
DiscordBtn.MouseLeave:Connect(function()
    TweenService:Create(DiscordBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Discord}):Play()
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    openLink(GETKEY_URL, KeyStatus, "Ссылка на получение ключа скопирована!")
end)
DiscordBtn.MouseButton1Click:Connect(function()
    openLink(DISCORD_URL, KeyStatus, "Ссылка на Discord скопирована!")
end)

-- ==== кнопка подтверждения ====
local SubmitBtn = Instance.new("TextButton")
SubmitBtn.Size = UDim2.new(1, -30, 0, 36)
SubmitBtn.Position = UDim2.new(0, 15, 0, 182)
SubmitBtn.BackgroundColor3 = Theme.Accent
SubmitBtn.BorderSizePixel = 0
SubmitBtn.Text = "Подтвердить"
SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitBtn.Font = Enum.Font.GothamBold
SubmitBtn.TextSize = 14
SubmitBtn.AutoButtonColor = false
SubmitBtn.Parent = KeyFrame
corner(SubmitBtn, 8)

SubmitBtn.MouseEnter:Connect(function()
    TweenService:Create(SubmitBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentDark}):Play()
end)
SubmitBtn.MouseLeave:Connect(function()
    TweenService:Create(SubmitBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
end)

makeDraggable(KeyFrame, KeyTop)

------------------------------------------------------------
-- ЛОГИКА ПРОВЕРКИ КЛЮЧА -> ПОДГРУЖАЕМ menu.lua
------------------------------------------------------------
local function tryKey()
    local input = KeyBox.Text

    if ValidKeys[input] then
        KeyGui:Destroy()

        local ok, err = pcall(function()
            local menuCode = game:HttpGet(MENU_URL)
            loadstring(menuCode)()
        end)

        if not ok then
            warn("Не удалось загрузить menu.lua: " .. tostring(err))
        end
    else
        KeyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
        KeyStatus.Text = "Неверный ключ!"
    end
end

SubmitBtn.MouseButton1Click:Connect(tryKey)
KeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        tryKey()
    end
end)
