local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================
-- CLEAN OLD GUI
--==================================================

local old = playerGui:FindFirstChild("DakzzBountyUI")
if old then
	old:Destroy()
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "DakzzBountyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

--==================================================
-- COLORS
--==================================================

local BG = Color3.fromRGB(17, 18, 22)
local CARD = Color3.fromRGB(24, 26, 31)
local CARD2 = Color3.fromRGB(31, 33, 39)

local TEXT = Color3.fromRGB(238, 240, 245)
local MUTED = Color3.fromRGB(145, 149, 160)

local ACCENT = Color3.fromRGB(105, 150, 255)
local GREEN = Color3.fromRGB(85, 220, 140)
local RED = Color3.fromRGB(230, 85, 95)

--==================================================
-- HELPERS
--==================================================

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function tween(obj, duration, props, style, direction)
	local info = TweenInfo.new(
		duration or 0.15,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)

	local t = TweenService:Create(obj, info, props)
	t:Play()

	return t
end

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(430, 270)
main.Position = UDim2.new(0.5, -215, 0.5, -135)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Parent = gui

corner(main, 12)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(48, 51, 59)
outline.Transparency = 0.25
outline.Thickness = 1
outline.Parent = main

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -130, 0, 22)
title.Position = UDim2.fromOffset(15, 6)
title.BackgroundTransparency = 1
title.Text = "DAKZZ BOUNTY"
title.TextColor3 = TEXT
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -130, 0, 14)
subtitle.Position = UDim2.fromOffset(15, 27)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Bounty Assistant"
subtitle.TextColor3 = MUTED
subtitle.TextSize = 9
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

-- status dot
local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(7, 7)
dot.Position = UDim2.new(1, -108, 0, 19)
dot.BackgroundColor3 = GREEN
dot.BorderSizePixel = 0
dot.Parent = header

corner(dot, 99)

-- minimize
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(28, 28)
minimize.Position = UDim2.new(1, -94, 0, 9)
minimize.BackgroundTransparency = 1
minimize.Text = "—"
minimize.TextColor3 = MUTED
minimize.TextSize = 16
minimize.Font = Enum.Font.GothamBold
minimize.Parent = header

-- compact/logo
local compact = Instance.new("TextButton")
compact.Size = UDim2.fromOffset(28, 28)
compact.Position = UDim2.new(1, -62, 0, 9)
compact.BackgroundTransparency = 1
compact.Text = "◆"
compact.TextColor3 = MUTED
compact.TextSize = 12
compact.Font = Enum.Font.GothamBold
compact.Parent = header

-- close
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -30, 0, 9)
close.BackgroundTransparency = 1
close.Text = "×"
close.TextColor3 = MUTED
close.TextSize = 18
close.Font = Enum.Font.GothamBold
close.Parent = header

--==================================================
-- DIVIDER
--==================================================

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -30, 0, 1)
divider.Position = UDim2.fromOffset(15, 50)
divider.BackgroundColor3 = Color3.fromRGB(42, 44, 51)
divider.BorderSizePixel = 0
divider.Parent = main

--==================================================
-- LEFT SIDE
--==================================================

local left = Instance.new("Frame")
left.Size = UDim2.fromOffset(190, 150)
left.Position = UDim2.fromOffset(15, 60)
left.BackgroundTransparency = 1
left.Parent = main

local controlsTitle = Instance.new("TextLabel")
controlsTitle.Size = UDim2.new(1, 0, 0, 18)
controlsTitle.BackgroundTransparency = 1
controlsTitle.Text = "CONTROLS"
controlsTitle.TextColor3 = MUTED
controlsTitle.TextSize = 9
controlsTitle.Font = Enum.Font.GothamBold
controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
controlsTitle.Parent = left

-- SKIP
local skip = Instance.new("TextButton")
skip.Size = UDim2.new(1, 0, 0, 36)
skip.Position = UDim2.fromOffset(0, 24)
skip.BackgroundColor3 = CARD
skip.Text = "SKIP"
skip.TextColor3 = TEXT
skip.TextSize = 10
skip.Font = Enum.Font.GothamBold
skip.Parent = left

corner(skip, 7)

-- SKILLS
local skills = Instance.new("TextButton")
skills.Size = UDim2.new(1, 0, 0, 36)
skills.Position = UDim2.fromOffset(0, 68)
skills.BackgroundColor3 = CARD
skills.Text = "SELECT SKILLS                 ›"
skills.TextColor3 = TEXT
skills.TextSize = 10
skills.Font = Enum.Font.GothamMedium
skills.TextXAlignment = Enum.TextXAlignment.Left
skills.Parent = left

corner(skills, 7)

-- HOP
local hop = Instance.new("TextButton")
hop.Size = UDim2.new(1, 0, 0, 36)
hop.Position = UDim2.fromOffset(0, 112)
hop.BackgroundColor3 = CARD
hop.Text = "HOP SERVER                       ON"
hop.TextColor3 = TEXT
hop.TextSize = 10
hop.Font = Enum.Font.GothamMedium
hop.TextXAlignment = Enum.TextXAlignment.Left
hop.Parent = left

corner(hop, 7)

--==================================================
-- TARGET INFO
--==================================================

local info = Instance.new("Frame")
info.Size = UDim2.fromOffset(190, 150)
info.Position = UDim2.fromOffset(224, 60)
info.BackgroundColor3 = CARD
info.BorderSizePixel = 0
info.Parent = main

corner(info, 8)

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, -20, 0, 20)
infoTitle.Position = UDim2.fromOffset(10, 7)
infoTitle.BackgroundTransparency = 1
infoTitle.Text = "TARGET INFO"
infoTitle.TextColor3 = MUTED
infoTitle.TextSize = 9
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.Parent = info

local function infoRow(name, value, y)
	local a = Instance.new("TextLabel")
	a.Size = UDim2.new(0.48, 0, 0, 20)
	a.Position = UDim2.fromOffset(10, y)
	a.BackgroundTransparency = 1
	a.Text = name
	a.TextColor3 = MUTED
	a.TextSize = 9
	a.Font = Enum.Font.Gotham
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = info

	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(0.52, -10, 0, 20)
	b.Position = UDim2.new(0.48, 0, 0, y)
	b.BackgroundTransparency = 1
	b.Text = value
	b.TextColor3 = TEXT
	b.TextSize = 9
	b.Font = Enum.Font.GothamMedium
	b.TextXAlignment = Enum.TextXAlignment.Right
	b.Parent = info
end

infoRow("PLAYER", "Unknown", 29)
infoRow("DISTANCE", "--", 49)
infoRow("LOCATION", "--", 69)
infoRow("LEVEL", "--", 89)
infoRow("HEALTH", "--", 109)
infoRow("EARNED", "0", 129)

--==================================================
-- SPEED
--==================================================

local speedText = Instance.new("TextLabel")
speedText.Size = UDim2.fromOffset(70, 18)
speedText.Position = UDim2.fromOffset(15, 221)
speedText.BackgroundTransparency = 1
speedText.Text = "Speed  1.0x"
speedText.TextColor3 = MUTED
speedText.TextSize = 9
speedText.Font = Enum.Font.GothamMedium
speedText.TextXAlignment = Enum.TextXAlignment.Left
speedText.Parent = main

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.fromOffset(130, 5)
speedBar.Position = UDim2.fromOffset(80, 228)
speedBar.BackgroundColor3 = Color3.fromRGB(52, 54, 61)
speedBar.BorderSizePixel = 0
speedBar.Parent = main

corner(speedBar, 99)

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = ACCENT
speedFill.BorderSizePixel = 0
speedFill.Parent = speedBar

corner(speedFill, 99)

local knob = Instance.new("TextButton")
knob.Size = UDim2.fromOffset(14, 14)
knob.Position = UDim2.new(0.5, -7, 0.5, -7)
knob.BackgroundColor3 = Color3.fromRGB(240, 242, 247)
knob.Text = ""
knob.Parent = speedBar

corner(knob, 99)

local draggingSpeed = false

local function setSpeed(x)
	local relative = math.clamp(
		(x - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X,
		0,
		1
	)

	speedFill.Size = UDim2.new(relative, 0, 1, 0)
	knob.Position = UDim2.new(relative, -7, 0.5, -7)

	local value = 0.5 + (relative * 1.5)
	speedText.Text = string.format("Speed  %.1fx", value)
end

knob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSpeed = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
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

speedBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setSpeed(input.Position.X)
		draggingSpeed = true
	end
end)

--==================================================
-- START
--==================================================

local start = Instance.new("TextButton")
start.Size = UDim2.fromOffset(190, 32)
start.Position = UDim2.fromOffset(224, 216)
start.BackgroundColor3 = ACCENT
start.Text = "START"
start.TextColor3 = Color3.new(1, 1, 1)
start.TextSize = 10
start.Font = Enum.Font.GothamBold
start.Parent = main

corner(start, 7)

local running = false

start.MouseButton1Click:Connect(function()
	running = not running

	if running then
		start.Text = "RUNNING"
		tween(start, 0.12, {
			BackgroundColor3 = GREEN
		})
	else
		start.Text = "START"
		tween(start, 0.12, {
			BackgroundColor3 = ACCENT
		})
	end
end)

--==================================================
-- SKILL POPUP
--==================================================

local popup = Instance.new("Frame")
popup.Size = UDim2.fromOffset(220, 150)
popup.Position = UDim2.new(0.5, -110, 0.5, -75)
popup.BackgroundColor3 = CARD
popup.BorderSizePixel = 0
popup.Visible = false
popup.ZIndex = 20
popup.Parent = gui

corner(popup, 10)

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(55, 58, 67)
popupStroke.Thickness = 1
popupStroke.Parent = popup

local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, -20, 0, 28)
popupTitle.Position = UDim2.fromOffset(10, 7)
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
	F = false
}

local function skillButton(letter, x, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(55, 31)
	b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = selected[letter] and ACCENT or CARD2
	b.Text = letter
	b.TextColor3 = TEXT
	b.TextSize = 10
	b.Font = Enum.Font.GothamBold
	b.ZIndex = 21
	b.Parent = popup

	corner(b, 7)

	b.MouseButton1Click:Connect(function()
		selected[letter] = not selected[letter]

		tween(b, 0.1, {
			BackgroundColor3 = selected[letter]
				and ACCENT
				or CARD2
		})
	end)
end

skillButton("Z", 10, 43)
skillButton("X", 82, 43)
skillButton("C", 154, 43)
skillButton("V", 46, 80)
skillButton("F", 118, 80)

local done = Instance.new("TextButton")
done.Size = UDim2.fromOffset(75, 26)
done.Position = UDim2.new(1, -85, 1, -34)
done.BackgroundColor3 = CARD2
done.Text = "DONE"
done.TextColor3 = TEXT
done.TextSize = 9
done.Font = Enum.Font.GothamBold
done.ZIndex = 21
done.Parent = popup

corner(done, 6)

local function closePopup()
	if not popup.Visible then
		return
	end

	local t = tween(
		popup,
		0.12,
		{
			Size = UDim2.fromOffset(200, 136)
		},
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)

	t.Completed:Connect(function()
		popup.Visible = false
	end)
end

skills.MouseButton1Click:Connect(function()
	popup.Visible = true
	popup.Size = UDim2.fromOffset(200, 136)

	tween(
		popup,
		0.16,
		{
			Size = UDim2.fromOffset(220, 150)
		}
	)
end)

done.MouseButton1Click:Connect(closePopup)

--==================================================
-- OUTSIDE CLICK
--==================================================

UIS.InputBegan:Connect(function(input)
	if not popup.Visible then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Touch
	and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local pos = input.Position
	local p = popup.AbsolutePosition
	local s = popup.AbsoluteSize

	local inside =
		pos.X >= p.X
		and pos.X <= p.X + s.X
		and pos.Y >= p.Y
		and pos.Y <= p.Y + s.Y

	if not inside then
		closePopup()
	end
end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

minimize.MouseButton1Click:Connect(function()
	if minimized then
		minimized = false

		tween(main, 0.18, {
			Size = UDim2.fromOffset(430, 270)
		})

		for _, child in ipairs(main:GetChildren()) do
			if child ~= header
			and child ~= divider
			and child ~= outline then

				if child:IsA("GuiObject") then
					child.Visible = true
				end
			end
		end

	else
		minimized = true

		for _, child in ipairs(main:GetChildren()) do
			if child ~= header
			and child ~= divider
			and child ~= outline then

				if child:IsA("GuiObject") then
					child.Visible = false
				end
			end
		end

		tween(main, 0.18, {
			Size = UDim2.fromOffset(430, 50)
		})
	end
end)

--==================================================
-- COMPACT LOGO MODE
--==================================================

local compactMode = false

local logo = Instance.new("TextButton")
logo.Size = UDim2.fromOffset(62, 62)
logo.Position = UDim2.new(0.5, -31, 0.5, -31)
logo.BackgroundColor3 = BG
logo.Text = "◆"
logo.TextColor3 = ACCENT
logo.TextSize = 23
logo.Font = Enum.Font.GothamBold
logo.Visible = false
logo.Parent = gui

corner(logo, 16)

local logoStroke = Instance.new("UIStroke")
logoStroke.Color = Color3.fromRGB(48, 51, 59)
logoStroke.Thickness = 1
logoStroke.Parent = logo

compact.MouseButton1Click:Connect(function()
	compactMode = true

	tween(main, 0.18, {
		Size = UDim2.fromOffset(0, 0)
	})

	task.delay(0.18, function()
		main.Visible = false
		logo.Visible = true
		logo.Size = UDim2.fromOffset(10, 10)

		tween(logo, 0.18, {
			Size = UDim2.fromOffset(62, 62)
		})
	end)
end)

logo.MouseButton1Click:Connect(function()
	tween(logo, 0.12, {
		Size = UDim2.fromOffset(10, 10)
	})

	task.delay(0.12, function()
		logo.Visible = false
		main.Visible = true

		main.Size = UDim2.fromOffset(0, 0)

		tween(main, 0.18, {
			Size = UDim2.fromOffset(430, 270)
		})
	end)
end)

--==================================================
-- CLOSE / DESTROY
--==================================================

close.MouseButton1Click:Connect(function()
	tween(main, 0.15, {
		Size = UDim2.fromOffset(0, 0)
	})

	task.delay(0.15, function()
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

UIS.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

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
end)