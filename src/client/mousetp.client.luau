local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local mouse = player:GetMouse()

-- Function to update character reference when player respawns
local function onCharacterAdded(newCharacter)
    character = newCharacter
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Function to teleport the character to the mouse position
local function teleportToMouse()
    -- Get the mouse hit position in world space
    local mouseHit = mouse.Hit.Position
    
    -- Get the humanoid root part and set its position
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(mouseHit)
    end
end

-- Connect the "T" key press event
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T and not gameProcessed then
        teleportToMouse()
    end
end)