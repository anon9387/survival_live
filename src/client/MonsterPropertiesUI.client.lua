--- Retrieves the Players service, which provides access to the players in the game.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Assume we have a RemoteFunction to get monster properties
local getMonsterPropertiesFunc = ReplicatedStorage:WaitForChild("GetMonsterProperties")

-- Create the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterPropertiesUI"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(1, -310, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -10, 1, -10)
scrollingFrame.Position = UDim2.new(0, 5, 0, 5)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollingFrame

-- Table to store labels
local propertyLabels = {}

-- Function to update UI
local function updateUI()
    local monsterProperties = getMonsterPropertiesFunc:InvokeServer()
    
    -- Update or create labels for each property
    for key, value in pairs(monsterProperties) do
        if not propertyLabels[key] then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = scrollingFrame
            propertyLabels[key] = label
        end
        propertyLabels[key].Text = key .. ": " .. tostring(value)
    end
    
    -- Update labels for properties not in the current data
    for key, label in pairs(propertyLabels) do
        if monsterProperties[key] == nil then
            label.Text = key .. ": nil"
        end
    end
    
    -- Update scrolling frame size
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

-- Initial creation of labels
local initialProperties = getMonsterPropertiesFunc:InvokeServer()
for key, _ in pairs(initialProperties) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = scrollingFrame
    propertyLabels[key] = label
end

while true do
    updateUI()
    task.wait(0.01)
end