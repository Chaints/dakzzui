local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

--==================================================
-- CLEAN OLD GUI
--==================================================

local old = playerGui:FindFirstChild("DakzzBountyUI")
if old then
	old:Destroy()
end

--==================================================
-- GUI ROOT
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "DakzzBountyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = playerGui

--==================================================
-- COLORS (Fluent/Rayfield-style mono, clean, no loud gradients)
--==================================================

local BG        = Color3.fromRGB(18, 18, 20)
local CARD      = Color3.fromRGB(26, 26, 29)
local CARD2     = Color3.fromRGB(33, 33, 37)
local STROKE    = Color3.fromRGB(50, 50, 55)

local TEXT      = Color3.fromRGB(240, 240, 242)
local MUTED     = Color3.fromRGB(148, 148, 155)

local ACCENT    = Color3.fromRGB(235, 235, 240)  -- near-white, mono accent
local ACCENT_2  = Color3.fromRGB(205, 205, 212)  -- slightly dimmer for subtle gradient
local ACCENT_TEXT = Color3.fromRGB(20, 20, 22)   -- dark text used on top of ACCENT bg
local GREEN     = Color3.fromRGB(96, 200, 145)
local RED       = Color3.fromRGB(225, 95, 100)

--==================================================
-- HELPERS
--==================================================

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = obj
	return c
end

local function stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or STROKE
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.35
	s.Parent = obj
	return s
end

-- Cheap gradient (2 color stops) - very light on GPU, no blur/shadow images needed
local function gradient(obj, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rotation or 90
	g.Parent = obj
	return g
end

local function pad(obj, l, t, r, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = obj
	return p
end

-- Short, cheap tweens (Quad/Sine, low duration) - kentang friendly
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

-- Simple press feedback (scale-free, color/transparency only = cheap)
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

--==================================================
-- RESPONSIVE SCALE (no UIScale dependency - some executors
-- don't support Instance.new("UIScale"), so we compute a
-- plain number and apply it to Size/Position offsets manually)
--==================================================

local currentScale = 1

local function computeScale()
	local vp = camera.ViewportSize
	-- base design size ~390x250; scale down on small screens, cap on large ones
	local scaleX = vp.X / 420
	local scaleY = vp.Y / 500
	local s = math.min(scaleX, scaleY, 1.05)
	s = math.clamp(s, 0.62, 1.05)
	return s
end

--==================================================
-- MAIN WINDOW
--==================================================

-- Fixed-size window (390x250). We don't rely on any scaling Instance
-- (UIScale isn't supported on all executors). Instead the window keeps
-- its native pixel size, sized to comfortably fit small phone screens
-- already, and we clamp its position so it never goes off-screen.
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(390, 246)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.46, 0)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.ClipsDescendants = false
main.Parent = gui

local function updateScale()
	-- kept as a no-op hook for future use; window size stays fixed
	-- since it's already compact enough for phone screens (390x250)
	currentScale = 1
end

corner(main, 14)
stroke(main, STROKE, 1, 0.2)
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
title.Text = "DAKZZ BOUNTY"
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

local statusBtn = Instance.new("TextButton")
statusBtn.Size = UDim2.fromOffset(64, 22)
statusBtn.AnchorPoint = Vector2.new(1, 0)
statusBtn.Position = UDim2.new(1, -118, 0, 12)
statusBtn.BackgroundColor3 = CARD2
statusBtn.AutoButtonColor = false
statusBtn.Text = ""
statusBtn.Parent = header
corner(statusBtn, 7)
stroke(statusBtn, STROKE, 1, 0.4)

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
statusLabel.Text = "START"
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

-- header buttons: minimize / compact / close
local function headerButton(icon, xOffsetFromRight, size)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(size or 30, size or 30)
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -xOffsetFromRight, 0, 8)
	b.BackgroundColor3 = CARD
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

local close = headerButton("×", 10, 30)
close.TextSize = 17

local compact = headerButton("◆", 46, 30)
compact.TextSize = 11

local minimize = headerButton("—", 82, 30)
minimize.TextSize = 14

--==================================================
-- DIVIDER
--==================================================

local divider = Instance.new("Frame")
divider.Name = "Divider"
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
left.Name = "Controls"
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

-- Generic control row button (card style, icon-less, elegant)
local function controlButton(text, y, height)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, height or 34)
	b.Position = UDim2.fromOffset(0, y)
	b.BackgroundColor3 = CARD
	b.AutoButtonColor = false
	b.Text = ""
	b.Parent = left
	corner(b, 8)
	stroke(b, STROKE, 1, 0.5)

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

-- SKIP
local skip = controlButton("SKIP TARGET", 20, 34)

-- SKILLS (with chevron)
local skills, skillsLabel = controlButton("SELECT SKILLS", 60, 34)
local chevron = Instance.new("TextLabel")
chevron.Size = UDim2.fromOffset(16, 34)
chevron.AnchorPoint = Vector2.new(1, 0)
chevron.Position = UDim2.new(1, -10, 0, 0)
chevron.BackgroundTransparency = 1
chevron.Text = "›"
chevron.TextColor3 = MUTED
chevron.TextSize = 14
chevron.Font = Enum.Font.GothamBold
chevron.Parent = skills

-- HOP SERVER (real toggle, right-aligned pill)
local hop = Instance.new("TextButton")
hop.Size = UDim2.new(1, 0, 0, 34)
hop.Position = UDim2.fromOffset(0, 100)
hop.BackgroundColor3 = CARD
hop.AutoButtonColor = false
hop.Text = ""
hop.Parent = left
corner(hop, 8)
stroke(hop, STROKE, 1, 0.5)

local hopLabel = Instance.new("TextLabel")
hopLabel.Size = UDim2.new(1, -70, 1, 0)
hopLabel.Position = UDim2.fromOffset(11, 0)
hopLabel.BackgroundTransparency = 1
hopLabel.Text = "HOP SERVER"
hopLabel.TextColor3 = TEXT
hopLabel.TextSize = 10
hopLabel.Font = Enum.Font.GothamMedium
hopLabel.TextXAlignment = Enum.TextXAlignment.Left
hopLabel.Parent = hop

local hopToggleBG = Instance.new("Frame")
hopToggleBG.Size = UDim2.fromOffset(38, 20)
hopToggleBG.AnchorPoint = Vector2.new(1, 0.5)
hopToggleBG.Position = UDim2.new(1, -10, 0.5, 0)
hopToggleBG.BackgroundColor3 = GREEN
hopToggleBG.BorderSizePixel = 0
hopToggleBG.Parent = hop
corner(hopToggleBG, 99)

local hopKnob = Instance.new("Frame")
hopKnob.Size = UDim2.fromOffset(16, 16)
hopKnob.Position = UDim2.new(1, -18, 0.5, -8)
hopKnob.BackgroundColor3 = Color3.new(1, 1, 1)
hopKnob.BorderSizePixel = 0
hopKnob.Parent = hopToggleBG
corner(hopKnob, 99)

local hopOn = true
hop.MouseButton1Click:Connect(function()
	hopOn = not hopOn
	if hopOn then
		tween(hopToggleBG, 0.14, { BackgroundColor3 = GREEN })
		tween(hopKnob, 0.14, { Position = UDim2.new(1, -18, 0.5, -8) })
	else
		tween(hopToggleBG, 0.14, { BackgroundColor3 = Color3.fromRGB(70, 73, 82) })
		tween(hopKnob, 0.14, { Position = UDim2.new(0, 2, 0.5, -8) })
	end
end)

pressFeedback(hop, CARD, CARD2)

--==================================================
-- RIGHT SIDE — TARGET INFO
--==================================================

local info = Instance.new("Frame")
info.Name = "TargetInfo"
info.Size = UDim2.fromOffset(176, 138)
info.Position = UDim2.fromOffset(200, 56)
info.BackgroundColor3 = CARD
info.BorderSizePixel = 0
info.Parent = main
corner(info, 10)
stroke(info, STROKE, 1, 0.5)

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
	a.Size = UDim2.new(0.46, 0, 1, 0)
	a.BackgroundTransparency = 1
	a.Text = name
	a.TextColor3 = MUTED
	a.TextSize = 9
	a.Font = Enum.Font.Gotham
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = row

	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(0.54, 0, 1, 0)
	b.Position = UDim2.new(0.46, 0, 0, 0)
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

infoRow("PLAYER", "Unknown", 30)
infoRow("DISTANCE", "--", 49)
infoRow("LOCATION", "--", 68)
infoRow("LEVEL", "--", 87)
infoRow("HEALTH", "--", 106)

local miniDivider = Instance.new("Frame")
miniDivider.Size = UDim2.new(1, -22, 0, 1)
miniDivider.Position = UDim2.fromOffset(11, 123)
miniDivider.BackgroundColor3 = STROKE
miniDivider.BackgroundTransparency = 0.4
miniDivider.BorderSizePixel = 0
miniDivider.Parent = info

-- EARNED gets emphasis (accent colored, slightly bigger)
local earnedRow = Instance.new("Frame")
earnedRow.Size = UDim2.new(1, -22, 0, 14)
earnedRow.Position = UDim2.fromOffset(11, 122)
earnedRow.BackgroundTransparency = 1
earnedRow.Parent = info

local earnedLabel = Instance.new("TextLabel")
earnedLabel.Size = UDim2.new(0.58, 0, 1, 0)
earnedLabel.BackgroundTransparency = 1
earnedLabel.Text = "EARNED BOUNTY"
earnedLabel.TextColor3 = MUTED
earnedLabel.TextSize = 8
earnedLabel.Font = Enum.Font.GothamBold
earnedLabel.TextXAlignment = Enum.TextXAlignment.Left
earnedLabel.Parent = earnedRow

local earnedValue = Instance.new("TextLabel")
earnedValue.Size = UDim2.new(0.42, 0, 1, 0)
earnedValue.Position = UDim2.new(0.58, 0, 0, 0)
earnedValue.BackgroundTransparency = 1
earnedValue.Text = "◈ 0"
earnedValue.TextColor3 = ACCENT
earnedValue.TextSize = 10
earnedValue.Font = Enum.Font.GothamBold
earnedValue.TextXAlignment = Enum.TextXAlignment.Right
earnedValue.Parent = earnedRow

infoValues["EARNED"] = earnedValue

--==================================================
-- SPEED SLIDER (bigger hit area for touch)
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
speedValueLabel.Text = "2.0x"
speedValueLabel.TextColor3 = TEXT
speedValueLabel.TextSize = 11
speedValueLabel.Font = Enum.Font.GothamBold
speedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
speedValueLabel.Parent = speedRow

-- invisible larger touch zone around the visual bar
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

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(1, 0, 1, 0)
speedFill.BackgroundColor3 = ACCENT
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar
corner(speedFill, 99)
gradient(speedFill, ACCENT, ACCENT_2, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(16, 16)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(1, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.BorderSizePixel = 0
knob.ZIndex = 2
knob.Parent = speedBar
corner(knob, 99)
stroke(knob, ACCENT, 2, 0)

local draggingSpeed = false

local function setSpeed(x)
	local relative = math.clamp(
		(x - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X,
		0,
		1
	)

	speedFill.Size = UDim2.new(relative, 0, 1, 0)
	knob.Position = UDim2.new(relative, 0, 0.5, 0)

	local value = 0.5 + (relative * 1.5)
	speedValueLabel.Text = string.format("%.1fx", value)
end

speedTouchZone.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
		setSpeed(input.Position.X)
		tween(knob, 0.1, { Size = UDim2.fromOffset(19, 19) })
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if draggingSpeed then
			tween(knob, 0.1, { Size = UDim2.fromOffset(16, 16) })
		end
		draggingSpeed = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if draggingSpeed then
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
			setSpeed(input.Position.X)
		end
	end
end)

--==================================================
-- START (compact status control, lives in header)
--==================================================

local running = false
local pulseConn

local function stopPulse()
	if pulseConn then
		pulseConn:Disconnect()
		pulseConn = nil
	end
	statusDot.BackgroundTransparency = 0
end

local function startPulse()
	local t = 0
	pulseConn = RunService.Heartbeat:Connect(function(dt)
		t = t + dt
		statusDot.BackgroundTransparency = 0.15 + math.sin(t * 4) * 0.35
	end)
end

statusBtn.MouseButton1Click:Connect(function()
	running = not running

	if running then
		statusLabel.Text = "RUNNING"
		tween(statusDot, 0.12, { BackgroundColor3 = GREEN })
		tween(statusBtn, 0.12, { BackgroundColor3 = CARD2 })
		local existingStroke = statusBtn:FindFirstChildOfClass("UIStroke")
		if existingStroke then existingStroke:Destroy() end
		stroke(statusBtn, GREEN, 1, 0.5)
		startPulse()
	else
		statusLabel.Text = "START"
		tween(statusDot, 0.12, { BackgroundColor3 = MUTED })
		local existingStroke = statusBtn:FindFirstChildOfClass("UIStroke")
		if existingStroke then existingStroke:Destroy() end
		stroke(statusBtn, STROKE, 1, 0.4)
		stopPulse()
	end
end)

pressFeedback(statusBtn, CARD2, CARD)

--==================================================
-- BACKDROP (for popup, tap outside to close)
--==================================================

local backdrop = Instance.new("TextButton")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.ZIndex = 19
backdrop.Parent = gui

--==================================================
-- SKILL POPUP
--==================================================

local popup = Instance.new("Frame")
popup.Size = UDim2.fromOffset(210, 150)
popup.AnchorPoint = Vector2.new(0.5, 0.5)
popup.Position = UDim2.new(0.5, 0, 0.46, 0)
popup.BackgroundColor3 = CARD
popup.BorderSizePixel = 0
popup.Visible = false
popup.ZIndex = 20
popup.Parent = gui

corner(popup, 12)
stroke(popup, STROKE, 1, 0.15)
gradient(popup, Color3.fromRGB(26, 27, 33), Color3.fromRGB(19, 20, 24), 90)

local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, -20, 0, 24)
popupTitle.Position = UDim2.fromOffset(14, 12)
popupTitle.BackgroundTransparency = 1
popupTitle.Text = "SELECT SKILLS"
popupTitle.TextColor3 = TEXT
popupTitle.TextSize = 12
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.ZIndex = 21
popupTitle.Parent = popup

local selected = {
	Z = true,
	X = true,
	C = true,
	V = true,
	F = false,
}

local skillGrid = Instance.new("Frame")
skillGrid.Size = UDim2.new(1, -28, 0, 76)
skillGrid.Position = UDim2.fromOffset(14, 44)
skillGrid.BackgroundTransparency = 1
skillGrid.ZIndex = 21
skillGrid.Parent = popup

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(56, 34)
layout.CellPadding = UDim2.fromOffset(6, 6)
layout.FillDirectionMaxCells = 3
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = skillGrid

local function skillButton(letter, order)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.BackgroundColor3 = selected[letter] and ACCENT or CARD2
	b.AutoButtonColor = false
	b.Text = letter
	b.TextColor3 = selected[letter] and ACCENT_TEXT or TEXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.ZIndex = 21
	b.Parent = skillGrid
	corner(b, 8)
	if selected[letter] then
		gradient(b, ACCENT, ACCENT_2, 0)
	end

	b.MouseButton1Click:Connect(function()
		selected[letter] = not selected[letter]

		-- clear any leftover gradient before re-adding
		local existingGrad = b:FindFirstChildOfClass("UIGradient")
		if existingGrad then existingGrad:Destroy() end

		if selected[letter] then
			tween(b, 0.1, { BackgroundColor3 = ACCENT, TextColor3 = ACCENT_TEXT })
			gradient(b, ACCENT, ACCENT_2, 0)
		else
			tween(b, 0.1, { BackgroundColor3 = CARD2, TextColor3 = TEXT })
		end
	end)
end

skillButton("Z", 1)
skillButton("X", 2)
skillButton("C", 3)
skillButton("V", 4)
skillButton("F", 5)

local done = Instance.new("TextButton")
done.Size = UDim2.fromOffset(80, 28)
done.AnchorPoint = Vector2.new(1, 1)
done.Position = UDim2.new(1, -14, 1, -12)
done.BackgroundColor3 = ACCENT
done.AutoButtonColor = false
done.Text = "DONE"
done.TextColor3 = ACCENT_TEXT
done.TextSize = 10
done.Font = Enum.Font.GothamBold
done.ZIndex = 21
done.Parent = popup
corner(done, 7)
pressFeedback(done, ACCENT, ACCENT_2)

local function closePopup()
	if not popup.Visible then
		return
	end

	tween(backdrop, 0.15, { BackgroundTransparency = 1 })
	local t = tween(
		popup,
		0.14,
		{ Size = UDim2.fromOffset(190, 138) },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)

	t.Completed:Connect(function()
		popup.Visible = false
		backdrop.Visible = false
		popup.Size = UDim2.fromOffset(210, 150)
	end)
end

local function openPopup()
	popup.Visible = true
	backdrop.Visible = true
	backdrop.BackgroundTransparency = 1
	popup.Size = UDim2.fromOffset(190, 138)

	tween(backdrop, 0.15, { BackgroundTransparency = 0.5 })
	tween(popup, 0.16, { Size = UDim2.fromOffset(210, 150) })
end

skills.MouseButton1Click:Connect(openPopup)
backdrop.MouseButton1Click:Connect(closePopup)
done.MouseButton1Click:Connect(closePopup)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false
local contentChildren = { left, info, speedRow, divider }

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		for _, child in ipairs(contentChildren) do
			child.Visible = false
		end
		tween(main, 0.16, { Size = UDim2.fromOffset(390, 46) })
	else
		for _, child in ipairs(contentChildren) do
			child.Visible = true
		end
		tween(main, 0.16, { Size = UDim2.fromOffset(390, 246) })
	end
end)

--==================================================
-- COMPACT LOGO MODE
--==================================================

local compactMode = false

local logo = Instance.new("TextButton")
logo.Size = UDim2.fromOffset(56, 56)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.Position = UDim2.new(0.5, 0, 0.46, 0)
logo.BackgroundColor3 = BG
logo.AutoButtonColor = false
logo.Text = ""
logo.Visible = false
logo.Parent = gui
corner(logo, 16)
stroke(logo, STROKE, 1, 0.2)
gradient(logo, Color3.fromRGB(20, 21, 26), Color3.fromRGB(13, 14, 17), 90)

-- Monogram: Z (behind, larger) + D (front, offset) overlapping like a collab mark
local logoZ = Instance.new("TextLabel")
logoZ.Size = UDim2.fromOffset(40, 40)
logoZ.AnchorPoint = Vector2.new(0.5, 0.5)
logoZ.Position = UDim2.new(0.5, -6, 0.5, -3)
logoZ.BackgroundTransparency = 1
logoZ.Text = "Z"
logoZ.TextColor3 = ACCENT
logoZ.TextTransparency = 0.15
logoZ.TextSize = 26
logoZ.Font = Enum.Font.GothamBlack
logoZ.ZIndex = 1
logoZ.Parent = logo

local logoD = Instance.new("TextLabel")
logoD.Size = UDim2.fromOffset(40, 40)
logoD.AnchorPoint = Vector2.new(0.5, 0.5)
logoD.Position = UDim2.new(0.5, 7, 0.5, 4)
logoD.BackgroundTransparency = 1
logoD.Text = "D"
logoD.TextColor3 = TEXT
logoD.TextSize = 26
logoD.Font = Enum.Font.GothamBlack
logoD.ZIndex = 2
logoD.Parent = logo

local logoFullSize = UDim2.fromOffset(56, 56)
local logoTinySize = UDim2.fromOffset(6, 6)

-- Drag state declared early so all closures below share the same locals
local logoDragging = false
local logoDragStart
local logoStartPos
local logoMoved = false
local LOGO_DRAG_THRESHOLD = 6 -- pixels of movement before it counts as a drag, not a tap

compact.MouseButton1Click:Connect(function()
	compactMode = true

	tween(main, 0.14, { Size = UDim2.fromOffset(6, 6) })

	task.delay(0.14, function()
		main.Visible = false
		main.Size = UDim2.fromOffset(390, 246) -- restore for next reopen

		logo.Visible = true
		logo.Size = logoTinySize
		tween(logo, 0.16, { Size = logoFullSize })
	end)
end)

logo.MouseButton1Click:Connect(function()
	if logoMoved then
		return -- was a drag, not a tap; don't open the UI
	end

	tween(logo, 0.1, { Size = logoTinySize })

	task.delay(0.1, function()
		logo.Visible = false
		main.Visible = true
		main.Size = UDim2.fromOffset(6, 6)
		tween(main, 0.16, { Size = UDim2.fromOffset(390, 246) })
	end)
end)

--==================================================
-- LOGO DRAG (independent of main window; tap still opens it)
--==================================================

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

UIS.InputChanged:Connect(function(input)
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

--==================================================
-- CLOSE / DESTROY
--==================================================

close.MouseButton1Click:Connect(function()
	tween(main, 0.14, { Size = UDim2.fromOffset(6, 6) })
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

local function beginDrag(input)
	dragging = true
	dragStart = input.Position
	startPos = main.Position
end

local function updateDrag(input)
	if not dragging then return end
	local delta = input.Position - dragStart
	main.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

local function endDrag()
	dragging = false
end

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginDrag(input)
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		endDrag()
	end
end)

UIS.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseMovement then
		updateDrag(input)
	end
end)

--==================================================
-- RESPONSIVE HOOKUP
--==================================================

updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

--==================================================
-- PUBLIC API (so your bounty logic can update the UI)
--==================================================

local API = {}

function API.SetTargetInfo(data)
	if data.player then infoValues["PLAYER"].Text = data.player end
	if data.distance then infoValues["DISTANCE"].Text = data.distance end
	if data.location then infoValues["LOCATION"].Text = data.location end
	if data.level then infoValues["LEVEL"].Text = tostring(data.level) end
	if data.health then infoValues["HEALTH"].Text = data.health end
	if data.earned then infoValues["EARNED"].Text = "◈ " .. tostring(data.earned) end
end

function API.SetHop(state)
	hopOn = state
	if hopOn then
		tween(hopToggleBG, 0.14, { BackgroundColor3 = GREEN })
		tween(hopKnob, 0.14, { Position = UDim2.new(1, -18, 0.5, -8) })
	else
		tween(hopToggleBG, 0.14, { BackgroundColor3 = Color3.fromRGB(70, 73, 82) })
		tween(hopKnob, 0.14, { Position = UDim2.new(0, 2, 0.5, -8) })
	end
end

function API.GetSelectedSkills()
	return selected
end

function API.GetSpeed()
	return tonumber(speedValueLabel.Text:gsub("x", ""))
end

function API.IsRunning()
	return running
end

function API.OnSkip(fn)
	skip.MouseButton1Click:Connect(fn)
end

function API.OnStart(fn)
	statusBtn.MouseButton1Click:Connect(fn)
end

_G.DakzzBountyUI = API

return API
