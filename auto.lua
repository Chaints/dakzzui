print("[Bounty Hunter] Menjalankan skrip primary lengkap (Auto Skill + Fast M1 + Combat Config + JSON Persistent) - UI TERHAPUS...")

-- ==========================================
-- SMART UI PARENTING (ANTI-CRASH)
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local SafeUIParent
pcall(function()
    SafeUIParent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
end)
if not SafeUIParent or not pcall(function() return SafeUIParent.Name end) then
    SafeUIParent = LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- ==========================================
-- AUTO-PURGE UI LAMA DI MEMORI HP
-- ==========================================
pcall(function()
    if SafeUIParent and SafeUIParent:FindFirstChild("BountyHunterDashboard") then
        SafeUIParent.BountyHunterDashboard:Destroy()
    end
    if SafeUIParent and SafeUIParent:FindFirstChild("BountyBadge") then
        SafeUIParent.BountyBadge:Destroy()
    end
    if workspace:FindFirstChild("AntiWaterPlatform") then
        workspace.AntiWaterPlatform:Destroy()
    end
end)

-- ==========================================
-- GLOBAL SERVICES & DEFAULT CONFIGURATIONS
-- ==========================================
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- DEFAULT AMAN: Saat pertama masuk, Auto Hunt diset OFF (false) agar tidak kaget
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
-- REMOTE EVENTS INITIALIZER (SEA 3 & FAST ATTACK)
-- ==========================================
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 5)
local Net = ModulesFolder and ModulesFolder:WaitForChild("Net", 5)

local NetFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = NetFolder:WaitForChild("RE/RegisterAttack")
local RegisterHit = NetFolder:WaitForChild("RE/RegisterHit")

local JedaSenjataAsli = 0.4000000059604645
local TokenKeamanan = "083cf9b7" -- ⚠️ Ganti dengan token terbaru jika darah tidak berkurang

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = RemotesFolder and RemotesFolder:WaitForChild("CommF_", 3)
local CommE = RemotesFolder and RemotesFolder:WaitForChild("CommE", 3)
local ClockFolder = RemotesFolder and RemotesFolder:FindFirstChild("Clock")
local MasterClockRemote = ClockFolder and ClockFolder:WaitForChild("DelayedRequestFunction", 3)

local M1_ATTACK_RANGE = 17.0   
local SKILL_ATTACK_RANGE = 10.0 
local MAGNET_RANGE = 8.0       

local totalHadiahDiperoleh = 0  

local combatConnection = nil
local noclipConnection = nil
local skillThread = nil
local m1Thread = nil 
local currentTargetPlayer = nil 
local manualSkipRequested = false 
local hasTeleportedToIsland = false 
local isHunting = false
local isEmergencyRetreating = false

local manualSkipList = {} 
local bountyBlacklist = {} 
local activeESP = {}

local sliderInputChangedConn = nil
local sliderInputEndedConn = nil
local isPlayerEligibleForPvP 
local isTargetInActiveFight = false 

local startHuntingLoop, stopAllThreads

-- ==========================================
-- PERSISTENT SERVER HOP QUEUE (GLOBAL / NON-RESET)
-- ==========================================
_G.PersistentReadyJobIds = _G.PersistentReadyJobIds or {}
local isHoppingNow = false

if not _G.ServerScannerInitialized then
    _G.ServerScannerInitialized = true
    task.spawn(function()
        local serverBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        local currentPage = 1
        local maxPages = 200
        
        while task.wait(0.5) do
            if #_G.PersistentReadyJobIds >= 2 or currentPage > maxPages then break end
            if serverBrowser then
                local success, servers = pcall(function() return serverBrowser:InvokeServer(currentPage) end)
                if success and type(servers) == "table" then
                    for jobId, serverData in pairs(servers) do
                        local count = type(serverData) == "table" and (serverData.Count or serverData.Players) or (type(serverData) == "number" and serverData or 0)
                        if count > 0 and count < 7 and jobId ~= game.JobId then
                            local alreadyInQueue = false
                            for _, qId in ipairs(_G.PersistentReadyJobIds) do
                                if qId == jobId then alreadyInQueue = true break end
                            end
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
-- DATABASE POSISI & TITIK TENGAH PULAU (SEA 3)
-- ==========================================
local PortalPositions = {
    ["Castle On The Sea"] = Vector3.new(-5058.86328125, 314.5155029296875, -3155.88330078125),
    ["Mansion Cafe"]      = Vector3.new(-12463.8740234375, 374.9144592285156, -7523.77392578125),
    ["Hydra Island"]      = Vector3.new(5670, 1039.27698, -340)
}

local RealIslandCenter = {
    ["Candy Island"]      = Vector3.new(-1094, 64.43, -14519),
    ["Chocolate Island"]  = Vector3.new(219, 126.65, -12604),
    ["Cake Island"]       = Vector3.new(-1897, 13.85, -11576),
    ["Peanut Island"]     = Vector3.new(-2082, 38.16, -10190),
    ["Kastil Berhantu"]   = Vector3.new(-9517, 142.16, 5528),
    ["Pelabuhan"]         = Vector3.new(-340.01, 20.67, 5523.99),
    ["Greetree"]          = Vector3.new(2205, 21.77, -6766),
    ["Ice Cream Island"]  = Vector3.new(-843, 65.88, -10944),
    ["Mansion Cafe"]      = Vector3.new(-12549.7246, 337.230865, -7487.36279),
    ["Castle On The Sea"] = Vector3.new(-4974.26416, 314.578552, -3011.15771),
    ["Hydra Island"]      = Vector3.new(5670, 1039.27698, -340),
    ["Tiki Outpost"]      = Vector3.new(-16833.5312, 58.3188362, 356.88559)
}

-- ==========================================
-- UI MODULE (ui.lua) — SHARED STATE + INIT
-- ==========================================
-- `state` is the shared table ui.lua reads/writes. auto.lua polls the
-- request flags (manualSkipRequested, stopRequested) each loop tick and
-- pushes live values (currentTargetPlayer, isHunting, totalHadiah) back
-- into it so the UI always reflects what's actually happening.
local state = {
    manualSkipList = manualSkipList,   -- same table reference, mutations are shared automatically
    manualSkipRequested = false,
    isHunting = false,
    currentTargetPlayer = nil,
    totalHadiah = 0,
    stopRequested = false,
    SaveConfig = saveConfig,           -- exposed so ui.lua can persist config changes (skill toggles, speed, etc.) to disk immediately instead of only in memory
}

-- Loaded lazily right before startHuntingLoop/stopAllThreads are defined,
-- since UIModule.Init needs the `state` table above and, once
-- startHuntingLoop exists, wires state.OnToggleHunt to it.
local UI

local function updateHUDDisplay(player)
    if UI and UI.updateHUDDisplay then
        UI.updateHUDDisplay(player)
    end
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
        textLabel.Name = "InfoText"
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
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                if char and root and myRoot then
                    billboardGui.Adornee = root
                    local distance = math.floor((myRoot.Position - root.Position).Magnitude)
                    if player == currentTargetPlayer then
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

local function applyTargetHighlight(targetChar)
    pcall(function()
        if not targetChar then return end
        if not targetChar:FindFirstChild("TargetHighlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "TargetHighlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 0) 
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.4
            highlight.OutlineTransparency = 0
            highlight.Parent = targetChar
        end
    end)
end

local function removeTargetHighlight(targetChar)
    pcall(function()
        if targetChar and targetChar:FindFirstChild("TargetHighlight") then targetChar.TargetHighlight:Destroy() end
    end)
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
        if not char:FindFirstChild("HasBuso") then
            if CommF then CommF:InvokeServer("Buso") end
        end
        if CommE then CommE:FireServer("Ken", true) end
    end)
end

local function activateRaceV3AndV4()
    pcall(function() 
        if CommE then 
            CommE:FireServer("ActivateAbility") 
            CommE:FireServer("ActivateAwakening") 
        end 
    end)
end

local function equipWeaponCategory(categoryName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not backpack or not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        local itemType = currentTool:FindFirstChild("ToolTip") and tostring(currentTool.ToolTip.Value) or tostring(currentTool.ToolTip) or ""
        if itemType:lower():find(categoryName:lower()) or currentTool.Name:lower():find(categoryName:lower()) then return currentTool end
    end

    for _, item in pairs(backpack:GetChildren()) do
        if item and item:IsA("Tool") then
            local itemType = item:FindFirstChild("ToolTip") and tostring(item.ToolTip.Value) or tostring(item.ToolTip) or ""
            if itemType:lower():find(categoryName:lower()) or item.Name:lower():find(categoryName:lower()) then
                local hum = char:WaitForChild("Humanoid", 2)
                if hum then hum:EquipTool(item) task.wait(0.05) return item end
            end
        end
    end
    return nil
end

-- ==========================================
-- RADAR SCANNER & STRICT PVP VALIDATION
-- ==========================================
local function isAlly(targetPlayer)
    if not targetPlayer then return true end
    if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
        if LocalPlayer.Team.Name == "Marines" then return true end
    end
    local myCrew = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Crew")
    local targetCrew = targetPlayer:FindFirstChild("Data") and targetPlayer.Data:FindFirstChild("Crew")
    if myCrew and targetCrew and myCrew.Value ~= "" and myCrew.Value == targetCrew.Value then return true end
    return false
end

local function isBuddhaOrPortalUser(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local char = targetPlayer.Character
    if char:FindFirstChild("buddha") or char:FindFirstChild("Big") or char:FindFirstChild("Transformation") then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.Size.Y > 5 then return true end

    local backpack = targetPlayer:FindFirstChild("Backpack")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool and (equippedTool.Name:lower():find("portal") or equippedTool.Name:lower():find("buddha")) then return true end

    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item and (item.Name:lower():find("portal") or item.Name:lower():find("buddha")) then return true end
        end
    end
    return false
end

isPlayerEligibleForPvP = function(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent or not targetPlayer:IsA("Player") or targetPlayer == LocalPlayer then return false end
    
    if isTargetInActiveFight and targetPlayer == currentTargetPlayer then
        local char = targetPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if char and hum and hum.Health > 0 then return true end
    end

    local dataFolder = targetPlayer:FindFirstChild("Data")
    if manualSkipList[targetPlayer.Name] then return false end
    if bountyBlacklist[targetPlayer.Name] and os.time() < bountyBlacklist[targetPlayer.Name] then return false end
    
    if targetPlayer:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    if targetPlayer:FindFirstChild("PlayerStats") and targetPlayer.PlayerStats:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    
    local char = targetPlayer.Character
    if not char then return false end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then return false end
    
    if char:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    if char:FindFirstChildOfClass("ForceField") then return false end
    
    if char:GetAttribute("SafeZone") or targetPlayer:GetAttribute("SafeZone") then return false end
    if char:FindFirstChild("SafeZone") then return false end
    local pvpDisabledAttr = char:GetAttribute("PvPDisabled") or targetPlayer:GetAttribute("PvPDisabled")
    if pvpDisabledAttr == true then return false end
    
    if targetPlayer:FindFirstChild("PvPDisabled") and targetPlayer.PvPDisabled.Value == true then return false end
    if dataFolder then
        local safeZoneVal = dataFolder:FindFirstChild("SafeZone")
        if safeZoneVal and safeZoneVal.Value == true then return false end
        local pvpVal = dataFolder:FindFirstChild("PvP") or dataFolder:FindFirstChild("PvPDisabled") or dataFolder:FindFirstChild("PvpDisabled")
        if pvpVal and (pvpVal.Value == false or (pvpVal.Value == true and pvpVal.Name:lower().find("disabled"))) then return false end
    end

    if isAlly(targetPlayer) or isBuddhaOrPortalUser(targetPlayer) then return false end
    
    local safeZones = {
        Vector3.new(-12463, 374, -7523),
        Vector3.new(-5058, 314, -3155),
        Vector3.new(5670, 1039, -340),
        Vector3.new(-16833, 58, 356)
    }
    for _, safePos in ipairs(safeZones) do
        if (root.Position - safePos).Magnitude < 350 then return false end
    end
    
    return true
end

-- ==========================================
-- FAST M1 KILL AURA (HANYA AKTIF 80% - 50% HP)
-- ==========================================
local function startM1Loop(targetPlayer)
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    m1Thread = task.spawn(function()
        while isHunting and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tChar = targetPlayer and targetPlayer.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.MaxHealth > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                if currentHPPercent <= 80 and currentHPPercent >= 50 then
                    isTargetInActiveFight = true
                    equipWeaponCategory("Melee")
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    if dist <= M1_ATTACK_RANGE then
                        for comboKe = 1, 4 do
                            RegisterAttack:FireServer(JedaSenjataAsli, comboKe)
                            local partTarget = tRoot or tChar:FindFirstChild("UpperTorso")
                            if partTarget then
                                local argsHit = {
                                    [1] = partTarget,
                                    [2] = {},
                                    [4] = TokenKeamanan
                                }
                                RegisterHit:FireServer(unpack(argsHit))
                            end
                        end
                    end
                end
            end
            task.wait(0.01) 
        end
    end)
end

-- ==========================================
-- AUTO SKILL COMBO (100-80% & < 50% HP)
-- ==========================================
local function executeToolRemoteInstant(targetPosition, skillType, toolRemote)
    pcall(function()
        pcall(function() game:GetService("ReplicatedStorage").Remotes.GetSetting:InvokeServer("MobileSchemeMode") end)
        if MasterClockRemote then pcall(function() MasterClockRemote:InvokeServer() end) end

        local keyCodeMap = {
            ["Z"] = Enum.KeyCode.Z,
            ["X"] = Enum.KeyCode.X,
            ["C"] = Enum.KeyCode.C,
            ["V"] = Enum.KeyCode.V,
            ["F"] = Enum.KeyCode.F
        }
        local targetKey = keyCodeMap[skillType]

        if skillType == "X" then 
            toolRemote:FireServer("X", false) 
        else 
            toolRemote:FireServer(skillType, targetPosition) 
        end

        if targetKey and VirtualInputManager then
            task.spawn(function()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, targetKey, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, targetKey, false, game)
                end)
            end)
        end
    end)
end

local function startSkillLoop(targetPlayer)
    if skillThread then task.cancel(skillThread) skillThread = nil end
    skillThread = task.spawn(function()
        local weaponCategories = {"Melee", "Fruit", "Sword", "Gun"}
        local skillKeys = {"Z", "X", "C", "V", "F"}
        local noVFruits = {"tiger", "yeti", "mammoth", "trex", "t-rex", "kitsune", "dragon", "gas", "buddha", "phoenix", "venom"}

        pcall(function()
            local subWorker = Net and Net:FindFirstChild("RF/SubmarineWorkerSpeak")
            if subWorker then subWorker:InvokeServer("AskKilledTikiBoss") end
        end)

        while isHunting and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tChar = targetPlayer and targetPlayer.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.MaxHealth > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                
                if (currentHPPercent > 80 and currentHPPercent <= 100) or (currentHPPercent < 50) then
                    isTargetInActiveFight = true
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    if dist <= SKILL_ATTACK_RANGE then 
                        autoOnHakiAndInstinct()
                        activateRaceV3AndV4()

                        for _, category in ipairs(weaponCategories) do
                            if not currentTargetPlayer or not isPlayerEligibleForPvP(currentTargetPlayer) then break end
                            
                            local equippedTool = equipWeaponCategory(category)
                            if equippedTool then
                                local targetPos = tRoot.Position
                                local toolName = equippedTool.Name:lower()
                                
                                local isTransformFruit = false
                                if category == "Fruit" then
                                    for _, fruitName in ipairs(noVFruits) do
                                        if toolName:find(fruitName) then isTransformFruit = true break end
                                    end
                                end
                                
                                local toolRemote = equippedTool:FindFirstChild("RemoteEvent") or equippedTool:FindFirstChildOfClass("RemoteEvent")
                                if toolRemote then
                                    for _, key in ipairs(skillKeys) do
                                        local catConfig = _G.CombatConfig[category]
                                        local skillSubCfg = catConfig and catConfig[key]
                                        
                                        if skillSubCfg and skillSubCfg.On then
                                            if not (key == "V" and isTransformFruit) then
                                                executeToolRemoteInstant(targetPos, key, toolRemote)
                                                task.wait(0.08)
                                            end
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
            
            local currentHpPercent = (hum.Health / hum.MaxHealth) * 100
            if currentHpPercent >= 50 or not isHunting then
                if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
                return
            end
            
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = root.CFrame + Vector3.new(0, _G.CustomFlightSpeed * deltaTime, 0)
        end)
    end)

    while escapeConnection and isHunting do
        task.wait(0.2)
    end
    
    isEmergencyRetreating = false
    disableNoclip()
end

-- ==========================================
-- SMART PORTAL ROUTER & SUBMARINE HANDLER
-- ==========================================
local function smoothMoveToTargetAndHold(destinationPos, speed, holdTime)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    enableNoclip()
    
    local startTime = tick()
    local startPos = root.Position
    local distance = (destinationPos - startPos).Magnitude
    local duration = distance / speed
    
    while task.wait() do
        if not isHunting then break end
        local currentPos = root.Position
        if (destinationPos - currentPos).Magnitude < 8 then 
            root.CFrame = CFrame.new(destinationPos)
            break 
        end
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local newPos = startPos:Lerp(destinationPos, alpha)
        root.CFrame = CFrame.new(newPos) * CFrame.lookAt(newPos, destinationPos).Rotation
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    
    local holdStart = tick()
    while tick() - holdStart < holdTime do
        if not isHunting then break end
        root.CFrame = CFrame.new(destinationPos)
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        task.wait(0.1)
    end
end

local function handleSmartPortalBypass(targetRoot)
    if not currentTargetPlayer or not currentTargetPlayer.Parent then return end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot or not targetRoot.Parent or hasTeleportedToIsland then return end

    local targetPos = targetRoot.Position
    local targetLocationTag = ""
    local dataFolder = currentTargetPlayer:FindFirstChild("Data")
    if dataFolder then
        local locTag = dataFolder:FindFirstChild("LocationTag") or dataFolder:FindFirstChild("Location")
        if locTag then targetLocationTag = tostring(locTag.Value) end
    end
    local myPos = myRoot.Position

    if (string.lower(targetLocationTag):find("submerged") or targetPos.Y < -1000) and myPos.Y > -500 then
        hasTeleportedToIsland = true
        pcall(function()
            enableNoclip()
            smoothMoveToTargetAndHold(Vector3.new(-16270.20, 25.25, 1372.97), _G.CustomFlightSpeed, 3.0)
            
            pcall(function()
                local modulesNet = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                if modulesNet then
                    local subWorkerSpeak = modulesNet:FindFirstChild("RF/SubmarineWorkerSpeak")
                    if subWorkerSpeak then
                        subWorkerSpeak:InvokeServer("TravelToSubmergedIsland")
                    end
                end
            end)
            task.wait(2.0) 
        end)
        return
    end

    if not (string.lower(targetLocationTag):find("submerged") or targetPos.Y < -1000) and myPos.Y < -1000 then
        hasTeleportedToIsland = true
        pcall(function()
            enableNoclip()
            smoothMoveToTargetAndHold(Vector3.new(11421.99, -2154.80, 9728.17), _G.CustomFlightSpeed, 3.0)
            
            pcall(function()
                local modulesNet = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                if modulesNet then
                    local subTransport = modulesNet:FindFirstChild("RF/SubmarineTransportation")
                    if subTransport then
                        subTransport:InvokeServer("InitiateTeleport", "Tiki Outpost")
                    end
                end
            end)
            task.wait(2.0) 
        end)
        return
    end

    local distanceDirect = (myRoot.Position - targetPos).Magnitude
    if distanceDirect > 2000 then
        local pulauTarget = "Castle On The Sea"
        local jarakTerpendek = math.huge

        for namaPulau, posisiPusat in pairs(RealIslandCenter) do
            local hitungJarak = (targetPos - posisiPusat).Magnitude
            if hitungJarak < jarakTerpendek then 
                jarakTerpendek = hitungJarak 
                pulauTarget = namaPulau 
            end
        end

        local targetIslandCenterPos = RealIslandCenter[pulauTarget] or targetPos
        local portalUtamaTerdekat = "Castle On The Sea"
        local jarakPortalTerpendek = math.huge
        
        for namaPortal, posPortal in pairs(PortalPositions) do
            local distToIsland = (targetIslandCenterPos - posPortal).Magnitude
            if distToIsland < jarakPortalTerpendek then
                jarakPortalTerpendek = distToIsland
                portalUtamaTerdekat = namaPortal
            end
        end

        local chosenPortalVector = PortalPositions[portalUtamaTerdekat]
        if chosenPortalVector and CommF then
            hasTeleportedToIsland = true
            pcall(function() CommF:InvokeServer("requestEntrance", chosenPortalVector) end)
            task.wait(0.2)
            pcall(function()
                myRoot.CFrame = CFrame.new(chosenPortalVector) * CFrame.new(0, 6, 0)
                myRoot.Anchored = true
            end)
            task.wait(3.0)
            pcall(function() myRoot.Anchored = false end)
        end
    end
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

    local magnetTether = myRoot:FindFirstChild("QuantumMagnetTether")
    if magnetTether then magnetTether:Destroy() end
    
    combatConnection = RunService.RenderStepped:Connect(function(deltaTime)
        pcall(function()
            if not isPlayerEligibleForPvP(currentTargetPlayer) or manualSkipRequested or isEmergencyRetreating then
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end 
                return
            end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")

            if root and humanoid and humanoid.Health > 0 and targetRoot and targetRoot.Parent then
                if root.Anchored then root.Anchored = false end
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                local targetPos = targetRoot.Position
                local currentPos = root.Position
                local distance = (targetPos - currentPos).Magnitude
                
                local camera = workspace.CurrentCamera
                if camera then
                    local camPos = camera.CFrame.Position
                    local targetCamCFrame = CFrame.lookAt(camPos, targetPos)
                    camera.CFrame = camera.CFrame:Lerp(targetCamCFrame, 0.75)
                end

                local straightLockCFrame = targetRoot.CFrame * CFrame.new(0, 0, MAGNET_RANGE)
                local targetGoalPos = straightLockCFrame.Position
                
                local safeDelta = math.clamp(deltaTime, 0.01, 0.033)

                if distance > MAGNET_RANGE then
                    local direction = (targetGoalPos - currentPos)
                    local dist = direction.Magnitude
                    local maxStep = math.min(_G.CustomFlightSpeed * safeDelta, dist)
                    
                    local hoverPos = currentPos + (direction.Unit * maxStep)
                    
                    local newLook = CFrame.lookAt(hoverPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
                    root.CFrame = CFrame.new(hoverPos) * newLook.Rotation
                else
                    local newLook = CFrame.lookAt(targetGoalPos, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
                    root.CFrame = CFrame.new(targetGoalPos) * newLook.Rotation
                end

                local platform = getOrCreatePlatform()
                platform.CFrame = CFrame.new(root.Position - Vector3.new(0, 4.2, 0))
            else
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end
            end
        end)
    end)
end

-- ==========================================
-- HUNTING MAIN LOOP
-- ==========================================
stopAllThreads = function()
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    if skillThread then task.cancel(skillThread) skillThread = nil end
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    disableNoclip()
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
    if myHumanoid then myHumanoid.AutoRotate = true end 
    if myRoot and myRoot:FindFirstChild("QuantumMagnetTether") then myRoot.QuantumMagnetTether:Destroy() end
    
    if currentTargetPlayer and currentTargetPlayer.Character then removeTargetHighlight(currentTargetPlayer.Character) end
    currentTargetPlayer = nil 
    isTargetInActiveFight = false 
    pcall(function() if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end end)
end

startHuntingLoop = function()
    if isHunting then return end
    isHunting = true
    task.spawn(function()
        while isHunting do
            task.wait(0.2)
            -- updateHUDDisplay(currentTargetPlayer) -- Panggil jika UI eksternal Anda membutuhkannya

            if not _G.AutoHuntEnabled then
                stopAllThreads()
                isHunting = false
                break
            end

            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChild("Humanoid")

            if char and humanoid and humanoid.Health > 0 then
                local myHpPercent = (humanoid.Health / humanoid.MaxHealth) * 100
                if myHpPercent <= 20 then
                    stopAllThreads()
                    handleEmergencyRetreat()
                end

                autoOnHakiAndInstinct()
                
                if not currentTargetPlayer then
                    for _, player in pairs(Players:GetPlayers()) do
                        if isPlayerEligibleForPvP(player) then
                            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                            
                            if targetRoot and targetHumanoid then
                                currentTargetPlayer = player
                                manualSkipRequested = false
                                hasTeleportedToIsland = false
                                isTargetInActiveFight = false
                                updateHUDDisplay(player)
                                applyTargetHighlight(player.Character)
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
                        if not hasTeleportedToIsland then
                            handleSmartPortalBypass(targetRoot)
                        end
                        
                        flyTowardsTarget(targetRoot)
                        startM1Loop(currentTargetPlayer)
                        startSkillLoop(currentTargetPlayer)
                        
                        local statsAwal = LocalPlayer:FindFirstChild("leaderstats")
                        local valBountyAwal = statsAwal and (statsAwal:FindFirstChild("Bounty/Honor") or statsAwal:FindFirstChild("Bounty"))
                        local bountySebelumKill = valBountyAwal and valBountyAwal.Value or 0

                        while isHunting and currentTargetPlayer and currentTargetPlayer.Parent do
                            if manualSkipRequested or not _G.AutoHuntEnabled then 
                                break 
                            end
                            
                            targetChar = currentTargetPlayer.Character
                            targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                            
                            if not targetHumanoid or targetHumanoid.Health <= 0 then 
                                break 
                            end
                            
                            if humanoid.Health <= 0 then 
                                break 
                            end
                            
                            task.wait(0.2)
                        end
                        
                        if currentTargetPlayer and not manualSkipRequested then
                            targetChar = currentTargetPlayer.Character
                            targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                            
                            if targetHumanoid and targetHumanoid.Health <= 0 then
                                bountyBlacklist[currentTargetPlayer.Name] = os.time() + 900
                                task.wait(1.0)
                                
                                local statsAkhir = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Data")
                                local valBountyAkhir = statsAkhir and (statsAkhir:FindFirstChild("Bounty/Honor") or statsAkhir:FindFirstChild("Bounty") or statsAkhir:FindFirstChild("Honor"))
                                local bountySesudahKill = valBountyAkhir and valBountyAkhir.Value or bountySebelumKill
                                local selisihBountyDapat = bountySesudahKill - bountySebelumKill
                                
                                if selisihBountyDapat > 0 then
                                    totalHadiahDiperoleh = totalHadiahDiperoleh + selisihBountyDapat
                                end
                            end
                        end
                        
                        stopAllThreads()
                        updateHUDDisplay(nil)
                        currentTargetPlayer = nil
                        manualSkipRequested = false
                        hasTeleportedToIsland = false
                        task.wait(0.5)
                    else
                        currentTargetPlayer = nil
                        hasTeleportedToIsland = false
                    end
                else
                    currentTargetPlayer = nil
                    hasTeleportedToIsland = false
                end
            end
        end
    end)
end

-- ==========================================
-- UI LOAD & WIRING
-- ==========================================
-- Loaded here (not at the top) so ui.lua's closures can safely reference
-- startHuntingLoop / stopAllThreads / manualSkipList, which only exist
-- as usable values from this point onward.
pcall(function()
    local UIModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/Chaints/dakzzui/refs/heads/main/ui.lua", true))()
    if UIModule and UIModule.Init then
        -- Init() returns { createNewLayoutUI, updateHUDDisplay, addTargetLogEntry, UIRefs }
        -- We must capture THIS return value into `UI`, not UIModule itself,
        -- otherwise UI.updateHUDDisplay below is always nil and the HUD
        -- (NAMA/LEVEL/STATUS/BOUNTY) never updates.
        UI = UIModule.Init(SafeUIParent, state)
    end
end)

-- state.OnToggleHunt: called by the dashboard START toggle. Keeps
-- _G.AutoHuntEnabled (read by startHuntingLoop's own poll) and the
-- actual loop start/stop in sync no matter which one flips first.
state.OnToggleHunt = function(newValue)
    _G.AutoHuntEnabled = newValue
    if newValue then
        startHuntingLoop()
    else
        stopAllThreads()
        isHunting = false
    end
end

-- Keeps `state` (read by ui.lua) in sync with auto.lua's real internal
-- values every tick — cheap poll, avoids threading UI updates through
-- every single mutation site in the hunting loop above.
task.spawn(function()
    while true do
        state.currentTargetPlayer = currentTargetPlayer
        state.isHunting = isHunting
        state.totalHadiah = totalHadiahDiperoleh

        if state.manualSkipRequested then
            manualSkipRequested = true
            state.manualSkipRequested = false -- consumed; UI must set it true again for another skip
        end

        task.wait(0.2)
    end
end)

-- Watcher: when the UI's "YA, HAPUS" confirm sets state.stopRequested = true,
-- fully tear down the hunt and stop polling.
task.spawn(function()
    while not state.stopRequested do
        task.wait(0.3)
    end
    _G.AutoHuntEnabled = false
    stopAllThreads()
    isHunting = false
end)

-- ==========================================
-- EKSEKUSI AWAL & EVENT HANDLERS
-- ==========================================

if _G.AutoHuntEnabled then
    startHuntingLoop()
end

LocalPlayer.CharacterRemoving:Connect(function()
    isHunting = false
    stopAllThreads()
    
    if sliderInputEndedConn then sliderInputEndedConn:Disconnect() end
    if sliderInputChangedConn then sliderInputChangedConn:Disconnect() end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    stopAllThreads()
    newChar:WaitForChild("HumanoidRootPart", 10)
    local hum = newChar:WaitForChild("Humanoid", 10)
    if hum then hum.AutoRotate = true end
    task.wait(1.0)
    autoOnHakiAndInstinct()
    isHunting = false
    if _G.AutoHuntEnabled then
        startHuntingLoop()
    end
end)