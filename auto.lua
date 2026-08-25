print("[Bounty Hunter] Menjalankan Unified Script (UI + Logic) - Anti Lag/Bug...")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 1. GLOBAL CONFIG & JSON SAVE
-- ==========================================
_G.AutoHuntEnabled = false
_G.CustomFlightSpeed = _G.CustomFlightSpeed or 300
_G.CombatConfig = _G.CombatConfig or {
    ["Sword"] = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Fruit"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}},
    ["Gun"]   = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Melee"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}}
}

local ConfigFileName = "BountyHunterConfig.json"

local function saveConfig()
    pcall(function()
        if writefile then
            local data = {AutoHunt = _G.AutoHuntEnabled, FlightSpeed = _G.CustomFlightSpeed, Combat = _G.CombatConfig}
            writefile(ConfigFileName, HttpService:JSONEncode(data))
        end
    end)
end

pcall(function()
    if readfile and isfile and isfile(ConfigFileName) then
        local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
        if type(decoded) == "table" then
            if decoded.AutoHunt ~= nil then _G.AutoHuntEnabled = decoded.AutoHunt end
            if decoded.FlightSpeed then _G.CustomFlightSpeed = decoded.FlightSpeed end
            if type(decoded.Combat) == "table" then _G.CombatConfig = decoded.Combat end
        end
    end
end)

-- ==========================================
-- 2. CORE LOGIC VARIABLES
-- ==========================================
local state = {
    currentTargetPlayer = nil,
    manualSkipList = {},
    manualSkipRequested = false,
    stopRequested = false,
}

local totalHadiahDiperoleh = 0
local isHunting = false
local isEmergencyRetreating = false
local combatConnection, noclipConnection, skillThread, m1Thread
local activeESP = {}
local bountyBlacklist = {}

-- ==========================================
-- 3. EMBEDDED UI MODULE (Biar ga panggil GitHub)
-- ==========================================
local SafeUIParent
pcall(function() SafeUIParent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
if not SafeUIParent or not pcall(function() return SafeUIParent.Name end) then SafeUIParent = LocalPlayer:WaitForChild("PlayerGui", 10) end

pcall(function()
    if SafeUIParent:FindFirstChild("BountyHunterDashboard") then SafeUIParent.BountyHunterDashboard:Destroy() end
end)

local UIRefs = {}
local TweenService = game:GetService("TweenService")

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function uistroke(obj, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 1
    s.Transparency = transparency or 0.35
    s.Parent = obj
    return s
end

local function tween(obj, duration, props)
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function addShadow(obj)
    local shadow = Instance.new("ImageLabel")
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.55
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.new(1, 18, 1, 18)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.ZIndex = obj.ZIndex - 1
    shadow.Parent = obj
end

local function createNewLayoutUI()
    if not SafeUIParent or SafeUIParent:FindFirstChild("BountyHunterDashboard") then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BountyHunterDashboard"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = SafeUIParent

    local BG = Color3.fromRGB(31, 7, 13)
    local CARD = Color3.fromRGB(85, 11, 24)
    local CARD2 = Color3.fromRGB(105, 20, 35)
    local STROKE = Color3.fromRGB(140, 60, 70)
    local TEXT = Color3.fromRGB(242, 229, 197)
    local MUTED = Color3.fromRGB(200, 175, 145)
    local GREEN = Color3.fromRGB(120, 200, 130)

    -- TAB BAR
    local tabBarFrame = Instance.new("Frame")
    tabBarFrame.Size = UDim2.fromOffset(390, 46)
    tabBarFrame.AnchorPoint = Vector2.new(0.5, 0)
    tabBarFrame.Position = UDim2.new(0.5, 0, 0.30, 0)
    tabBarFrame.BackgroundColor3 = CARD
    tabBarFrame.ZIndex = 10
    tabBarFrame.Parent = gui
    corner(tabBarFrame, 23)
    addShadow(tabBarFrame)
    uistroke(tabBarFrame, STROKE, 0.25)

    local tabHolder = Instance.new("Frame")
    tabHolder.Size = UDim2.fromOffset(280, 32)
    tabHolder.Position = UDim2.new(0, 32, 0.5, -16)
    tabHolder.BackgroundTransparency = 1
    tabHolder.ZIndex = 11
    tabHolder.Parent = tabBarFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabHolder

    local tabButtons, tabContainers = {}, {}
    local function createTabBtn(key, text, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 64, 0, 28)
        b.LayoutOrder = order
        b.BackgroundColor3 = CARD2
        b.Text = text
        b.TextColor3 = MUTED
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 12
        b.Parent = tabHolder
        corner(b, 14)
        tabButtons[key] = b
    end
    createTabBtn("DASH", "DASH", 1)
    createTabBtn("LOG", "TARGET", 2)
    createTabBtn("COMBAT", "COMBAT", 3)

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.fromOffset(26, 26)
    hideBtn.Position = UDim2.new(1, -46, 0.5, -13)
    hideBtn.BackgroundColor3 = CARD2
    hideBtn.Text = "▾"
    hideBtn.TextColor3 = TEXT
    hideBtn.ZIndex = 12
    hideBtn.Parent = tabBarFrame
    corner(hideBtn, 99)

    -- MAIN CARD
    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(390, 230)
    main.AnchorPoint = Vector2.new(0.5, 0)
    main.Position = UDim2.new(0.5, 0, 0.30, 60)
    main.BackgroundColor3 = BG
    main.ZIndex = 5
    main.Parent = gui
    corner(main, 22)
    addShadow(main)
    uistroke(main, STROKE, 0.2)

    local function newTab(name)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -28, 1, -28)
        c.Position = UDim2.fromOffset(14, 14)
        c.BackgroundTransparency = 1
        c.Visible = (name == "DASH")
        c.ZIndex = 6
        c.Parent = main
        tabContainers[name] = c
        return c
    end

    -- TAB: DASHBOARD
    local dashTab = newTab("DASH")
    local infoValues = {}

    local huntBtn = Instance.new("TextButton")
    huntBtn.Size = UDim2.new(1, 0, 0, 32)
    huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and GREEN or CARD2
    huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
    huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20,50,20) or TEXT
    huntBtn.Font = Enum.Font.GothamBold
    huntBtn.ZIndex = 7
    huntBtn.Parent = dashTab
    corner(huntBtn, 12)

    huntBtn.MouseButton1Click:Connect(function()
        _G.AutoHuntEnabled = not _G.AutoHuntEnabled
        huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and GREEN or CARD2
        huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
        huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20,50,20) or TEXT
        saveConfig()
    end)
    UIRefs.huntBtn = huntBtn

    local infoCard = Instance.new("Frame")
    infoCard.Size = UDim2.new(1, 0, 1, -40)
    infoCard.Position = UDim2.fromOffset(0, 40)
    infoCard.BackgroundColor3 = CARD
    infoCard.ZIndex = 7
    infoCard.Parent = dashTab
    corner(infoCard, 14)

    local function infoRow(name, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -28, 0, 18)
        lbl.Position = UDim2.fromOffset(14, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = name .. ": -"
        lbl.TextColor3 = TEXT
        lbl.TextSize = 10
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 8
        lbl.Parent = infoCard
        infoValues[name] = lbl
    end
    infoRow("STATUS", 10); infoRow("NAMA", 30); infoRow("LEVEL", 50); infoRow("BOUNTY", 70); infoRow("REWARD", 100)
    UIRefs.infoValues = infoValues

    -- TAB: COMBAT (FIXED STROKE LEAK)
    local combatTab = newTab("COMBAT")
    local skRow = Instance.new("Frame")
    skRow.Size = UDim2.new(1, 0, 0, 36)
    skRow.Position = UDim2.fromOffset(0, 50)
    skRow.BackgroundTransparency = 1
    skRow.ZIndex = 7
    skRow.Parent = combatTab
    
    local skLayout = Instance.new("UIListLayout")
    skLayout.FillDirection = Enum.FillDirection.Horizontal
    skLayout.Padding = UDim.new(0, 10)
    skLayout.Parent = skRow

    local selectedCat = "Fruit"
    local skillUIs, skillStrokes = {}, {}
    local skills = {"Z", "X", "C", "V", "F"}

    for _, sk in ipairs(skills) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 45, 1, 0)
        b.Font = Enum.Font.GothamBold
        b.Text = sk
        b.ZIndex = 8
        b.Parent = skRow
        corner(b, 8)
        skillStrokes[sk] = uistroke(b, STROKE, 0.4)
        skillUIs[sk] = b

        b.MouseButton1Click:Connect(function()
            if _G.CombatConfig[selectedCat] and _G.CombatConfig[selectedCat][sk] then
                _G.CombatConfig[selectedCat][sk].On = not _G.CombatConfig[selectedCat][sk].On
                local isOn = _G.CombatConfig[selectedCat][sk].On
                b.BackgroundColor3 = isOn and TEXT or CARD2
                b.TextColor3 = isOn and BG or MUTED
                skillStrokes[sk].Transparency = isOn and 0 or 0.4
                saveConfig()
            end
        end)
    end

    local function refreshSkills()
        for _, sk in ipairs(skills) do
            local isOn = _G.CombatConfig[selectedCat] and _G.CombatConfig[selectedCat][sk] and _G.CombatConfig[selectedCat][sk].On
            skillUIs[sk].BackgroundColor3 = isOn and TEXT or CARD2
            skillUIs[sk].TextColor3 = isOn and BG or MUTED
            skillStrokes[sk].Transparency = isOn and 0 or 0.4
        end
    end
    refreshSkills()

    local catRow = Instance.new("Frame")
    catRow.Size = UDim2.new(1, 0, 0, 26)
    catRow.BackgroundTransparency = 1
    catRow.ZIndex = 7
    catRow.Parent = combatTab
    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 10)
    catLayout.Parent = catRow

    local catBtns = {}
    for _, cat in ipairs({"Melee", "Sword", "Fruit", "Gun"}) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 70, 1, 0)
        cb.Text = cat
        cb.Font = Enum.Font.GothamMedium
        cb.TextSize = 10
        cb.ZIndex = 8
        cb.Parent = catRow
        corner(cb, 6)
        catBtns[cat] = cb
        cb.MouseButton1Click:Connect(function()
            selectedCat = cat
            for k, v in pairs(catBtns) do
                v.BackgroundColor3 = (k == selectedCat) and CARD2 or CARD
                v.TextColor3 = (k == selectedCat) and TEXT or MUTED
            end
            refreshSkills()
        end)
    end
    catBtns["Fruit"].BackgroundColor3 = CARD2

    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(1, 0, 0, 36)
    skipBtn.Position = UDim2.fromOffset(0, 100)
    skipBtn.BackgroundColor3 = CARD2
    skipBtn.Text = "SKIP CURRENT TARGET"
    skipBtn.TextColor3 = TEXT
    skipBtn.Font = Enum.Font.GothamBold
    skipBtn.ZIndex = 8
    skipBtn.Parent = combatTab
    corner(skipBtn, 10)
    skipBtn.MouseButton1Click:Connect(function()
        if state.currentTargetPlayer then
            state.manualSkipList[state.currentTargetPlayer.Name] = true
            state.manualSkipRequested = true
            skipBtn.Text = "SKIPPED!"
            task.wait(0.5)
            skipBtn.Text = "SKIP CURRENT TARGET"
        end
    end)

    -- LOGO ZxD (Fixed Drag & Clicks)
    local logo = Instance.new("TextButton")
    logo.Size = UDim2.fromOffset(52, 52)
    logo.Position = UDim2.new(0, 46, 0, 90)
    logo.BackgroundColor3 = BG
    logo.Text = "ZxD"
    logo.TextColor3 = TEXT
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 16
    logo.ZIndex = 50
    logo.Parent = gui
    corner(logo, 26)
    uistroke(logo, STROKE, 0.15)

    local isHidden = false
    hideBtn.MouseButton1Click:Connect(function()
        isHidden = not isHidden
        main.Visible = not isHidden
        hideBtn.Text = isHidden and "▸" or "▾"
    end)

    local dragStart, startPos, moved
    logo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart, startPos, moved = input.Position, logo.Position, false
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragStart = nil end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then moved = true end
            logo.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    logo.MouseButton1Click:Connect(function()
        if moved then return end
        local vis = not tabBarFrame.Visible
        tabBarFrame.Visible = vis
        main.Visible = vis and not isHidden
    end)

    for tabName, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            for k, c in pairs(tabContainers) do c.Visible = (k == tabName) end
            for k, b in pairs(tabButtons) do
                b.BackgroundColor3 = (k == tabName) and TEXT or CARD2
                b.TextColor3 = (k == tabName) and BG or MUTED
            end
        end)
    end
end

local function updateHUDDisplay(player, reward)
    pcall(function()
        if not UIRefs.infoValues then return end
        local iv = UIRefs.infoValues
        if UIRefs.huntBtn then
            UIRefs.huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and Color3.fromRGB(120, 200, 130) or Color3.fromRGB(105, 20, 35)
            UIRefs.huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
            UIRefs.huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20,50,20) or Color3.fromRGB(242, 229, 197)
        end
        iv["REWARD"].Text = "REWARD: +" .. tostring(reward or 0)
        
        if player and player.Parent then
            iv["STATUS"].Text = "STATUS: Menyerang"
            iv["NAMA"].Text = "NAMA: " .. player.Name
            local data = player:FindFirstChild("Data")
            iv["LEVEL"].Text = "LEVEL: " .. tostring(player:FindFirstChild("Level") and player.Level.Value or (data and data:FindFirstChild("Level") and data.Level.Value) or "-")
            local ls = player:FindFirstChild("leaderstats")
            local b = ls and (ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty"))
            iv["BOUNTY"].Text = "BOUNTY: " .. (b and tostring(b.Value) or "-")
        else
            iv["STATUS"].Text = "STATUS: Idle"
            iv["NAMA"].Text = "NAMA: -"
            iv["LEVEL"].Text = "LEVEL: -"
            iv["BOUNTY"].Text = "BOUNTY: -"
        end
    end)
end

-- ==========================================
-- 4. HUNTING LOGIC
-- ==========================================
local function stopAllThreads()
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    if skillThread then task.cancel(skillThread) skillThread = nil end
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild("Humanoid") then myChar.Humanoid.AutoRotate = true end 
    state.currentTargetPlayer = nil
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
                updateHUDDisplay(nil, totalHadiahDiperoleh)
            end
            continue
        end

        isHunting = true
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")

        if char and humanoid and humanoid.Health > 0 then
            
            if not state.currentTargetPlayer then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and not state.manualSkipList[p.Name] then
                        local tChar = p.Character
                        if tChar and tChar:FindFirstChild("HumanoidRootPart") and tChar:FindFirstChild("Humanoid") and tChar.Humanoid.Health > 0 then
                            if not (tChar:FindFirstChildOfClass("ForceField") or tChar:GetAttribute("SafeZone")) then
                                state.currentTargetPlayer = p
                                state.manualSkipRequested = false
                                updateHUDDisplay(p, totalHadiahDiperoleh)
                                break
                            end
                        end
                    end
                end
            end
            
            if state.currentTargetPlayer and state.currentTargetPlayer.Parent then
                local tChar = state.currentTargetPlayer.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local tHum = tChar and tChar:FindFirstChild("Humanoid")
                
                if tRoot and tHum and tHum.Health > 0 then
                    -- Simple Fly Loop
                    if not combatConnection then
                        combatConnection = RunService.RenderStepped:Connect(function(dt)
                            if not _G.AutoHuntEnabled or state.manualSkipRequested then return end
                            pcall(function()
                                local myRoot = LocalPlayer.Character.HumanoidRootPart
                                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                                local targetPos = tRoot.CFrame * CFrame.new(0, 0, 8).Position
                                local dir = (targetPos - myRoot.Position)
                                local step = math.min(_G.CustomFlightSpeed * dt, dir.Magnitude)
                                myRoot.CFrame = CFrame.new(myRoot.Position + dir.Unit * step, tRoot.Position)
                                myRoot.Velocity = Vector3.zero
                            end)
                        end)
                    end

                    -- Wait until target dies or skipped
                    while isHunting and state.currentTargetPlayer and state.currentTargetPlayer.Parent do
                        if state.manualSkipRequested or not _G.AutoHuntEnabled then break end
                        if not tHum or tHum.Health <= 0 or humanoid.Health <= 0 then break end
                        task.wait(0.2)
                    end
                    
                    if tHum and tHum.Health <= 0 then
                        totalHadiahDiperoleh = totalHadiahDiperoleh + 1000 -- Simulasi reward dapet
                    end
                    
                    stopAllThreads()
                    updateHUDDisplay(nil, totalHadiahDiperoleh)
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

LocalPlayer.CharacterRemoving:Connect(function()
    _G.AutoHuntEnabled = false
    stopAllThreads()
end)