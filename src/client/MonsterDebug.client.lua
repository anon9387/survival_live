local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create debug UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterDebug"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 300)
frame.Position = UDim2.new(1, -220, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "Monster Debug"
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -20, 1, -40)
list.Position = UDim2.new(0, 10, 0, 35)
list.BackgroundTransparency = 1
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = list

-- Dynamic label management
local labels = {}

-- Function to format values for display
local function formatValue(value)
    if typeof(value) == "Vector3" then
        return string.format("(%.1f, %.1f, %.1f)", value.X, value.Y, value.Z)
    elseif typeof(value) == "boolean" then
        return value and "Yes" or "No"
    else
        return tostring(value)
    end
end

-- Function to create or update labels based on state
local function updateDebugDisplay(state)
    -- Sort properties for consistent display order
    local sortedProperties = {}
    for prop, _ in pairs(state) do
        table.insert(sortedProperties, prop)
    end
    table.sort(sortedProperties)
    
    -- Create or update labels
    for _, prop in ipairs(sortedProperties) do
        if not labels[prop] then
            -- Create new label if it doesn't exist
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.Parent = list
            labels[prop] = label
        end
        
        -- Update label text
        local formattedValue = formatValue(state[prop])
        labels[prop].Text = prop .. ": " .. formattedValue
    end
    
    -- Remove any labels for properties that no longer exist
    for prop, label in pairs(labels) do
        if not state[prop] then
            label:Destroy()
            labels[prop] = nil
        end
    end
    
    -- Update frame size to fit content
    local contentHeight = layout.AbsoluteContentSize.Y + 45
    frame.Size = UDim2.new(0, 200, 0, math.min(contentHeight, 400))
end

-- Add draggable functionality
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                              startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Connect to debug updates
ReplicatedStorage:WaitForChild("MonsterDebugUpdate").OnClientEvent:Connect(updateDebugDisplay)

-- Parent to PlayerGui
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
