warn("UI Script Starting...")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Get UI elements
local mainGui = script.Parent.Parent:WaitForChild("Main")
if not mainGui then
    warn("Failed to find Main GUI")
    return
end 
local shopButton = mainGui:WaitForChild("Left"):WaitForChild("Shop"):WaitForChild("Button")
local shopFrame = mainGui:WaitForChild("Shop")
local coinText = mainGui:WaitForChild("Left"):WaitForChild("Coin"):WaitForChild("TextLabel")

-- Set initial value to 0
coinText.Text = "0"

-- Connect to coin updates
local UpdateCoins = ReplicatedStorage:WaitForChild("UpdateCoins")
UpdateCoins.OnClientEvent:Connect(function(newAmount)
    coinText.Text = tostring(newAmount)
end)

-- Also connect to initial data load
local DataLoaded = ReplicatedStorage:WaitForChild("DataLoaded")
DataLoaded.OnClientEvent:Connect(function(data)
    coinText.Text = tostring(data.coins)
end)

-- Get the steak text label
local steakText = mainGui:WaitForChild("Collected"):WaitForChild("Steak"):WaitForChild("TextLabel")

-- Set initial value to 0/15
steakText.Text = "0/15"

-- Connect to meat updates
local UpdateMeat = ReplicatedStorage:WaitForChild("UpdateMeat")
UpdateMeat.OnClientEvent:Connect(function(newMeatList)
    steakText.Text = tostring(#newMeatList) .. "/15"
end)

-- Also connect to initial data load for meat count
DataLoaded.OnClientEvent:Connect(function(data)
    steakText.Text = tostring(#data.ownedMeat) .. "/15"
end)

-- Tween configuration
local tweenInfo = TweenInfo.new(
    0.1,                -- Duration
    Enum.EasingStyle.Back,  -- Easing style for bubbly effect
    Enum.EasingDirection.Out
)

local hoverTweenInfo = TweenInfo.new(
    0.2,                -- Longer duration for more bounce
    Enum.EasingStyle.Bounce,
    Enum.EasingDirection.Out,
    0,                  -- No repeat
    false,              -- Don't reverse
    0                   -- No delay
)

-- Initial state
shopFrame.Visible = false
local isOpen = false

-- Create tween goals
local openGoal = {
    Size = UDim2.new(0.6, 0, 0.6, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0)
}
local closedGoal = {
    Size = UDim2.new(0, 0, 0, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0)
}

-- Toggle function
local function toggleShop()
    isOpen = not isOpen
    shopFrame.Visible = true
    
    print("Shop toggled. Is open:", isOpen)  -- Debug print
    
    local targetGoal = isOpen and openGoal or closedGoal
    local tween = TweenService:Create(shopFrame, tweenInfo, targetGoal)
    
    tween:Play()
    
    if not isOpen then
        tween.Completed:Connect(function()
            shopFrame.Visible = false
        end)
    end
end

-- Connect button click
shopButton.MouseButton1Click:Connect(toggleShop)

-- Setup friend invite button
local SocialService = game:GetService("SocialService")
local friendsButton = mainGui:WaitForChild("Left"):WaitForChild("Friends"):WaitForChild("Button")

-- Function to check whether the player can send an invite
local function canSendGameInvite(sendingPlayer)
    local success, canSend = pcall(function()
        return SocialService:CanSendGameInviteAsync(sendingPlayer)
    end)
    return success and canSend
end

-- Connect friends button
friendsButton.MouseButton1Click:Connect(function()
    local canInvite = canSendGameInvite(player)
    if canInvite then
        SocialService:PromptGameInvite(player)
    else
        print("Player cannot send game invites")
    end
end)

-- Setup hover effects function
local function setupHoverEffect(item)
    if item:IsA("GuiObject") then
        -- Make sure the item can receive mouse input
        item.Active = true
        
        local originalSize = item.Size
        local hoverSize = originalSize + UDim2.new(0, 10, 0, 10)
        
        item.MouseEnter:Connect(function()
            print("Mouse entered:", item.Name)  -- Debug print
            local growTween = TweenService:Create(item, hoverTweenInfo, {
                Size = hoverSize
            })
            growTween:Play()
        end)
        
        item.MouseLeave:Connect(function()
            print("Mouse left:", item.Name)  -- Debug print
            local shrinkTween = TweenService:Create(item, hoverTweenInfo, {
                Size = originalSize
            })
            shrinkTween:Play()
        end)
    end
end

-- Setup rotation hover effect for ImageLabels
local function setupRotationEffect(item)
    for _, descendant in ipairs(item:GetDescendants()) do
        if descendant:IsA("ImageLabel") then
            descendant.Active = true
            
            local originalRotation = descendant.Rotation
            local hoverRotation = originalRotation + 10
            
            descendant.MouseEnter:Connect(function()
                print("Rotating:", descendant.Name)  -- Debug print
                local rotateTween = TweenService:Create(descendant, hoverTweenInfo, {
                    Rotation = hoverRotation
                })
                rotateTween:Play()
            end)
            
            descendant.MouseLeave:Connect(function()
                local unrotateTween = TweenService:Create(descendant, hoverTweenInfo, {
                    Rotation = originalRotation
                })
                unrotateTween:Play()
            end)
        end
    end
end

-- Setup hover effects for pass items
local passesFrame = shopFrame:WaitForChild("ScrollingFrame"):WaitForChild("Passes")
for _, item in ipairs(passesFrame:GetChildren()) do
    setupHoverEffect(item)
end

-- Setup hover effects for Left frame items
local leftFrame = mainGui:WaitForChild("Left")
for _, item in ipairs(leftFrame:GetChildren()) do
    setupHoverEffect(item)
    setupRotationEffect(item)
end

-- Add bubbly effect to Collected Steak More button
local steakMoreButton = mainGui:WaitForChild("Collected"):WaitForChild("Steak"):WaitForChild("More")
setupHoverEffect(steakMoreButton)

-- Connect exit button
local exitButton = shopFrame:WaitForChild("Exit")
exitButton.MouseButton1Click:Connect(function()
    if isOpen then
        toggleShop()
    end
end)

print("Script loaded, button connected") -- Debug print
