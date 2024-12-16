

local RunService = game:GetService("RunService")

local function monitorPhysicsFPS()
    while true do
        local fps = workspace:GetRealPhysicsFPS()
        print("Current Physics FPS:", fps)
        task.wait(1)
    end
end

local function testFunc()
    print("amongus 20e92913")
end


testFunc()

task.spawn(monitorPhysicsFPS)
