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

-- ---- palette ----
local BG        = Color3.fromRGB(18, 18, 20)
local CARD      = Color3.fromRGB(26, 26, 29)
local CARD2     = Color3.fromRGB(33, 33, 37)
local STROKE    = Color3.fromRGB(50, 50, 55)
local TEXT      = Color3.fromRGB(240, 240, 242)
local MUTED     = Color3.fromRGB(148, 148, 155)
local ACCENT    = Color3.fromRGB(235, 235, 240)
local ACCENT_2  = Color3.fromRGB(205, 205, 212)
local ACCENT_TEXT = Color3.fromRGB(20, 20, 22)
local GREEN     = Color3.fromRGB(96, 200, 145)
local ORANGE    = Color3.fromRGB(220, 165, 90)
local RED       = Color3.fromRGB(225, 95, 100)

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

    --==================================================
    -- MAIN WINDOW
    --==================================================
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(390, 246)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.46, 0)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.ClipsDescendants = false
    main.Parent = gui
    corner(main, 14)
    uistroke(main, STROKE, 1, 0.2)
    gradient(main, Color3.fromRGB(18, 19, 24), Color3.fromRGB(13, 14, 17), 90)

    --==================================================
    -- HEADER
    --==================================================
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 46)
    header.BackgroundTransparency = 1
    header.Parent = main

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.fromOffset(3, 22)
    accentBar.Position = UDim2.fromOffset(14, 12)
    accentBar.BackgroundColor3 = ACCENT
    accentBar.BorderSizePixel = 0
    accentBar.Parent = header
    corner(accentBar, 2)
    gradient(accentBar, ACCENT, ACCENT_2, 90)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -140, 0, 18)
    title.Position = UDim2.fromOffset(26, 8)
    title.BackgroundTransparency = 1
    title.Text = "BOUNTY HUNTER"
    title.TextColor3 = TEXT
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitleRow = Instance.new("Frame")
    subtitleRow.Size = UDim2.new(1, -140, 0, 12)
    subtitleRow.Position = UDim2.fromOffset(26, 25)
    subtitleRow.BackgroundTransparency = 1
    subtitleRow.Parent = header

    -- Status indicator (READ-ONLY: reflects isHunting, not clickable to stop)
    local statusBtn = Instance.new("Frame")
    statusBtn.Size = UDim2.fromOffset(64, 22)
    statusBtn.AnchorPoint = Vector2.new(1, 0)
    statusBtn.Position = UDim2.new(1, -118, 0, 12)
    statusBtn.BackgroundColor3 = CARD2
    statusBtn.Parent = header
    corner(statusBtn, 7)
    uistroke(statusBtn, STROKE, 1, 0.4)

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.fromOffset(6, 6)
    statusDot.AnchorPoint = Vector2.new(0, 0.5)
    statusDot.Position = UDim2.new(0, 8, 0.5, 0)
    statusDot.BackgroundColor3 = MUTED
    statusDot.BorderSizePixel = 0
    statusDot.Parent = statusBtn
    corner(statusDot, 99)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 1, 0)
    statusLabel.Position = UDim2.fromOffset(18, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "IDLE"
    statusLabel.TextColor3 = TEXT
    statusLabel.TextSize = 9
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = statusBtn

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 12)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Bounty Assistant"
    subtitle.TextColor3 = MUTED
    subtitle.TextSize = 9
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = subtitleRow

    -- header buttons: minimize / close
    local function headerButton(icon, xOffsetFromRight, size)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(size or 30, size or 30)
        b.AnchorPoint = Vector2.new(1, 0)
        b.Position = UDim2.new(1, -xOffsetFromRight, 0, 8)
        b.BackgroundColor3 = CARD2
        b.BackgroundTransparency = 1
        b.Text = icon
        b.TextColor3 = MUTED
        b.TextSize = 14
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = header
        corner(b, 8)

        b.MouseButton1Down:Connect(function()
            tween(b, 0.08, { BackgroundTransparency = 0, BackgroundColor3 = CARD2 })
        end)
        b.MouseButton1Up:Connect(function()
            tween(b, 0.12, { BackgroundTransparency = 1 })
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.12, { BackgroundTransparency = 1 })
        end)

        return b
    end

    local hideBtn = headerButton("><", 10, 34)
    hideBtn.TextSize = 11

    local stopBtn = headerButton("×", 46, 30)
    stopBtn.TextSize = 17

    --==================================================
    -- DIVIDER
    --==================================================
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -28, 0, 1)
    divider.Position = UDim2.fromOffset(14, 46)
    divider.BackgroundColor3 = STROKE
    divider.BackgroundTransparency = 0.3
    divider.BorderSizePixel = 0
    divider.Parent = main

    --==================================================
    -- LEFT SIDE — CONTROLS
    --==================================================
    local left = Instance.new("Frame")
    left.Size = UDim2.fromOffset(172, 138)
    left.Position = UDim2.fromOffset(14, 56)
    left.BackgroundTransparency = 1
    left.Parent = main

    local controlsTitle = Instance.new("TextLabel")
    controlsTitle.Size = UDim2.new(1, 0, 0, 16)
    controlsTitle.BackgroundTransparency = 1
    controlsTitle.Text = "CONTROLS"
    controlsTitle.TextColor3 = MUTED
    controlsTitle.TextSize = 9
    controlsTitle.Font = Enum.Font.GothamBold
    controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
    controlsTitle.Parent = left

    local function controlButton(text, y, height)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, height or 34)
        b.Position = UDim2.fromOffset(0, y)
        b.BackgroundColor3 = CARD
        b.AutoButtonColor = false
        b.Text = ""
        b.Parent = left
        corner(b, 8)
        uistroke(b, STROKE, 1, 0.5)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -22, 1, 0)
        label.Position = UDim2.fromOffset(11, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = TEXT
        label.TextSize = 10
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = b

        pressFeedback(b, CARD, CARD2)

        return b, label
    end

    -- SKIP TARGET (wired to real skip logic)
    local skipBtn, skipLabel = controlButton("SKIP TARGET", 20, 34)

    -- HOP SERVER (status button — text/color updated live from readyJobIds)
    local hopBtn = Instance.new("TextButton")
    hopBtn.Size = UDim2.new(1, 0, 0, 34)
    hopBtn.Position = UDim2.fromOffset(0, 60)
    hopBtn.BackgroundColor3 = CARD
    hopBtn.AutoButtonColor = false
    hopBtn.Text = ""
    hopBtn.Parent = left
    corner(hopBtn, 8)
    uistroke(hopBtn, STROKE, 1, 0.5)

    local hopDot = Instance.new("Frame")
    hopDot.Size = UDim2.fromOffset(6, 6)
    hopDot.AnchorPoint = Vector2.new(0, 0.5)
    hopDot.Position = UDim2.new(0, 11, 0.5, 0)
    hopDot.BackgroundColor3 = ORANGE
    hopDot.BorderSizePixel = 0
    hopDot.Parent = hopBtn
    corner(hopDot, 99)

    local hopLabel = Instance.new("TextLabel")
    hopLabel.Size = UDim2.new(1, -30, 1, 0)
    hopLabel.Position = UDim2.fromOffset(22, 0)
    hopLabel.BackgroundTransparency = 1
    hopLabel.Text = "MENCARI..."
    hopLabel.TextColor3 = TEXT
    hopLabel.TextSize = 10
    hopLabel.Font = Enum.Font.GothamMedium
    hopLabel.TextXAlignment = Enum.TextXAlignment.Left
    hopLabel.Parent = hopBtn

    pressFeedback(hopBtn, CARD, CARD2)

    -- placeholder third slot (kept empty; skill selector removed per request)
    local infoSmall = Instance.new("TextLabel")
    infoSmall.Size = UDim2.new(1, 0, 0, 34)
    infoSmall.Position = UDim2.fromOffset(0, 100)
    infoSmall.BackgroundTransparency = 1
    infoSmall.Text = ""
    infoSmall.TextColor3 = MUTED
    infoSmall.TextSize = 8
    infoSmall.Font = Enum.Font.Gotham
    infoSmall.Parent = left

    --==================================================
    -- RIGHT SIDE — TARGET INFO
    --==================================================
    local info = Instance.new("Frame")
    info.Size = UDim2.fromOffset(176, 138)
    info.Position = UDim2.fromOffset(200, 56)
    info.BackgroundColor3 = CARD
    info.BorderSizePixel = 0
    info.Parent = main
    corner(info, 10)
    uistroke(info, STROKE, 1, 0.5)

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -20, 0, 18)
    infoTitle.Position = UDim2.fromOffset(11, 8)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "TARGET INFO"
    infoTitle.TextColor3 = MUTED
    infoTitle.TextSize = 9
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = info

    local infoValues = {}

    local function infoRow(name, value, y)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -22, 0, 17)
        row.Position = UDim2.fromOffset(11, y)
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

    infoRow("STATUS", "Idle / Mencari...", 30)
    infoRow("NAMA", "-", 49)
    infoRow("LEVEL", "-", 68)
    infoRow("JARAK", "-", 87)

    local miniDivider = Instance.new("Frame")
    miniDivider.Size = UDim2.new(1, -22, 0, 1)
    miniDivider.Position = UDim2.fromOffset(11, 104)
    miniDivider.BackgroundColor3 = STROKE
    miniDivider.BackgroundTransparency = 0.4
    miniDivider.BorderSizePixel = 0
    miniDivider.Parent = info

    local bountyRow = Instance.new("Frame")
    bountyRow.Size = UDim2.new(1, -22, 0, 22)
    bountyRow.Position = UDim2.fromOffset(11, 108)
    bountyRow.BackgroundTransparency = 1
    bountyRow.Parent = info

    local bountyLabel = Instance.new("TextLabel")
    bountyLabel.Size = UDim2.new(0.5, 0, 1, 0)
    bountyLabel.BackgroundTransparency = 1
    bountyLabel.Text = "BOUNTY"
    bountyLabel.TextColor3 = MUTED
    bountyLabel.TextSize = 9
    bountyLabel.Font = Enum.Font.GothamBold
    bountyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bountyLabel.Parent = bountyRow

    local bountyValue = Instance.new("TextLabel")
    bountyValue.Size = UDim2.new(0.5, 0, 1, 0)
    bountyValue.Position = UDim2.new(0.5, 0, 0, 0)
    bountyValue.BackgroundTransparency = 1
    bountyValue.Text = "◈ -"
    bountyValue.TextColor3 = ACCENT
    bountyValue.TextSize = 11
    bountyValue.Font = Enum.Font.GothamBold
    bountyValue.TextXAlignment = Enum.TextXAlignment.Right
    bountyValue.Parent = bountyRow

    infoValues["BOUNTY"] = bountyValue

    --==================================================
    -- SPEED SLIDER (1 - 350, real unit from _G.CustomFlightSpeed)
    --==================================================
    local speedRow = Instance.new("Frame")
    speedRow.Size = UDim2.new(1, -28, 0, 34)
    speedRow.Position = UDim2.fromOffset(14, 202)
    speedRow.BackgroundTransparency = 1
    speedRow.Parent = main

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
    speedBar.BackgroundColor3 = Color3.fromRGB(48, 51, 59)
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
    gradient(logo, Color3.fromRGB(20, 21, 26), Color3.fromRGB(13, 14, 17), 90)

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

    local MAIN_FULL = UDim2.fromOffset(390, 246)

    -- Logo is always visible and independent of this show/hide toggle.
    -- Clicking the logo now hides the ENTIRE dashboard (main.Visible = false),
    -- not just a resize down to a title strip — nothing about the script
    -- stops running in the background either way.
    local function collapseDashboard()
        state.uiHidden = true
        main.Visible = false
    end

    local function expandDashboard()
        state.uiHidden = false
        main.Visible = true
        main.Size = MAIN_FULL
    end

    local dashboardCollapsed = false

    local function toggleDashboard()
        dashboardCollapsed = not dashboardCollapsed
        if dashboardCollapsed then
            collapseDashboard()
        else
            expandDashboard()
        end
    end

    hideBtn.MouseButton1Click:Connect(toggleDashboard)

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
            return -- was a drag, not a tap; don't toggle the dashboard
        end
        playLogoBurst()
        toggleDashboard()
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
    -- DRAG
    --==================================================
    local dragging = false
    local dragStart
    local startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
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
                    statusLabel.Text = "HUNTING"
                    statusDot.BackgroundColor3 = RED
                else
                    statusLabel.Text = "SCANNING"
                    statusDot.BackgroundColor3 = GREEN
                end
            else
                statusLabel.Text = "IDLE"
                statusDot.BackgroundColor3 = MUTED
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

            if infoValues["JARAK"] and state.currentTargetPlayer and state.currentTargetPlayer.Parent then
                pcall(function()
                    local LocalPlayer = game:GetService("Players").LocalPlayer
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local targetChar = state.currentTargetPlayer.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                    if myRoot and targetRoot then
                        local d = (myRoot.Position - targetRoot.Position).Magnitude
                        infoValues["JARAK"].Text = tostring(math.floor(d)) .. " studs"
                    end
                end)
            end
        end
    end)

    -- Expose refs for updateHUDDisplay to use
    UIRefs.infoValues = infoValues
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

--==================================================
-- MODULE RETURN
--==================================================
return {
    createNewLayoutUI = createNewLayoutUI,
    updateHUDDisplay = updateHUDDisplay,
    UIRefs = UIRefs,
}

end -- UIModule.Init

return UIModule
