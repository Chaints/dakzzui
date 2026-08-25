print("[Bounty Hunter] Menjalankan inisialisasi awal (JSON Persistent & Modular UI)...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- GLOBAL DEFAULT CONFIGURATIONS
-- ==========================================
_G.AutoHuntEnabled = _G.AutoHuntEnabled ~= nil and _G.AutoHuntEnabled or false
_G.CustomFlightSpeed = _G.CustomFlightSpeed or 300
_G.CombatConfig = _G.CombatConfig or {
    ["Sword"] = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Fruit"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}},
    ["Gun"]   = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Melee"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}}
}

-- ==========================================
-- JSON PERSISTENT CONFIG SYSTEM (AUTO SAVE/LOAD)
-- ==========================================
local ConfigFileName = "BountyHunterConfig.json"

local function saveConfig()
    pcall(function()
        if writefile then
            local data = {
                AutoHunt = _G.AutoHuntEnabled,
                FlightSpeed = _G.CustomFlightSpeed,
                Combat = _G.CombatConfig
            }
            writefile(ConfigFileName, HttpService:JSONEncode(data))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(ConfigFileName) then
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(decoded) == "table" then
                if decoded.AutoHunt ~= nil then _G.AutoHuntEnabled = decoded.AutoHunt end
                if decoded.FlightSpeed then _G.CustomFlightSpeed = decoded.FlightSpeed end
                if type(decoded.Combat) == "table" then _G.CombatConfig = decoded.Combat end
                print("[Bounty Hunter] Konfigurasi JSON berhasil dimuat!")
            end
        end
    end)
end

loadConfig()

-- ==========================================
-- SMART UI PARENTING & UI CLEANUP
-- ==========================================
local SafeUIParent
pcall(function() SafeUIParent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
if not SafeUIParent or not pcall(function() return SafeUIParent.Name end) then
    SafeUIParent = LocalPlayer:WaitForChild("PlayerGui", 10)
end

pcall(function()
    if SafeUIParent and SafeUIParent:FindFirstChild("BountyHunterDashboard") then SafeUIParent.BountyHunterDashboard:Destroy() end
    if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end
end)

-- ==========================================
-- LOAD UI MODULE (ui.lua)
-- ==========================================
local UI_RAW_URL = "https://raw.githubusercontent.com/Chaints/dakzzui/main/ui.lua"

local UIModule
do
    local ok, result = pcall(function() return loadstring(game:HttpGet(UI_RAW_URL))() end)
    if ok and result then UIModule = result else warn("[Bounty Hunter] Gagal load ui.lua:", result) end
end

local state = {
    currentTargetPlayer = nil,
    manualSkipList = {},
    manualSkipRequested = false,
    isHunting = false,
    stopRequested = false,
    saveConfig = saveConfig -- Kirim fungsi save ke UI biar slider/tombol skill bisa autosave
}

local UI
if UIModule then
    local ok, result = pcall(function() return UIModule.Init(SafeUIParent, state) end)
    if ok then UI = result else warn("[Bounty Hunter] Gagal inisialisasi ui.lua:", result) end
end

local totalHadiahDiperoleh = 0

local function createNewLayoutUI() if UI and not state.stopRequested then UI.createNewLayoutUI() end end
local function updateHUDDisplay(player) if UI and not state.stopRequested then UI.updateHUDDisplay(player, totalHadiahDiperoleh) end end
local function addTargetLogEntry(entryText) if UI and not state.stopRequested then UI.addTargetLogEntry(entryText) end end

-- Sync loop
task.spawn(function()
    while not state.stopRequested do
        task.wait(0.1)
        state.isHunting = _G.AutoHuntEnabled
    end
end)

-- ==========================================
-- REMOTE EVENTS INITIALIZER & VARIABLES
-- ==========================================
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 5)
local Net = ModulesFolder and ModulesFolder:WaitForChild("Net", 5)
local RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net and Net:WaitForChild("RE/RegisterHit")

local JedaSenjataAsli = 0.4000000059604645
local TokenKeamanan = "083cf9b7"

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = RemotesFolder and RemotesFolder:WaitForChild("CommF_", 3)
local CommE = RemotesFolder and RemotesFolder:WaitForChild("CommE", 3)
local ClockFolder = RemotesFolder and RemotesFolder:FindFirstChild("Clock")
local MasterClockRemote = ClockFolder and ClockFolder:WaitForChild("DelayedRequestFunction", 3)

local M1_ATTACK_RANGE = 17.0   
local SKILL_ATTACK_RANGE = 10.0 
local MAGNET_RANGE = 8.0       

local combatConnection, noclipConnection, skillThread, m1Thread
local currentTargetPlayer = nil 
local hasTeleportedToIsland = false 
local isHunting = false
local isEmergencyRetreating = false

local bountyBlacklist = {} 
local activeESP = {}
local isTargetInActiveFight = false 

-- ==========================================
-- PERSISTENT SERVER HOP QUEUE 
-- ==========================================
_G.PersistentReadyJobIds = _G.PersistentReadyJobIds or {}
if not _G.ServerScannerInitialized then
    _G.ServerScannerInitialized = true
    task.spawn(function()
        local serverBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        local currentPage = 1
        while task.wait(0.5) do
            if #_G.PersistentReadyJobIds >= 2 or currentPage > 200 then break end
            if serverBrowser then
                local success, servers = pcall(function() return serverBrowser:InvokeServer(currentPage) end)
                if success and type(servers) == "table" then
                    for jobId, serverData in pairs(servers) do
                        local count = type(serverData) == "table" and (serverData.Count or serverData.Players) or (type(serverData) == "number" and serverData or 0)
                        if count > 0 and count < 7 and jobId ~= game.JobId then
                            local alreadyInQueue = false
                            for _, qId in ipairs(_G.PersistentReadyJobIds) do if qId == jobId then alreadyInQueue = true break end end
                            if not alreadyInQueue then
                                table.insert(_G.PersistentReadyJobIds, jobId)
                                if #_G.PersistentReadyJobIds >= 2 then break end
                            end
                        end
                    end
                end
                currentPage = currentPage + 1
            end
        end
    end)
end

-- ==========================================
-- ESP SYSTEM
-- ==========================================
local function createPlayerESP(player)
    if player == LocalPlayer or not SafeUIParent then return end
    pcall(function()
        local guiName = "ESP_" .. player.Name
        local existingGui = SafeUIParent:FindFirstChild(guiName)
        if existingGui then existingGui:Destroy() end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = guiName
        billboardGui.AlwaysOnTop = true
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.Parent = SafeUIParent

        local textLabel = Instance.new("TextLabel", billboardGui)
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.2
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 14
        textLabel.Text = player.Name

        activeESP[player] = {Gui = billboardGui, Label = textLabel}

        local connection
        connection = RunService.RenderStepped:Connect(function()
            pcall(function()
                if not player or not player.Parent then
                    billboardGui:Destroy() activeESP[player] = nil connection:Disconnect() return
                end
                local char, myChar = player.Character, LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                if root and myRoot then
                    billboardGui.Adornee = root
                    local distance = math.floor((myRoot.Position - root.Position).Magnitude)
                    if player == state.currentTargetPlayer then
                        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        textLabel.Text = "[TARGET] " .. player.Name .. " [" .. distance .. " studs]"
                    else
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        textLabel.Text = player.Name .. " [" .. distance .. " studs]"
                    end
                else
                    billboardGui.Adornee = nil
                end
            end)
        end)
    end)
end

for _, p in pairs(Players:GetPlayers()) do createPlayerESP(p) end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(function(p)
    if activeESP[p] then pcall(function() activeESP[p].Gui:Destroy() end) activeESP[p] = nil end
end)

-- ==========================================
-- UTILITIES & SAFETY
-- ==========================================
local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function getOrCreatePlatform()
    local platform = Workspace:FindFirstChild("AntiWaterPlatform")
    if not platform then
        platform = Instance.new("Part")
        platform.Name = "AntiWaterPlatform"
        platform.Size = Vector3.new(10, 1, 10)
        platform.Transparency = 1
        platform.Anchored = true
        platform.CanCollide = true
        platform.Parent = Workspace
    end
    return platform
end

local function autoOnHakiAndInstinct()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        if not char:FindFirstChild("HasBuso") then if CommF then CommF:InvokeServer("Buso") end end
        if CommE then CommE:FireServer("Ken", true) end
    end)
end

local function activateRaceV3AndV4()
    pcall(function() 
        if CommE then CommE:FireServer("ActivateAbility"); CommE:FireServer("ActivateAwakening") end 
    end)
end

local function equipWeaponCategory(categoryName)
    local backpack, char = LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character
    if not backpack or not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():find(categoryName:lower()) or (currentTool:FindFirstChild("ToolTip") and tostring(currentTool.ToolTip.Value):lower():find(categoryName:lower()))) then 
        return currentTool 
    end

    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find(categoryName:lower()) or (item:FindFirstChild("ToolTip") and tostring(item.ToolTip.Value):lower():find(categoryName:lower()))) then
            local hum = char:WaitForChild("Humanoid", 2)
            if hum then hum:EquipTool(item); task.wait(0.05); return item end
        end
    end
    return nil
end

-- ==========================================
-- PVP VALIDATION
-- ==========================================
local function isAlly(targetPlayer)
    if not targetPlayer then return true end
    if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team and LocalPlayer.Team.Name == "Marines" then return true end
    local myCrew = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Crew")
    local targetCrew = targetPlayer:FindFirstChild("Data") and targetPlayer.Data:FindFirstChild("Crew")
    if myCrew and targetCrew and myCrew.Value ~= "" and myCrew.Value == targetCrew.Value then return true end
    return false
end

local function isPlayerEligibleForPvP(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent or targetPlayer == LocalPlayer then return false end
    
    if isTargetInActiveFight and targetPlayer == currentTargetPlayer then
        local char = targetPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then return true end
    end

    if state.manualSkipList[targetPlayer.Name] then return false end
    if bountyBlacklist[targetPlayer.Name] and os.time() < bountyBlacklist[targetPlayer.Name] then return false end
    if targetPlayer:FindFirstChild("DiedRecently") or (targetPlayer:FindFirstChild("PlayerStats") and targetPlayer.PlayerStats:FindFirstChild("DiedRecently")) then return false end
    
    local char = targetPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChild("Humanoid")
    if not char or not humanoid or humanoid.Health <= 0 or not root then return false end
    if char:FindFirstChild("DiedRecently") or char:FindFirstChildOfClass("ForceField") or char:FindFirstChild("SafeZone") then return false end
    
    if char:GetAttribute("SafeZone") or targetPlayer:GetAttribute("SafeZone") or char:GetAttribute("PvPDisabled") or targetPlayer:GetAttribute("PvPDisabled") then return false end
    if targetPlayer:FindFirstChild("PvPDisabled") and targetPlayer.PvPDisabled.Value == true then return false end
    
    local dataFolder = targetPlayer:FindFirstChild("Data")
    if dataFolder then
        local safeZoneVal = dataFolder:FindFirstChild("SafeZone")
        if safeZoneVal and safeZoneVal.Value == true then return false end
        local pvpVal = dataFolder:FindFirstChild("PvP") or dataFolder:FindFirstChild("PvPDisabled")
        if pvpVal and (pvpVal.Value == false or (pvpVal.Value == true and pvpVal.Name:lower():find("disabled"))) then return false end
    end

    if isAlly(targetPlayer) then return false end
    return true
end

-- ==========================================
-- ATTACK LOOPS
-- ==========================================
local function startM1Loop(targetPlayer)
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    m1Thread = task.spawn(function()
        while isHunting and _G.AutoHuntEnabled and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local tChar = targetPlayer and targetPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.Health > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                if currentHPPercent <= 80 and currentHPPercent >= 50 then
                    isTargetInActiveFight = true
                    equipWeaponCategory("Melee")
                    if (myRoot.Position - tRoot.Position).Magnitude <= M1_ATTACK_RANGE then
                        for comboKe = 1, 4 do
                            if RegisterAttack then RegisterAttack:FireServer(JedaSenjataAsli, comboKe) end
                            local partTarget = tRoot or tChar:FindFirstChild("UpperTorso")
                            if partTarget and RegisterHit then RegisterHit:FireServer(partTarget, {}, TokenKeamanan) end
                        end
                    end
                end
            end
            task.wait(0.01) 
        end
    end)
end

local function startSkillLoop(targetPlayer)
    if skillThread then task.cancel(skillThread) skillThread = nil end
    skillThread = task.spawn(function()
        local weaponCategories = {"Melee", "Fruit", "Sword", "Gun"}
        local skillKeys = {"Z", "X", "C", "V", "F"}
        local keyCodeMap = {["Z"]=Enum.KeyCode.Z, ["X"]=Enum.KeyCode.X, ["C"]=Enum.KeyCode.C, ["V"]=Enum.KeyCode.V, ["F"]=Enum.KeyCode.F}

        while isHunting and _G.AutoHuntEnabled and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local tChar = targetPlayer and targetPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.Health > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                if (currentHPPercent > 80 and currentHPPercent <= 100) or (currentHPPercent < 50) then
                    isTargetInActiveFight = true
                    if (myRoot.Position - tRoot.Position).Magnitude <= SKILL_ATTACK_RANGE then 
                        autoOnHakiAndInstinct()
                        activateRaceV3AndV4()

                        for _, category in ipairs(weaponCategories) do
                            if not currentTargetPlayer or not isPlayerEligibleForPvP(currentTargetPlayer) then break end
                            local equippedTool = equipWeaponCategory(category)
                            if equippedTool then
                                local targetPos = tRoot.Position
                                local toolRemote = equippedTool:FindFirstChild("RemoteEvent") or equippedTool:FindFirstChildOfClass("RemoteEvent")
                                if toolRemote then
                                    for _, key in ipairs(skillKeys) do
                                        local catConfig = _G.CombatConfig[category]
                                        if catConfig and catConfig[key] and catConfig[key].On then
                                            pcall(function()
                                                if key == "X" then toolRemote:FireServer("X", false) else toolRemote:FireServer(key, targetPos) end
                                                task.spawn(function()
                                                    VirtualInputManager:SendKeyEvent(true, keyCodeMap[key], false, game)
                                                    task.wait(0.05)
                                                    VirtualInputManager:SendKeyEvent(false, keyCodeMap[key], false, game)
                                                end)
                                            end)
                                            task.wait(0.08)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1) 
        end
    end)
end

-- ==========================================
-- EMERGENCY ESCAPE
-- ==========================================
local function handleEmergencyRetreat()
    if isEmergencyRetreating then return end
    isEmergencyRetreating = true
    enableNoclip()
    local escapeConnection
    escapeConnection = RunService.RenderStepped:Connect(function(deltaTime)
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not hum or not root or hum.Health <= 0 then return end
            
            if (hum.Health / hum.MaxHealth) * 100 >= 50 or not _G.AutoHuntEnabled then
                if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
                return
            end
            
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = root.CFrame + Vector3.new(0, _G.CustomFlightSpeed * deltaTime, 0)
        end)
    end)
    while escapeConnection and _G.AutoHuntEnabled do task.wait(0.2) end
    isEmergencyRetreating = false
    disableNoclip()
end

-- ==========================================
-- FLY ENGINE
-- ==========================================
local function flyTowardsTarget(targetRoot)
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    enableNoclip()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:WaitForChild("Humanoid", 5)
    if not myRoot or not myHumanoid then return end
    myHumanoid.AutoRotate = false

    combatConnection = RunService.RenderStepped:Connect(function(deltaTime)
        pcall(function()
            if not isPlayerEligibleForPvP(currentTargetPlayer) or state.manualSkipRequested or isEmergencyRetreating or not _G.AutoHuntEnabled then
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end 
                return
            end
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")

            if root and humanoid and humanoid.Health > 0 and targetRoot and targetRoot.Parent then
                root.Anchored = false
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                local targetPos = targetRoot.Position
                local currentPos = root.Position
                
                local camera = workspace.CurrentCamera
                if camera then camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPos), 0.75) end

                local straightLockCFrame = targetRoot.CFrame * CFrame.new(0, 0, MAGNET_RANGE)
                local targetGoalPos = straightLockCFrame.Position
                local safeDelta = math.clamp(deltaTime, 0.01, 0.033)

                if (targetPos - currentPos).Magnitude > MAGNET_RANGE then
                    local direction = (targetGoalPos - currentPos)
                    local maxStep = math.min(_G.CustomFlightSpeed * safeDelta, direction.Magnitude)
                    local hoverPos = currentPos + (direction.Unit * maxStep)
                    root.CFrame = CFrame.new(hoverPos) * CFrame.lookAt(hoverPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)).Rotation
                else
                    root.CFrame = CFrame.new(targetGoalPos) * CFrame.lookAt(targetGoalPos, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)).Rotation
                end

                getOrCreatePlatform().CFrame = CFrame.new(root.Position - Vector3.new(0, 4.2, 0))
            else
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end
            end
        end)
    end)
end

-- ==========================================
-- HUNTING MAIN LOOP
-- ==========================================
local function stopAllThreads()
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    if skillThread then task.cancel(skillThread) skillThread = nil end
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    disableNoclip()
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
    if myHumanoid then myHumanoid.AutoRotate = true end 
    
    currentTargetPlayer = nil 
    state.currentTargetPlayer = nil
    isTargetInActiveFight = false 
    pcall(function() if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end end)
end

task.spawn(function()
    while not state.stopRequested do
        task.wait(0.2)
        createNewLayoutUI()

        if not _G.AutoHuntEnabled then
            if isHunting then
                stopAllThreads()
                isHunting = false
                updateHUDDisplay(nil)
            end
            continue
        end

        isHunting = true
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")

        if char and humanoid and humanoid.Health > 0 then
            if (humanoid.Health / humanoid.MaxHealth) * 100 <= 20 then
                stopAllThreads()
                handleEmergencyRetreat()
            end

            autoOnHakiAndInstinct()
            
            if not currentTargetPlayer then
                for _, player in pairs(Players:GetPlayers()) do
                    if isPlayerEligibleForPvP(player) then
                        local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            currentTargetPlayer = player
                            state.currentTargetPlayer = player
                            state.manualSkipRequested = false
                            isTargetInActiveFight = false
                            updateHUDDisplay(player)
                            break
                        end
                    end
                end
            end
            
            if currentTargetPlayer and currentTargetPlayer.Parent then
                local targetChar = currentTargetPlayer.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                    flyTowardsTarget(targetRoot)
                    startM1Loop(currentTargetPlayer)
                    startSkillLoop(currentTargetPlayer)
                    
                    local statsAwal = LocalPlayer:FindFirstChild("leaderstats")
                    local valBountyAwal = statsAwal and (statsAwal:FindFirstChild("Bounty/Honor") or statsAwal:FindFirstChild("Bounty"))
                    local bountySebelumKill = valBountyAwal and valBountyAwal.Value or 0

                    while isHunting and currentTargetPlayer and currentTargetPlayer.Parent do
                        if state.manualSkipRequested or not _G.AutoHuntEnabled then break end
                        
                        targetChar = currentTargetPlayer.Character
                        targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                        if not targetHumanoid or targetHumanoid.Health <= 0 or humanoid.Health <= 0 then break end
                        
                        task.wait(0.2)
                    end
                    
                    if currentTargetPlayer and not state.manualSkipRequested then
                        targetChar = currentTargetPlayer.Character
                        targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                        
                        if targetHumanoid and targetHumanoid.Health <= 0 then
                            bountyBlacklist[currentTargetPlayer.Name] = os.time() + 900
                            task.wait(1.0)
                            
                            local statsAkhir = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Data")
                            local valBountyAkhir = statsAkhir and (statsAkhir:FindFirstChild("Bounty/Honor") or statsAkhir:FindFirstChild("Bounty") or statsAkhir:FindFirstChild("Honor"))
                            local selisih = (valBountyAkhir and valBountyAkhir.Value or bountySebelumKill) - bountySebelumKill
                            
                            if selisih > 0 then
                                totalHadiahDiperoleh = totalHadiahDiperoleh + selisih
                                addTargetLogEntry("[" .. os.date("%H:%M:%S") .. "] " .. currentTargetPlayer.Name .. " -> +" .. math.floor(selisih) .. " bounty")
                            else
                                addTargetLogEntry("[" .. os.date("%H:%M:%S") .. "] " .. currentTargetPlayer.Name .. " -> Dikalahkan")
                            end
                        end
                    end
                    
                    stopAllThreads()
                    updateHUDDisplay(nil)
                    state.manualSkipRequested = false
                    task.wait(0.5)
                else
                    stopAllThreads()
                end
            else
                stopAllThreads()
            end
        end
    end
end)

-- ==========================================
-- EVENT HANDLERS
-- ==========================================
LocalPlayer.CharacterRemoving:Connect(function()
    _G.AutoHuntEnabled = false
    stopAllThreads()
    pcall(function()
        if SafeUIParent and SafeUIParent:FindFirstChild("BountyHunterDashboard") then
            SafeUIParent.BountyHunterDashboard:Destroy()
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    stopAllThreads()
    newChar:WaitForChild("HumanoidRootPart", 10)
    local hum = newChar:WaitForChild("Humanoid", 10)
    if hum then hum.AutoRotate = true end
    task.wait(1.0)
    createNewLayoutUI()
    autoOnHakiAndInstinct()
end)

-- Watcher GUI Close
task.spawn(function()
    while not state.stopRequested do task.wait(0.2) end
    _G.AutoHuntEnabled = false
    stopAllThreads()
    for p, esp in pairs(activeESP) do pcall(function() esp.Gui:Destroy() end) end
    activeESP = {}
    print("[Bounty Hunter] Script dihentikan total via UI.")
end)