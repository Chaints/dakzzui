-- ==========================================
-- ui.lua — Bounty Hunter Dashboard (Mono Fluent-style)
-- Loaded via loadstring(game:HttpGet(...))(). Returns a module table
-- with :Init(SafeUIParent, state) that builds the dashboard and wires
-- it to a shared `state` table owned by auto.lua.
--
-- state fields read/written by this UI:
--   state.currentTargetPlayer   (Player or nil)
--   state.manualSkipList        (table, key = player name)
--   state.manualSkipRequested   (bool)
--   state.isHunting             (bool)
-- ==========================================

local UIModule = {}

function UIModule.Init(SafeUIParent, state)

local UI_NAME = "BountyHunterDashboard"

-- ---- palette (Mono: Black / White / Warm Grey theme) ----
local BG        = Color3.fromRGB(20, 20, 20)    -- near-black backdrop, slightly darker than CARD
local CARD      = Color3.fromRGB(51, 51, 51)    -- #333333 hitam
local CARD2     = Color3.fromRGB(70, 70, 70)    -- lighter grey for hover/press
local STROKE    = Color3.fromRGB(112, 108, 97)  -- #706C61 abu coklat, used as border
local TEXT      = Color3.fromRGB(255, 255, 255) -- #FFFFFF putih
local MUTED     = Color3.fromRGB(180, 176, 166) -- dimmer warm grey
local ACCENT    = Color3.fromRGB(255, 255, 255) -- #FFFFFF putih (used as the accent)
local ACCENT_2  = Color3.fromRGB(112, 108, 97)  -- #706C61 abu coklat for gradient
local ACCENT_TEXT = Color3.fromRGB(51, 51, 51)  -- #333333 dark text on top of white accent backgrounds
local GREEN     = Color3.fromRGB(120, 200, 130)
local ORANGE    = Color3.fromRGB(230, 165, 90)
local RED       = Color3.fromRGB(220, 90, 90)

-- ---- helpers ----
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

-- Adds a soft drop-shadow behind `obj` using a pre-blurred rounded-rect
-- image (cheap: one ImageLabel, no runtime blur calculation). Makes cards
-- read as "floating" above the background instead of flat/flush with it.
local function addShadow(obj, intensity)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084" -- soft rounded shadow, public Roblox asset
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = intensity or 0.55
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.new(1, 18, 1, 18)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.ZIndex = -1 -- always render behind everything in its parent
    -- IMPORTANT: parent to `obj` itself (not obj.Parent). The Size above
    -- is Scale-relative to whatever this is parented to — parenting to
    -- obj.Parent made a 100%+18px shadow relative to the WHOLE SCREEN
    -- (since some callers' parent was the top-level ScreenGui), which
    -- covered the entire display and blocked every click including
    -- Roblox's own chat button. Parenting to obj makes the 100% actually
    -- mean "100% of this card", which is what was intended.
    shadow.Parent = obj
    return shadow
end

local function tween(obj, duration, props, style, direction)
    local info = TweenInfo.new(
        duration or 0.12,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function pressFeedback(button, normalColor, pressColor)
    button.MouseButton1Down:Connect(function()
        tween(button, 0.08, { BackgroundColor3 = pressColor })
    end)
    button.MouseButton1Up:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = normalColor })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = normalColor })
    end)
end

-- References the UI needs to update live (populated inside createNewLayoutUI)
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

    -- Fixed anchor point both floating pieces are positioned relative to.
    -- Nothing here is draggable — it stays put, per request.
    -- Positioned low enough to avoid Roblox's own chat/notification area
    -- in the top-left, with a clear visual gap between the tab bar pill
    -- and the content card below it (they were rendering flush together
    -- before because the gap in Scale units was too small).
    local ANCHOR_X = 0.5
    local ANCHOR_Y_TABBAR = 0.14 -- moved up from 0.30 so it doesn't sit too low by default
    local TABBAR_TO_CARD_GAP = 14 -- pixels, fixed regardless of screen size

    -- Both floating pieces (tabbar + main card) now move together when the
    -- tabbar is dragged. We track the tabbar's live position here and
    -- reposition `main` underneath it on every drag update.
    local tabBarPosition -- set once tabBarFrame is created below

    --==================================================
    -- TAB BAR — floats independently at the top. Contains the live
    -- status pill, the 4 section tabs, a toggle-card button, and
    -- close. This piece stays visible even when the content card is
    -- hidden (that's the whole point of splitting them).
    --==================================================
    local tabBarFrame = Instance.new("Frame")
    tabBarFrame.Name = "TabBar"
    tabBarFrame.Size = UDim2.fromOffset(390, 46)
    tabBarFrame.AnchorPoint = Vector2.new(ANCHOR_X, 0)
    tabBarFrame.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 0)
    tabBarFrame.BackgroundColor3 = CARD
    tabBarFrame.BorderSizePixel = 0
    tabBarFrame.Parent = gui
    corner(tabBarFrame, 23) -- full pill (half of 46px height)
    addShadow(tabBarFrame, 0.5)
    uistroke(tabBarFrame, STROKE, 1, 0.25)
    gradient(tabBarFrame, Color3.fromRGB(60, 60, 60), Color3.fromRGB(38, 38, 38), 90)

    tabBarPosition = tabBarFrame.Position

    -- Status dot, doubles as a small live "is it working" indicator
    -- even when the content card is hidden.
    local tabBarStatusDot = Instance.new("Frame")
    tabBarStatusDot.Size = UDim2.fromOffset(8, 8)
    tabBarStatusDot.AnchorPoint = Vector2.new(0, 0.5)
    tabBarStatusDot.Position = UDim2.new(0, 16, 0.5, 0)
    tabBarStatusDot.BackgroundColor3 = MUTED
    tabBarStatusDot.BorderSizePixel = 0
    tabBarStatusDot.Parent = tabBarFrame
    corner(tabBarStatusDot, 99)

    --==================================================
    -- 4 SECTION TABS, centered-ish in the pill
    --==================================================
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
        corner(b, 14) -- full pill
        tabButtons[key] = b
        return b
    end

    createTabButton("DASHBOARD", "DASH", 1)
    createTabButton("TARGETS", "TARGET", 2)
    createTabButton("COMBAT", "COMBAT", 3)
    createTabButton("HOP", "HOP", 4)

    --==================================================
    -- TAB BAR RIGHT-SIDE BUTTONS: toggle card visibility, close
    --==================================================
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

        b.MouseButton1Down:Connect(function()
            tween(b, 0.08, { BackgroundTransparency = 0 })
        end)
        b.MouseButton1Up:Connect(function()
            tween(b, 0.12, { BackgroundTransparency = 0.3 })
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.12, { BackgroundTransparency = 0.3 })
        end)

        return b
    end

    local stopBtn = tabBarButton("×", 12, 28)
    local hideBtn = tabBarButton("▾", 46, 26) -- toggles just the content card

    --==================================================
    -- CONTENT CARD — floats separately below the tab bar. Its content
    -- swaps based on the active tab. Hiding this (via hideBtn) leaves
    -- the tab bar fully visible above it.
    --==================================================
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(390, 264)
    main.AnchorPoint = Vector2.new(ANCHOR_X, 0)
    main.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 46 + TABBAR_TO_CARD_GAP)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.ClipsDescendants = false
    main.Parent = gui
    corner(main, 22)
    addShadow(main, 0.5)
    uistroke(main, STROKE, 1, 0.2)
    gradient(main, Color3.fromRGB(60, 60, 60), Color3.fromRGB(38, 38, 38), 90)

    --==================================================
    -- DRAG (tabbar is the handle; main card follows underneath it,
    -- keeping the same 46px + gap offset it had at creation time).
    -- Works with touch (phone) and mouse alike.
    --==================================================
    local dragging = false
    local dragInputStart
    local dragTabBarStart

    local function beginDrag(input)
        dragging = true
        dragInputStart = input.Position
        dragTabBarStart = tabBarFrame.Position
    end

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragInputStart

        local newTabBarPos = UDim2.new(
            dragTabBarStart.X.Scale,
            dragTabBarStart.X.Offset + delta.X,
            dragTabBarStart.Y.Scale,
            dragTabBarStart.Y.Offset + delta.Y
        )
        tabBarFrame.Position = newTabBarPos

        -- main card keeps the same fixed offset below the tabbar it had
        -- when it was first positioned (46 = tabbar height, then the gap)
        main.Position = UDim2.new(
            newTabBarPos.X.Scale,
            newTabBarPos.X.Offset,
            newTabBarPos.Y.Scale,
            newTabBarPos.Y.Offset + 46 + TABBAR_TO_CARD_GAP
        )
    end

    local function endDrag()
        dragging = false
    end

    tabBarFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginDrag(input)
        end
    end)

    tabBarFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            endDrag()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)

    --==================================================
    -- TAB CONTENT AREA (all tabs share this same rectangle inside
    -- the content card, only the active one is Visible)
    --==================================================
    local tabContentY = 16
    local tabContentHeight = 232 -- grew to fit SKIP TARGET + reordered BOUNTY/TOTAL rows in the info card

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

    --==================================================
    -- TAB: DASHBOARD — target info card (status/nama/level/jarak/bounty)
    --==================================================
    local dashTab = newTabContainer("DASHBOARD")

    local info = Instance.new("Frame")
    info.Size = UDim2.new(1, 0, 1, 0)
    info.BackgroundColor3 = CARD
    info.BorderSizePixel = 0
    info.Parent = dashTab
    corner(info, 18)
    addShadow(info, 0.6)
    uistroke(info, STROKE, 1, 0.5)

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -20, 0, 18)
    infoTitle.Position = UDim2.fromOffset(14, 10)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "TARGET INFO"
    infoTitle.TextColor3 = MUTED
    infoTitle.TextSize = 9
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = info

    --==================================================
    -- SKIP TARGET (moved here from Combat tab; sits right under the
    -- title, above STATUS, so it's an at-a-glance action next to the
    -- target info it affects)
    --==================================================
    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(1, -28, 0, 30)
    skipBtn.Position = UDim2.fromOffset(14, 32)
    skipBtn.BackgroundColor3 = CARD2
    skipBtn.AutoButtonColor = false
    skipBtn.Text = ""
    skipBtn.Parent = info
    corner(skipBtn, 14)
    uistroke(skipBtn, STROKE, 1, 0.4)

    local skipLabel = Instance.new("TextLabel")
    skipLabel.Size = UDim2.new(1, 0, 1, 0)
    skipLabel.BackgroundTransparency = 1
    skipLabel.Text = "SKIP TARGET"
    skipLabel.TextColor3 = TEXT
    skipLabel.TextSize = 10
    skipLabel.Font = Enum.Font.GothamMedium
    skipLabel.Parent = skipBtn

    pressFeedback(skipBtn, CARD2, CARD)

    local infoValues = {}

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

    -- Rows shifted down 40px total to make room for the SKIP TARGET button.
    -- BOUNTY (current target's bounty) now comes right after JARAK.
    infoRow("STATUS", "Idle / Mencari...", 74)
    infoRow("NAMA", "-", 95)
    infoRow("LEVEL", "-", 116)
    infoRow("JARAK", "-", 137)

    local bountyRow = Instance.new("Frame")
    bountyRow.Size = UDim2.new(1, -28, 0, 19)
    bountyRow.Position = UDim2.fromOffset(14, 158)
    bountyRow.BackgroundTransparency = 1
    bountyRow.Parent = info

    local bountyLabel = Instance.new("TextLabel")
    bountyLabel.Size = UDim2.new(0.4, 0, 1, 0)
    bountyLabel.BackgroundTransparency = 1
    bountyLabel.Text = "BOUNTY"
    bountyLabel.TextColor3 = MUTED
    bountyLabel.TextSize = 9
    bountyLabel.Font = Enum.Font.Gotham
    bountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bountyLabel.Parent = bountyRow

    local bountyValue = Instance.new("TextLabel")
    bountyValue.Size = UDim2.new(0.6, 0, 1, 0)
    bountyValue.Position = UDim2.new(0.4, 0, 0, 0)
    bountyValue.BackgroundTransparency = 1
    bountyValue.Text = "◈ -"
    bountyValue.TextColor3 = TEXT
    bountyValue.TextSize = 9
    bountyValue.Font = Enum.Font.GothamMedium
    bountyValue.TextXAlignment = Enum.TextXAlignment.Right
    bountyValue.Parent = bountyRow

    infoValues["BOUNTY"] = bountyValue

    local miniDivider = Instance.new("Frame")
    miniDivider.Size = UDim2.new(1, -28, 0, 1)
    miniDivider.Position = UDim2.fromOffset(14, 186)
    miniDivider.BackgroundColor3 = STROKE
    miniDivider.BackgroundTransparency = 0.4
    miniDivider.BorderSizePixel = 0
    miniDivider.Parent = info

    --==================================================
    -- TOTAL PENDAPATAN — cumulative bounty earned this session, mirrors
    -- auto.lua's totalHadiahDiperoleh via state.totalHadiah (see the
    -- polling loop further below that keeps this label live).
    --==================================================
    local totalRow = Instance.new("Frame")
    totalRow.Size = UDim2.new(1, -28, 0, 26)
    totalRow.Position = UDim2.fromOffset(14, 192)
    totalRow.BackgroundTransparency = 1
    totalRow.Parent = info

    local totalLabel = Instance.new("TextLabel")
    totalLabel.Size = UDim2.new(0.55, 0, 1, 0)
    totalLabel.BackgroundTransparency = 1
    totalLabel.Text = "TOTAL PENDAPATAN"
    totalLabel.TextColor3 = MUTED
    totalLabel.TextSize = 9
    totalLabel.Font = Enum.Font.GothamBold
    totalLabel.TextXAlignment = Enum.TextXAlignment.Left
    totalLabel.Parent = totalRow

    local totalValue = Instance.new("TextLabel")
    totalValue.Size = UDim2.new(0.45, 0, 1, 0)
    totalValue.Position = UDim2.new(0.55, 0, 0, 0)
    totalValue.BackgroundTransparency = 1
    totalValue.Text = "◈ 0"
    totalValue.TextColor3 = ACCENT
    totalValue.TextSize = 12
    totalValue.Font = Enum.Font.GothamBold
    totalValue.TextXAlignment = Enum.TextXAlignment.Right
    totalValue.Parent = totalRow

    infoValues["TOTAL"] = totalValue

    --==================================================
    -- TAB: TARGETS — session kill log (resets on script reload,
    -- newest entry at the top, capped at 20 entries)
    --==================================================
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
        row.LayoutOrder = -logOrderCounter -- newest first
        row.BackgroundTransparency = 1
        row.Text = entryText
        row.TextColor3 = TEXT
        row.TextSize = 9
        row.Font = Enum.Font.Gotham
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextTruncate = Enum.TextTruncate.AtEnd
        row.Parent = logScroll

        local children = logScroll:GetChildren()
        local entries = {}
        for _, child in ipairs(children) do
            if child:IsA("TextLabel") then
                table.insert(entries, child)
            end
        end
        if #entries > MAX_LOG_ENTRIES then
            table.sort(entries, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
            for i = MAX_LOG_ENTRIES + 1, #entries do
                entries[i]:Destroy()
            end
        end
    end

    --==================================================
    -- TAB: COMBAT — speed slider (1 - 350, real unit from _G.CustomFlightSpeed)
    --==================================================
    local combatTab = newTabContainer("COMBAT")

    local combatCard = Instance.new("Frame")
    combatCard.Size = UDim2.new(1, 0, 1, 0)
    combatCard.BackgroundColor3 = CARD
    combatCard.BorderSizePixel = 0
    combatCard.Parent = combatTab
    corner(combatCard, 18)
    addShadow(combatCard, 0.6)
    uistroke(combatCard, STROKE, 1, 0.5)

    local combatTitle = Instance.new("TextLabel")
    combatTitle.Size = UDim2.new(1, -20, 0, 16)
    combatTitle.Position = UDim2.fromOffset(14, 10)
    combatTitle.BackgroundTransparency = 1
    combatTitle.Text = "PENGATURAN COMBAT"
    combatTitle.TextColor3 = MUTED
    combatTitle.TextSize = 8
    combatTitle.Font = Enum.Font.GothamBold
    combatTitle.TextXAlignment = Enum.TextXAlignment.Left
    combatTitle.Parent = combatCard

    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, -28, 0, 34)
    speedRow.Position = UDim2.fromOffset(14, 34)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = combatCard

    local speedText = Instance.new("TextLabel")
    speedText.Size = UDim2.fromOffset(62, 34)
    speedText.BackgroundTransparency = 1
    speedText.Text = "Speed"
    speedText.TextColor3 = MUTED
    speedText.TextSize = 9
    speedText.Font = Enum.Font.GothamMedium
    speedText.TextXAlignment = Enum.TextXAlignment.Left
    speedText.Parent = speedRow

    local speedValueLabel = Instance.new("TextLabel")
    speedValueLabel.Size = UDim2.fromOffset(62, 34)
    speedValueLabel.Position = UDim2.fromOffset(0, 12)
    speedValueLabel.BackgroundTransparency = 1
    speedValueLabel.Text = tostring(_G.CustomFlightSpeed)
    speedValueLabel.TextColor3 = TEXT
    speedValueLabel.TextSize = 11
    speedValueLabel.Font = Enum.Font.GothamBold
    speedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedValueLabel.Parent = speedRow

    local speedTouchZone = Instance.new("TextButton")
    speedTouchZone.Size = UDim2.new(1, -62, 0, 34)
    speedTouchZone.Position = UDim2.fromOffset(62, 0)
    speedTouchZone.BackgroundTransparency = 1
    speedTouchZone.Text = ""
    speedTouchZone.AutoButtonColor = false
    speedTouchZone.Parent = speedRow

    local speedBar = Instance.new("Frame")
    speedBar.Size = UDim2.new(1, 0, 0, 6)
    speedBar.AnchorPoint = Vector2.new(0, 0.5)
    speedBar.Position = UDim2.new(0, 0, 0.5, 0)
    speedBar.BackgroundColor3 = Color3.fromRGB(60, 25, 32)
    speedBar.BorderSizePixel = 0
    speedBar.Parent = speedTouchZone
    corner(speedBar, 99)

    local MAX_SPEED = 350
    local initialRel = math.clamp(_G.CustomFlightSpeed / MAX_SPEED, 0, 1)

    local speedFill = Instance.new("Frame")
    speedFill.Size = UDim2.new(initialRel, 0, 1, 0)
    speedFill.BackgroundColor3 = ACCENT
    speedFill.BorderSizePixel = 0
    speedFill.Parent = speedBar
    corner(speedFill, 99)
    gradient(speedFill, ACCENT, ACCENT_2, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(initialRel, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = speedBar
    corner(knob, 99)
    uistroke(knob, ACCENT, 2, 0)

    local draggingSpeedUI = false

    local function setSpeedFromX(x)
        local relative = math.clamp(
            (x - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X,
            0,
            1
        )

        speedFill.Size = UDim2.new(relative, 0, 1, 0)
        knob.Position = UDim2.new(relative, 0, 0.5, 0)

        local newSpeed = math.floor(relative * MAX_SPEED)
        if newSpeed < 1 then newSpeed = 1 end
        _G.CustomFlightSpeed = newSpeed
        speedValueLabel.Text = tostring(newSpeed)
    end

    speedTouchZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSpeedUI = true
            setSpeedFromX(input.Position.X)
            tween(knob, 0.1, { Size = UDim2.fromOffset(19, 19) })
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if draggingSpeedUI then
                tween(knob, 0.1, { Size = UDim2.fromOffset(16, 16) })
            end
            draggingSpeedUI = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSpeedUI then
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then
                setSpeedFromX(input.Position.X)
            end
        end
    end)

    --==================================================
    -- TAB: HOP — server hop button (bigger/clearer since it now
    -- has a whole tab to itself)
    --==================================================
    local hopTab = newTabContainer("HOP")

    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, 0, 1, 0)
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

    pressFeedback(hopBtn, CARD, CARD2)

    --==================================================
    -- TAB BUTTON CLICK WIRING
    --==================================================
    for tabName, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            setActiveTab(tabName)
        end)
    end
    setActiveTab("DASHBOARD")

    --==================================================
    -- TOGGLE CARD (hideBtn on the tab bar): hides ONLY the content
    -- card, tab bar stays visible and clickable the whole time.
    --==================================================
    local function toggleCard()
        cardHidden = not cardHidden
        main.Visible = not cardHidden
        hideBtn.Text = cardHidden and "▸" or "▾"
    end
    hideBtn.MouseButton1Click:Connect(toggleCard)


    --==================================================
    -- CIRCULAR "ZD" LOGO (always visible from the start, floating
    -- independently of the dashboard. Tapping it toggles the dashboard
    -- show/hide, but the logo itself never disappears — script keeps
    -- running the whole time since nothing gets Destroy()'d here.)
    --==================================================
    local logo = Instance.new("TextButton")
    logo.Name = "ZDLogo"
    logo.Size = UDim2.fromOffset(52, 52)
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0, 46, 0, 90)
    logo.BackgroundColor3 = BG
    logo.AutoButtonColor = false
    logo.Text = ""
    logo.Visible = true
    logo.ZIndex = 50
    logo.Parent = gui
    corner(logo, 26) -- perfect circle at 52x52
    uistroke(logo, STROKE, 1, 0.15)
    gradient(logo, Color3.fromRGB(60, 60, 60), Color3.fromRGB(30, 30, 30), 90)

    local logoZ = Instance.new("TextLabel")
    logoZ.Size = UDim2.fromOffset(36, 36)
    logoZ.AnchorPoint = Vector2.new(0.5, 0.5)
    logoZ.Position = UDim2.new(0.5, -5, 0.5, -2)
    logoZ.BackgroundTransparency = 1
    logoZ.Text = "Z"
    logoZ.TextColor3 = ACCENT
    logoZ.TextTransparency = 0.15
    logoZ.TextSize = 22
    logoZ.Font = Enum.Font.GothamBlack
    logoZ.ZIndex = 51
    logoZ.Parent = logo

    local logoD = Instance.new("TextLabel")
    logoD.Size = UDim2.fromOffset(36, 36)
    logoD.AnchorPoint = Vector2.new(0.5, 0.5)
    logoD.Position = UDim2.new(0.5, 6, 0.5, 3)
    logoD.BackgroundTransparency = 1
    logoD.Text = "D"
    logoD.TextColor3 = TEXT
    logoD.TextSize = 22
    logoD.Font = Enum.Font.GothamBlack
    logoD.ZIndex = 52
    logoD.Parent = logo

    -- small live status dot on the logo, mirrors state.isHunting
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

    --==================================================
    -- MINI Z×D BURST (lightweight tap feedback, same visual
    -- language as the ZxD loading screen but tiny & fast: a
    -- handful of small squares pop out from the logo and fade,
    -- instead of the full 35-cell assemble/disperse sequence.
    -- Cheap: ~9 frames, short-range tweens, no bounce easing.
    --==================================================
    local burstColors = { ACCENT, TEXT, ACCENT_2 }

    local function playLogoBurst()
        for i = 1, 9 do
            local angle = (i / 9) * math.pi * 2
            local dist = 34

            local particle = Instance.new("Frame")
            particle.Size = UDim2.fromOffset(6, 6)
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.Position = UDim2.new(0.5, 0, 0.5, 0)
            particle.BackgroundColor3 = burstColors[(i % 3) + 1]
            particle.BorderSizePixel = 0
            particle.ZIndex = 49
            particle.Parent = logo
            corner(particle, 2)

            local targetX = math.cos(angle) * dist
            local targetY = math.sin(angle) * dist

            tween(particle, 0.28, {
                Position = UDim2.new(0.5, targetX, 0.5, targetY),
                BackgroundTransparency = 1,
                Rotation = math.random(-60, 60),
            }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            task.delay(0.28, function()
                particle:Destroy()
            end)
        end

        -- logo itself gives a quick punchy scale-down/up, like a heartbeat tap
        tween(logo, 0.08, { Size = UDim2.fromOffset(46, 46) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(0.08, function()
            tween(logo, 0.12, { Size = UDim2.fromOffset(52, 52) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
    end

    -- Logo toggles EVERYTHING (both the tab bar and the content card).
    -- The tab bar's own hideBtn (▾/▸) only ever toggles the content
    -- card by itself — that's the "just hide the card" behavior from
    -- the tab bar; the logo is the "hide absolutely everything" switch.
    local everythingHidden = false

    local function toggleEverything()
        everythingHidden = not everythingHidden
        tabBarFrame.Visible = not everythingHidden
        main.Visible = not everythingHidden and not cardHidden
    end

    -- ---- logo drag (independent of main window; tap still opens it) ----
    local logoDragging = false
    local logoDragStart
    local logoStartPos
    local logoMoved = false
    local LOGO_DRAG_THRESHOLD = 6 -- pixels of movement before it counts as a drag, not a tap

    logo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            logoDragging = true
            logoMoved = false
            logoDragStart = input.Position
            logoStartPos = logo.Position
        end
    end)

    logo.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            logoDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not logoDragging then return end
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - logoDragStart

            if math.abs(delta.X) > LOGO_DRAG_THRESHOLD or math.abs(delta.Y) > LOGO_DRAG_THRESHOLD then
                logoMoved = true
            end

            if logoMoved then
                logo.Position = UDim2.new(
                    logoStartPos.X.Scale,
                    logoStartPos.X.Offset + delta.X,
                    logoStartPos.Y.Scale,
                    logoStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    logo.MouseButton1Click:Connect(function()
        if logoMoved then
            return -- was a drag, not a tap; don't toggle visibility
        end
        playLogoBurst()
        toggleEverything()
    end)

    -- keep the logo's status dot live at all times, collapsed or not
    task.spawn(function()
        while gui.Parent do
            task.wait(0.3)
            if state.isHunting then
                logoStatusDot.BackgroundColor3 = state.currentTargetPlayer and RED or GREEN
            else
                logoStatusDot.BackgroundColor3 = MUTED
            end
        end
    end)

    --==================================================
    -- STOP CONFIRMATION POPUP (tombol X → Yes/No, bukan langsung destroy)
    --==================================================
    local confirmBackdrop = Instance.new("TextButton")
    confirmBackdrop.Size = UDim2.fromScale(1, 1)
    confirmBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    confirmBackdrop.BackgroundTransparency = 1
    confirmBackdrop.Text = ""
    confirmBackdrop.AutoButtonColor = false
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
    gradient(confirmPopup, Color3.fromRGB(45, 45, 45), Color3.fromRGB(25, 25, 25), 90)

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

    local confirmDesc = Instance.new("TextLabel")
    confirmDesc.Size = UDim2.new(1, -32, 0, 34)
    confirmDesc.Position = UDim2.fromOffset(16, 42)
    confirmDesc.BackgroundTransparency = 1
    confirmDesc.Text = "Script akan berhenti total dan dashboard akan ditutup. Yakin?"
    confirmDesc.TextColor3 = MUTED
    confirmDesc.TextSize = 10
    confirmDesc.Font = Enum.Font.Gotham
    confirmDesc.TextXAlignment = Enum.TextXAlignment.Left
    confirmDesc.TextWrapped = true
    confirmDesc.ZIndex = 92
    confirmDesc.Parent = confirmPopup

    local function confirmButton(text, xOffset, bgColor, textColor)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.5, -20, 0, 34)
        b.Position = UDim2.new(0, xOffset, 1, -50)
        b.BackgroundColor3 = bgColor
        b.AutoButtonColor = false
        b.Text = text
        b.TextColor3 = textColor
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 92
        b.Parent = confirmPopup
        corner(b, 9)
        pressFeedback(b, bgColor, bgColor == RED and Color3.fromRGB(190, 75, 80) or CARD2)
        return b
    end

    local yesBtn = confirmButton("YA, HAPUS", 16, RED, Color3.fromRGB(255, 255, 255))
    local noBtn = confirmButton("BATAL", 128, CARD2, TEXT)
    uistroke(noBtn, STROKE, 1, 0.4)

    local function openConfirm()
        confirmBackdrop.Visible = true
        confirmPopup.Visible = true
        confirmBackdrop.BackgroundTransparency = 1
        confirmPopup.Size = UDim2.fromOffset(220, 126)

        tween(confirmBackdrop, 0.15, { BackgroundTransparency = 0.5 })
        tween(confirmPopup, 0.16, { Size = UDim2.fromOffset(240, 140) })
    end

    local function closeConfirm()
        tween(confirmBackdrop, 0.15, { BackgroundTransparency = 1 })
        local t = tween(
            confirmPopup,
            0.14,
            { Size = UDim2.fromOffset(220, 126) },
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        )
        t.Completed:Connect(function()
            confirmPopup.Visible = false
            confirmBackdrop.Visible = false
        end)
    end

    stopBtn.MouseButton1Click:Connect(openConfirm)
    confirmBackdrop.MouseButton1Click:Connect(closeConfirm)
    noBtn.MouseButton1Click:Connect(closeConfirm)

    yesBtn.MouseButton1Click:Connect(function()
        state.stopRequested = true -- auto.lua polls this to kill its own loops/connections
        closeConfirm()
        tween(main, 0.14, { Size = UDim2.fromOffset(6, 6) })
        tween(logo, 0.14, { Size = UDim2.fromOffset(6, 6) })
        task.delay(0.14, function()
            gui:Destroy()
        end)
    end)

    --==================================================
    -- SKIP LOGIC (unchanged behavior, new visuals)
    --==================================================
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

    --==================================================
    -- SERVER HOP LOGIC — reads directly from _G.PersistentReadyJobIds,
    -- which auto.lua's background scanner fills. No separate scanner
    -- here anymore (that was the bug: two independent scanners existed,
    -- and only auto.lua's ever actually filled up, so this button never
    -- saw it and stayed stuck on "MENCARI...").
    --==================================================
    _G.PersistentReadyJobIds = _G.PersistentReadyJobIds or {}
    local isHoppingNow = false

    task.spawn(function()
        while task.wait(0.3) do
            if not isHoppingNow then
                local count = #_G.PersistentReadyJobIds
                if count > 0 then
                    hopLabel.Text = "HOP (" .. count .. " SIAP)"
                    tween(hopDot, 0.15, { BackgroundColor3 = GREEN })
                else
                    hopLabel.Text = "MENCARI..."
                    tween(hopDot, 0.15, { BackgroundColor3 = ORANGE })
                end
            end
        end
    end)

    hopBtn.MouseButton1Click:Connect(function()
        if isHoppingNow then return end
        if #_G.PersistentReadyJobIds > 0 then
            isHoppingNow = true

            local function attemptHop()
                local targetJobId = table.remove(_G.PersistentReadyJobIds, 1)
                if not targetJobId then
                    -- ran out of candidates in the queue
                    hopLabel.Text = "GAGAL, ULANGI"
                    tween(hopDot, 0.15, { BackgroundColor3 = RED })
                    task.wait(1.2)
                    isHoppingNow = false
                    return
                end

                hopLabel.Text = "JOINING..."
                tween(hopDot, 0.15, { BackgroundColor3 = GREEN })

                local ok = pcall(function()
                    local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
                    if serverBrowser then
                        serverBrowser:InvokeServer("teleport", targetJobId)
                    end
                end)

                -- If we're still here after ~2s, the teleport likely failed silently
                -- (server full / rejected) rather than actually switching servers.
                -- Try the next candidate in the queue instead of just giving up.
                task.wait(2)

                if not ok then
                    if #_G.PersistentReadyJobIds > 0 then
                        hopLabel.Text = "SERVER PENUH, COBA LAGI..."
                        attemptHop()
                        return
                    else
                        hopLabel.Text = "GAGAL, ULANGI"
                        tween(hopDot, 0.15, { BackgroundColor3 = RED })
                        task.wait(1.2)
                    end
                end

                isHoppingNow = false
            end

            attemptHop()
        end
    end)

    --==================================================
    -- STATUS INDICATOR LOOP (read-only reflection of isHunting)
    --==================================================
    local statusPulseConn
    task.spawn(function()
        local t = 0
        while gui.Parent do
            task.wait(0.3)
            t = t + 0.3
            if state.isHunting then
                if state.currentTargetPlayer then
                    tabBarStatusDot.BackgroundColor3 = RED
                else
                    tabBarStatusDot.BackgroundColor3 = GREEN
                end
            else
                tabBarStatusDot.BackgroundColor3 = MUTED
            end

            if infoValues["TOTAL"] then
                local total = state.totalHadiah or 0
                local formattedTotal = tostring(math.floor(total))
                if total >= 1000000 then
                    formattedTotal = string.format("%.1fM", total / 1000000)
                elseif total >= 1000 then
                    formattedTotal = string.format("%.1fK", total / 1000)
                end
                infoValues["TOTAL"].Text = "◈ " .. formattedTotal
            end
        end
    end)

    --==================================================
    -- LIVE DISTANCE UPDATE (JARAK field refreshes continuously while
    -- a target is active, instead of only once when the target was
    -- first found — distance changes as both players move, so this
    -- needs its own fast loop separate from updateHUDDisplay).
    --==================================================
    task.spawn(function()
        while gui.Parent do
            task.wait(0.2)

            if not infoValues["JARAK"] then
                -- infoValues["JARAK"] missing entirely; shouldn't happen but log once if so
            elseif not state.currentTargetPlayer then
                -- no active target right now, nothing to update
            elseif not state.currentTargetPlayer.Parent then
                print("[JARAK DEBUG] state.currentTargetPlayer.Parent is nil (target left?), skipping update")
            else
                local ok, err = pcall(function()
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local targetChar = state.currentTargetPlayer.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                    if not myRoot then
                        print("[JARAK DEBUG] myRoot nil (LocalPlayer character/HRP missing)")
                    elseif not targetRoot then
                        print("[JARAK DEBUG] targetRoot nil (target character/HRP missing)")
                    else
                        local d = (myRoot.Position - targetRoot.Position).Magnitude
                        infoValues["JARAK"].Text = tostring(math.floor(d)) .. " studs"
                    end
                end)
                if not ok then
                    print("[JARAK DEBUG] pcall error:", err)
                end
            end
        end
    end)

    -- Expose refs for updateHUDDisplay / auto.lua to use
    UIRefs.infoValues = infoValues
    UIRefs.addTargetLogEntry = addTargetLogEntry
end

--==================================================
-- HUD UPDATE (fills TARGET INFO card fields live)
--==================================================
local LocalPlayer = game:GetService("Players").LocalPlayer

local function updateHUDDisplay(player)
    pcall(function()
        if not UIRefs.infoValues then return end
        local iv = UIRefs.infoValues

        if player and player.Parent then
            local leaderstats = player:FindFirstChild("leaderstats")
            local dataFolder = player:FindFirstChild("Data")

            local lvVal = player:FindFirstChild("Level") or (dataFolder and dataFolder:FindFirstChild("Level")) or "2550"
            local bountyVal = leaderstats and (leaderstats:FindFirstChild("Bounty/Honor") or leaderstats:FindFirstChild("Bounty"))

            local formattedBounty = bountyVal and tostring(bountyVal.Value) or "-"
            if bountyVal and bountyVal.Value >= 1000000 then
                formattedBounty = string.format("%.1fM", bountyVal.Value / 1000000)
            elseif bountyVal and bountyVal.Value >= 1000 then
                formattedBounty = string.format("%.1fK", bountyVal.Value / 1000)
            end

            local distanceText = "-"
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local targetChar = player.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    local d = (myRoot.Position - targetRoot.Position).Magnitude
                    distanceText = tostring(math.floor(d)) .. " studs"
                end
            end)

            if iv["STATUS"] then iv["STATUS"].Text = "Menyerang!" end
            if iv["NAMA"] then iv["NAMA"].Text = player.Name end
            if iv["LEVEL"] then iv["LEVEL"].Text = tostring(lvVal.Value or lvVal) end
            if iv["JARAK"] then iv["JARAK"].Text = distanceText end
            if iv["BOUNTY"] then iv["BOUNTY"].Text = "◈ " .. formattedBounty end
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
        if UIRefs.addTargetLogEntry then
            UIRefs.addTargetLogEntry(entryText)
        end
    end)
end

--==================================================
-- MODULE RETURN
--==================================================
return {
    createNewLayoutUI = createNewLayoutUI,
    updateHUDDisplay = updateHUDDisplay,
    addTargetLogEntry = addTargetLogEntry,
    UIRefs = UIRefs,
}

end -- UIModule.Init

return UIModule
