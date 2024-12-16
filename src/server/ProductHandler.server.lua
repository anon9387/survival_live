local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataManager = require(script.Parent.DataManager)

-- Product IDs
local ALL_MEATS_PRODUCT_ID = 2665899719

-- Handle developer product purchases
local function onProductPurchase(receipt)
    local player = Players:GetPlayerByUserId(receipt.PlayerId)
    
    if not player then
        print("No player found for the purchase receipt. PlayerID:", receipt.PlayerId)
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    
    if receipt.ProductId == ALL_MEATS_PRODUCT_ID then
        print("Processing all meats purchase for:", player.Name)
        -- Give meats 1 through 15
        for i = 1, 15 do
            DataManager.AddMeat(player, tostring(i))
            task.wait(0.1) -- Adding a tiny wait of 0.1 seconds between each iteration
        end
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Connect purchase event
MarketplaceService.ProcessReceipt = onProductPurchase