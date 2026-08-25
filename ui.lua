-- ==========================================
-- ui.lua — Bounty Hunter Dashboard (Mono Fluent-style)
-- Diupdate dengan fitur Auto Hunt Toggle, Combat Config, & Total Reward
-- ==========================================

local UIModule = {}

function UIModule.Init(SafeUIParent, state)

local UI_NAME = "BountyHunterDashboard"

-- ---- palette (Maroon & Sand theme) ----
local BG        = Color3.fromRGB(31, 7, 13)
local CARD      = Color3.fromRGB(85, 11, 24)
local CARD2     = Color3.fromRGB(105, 20, 35)
local STROKE    = Color3.fromRGB(140, 60, 70)
local TEXT      = Color3.fromRGB(242, 229, 197)
local MUTED     = Color3.fromRGB(200, 175, 145)
local ACCENT    = Color3.fromRGB(242, 229, 197)
local ACCENT_2  = Color3.fromRGB(214, 195, 150)
local ACCENT_TEXT = Color3.fromRGB(45, 12, 18)
local GREEN     = Color3.fromRGB(120, 200, 130)
local ORANGE    = Color3.fromRGB(230, 165, 90)
local RED       = Color3.fromRGB(220, 90, 90)

-- Pastikan fallback config global ada (jaga-jaga UI diload duluan)
_G.AutoHuntEnabled = _G.AutoHuntEnabled or false
_G.CustomFlightSpeed = _G.CustomFlightSpeed or 300
_G.CombatConfig = _G.CombatConfig or {
    ["Sword"] = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Fruit"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}},
    ["Gun"]   = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Melee"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}}
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function uistroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or STROKE
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.Parent = obj
    return s
end

local function gradient(obj, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = obj
    return g
end

-- Bayangan murah meriah (statis, bukan blur runtime)
local function addShadow(obj, intensity)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = intensity or 0.55
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.new(1, 18, 1, 18)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.ZIndex = -1
    shadow.Parent = obj
    return shadow
end

local function tween(obj, duration, props, style, direction)
    local info = TweenInfo.new(duration or 0.12, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function pressFeedback(button, normalColor, pressColor)
    button.MouseButton1Down:Connect(function() tween(button, 0.08, { BackgroundColor3 = pressColor }) end)
    button.MouseButton1Up:Connect(function() tween(button, 0.12, { BackgroundColor3 = normalColor }) end)
    button.MouseLeave:Connect(function() tween(button, 0.12, { BackgroundColor3 = normalColor }) end)
end

local UIRefs = {}

local function createNewLayoutUI()
    if not SafeUIParent then return end
    if SafeUIParent:FindFirstChild(UI_NAME) then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = UI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = SafeUIParent

    local ANCHOR_X = 0.5
    local ANCHOR_Y_TABBAR = 0.30
    local TABBAR_TO_CARD_GAP = 14

    -- ==================== TAB BAR ====================
    local tabBarFrame = Instance.new("Frame")
    tabBarFrame.Name = "TabBar"
    tabBarFrame.Size = UDim2.fromOffset(390, 46)
    tabBarFrame.AnchorPoint = Vector2.new(ANCHOR_X, 0)
    tabBarFrame.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 0)
    tabBarFrame.BackgroundColor3 = CARD
    tabBarFrame.BorderSizePixel = 0
    tabBarFrame.Parent = gui
    corner(tabBarFrame, 23)
    addShadow(tabBarFrame, 0.5)
    uistroke(tabBarFrame, STROKE, 1, 0.25)
    gradient(tabBarFrame, Color3.fromRGB(95, 15, 30), Color3.fromRGB(65, 6, 16), 90)

    local tabBarStatusDot = Instance.new("Frame")
    tabBarStatusDot.Size = UDim2.fromOffset(8, 8)
    tabBarStatusDot.AnchorPoint = Vector2.new(0, 0.5)
    tabBarStatusDot.Position = UDim2.new(0, 16, 0.5, 0)
    tabBarStatusDot.BackgroundColor3 = MUTED
    tabBarStatusDot.BorderSizePixel = 0
    tabBarStatusDot.Parent = tabBarFrame
    corner(tabBarStatusDot, 99)

    local tabHolder = Instance.new("Frame")
    tabHolder.Size = UDim2.fromOffset(280, 32)
    tabHolder.AnchorPoint = Vector2.new(0, 0.5)
    tabHolder.Position = UDim2.new(0, 32, 0.5, 0)
    tabHolder.BackgroundTransparency = 1
    tabHolder.Parent = tabBarFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabLayout.Parent = tabHolder

    local tabButtons = {}
    local tabContainers = {}
    local activeTabName = "DASHBOARD"
    local cardHidden = false

    local function createTabButton(key, displayText, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 64, 0, 28)
        b.LayoutOrder = order
        b.BackgroundColor3 = CARD2
        b.AutoButtonColor = false
        b.Text = displayText
        b.TextColor3 = MUTED
        b.TextSize = 8
        b.Font = Enum.Font.GothamBold
        b.Parent = tabHolder
        corner(b, 14)
        tabButtons[key] = b
        return b
    end

    createTabButton("DASHBOARD", "DASH", 1)
    createTabButton("TARGETS", "TARGET", 2)
    createTabButton("COMBAT", "COMBAT", 3)
    createTabButton("HOP", "HOP", 4)

    local function tabBarButton(icon, xOffsetFromRight, size)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(size or 28, size or 28)
        b.AnchorPoint = Vector2.new(1, 0.5)
        b.Position = UDim2.new(1, -xOffsetFromRight, 0.5, 0)
        b.BackgroundColor3 = CARD2
        b.BackgroundTransparency = 0.3
        b.Text = icon
        b.TextColor3 = TEXT
        b.TextSize = 13
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = tabBarFrame
        corner(b, 99)
        return b
    end

    local stopBtn = tabBarButton("×", 12, 28)
    local hideBtn = tabBarButton("▾", 46, 26)

    -- ==================== MAIN CONTENT CARD ====================
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(390, 230) -- Ditinggikan sedikit untuk tombol Auto Hunt
    main.AnchorPoint = Vector2.new(ANCHOR_X, 0)
    main.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 46 + TABBAR_TO_CARD_GAP)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.Parent = gui
    corner(main, 22)
    addShadow(main, 0.5)
    uistroke(main, STROKE, 1, 0.2)
    gradient(main, Color3.fromRGB(95, 15, 30), Color3.fromRGB(65, 6, 16), 90)

    local tabContentY = 16
    local tabContentHeight = 198

    local function newTabContainer(name)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -28, 0, tabContentHeight)
        c.Position = UDim2.fromOffset(14, tabContentY)
        c.BackgroundTransparency = 1
        c.Visible = (name == "DASHBOARD")
        c.Parent = main
        tabContainers[name] = c
        return c
    end

    local function setActiveTab(name)
        if not tabContainers[name] then return end
        activeTabName = name
        for tabName, container in pairs(tabContainers) do
            container.Visible = (tabName == name)
        end
        for tabName, btn in pairs(tabButtons) do
            if tabName == name then
                tween(btn, 0.12, { BackgroundColor3 = ACCENT })
                btn.TextColor3 = ACCENT_TEXT
            else
                tween(btn, 0.12, { BackgroundColor3 = CARD2 })
                btn.TextColor3 = MUTED
            end
        end
    end

    -- ==================== TAB: DASHBOARD ====================
    local dashTab = newTabContainer("DASHBOARD")
    local infoValues = {}

    -- Auto Hunt Toggle Button
    local huntBtn = Instance.new("TextButton")
    huntBtn.Size = UDim2.new(1, 0, 0, 32)
    huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and GREEN or CARD2
    huntBtn.AutoButtonColor = false
    huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
    huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20, 50, 20) or TEXT
    huntBtn.Font = Enum.Font.GothamBold
    huntBtn.TextSize = 11
    huntBtn.Parent = dashTab
    corner(huntBtn, 12)
    uistroke(huntBtn, STROKE, 1, 0.4)

    huntBtn.MouseButton1Click:Connect(function()
        _G.AutoHuntEnabled = not _G.AutoHuntEnabled
        huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and GREEN or CARD2
        huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
        huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20, 50, 20) or TEXT
        if state.saveConfig then state.saveConfig() end
    end)

    -- Info Card
    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, 0, 1, -40)
    info.Position = UDim2.fromOffset(0, 40)
    info.BackgroundColor3 = CARD
    info.BorderSizePixel = 0
    info.Parent = dashTab
    corner(info, 18)
    addShadow(info, 0.6)
    uistroke(info, STROKE, 1, 0.5)

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -20, 0, 18)
    infoTitle.Position = UDim2.fromOffset(14, 8)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "TARGET INFO"
    infoTitle.TextColor3 = MUTED
    infoTitle.TextSize = 9
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = info

    local function infoRow(name, value, y)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -28, 0, 19)
        row.Position = UDim2.fromOffset(14, y)
        row.BackgroundTransparency = 1
        row.Parent = info

        local a = Instance.new("TextLabel")
        a.Size = UDim2.new(0.4, 0, 1, 0)
        a.BackgroundTransparency = 1
        a.Text = name
        a.TextColor3 = MUTED
        a.TextSize = 9
        a.Font = Enum.Font.Gotham
        a.TextXAlignment = Enum.TextXAlignment.Left
        a.Parent = row

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(0.6, 0, 1, 0)
        b.Position = UDim2.new(0.4, 0, 0, 0)
        b.BackgroundTransparency = 1
        b.Text = value
        b.TextColor3 = TEXT
        b.TextSize = 9
        b.Font = Enum.Font.GothamMedium
        b.TextXAlignment = Enum.TextXAlignment.Right
        b.Parent = row

        infoValues[name] = b
        return b
    end

    infoRow("STATUS", "Idle / Mencari...", 28)
    infoRow("NAMA", "-", 47)
    infoRow("LEVEL", "-", 66)
    infoRow("JARAK", "-", 85)
    infoRow("BOUNTY", "◈ -", 104)

    local miniDivider = Instance.new("Frame")
    miniDivider.Size = UDim2.new(1, -28, 0, 1)
    miniDivider.Position = UDim2.fromOffset(14, 128)
    miniDivider.BackgroundColor3 = STROKE
    miniDivider.BackgroundTransparency = 0.4
    miniDivider.BorderSizePixel = 0
    miniDivider.Parent = info

    local rewardRow = Instance.new("Frame")
    rewardRow.Size = UDim2.new(1, -28, 0, 20)
    rewardRow.Position = UDim2.fromOffset(14, 134)
    rewardRow.BackgroundTransparency = 1
    rewardRow.Parent = info

    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size = UDim2.new(0.5, 0, 1, 0)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text = "TOTAL HADIAH SESI INI"
    rewardLabel.TextColor3 = MUTED
    rewardLabel.TextSize = 9
    rewardLabel.Font = Enum.Font.GothamBold
    rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
    rewardLabel.Parent = rewardRow

    local rewardValue = Instance.new("TextLabel")
    rewardValue.Size = UDim2.new(0.5, 0, 1, 0)
    rewardValue.Position = UDim2.new(0.5, 0, 0, 0)
    rewardValue.BackgroundTransparency = 1
    rewardValue.Text = "+0"
    rewardValue.TextColor3 = GREEN
    rewardValue.TextSize = 11
    rewardValue.Font = Enum.Font.GothamBold
    rewardValue.TextXAlignment = Enum.TextXAlignment.Right
    rewardValue.Parent = rewardRow

    infoValues["REWARD"] = rewardValue

    -- ==================== TAB: TARGETS (LOG) ====================
    local targetsTab = newTabContainer("TARGETS")

    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, 0, 1, 0)
    logFrame.BackgroundColor3 = CARD
    logFrame.BorderSizePixel = 0
    logFrame.Parent = targetsTab
    corner(logFrame, 18)
    addShadow(logFrame, 0.6)
    uistroke(logFrame, STROKE, 1, 0.5)

    local logTitle = Instance.new("TextLabel")
    logTitle.Size = UDim2.new(1, -20, 0, 16)
    logTitle.Position = UDim2.fromOffset(14, 10)
    logTitle.BackgroundTransparency = 1
    logTitle.Text = "RIWAYAT TARGET (SESI INI)"
    logTitle.TextColor3 = MUTED
    logTitle.TextSize = 8
    logTitle.Font = Enum.Font.GothamBold
    logTitle.TextXAlignment = Enum.TextXAlignment.Left
    logTitle.Parent = logFrame

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -28, 1, -40)
    logScroll.Position = UDim2.fromOffset(14, 30)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 3
    logScroll.ScrollBarImageColor3 = ACCENT
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Parent = logFrame

    local logListLayout = Instance.new("UIListLayout")
    logListLayout.Padding = UDim.new(0, 3)
    logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logListLayout.Parent = logScroll

    local logOrderCounter = 0
    local MAX_LOG_ENTRIES = 20

    local function addTargetLogEntry(entryText)
        logOrderCounter = logOrderCounter + 1
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 15)
        row.LayoutOrder = -logOrderCounter
        row.BackgroundTransparency = 1
        row.Text = entryText
        row.TextColor3 = TEXT
        row.TextSize = 9
        row.Font = Enum.Font.Gotham
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = logScroll

        local children = logScroll:GetChildren()
        local entries = {}
        for _, child in ipairs(children) do
            if child:IsA("TextLabel") then table.insert(entries, child) end
        end
        if #entries > MAX_LOG_ENTRIES then
            table.sort(entries, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
            for i = MAX_LOG_ENTRIES + 1, #entries do entries[i]:Destroy() end
        end
    end

    -- ==================== TAB: COMBAT (CONFIG BARU) ====================
    local combatTab = newTabContainer("COMBAT")
    
    local combatCard = Instance.new("Frame")
    combatCard.Size = UDim2.new(1, 0, 1, 0)
    combatCard.BackgroundColor3 = CARD
    combatCard.BorderSizePixel = 0
    combatCard.Parent = combatTab
    corner(combatCard, 18)
    addShadow(combatCard, 0.6)
    uistroke(combatCard, STROKE, 1, 0.5)

    -- 1. Speed Slider
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, -28, 0, 30)
    speedRow.Position = UDim2.fromOffset(14, 12)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = combatCard

    local speedText = Instance.new("TextLabel")
    speedText.Size = UDim2.fromOffset(62, 30)
    speedText.BackgroundTransparency = 1
    speedText.Text = "Speed"
    speedText.TextColor3 = MUTED
    speedText.TextSize = 9
    speedText.Font = Enum.Font.GothamMedium
    speedText.TextXAlignment = Enum.TextXAlignment.Left
    speedText.Parent = speedRow

    local speedValueLabel = Instance.new("TextLabel")
    speedValueLabel.Size = UDim2.fromOffset(62, 30)
    speedValueLabel.Position = UDim2.fromOffset(0, 12)
    speedValueLabel.BackgroundTransparency = 1
    speedValueLabel.Text = tostring(_G.CustomFlightSpeed)
    speedValueLabel.TextColor3 = TEXT
    speedValueLabel.TextSize = 11
    speedValueLabel.Font = Enum.Font.GothamBold
    speedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedValueLabel.Parent = speedRow

    local speedTouchZone = Instance.new("TextButton")
    speedTouchZone.Size = UDim2.new(1, -62, 0, 30)
    speedTouchZone.Position = UDim2.fromOffset(62, 0)
    speedTouchZone.BackgroundTransparency = 1
    speedTouchZone.Text = ""
    speedTouchZone.Parent = speedRow

    local speedBar = Instance.new("Frame")
    speedBar.Size = UDim2.new(1, 0, 0, 6)
    speedBar.AnchorPoint = Vector2.new(0, 0.5)
    speedBar.Position = UDim2.new(0, 0, 0.5, 0)
    speedBar.BackgroundColor3 = Color3.fromRGB(60, 25, 32)
    speedBar.BorderSizePixel = 0
    speedBar.Parent = speedTouchZone
    corner(speedBar, 99)

    local initialRel = math.clamp(_G.CustomFlightSpeed / 350, 0, 1)
    local speedFill = Instance.new("Frame")
    speedFill.Size = UDim2.new(initialRel, 0, 1, 0)
    speedFill.BackgroundColor3 = ACCENT
    speedFill.Parent = speedBar
    corner(speedFill, 99)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialRel, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = speedBar
    corner(knob, 99)

    local draggingSpeedUI = false
    local function setSpeedFromX(x)
        local relative = math.clamp((x - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X, 0, 1)
        speedFill.Size = UDim2.new(relative, 0, 1, 0)
        knob.Position = UDim2.new(relative, 0, 0.5, 0)
        local newSpeed = math.max(1, math.floor(relative * 350))
        _G.CustomFlightSpeed = newSpeed
        speedValueLabel.Text = tostring(newSpeed)
    end

    speedTouchZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSpeedUI = true
            setSpeedFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and draggingSpeedUI then
            draggingSpeedUI = false
            if state.saveConfig then state.saveConfig() end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSpeedUI and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            setSpeedFromX(input.Position.X)
        end
    end)

    -- 2. Weapon Category Selector
    local catRow = Instance.new("Frame")
    catRow.Size = UDim2.new(1, -28, 0, 26)
    catRow.Position = UDim2.fromOffset(14, 56)
    catRow.BackgroundTransparency = 1
    catRow.Parent = combatCard

    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
    catLayout.Parent = catRow

    local categories = {"Melee", "Sword", "Fruit", "Gun"}
    local catBtns = {}
    local selectedCat = "Fruit"

    -- 3. Skill Toggles
    local skillRow = Instance.new("Frame")
    skillRow.Size = UDim2.new(1, -28, 0, 36)
    skillRow.Position = UDim2.fromOffset(14, 92)
    skillRow.BackgroundTransparency = 1
    skillRow.Parent = combatCard

    local skillLayout = Instance.new("UIListLayout")
    skillLayout.FillDirection = Enum.FillDirection.Horizontal
    skillLayout.HorizontalAlignment = Enum.HorizontalAlignment.SpaceBetween
    skillLayout.Parent = skillRow

    local skills = {"Z", "X", "C", "V", "F"}
    local skillUIs = {}

    local function updateSkillUIs()
        for _, sk in ipairs(skills) do
            local btn = skillUIs[sk]
            local isOn = _G.CombatConfig[selectedCat] and _G.CombatConfig[selectedCat][sk] and _G.CombatConfig[selectedCat][sk].On
            btn.BackgroundColor3 = isOn and ACCENT or CARD2
            btn.TextColor3 = isOn and ACCENT_TEXT or MUTED
            uistroke(btn, isOn and ACCENT_2 or STROKE, 1, isOn and 0 or 0.4)
        end
    end

    for _, sk in ipairs(skills) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 56, 1, 0)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Text = sk
        btn.AutoButtonColor = false
        btn.Parent = skillRow
        corner(btn, 8)
        skillUIs[sk] = btn

        btn.MouseButton1Click:Connect(function()
            if _G.CombatConfig[selectedCat] and _G.CombatConfig[selectedCat][sk] then
                _G.CombatConfig[selectedCat][sk].On = not _G.CombatConfig[selectedCat][sk].On
                updateSkillUIs()
                if state.saveConfig then state.saveConfig() end
            end
        end)
    end

    for _, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 78, 1, 0)
        btn.BackgroundColor3 = (cat == selectedCat) and CARD2 or CARD
        btn.TextColor3 = (cat == selectedCat) and TEXT or MUTED
        btn.Text = cat
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.AutoButtonColor = false
        btn.Parent = catRow
        corner(btn, 8)
        uistroke(btn, STROKE, 1, 0.4)
        catBtns[cat] = btn

        btn.MouseButton1Click:Connect(function()
            selectedCat = cat
            for cName, cBtn in pairs(catBtns) do
                local active = (cName == selectedCat)
                cBtn.BackgroundColor3 = active and CARD2 or CARD
                cBtn.TextColor3 = active and TEXT or MUTED
            end
            updateSkillUIs()
        end)
    end
    updateSkillUIs()

    -- 4. Skip Button
    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(1, -28, 0, 36)
    skipBtn.Position = UDim2.fromOffset(14, 142)
    skipBtn.BackgroundColor3 = CARD2
    skipBtn.AutoButtonColor = false
    skipBtn.Text = ""
    skipBtn.Parent = combatCard
    corner(skipBtn, 12)
    uistroke(skipBtn, STROKE, 1, 0.4)

    local skipLabel = Instance.new("TextLabel")
    skipLabel.Size = UDim2.new(1, 0, 1, 0)
    skipLabel.BackgroundTransparency = 1
    skipLabel.Text = "SKIP TARGET"
    skipLabel.TextColor3 = TEXT
    skipLabel.TextSize = 10
    skipLabel.Font = Enum.Font.GothamMedium
    skipLabel.Parent = skipBtn

    skipBtn.MouseButton1Click:Connect(function()
        if state.currentTargetPlayer then
            state.manualSkipList[state.currentTargetPlayer.Name] = true
            state.manualSkipRequested = true
            skipLabel.Text = "SKIPPED!"
            tween(skipBtn, 0.1, { BackgroundColor3 = CARD2 })
            task.wait(0.3)
            skipLabel.Text = "SKIP TARGET"
            tween(skipBtn, 0.1, { BackgroundColor3 = CARD })
        end
    end)

    -- ==================== TAB: HOP ====================
    local hopTab = newTabContainer("HOP")
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, 0, 1, -40)
    hopBtn.Position = UDim2.fromOffset(0, 20)
    hopBtn.BackgroundColor3 = CARD
    hopBtn.AutoButtonColor = false
    hopBtn.Text = ""
    hopBtn.Parent = hopTab
    corner(hopBtn, 18)
    addShadow(hopBtn, 0.6)
    uistroke(hopBtn, STROKE, 1, 0.5)

    local hopDot = Instance.new("Frame")
    hopDot.Size = UDim2.fromOffset(10, 10)
    hopDot.AnchorPoint = Vector2.new(0.5, 0.5)
    hopDot.Position = UDim2.new(0.5, 0, 0.38, 0)
    hopDot.BackgroundColor3 = ORANGE
    hopDot.BorderSizePixel = 0
    hopDot.Parent = hopBtn
    corner(hopDot, 99)

    local hopLabel = Instance.new("TextLabel")
    hopLabel.Size = UDim2.new(1, -20, 0, 20)
    hopLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    hopLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
    hopLabel.BackgroundTransparency = 1
    hopLabel.Text = "MENCARI..."
    hopLabel.TextColor3 = TEXT
    hopLabel.TextSize = 12
    hopLabel.Font = Enum.Font.GothamBold
    hopLabel.Parent = hopBtn

    -- ==================== EVENTS & WIRING ====================
    for tabName, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function() setActiveTab(tabName) end)
    end
    setActiveTab("DASHBOARD")

    local function toggleCard()
        cardHidden = not cardHidden
        main.Visible = not cardHidden
        hideBtn.Text = cardHidden and "▸" or "▾"
    end
    hideBtn.MouseButton1Click:Connect(toggleCard)

    -- Logo ZxD (Toggle Full UI)
    local logo = Instance.new("TextButton")
    logo.Name = "ZDLogo"
    logo.Size = UDim2.fromOffset(52, 52)
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0, 46, 0, 90)
    logo.BackgroundColor3 = BG
    logo.AutoButtonColor = false
    logo.Text = ""
    logo.ZIndex = 50
    logo.Parent = gui
    corner(logo, 26)
    uistroke(logo, STROKE, 1, 0.15)
    gradient(logo, Color3.fromRGB(95, 15, 30), Color3.fromRGB(50, 5, 12), 90)

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Text = "ZxD"
    logoText.TextColor3 = ACCENT
    logoText.TextSize = 16
    logoText.Font = Enum.Font.GothamBlack
    logoText.ZIndex = 51
    logoText.Parent = logo

    local logoStatusDot = Instance.new("Frame")
    logoStatusDot.Size = UDim2.fromOffset(9, 9)
    logoStatusDot.AnchorPoint = Vector2.new(0.5, 0.5)
    logoStatusDot.Position = UDim2.new(1, -8, 0, 8)
    logoStatusDot.BackgroundColor3 = MUTED
    logoStatusDot.BorderSizePixel = 0
    logoStatusDot.ZIndex = 53
    logoStatusDot.Parent = logo
    corner(logoStatusDot, 99)
    uistroke(logoStatusDot, BG, 2, 0)

    local everythingHidden = false
    logo.MouseButton1Click:Connect(function()
        everythingHidden = not everythingHidden
        tabBarFrame.Visible = not everythingHidden
        main.Visible = not everythingHidden and not cardHidden
        tween(logo, 0.1, {Size = UDim2.fromOffset(46,46)})
        task.delay(0.1, function() tween(logo, 0.1, {Size = UDim2.fromOffset(52,52)}) end)
    end)

    -- Drag Logo Logic
    local dragging, dragStart, startPos
    logo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = logo.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            logo.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    logo.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Close Confirm Popup
    local confirmBackdrop = Instance.new("TextButton")
    confirmBackdrop.Size = UDim2.fromScale(1, 1)
    confirmBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    confirmBackdrop.BackgroundTransparency = 1
    confirmBackdrop.Text = ""
    confirmBackdrop.Visible = false
    confirmBackdrop.ZIndex = 90
    confirmBackdrop.Parent = gui

    local confirmPopup = Instance.new("Frame")
    confirmPopup.Size = UDim2.fromOffset(240, 140)
    confirmPopup.AnchorPoint = Vector2.new(0.5, 0.5)
    confirmPopup.Position = UDim2.new(0.5, 0, 0.46, 0)
    confirmPopup.BackgroundColor3 = CARD
    confirmPopup.BorderSizePixel = 0
    confirmPopup.Visible = false
    confirmPopup.ZIndex = 91
    confirmPopup.Parent = gui
    corner(confirmPopup, 14)
    uistroke(confirmPopup, STROKE, 1, 0.15)
    gradient(confirmPopup, Color3.fromRGB(27, 28, 34), Color3.fromRGB(18, 19, 23), 90)

    local confirmTitle = Instance.new("TextLabel")
    confirmTitle.Size = UDim2.new(1, -32, 0, 20)
    confirmTitle.Position = UDim2.fromOffset(16, 18)
    confirmTitle.BackgroundTransparency = 1
    confirmTitle.Text = "Hapus Script?"
    confirmTitle.TextColor3 = TEXT
    confirmTitle.TextSize = 14
    confirmTitle.Font = Enum.Font.GothamBold
    confirmTitle.TextXAlignment = Enum.TextXAlignment.Left
    confirmTitle.ZIndex = 92
    confirmTitle.Parent = confirmPopup
    
    local yesBtn = Instance.new("TextButton", confirmPopup)
    yesBtn.Size = UDim2.new(0.5, -20, 0, 34)
    yesBtn.Position = UDim2.new(0, 16, 1, -50)
    yesBtn.BackgroundColor3 = RED
    yesBtn.Text = "YA, HAPUS"
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 11
    yesBtn.ZIndex = 92
    corner(yesBtn, 9)

    local noBtn = Instance.new("TextButton", confirmPopup)
    noBtn.Size = UDim2.new(0.5, -20, 0, 34)
    noBtn.Position = UDim2.new(0, 128, 1, -50)
    noBtn.BackgroundColor3 = CARD2
    noBtn.Text = "BATAL"
    noBtn.TextColor3 = TEXT
    noBtn.Font = Enum.Font.GothamBold
    noBtn.TextSize = 11
    noBtn.ZIndex = 92
    corner(noBtn, 9)

    stopBtn.MouseButton1Click:Connect(function()
        confirmBackdrop.Visible = true
        confirmPopup.Visible = true
        tween(confirmBackdrop, 0.15, { BackgroundTransparency = 0.5 })
    end)
    local function closeConfirm()
        tween(confirmBackdrop, 0.15, { BackgroundTransparency = 1 })
        confirmPopup.Visible = false
        confirmBackdrop.Visible = false
    end
    noBtn.MouseButton1Click:Connect(closeConfirm)
    confirmBackdrop.MouseButton1Click:Connect(closeConfirm)
    yesBtn.MouseButton1Click:Connect(function()
        state.stopRequested = true
        gui:Destroy()
    end)

    -- Status Loops & Server Hop logic
    _G.PersistentReadyJobIds = _G.PersistentReadyJobIds or {}
    local isHoppingNow = false

    task.spawn(function()
        while gui.Parent do
            task.wait(0.3)
            -- Hop Text
            if not isHoppingNow then
                local count = #_G.PersistentReadyJobIds
                if count > 0 then
                    hopLabel.Text = "HOP (" .. count .. " SIAP)"
                    hopDot.BackgroundColor3 = GREEN
                else
                    hopLabel.Text = "MENCARI..."
                    hopDot.BackgroundColor3 = ORANGE
                end
            end
            
            -- Indicator Dots
            if state.isHunting then
                logoStatusDot.BackgroundColor3 = state.currentTargetPlayer and RED or GREEN
                tabBarStatusDot.BackgroundColor3 = state.currentTargetPlayer and RED or GREEN
            else
                logoStatusDot.BackgroundColor3 = MUTED
                tabBarStatusDot.BackgroundColor3 = MUTED
            end
        end
    end)

    hopBtn.MouseButton1Click:Connect(function()
        if isHoppingNow then return end
        if #_G.PersistentReadyJobIds > 0 then
            isHoppingNow = true
            local targetJobId = table.remove(_G.PersistentReadyJobIds, 1)
            hopLabel.Text = "JOINING..."
            hopDot.BackgroundColor3 = GREEN
            pcall(function()
                local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
                if serverBrowser then serverBrowser:InvokeServer("teleport", targetJobId) end
            end)
            task.wait(3)
            isHoppingNow = false
        end
    end)

    task.spawn(function()
        while gui.Parent do
            task.wait(0.2)
            if infoValues["JARAK"] and state.currentTargetPlayer and state.currentTargetPlayer.Parent then
                pcall(function()
                    local myChar = game:GetService("Players").LocalPlayer.Character
                    local tChar = state.currentTargetPlayer.Character
                    if myChar and tChar and myChar:FindFirstChild("HumanoidRootPart") and tChar:FindFirstChild("HumanoidRootPart") then
                        local d = (myChar.HumanoidRootPart.Position - tChar.HumanoidRootPart.Position).Magnitude
                        infoValues["JARAK"].Text = tostring(math.floor(d)) .. " studs"
                    end
                end)
            end
        end
    end)

    UIRefs.infoValues = infoValues
    UIRefs.addTargetLogEntry = addTargetLogEntry
    UIRefs.huntBtn = huntBtn
end

local function updateHUDDisplay(player, totalReward)
    pcall(function()
        if not UIRefs.infoValues then return end
        local iv = UIRefs.infoValues

        if UIRefs.huntBtn then
            UIRefs.huntBtn.BackgroundColor3 = _G.AutoHuntEnabled and Color3.fromRGB(120, 200, 130) or Color3.fromRGB(105, 20, 35)
            UIRefs.huntBtn.Text = _G.AutoHuntEnabled and "AUTO HUNT: ON" or "AUTO HUNT: OFF"
            UIRefs.huntBtn.TextColor3 = _G.AutoHuntEnabled and Color3.fromRGB(20, 50, 20) or Color3.fromRGB(242, 229, 197)
        end

        local rewardFormatted = "+0"
        if totalReward then
            if totalReward >= 1000000 then rewardFormatted = string.format("+%.1fM", totalReward / 1000000)
            elseif totalReward >= 1000 then rewardFormatted = string.format("+%.1fK", totalReward / 1000)
            else rewardFormatted = "+" .. tostring(totalReward) end
        end
        if iv["REWARD"] then iv["REWARD"].Text = rewardFormatted end

        if player and player.Parent then
            local leaderstats = player:FindFirstChild("leaderstats")
            local dataFolder = player:FindFirstChild("Data")
            local lvVal = player:FindFirstChild("Level") or (dataFolder and dataFolder:FindFirstChild("Level")) or "2550"
            local bountyVal = leaderstats and (leaderstats:FindFirstChild("Bounty/Honor") or leaderstats:FindFirstChild("Bounty"))
            local fb = bountyVal and tostring(bountyVal.Value) or "-"
            if bountyVal and bountyVal.Value >= 1000000 then fb = string.format("%.1fM", bountyVal.Value / 1000000)
            elseif bountyVal and bountyVal.Value >= 1000 then fb = string.format("%.1fK", bountyVal.Value / 1000) end

            if iv["STATUS"] then iv["STATUS"].Text = "Menyerang!" end
            if iv["NAMA"] then iv["NAMA"].Text = player.Name end
            if iv["LEVEL"] then iv["LEVEL"].Text = tostring(lvVal.Value or lvVal) end
            if iv["BOUNTY"] then iv["BOUNTY"].Text = "◈ " .. fb end
        else
            if iv["STATUS"] then iv["STATUS"].Text = "Idle / Mencari..." end
            if iv["NAMA"] then iv["NAMA"].Text = "-" end
            if iv["LEVEL"] then iv["LEVEL"].Text = "-" end
            if iv["JARAK"] then iv["JARAK"].Text = "-" end
            if iv["BOUNTY"] then iv["BOUNTY"].Text = "◈ -" end
        end
    end)
end

local function addTargetLogEntry(entryText)
    pcall(function()
        createNewLayoutUI()
        if UIRefs.addTargetLogEntry then UIRefs.addTargetLogEntry(entryText) end
    end)
end

return {
    createNewLayoutUI = createNewLayoutUI,
    updateHUDDisplay = updateHUDDisplay,
    addTargetLogEntry = addTargetLogEntry,
    UIRefs = UIRefs,
}

end

return UIModule