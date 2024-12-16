local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local monster = workspace:WaitForChild("monster")

local shakeIntensity = 0
local shakeDecay = 0.95
local minDistance = 0
local maxDistance = 50


-- Create ColorCorrection effect
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Parent = Lighting

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function getIntensityFromDistance(distance)
    return math.clamp(1 - ((distance - minDistance) / (maxDistance - minDistance)), 0, 1)
end

local function updateShake()
    if shakeIntensity > 0.01 then
        local randomAngle = math.rad(math.random() * 360)
        local shakeOffset = Vector3.new(
            math.cos(randomAngle) * shakeIntensity,
            math.sin(randomAngle) * shakeIntensity,
            0
        )
        
        camera.CFrame = camera.CFrame * CFrame.new(shakeOffset)
        shakeIntensity = shakeIntensity * shakeDecay
    else
        shakeIntensity = 0
    end
end

local function updateEffects()
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local monsterRoot = monster:FindFirstChild("HumanoidRootPart")
    if not monsterRoot then return end
    
    local distance = (rootPart.Position - monsterRoot.Position).Magnitude
    local intensity = getIntensityFromDistance(distance)
    
    -- Update shake intensity (increased by 30%)
    local targetShakeIntensity = intensity * 0.65
    shakeIntensity = lerp(shakeIntensity, targetShakeIntensity, 0.1)
    
    -- Update color correction (increased redness by 20%)
    local targetRedTint = intensity * 0.36 -- Max 36% red tint
    colorCorrection.TintColor = Color3.new(1, 1 - targetRedTint, 1 - targetRedTint)
end

RunService.RenderStepped:Connect(function(deltaTime)
    updateEffects()
    updateShake()
end)
  -- Clean up ColorCorrection when the script is destroyed
  game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
      if not game:GetService("Players"):FindFirstChild(game:GetService("Players").LocalPlayer.Name) then
          colorCorrection:Destroy()
      end
  end)
