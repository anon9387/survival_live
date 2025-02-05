
game.Players.PlayerAdded:Connect(function(player)
    print("Player added:", player.Name)
    player.CharacterAdded:Connect(function(character)
        print("Character added for player:", player.Name)
        character.Humanoid.Died:Connect(function()
            print("Player died:", player.Name)
        end)
    end)
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create a new folder in ReplicatedStorage to store the cloned meats
local meatsFolder = Instance.new("Folder")
meatsFolder.Name = "MeatsClones"
meatsFolder.Parent = ReplicatedStorage

-- Clone everything from Workspace.Meats
if workspace:FindFirstChild("Meats") then
    for _, meat in pairs(workspace.Meats:GetChildren()) do
        local clonedMeat = meat:Clone()
        clonedMeat.Parent = meatsFolder
        meat:Destroy() -- Destroy the original meat after cloning
    end
end



