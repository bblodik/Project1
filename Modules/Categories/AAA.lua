--[[
    Project1 - Категория "AAA" (Modules/Categories/AAA.lua)

    Это ЗАГЛУШКИ. Каждый тумблер просто печатает своё состояние в консоль.
    Чтобы подключить реальную логику — впиши её внутрь callback-функции
    там, где стоит комментарий "-- TODO: логика функции".
]]

local AAA = {}

-- список функций этой вкладки: {Название, ключ для сохранения состояния}
local Features = {
    {Name = "Функция AAA 1", Id = "aaa_1"},
    {Name = "Функция AAA 2", Id = "aaa_2"},
    {Name = "Функция AAA 3", Id = "aaa_3"},
}

-- ctx = {Page = ScrollingFrame, Theme = Theme, UI = UI}
function AAA.Build(ctx)
    local Page, Theme, UI = ctx.Page, ctx.Theme, ctx.UI

    for i, feature in ipairs(Features) do
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 36)
        Row.BackgroundTransparency = 1
        Row.LayoutOrder = i
        Row.Parent = Page

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -34, 1, 0)
        Label.Text = feature.Name
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Row
        Theme.reg(Label, "TextColor3", "Text")

        local Toggle = UI.createToggle(Row, Theme, false, function(state)
            -- TODO: логика функции (feature.Id == "aaa_1" и т.д.)
            print(("[AAA] %s -> %s"):format(feature.Name, tostring(state)))
        end)
        Toggle.AnchorPoint = Vector2.new(1, 0.5)
        Toggle.Position = UDim2.new(1, 0, 0.5, 0)
    end
end

return AAA
