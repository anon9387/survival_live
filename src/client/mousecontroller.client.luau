local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Create a ScreenGui to hold the cursor
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CursorGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.Parent = player.PlayerGui

local cursor = Instance.new("ImageLabel")
cursor.Name = "CustomCursor"
cursor.AnchorPoint = Vector2.new(0, 0)
cursor.Size = UDim2.new(0, 32, 0, 32)
cursor.BackgroundTransparency = 1
cursor.Image = "rbxassetid://74101398276123"
cursor.ZIndex = 999999
cursor.Parent = screenGui

-- Disable default cursor
UserInputService.MouseIconEnabled = false

-- Animation settings
local currentTween = nil

-- Add these near the top with other variables
local defaultCursorImage = "rbxassetid://74101398276123"
local blueDoorCursorImage = "rbxassetid://71739784684818"
local defaultCursorSize = UDim2.new(0, 32, 0, 32)
local blueDoorCursorSize = UDim2.new(0, 96, 0, 96)  -- 2x bigger than default

local function createClickEffect(position)
    local effect = Instance.new("Frame")
    effect.Size = UDim2.new(0, 0, 0, 0)
    effect.AnchorPoint = Vector2.new(0.5, 0.5)
    effect.Position = UDim2.new(0, position.X, 0, position.Y)
    effect.BackgroundColor3 = Color3.new(1, 1, 1)
    effect.BorderSizePixel = 0
    effect.ZIndex = 999
    effect.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = effect

    local growTween = TweenService:Create(effect, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 92, 0, 92),
        BackgroundTransparency = 1
    })

    growTween.Completed:Connect(function()
        effect:Destroy()
    end)

    growTween:Play()
end

local function onClick()
    if currentTween then
        currentTween:Cancel()
    end
    
    cursor.Size = UDim2.new(0, 32, 0, 32)
    
    currentTween = TweenService:Create(cursor, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 37, 0, 37)
    })
    
    createClickEffect(Vector2.new(mouse.X, mouse.Y))
    
    currentTween.Completed:Connect(function()
        if currentTween then
            local shrinkTween = TweenService:Create(cursor, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 32, 0, 32)
            })
            shrinkTween:Play()
            currentTween = shrinkTween
        end
    end)
    
    currentTween:Play()
end

-- Update cursor position and check hover using RenderStepped
RunService.RenderStepped:Connect(function()
    cursor.Position = UDim2.new(0, mouse.X - 0, 0, mouse.Y - 0)
    
    -- Check if mouse is hovering over Blue folder
    local target = mouse.Target
    if target and target:IsDescendantOf(Workspace:WaitForChild("UnlockableDoors"):WaitForChild("Blue")) then
        cursor.Image, cursor.Size = blueDoorCursorImage, blueDoorCursorSize
    else
        cursor.Image, cursor.Size = defaultCursorImage, defaultCursorSize
    end
end)

-- Connect click animation
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onClick()
    end
end)

