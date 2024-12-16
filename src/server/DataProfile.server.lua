local ProfileService = require(game:GetService("ServerScriptService"):WaitForChild("ProfileService"))
local DataManager = require(script.Parent.DataManager)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Profile Store Setup
local ProfileTemplate = {
    Coins = 0,
    OwnedMeat = {}, -- Will store meat IDs that the player owns
}

local GameProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    ProfileTemplate
)

local Profiles = {} -- {[player] = profile}

-- Initialize DataManager with Profiles table
DataManager.Initialize(Profiles)

-- Function to handle a player joining
local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync(
        "Player_" .. player.UserId,
        "ForceLoad"
    )
    
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate
        
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick("Your data was loaded on another server.")
        end)
        
        if player:IsDescendantOf(Players) then
            Profiles[player] = profile
            
            -- Fire client to let them know data is ready
            ReplicatedStorage:WaitForChild("DataLoaded"):FireClient(player, {
                coins = profile.Data.Coins,
                ownedMeat = profile.Data.OwnedMeat
            })
        else
            profile:Release()
        end
    else
        player:Kick("Failed to load your data. Please rejoin.")
    end
end

-- Connect events
Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local profile = Profiles[player]
    if profile ~= nil then
        profile:Release()
    end
end)

-- Setup remote events for client communication
local RemoteEvents = {
    DataLoaded = Instance.new("RemoteEvent"),
    UpdateCoins = Instance.new("RemoteEvent"),
    UpdateMeat = Instance.new("RemoteEvent"),
    CollectMeat = Instance.new("RemoteEvent") -- unsecured for meat collection
}

for name, event in pairs(RemoteEvents) do
    event.Name = name
    event.Parent = ReplicatedStorage
end 

ReplicatedStorage:WaitForChild("CollectMeat").OnServerEvent:Connect(function(player, meatId)
    print("Server received meat collection request:", meatId)
    DataManager.AddMeat(player, meatId)
end)

-- Add this after the RemoteEvents setup
local RequestData = Instance.new("RemoteFunction")
RequestData.Name = "RequestData"
RequestData.Parent = ReplicatedStorage

-- Debounce system
local requestCooldowns = {}
local COOLDOWN_TIME = 1 -- 1 second cooldown

-- Add the request handler with debounce
function RequestData.OnServerInvoke(player)
    local lastRequest = requestCooldowns[player]
    local currentTime = tick()
    
    if lastRequest and currentTime - lastRequest < COOLDOWN_TIME then
        print("Request denied - cooldown active for player:", player.Name)
        return nil
    end
    
    requestCooldowns[player] = currentTime
    
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        ReplicatedStorage:WaitForChild("DataLoaded"):FireClient(player, {
            coins = profile.Data.Coins,
            ownedMeat = profile.Data.OwnedMeat
        })
    end
end

-- Clean up cooldowns when player leaves
Players.PlayerRemoving:Connect(function(player)
    requestCooldowns[player] = nil
end)