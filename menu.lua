--[[
    Project1 - Main Menu + HUD (menu.lua)
    Подгружается из main.lua после ввода правильного ключа
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("Project1_Main") then
    CoreGui.Project1_Main:Destroy()
end
if CoreGui:FindFirstChild("Project1_HUD") then
    CoreGui.Project1_HUD:Destroy()
end

------------------------------------------------------------
-- ЦВЕТОВАЯ ТЕМА (можно менять из вкладки Settings)
------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(22, 22, 26),
    Secondary  = Color3.fromRGB(30, 30, 36),
    Elevated   = Color3.fromRGB(38, 38, 45),
    Stroke     = Color3.fromRGB(48, 48, 56),
    Accent     = Color3.fromRGB(114, 137, 255),
    Text       = Color3.fromRGB(235, 235, 240),
    SubText    = Color3.fromRGB(150, 150, 162),
}

-- порядок и подписи для вкладки Settings
local ThemeKeysOrder = {
    {key = "Background", label = "Фон"},
    {key = "Secondary",   label = "Панели"},
    {key = "Elevated",    label = "Кнопки"},
    {key = "Stroke",      label = "Обводка"},
    {key = "Accent",      label = "Акцент"},
    {key = "Text",        label = "Текст"},
    {key = "SubText",     label = "Текст (второй план)"},
}

------------------------------------------------------------
-- РЕЕСТР ТЕМЫ: любой элемент, зарегистрированный через reg(),
-- будет автоматически перекрашен при изменении цвета в Settings
------------------------------------------------------------
local ThemeRegistry = {}

local function reg(inst, prop, key)
    table.insert(ThemeRegistry, {inst = inst, prop = prop, key = key})
    inst[prop] = Theme[key]
    return inst
end

local RefreshCallbacks = {} -- функции, которые нужно вызвать после смены темы (например перерисовка активной вкладки)

local function ApplyTheme()
    for _, e in ipairs(ThemeRegistry) do
        pcall(function()
            e.inst[e.prop] = Theme[e.key]
        end)
    end
    for _, cb in ipairs(RefreshCallbacks) do
        pcall(cb)
    end
end

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, key, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Parent = parent
    reg(s, "Color", key or "Stroke")
    return s
end

local function squareOff(parent, key, height, fromBottom)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.ZIndex = 0
    f.Size = UDim2.new(1, 0, 0, height)
    f.Position = fromBottom and UDim2.new(0, 0, 1, -height) or UDim2.new(0, 0, 0, 0)
    f.Parent = parent
    reg(f, "BackgroundColor3", key)
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

------------------------------------------------------------
-- СИСТЕМА БИНДОВ (список того, что забинжено, показывается в HUD)
------------------------------------------------------------
local BindsList = {
    {name = "Открыть/закрыть меню", key = "Insert"},
}

-- эта функция публичная, чтобы функции на вкладках AAA/Visuals/MISC
-- могли сами регистрировать свои бинды в будущем
local BindsUpdatedCallback = nil
_G.Project1_AddBind = function(name, key)
    table.insert(BindsList, {name = name, key = key})
    if BindsUpdatedCallback then
        pcall(BindsUpdatedCallback)
    end
end

------------------------------------------------------------
-- СИСТЕМА КОНФИГОВ (сохранение/загрузка темы через файлы экзекьютора)
------------------------------------------------------------
local CONFIG_FILE = "Project1_Config.json"

local function fileIOAvailable()
    return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function saveConfig(statusLabel)
    if not fileIOAvailable() then
        if statusLabel then
            statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
            statusLabel.Text = "Файловые функции недоступны в этом экзекьюторе"
        end
        return
    end

    local data = {}
    for _, entry in ipairs(ThemeKeysOrder) do
        local c = Theme[entry.key]
        data[entry.key] = {math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)}
    end

    local ok = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(data))
    end)

    if statusLabel then
        if ok then
            statusLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
            statusLabel.Text = "Конфиг сохранён!"
        else
            statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
            statusLabel.Text = "Ошибка при сохранении"
        end
    end
end

local function loadConfig(statusLabel)
    if not fileIOAvailable() or not isfile(CONFIG_FILE) then
        if statusLabel then
            statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
            statusLabel.Text = "Сохранённый конфиг не найден"
        end
        return
    end

    local ok = pcall(function()
        local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for key, rgb in pairs(decoded) do
            if Theme[key] then
                Theme[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            end
        end
    end)

    if ok then
        ApplyTheme()
        if statusLabel then
            statusLabel.TextColor3 = Color3.fromRGB(120, 220, 140)
            statusLabel.Text = "Конфиг загружен!"
        end
    elseif statusLabel then
        statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        statusLabel.Text = "Ошибка при загрузке"
    end
end

------------------------------------------------------------
-- ===================== HUD =========================
------------------------------------------------------------
local function buildHUD()
    local HUDGui = Instance.new("ScreenGui")
    HUDGui.Name = "Project1_HUD"
    HUDGui.ResetOnSpawn = false
    HUDGui.IgnoreGuiInset = true
    HUDGui.Enabled = true -- ХУД включен всегда по умолчанию
    HUDGui.Parent = CoreGui

    ------------------------------------------------------------
    -- ИНФО-ПАНЕЛЬ (UOLO / USER / скорость)
    ------------------------------------------------------------
    local InfoPanel = Instance.new("Frame")
    InfoPanel.Name = "InfoPanel"
    InfoPanel.Size = UDim2.new(0, 190, 0, 106)
    InfoPanel.Position = UDim2.new(0, 20, 0, 20)
    InfoPanel.BorderSizePixel = 0
    InfoPanel.Parent = HUDGui
    reg(InfoPanel, "BackgroundColor3", "Background")
    corner(InfoPanel, 10)
    stroke(InfoPanel, "Stroke", 1)

    local InfoHandle = Instance.new("Frame")
    InfoHandle.Size = UDim2.new(1, 0, 0, 26)
    InfoHandle.BorderSizePixel = 0
    InfoHandle.Parent = InfoPanel
    reg(InfoHandle, "BackgroundColor3", "Secondary")
    corner(InfoHandle, 10)
    squareOff(InfoHandle, "Secondary", 10, true)

    local InfoTitle = Instance.new("TextLabel")
    InfoTitle.BackgroundTransparency = 1
    InfoTitle.Size = UDim2.new(1, -16, 1, 0)
    InfoTitle.Position = UDim2.new(0, 10, 0, 0)
    InfoTitle.Text = "Project1 Info"
    InfoTitle.Font = Enum.Font.GothamBold
    InfoTitle.TextSize = 13
    InfoTitle.TextXAlignment = Enum.TextXAlignment.Left
    InfoTitle.Parent = InfoHandle
    reg(InfoTitle, "TextColor3", "Text")

    local function infoRow(order, labelText)
        local row = Instance.new("TextLabel")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -20, 0, 20)
        row.Position = UDim2.new(0, 10, 0, 26 + (order * 20))
        row.Font = Enum.Font.Gotham
        row.TextSize = 13
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Text = labelText
        row.Parent = InfoPanel
        reg(row, "TextColor3", "SubText")
        return row
    end

    -- UOLO — отдельный показатель-заглушка, подключи сюда свою метрику
    local UoloRow = infoRow(0, "UOLO: --")
    local UserRow = infoRow(1, "USER: " .. LocalPlayer.Name)
    local SpeedRow = infoRow(2, "Скорость: --")

    makeDraggable(InfoPanel, InfoHandle)

    -- обновление USER / скорости
    local function updateInfo()
        UserRow.Text = "USER: " .. LocalPlayer.Name
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            SpeedRow.Text = "Скорость: " .. math.floor(humanoid.WalkSpeed)
        else
            SpeedRow.Text = "Скорость: --"
        end
    end

    ------------------------------------------------------------
    -- РАДАР
    ------------------------------------------------------------
    local RADAR_SIZE = 160
    local RADAR_RANGE = 150 -- дальность радара в студах

    local RadarPanel = Instance.new("Frame")
    RadarPanel.Name = "RadarPanel"
    RadarPanel.Size = UDim2.new(0, RADAR_SIZE, 0, RADAR_SIZE + 26)
    RadarPanel.Position = UDim2.new(1, -RADAR_SIZE - 20, 0, 20)
    RadarPanel.BorderSizePixel = 0
    RadarPanel.Parent = HUDGui
    reg(RadarPanel, "BackgroundColor3", "Background")
    corner(RadarPanel, 10)
    stroke(RadarPanel, "Stroke", 1)

    local RadarHandle = Instance.new("Frame")
    RadarHandle.Size = UDim2.new(1, 0, 0, 26)
    RadarHandle.BorderSizePixel = 0
    RadarHandle.Parent = RadarPanel
    reg(RadarHandle, "BackgroundColor3", "Secondary")
    corner(RadarHandle, 10)
    squareOff(RadarHandle, "Secondary", 10, true)

    local RadarTitle = Instance.new("TextLabel")
    RadarTitle.BackgroundTransparency = 1
    RadarTitle.Size = UDim2.new(1, -16, 1, 0)
    RadarTitle.Position = UDim2.new(0, 10, 0, 0)
    RadarTitle.Text = "Radar"
    RadarTitle.Font = Enum.Font.GothamBold
    RadarTitle.TextSize = 13
    RadarTitle.TextXAlignment = Enum.TextXAlignment.Left
    RadarTitle.Parent = RadarHandle
    reg(RadarTitle, "TextColor3", "Text")

    local RadarSurface = Instance.new("Frame")
    RadarSurface.Name = "RadarSurface"
    RadarSurface.Size = UDim2.new(1, -20, 1, -36)
    RadarSurface.Position = UDim2.new(0, 10, 0, 30)
    RadarSurface.ClipsDescendants = true
    RadarSurface.BorderSizePixel = 0
    RadarSurface.Parent = RadarPanel
    reg(RadarSurface, "BackgroundColor3", "Secondary")
    corner(RadarSurface, 8)

    -- центр (сам игрок)
    local CenterDot = Instance.new("Frame")
    CenterDot.Size = UDim2.new(0, 8, 0, 8)
    CenterDot.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterDot.BorderSizePixel = 0
    CenterDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CenterDot.Parent = RadarSurface
    corner(CenterDot, 4)

    makeDraggable(RadarPanel, RadarHandle)

    local radarDots = {} -- [player] = Frame

    local function updateRadar()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local surfaceSize = RadarSurface.AbsoluteSize
        local radius = math.min(surfaceSize.X, surfaceSize.Y) / 2

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if root then
                    local dx = root.Position.X - myRoot.Position.X
                    local dz = root.Position.Z - myRoot.Position.Z

                    local scaledX = (dx / RADAR_RANGE) * radius
                    local scaledY = (dz / RADAR_RANGE) * radius

                    -- обрезаем по краю радара
                    local dist = math.sqrt(scaledX ^ 2 + scaledY ^ 2)
                    if dist > radius - 4 then
                        local ratio = (radius - 4) / dist
                        scaledX = scaledX * ratio
                        scaledY = scaledY * ratio
                    end

                    local dot = radarDots[plr]
                    if not dot then
                        dot = Instance.new("Frame")
                        dot.Size = UDim2.new(0, 6, 0, 6)
                        dot.AnchorPoint = Vector2.new(0.5, 0.5)
                        dot.BorderSizePixel = 0
                        dot.Parent = RadarSurface
                        corner(dot, 3)
                        reg(dot, "BackgroundColor3", "Accent")
                        radarDots[plr] = dot
                    end

                    dot.Position = UDim2.new(0.5, scaledX, 0.5, scaledY)
                else
                    if radarDots[plr] then
                        radarDots[plr]:Destroy()
                        radarDots[plr] = nil
                    end
                end
            end
        end

        -- чистим дотки игроков, которые вышли
        for plr, dot in pairs(radarDots) do
            if not plr.Parent then
                dot:Destroy()
                radarDots[plr] = nil
            end
        end
    end

    ------------------------------------------------------------
    -- BINDS панель
    ------------------------------------------------------------
    local BindsPanel = Instance.new("Frame")
    BindsPanel.Name = "BindsPanel"
    BindsPanel.Size = UDim2.new(0, 190, 0, 26 + (#BindsList * 20) + 10)
    BindsPanel.Position = UDim2.new(0, 20, 1, -(26 + (#BindsList * 20) + 10) - 20)
    BindsPanel.BorderSizePixel = 0
    BindsPanel.Parent = HUDGui
    reg(BindsPanel, "BackgroundColor3", "Background")
    corner(BindsPanel, 10)
    stroke(BindsPanel, "Stroke", 1)

    local BindsHandle = Instance.new("Frame")
    BindsHandle.Size = UDim2.new(1, 0, 0, 26)
    BindsHandle.BorderSizePixel = 0
    BindsHandle.Parent = BindsPanel
    reg(BindsHandle, "BackgroundColor3", "Secondary")
    corner(BindsHandle, 10)
    squareOff(BindsHandle, "Secondary", 10, true)

    local BindsTitle = Instance.new("TextLabel")
    BindsTitle.BackgroundTransparency = 1
    BindsTitle.Size = UDim2.new(1, -16, 1, 0)
    BindsTitle.Position = UDim2.new(0, 10, 0, 0)
    BindsTitle.Text = "Binds"
    BindsTitle.Font = Enum.Font.GothamBold
    BindsTitle.TextSize = 13
    BindsTitle.TextXAlignment = Enum.TextXAlignment.Left
    BindsTitle.Parent = BindsHandle
    reg(BindsTitle, "TextColor3", "Text")

    local BindsListFrame = Instance.new("Frame")
    BindsListFrame.Name = "BindsListFrame"
    BindsListFrame.Size = UDim2.new(1, -20, 1, -36)
    BindsListFrame.Position = UDim2.new(0, 10, 0, 30)
    BindsListFrame.BackgroundTransparency = 1
    BindsListFrame.Parent = BindsPanel

    local BindsLayout = Instance.new("UIListLayout")
    BindsLayout.Padding = UDim.new(0, 2)
    BindsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BindsLayout.Parent = BindsListFrame

    makeDraggable(BindsPanel, BindsHandle)

    local function rebuildBinds()
        for _, child in ipairs(BindsListFrame:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        for i, bind in ipairs(BindsList) do
            local row = Instance.new("TextLabel")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 18)
            row.Font = Enum.Font.Gotham
            row.TextSize = 12
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.Text = bind.name .. "  —  [" .. bind.key .. "]"
            row.LayoutOrder = i
            row.Parent = BindsListFrame
            reg(row, "TextColor3", "SubText")
        end

        BindsPanel.Size = UDim2.new(0, 190, 0, 26 + (#BindsList * 20) + 10)
    end

    rebuildBinds()
    BindsUpdatedCallback = rebuildBinds

    ------------------------------------------------------------
    -- ЦИКЛ ОБНОВЛЕНИЯ
    ------------------------------------------------------------
    local lastUpdate = 0
    RunService.Heartbeat:Connect(function(dt)
        lastUpdate += dt
        if lastUpdate >= 0.1 then -- обновляем 10 раз в секунду, для производительности
            lastUpdate = 0
            updateInfo()
            updateRadar()
        end
    end)

    return HUDGui
end

------------------------------------------------------------
-- ===================== MAIN MENU ===========================
------------------------------------------------------------
local function buildMainMenu(HUDGui)

    local MainGui = Instance.new("ScreenGui")
    MainGui.Name = "Project1_Main"
    MainGui.ResetOnSpawn = false
    MainGui.IgnoreGuiInset = true
    MainGui.Enabled = true
    MainGui.Parent = CoreGui

    local SIDEBAR_WIDTH = 150
    local TOPBAR_HEIGHT = 44

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 580, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -290, 0.5, -190)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = MainGui
    reg(MainFrame, "BackgroundColor3", "Background")
    corner(MainFrame, 12)
    stroke(MainFrame, "Stroke", 1)

    -- ==== верхняя панель ====
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    reg(TopBar, "BackgroundColor3", "Secondary")
    corner(TopBar, 12)
    squareOff(TopBar, "Secondary", 12, true)

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Text = "Project1"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar
    reg(Title, "TextColor3", "Text")

    local SubTitle = Instance.new("TextLabel")
    SubTitle.BackgroundTransparency = 1
    SubTitle.Size = UDim2.new(0, 170, 1, 0)
    SubTitle.Position = UDim2.new(1, -235, 0, 0)
    SubTitle.Text = "INSERT — открыть/закрыть"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 12
    SubTitle.TextXAlignment = Enum.TextXAlignment.Right
    SubTitle.Parent = TopBar
    reg(SubTitle, "TextColor3", "SubText")

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.AutoButtonColor = false
    CloseBtn.ZIndex = 2
    CloseBtn.Parent = TopBar
    reg(CloseBtn, "BackgroundColor3", "Elevated")
    reg(CloseBtn, "TextColor3", "Text")
    corner(CloseBtn, 6)

    CloseBtn.MouseButton1Click:Connect(function()
        MainGui.Enabled = false
    end)

    -- ==== БОКОВАЯ ПАНЕЛЬ ====
    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -TOPBAR_HEIGHT)
    SideBar.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
    SideBar.BorderSizePixel = 0
    SideBar.Parent = MainFrame
    reg(SideBar, "BackgroundColor3", "Secondary")

    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.Size = UDim2.new(1, -20, 1, -110)
    TabsContainer.Position = UDim2.new(0, 10, 0, 10)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Parent = SideBar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 6)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabsContainer

    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 10, 1, -108)
    Divider.BorderSizePixel = 0
    Divider.Parent = SideBar
    reg(Divider, "BackgroundColor3", "Stroke")

    local ModeLabel = Instance.new("TextLabel")
    ModeLabel.BackgroundTransparency = 1
    ModeLabel.Size = UDim2.new(1, -20, 0, 16)
    ModeLabel.Position = UDim2.new(0, 10, 1, -98)
    ModeLabel.Text = "Mode ID: 0001"
    ModeLabel.Font = Enum.Font.Gotham
    ModeLabel.TextSize = 12
    ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    ModeLabel.Parent = SideBar
    reg(ModeLabel, "TextColor3", "SubText")

    local ProfileContainer = Instance.new("Frame")
    ProfileContainer.Name = "ProfileContainer"
    ProfileContainer.Size = UDim2.new(1, -20, 0, 70)
    ProfileContainer.Position = UDim2.new(0, 10, 1, -80)
    ProfileContainer.BorderSizePixel = 0
    ProfileContainer.Parent = SideBar
    reg(ProfileContainer, "BackgroundColor3", "Elevated")
    corner(ProfileContainer, 8)
    stroke(ProfileContainer, "Stroke", 1)

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.new(0, 44, 0, 44)
    AvatarImage.Position = UDim2.new(0, 8, 0.5, -22)
    AvatarImage.Parent = ProfileContainer
    reg(AvatarImage, "BackgroundColor3", "Secondary")
    corner(AvatarImage, 22)

    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and content then
            AvatarImage.Image = content
        end
    end)

    local UserNameLabel = Instance.new("TextLabel")
    UserNameLabel.BackgroundTransparency = 1
    UserNameLabel.Size = UDim2.new(1, -60, 0, 18)
    UserNameLabel.Position = UDim2.new(0, 58, 0, 12)
    UserNameLabel.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    UserNameLabel.Font = Enum.Font.GothamBold
    UserNameLabel.TextSize = 13
    UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UserNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UserNameLabel.Parent = ProfileContainer
    reg(UserNameLabel, "TextColor3", "Text")

    local UIDLabel = Instance.new("TextLabel")
    UIDLabel.BackgroundTransparency = 1
    UIDLabel.Size = UDim2.new(1, -60, 0, 16)
    UIDLabel.Position = UDim2.new(0, 58, 0, 32)
    UIDLabel.Text = "UID: 1"
    UIDLabel.Font = Enum.Font.Gotham
    UIDLabel.TextSize = 12
    UIDLabel.TextXAlignment = Enum.TextXAlignment.Left
    UIDLabel.Parent = ProfileContainer
    reg(UIDLabel, "TextColor3", "SubText")

    -- ==== контейнер контента ====
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -TOPBAR_HEIGHT)
    ContentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, TOPBAR_HEIGHT)
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = MainFrame
    reg(ContentArea, "BackgroundColor3", "Background")

    local tabNames = {"AAA", "Visuals", "MISC", "Settings"}
    local pages = {}
    local buttons = {}
    local currentTab = "AAA"

    local function selectTab(name)
        currentTab = name
        for tabName, page in pairs(pages) do
            page.Visible = (tabName == name)
        end
        for tabName, btn in pairs(buttons) do
            if tabName == name then
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Accent}):Play()
                btn.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Elevated}):Play()
                btn.TextLabel.TextColor3 = Theme.SubText
            end
        end
    end
    table.insert(RefreshCallbacks, function() selectTab(currentTab) end)

    for i, name in ipairs(tabNames) do
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.LayoutOrder = i
        TabBtn.Parent = TabsContainer
        TabBtn.BackgroundColor3 = Theme.Elevated
        corner(TabBtn, 8)

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TextLabel"
        TabLabel.BackgroundTransparency = 1
        TabLabel.Size = UDim2.new(1, -10, 1, 0)
        TabLabel.Position = UDim2.new(0, 10, 0, 0)
        TabLabel.Text = name
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextSize = 14
        TabLabel.TextColor3 = Theme.SubText
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabBtn

        buttons[name] = TabBtn

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, -20, 1, -20)
        Page.Position = UDim2.new(0, 10, 0, 10)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 4
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea
        reg(Page, "ScrollBarImageColor3", "Accent")

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local SectionTitle = Instance.new("TextLabel")
        SectionTitle.BackgroundTransparency = 1
        SectionTitle.Size = UDim2.new(1, 0, 0, 26)
        SectionTitle.Text = "Категория: " .. name
        SectionTitle.Font = Enum.Font.GothamBold
        SectionTitle.TextSize = 16
        SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        SectionTitle.LayoutOrder = 1
        SectionTitle.Parent = Page
        reg(SectionTitle, "TextColor3", "Text")

        if name ~= "Settings" then
            local ExampleBtn = Instance.new("TextButton")
            ExampleBtn.Size = UDim2.new(1, 0, 0, 34)
            ExampleBtn.Text = "Пример кнопки (" .. name .. ")"
            ExampleBtn.Font = Enum.Font.Gotham
            ExampleBtn.TextSize = 13
            ExampleBtn.AutoButtonColor = false
            ExampleBtn.LayoutOrder = 2
            ExampleBtn.Parent = Page
            reg(ExampleBtn, "BackgroundColor3", "Elevated")
            reg(ExampleBtn, "TextColor3", "Text")
            corner(ExampleBtn, 6)
            stroke(ExampleBtn, "Stroke", 1)

            ExampleBtn.MouseButton1Click:Connect(function()
                print("Нажата кнопка на вкладке " .. name)
            end)
        end

        pages[name] = Page

        TabBtn.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
    end

    ------------------------------------------------------------
    -- ===================== SETTINGS TAB ===========================
    ------------------------------------------------------------
    local SettingsPage = pages["Settings"]

    local ColorsHint = Instance.new("TextLabel")
    ColorsHint.BackgroundTransparency = 1
    ColorsHint.Size = UDim2.new(1, 0, 0, 30)
    ColorsHint.Text = "Полностью настраиваемый дизайн — меняй любой цвет интерфейса"
    ColorsHint.Font = Enum.Font.Gotham
    ColorsHint.TextSize = 12
    ColorsHint.TextWrapped = true
    ColorsHint.TextXAlignment = Enum.TextXAlignment.Left
    ColorsHint.LayoutOrder = 2
    ColorsHint.Parent = SettingsPage
    reg(ColorsHint, "TextColor3", "SubText")

    local function clampByte(n)
        n = tonumber(n)
        if not n then return nil end
        return math.clamp(math.floor(n), 0, 255)
    end

    local function createColorRow(order, label, key)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 40)
        Row.BackgroundTransparency = 1
        Row.LayoutOrder = order
        Row.Parent = SettingsPage

        local Swatch = Instance.new("Frame")
        Swatch.Size = UDim2.new(0, 26, 0, 26)
        Swatch.Position = UDim2.new(0, 0, 0.5, -13)
        Swatch.BorderSizePixel = 0
        Swatch.Parent = Row
        reg(Swatch, "BackgroundColor3", key)
        corner(Swatch, 6)
        stroke(Swatch, "Stroke", 1)

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(0, 130, 1, 0)
        Label.Position = UDim2.new(0, 36, 0, 0)
        Label.Text = label
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Row
        reg(Label, "TextColor3", "Text")

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
            reg(Box, "BackgroundColor3", "Elevated")
            reg(Box, "TextColor3", "Text")
            corner(Box, 6)
            return Box
        end

        local RBox = makeBox(170, "R")
        local GBox = makeBox(218, "G")
        local BBox = makeBox(266, "B")

        local function applyColor()
            local c = Theme[key]
            local r = clampByte(RBox.Text) or math.floor(c.R * 255)
            local g = clampByte(GBox.Text) or math.floor(c.G * 255)
            local b = clampByte(BBox.Text) or math.floor(c.B * 255)
            Theme[key] = Color3.fromRGB(r, g, b)
            ApplyTheme()
        end

        RBox.FocusLost:Connect(applyColor)
        GBox.FocusLost:Connect(applyColor)
        BBox.FocusLost:Connect(applyColor)
    end

    local order = 3
    for _, entry in ipairs(ThemeKeysOrder) do
        createColorRow(order, entry.label, entry.key)
        order += 1
    end

    -- --- переключатель ХУДа ---
    local HudRow = Instance.new("Frame")
    HudRow.Size = UDim2.new(1, 0, 0, 36)
    HudRow.BackgroundTransparency = 1
    HudRow.LayoutOrder = order
    HudRow.Parent = SettingsPage
    order += 1

    local HudLabel = Instance.new("TextLabel")
    HudLabel.BackgroundTransparency = 1
    HudLabel.Size = UDim2.new(1, -60, 1, 0)
    HudLabel.Text = "Показывать HUD"
    HudLabel.Font = Enum.Font.Gotham
    HudLabel.TextSize = 13
    HudLabel.TextXAlignment = Enum.TextXAlignment.Left
    HudLabel.Parent = HudRow
    reg(HudLabel, "TextColor3", "Text")

    local HudToggle = Instance.new("TextButton")
    HudToggle.Size = UDim2.new(0, 44, 0, 24)
    HudToggle.Position = UDim2.new(1, -44, 0.5, -12)
    HudToggle.Text = "ON"
    HudToggle.Font = Enum.Font.GothamBold
    HudToggle.TextSize = 12
    HudToggle.AutoButtonColor = false
    HudToggle.Parent = HudRow
    corner(HudToggle, 12)
    reg(HudToggle, "BackgroundColor3", "Accent")
    HudToggle.TextColor3 = Color3.fromRGB(255, 255, 255)

    HudToggle.MouseButton1Click:Connect(function()
        HUDGui.Enabled = not HUDGui.Enabled
        if HUDGui.Enabled then
            HudToggle.Text = "ON"
            HudToggle.BackgroundColor3 = Theme.Accent
        else
            HudToggle.Text = "OFF"
            HudToggle.BackgroundColor3 = Theme.Elevated
        end
    end)

    -- --- конфиги ---
    local ConfigRow = Instance.new("Frame")
    ConfigRow.Size = UDim2.new(1, 0, 0, 36)
    ConfigRow.BackgroundTransparency = 1
    ConfigRow.LayoutOrder = order
    ConfigRow.Parent = SettingsPage
    order += 1

    local ConfigStatus = Instance.new("TextLabel")
    ConfigStatus.BackgroundTransparency = 1
    ConfigStatus.Size = UDim2.new(1, 0, 0, 18)
    ConfigStatus.Text = ""
    ConfigStatus.Font = Enum.Font.Gotham
    ConfigStatus.TextSize = 12
    ConfigStatus.TextXAlignment = Enum.TextXAlignment.Left
    ConfigStatus.LayoutOrder = order
    ConfigStatus.Parent = SettingsPage
    order += 1

    local function configBtn(xOffset, text)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 110, 0, 32)
        Btn.Position = UDim2.new(0, xOffset, 0, 0)
        Btn.Text = text
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Btn.AutoButtonColor = false
        Btn.Parent = ConfigRow
        reg(Btn, "BackgroundColor3", "Elevated")
        reg(Btn, "TextColor3", "Text")
        corner(Btn, 6)
        stroke(Btn, "Stroke", 1)
        return Btn
    end

    local SaveBtn = configBtn(0, "Сохранить")
    local LoadBtn = configBtn(120, "Загрузить")
    local ResetBtn = configBtn(240, "Сброс")

    SaveBtn.MouseButton1Click:Connect(function()
        saveConfig(ConfigStatus)
    end)
    LoadBtn.MouseButton1Click:Connect(function()
        loadConfig(ConfigStatus)
    end)
    ResetBtn.MouseButton1Click:Connect(function()
        Theme.Background = Color3.fromRGB(22, 22, 26)
        Theme.Secondary  = Color3.fromRGB(30, 30, 36)
        Theme.Elevated   = Color3.fromRGB(38, 38, 45)
        Theme.Stroke     = Color3.fromRGB(48, 48, 56)
        Theme.Accent     = Color3.fromRGB(114, 137, 255)
        Theme.Text       = Color3.fromRGB(235, 235, 240)
        Theme.SubText    = Color3.fromRGB(150, 150, 162)
        ApplyTheme()
        ConfigStatus.TextColor3 = Color3.fromRGB(120, 220, 140)
        ConfigStatus.Text = "Тема сброшена до стандартной"
    end)

    selectTab("AAA")

    makeDraggable(MainFrame, TopBar)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Insert then
            MainGui.Enabled = not MainGui.Enabled
        end
    end)

    return MainGui
end

------------------------------------------------------------
-- ЗАПУСК
------------------------------------------------------------
local HUDGui = buildHUD()
buildMainMenu(HUDGui)
