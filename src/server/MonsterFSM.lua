-- MonsterFSM ModuleScript
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonsterFSM = {}
MonsterFSM.__index = MonsterFSM

-- Constants
local SIGHT_RANGE = 30
local DAMAGE = 30
local PATROL_SPEED = 40
local CHASE_SPEED = 24

-- Create debug remote event
local debugRemote = Instance.new("RemoteEvent")
debugRemote.Name = "MonsterDebugUpdate"
debugRemote.Parent = ReplicatedStorage

function MonsterFSM.new(monster)
    local self = setmetatable({}, MonsterFSM)
    
    -- Clean up any existing monster in workspace first
    if workspace:FindFirstChild("Monster") then
        workspace.Monster:Destroy()
    end
    
    -- Add stuck detection variables
    self.lastCheckPosition = Vector3.new(0, 0, 0)
    self.stuckTime = 0
    self.longTermStuckTime = 0
    self.lastCheckTime = os.clock()
    self.loopIterations = 0
    self.forceNewPath = false
    
    -- Add this with other state variables
    self.seeingPlayer = "None"
    
    -- References
    self.monster = monster:Clone()  -- Clone the template monster
    self.waypointsFolder = workspace:WaitForChild("MonsterWaypoints")
    self.respawnPoints = workspace:WaitForChild("RespawnPoints")
    
    -- Get random respawn point for initial spawn
    local respawnPoints = self.respawnPoints:GetChildren()
    local randomPoint = respawnPoints[math.random(1, #respawnPoints)]
    
    -- Set initial position and parent to workspace
    if randomPoint then
        self.monster:PivotTo(randomPoint.CFrame + Vector3.new(0, 3, 0))
        self.monster.Parent = workspace
    end
    
    -- Get references to parts
    self.humanoid = self.monster:WaitForChild("Humanoid")
    self.rootPart = self.monster:WaitForChild("HumanoidRootPart")
    
    -- Set network owner to nil for server control
    self.rootPart:SetNetworkOwner(nil)
    
    -- Path setup
    self.pathParams = {
        AgentHeight = 5,
        AgentRadius = 3,
        AgentCanJump = false
    }
    
    -- Raycast setup
    self.rayParams = RaycastParams.new()
    self.rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.rayParams.FilterDescendantsInstances = {self.monster}
    
    -- State variables
    self.lastPos = nil
    self.attackDebounce = false
    self.active = true
    self.currentTarget = nil
    
    -- Setup respawn handling
    self.humanoid.Died:Connect(function()
        self:onMonsterDied()
    end)
    
    -- Monitor for monster deletion
    self.monster.AncestryChanged:Connect(function()
        if not self.monster:IsDescendantOf(game) then
            self:onMonsterDied()
        end
    end)
    
    -- Initial spawn
    self:respawnMonster()
    
    return self
end
    function MonsterFSM:respawnMonster()
        -- Stop any existing monster first
        if workspace:FindFirstChild("Monster") then
            workspace.Monster:Destroy()
        end
        
        -- Reset stuck timers
        self.stuckTime = 0
        self.longTermStuckTime = 0
        
        -- Create fresh monster instance
        local monsterModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Monster")
        self.monster = monsterModel:Clone()
    
        -- Get random respawn point
        local respawnPoints = self.respawnPoints:GetChildren()
        local randomPoint = respawnPoints[math.random(1, #respawnPoints)]
    
        if randomPoint then
            -- Set position and parent
            self.monster:PivotTo(randomPoint.CFrame + Vector3.new(0, 3, 0))
            self.monster.Parent = workspace
        
            -- Update references
            self.humanoid = self.monster:WaitForChild("Humanoid")
            self.rootPart = self.monster:WaitForChild("HumanoidRootPart")
            self.rootPart:SetNetworkOwner(nil)
        
            -- Update raycast filter to use new monster model
            self.rayParams.FilterDescendantsInstances = {self.monster}
        
            -- Reset state
            self.humanoid.Health = self.humanoid.MaxHealth
            self.active = true
        
            -- Setup new connections
            self.humanoid.Died:Connect(function()
                if self.monster then
                    self:onMonsterDied()
                end
            end)
        
            self.monster.AncestryChanged:Connect(function(_, parent)
                if self.monster and not parent then
                    self:onMonsterDied()
                end
            end)
        end
    end
      function MonsterFSM:onMonsterDied()
          if not self.active then return end
    
          self.active = false  -- Stop all loops
          task.wait(0.1)  -- Give time for loops to end
    
          -- Force cleanup any existing monster
          if workspace:FindFirstChild("Monster") then
              workspace.Monster:Destroy()
          end
    
          self.monster = nil  -- Clear reference
    
          task.delay(1, function()
              self:respawnMonster()
              self.active = true  -- Ensure active is set to true
              self.lastCheckPosition = self.rootPart.Position  -- Reset position check
              self.longTermStuckTime = 0  -- Reset stuck time
              self:start()  -- Start the AI loops again
          end)
      end
  

    function MonsterFSM:canSeeTarget(target)
        local origin = self.rootPart.Position
        local targetPoint = target.HumanoidRootPart.Position
        local direction = (targetPoint - origin)
        local distance = direction.Magnitude
        
        if distance <= SIGHT_RANGE then
            -- Ensure direction is normalized * distance for accurate raycast
            direction = direction.Unit * distance
            local ray = workspace:Raycast(origin, direction, self.rayParams)
            
            -- Debug print for troubleshooting
            if ray then
                print("Ray hit:", ray.Instance:GetFullName())
            end
            
            if not ray or (ray.Instance and ray.Instance:IsDescendantOf(target)) then
                return true
            end
        end
        
        return false
    end

function MonsterFSM:findTarget()
    -- Keep current target if still valid and in range
    if self.currentTarget and 
       self.currentTarget:IsDescendantOf(game) and 
       self.currentTarget:FindFirstChild("Humanoid") and 
       self.currentTarget.Humanoid.Health > 0 then
        local distance = (self.rootPart.Position - self.currentTarget.HumanoidRootPart.Position).Magnitude
        if distance < SIGHT_RANGE and self:canSeeTarget(self.currentTarget) then
            return self.currentTarget
        end
    end
    
    -- Look for new target if current is invalid
    local nearestTarget
    local maxDistance = SIGHT_RANGE
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local target = player.Character
            local distance = (self.rootPart.Position - target.HumanoidRootPart.Position).Magnitude
            
            if distance < maxDistance and self:canSeeTarget(target) then
                nearestTarget = target
                maxDistance = distance
            end
        end
    end
    
    -- Update current target
    self.currentTarget = nearestTarget
    return nearestTarget
end

function MonsterFSM:getPath(destination)
    local path = PathfindingService:CreatePath(self.pathParams)
    path:ComputeAsync(self.rootPart.Position, destination.Position)
    return path
end

function MonsterFSM:attack(target)
    local distance = (self.rootPart.Position - target.HumanoidRootPart.Position).Magnitude
    
    if distance > 5 then
        self.humanoid.WalkSpeed = CHASE_SPEED
        self.humanoid:MoveTo(target.HumanoidRootPart.Position)
    elseif not self.attackDebounce then
        self.attackDebounce = true
        
        if self.monster.Head:FindFirstChild("AttackSound") then
            self.monster.Head.AttackSound:Play()
        end
        target.Humanoid.Health -= DAMAGE
        
        task.wait(0.5)
        self.attackDebounce = false
    end
end

function MonsterFSM:walkTo(destination)
    local path = self:getPath(destination)
    
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in pairs(path:GetWaypoints()) do
            if not self.active or self.forceNewPath then 
                self.forceNewPath = false
                return 
            end
            
            path.Blocked:Connect(function()
                path:Destroy()
            end)
            
            -- Check for target without clearing current target
            local target = self:findTarget()
            
            if target and target.Humanoid.Health > 0 then
                self.lastPos = target.HumanoidRootPart.Position
                self:attack(target)
                break
            else
                -- If we had a lastPos but lost sight, give player a chance to escape
                if self.lastPos then
                    task.delay(0.5, function()  -- Add 0.5s delay before speed change
                        if self.humanoid then
                            self.lastPos = nil
                            self.humanoid.WalkSpeed = PATROL_SPEED
                        end
                    end)
                    return -- Immediately return to start new patrol
                end
                
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                
                if self.lastPos then
                    self.humanoid.WalkSpeed = CHASE_SPEED
                    self.humanoid:MoveTo(self.lastPos)
                    self.humanoid.MoveToFinished:Wait()
                    self.lastPos = nil
                    self.humanoid.WalkSpeed = PATROL_SPEED
                    -- Don't clear currentTarget here, only clear lastPos
                else
                    self.humanoid:MoveTo(waypoint.Position)
                    self.humanoid.MoveToFinished:Wait()
                end
            end
        end
    end
end

function MonsterFSM:patrol()
    -- Only clear target if we can't see them anymore
    if self.currentTarget then
        if not self:canSeeTarget(self.currentTarget) then
            self.currentTarget = nil
        end
    end
    
    local waypoints = self.waypointsFolder:GetChildren()
    local randomWaypoint = waypoints[math.random(1, #waypoints)]
    self:walkTo(randomWaypoint)
end

function MonsterFSM:reportDebugState()
    if not self.monster then return end
    
    -- Get target name more reliably
    local targetName = "None"
    if self.currentTarget then
        local player = Players:GetPlayerFromCharacter(self.currentTarget)
        if player then
            targetName = player.Name
        end
    end
    
    local debugState = {
        Position = self.rootPart and self.rootPart.Position or Vector3.new(),
        Health = self.humanoid and self.humanoid.Health or 0,
        MaxHealth = self.humanoid and self.humanoid.MaxHealth or 0,
        WalkSpeed = self.humanoid and self.humanoid.WalkSpeed or 0,
        StuckTime = self.stuckTime,
        LongTermStuckTime = self.longTermStuckTime,
        LastCheckPosition = self.lastCheckPosition,
        IsAttacking = self.attackDebounce,
        LastTargetPosition = self.lastPos,
        Active = self.active,
        CurrentTarget = targetName,
        LoopIterations = self.loopIterations,
        ForceNewPath = self.forceNewPath,
        IsStuck = self.stuckTime > 1,
        SeeingPlayer = self.seeingPlayer
    }
    
    debugRemote:FireAllClients(debugState)
end

function MonsterFSM:start()
    -- Ensure we're not already running
    if not self.active then return end
    
    -- Reset state
    self.longTermStuckTime = 0
    self.stuckTime = 0
    self.lastCheckPosition = self.rootPart.Position
    
    -- Main AI loop
    task.spawn(function()
        while self.active do
            self.loopIterations += 1
            
            if self.forceNewPath then
                print("Forcing new path from main loop")
                self.forceNewPath = false
                pcall(function()
                    self:patrol()
                end)
            end
            
            -- Check if monster still exists before each patrol cycle
            if not self.monster:IsDescendantOf(game) or 
               not self.rootPart:IsDescendantOf(game) or 
               not self.humanoid:IsDescendantOf(game) then
                print("Monster or critical parts missing, respawning...")
                self:respawnMonster()
                if not self.active then break end
            end
            
            pcall(function()
                if not self.forceNewPath then
                    self:patrol()
                end
            end)
            
            task.wait(0.03)
        end
    end)
    
    -- Separate stuck detection loop
    task.spawn(function()
        while self.active do
            if self.monster and self.rootPart then
                local currentPos = self.rootPart.Position
                local currentTime = os.clock()
                local deltaTime = currentTime - self.lastCheckTime
                
                local xzDiff = Vector3.new(
                    currentPos.X - self.lastCheckPosition.X,
                    0,
                    currentPos.Z - self.lastCheckPosition.Z
                ).Magnitude
                
                if xzDiff < 0.1 then
                    self.stuckTime = self.stuckTime + deltaTime
                    if self.stuckTime > 0.15 then
                        print("Monster stuck, forcing new path")
                        self.stuckTime = 0
                        self.lastCheckPosition = currentPos
                        self.forceNewPath = true
                        self.humanoid:MoveTo(self.rootPart.Position)
                    end
                else
                    self.stuckTime = 0
                    self.lastCheckPosition = currentPos
                end
                
                self.lastCheckTime = currentTime
            end
            
            task.wait(0.05)
        end
    end)
    
    -- Debug update loop
    task.spawn(function()
        while self.active do
            pcall(function()
                self:reportDebugState()
            end)
            task.wait(0.015) -- Update at ~60fps
        end
    end)
    
    -- Add visibility check loop
    task.spawn(function()
        while self.active do
            local seenPlayer = "None"
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and 
                   player.Character:FindFirstChild("Humanoid") and 
                   player.Character.Humanoid.Health > 0 and
                   self:canSeeTarget(player.Character) then
                    seenPlayer = player.Name
                    break
                end
            end
            self.seeingPlayer = seenPlayer
            task.wait(0.01)
        end
    end)
    
    -- Add long-term stuck detection loop
    task.spawn(function()
        while self.active do
            if self.monster and self.monster:IsDescendantOf(game) and self.rootPart then
                local currentPos = self.rootPart.Position
                local xzDiff = Vector3.new(
                    currentPos.X - self.lastCheckPosition.X,
                    0,
                    currentPos.Z - self.lastCheckPosition.Z
                ).Magnitude
                
                if xzDiff < 0.1 then
                    self.longTermStuckTime += 0.02
                    if self.longTermStuckTime > 8 then
                        print("Monster stuck for too long, respawning...")
                        self:onMonsterDied()
                        break  -- Exit this loop after triggering respawn
                    end
                else
                    self.longTermStuckTime = 0
                end
            end
            task.wait(0.02)
        end
    end)
end

function MonsterFSM:stop()
    self.active = false
end

return MonsterFSM