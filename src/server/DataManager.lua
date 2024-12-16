local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = {}
local Profiles = nil

-- Initialize function to set up the reference to Profiles
function DataManager.Initialize(profilesTable)
    Profiles = profilesTable
    print("DataManager initialized with profilesTable.")
end

-- Function to get player's coins
function DataManager.GetCoins(player)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        print("Getting coins for player:", player.Name, "Coins:", profile.Data.Coins)
        return profile.Data.Coins
    end
    print("No active profile found for player:", player.Name)
    return 0
end

-- Function to add coins to a player
function DataManager.AddCoins(player, amount)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        profile.Data.Coins += amount
        print("Added coins to player:", player.Name, "New coin total:", profile.Data.Coins)
        ReplicatedStorage:WaitForChild("UpdateCoins"):FireClient(
            player, 
            profile.Data.Coins
        )
        return true
    end
    print("Failed to add coins to player:", player.Name)
    return false
end

-- Function to subtract coins from a player
function DataManager.SubtractCoins(player, amount)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        if profile.Data.Coins >= amount then
            profile.Data.Coins -= amount
            print("Subtracted coins from player:", player.Name, "New coin total:", profile.Data.Coins)
            ReplicatedStorage:WaitForChild("UpdateCoins"):FireClient(
                player, 
                profile.Data.Coins
            )
            return true
        else
            print("Not enough coins to subtract from player:", player.Name)
        end
    end
    print("Failed to subtract coins from player:", player.Name)
    return false
end

-- Function to reset player's coins
function DataManager.ResetCoins(player)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        profile.Data.Coins = 0
        print("Reset coins for player:", player.Name)
        ReplicatedStorage:WaitForChild("UpdateCoins"):FireClient(
            player, 
            profile.Data.Coins
        )
        return true
    end
    print("Failed to reset coins for player:", player.Name)
    return false
end

-- Function to get player's owned meat
function DataManager.GetMeat(player)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        print("Getting owned meat for player:", player.Name, "Owned meat:", profile.Data.OwnedMeat)
        return profile.Data.OwnedMeat
    end
    print("No active profile found for player:", player.Name)
    return {}
end

-- Function to add meat to a player
function DataManager.AddMeat(player, meatId)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        -- Check if player already has this meat
        if not table.find(profile.Data.OwnedMeat, meatId) then
            table.insert(profile.Data.OwnedMeat, meatId)
            print("Added meat to player:", player.Name, "Meat ID:", meatId)
            ReplicatedStorage:WaitForChild("UpdateMeat"):FireClient(
                player, 
                profile.Data.OwnedMeat
            )
            return true
        else
            print("Player already owns meat ID:", meatId)
        end
    end
    print("Failed to add meat to player:", player.Name)
    return false
end

-- Function to remove meat from a player
function DataManager.RemoveMeat(player, meatId)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        local index = table.find(profile.Data.OwnedMeat, meatId)
        if index then
            table.remove(profile.Data.OwnedMeat, index)
            print("Removed meat from player:", player.Name, "Meat ID:", meatId)
            ReplicatedStorage:WaitForChild("UpdateMeat"):FireClient(
                player, 
                profile.Data.OwnedMeat
            )
            return true
        else
            print("Player does not own meat ID:", meatId)
        end
    end
    print("Failed to remove meat from player:", player.Name)
    return false
end

-- Function to reset player's meat
function DataManager.ResetMeat(player)
    local profile = Profiles[player]
    if profile and profile:IsActive() then
        profile.Data.OwnedMeat = {}
        print("Reset owned meat for player:", player.Name)
        ReplicatedStorage:WaitForChild("UpdateMeat"):FireClient(
            player, 
            profile.Data.OwnedMeat
        )
        return true
    end
    print("Failed to reset meat for player:", player.Name)
    return false
end

return DataManager