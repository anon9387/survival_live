local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Meats = Workspace:WaitForChild("Meats")
local ClonedMeatFolder = ReplicatedStorage:WaitForChild("MeatsClones")

local sf = 3234
-- Cache remote events
local DataLoaded = ReplicatedStorage:WaitForChild("DataLoaded")
local UpdateMeat = ReplicatedStorage:WaitForChild("UpdateMeat")
local CollectMeat = ReplicatedStorage:WaitForChild("CollectMeat")

-- Local data cache
local PlayerData = {
    OwnedMeat = {}
}

-- At the top of the file with other variables
local promptConnections = {} -- Store connections by meat instance

-- Function to setup meat animation
local function setupMeatAnimation(meat)
    if not meat then return end
    
    task.spawn(function()
        local rotationSpeed = 1
        local amplitude = 0.025
        local frequency = 1.5
        local time = 0
        
        while meat and meat:IsDescendantOf(game) do
            task.wait(0.03)
            time = time + 0.03 * frequency
            local verticalOffset = math.sin(time) * amplitude
            meat.CFrame = meat.CFrame * CFrame.Angles(0, math.rad(rotationSpeed), 0) 
                + Vector3.new(0, verticalOffset, 0)
        end
    end)
end

-- Modified setupMeatPrompt function
local function setupMeatPrompt(meat)
    if meat:IsA("StringValue") then return end
    
    -- If player already owns this meat, remove it from workspace
    if table.find(PlayerData.OwnedMeat, meat.Name) then
        if Meats:FindFirstChild(meat.Name) then
            Meats:FindFirstChild(meat.Name):Destroy()
        end
        return
    end
    
    -- Cleanup old connection if it exists
    if promptConnections[meat] then
        promptConnections[meat]:Disconnect()
        promptConnections[meat] = nil
    end
    
    -- Create or get proximity prompt
    local prompt = meat:FindFirstChild("ProximityPrompt")
    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = meat.Name
        prompt.ActionText = "Collect"
        prompt.Parent = meat
    end
    
    -- Connect prompt trigger and store the connection
    promptConnections[meat] = prompt.Triggered:Connect(function()
        CollectMeat:FireServer(meat.Name)
        meat:Destroy()
        promptConnections[meat] = nil -- Clean up the connection reference
    end)
    
    -- Setup animation
    setupMeatAnimation(meat)
end

-- Handle initial data load
DataLoaded.OnClientEvent:Connect(function(data)
    PlayerData.OwnedMeat = data.ownedMeat
    
    -- Process all meats in ClonedMeatFolder
    for _, meat in ipairs(ClonedMeatFolder:GetChildren()) do
        local workspaceMeat = Meats:FindFirstChild(meat.Name)
        if not workspaceMeat and not table.find(PlayerData.OwnedMeat, meat.Name) then
            local newMeat = meat:Clone()
            newMeat.Parent = Meats
            setupMeatPrompt(newMeat)
        end
    end
end)

-- Handle meat updates
UpdateMeat.OnClientEvent:Connect(function(newMeatList)
    PlayerData.OwnedMeat = newMeatList
    
    -- Reprocess all meats
    for _, meat in ipairs(ClonedMeatFolder:GetChildren()) do
        local workspaceMeat = Meats:FindFirstChild(meat.Name)
        if workspaceMeat then
            setupMeatPrompt(workspaceMeat)
        elseif not table.find(PlayerData.OwnedMeat, meat.Name) then
            local newMeat = meat:Clone()
            newMeat.Parent = Meats
            setupMeatPrompt(newMeat)
        end
    end
end)

-- Setup prompts for new meats
Meats.ChildAdded:Connect(setupMeatPrompt)

Meats.ChildRemoved:Connect(function(meat)
    if promptConnections[meat] then
        promptConnections[meat]:Disconnect()
        promptConnections[meat] = nil
    end
end)

