local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Get the beam template
local beamTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Beam")

-- Keep track of current beam and attachments
local currentBeam = nil
local currentAttachment0 = nil
local currentAttachment1 = nil

-- Function to cleanup existing beam
local function cleanupBeam()
    if currentBeam then
        currentBeam:Destroy()
        currentBeam = nil
    end
    if currentAttachment0 then
        currentAttachment0:Destroy()
        currentAttachment0 = nil
    end
    if currentAttachment1 then
        currentAttachment1:Destroy()
        currentAttachment1 = nil
    end
end

-- Function to create beam between two attachments
local function createBeam(origin, target)
    cleanupBeam()
    
    currentAttachment0 = Instance.new("Attachment")
    currentAttachment1 = Instance.new("Attachment")
    
    -- Reversed attachment parenting
    currentAttachment0.Parent = target
    currentAttachment1.Parent = origin
    
    local beam = beamTemplate:Clone()
    beam.Attachment0 = currentAttachment0
    beam.Attachment1 = currentAttachment1
    beam.Parent = workspace
    
    currentBeam = beam
    return beam
end

-- Update beam based on equipped tool
local function updateBeam()
    cleanupBeam()
    
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if not tool then 
        return 
    end
    
    local doorsFolder = workspace:FindFirstChild("UnlockableDoors")
    if not doorsFolder then 
        return 
    end
    
    -- Look for matching door
    for _, door in ipairs(doorsFolder:GetChildren()) do
        if door:IsA("Model") and door.Name == tool.Name and door.PrimaryPart then
            -- Check if the door is visible to this client
            local isVisible = false
            for _, part in ipairs(door:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    isVisible = true
                    break
                end
            end
            
            if isVisible then
                createBeam(humanoidRootPart, door.PrimaryPart)
                break
            end
        end
    end
end

-- Connect character events
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Watch for tool equipped/unequipped
    character.ChildAdded:Connect(function(child)
        task.wait() -- Give the tool a frame to fully replicate
        if child:IsA("Tool") then
            updateBeam()
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            cleanupBeam()
        end
    end)
    
    -- Check if player already has a tool equipped
    task.wait() -- Wait a frame for character to fully load
    updateBeam()
end

-- Handle initial character and character respawns
player.CharacterAdded:Connect(onCharacterAdded)

-- Handle initial character if player already spawned
if player.Character then
    onCharacterAdded(player.Character)
end
