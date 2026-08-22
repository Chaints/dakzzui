local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DakzzUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

--// Main Window
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(340, 400)
main.Position = UDim2.new(0.5, -170, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

--// Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(18, 0)
title.BackgroundTransparency = 1
title.Text = "DAKZZ"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(38, 38)
close.Position = UDim2.new(1, -46, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
close.Text = "×"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = close

--// Status
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -36, 0, 42)
status.Position = UDim2.fromOffset(18, 62)
status.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
status.Text = "●  Ready"
status.TextColor3 = Color3.fromRGB(120, 255, 150)
status.TextSize = 13
status.Font = Enum.Font.GothamMedium
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = status

--// Tab container
local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -36, 0, 42)
tabs.Position = UDim2.fromOffset(18, 114)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local function makeTab(text, x)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(96, 38)
	button.Position = UDim2.fromOffset(x, 0)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(220, 220, 225)
	button.TextSize = 13
	button.Font = Enum.Font.GothamMedium
	button.Parent = tabs

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local mainTab = makeTab("Main", 0)
local playerTab = makeTab("Player", 102)
local settingsTab = makeTab("Settings", 204)

--// Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -36, 0, 210)
content.Position = UDim2.fromOffset(18, 166)
content.BackgroundTransparency = 1
content.Parent = main

local function makeButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 44)
	button.Position = UDim2.fromOffset(0, y)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 235, 240)
	button.TextSize = 13
	button.Font = Enum.Font.GothamMedium
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

makeButton("Button 1", 0)
makeButton("Button 2", 54)
makeButton("Button 3", 108)
makeButton("Button 4", 162)

--// Hide button
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.fromOffset(52, 52)
openButton.Position = UDim2.fromOffset(15, 15)
openButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openButton.Text = "☰"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 20
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 12)
openCorner.Parent = openButton

--// Close
close.MouseButton1Click:Connect(function()
	main.Visible = false
	openButton.Visible = true
end)

openButton.MouseButton1Click:Connect(function()
	main.Visible = true
	openButton.Visible = false
end)

--// Drag
local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)