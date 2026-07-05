--[[
    Project1 - Главное меню (menu.lua)
    Подгружается из main.lua после ввода правильного ключа.

    ХУД ПОЛНОСТЬЮ УБРАН — только главное окно с вкладками.

    Структура вынесена в модули (загружаются по HttpGet с BASE_URL):
      Modules/Theme.lua               — палитра цветов, пресеты
      Modules/UI.lua                  — общие UI-хелперы (corner, stroke, тумблер...)
      Modules/Settings.lua            — вкладка настроек (палитра, RGB, конфиги)
      Modules/Categories/AAA.lua      — функции вкладки AAA (заглушки)
      Modules/Categories/Visuals.lua  — функции вкладки Visuals (заглушки)
      Modules/Categories/Misc.lua     — функции вкладки MISC (заглушки)

    Чтобы добавить новую вкладку — сделай файл в Modules/Categories/,
    который возвращает таблицу с функцией Build(ctx), и добавь строку
    в CategoryModules ниже.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("Project1_Main") then
    CoreGui.Project1_Main:Destroy()
end
if CoreGui:FindFirstChild("Project1_HUD") then
    CoreGui.Project1_HUD:Destroy() -- удаляем ХУД от старой версии, если он был загружен ранее
end

------------------------------------------------------------
-- ЗАГРУЗКА МОДУЛЕЙ
------------------------------------------------------------
-- ВАЖНО: замени на свой репозиторий/ветку, где лежит папка Modules/
local BASE_URL = "https://raw.githubusercontent.com/bblodik/Project1/main/"

local function loadModule(path)
    local src = game:HttpGet(BASE_URL .. path)
    local chunk = assert(loadstring(src, path))
    return chunk()
end

local Theme    = loadModule("Modules/Theme.lua")
local UI       = loadModule("Modules/UI.lua")
local Settings = loadModule("Modules/Settings.lua")

-- вкладки-категории: имя вкладки -> путь к модулю с функциями
local CategoryModules = {
    {Name = "AAA",     Path = "Modules/Categories/AAA.lua"},
    {Name = "Visuals", Path = "Modules/Categories/Visuals.lua"},
    {Name = "MISC",    Path = "Modules/Categories/Misc.lua"},
}

------------------------------------------------------------
-- HELPERS (локальные, только для сборки самого окна)
------------------------------------------------------------
local TOPBAR_HEIGHT = 44
local SIDEBAR_WIDTH = 150

------------------------------------------------------------
-- ===================== ГЛАВНОЕ ОКНО =========================
------------------------------------------------------------
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "Project1_Main"
MainGui.ResetOnSpawn = false
MainGui.IgnoreGuiInset = true
MainGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 560, 0, 380)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = MainGui
Theme.reg(MainFrame, "BackgroundColor3", "Background")
UI.corner(MainFrame, 12)
UI.stroke(MainFrame, Theme, "Stroke", 1)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Theme.reg(TopBar, "BackgroundColor3", "Secondary")
UI.corner(TopBar, 12)
UI.squareOff(TopBar, Theme, "Secondary", 12, true)

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "Project1"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar
Theme.reg(Title, "TextColor3", "Text")

local SubTitle = Instance.new("TextLabel")
SubTitle.BackgroundTransparency = 1
SubTitle.Size = UDim2.new(0, 170, 1, 0)
SubTitle.Position = UDim2.new(1, -235, 0, 0)
SubTitle.Text = "INSERT — открыть/закрыть"
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 12
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.Parent = TopBar
Theme.reg(SubTitle, "TextColor3", "SubText")

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 2
CloseBtn.Parent = TopBar
Theme.reg(CloseBtn, "BackgroundColor3", "Elevated")
Theme.reg(CloseBtn, "TextColor3", "Text")
UI.corner(CloseBtn, 6)

CloseBtn.MouseButton1Click:Connect(function()
    MainGui.Enabled = false
end)

-- ==== БОКОВАЯ ПАНЕЛЬ ====
local SideBar = Instance.new("Frame")
SideBar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -TOPBAR_HEIGHT)
SideBar.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
SideBar.BorderSizePixel = 0
SideBar.Parent = MainFrame
Theme.reg(SideBar, "BackgroundColor3", "Secondary")

local TabsContainer = Instance.new("Frame")
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
Theme.reg(Divider, "BackgroundColor3", "Stroke")

local ModeLabel = Instance.new("TextLabel")
ModeLabel.BackgroundTransparency = 1
ModeLabel.Size = UDim2.new(1, -20, 0, 16)
ModeLabel.Position = UDim2.new(0, 10, 1, -98)
ModeLabel.Text = "Mode ID: 0001"
ModeLabel.Font = Enum.Font.Gotham
ModeLabel.TextSize = 12
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = SideBar
Theme.reg(ModeLabel, "TextColor3", "SubText")

local ProfileContainer = Instance.new("Frame")
ProfileContainer.Size = UDim2.new(1, -20, 0, 70)
ProfileContainer.Position = UDim2.new(0, 10, 1, -80)
ProfileContainer.BorderSizePixel = 0
ProfileContainer.Parent = SideBar
Theme.reg(ProfileContainer, "BackgroundColor3", "Elevated")
UI.corner(ProfileContainer, 8)
UI.stroke(ProfileContainer, Theme, "Stroke", 1)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 44, 0, 44)
AvatarImage.Position = UDim2.new(0, 8, 0.5, -22)
AvatarImage.Parent = ProfileContainer
Theme.reg(AvatarImage, "BackgroundColor3", "Secondary")
UI.corner(AvatarImage, 22)

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
Theme.reg(UserNameLabel, "TextColor3", "Text")

local UIDLabel = Instance.new("TextLabel")
UIDLabel.BackgroundTransparency = 1
UIDLabel.Size = UDim2.new(1, -60, 0, 16)
UIDLabel.Position = UDim2.new(0, 58, 0, 32)
UIDLabel.Text = "UID: 1"
UIDLabel.Font = Enum.Font.Gotham
UIDLabel.TextSize = 12
UIDLabel.TextXAlignment = Enum.TextXAlignment.Left
UIDLabel.Parent = ProfileContainer
Theme.reg(UIDLabel, "TextColor3", "SubText")

-- ==== контейнер контента ====
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -TOPBAR_HEIGHT)
ContentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, TOPBAR_HEIGHT)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame
Theme.reg(ContentArea, "BackgroundColor3", "Background")

local pages = {}
local buttons = {}
local currentTab = nil

local function selectTab(name)
    currentTab = name
    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end
    for tabName, btn in pairs(buttons) do
        if tabName == name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Current.Accent}):Play()
            btn.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Current.Elevated}):Play()
            btn.TextLabel.TextColor3 = Theme.Current.SubText
        end
    end
end
Theme.OnRefresh(function()
    if currentTab then selectTab(currentTab) end
end)

local function createPage(name, layoutOrder)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name
    TabBtn.Size = UDim2.new(1, 0, 0, 36)
    TabBtn.AutoButtonColor = false
    TabBtn.Text = ""
    TabBtn.LayoutOrder = layoutOrder
    TabBtn.Parent = TabsContainer
    TabBtn.BackgroundColor3 = Theme.Current.Elevated
    UI.corner(TabBtn, 8)

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Name = "TextLabel"
    TabLabel.BackgroundTransparency = 1
    TabLabel.Size = UDim2.new(1, -10, 1, 0)
    TabLabel.Position = UDim2.new(0, 10, 0, 0)
    TabLabel.Text = name
    TabLabel.Font = Enum.Font.GothamMedium
    TabLabel.TextSize = 14
    TabLabel.TextColor3 = Theme.Current.SubText
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
    Theme.reg(Page, "ScrollBarImageColor3", "Accent")

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
    SectionTitle.LayoutOrder = 0
    SectionTitle.Parent = Page
    Theme.reg(SectionTitle, "TextColor3", "Text")

    pages[name] = Page
    TabBtn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    return Page
end

------------------------------------------------------------
-- Вкладки-категории (грузятся из Modules/Categories/)
------------------------------------------------------------
for i, cat in ipairs(CategoryModules) do
    local Page = createPage(cat.Name, i)
    local ok, mod = pcall(loadModule, cat.Path)
    if ok and mod and mod.Build then
        mod.Build({Page = Page, Theme = Theme, UI = UI})
    else
        warn("Не удалось загрузить категорию " .. cat.Name .. ": " .. tostring(mod))
    end
end

-- вкладка Settings (палитра, ручная настройка, конфиги)
local SettingsPage = createPage("Settings", #CategoryModules + 1)
Settings.Build({Page = SettingsPage, Theme = Theme, UI = UI})

selectTab(CategoryModules[1].Name)

UI.makeDraggable(MainFrame, TopBar)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainGui.Enabled = not MainGui.Enabled
    end
end)
