
repeat task.wait() until game.Loaded
task.wait(3)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Keys = Workspace.Keys
local KeyTools = ReplicatedStorage.Assets.KeyTools

-- Storage for original keys and their connections
local OriginalKeys = {}
local KeyConnections = {}

-- Function to give key tool to player and remove key from world
local function giveKeyToPlayer(keyName, keyObject)
    local tool = KeyTools:FindFirstChild(keyName)
    if tool then
        tool:Clone().Parent = player.Backpack
        keyObject:Destroy()
    end
end

-- Function to create proximity prompt connection
local function createPromptConnection(key)
    local connection = key.ProximityPrompt.Triggered:Connect(function()
        giveKeyToPlayer(key.Name, key)
    end)
    KeyConnections[key] = connection
end

-- Wait until all children of the Keys folder are loaded
local function waitForKeysToLoad()
    while #Keys:GetChildren() < 5 do
        task.wait()
    end
end

waitForKeysToLoad()

for _, key in ipairs(Keys:GetChildren()) do
    OriginalKeys[key.Name] = key:Clone()
    createPromptConnection(key)
end

-- Function to respawn a key
local function respawnKey(keyName, originalKey)
    local newKey = originalKey:Clone()
    newKey.Parent = Keys
    createPromptConnection(newKey)
end

-- Respawn missing keys when character respawns
player.CharacterAdded:Connect(function()
    for name, originalKey in pairs(OriginalKeys) do
        if not Keys:FindFirstChild(name) then
            respawnKey(name, originalKey)
        end
    end
end)