local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mainGui = player:WaitForChild("PlayerGui"):WaitForChild("Main")
local steakMoreButton = mainGui:WaitForChild("Collected"):WaitForChild("Steak"):WaitForChild("More"):WaitForChild("Button")

-- Product IDs
local ALL_MEATS_PRODUCT_ID = 2665899719

-- Function to prompt purchase
local function promptAllMeatsPurchase()
    MarketplaceService:PromptProductPurchase(player, ALL_MEATS_PRODUCT_ID)
end

-- Connect button
steakMoreButton.MouseButton1Click:Connect(promptAllMeatsPurchase)
