local Players = game:GetService("Players")
local DataManager = require(script.Parent.DataManager)

-- Command format in console
-- :data [get/add/sub/giveall] [player_name] [coins/meat] [amount/meatId]
-- :data reset nekotorus coins
-- :data reset nekotorus meat
-- :data get nekotorus coins
-- :data get nekotorus meat
-- :data add nekotorus coins 100
-- :data add nekotorus meat 1
-- :data sub nekotorus coins 100
-- :data sub nekotorus meat 1
-- :data giveall nekotorus meat

game:GetService("Players").PlayerAdded:Connect(function(player)
    print("Player added:", player.Name)
    if player:GetRankInGroup(33062890) >= 23 then -- Admin rank
        print("Admin detected:", player.Name)
        player.Chatted:Connect(function(message)
            print("Message received:", message)
            if message:sub(1,5) == ":data" then
                print("Data command detected")
                local args = message:split(" ")
                print("Args:", table.concat(args, ", "))
                
                local action = args[2]
                local targetName = args[3]
                local dataType = args[4]
                local value = args[5]
                
                print("Processing command:", action, targetName, dataType, value)
                
                local targetPlayer = Players:FindFirstChild(targetName)
                
                if targetPlayer then
                    print("Target player found:", targetPlayer.Name)
                    if action == "giveall" and dataType == "meat" then
                        print("Giving all meats to", targetPlayer.Name)
                        -- Give meats 1 through 15
                        for i = 1, 15 do
                            DataManager.AddMeat(targetPlayer, tostring(i))
                        end
                    elseif action == "reset" then
                        if dataType == "meat" then
                            print("Resetting meat for", targetPlayer.Name)
                            DataManager.ResetMeat(targetPlayer)
                        elseif dataType == "coins" then
                            print("Resetting coins for", targetPlayer.Name)
                            DataManager.ResetCoins(targetPlayer)
                        end
                    elseif action == "get" then
                        if dataType == "coins" then
                            print("Getting coins for", targetPlayer.Name)
                            DataManager.GetCoins(targetPlayer)
                        elseif dataType == "meat" then
                            print("Getting meat for", targetPlayer.Name)
                            DataManager.GetMeat(targetPlayer)
                        end
                    elseif action == "add" then
                        if dataType == "coins" then
                            print("Adding coins for", targetPlayer.Name, "amount:", value)
                            DataManager.AddCoins(targetPlayer, tonumber(value))
                        elseif dataType == "meat" then
                            print("Adding meat for", targetPlayer.Name, "meatId:", value)
                            DataManager.AddMeat(targetPlayer, value)
                        end
                    elseif action == "sub" then
                        if dataType == "coins" then
                            print("Subtracting coins for", targetPlayer.Name, "amount:", value)
                            DataManager.SubtractCoins(targetPlayer, tonumber(value))
                        elseif dataType == "meat" then
                            print("Removing meat for", targetPlayer.Name, "meatId:", value)
                            DataManager.RemoveMeat(targetPlayer, value)
                        end
                    end
                else
                    print("Target player not found:", targetName)
                end
            end
        end)
    else
        print("Non-admin player:", player.Name)
    end
end)