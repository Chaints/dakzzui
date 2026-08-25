--[[
	ZxD HUB — Mobile Game Dashboard UI Framework
	----------------------------------------------
	Style: Deep Matte Maroon/Crimson base, Warm Sand/Cream highlights, Dusty Rose secondary text.
	Purpose: In-game dashboard for YOUR OWN Roblox experience — companion/party status,
	         quest log, inventory toggles, and a live event console.

	This is a UI-ONLY framework. No game logic, no automation, no other-player targeting.
	Wire up the exposed :SetX() methods to your own game's RemoteEvents/DataStores.

	Structure:
	  1. Theme constants
	  2. Root ScreenGui + floating pill Tab Bar (7 tabs)
	  3. Content Area
	     - Left Card: "Party Auto-Assist" toggle + region/status selectors
	     - Right Card: Companion Monitor (avatar box, name, level/rank, HP bar)
	  4. Bottom: Live Console Log box + Engine Status pill
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--======================================================
-- 1. THEME
--======================================================
local Theme = {
	BgDeep       = Color3.fromRGB(26, 8, 12),     -- #1A080C
	BgPanel      = Color3.fromRGB(41, 16, 22),    -- #291016
	Cream        = Color3.fromRGB(232, 216, 200), -- #E8D8C8 (highlights / primary text)
	DustyRose    = Color3.fromRGB(168, 139, 125), -- #A88B7D (secondary text)
	Success      = Color3.fromRGB(150, 196, 150),
	Warning      = Color3.fromRGB(214, 168, 120),
	Font         = Enum.Font.GothamMedium,
	FontBold     = Enum.Font.GothamBold,
}

local function corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = inst
	return c
end

local function stroke(inst, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.DustyRose
	s.Thickness = thickness or 1
	s.Transparency = 0.6
	s.Parent = inst
	return s
end

local function pad(inst, all)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all)
	p.PaddingBottom = UDim.new(0, all)
	p.PaddingLeft = UDim.new(0, all)
	p.PaddingRight = UDim.new(0, all)
	p.Parent = inst
	return p
end

--======================================================
-- 2. ROOT
--======================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZxD_HUB"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = Theme.BgDeep
root.BorderSizePixel = 0
root.Parent = screenGui

--------------------------------------------------------
-- Floating pill Tab Bar
--------------------------------------------------------
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.AnchorPoint = Vector2.new(0.5, 0)
tabBar.Position = UDim2.new(0.5, 0, 0.03, 0)
tabBar.Size = UDim2.new(0.94, 0, 0, 52)
tabBar.BackgroundColor3 = Theme.BgPanel
tabBar.Parent = root
corner(tabBar, 26)
stroke(tabBar, Theme.DustyRose, 1)

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Padding = UDim.new(0, 4)
tabList.Parent = tabBar
pad(tabBar, 6)

local TAB_NAMES = { "DASHBOARD", "PARTY", "QUESTS", "INVENTORY", "SETTINGS", "SUPPORT", "CREDITS" }
local tabButtons = {}

local function styleTab(btn, active)
	if active then
		btn.BackgroundColor3 = Theme.Cream
		btn.TextColor3 = Theme.BgDeep
		btn.Font = Theme.FontBold
	else
		btn.BackgroundColor3 = Theme.BgPanel
		btn.TextColor3 = Theme.DustyRose
		btn.Font = Theme.Font
	end
end

local function selectTab(name)
	for tabName, btn in pairs(tabButtons) do
		styleTab(btn, tabName == name)
	end
	-- Hook: fire a BindableEvent / show the matching content frame here
end

for _, name in ipairs(TAB_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Tab"
	btn.Size = UDim2.new(0, name == "DASHBOARD" and 110 or 90, 1, -8)
	btn.AutoButtonColor = false
	btn.Text = name
	btn.TextSize = 12
	btn.Font = Theme.Font
	btn.TextColor3 = Theme.DustyRose
	btn.BackgroundColor3 = Theme.BgPanel
	btn.Parent = tabBar
	corner(btn, 18)
	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
end
selectTab("DASHBOARD")

--======================================================
-- 3. CONTENT AREA
--======================================================
local content = Instance.new("Frame")
content.Name = "Content"
content.AnchorPoint = Vector2.new(0.5, 0)
content.Position = UDim2.new(0.5, 0, 0.12, 0)
content.Size = UDim2.new(0.94, 0, 0, 260)
content.BackgroundTransparency = 1
content.Parent = root

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Horizontal
contentLayout.Padding = UDim.new(0, 12)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

--------------------------------------------------------
-- LEFT CARD: Party Auto-Assist
--------------------------------------------------------
local leftCard = Instance.new("Frame")
leftCard.Name = "PartyAssistCard"
leftCard.Size = UDim2.new(0.48, 0, 1, 0)
leftCard.BackgroundColor3 = Theme.BgPanel
leftCard.Parent = content
corner(leftCard, 16)
stroke(leftCard, Theme.DustyRose)
pad(leftCard, 16)

local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 10)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftCard

local function makeLabel(parent, text, size, color, font, order)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextSize = size
	lbl.TextColor3 = color
	lbl.Font = font
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Size = UDim2.new(1, 0, 0, size + 6)
	lbl.LayoutOrder = order or 0
	lbl.Parent = parent
	return lbl
end

makeLabel(leftCard, "PARTY AUTO-ASSIST", 15, Theme.Cream, Theme.FontBold, 1)

-- Toggle row
local toggleRow = Instance.new("Frame")
toggleRow.BackgroundTransparency = 1
toggleRow.Size = UDim2.new(1, 0, 0, 34)
toggleRow.LayoutOrder = 2
toggleRow.Parent = leftCard

local toggleLabel = makeLabel(toggleRow, "Assist Mode", 13, Theme.DustyRose, Theme.Font)
toggleLabel.Size = UDim2.new(0.6, 0, 1, 0)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "AssistToggle"
toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
toggleBtn.Position = UDim2.new(1, 0, 0.5, 0)
toggleBtn.Size = UDim2.new(0, 52, 0, 28)
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.BackgroundColor3 = Theme.Cream
toggleBtn.Parent = toggleRow
corner(toggleBtn, 14)

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 22, 0, 22)
knob.Position = UDim2.new(1, -25, 0.5, -11)
knob.BackgroundColor3 = Theme.BgDeep
knob.Parent = toggleBtn
corner(knob, 11)

local assistActive = true
toggleBtn.MouseButton1Click:Connect(function()
	assistActive = not assistActive
	local targetPos = assistActive and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
	local targetColor = assistActive and Theme.Cream or Theme.BgDeep
	TweenService:Create(knob, TweenInfo.new(0.18), { Position = targetPos }):Play()
	TweenService:Create(toggleBtn, TweenInfo.new(0.18), { BackgroundColor3 = targetColor }):Play()
	-- Hook: fire your own RemoteEvent here, e.g. AssistRemote:FireServer(assistActive)
end)

makeLabel(leftCard, "Status: Active — Following Party", 12, Theme.Success, Theme.Font, 3)
makeLabel(leftCard, "Current Zone: Port Town", 12, Theme.DustyRose, Theme.Font, 4)

-- Region selector (dropdown placeholder)
local regionRow = Instance.new("TextButton")
regionRow.Name = "RegionSelector"
regionRow.Size = UDim2.new(1, 0, 0, 32)
regionRow.BackgroundColor3 = Theme.BgDeep
regionRow.Text = "  Region:  Port Town  ▾"
regionRow.TextXAlignment = Enum.TextXAlignment.Left
regionRow.TextSize = 12
regionRow.TextColor3 = Theme.Cream
regionRow.Font = Theme.Font
regionRow.LayoutOrder = 5
regionRow.Parent = leftCard
corner(regionRow, 8)

-- Level range filter
makeLabel(leftCard, "Party Level Range", 12, Theme.DustyRose, Theme.Font, 6)
local rangeRow = Instance.new("TextButton")
rangeRow.Size = UDim2.new(1, 0, 0, 32)
rangeRow.BackgroundColor3 = Theme.BgDeep
rangeRow.Text = "  Lv. 10 – 25"
rangeRow.TextXAlignment = Enum.TextXAlignment.Left
rangeRow.TextSize = 12
rangeRow.TextColor3 = Theme.Cream
rangeRow.Font = Theme.Font
rangeRow.LayoutOrder = 7
rangeRow.Parent = leftCard
corner(rangeRow, 8)

--------------------------------------------------------
-- RIGHT CARD: Companion Monitor
--------------------------------------------------------
local rightCard = Instance.new("Frame")
rightCard.Name = "CompanionMonitorCard"
rightCard.Size = UDim2.new(0.48, 0, 1, 0)
rightCard.BackgroundColor3 = Theme.BgPanel
rightCard.Parent = content
corner(rightCard, 16)
stroke(rightCard, Theme.DustyRose)
pad(rightCard, 16)

local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0, 8)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Parent = rightCard

makeLabel(rightCard, "COMPANION MONITOR", 15, Theme.Cream, Theme.FontBold, 1)

local avatarRow = Instance.new("Frame")
avatarRow.BackgroundTransparency = 1
avatarRow.Size = UDim2.new(1, 0, 0, 54)
avatarRow.LayoutOrder = 2
avatarRow.Parent = rightCard

local avatarBox = Instance.new("Frame")
avatarBox.Size = UDim2.new(0, 54, 0, 54)
avatarBox.BackgroundColor3 = Theme.BgDeep
avatarBox.Parent = avatarRow
corner(avatarBox, 12)
stroke(avatarBox, Theme.Cream, 1)

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(1, 0, 1, 0)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = "" -- Hook: Players:GetUserThumbnailAsync or your character icon
avatarImage.Parent = avatarBox
corner(avatarImage, 12)

local nameBlock = Instance.new("Frame")
nameBlock.BackgroundTransparency = 1
nameBlock.AnchorPoint = Vector2.new(1, 0.5)
nameBlock.Position = UDim2.new(1, 0, 0.5, 0)
nameBlock.Size = UDim2.new(1, -66, 1, 0)
nameBlock.Parent = avatarRow

local nameLbl = makeLabel(nameBlock, "Ally_Windrunner", 14, Theme.Cream, Theme.FontBold, 1)
nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
local rankLbl = makeLabel(nameBlock, "Level 22  •  Ranger", 11, Theme.DustyRose, Theme.Font, 2)
rankLbl.Position = UDim2.new(0, 0, 0, 20)

-- HP Bar
makeLabel(rightCard, "HP", 11, Theme.DustyRose, Theme.Font, 3)
local hpTrack = Instance.new("Frame")
hpTrack.Size = UDim2.new(1, 0, 0, 14)
hpTrack.BackgroundColor3 = Theme.BgDeep
hpTrack.LayoutOrder = 4
hpTrack.Parent = rightCard
corner(hpTrack, 7)

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(0.95, 0, 1, 0) -- 95%
hpFill.BackgroundColor3 = Theme.Cream
hpFill.Parent = hpTrack
corner(hpFill, 7)

local hpPercentLbl = Instance.new("TextLabel")
hpPercentLbl.BackgroundTransparency = 1
hpPercentLbl.Text = "95%"
hpPercentLbl.TextSize = 10
hpPercentLbl.Font = Theme.FontBold
hpPercentLbl.TextColor3 = Theme.BgDeep
hpPercentLbl.Size = UDim2.new(1, 0, 1, 0)
hpPercentLbl.Parent = hpFill

makeLabel(rightCard, "Distance: 12 studs  •  In Combat: No", 11, Theme.DustyRose, Theme.Font, 5)

--======================================================
-- 4. BOTTOM: Live Console Log + Engine Status
--======================================================
local consoleBox = Instance.new("Frame")
consoleBox.Name = "ConsoleLog"
consoleBox.AnchorPoint = Vector2.new(0.5, 0)
consoleBox.Position = UDim2.new(0.5, 0, 0.40, 0)
consoleBox.Size = UDim2.new(0.94, 0, 0, 130)
consoleBox.BackgroundColor3 = Theme.BgDeep
consoleBox.Parent = root
corner(consoleBox, 14)
stroke(consoleBox, Theme.DustyRose)
pad(consoleBox, 10)

local consoleHeader = makeLabel(consoleBox, "LIVE EVENT LOG", 12, Theme.Cream, Theme.FontBold)

local logScroll = Instance.new("ScrollingFrame")
logScroll.Position = UDim2.new(0, 0, 0, 22)
logScroll.Size = UDim2.new(1, 0, 1, -22)
logScroll.BackgroundTransparency = 1
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = Theme.DustyRose
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = consoleBox

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.Parent = logScroll

local function pushLog(text, color)
	local line = Instance.new("TextLabel")
	line.BackgroundTransparency = 1
	line.Text = text
	line.TextSize = 11
	line.Font = Enum.Font.Code
	line.TextColor3 = color or Theme.DustyRose
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.Size = UDim2.new(1, 0, 0, 14)
	line.Parent = logScroll
end

-- Sample placeholder log lines (replace with real game event hooks)
pushLog("[12:04:01] Party synced — Ally_Windrunner joined.", Theme.DustyRose)
pushLog("[12:04:03] Quest 'Riverside Patrol' progress: 3/5.", Theme.DustyRose)
pushLog("[12:04:07] Zone changed: Port Town.", Theme.DustyRose)
pushLog("[12:04:12] Companion HP restored to 95%.", Theme.Success)

-- Engine/connection status pill
local statusPill = Instance.new("Frame")
statusPill.Name = "EngineStatus"
statusPill.AnchorPoint = Vector2.new(0.5, 1)
statusPill.Position = UDim2.new(0.5, 0, 0.985, 0)
statusPill.Size = UDim2.new(0, 220, 0, 34)
statusPill.BackgroundColor3 = Theme.BgPanel
statusPill.Parent = root
corner(statusPill, 17)
stroke(statusPill, Theme.DustyRose)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(0, 14, 0.5, 0)
statusDot.BackgroundColor3 = Theme.Success
statusDot.Parent = statusPill
corner(statusDot, 4)

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Text = "SYSTEM ONLINE"
statusText.TextSize = 11
statusText.Font = Theme.FontBold
statusText.TextColor3 = Theme.Cream
statusText.Position = UDim2.new(0, 28, 0, 0)
statusText.Size = UDim2.new(1, -36, 1, 0)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusPill

--======================================================
-- Public API (hook these into your own game systems)
--======================================================
local ZxD_HUB = {}

function ZxD_HUB:SetCompanion(name, level, className, hpPercent)
	nameLbl.Text = name
	rankLbl.Text = ("Level %d  •  %s"):format(level, className)
	local clamped = math.clamp(hpPercent, 0, 1)
	TweenService:Create(hpFill, TweenInfo.new(0.25), { Size = UDim2.new(clamped, 0, 1, 0) }):Play()
	hpPercentLbl.Text = math.floor(clamped * 100) .. "%"
end

function ZxD_HUB:Log(text, color)
	pushLog(text, color)
end

function ZxD_HUB:SetEngineStatus(online)
	statusDot.BackgroundColor3 = online and Theme.Success or Theme.Warning
	statusText.Text = online and "SYSTEM ONLINE" or "RECONNECTING..."
end

return ZxD_HUB
