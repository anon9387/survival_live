local Workspace = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")

local MonsterModule = require(rs:WaitForChild("shared"):WaitForChild("MonsterModule"))

local monsterTemplate = rs.Assets.monster
local monster = monsterTemplate:Clone()
monster.Parent = Workspace
local monsterAI = MonsterModule.new(monster)

-- Add the GetMonsterProperties RemoteFunction
local getMonsterPropertiesFunc = Instance.new("RemoteFunction")
getMonsterPropertiesFunc.Name = "GetMonsterProperties"
getMonsterPropertiesFunc.Parent = rs

function getMonsterPropertiesFunc.OnServerInvoke(player)
    local properties = {}
    for key, value in pairs(monsterAI) do
        if type(value) ~= "function" then
            properties[key] = value
        end
    end
    return properties
end

-- Set the network owner to nil (server) for all descendants
for _, descendant in ipairs(monster:GetDescendants()) do
    if descendant:IsA("BasePart") then
        descendant:SetNetworkOwner(nil)
    end
end

-- Adjust the seeing distance and chase distance if needed
monsterAI.seeingDistance = 50  -- Change this value to adjust the seeing distance
monsterAI.chaseDistance = 24   -- Change this value to adjust the close-range chase distance

-- Create debug spheres for chase and sight ranges
local function createDebugSphere(radius, color)
    local sphere = Instance.new("Part")
    sphere.Shape = Enum.PartType.Ball
    sphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    sphere.Color = color
    sphere.Material = Enum.Material.Neon
    sphere.Transparency = 0.95
    sphere.CanCollide = false
    sphere.Anchored = true
    sphere.Parent = monster

    return sphere
end

local chaseSphere = createDebugSphere(monsterAI.chaseDistance, Color3.new(1, 0, 0))  -- Red for chase range
local sightSphere = createDebugSphere(monsterAI.seeingDistance, Color3.new(0, 1, 0))  -- Green for sight range

-- Function to update the position of debug spheres
local function updateDebugSpheres()
    chaseSphere.Position = monster.PrimaryPart.Position
    sightSphere.Position = monster.PrimaryPart.Position
end

-- Add these functions after the createDebugSphere function

local pathParts = {}

local function createPathPart()
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.5, 0.5, 0.5)
    part.Color = Color3.new(1, 1, 0)  -- Yellow color for path parts
    part.Material = Enum.Material.Neon
    part.CanCollide = false
    part.Anchored = true
    part.Parent = Workspace
    return part
end

local function updateDebugPath(waypoints)
    -- Remove existing path parts
    for _, part in ipairs(pathParts) do
        part:Destroy()
    end
    pathParts = {}

    -- Create new path parts
    for _, waypoint in ipairs(waypoints) do
        local part = createPathPart()
        part.Position = waypoint.Position
        table.insert(pathParts, part)
    end
end

-- Function to respawn the monster
local function respawnMonster()
    monster:Destroy()
    monster = monsterTemplate:Clone()
    
    -- Unlock all parts in the monster model
    for _, descendant in ipairs(monster:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Locked = false
        end
    end
    
    monster.Parent = Workspace
    monsterAI = MonsterModule.new(monster)
    monster.PrimaryPart:SetNetworkOwner(nil)
    
    -- Respawn at a random respawn point
    local respawnPoints = Workspace.RespawnPoints:GetChildren()
    if #respawnPoints > 0 then
        local respawnPoint = respawnPoints[math.random(1, #respawnPoints)]
        monster:SetPrimaryPartCFrame(respawnPoint.CFrame + Vector3.new(0, 3, 0))
    else
        warn("No respawn points found for the monster!")
    end
    
    -- Recreate debug spheres
    sightSphere = createDebugSphere(monsterAI.seeingDistance, Color3.new(0, 1, 0))
    sightSphere.Parent = monster
end

-- Modify the main loop

respawnMonster()

while true do
    local state = monsterAI:update()
    
    if state == "Dead" then
        respawnMonster()
    else
        updateDebugSpheres()
        
        if state == "Patrolling" then
            local debugPath = monsterAI:getDebugPath()
            updateDebugPath(debugPath)
        else
            updateDebugPath({})  -- Clear the path when not patrolling
        end
    end
    
    task.wait(0.001)
end