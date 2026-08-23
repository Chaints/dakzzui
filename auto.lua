print("[Bounty Hunter] Menjalankan inisialisasi awal (Auto-Queue Player <7, Scan Halaman 50-100)...")

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
    if workspace:FindFirstChild("AntiWaterPlatform") then
        workspace.AntiWaterPlatform:Destroy()
    end
end)

-- ==========================================
-- GLOBAL VARIABLES & SERVICES
-- ==========================================
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- REMOTE EVENTS INITIALIZER
-- ==========================================
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules", 5)
local Net = ModulesFolder and ModulesFolder:WaitForChild("Net", 5)

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = RemotesFolder and RemotesFolder:WaitForChild("CommF_", 3)
local CommE = RemotesFolder and RemotesFolder:WaitForChild("CommE", 3)
local ClockFolder = RemotesFolder and RemotesFolder:FindFirstChild("Clock")
local MasterClockRemote = ClockFolder and ClockFolder:WaitForChild("DelayedRequestFunction", 3)

-- PARAMETER UTAMA 
_G.CustomFlightSpeed = 300     
local ATTACK_RANGE = 10.0      -- 10 STUD
local MAGNET_RANGE = 8.0       

-- VARIABEL STATE
local combatConnection = nil
local noclipConnection = nil
local skillThread = nil
local currentTargetPlayer = nil 
local manualSkipRequested = false 
local hasTeleportedToIsland = false 
local isHunting = false

local manualSkipList = {} 
local bountyBlacklist = {} -- Menggunakan sistem waktu (os.time)
local activeESP = {}

local sliderInputChangedConn = nil
local sliderInputEndedConn = nil
local isPlayerEligibleForPvP
local stopAllThreads -- forward declaration; real definition is further below 

-- ==========================================
-- DATABASE POSISI & TITIK TENGAH PULAU
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
-- LOAD UI MODULE (ui.lua) — replace URL below with your actual raw GitHub link
-- ==========================================
local UI_RAW_URL = "https://raw.githubusercontent.com/Chaints/dakzzui/main/ui.lua"

local UIModule
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(UI_RAW_URL))()
    end)

    if ok and result then
        UIModule = result
    else
        warn("[Bounty Hunter] Gagal load ui.lua:", result)
        UIModule = nil
    end
end

-- Shared state table: auto.lua keeps its own local variables as the
-- source of truth (unchanged below), and mirrors them into `state`
-- so ui.lua can read/write without needing direct upvalue access.
local state = {
    currentTargetPlayer = nil,
    manualSkipList = manualSkipList,   -- same table reference, mutations are shared automatically
    manualSkipRequested = false,
    isHunting = false,
    uiHidden = false,
    stopRequested = false,
}

-- UI is a table with { createNewLayoutUI, updateHUDDisplay, UIRefs },
-- produced by running UIModule.Init(...) once.
local UI
if UIModule then
    local ok, result = pcall(function()
        return UIModule.Init(SafeUIParent, state)
    end)
    if ok then
        UI = result
    else
        warn("[Bounty Hunter] Gagal inisialisasi ui.lua:", result)
    end
end

-- Lightweight sync loop: mirrors the real local variables into `state`
-- every tick, and consumes any UI-driven skip request exactly once
-- (edge-triggered) to avoid a race where the UI's flag stays true and
-- keeps re-arming manualSkipRequested after the hunting loop already
-- cleared it — that was the "skip → search → skip → search" loop bug.
task.spawn(function()
    while not state.stopRequested do
        task.wait(0.1)
        state.currentTargetPlayer = currentTargetPlayer
        state.isHunting = isHunting

        -- Consume the UI's skip request exactly once: read it, act on it,
        -- then immediately clear BOTH the state flag and local flag's
        -- source so it can't re-trigger next tick.
        if state.manualSkipRequested then
            manualSkipRequested = true
            state.manualSkipRequested = false -- consumed; UI must set it true again for another skip
        end
    end
end)

-- Watcher: when the UI's "YA, HAPUS" confirm sets state.stopRequested = true,
-- tear down every loop/connection this script owns. The UI closes/destroys
-- itself separately; this just makes sure nothing keeps running headless.
task.spawn(function()
    while not state.stopRequested do
        task.wait(0.2)
    end

    isHunting = false
    stopAllThreads()

    if combatConnection then combatConnection:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    if sliderInputEndedConn then sliderInputEndedConn:Disconnect() end
    if sliderInputChangedConn then sliderInputChangedConn:Disconnect() end

    for player, esp in pairs(activeESP) do
        pcall(function()
            if esp.Gui then esp.Gui:Destroy() end
        end)
    end
    activeESP = {}

    pcall(function()
        if workspace:FindFirstChild("AntiWaterPlatform") then
            workspace.AntiWaterPlatform:Destroy()
        end
    end)

    print("[Bounty Hunter] Script dihentikan lewat konfirmasi popup.")
end)

local function createNewLayoutUI()
    if UI and not state.stopRequested then
        UI.createNewLayoutUI()
    end
end

local function updateHUDDisplay(player)
    if UI and not state.stopRequested then
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
                    billboardGui:Destroy() 
                    activeESP[player] = nil 
                    connection:Disconnect() 
                    return
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
    if activeESP[p] then 
        pcall(function() activeESP[p].Gui:Destroy() end) 
        activeESP[p] = nil 
    end
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
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
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
        if targetChar and targetChar:FindFirstChild("TargetHighlight") then
            targetChar.TargetHighlight:Destroy()
        end
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
        if itemType:lower():find(categoryName:lower()) or currentTool.Name:lower():find(categoryName:lower()) then
            return currentTool
        end
    end

    for _, item in pairs(backpack:GetChildren()) do
        if item and item:IsA("Tool") then
            local itemType = item:FindFirstChild("ToolTip") and tostring(item.ToolTip.Value) or tostring(item.ToolTip) or ""
            if itemType:lower():find(categoryName:lower()) or item.Name:lower():find(categoryName:lower()) then
                local hum = char:WaitForChild("Humanoid", 2)
                if hum then
                    hum:EquipTool(item)
                    task.wait(0.05) 
                    return item
                end
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
    
    local dataFolder = targetPlayer:FindFirstChild("Data")
    if manualSkipList[targetPlayer.Name] then return false end
    
    -- Cek Blacklist (120 Detik)
    if bountyBlacklist[targetPlayer.Name] and os.time() < bountyBlacklist[targetPlayer.Name] then 
        return false 
    end
    
    -- DIED RECENTLY SUPER KETAT
    if targetPlayer:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 120
        return false 
    end
    if targetPlayer:FindFirstChild("PlayerStats") and targetPlayer.PlayerStats:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 120
        return false 
    end
    
    local char = targetPlayer.Character
    if not char then return false end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then return false end
    
    if char:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 120
        return false 
    end
    if char:FindFirstChildOfClass("ForceField") then return false end
    
    -- SAFE ZONE SUPER KETAT
    if char:GetAttribute("SafeZone") or targetPlayer:GetAttribute("SafeZone") then return false end
    if char:FindFirstChild("SafeZone") then return false end
    local pvpDisabledAttr = char:GetAttribute("PvPDisabled") or targetPlayer:GetAttribute("PvPDisabled")
    if pvpDisabledAttr == true then return false end
    
    if targetPlayer:FindFirstChild("PvPDisabled") and targetPlayer.PvPDisabled.Value == true then return false end
    if dataFolder then
        local safeZoneVal = dataFolder:FindFirstChild("SafeZone")
        if safeZoneVal and safeZoneVal.Value == true then return false end
        
        local pvpVal = dataFolder:FindFirstChild("PvP") or dataFolder:FindFirstChild("PvPDisabled") or dataFolder:FindFirstChild("PvpDisabled")
        if pvpVal and (pvpVal.Value == false or (pvpVal.Value == true and pvpVal.Name:lower():find("disabled"))) then return false end
    end

    if isAlly(targetPlayer) or isBuddhaOrPortalUser(targetPlayer) then return false end
    
    -- Jarak Fisik Safe Zone
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
-- INSTANT SKILL COMBO (ASYNC NO-DELAY)
-- ==========================================
local function executeToolRemote(targetPosition, skillType)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end

        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end

        local toolRemote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent")
        
        pcall(function() game:GetService("ReplicatedStorage").Remotes.GetSetting:InvokeServer("MobileSchemeMode") end)
        if MasterClockRemote then pcall(function() MasterClockRemote:InvokeServer() end) end

        if toolRemote then
            local keyCodeMap = {["Z"] = Enum.KeyCode.Z, ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C, ["V"] = Enum.KeyCode.V}
            local targetKey = keyCodeMap[skillType]

            if targetKey then
                pcall(function()
                    if skillType == "X" then toolRemote:FireServer("X", false) else toolRemote:FireServer(skillType, targetPosition) end
                    
                    task.spawn(function()
                        VirtualInputManager:SendKeyEvent(true, targetKey, false, game)
                        task.wait(0.05) 
                        VirtualInputManager:SendKeyEvent(false, targetKey, false, game)
                    end)
                end)
            end
        end
    end)
end

local function startSkillLoop(targetPlayer)
    if skillThread then task.cancel(skillThread) skillThread = nil end

    skillThread = task.spawn(function()
        local weaponCategories = {"Melee", "Fruit", "Sword", "Gun"}
        local skillKeys = {"Z", "X", "C", "V"}
        
        -- BLOKIR SKILL V UNTUK BUAH INI
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

            if myRoot and tRoot then
                local dist = (myRoot.Position - tRoot.Position).Magnitude
                if dist <= ATTACK_RANGE then 
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
                                    if toolName:find(fruitName) then
                                        isTransformFruit = true
                                        break
                                    end
                                end
                            end
                            
                            for _, key in ipairs(skillKeys) do
                                if key == "V" and isTransformFruit then
                                    -- Lewati Skill V agar tidak transform
                                else
                                    executeToolRemote(targetPos, key)
                                end
                            end
                        end
                    end
                end
            end
            task.wait() 
        end
    end)
end

-- ==========================================
-- SMART PORTAL ROUTER & SUBMARINE HANDLER (DELAY 3 DETIK DI NPC)
-- ==========================================
local function smoothMoveToTarget(destinationPos, speed)
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
        local currentDist = (destinationPos - currentPos).Magnitude
        
        if currentDist < 8 then 
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
            
            local npcLuariPos = Vector3.new(-16270.20, 25.25, 1372.97)
            smoothMoveToTarget(npcLuariPos, _G.CustomFlightSpeed)
            
            task.wait(3.0) 
            pcall(function()
                local modulesNet = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                if modulesNet then
                    local subWorkerSpeak = modulesNet:FindFirstChild("RF/SubmarineWorkerSpeak")
                    if subWorkerSpeak then
                        local args = { [1] = "TravelToSubmergedIsland" }
                        subWorkerSpeak:InvokeServer(unpack(args))
                    end
                end
            end)
            
            task.wait(3.0) 
        end)
        return
    end

    if not (string.lower(targetLocationTag):find("submerged") or targetPos.Y < -1000) and myPos.Y < -1000 then
        hasTeleportedToIsland = true
        pcall(function()
            enableNoclip()
            
            local npcDalamPos = Vector3.new(11421.99, -2154.80, 9728.17)
            smoothMoveToTarget(npcDalamPos, _G.CustomFlightSpeed)
            
            task.wait(3.0) 
            pcall(function()
                local modulesNet = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
                if modulesNet then
                    local subTransport = modulesNet:FindFirstChild("RF/SubmarineTransportation")
                    if subTransport then
                        local args = { [1] = "InitiateTeleport", [2] = "Tiki Outpost" }
                        subTransport:InvokeServer(unpack(args))
                    end
                end
            end)
            
            task.wait(3.0) 
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
-- FLY ENGINE (CAM LOCK AKTIF & NGEKOR ABSOLUT)
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
            if not isPlayerEligibleForPvP(currentTargetPlayer) or manualSkipRequested then
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
    disableNoclip()
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
    if myHumanoid then myHumanoid.AutoRotate = true end 
    if myRoot and myRoot:FindFirstChild("QuantumMagnetTether") then myRoot.QuantumMagnetTether:Destroy() end
    
    if currentTargetPlayer and currentTargetPlayer.Character then removeTargetHighlight(currentTargetPlayer.Character) end
    currentTargetPlayer = nil 
    pcall(function() if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end end)
end

local function startHuntingLoop()
    if isHunting then return end
    isHunting = true
    task.spawn(function()
        while isHunting do
            task.wait(0.2)
            createNewLayoutUI()
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChild("Humanoid")

            if char and humanoid and humanoid.Health > 0 then
                autoOnHakiAndInstinct()
                
                if not currentTargetPlayer then
                    -- Skip was already processed (currentTargetPlayer got nil'd below
                    -- when we broke out of the fight loop). Clear the flag here,
                    -- regardless of whether a new target is found this tick — otherwise
                    -- manualSkipRequested stays stuck true forever whenever there's no
                    -- other eligible player, causing the fly/combat loop to keep
                    -- starting and immediately self-cancelling (the "jalan-mati-jalan-mati" bug).
                    manualSkipRequested = false

                    for _, player in pairs(Players:GetPlayers()) do
                        if isPlayerEligibleForPvP(player) then
                            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                            
                            if targetRoot and targetHumanoid then
                                currentTargetPlayer = player
                                hasTeleportedToIsland = false
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
                        startSkillLoop(currentTargetPlayer)
                        
                        repeat
                            task.wait(0.1)
                            if manualSkipRequested then break end
                            targetChar = currentTargetPlayer and currentTargetPlayer.Character
                            targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                        until not isHunting 
                           or not currentTargetPlayer 
                           or not currentTargetPlayer.Parent
                           or (targetHumanoid and targetHumanoid.Health <= 0)
                           or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0)
                        
                        if targetHumanoid and targetHumanoid.Health <= 0 and currentTargetPlayer then
                            -- BLACKLIST 120 DETIK SETELAH MATI
                            bountyBlacklist[currentTargetPlayer.Name] = os.time() + 120
                            print("[Bounty Hunter] Target ditumbangkan & masuk blacklist 2 menit: " .. currentTargetPlayer.Name)
                        end

                        stopAllThreads()
                        updateHUDDisplay(nil)
                        if currentTargetPlayer and currentTargetPlayer.Character then
                            removeTargetHighlight(currentTargetPlayer.Character)
                        end
                        currentTargetPlayer = nil
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
-- EXEKUSI AWAL & EVENT HANDLERS
-- ==========================================
createNewLayoutUI()
startHuntingLoop()

LocalPlayer.CharacterRemoving:Connect(function()
    isHunting = false
    stopAllThreads()
    
    if sliderInputEndedConn then sliderInputEndedConn:Disconnect() end
    if sliderInputChangedConn then sliderInputChangedConn:Disconnect() end

    pcall(function()
        if SafeUIParent and SafeUIParent:FindFirstChild("BountyHunterDashboard") then
            SafeUIParent.BountyHunterDashboard:Destroy()
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if state.stopRequested then return end
    stopAllThreads()
    newChar:WaitForChild("HumanoidRootPart", 10)
    local hum = newChar:WaitForChild("Humanoid", 10)
    if hum then hum.AutoRotate = true end
    task.wait(1.0)
    if state.stopRequested then return end
    createNewLayoutUI()
    autoOnHakiAndInstinct()
    isHunting = false
    startHuntingLoop()
end)