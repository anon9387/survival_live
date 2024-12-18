local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Doors = Workspace:WaitForChild("UnlockableDoors")

local unlockedDoors = {}

local function unlockDoor(door)
    if unlockedDoors[door] then 
        return 
    end
    
    local character = player.Character
    if not character then 
        return 
    end
    
    local tool = character:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChild(door.Name)
    
    if tool and tool.Name == door.Name then
        unlockedDoors[door] = true
        
        for _, part in ipairs(door:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
                part.Transparency = 1
                part.CanCollide = false
            elseif part:IsA("Texture") then
                part.Transparency = 1
            elseif part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("SurfaceGui") or part:IsA("BillboardGui") then
                part.Enabled = false
            end
        end
        
        local prompt = door:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt.Enabled = false
        end
        
        tool:Destroy()
    end
end

player.CharacterAdded:Connect(function(character)
    for door, _ in pairs(unlockedDoors) do
        if door:IsDescendantOf(game) then
            for _, part in ipairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
        end
    end
end)

local function init()
    for _, door in ipairs(Doors:GetChildren()) do
        if door:IsA("Model") then
            local prompt = door:WaitForChild("ProximityPrompt")
            if not prompt then
                prompt = Instance.new("ProximityPrompt")
                prompt.Parent = door
            end
            
            prompt.Triggered:Connect(function()
                unlockDoor(door)
            end)
            
            for _, part in ipairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.Parent = part
                    clickDetector.MouseClick:Connect(function()
                        unlockDoor(door)
                    end)
                end
            end
        end
    end
end

local function waitForDoorsToLoad()
    while #Doors:GetChildren() < 5 do
        task.wait(.1)
    end
end

waitForDoorsToLoad()

init()
print("Door system initialized!")