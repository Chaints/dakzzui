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
--
-- LAYOUT MODEL (v2):
--   - DASHBOARD tab -> just ONE fixed card (Master Status). Always
--     visible, never closes, lives directly in `root`.
--   - TARGETS / COMBAT / SERVER HOP / SETTINGS / LOG tabs -> each
--     opens its own FLOATING panel next to root when clicked. Click
--     again to close (toggle). Max 3 floating panels open at once —
--     opening a 4th auto-closes the oldest (FIFO).
--   - Navbar trimmed from 7 tabs to 6: SUPPORT and CREDITS removed,
--     replaced by a single LOG tab (activity log is now its own
--     floating panel instead of being glued under the dashboard card).
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
    gui.IgnoreGuiInset = false -- respect Roblox's topbar inset so we don't cover the menu/chat buttons
    gui.DisplayOrder = 999
    gui.Parent = SafeUIParent

    --==================================================
    -- NAVBAR HOLDER — positioned independently near the top of the
    -- screen, next to the game's own top icon row (menu/chat/etc).
    -- Kept as its own frame (not a child of root) so the tab bar and
    -- the card below never move together as one glued block.
    --==================================================
    local navbarHolder = Instance.new("Frame")
    navbarHolder.Name = "NavbarHolder"
    navbarHolder.AnchorPoint = Vector2.new(0.5, 0)
    navbarHolder.Position = UDim2.new(0.5, 0, 0, 15)
    navbarHolder.Size = UDim2.new(0.62, 0, 0.09, 0)
    navbarHolder.BackgroundTransparency = 1
    navbarHolder.Parent = gui

    --==================================================
    -- ROOT — holds the single fixed DASHBOARD card. Centered on its
    -- own in the middle-ish of the screen, independent from the
    -- navbar above it. Floating panels (opened from other tabs) are
    -- parented here too, positioned to the side of this card.
    --==================================================
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.new(0.5, 0, 0.4, 0)
    root.Size = UDim2.new(0.3, 0, 0.32, 0)
    root.BackgroundTransparency = 1
    root.Parent = gui

    --==================================================
    -- NAVBAR — pill-shaped bar with 6 rounded tab buttons in a row.
    -- All positions are computed manually (no UIListLayout/UIGridLayout
    -- driving critical placement) so nothing can silently fail to
    -- position itself on any executor.
    --==================================================
    local navbar = Instance.new("Frame")
    navbar.Name = "Navbar"
    navbar.Size = UDim2.new(1, 0, 1, 0)
    navbar.Position = UDim2.new(0, 0, 0, 0)
    navbar.BackgroundColor3 = BG_CARD
    navbar.BorderSizePixel = 0
    navbar.ZIndex = 10
    navbar.Parent = navbarHolder
    corner(navbar, 16)
    uistroke(navbar, STROKE, 1, 0.15)

    -- SUPPORT + CREDITS removed, LOG added (activity log is now its
    -- own floating panel instead of living under the dashboard card).
    local tabNames = { "DASHBOARD", "TARGETS", "COMBAT", "SERVER HOP", "SETTINGS", "LOG" }
    local tabButtons = {}
    local tabContainers = {}

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
        b.Name = name:gsub("%s+", "") .. "Tab"
        b.AnchorPoint = Vector2.new(0, 0.5)
        b.Position = UDim2.new(posScale, posOffset, 0.5, 0)
        b.Size = UDim2.new(sizeScale, sizeOffset, 0.8, 0)
        b.BackgroundColor3 = SAND
        b.AutoButtonColor = false
        b.Text = name
        b.TextColor3 = SAND_TEXT
        b.TextSize = 10
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

    -- Holds one container Frame per non-DASHBOARD tab (created lazily
    -- below), used by the floating-panel system.
    local function newTabContainer(name)
        local c = Instance.new("Frame")
        c.Name = name:gsub("%s+", "") .. "Container"
        c.Size = UDim2.new(1, 0, 1, 0)
        c.BackgroundTransparency = 1
        c.Visible = true
        tabContainers[name] = c
        return c
    end

    --==================================================
    -- DASHBOARD — the ONE fixed card. Always visible, lives directly
    -- in root, never gets closed. Just the master status summary.
    --==================================================
    local statusCard = newCard(root, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
    statusCard.ZIndex = 15

    local statusPill = Instance.new("Frame")
    statusPill.Size = UDim2.new(1, -16, 0.16, 0)
    statusPill.Position = UDim2.new(0, 8, 0.06, 0)
    statusPill.BackgroundTransparency = 1
    statusPill.ZIndex = 16
    statusPill.Parent = statusCard

    label(statusPill, "MASTER AUTO BOUNTY", UDim2.new(0, 0, 0, 0), UDim2.new(0.6, 0, 1, 0), 14, TEXT, Enum.Font.GothamBold).ZIndex = 16

    local onPill = Instance.new("Frame")
    onPill.AnchorPoint = Vector2.new(1, 0.5)
    onPill.Position = UDim2.new(1, 0, 0.5, 0)
    onPill.Size = UDim2.new(0.28, 0, 0.7, 0)
    onPill.BackgroundColor3 = GREEN
    onPill.ZIndex = 16
    onPill.Parent = statusPill
    corner(onPill, 10)

    local onLabel = label(onPill, "ON", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), 13, GREEN_DARK, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    onLabel.ZIndex = 17
    UIRefs.masterStatusPill = onPill
    UIRefs.masterStatusLabel = onLabel

    local statusLine1 = label(statusCard, "Status: Active Hunting", UDim2.new(0, 8, 0.28, 0), UDim2.new(1, -16, 0.14, 0), 12, TEXT)
    local statusLine2 = label(statusCard, "Current Region: Port Town", UDim2.new(0, 8, 0.44, 0), UDim2.new(1, -16, 0.14, 0), 12, TEXT)
    local statusLine3 = label(statusCard, "Region: Sandy Island - 90%", UDim2.new(0, 8, 0.60, 0), UDim2.new(1, -16, 0.14, 0), 12, MUTED)
    local statusLine4 = label(statusCard, "Bounty Filter: 500K - 100M", UDim2.new(0, 8, 0.76, 0), UDim2.new(1, -16, 0.14, 0), 12, MUTED)
    for _, l in ipairs({ statusLine1, statusLine2, statusLine3, statusLine4 }) do l.ZIndex = 16 end

    UIRefs.statusLines = { statusLine1, statusLine2, statusLine3, statusLine4 }

    --==================================================
    -- TARGET INFO content — used to fill the TARGETS floating panel.
    -- Same content as before, just no longer glued under the status
    -- card; now lives in its own tab container.
    --==================================================
    local targetsTab = newTabContainer("TARGETS")
    do
        local targetCard = newCard(targetsTab, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        targetCard.ZIndex = 22

        local avatarSlot = Instance.new("Frame")
        avatarSlot.Size = UDim2.new(0.28, 0, 0.36, 0)
        avatarSlot.Position = UDim2.new(0, 8, 0.06, 0)
        avatarSlot.BackgroundColor3 = BG_CARD2
        avatarSlot.ZIndex = 23
        avatarSlot.Parent = targetCard
        corner(avatarSlot, 8)
        uistroke(avatarSlot, STROKE, 1, 0.3)
        -- NOTE: no image set — plug in player thumbnail from your own
        -- script via UIRefs.avatarImage below if wanted.
        local avatarImage = Instance.new("ImageLabel")
        avatarImage.Size = UDim2.new(1, 0, 1, 0)
        avatarImage.BackgroundTransparency = 1
        avatarImage.Image = ""
        avatarImage.ZIndex = 24
        avatarImage.Parent = avatarSlot
        corner(avatarImage, 8)
        UIRefs.avatarImage = avatarImage

        local targetName = label(targetCard, "Player_SwiftSword", UDim2.new(0.34, 0, 0.05, 0), UDim2.new(0.64, 0, 0.13, 0), 13, TEXT, Enum.Font.GothamBold)
        local targetBounty = label(targetCard, "Bounty: 4.8M+", UDim2.new(0.34, 0, 0.19, 0), UDim2.new(0.64, 0, 0.11, 0), 12, MUTED)
        local targetRank = label(targetCard, "Rank: Grandmaster", UDim2.new(0.34, 0, 0.31, 0), UDim2.new(0.64, 0, 0.11, 0), 12, MUTED)
        for _, l in ipairs({ targetName, targetBounty, targetRank }) do l.ZIndex = 23 end

        local hpBarBg = Instance.new("Frame")
        hpBarBg.Size = UDim2.new(0.64, 0, 0.12, 0)
        hpBarBg.Position = UDim2.new(0.34, 0, 0.45, 0)
        hpBarBg.BackgroundColor3 = GREEN_DARK
        hpBarBg.ZIndex = 23
        hpBarBg.Parent = targetCard
        corner(hpBarBg, 8)

        local hpBarFill = Instance.new("Frame")
        hpBarFill.Size = UDim2.new(0.95, 0, 1, 0) -- placeholder 95%
        hpBarFill.BackgroundColor3 = GREEN
        hpBarFill.ZIndex = 24
        hpBarFill.Parent = hpBarBg
        corner(hpBarFill, 8)

        local hpLabel = label(hpBarFill, "HP: 95%", UDim2.new(0, 6, 0, 0), UDim2.new(1, -6, 1, 0), 11, GREEN_DARK, Enum.Font.GothamBold)
        hpLabel.ZIndex = 25
        UIRefs.hpBarFill = hpBarFill
        UIRefs.hpLabel = hpLabel
        UIRefs.targetName = targetName
        UIRefs.targetBounty = targetBounty
        UIRefs.targetRank = targetRank

        local killsLine = label(targetCard, "Total Kills: 875", UDim2.new(0, 8, 0.64, 0), UDim2.new(1, -16, 0.12, 0), 12, TEXT)
        local earnedLine = label(targetCard, "Earned Today: +150K", UDim2.new(0, 8, 0.78, 0), UDim2.new(1, -16, 0.12, 0), 12, TEXT)
        killsLine.ZIndex = 23
        earnedLine.ZIndex = 23
        UIRefs.killsLine = killsLine
        UIRefs.earnedLine = earnedLine
    end

    --==================================================
    -- LOG content — used to fill the LOG floating panel. Same
    -- scrolling activity log as before, now its own tab.
    --==================================================
    local logTab = newTabContainer("LOG")
    local addLogLine
    do
        local logCard = newCard(logTab, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        logCard.ZIndex = 22

        local logScroll = Instance.new("ScrollingFrame")
        logScroll.Size = UDim2.new(1, -12, 1, -12)
        logScroll.Position = UDim2.new(0, 6, 0, 6)
        logScroll.BackgroundTransparency = 1
        logScroll.BorderSizePixel = 0
        logScroll.ScrollBarThickness = 3
        logScroll.ScrollBarImageColor3 = SAND
        logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        logScroll.ZIndex = 23
        logScroll.Parent = logCard

        local logListLayout = Instance.new("UIListLayout")
        logListLayout.Padding = UDim.new(0, 2)
        logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        logListLayout.Parent = logScroll

        local logOrderCounter = 0
        local MAX_LOG_ENTRIES = 30

        addLogLine = function(text)
            logOrderCounter = logOrderCounter + 1
            local row = Instance.new("TextLabel")
            row.Size = UDim2.new(1, 0, 0, 16)
            row.LayoutOrder = logOrderCounter
            row.BackgroundTransparency = 1
            row.Text = text
            row.TextColor3 = TEXT
            row.TextSize = 11
            row.Font = Enum.Font.Gotham
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.ZIndex = 23
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
        addLogLine("[00:00:00] Dashboard initialized (UI shell — no logic wired yet)")
    end

    --==================================================
    -- TAB: COMBAT / SERVER HOP / SETTINGS — empty placeholder cards,
    -- same style as everything else, ready for you to fill in.
    --==================================================
    local placeholderTabs = { "COMBAT", "SERVER HOP", "SETTINGS" }
    for _, name in ipairs(placeholderTabs) do
        local tab = newTabContainer(name)
        local placeholderCard = newCard(tab, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        placeholderCard.ZIndex = 22
        local l1 = label(placeholderCard, name .. " (floating panel)", UDim2.new(0, 14, 0, 14), UDim2.new(1, -28, 0, 20), 14, MUTED, Enum.Font.GothamBold)
        local l2 = label(placeholderCard, "Klik tab ini lagi buat nutup.", UDim2.new(0, 14, 0, 38), UDim2.new(1, -28, 0, 18), 11, MUTED)
        l1.ZIndex = 23
        l2.ZIndex = 23
    end

    -- ==================================================
    -- FLOATING PANELS — clicking a non-DASHBOARD tab opens its
    -- container as a separate floating card next to root's status
    -- card. Rules: max 3 floating panels at once (FIFO — oldest
    -- auto-closes when a 4th is opened); clicking a tab that's
    -- already open closes just that one (toggle).
    -- ==================================================
    local MAX_FLOATING = 3
    local floatingOrder = {} -- array of tab names currently floating, oldest first
    local floatingFrames = {} -- name -> the floating holder Frame
    local FLOAT_PANEL_GAP = 0.03 -- vertical gap between stacked panels, in Scale

    local function layoutFloatingPanels()
        local count = #floatingOrder
        if count == 0 then return end
        local totalGapScale = FLOAT_PANEL_GAP * (count - 1)
        local panelHeight = (1 - totalGapScale) / count
        for i, name in ipairs(floatingOrder) do
            local holder = floatingFrames[name]
            if holder then
                local yScale = (i - 1) * (panelHeight + FLOAT_PANEL_GAP)
                local targetPos = UDim2.new(1, 20, yScale, 0)
                local targetSize = UDim2.new(1, 0, panelHeight, 0)
                if holder:GetAttribute("Placed") then
                    tween(holder, 0.18, { Position = targetPos, Size = targetSize })
                else
                    holder:SetAttribute("Placed", true)
                    holder.Position = targetPos
                    holder.Size = targetSize
                end
            end
        end
    end

    local function closeFloating(name, skipLayout)
        local holder = floatingFrames[name]
        if not holder then return end
        for i, n in ipairs(floatingOrder) do
            if n == name then table.remove(floatingOrder, i) break end
        end
        floatingFrames[name] = nil

        tween(holder, 0.15, {
            Position = UDim2.new(1, 80, holder.Position.Y.Scale, holder.Position.Y.Offset),
        })
        for _, child in ipairs(holder:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") or child:IsA("ImageLabel") then
                pcall(function() tween(child, 0.15, { BackgroundTransparency = 1, TextTransparency = 1 }) end)
            end
        end
        task.delay(0.16, function()
            if holder then holder:Destroy() end
        end)

        if tabButtons[name] then
            tween(tabButtons[name], 0.12, { BackgroundColor3 = SAND })
        end
        if not skipLayout then layoutFloatingPanels() end
    end

    local function openFloating(name)
        local container = tabContainers[name]
        if not container then return end

        -- If it's already open, treat the click as a close (toggle).
        if floatingFrames[name] then
            closeFloating(name)
            return
        end

        -- Enforce the 3-panel cap: close the oldest (FIFO) first.
        if #floatingOrder >= MAX_FLOATING then
            closeFloating(floatingOrder[1], true)
        end

        local holder = Instance.new("Frame")
        holder.Name = name:gsub("%s+", "") .. "Float"
        holder.AnchorPoint = Vector2.new(0, 0)
        holder.BackgroundTransparency = 1
        holder.Position = UDim2.new(1, 80, 0, 0) -- start off to the right, slides in
        holder.Size = UDim2.new(1, 0, 0.3, 0)
        holder.ZIndex = 20
        holder.Parent = root

        container.Parent = holder
        container.Position = UDim2.new(0, 0, 0, 0)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Visible = true

        floatingFrames[name] = holder
        table.insert(floatingOrder, name)

        layoutFloatingPanels()
        tween(tabButtons[name], 0.12, { BackgroundColor3 = Color3.fromRGB(255, 225, 170) })
    end

    local function setActiveTab(name)
        if name == "DASHBOARD" then
            -- DASHBOARD has no container/panel of its own to toggle —
            -- its card is always visible in root. Just flash the tab.
            tween(tabButtons["DASHBOARD"], 0.12, { BackgroundColor3 = Color3.fromRGB(255, 225, 170) })
            task.delay(0.2, function()
                tween(tabButtons["DASHBOARD"], 0.12, { BackgroundColor3 = SAND })
            end)
            return
        end
        openFloating(name)
    end

    for name, btn in pairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            setActiveTab(name)
        end)
    end

    UIRefs.setActiveTab = setActiveTab
    UIRefs.openFloating = openFloating
    UIRefs.closeFloating = closeFloating
    UIRefs.gui = gui
    UIRefs.root = root
    UIRefs.navbarHolder = navbarHolder
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
