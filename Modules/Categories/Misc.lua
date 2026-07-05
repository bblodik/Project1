--[[
    Project1 - Категория "MISC" (Modules/Categories/Misc.lua)

    Это ЗАГЛУШКИ. Каждый тумблер просто печатает своё состояние в консоль.
    Впиши реальную логику внутрь callback-функции, там где "-- TODO: логика функции".
]]

local Misc = {}

local Features = {
    {Name = "Функция MISC 1", Id = "misc_1"},
    {Name = "Функция MISC 2", Id = "misc_2"},
    {Name = "Функция MISC 3", Id = "misc_3"},
}

function Misc.Build(ctx)
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
            -- TODO: логика функции (feature.Id == "misc_1" и т.д.)
            print(("[MISC] %s -> %s"):format(feature.Name, tostring(state)))
        end)
        Toggle.AnchorPoint = Vector2.new(1, 0.5)
        Toggle.Position = UDim2.new(1, 0, 0.5, 0)
    end
end

return Misc
