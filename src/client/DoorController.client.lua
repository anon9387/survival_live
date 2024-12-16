local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Doors = Workspace:WaitForChild("UnlockableDoors")

print("Script started - Player:", player.Name)

local unlockedDoors = {}

local function unlockDoor(door)
    print("Attempting to unlock door:", door.Name)
    if unlockedDoors[door] then 
        print("Door already unlocked, skipping")
        return 
    end
    
    local character = player.Character
    if not character then 
        print("No character found")
        return 
    end
    
    local tool = character:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChild(door.Name)
    print("Found tool:", tool and tool.Name or "No matching tool")
    
    if tool and tool.Name == door.Name then
        print("Correct tool found! Unlocking door:", door.Name)
        unlockedDoors[door] = true
        
        print("Making door parts transparent...")
        for _, part in ipairs(door:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
                part.Transparency = 1
                part.CanCollide = false
                print("Made part transparent:", part.Name)
            elseif part:IsA("Texture") then
                part.Transparency = 1
                print("Made texture transparent:", part.Name)
            elseif part:IsA("Decal") then
                part.Transparency = 1
                print("Made decal transparent:", part.Name)
            elseif part:IsA("SurfaceGui") or part:IsA("BillboardGui") then
                part.Enabled = false
                print("Disabled UI:", part.Name)
            end
        end
        
        -- Disable the ProximityPrompt
        local prompt = door:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt.Enabled = false
            print("Disabled ProximityPrompt for door:", door.Name)
        end
        
        print("Destroying tool...")
        tool:Destroy()
        print("Door unlock complete!")
    else
        print("Wrong tool or no tool for door:", door.Name)
    end
end

player.CharacterAdded:Connect(function(character)
    print("Character respawned - Reapplying door states")
    for door, _ in pairs(unlockedDoors) do
        if door:IsDescendantOf(game) then
            print("Restoring unlocked state for door:", door.Name)
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
    print("Initializing door system...")
    print("Found", #Doors:GetChildren(), "doors")
    
    for _, door in ipairs(Doors:GetChildren()) do
        print("Setting up door:", door.Name)
        print(door:IsA("Model"), door.PrimaryPart, "DOOR IS VALID")
        if door:IsA("Model") then
            local prompt = door:WaitForChild("ProximityPrompt")
            print("Prompt found:", prompt and prompt.Name or "NONE")
            if not prompt then
                print("Creating new ProximityPrompt for:", door.Name)
                prompt = Instance.new("ProximityPrompt")
                prompt.Parent = door
            end
            
            prompt.Triggered:Connect(function()
                print("ProximityPrompt triggered for door:", door.Name)
                unlockDoor(door)
            end)
            
            print("Adding ClickDetectors to door parts:", door.Name)
            for _, part in ipairs(door:GetDescendants()) do
                if part:IsA("BasePart") then
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.Parent = part
                    clickDetector.MouseClick:Connect(function()
                        print("Click detected on door part:", part.Name)
                        unlockDoor(door)
                    end)
                end
            end
        end
    end
    print("Door system initialization complete!")
end

init()