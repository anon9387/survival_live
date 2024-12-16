local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MonsterModule = {}

function MonsterModule.new(monster)
    local self = {
        monster = monster,
        humanoid = monster:WaitForChild("Humanoid"),
        rootPart = monster:WaitForChild("HumanoidRootPart"),
        head = monster:WaitForChild("Head"),
        path = nil,
        waypoints = {},
        currentWaypointIndex = 0,
        state = "Idle",
        lastSeenPlayer = 0,
        targetPlayer = nil,
        seeingDistance = 50,
        chaseDistance = 0,
        patrolWalkSpeed = 40,
        chaseWalkSpeed = 10,
        lastPosition = Vector3.new(0, 0, 0),
        stuckTime = 0,
        totalStuckTime = 0,
        successfulMovements = 0,
        pathfindingCooldown = 25,
        pathfindingCounter = 0,
        sightRaycastSuccess = false,  -- New property added here
    }
      -- Function to check if the monster can see a player
      function self:canSeePlayer(playerRoot)
          -- Reset the sightRaycastSuccess at the start of the function
          self.sightRaycastSuccess = false

          local distance = (playerRoot.Position - self.rootPart.Position).Magnitude
          if distance <= self.chaseDistance then
              self.sightRaycastSuccess = true
              return true
          end
          if distance > self.seeingDistance then
              return false
          end

          local raycastParams = RaycastParams.new()
          raycastParams.FilterDescendantsInstances = {self.monster}
          raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

          local positions = {}
          local offsets = {
              Vector3.new(-2, -4, 0),
              Vector3.new(2, -4, 0),
              Vector3.new(-2, 4, 0),
              Vector3.new(2, 4, 0),
          }

          local debugParts = {}

          -- Generate positions and create debug parts
          for _, offset in ipairs(offsets) do
              local position = self.rootPart.Position + self.rootPart.CFrame:VectorToWorldSpace(offset)
              table.insert(positions, position)

              -- Create a debug part at the position
              local debugPart = Instance.new("Part")
              debugPart.Size = Vector3.new(0.2, 0.2, 0.2)
              debugPart.Position = position
              debugPart.Anchored = true
              debugPart.CanCollide = false
              debugPart.Color = Color3.new(1, 0, 0) -- Red color
              debugPart.Transparency = 0.5
              debugPart.Parent = Workspace
              table.insert(debugParts, debugPart)
          end

          -- Perform raycasts from each position to the player's root part
          for i, position in ipairs(positions) do
              local direction = playerRoot.Position - position
              local raycastResult = Workspace:Raycast(position, direction.Unit * direction.Magnitude, raycastParams)
              
              -- Update debug part color based on raycast result
              if raycastResult and raycastResult.Instance:IsDescendantOf(playerRoot.Parent) then
                  debugParts[i].Color = Color3.new(0, 1, 0) -- Green if hit player
              else
                  debugParts[i].Color = Color3.new(1, 0, 0) -- Red if didn't hit player
                  self.sightRaycastSuccess = false
                  
                  -- Remove debug parts after a delay
                  task.delay(2, function()
                      for _, part in ipairs(debugParts) do
                          part:Destroy()
                      end
                  end)
                  
                  return false
              end
          end

          -- Remove debug parts after a delay
          task.delay(2, function()
              for _, part in ipairs(debugParts) do
                  part:Destroy()
              end
          end)

          self.sightRaycastSuccess = true  -- All raycasts were successful
          return true
      end    -- Function to find the nearest player within seeing distance
    function self:findNearestPlayer()
        local nearestPlayer = nil
        local shortestDistance = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                local playerRoot = character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    local distance = (playerRoot.Position - self.rootPart.Position).Magnitude
                    if distance < shortestDistance and distance <= self.seeingDistance then
                        shortestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
        return nearestPlayer
    end

    -- Updated function to chase a player
    function self:chasePlayer()
        if not self.targetPlayer then return end
        local character = self.targetPlayer.Character
        if not character then return end
        local playerRoot = character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end
        if self:canSeePlayer(playerRoot) then
            self.lastSeenPlayer = tick()
            self.humanoid:MoveTo(playerRoot.Position)
        elseif tick() - self.lastSeenPlayer > 1 then
            self.state = "Patrolling"
            self.targetPlayer = nil
            -- Reset the patrol path to a new random waypoint
            self.path = nil
            self.waypoints = {}
            self.currentWaypointIndex = 0
            self.pathfindingCounter = self.pathfindingCooldown  -- Ensure a new path is generated immediately
        end
    end

    -- Function to get a random waypoint
    function self:getRandomWaypoint()
        local waypointsFolder = Workspace:FindFirstChild("MonsterWaypoints")
        if not waypointsFolder then return nil end
        local waypoints = waypointsFolder:GetChildren()
        if #waypoints == 0 then return nil end
        return waypoints[math.random(1, #waypoints)]
    end

    -- Updated function for monster patrolling behavior
    function self:patrol()
        if not self.path or self.currentWaypointIndex > #self.waypoints then
            if self.pathfindingCounter >= self.pathfindingCooldown then
                self.pathfindingCounter = 0
                print("Debug: Creating new path for patrol")
                local randomWaypoint = self:getRandomWaypoint()
    
                if not randomWaypoint then
                    print("Debug: No random waypoint found")
                    return
                end
                self.path = PathfindingService:CreatePath({
                    AgentRadius = 5,
                    AgentHeight = 6,
                    AgentCanJump = false,
                    Costs = {
                        Water = 20,
                        Grass = 5,
                    }
                })
                print("Debug: Computing path to random waypoint")
                self.path:ComputeAsync(self.rootPart.Position, randomWaypoint.Position)
                if self.path.Status == Enum.PathStatus.Success then
                    print("Debug: Path computed successfully")
                    self.waypoints = self.path:GetWaypoints()
                    self.currentWaypointIndex = 2  -- Start from the second waypoint
                else
                    print("Debug: Path computation failed")
                    self.path = nil
                    self.waypoints = {}
                    self.currentWaypointIndex = 0
                    return
                end
            else
                -- Do not attempt to create a new path yet
                return
            end
        end
    
        if self.currentWaypointIndex <= #self.waypoints then
            local nextWaypoint = self.waypoints[self.currentWaypointIndex]
            local deltaPosition = nextWaypoint.Position - self.rootPart.Position
            local distance = Vector2.new(deltaPosition.X, deltaPosition.Z).Magnitude
    
            if distance <= 1 then  -- Consider the waypoint reached if within 1 stud
                self.currentWaypointIndex += 1
            else
                self.humanoid:MoveTo(nextWaypoint.Position)
            end
        else
            print("Debug: Reached end of waypoints")
        end

    end
    

    -- Add this function to the MonsterModule
    function self:getDebugPath()
        if self.path and self.path.Status == Enum.PathStatus.Success then
            return self.path:GetWaypoints()
        end
        return {}
    end

    -- Add this function to reset the monster at a respawn point
    function self:resetAtRespawnPoint()
        local respawnPoints = Workspace.RespawnPoints:GetChildren()
        if #respawnPoints > 0 then
            local nearestRespawnPoint = nil
            local shortestDistance = math.huge
            local currentPosition = self.rootPart.Position

            for _, respawnPoint in ipairs(respawnPoints) do
                local distance = (respawnPoint.Position - currentPosition).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestRespawnPoint = respawnPoint
                end
            end

            if nearestRespawnPoint then
                self.rootPart.CFrame = nearestRespawnPoint.CFrame + Vector3.new(0, 3, 0)
            end

            self.path = nil
            self.waypoints = {}
            self.currentWaypointIndex = 0
            self.state = "Patrolling"
            self.stuckTime = 0
            self.totalStuckTime = 0
        end
    end

    -- Updated main update function for monster behavior
    function self:update()
        if not self.monster:IsDescendantOf(Workspace) or self.humanoid.Health <= 0 then
            return "Dead"
        end

        local currentPosition = self.rootPart.Position
        -- Create Vector2 instances for current and last positions using x and z coordinates
        local currentXZ = Vector2.new(currentPosition.X, currentPosition.Z)
        local lastXZ = Vector2.new(self.lastPosition.X, self.lastPosition.Z)
        -- Calculate the movement difference on the x and z axes
        if (currentXZ - lastXZ).Magnitude < 0.1 then
            self.stuckTime += 0.01
            self.totalStuckTime += 0.01
            self.successfulMovements = 0
            print("Monster is stuck. Stuck time: " .. self.stuckTime .. ", Total stuck time: " .. self.totalStuckTime)
        else
            self.stuckTime = 0
            self.successfulMovements += 1
            print("Monster is moving normally. Successful movements: " .. self.successfulMovements)

            if self.successfulMovements >= 10 then
                self.totalStuckTime = 0
                print("Monster has moved successfully for 10 iterations. Resetting total stuck time.")
            end
        end
        self.lastPosition = currentPosition
        self.pathfindingCounter += 1
        if self.stuckTime >= 0.3 then
            self.path = nil
            self.waypoints = {}
            self.currentWaypointIndex = 0
            print("Monster has been stuck for 0.3 second. Resetting path.")
        end

        if self.totalStuckTime >= 7 then
            print("Monster has been stuck for a total of 7 seconds. Resetting at respawn point.")
            self:resetAtRespawnPoint()
        end

        local nearestPlayer = self:findNearestPlayer()
        if nearestPlayer and self:canSeePlayer(nearestPlayer.Character.HumanoidRootPart) then
            self.state = "Chasing"
            self.targetPlayer = nearestPlayer
            self.lastSeenPlayer = tick()
            self.humanoid.WalkSpeed = self.chaseWalkSpeed
            self:chasePlayer()
        elseif self.state == "Chasing" then
            self:chasePlayer()
        else
            self.state = "Patrolling"
            self.humanoid.WalkSpeed = self.patrolWalkSpeed
            self:patrol()
        end

        return self.state
    end    return self

end
return MonsterModule

