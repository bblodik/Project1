--[[
    Project1 - UI хелперы (Modules/UI.lua)
    Общие функции для построения интерфейса.
    Используются во всех вкладках/категориях, чтобы не дублировать код.
]]

local UI = {}

function UI.corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- обводка, привязанная к теме (перекрасится сама при смене палитры)
function UI.stroke(parent, Theme, key, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Parent = parent
    Theme.reg(s, "Color", key or "Stroke")
    return s
end

function UI.squareOff(parent, Theme, key, height, fromBottom)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.ZIndex = 0
    f.Size = UDim2.new(1, 0, 0, height)
    f.Position = fromBottom and UDim2.new(0, 0, 1, -height) or UDim2.new(0, 0, 0, 0)
    f.Parent = parent
    Theme.reg(f, "BackgroundColor3", key)
    return f
end

function UI.makeDraggable(frame, dragHandle)
    local UserInputService = game:GetService("UserInputService")
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
-- КВАДРАТНЫЙ ТУМБЛЕР (замена ON/OFF)
-- Квадратик: пустой = выключено, залит акцентным цветом = включено.
-- Возвращает сам Frame-кнопку и функцию getState()
------------------------------------------------------------
function UI.createToggle(parent, Theme, default, callback)
    local state = default and true or false

    local Box = Instance.new("TextButton")
    Box.Size = UDim2.new(0, 22, 0, 22)
    Box.Text = ""
    Box.AutoButtonColor = false
    Box.BorderSizePixel = 0
    Box.Parent = parent
    UI.corner(Box, 5)
    UI.stroke(Box, Theme, "Stroke", 1)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 12, 0, 12)
    Fill.AnchorPoint = Vector2.new(0.5, 0.5)
    Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
    Fill.BorderSizePixel = 0
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.Parent = Box
    UI.corner(Fill, 3)

    local function redraw()
        Box.BackgroundColor3 = state and Theme.Current.Accent or Theme.Current.Elevated
        Fill.Visible = state
    end

    Theme.OnRefresh(redraw)
    redraw()

    Box.MouseButton1Click:Connect(function()
        state = not state
        redraw()
        if callback then
            pcall(callback, state)
        end
    end)

    return Box, function()
        return state
    end
end

return UI
