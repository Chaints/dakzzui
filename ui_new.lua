-- ==========================================
-- ui.lua — Dashboard UI shell (visual/layout ONLY)
-- Loaded via loadstring(game:HttpGet(...))() and runs immediately —
-- no extra .Init(...) or .createUI() call needed from the loader.
--
-- IMPORTANT: this file is UI/layout ONLY. It has no auto-hunting,
-- auto-targeting, or auto-combat logic of any kind. Every value shown
-- (status text, target name, HP%, kill count, log lines, etc.) is a
-- static placeholder. To make this dashboard reflect real data, wire
-- your own separate script to the functions exposed in UIRefs at the
-- bottom of this file (setStatus, setTargetInfo, addLogLine, etc.) —
-- this file itself does not read game state, players, or combat data.
-- ==========================================

local UIModule = {}

-- Auto-detect a safe parent to put the ScreenGui under, since this
-- file now runs itself immediately rather than waiting for the loader
-- to pass one in. Prefers gethui() (executor-provided hidden UI
-- container) when available, falling back to CoreGui, then PlayerGui.
local function getSafeUIParent()
    local ok, result = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    if ok and result then return result end

    local ok2, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok2 and coreGui then return coreGui end

    local player = game:GetService("Players").LocalPlayer
    return player and player:FindFirstChild("PlayerGui")
end

function UIModule.Init(SafeUIParent)

local UI_NAME = "Dashboard"

-- ---- palette (warm sand & dark wood, matches the reference image) ----
local BG_CARD    = Color3.fromRGB(40, 15, 20)    -- dark maroon-brown card bg
local BG_CARD2   = Color3.fromRGB(55, 22, 26)    -- slightly lighter, for nested panels
local STROKE     = Color3.fromRGB(90, 45, 35)    -- warm brown border
local SAND       = Color3.fromRGB(235, 205, 150) -- pill/tab background
local SAND_TEXT  = Color3.fromRGB(50, 25, 15)    -- dark text on sand pills
local TEXT       = Color3.fromRGB(240, 220, 190) -- main light text on dark cards
local MUTED      = Color3.fromRGB(190, 160, 130) -- dimmer text
local GREEN      = Color3.fromRGB(110, 200, 120)
local GREEN_DARK = Color3.fromRGB(30, 60, 35)

-- ---- helpers ----
local TweenService = game:GetService("TweenService")

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
    s.Transparency = transparency or 0.2
    s.Parent = obj
    return s
end

local function tween(obj, duration, props)
    local info = TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function label(parent, text, pos, size, textSize, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Text = text
    l.TextColor3 = color or TEXT
    l.TextSize = textSize or 14
    l.Font = font or Enum.Font.GothamMedium
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

-- References exposed for an external script to push live data into.
-- This file never calls these itself — it only defines them.
local UIRefs = {}

local function createUI()
    if not SafeUIParent then return end
    if SafeUIParent:FindFirstChild(UI_NAME) then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = UI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = SafeUIParent

    --==================================================
    -- ROOT — invisible anchor everything positions relative to.
    -- Width clamps to a sane pixel range across phone/tablet/PC.
    --==================================================
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.AnchorPoint = Vector2.new(0.5, 0)
    root.Position = UDim2.new(0.5, 0, 0, 8)
    -- Scale-based (percentage of screen), not fixed pixels, so the
    -- whole dashboard shrinks/grows with the actual device screen
    -- instead of being oversized on phones. Height is clamped so it
    -- never exceeds roughly 40% of the screen — everything fits in
    -- one glance without scrolling.
    root.Size = UDim2.new(0.94, 0, 0.4, 0)
    root.BackgroundTransparency = 1
    root.Parent = gui

    --==================================================
    -- NAVBAR — pill-shaped bar with 7 rounded tab buttons in a row.
    -- All positions are computed manually (no UIListLayout/UIGridLayout
    -- driving critical placement) so nothing can silently fail to
    -- position itself on any executor.
    --==================================================
    local navbar = Instance.new("Frame")
    navbar.Name = "Navbar"
    navbar.Size = UDim2.new(1, 0, 0.22, 0) -- slim strip, ~22% of root height
    navbar.Position = UDim2.new(0, 0, 0, 0)
    navbar.BackgroundColor3 = BG_CARD
    navbar.BorderSizePixel = 0
    navbar.ZIndex = 10
    navbar.Parent = root
    corner(navbar, 16)
    uistroke(navbar, STROKE, 1, 0.15)

    local tabNames = { "DASHBOARD", "TARGETS", "COMBAT", "SERVER HOP", "SETTINGS", "SUPPORT", "CREDITS" }
    local tabButtons = {}
    local tabContainers = {}
    local activeTabName = "DASHBOARD"

    -- Manual layout math: each tab gets equal Scale width minus its
    -- share of the total gap, positioned cumulatively left-to-right.
    local TAB_COUNT = #tabNames
    local TAB_GAP = 4
    local SIDE_PADDING = 8
    local totalGap = TAB_GAP * (TAB_COUNT - 1)

    local function createTabButton(name, index)
        local sizeScale = 1 / TAB_COUNT
        local sizeOffset = -(totalGap / TAB_COUNT) - (SIDE_PADDING * 2 / TAB_COUNT)
        local posScale = sizeScale * index
        local posOffset = SIDE_PADDING + (sizeOffset * index) + (TAB_GAP * index)

        local b = Instance.new("TextButton")
        b.Name = name .. "Tab"
        b.AnchorPoint = Vector2.new(0, 0.5)
        b.Position = UDim2.new(posScale, posOffset, 0.5, 0)
        b.Size = UDim2.new(sizeScale, sizeOffset, 0.7, 0)
        b.BackgroundColor3 = SAND
        b.AutoButtonColor = false
        b.Text = name
        b.TextColor3 = SAND_TEXT
        b.TextSize = 7
        b.TextScaled = true
        b.Font = Enum.Font.GothamBold
        b.ZIndex = 12
        b.Parent = navbar
        corner(b, 10)

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 3)
        pad.Parent = b

        tabButtons[name] = b
        return b
    end

    for i, name in ipairs(tabNames) do
        createTabButton(name, i - 1)
    end

    --==================================================
    -- CONTENT LAYER — holds one container Frame per tab. Only the
    -- active tab's container is Visible; others are hidden. Each
    -- container's internal contents also use manual Position (no
    -- UIListLayout) for the same reliability reason as the navbar.
    --==================================================
    local contentLayer = Instance.new("Frame")
    contentLayer.Name = "ContentLayer"
    contentLayer.Position = UDim2.new(0, 0, 0.22, 6) -- right after the navbar's 0.22 scale height + small gap
    contentLayer.Size = UDim2.new(1, 0, 0.78, -6)
    contentLayer.BackgroundTransparency = 1
    contentLayer.Parent = root

    local function newTabContainer(name)
        local c = Instance.new("Frame")
        c.Name = name .. "Container"
        c.Size = UDim2.new(1, 0, 1, 0)
        c.BackgroundTransparency = 1
        c.Visible = (name == "DASHBOARD")
        c.Parent = contentLayer
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
                tween(btn, 0.12, { BackgroundColor3 = Color3.fromRGB(255, 225, 170) })
            else
                tween(btn, 0.12, { BackgroundColor3 = SAND })
            end
        end
    end

    for name, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            setActiveTab(name)
        end)
    end

    --==================================================
    -- CARD HELPER — a rounded dark card at a given position/size.
    --==================================================
    local function newCard(parent, pos, size)
        local card = Instance.new("Frame")
        card.BackgroundColor3 = BG_CARD
        card.BorderSizePixel = 0
        card.Position = pos
        card.Size = size
        card.Parent = parent
        corner(card, 20)
        uistroke(card, STROKE, 1, 0.2)
        return card
    end

    --==================================================
    -- TAB: DASHBOARD
    -- Left card: MASTER STATUS. Right card: TARGET INFO (with avatar
    -- placeholder + HP bar). Below both: scrolling activity log.
    --==================================================
    local dashTab = newTabContainer("DASHBOARD")

    -- Top row (status + target cards) takes 60% of dashTab height,
    -- log card takes the rest — all Scale-based so it compresses
    -- proportionally on any screen size instead of overflowing.
    local TOP_ROW_HEIGHT = 0.58

    -- Left card: master status summary
    local statusCard = newCard(dashTab, UDim2.new(0, 0, 0, 0), UDim2.new(0.48, -4, TOP_ROW_HEIGHT, -4))

    local statusPill = Instance.new("Frame")
    statusPill.Size = UDim2.new(1, -16, 0.26, 0)
    statusPill.Position = UDim2.new(0, 8, 0.04, 0)
    statusPill.BackgroundTransparency = 1
    statusPill.Parent = statusCard

    label(statusPill, "MASTER AUTO BOUNTY", UDim2.new(0, 0, 0, 0), UDim2.new(0.6, 0, 1, 0), 10, TEXT, Enum.Font.GothamBold)

    local onPill = Instance.new("Frame")
    onPill.AnchorPoint = Vector2.new(1, 0.5)
    onPill.Position = UDim2.new(1, 0, 0.5, 0)
    onPill.Size = UDim2.new(0.28, 0, 0.7, 0)
    onPill.BackgroundColor3 = GREEN
    onPill.Parent = statusPill
    corner(onPill, 10)

    local onLabel = label(onPill, "ON", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), 9, GREEN_DARK, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    UIRefs.masterStatusPill = onPill
    UIRefs.masterStatusLabel = onLabel

    local statusLine1 = label(statusCard, "Status: Active Hunting", UDim2.new(0, 8, 0.34, 0), UDim2.new(1, -16, 0.15, 0), 8, TEXT)
    local statusLine2 = label(statusCard, "Current Region: Port Town", UDim2.new(0, 8, 0.49, 0), UDim2.new(1, -16, 0.15, 0), 8, TEXT)
    local statusLine3 = label(statusCard, "Region: Sandy Island - 90%", UDim2.new(0, 8, 0.64, 0), UDim2.new(1, -16, 0.15, 0), 8, MUTED)
    local statusLine4 = label(statusCard, "Bounty Filter: 500K - 100M", UDim2.new(0, 8, 0.79, 0), UDim2.new(1, -16, 0.15, 0), 8, MUTED)

    UIRefs.statusLines = { statusLine1, statusLine2, statusLine3, statusLine4 }

    -- Right card: target info with avatar + HP bar
    local targetCard = newCard(dashTab, UDim2.new(0.52, 4, 0, 0), UDim2.new(0.48, -4, TOP_ROW_HEIGHT, -4))

    local avatarSlot = Instance.new("Frame")
    avatarSlot.Size = UDim2.new(0.24, 0, 0.42, 0)
    avatarSlot.Position = UDim2.new(0, 8, 0.06, 0)
    avatarSlot.BackgroundColor3 = BG_CARD2
    avatarSlot.Parent = targetCard
    corner(avatarSlot, 8)
    uistroke(avatarSlot, STROKE, 1, 0.3)
    -- NOTE: no image set — plug in player thumbnail from your own
    -- script via UIRefs.avatarImage below if wanted.
    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(1, 0, 1, 0)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = ""
    avatarImage.Parent = avatarSlot
    corner(avatarImage, 8)
    UIRefs.avatarImage = avatarImage

    local targetName = label(targetCard, "Player_SwiftSword", UDim2.new(0.3, 0, 0.06, 0), UDim2.new(0.68, 0, 0.15, 0), 9, TEXT, Enum.Font.GothamBold)
    local targetBounty = label(targetCard, "Bounty: 4.8M+", UDim2.new(0.3, 0, 0.22, 0), UDim2.new(0.68, 0, 0.13, 0), 8, MUTED)
    local targetRank = label(targetCard, "Rank: Grandmaster", UDim2.new(0.3, 0, 0.36, 0), UDim2.new(0.68, 0, 0.13, 0), 8, MUTED)

    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(0.68, 0, 0.14, 0)
    hpBarBg.Position = UDim2.new(0.3, 0, 0.5, 0)
    hpBarBg.BackgroundColor3 = GREEN_DARK
    hpBarBg.Parent = targetCard
    corner(hpBarBg, 8)

    local hpBarFill = Instance.new("Frame")
    hpBarFill.Size = UDim2.new(0.95, 0, 1, 0) -- placeholder 95%
    hpBarFill.BackgroundColor3 = GREEN
    hpBarFill.Parent = hpBarBg
    corner(hpBarFill, 8)

    local hpLabel = label(hpBarFill, "HP: 95%", UDim2.new(0, 6, 0, 0), UDim2.new(1, -6, 1, 0), 7, GREEN_DARK, Enum.Font.GothamBold)
    UIRefs.hpBarFill = hpBarFill
    UIRefs.hpLabel = hpLabel
    UIRefs.targetName = targetName
    UIRefs.targetBounty = targetBounty
    UIRefs.targetRank = targetRank

    local killsLine = label(targetCard, "Total Kills: 875", UDim2.new(0, 8, 0.7, 0), UDim2.new(1, -16, 0.13, 0), 8, TEXT)
    local earnedLine = label(targetCard, "Earned Today: +150K", UDim2.new(0, 8, 0.85, 0), UDim2.new(1, -16, 0.13, 0), 8, TEXT)
    UIRefs.killsLine = killsLine
    UIRefs.earnedLine = earnedLine

    -- Activity log card (below both, fills remaining height)
    local logCard = newCard(dashTab, UDim2.new(0, 0, TOP_ROW_HEIGHT, 4), UDim2.new(1, 0, 1 - TOP_ROW_HEIGHT, -4))

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -12, 1, -12)
    logScroll.Position = UDim2.new(0, 6, 0, 6)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 3
    logScroll.ScrollBarImageColor3 = SAND
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.Parent = logCard

    local logListLayout = Instance.new("UIListLayout")
    logListLayout.Padding = UDim.new(0, 2)
    logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logListLayout.Parent = logScroll
    -- NOTE: UIListLayout here is fine — it's a simple vertical stack of
    -- log rows inside a ScrollingFrame, not the kind of nested
    -- multi-level positioning that failed before. If log entries ever
    -- fail to space out on some executor, switch to manual Y offsets
    -- (row height * index) the same way the navbar tabs are positioned.

    local logOrderCounter = 0
    local MAX_LOG_ENTRIES = 30

    local function addLogLine(text)
        logOrderCounter = logOrderCounter + 1
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, 0, 0, 12)
        row.LayoutOrder = logOrderCounter
        row.BackgroundTransparency = 1
        row.Text = text
        row.TextColor3 = TEXT
        row.TextSize = 8
        row.Font = Enum.Font.Gotham
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = logScroll

        local rows = {}
        for _, child in ipairs(logScroll:GetChildren()) do
            if child:IsA("TextLabel") then table.insert(rows, child) end
        end
        if #rows > MAX_LOG_ENTRIES then
            table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
            rows[1]:Destroy()
        end
    end
    UIRefs.addLogLine = addLogLine

    -- a few placeholder lines so the log card isn't empty on first load
    addLogLine("[00:00:00] Dashboard initialized (UI shell — no logic wired yet)")

    --==================================================
    -- TAB: TARGETS / COMBAT / SERVER HOP / SETTINGS / SUPPORT / CREDITS
    -- Empty placeholder cards for now — same style/corner/stroke as
    -- the dashboard cards, ready for you to fill in per tab.
    --==================================================
    local placeholderTabs = { "TARGETS", "COMBAT", "SERVER HOP", "SETTINGS", "SUPPORT", "CREDITS" }
    for _, name in ipairs(placeholderTabs) do
        local tab = newTabContainer(name)
        local placeholderCard = newCard(tab, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        label(placeholderCard, name .. " — placeholder", UDim2.new(0, 14, 0, 14), UDim2.new(1, -28, 0, 20), 14, MUTED, Enum.Font.GothamBold)
    end

    UIRefs.setActiveTab = setActiveTab
    UIRefs.gui = gui
    UIRefs.root = root
end

return {
    createUI = createUI,
    UIRefs = UIRefs,
}

end -- UIModule.Init

-- ==========================================
-- AUTO-RUN: build the UI immediately when this file loads, so
-- loadstring(game:HttpGet(url))() alone is enough — no separate
-- .Init(...) or .createUI() call is required from the loader script.
-- ==========================================
local parent = getSafeUIParent()
local instance = UIModule.Init(parent)
if instance then
    instance.createUI()
end

return instance
