local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- cleanup kalau execute ulang
local old = playerGui:FindFirstChild("DakzzBountyUI")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "DakzzBountyUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- COLORS
local BG = Color3.fromRGB(18, 19, 23)
local CARD = Color3.fromRGB(25, 27, 32)
local CARD2 = Color3.fromRGB(30, 32, 38)
local TEXT = Color3.fromRGB(235, 237, 242)
local MUTED = Color3.fromRGB(145, 149, 160)
local ACCENT = Color3.fromRGB(105, 150, 255)
local GREEN = Color3.fromRGB(90, 220, 140)

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function tween(obj, info, props)
	return TweenService:Create(obj, info, props)
end

-- MAIN
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(430, 270)
main.Position = UDim2.new(0.5, -215, 0.5, -135)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 12)

-- subtle stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(48, 51, 59)
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = main

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 24)
title.Position = UDim2.fromOffset(16, 7)
title.BackgroundTransparency = 1
title.Text = "DAKZZ BOUNTY"
title.TextColor3 = TEXT
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 15)
subtitle.Position = UDim2.fromOffset(16, 27)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Bounty Assistant"
subtitle.TextColor3 = MUTED
subtitle.TextSize = 9
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(8, 8)
statusDot.Position = UDim2.new(1, -28, 0, 17)
statusDot.BackgroundColor3 = GREEN
statusDot.BorderSizePixel = 0
statusDot.Parent = header
corner(statusDot, 99)

-- DIVIDER
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -32, 0, 1)
divider.Position = UDim2.fromOffset(16, 48)
divider.BackgroundColor3 = Color3.fromRGB(42, 44, 51)
divider.BorderSizePixel = 0
divider.Parent = main

-- LEFT
local left = Instance.new("Frame")
left.Size = UDim2.fromOffset(190, 155)
left.Position = UDim2.fromOffset(16, 60)
left.BackgroundTransparency = 1
left.Parent = main

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, 0, 0, 18)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET"
targetLabel.TextColor3 = MUTED
targetLabel.TextSize = 9
targetLabel.Font = Enum.Font.GothamBold
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = left

local targetBox = Instance.new("TextButton")
targetBox.Size = UDim2.new(1, 0, 0, 35)
targetBox.Position = UDim2.fromOffset(0, 21)
targetBox.BackgroundColor3 = CARD
targetBox.Text = "Player Name                 ›"
targetBox.TextColor3 = TEXT
targetBox.TextSize = 11
targetBox.Font = Enum.Font.GothamMedium
targetBox.TextXAlignment = Enum.TextXAlignment.Left
targetBox.Parent = left
corner(targetBox, 7)

local controlsLabel = Instance.new("TextLabel")
controlsLabel.Size = UDim2.new(1, 0, 0, 18)
controlsLabel.Position = UDim2.fromOffset(0, 66)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Text = "CONTROLS"
controlsLabel.TextColor3 = MUTED
controlsLabel.TextSize = 9
controlsLabel.Font = Enum.Font.GothamBold
controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
controlsLabel.Parent = left

local function createToggle(text, y)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -45, 0, 25)
	label.Position = UDim2.fromOffset(0, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = TEXT
	label.TextSize = 10
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = left

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(38, 20)
	button.Position = UDim2.new(1, -38, 0, y + 2)
	button.BackgroundColor3 = ACCENT
	button.Text = "ON"
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 8
	button.Font = Enum.Font.GothamBold
	button.Parent = left
	corner(button, 6)

	local enabled = true

	button.MouseButton1Click:Connect(function()
		enabled = not enabled
		button.Text = enabled and "ON" or "OFF"

		tween(
			button,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 = enabled
					and ACCENT
					or Color3.fromRGB(55, 57, 64)
			}
		):Play()
	end)
end

createToggle("Skip Player", 90)
createToggle("Hop Server", 118)

local skills = Instance.new("TextButton")
skills.Size = UDim2.new(1, 0, 0, 27)
skills.Position = UDim2.fromOffset(0, 146)
skills.BackgroundColor3 = CARD
skills.Text = "Select Skills                         ›"
skills.TextColor3 = TEXT
skills.TextSize = 10
skills.Font = Enum.Font.GothamMedium
skills.TextXAlignment = Enum.TextXAlignment.Left
skills.Parent = left
corner(skills, 7)

-- RIGHT / INFO
local info = Instance.new("Frame")
info.Size = UDim2.fromOffset(190, 155)
info.Position = UDim2.fromOffset(224, 60)
info.BackgroundColor3 = CARD
info.BorderSizePixel = 0
info.Parent = main
corner(info, 8)

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, -20, 0, 22)
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
	a.Size = UDim2.new(0.5, 0, 0, 20)
	a.Position = UDim2.fromOffset(10, y)
	a.BackgroundTransparency = 1
	a.Text = name
	a.TextColor3 = MUTED
	a.TextSize = 9
	a.Font = Enum.Font.Gotham
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = info

	local b = Instance.new("TextLabel")
	b.Size = UDim2.new(0.5, -10, 0, 20)
	b.Position = UDim2.new(0.5, 0, 0, y)
	b.BackgroundTransparency = 1
	b.Text = value
	b.TextColor3 = TEXT
	b.TextSize = 9
	b.Font = Enum.Font.GothamMedium
	b.TextXAlignment = Enum.TextXAlignment.Right
	b.Parent = info
end

infoRow("PLAYER", "Unknown", 32)
infoRow("DISTANCE", "--", 54)
infoRow("LOCATION", "--", 76)
infoRow("LEVEL", "--", 98)
infoRow("HEALTH", "--", 120)

-- SPEED
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.fromOffset(70, 18)
speedLabel.Position = UDim2.fromOffset(16, 224)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed  1.0x"
speedLabel.TextColor3 = MUTED
speedLabel.TextSize = 9
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = main

local bar = Instance.new("Frame")
bar.Size = UDim2.fromOffset(130, 4)
bar.Position = UDim2.fromOffset(82, 231)
bar.BackgroundColor3 = Color3.fromRGB(55, 57, 64)
bar.BorderSizePixel = 0
bar.Parent = main
corner(bar, 99)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.45, 0, 1, 0)
fill.BackgroundColor3 = ACCENT
fill.BorderSizePixel = 0
fill.Parent = bar
corner(fill, 99)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(10, 10)
knob.Position = UDim2.new(0.45, -5, 0.5, -5)
knob.BackgroundColor3 = Color3.fromRGB(240, 242, 247)
knob.BorderSizePixel = 0
knob.Parent = bar
corner(knob, 99)

-- START
local start = Instance.new("TextButton")
start.Size = UDim2.fromOffset(190, 32)
start.Position = UDim2.fromOffset(224, 218)
start.BackgroundColor3 = ACCENT
start.Text = "START"
start.TextColor3 = Color3.new(1, 1, 1)
start.TextSize = 10
start.Font = Enum.Font.GothamBold
start.Parent = main
corner(start, 7)

-- SKILL POPUP
local popup = Instance.new("Frame")
popup.Size = UDim2.fromOffset(220, 150)
popup.Position = UDim2.new(0.5, -110, 0.5, -75)
popup.BackgroundColor3 = CARD
popup.BorderSizePixel = 0
popup.Visible = false
popup.Parent = gui
corner(popup, 10)

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(55, 58, 67)
popupStroke.Thickness = 1
popupStroke.Parent = popup

local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, -20, 0, 28)
popupTitle.Position = UDim2.fromOffset(10, 8)
popupTitle.BackgroundTransparency = 1
popupTitle.Text = "SELECT SKILLS"
popupTitle.TextColor3 = TEXT
popupTitle.TextSize = 12
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.Parent = popup

local selected = {
	Z = true,
	X = true,
	C = true,
	V = true,
	F = false
}

local skillButtons = {}

local function skillButton(letter, x, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(55, 32)
	b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = selected[letter] and ACCENT or CARD2
	b.Text = letter
	b.TextColor3 = TEXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.Parent = popup
	corner(b, 7)

	b.MouseButton1Click:Connect(function()
		selected[letter] = not selected[letter]

		tween(
			b,
			TweenInfo.new(0.12),
			{
				BackgroundColor3 = selected[letter]
					and ACCENT
					or CARD2
			}
		):Play()
	end)

	skillButtons[letter] = b
end

skillButton("Z", 10, 45)
skillButton("X", 82, 45)
skillButton("C", 154, 45)
skillButton("V", 46, 83)
skillButton("F", 118, 83)

local done = Instance.new("TextButton")
done.Size = UDim2.fromOffset(80, 27)
done.Position = UDim2.new(1, -90, 1, -36)
done.BackgroundColor3 = CARD2
done.Text = "DONE"
done.TextColor3 = TEXT
done.TextSize = 9
done.Font = Enum.Font.GothamBold
done.Parent = popup
corner(done, 6)

-- popup animation
skills.MouseButton1Click:Connect(function()
	popup.Visible = true
	popup.Size = UDim2.fromOffset(200, 136)
	popup.Position = UDim2.new(0.5, -100, 0.5, -68)

	tween(
		popup,
		TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromOffset(220, 150),
			Position = UDim2.new(0.5, -110, 0.5, -75)
		}
	):Play()
end)

done.MouseButton1Click:Connect(function()
	tween(
		popup,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.fromOffset(200, 136)
		}
	):Play()

	task.delay(0.12, function()
		popup.Visible = false
	end)
end)

-- start dummy UI state
local running = false

start.MouseButton1Click:Connect(function()
	running = not running

	if running then
		start.Text = "RUNNING"
		start.BackgroundColor3 = Color3.fromRGB(65, 180, 115)
	else
		start.Text = "START"
		start.BackgroundColor3 = ACCENT
	end
end)

-- DRAG
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
	if not dragging then return end

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