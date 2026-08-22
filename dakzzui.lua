--// Lightweight Mobile GUI - UI ONLY
--// No exploit/gameplay functions

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "DakzzUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Main
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(340, 400)
main.Position = UDim2.new(0.5, -170, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(18, 0)
title.BackgroundTransparency = 1
title.Text = "DAKZZ UI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(40, 40)
close.Position = UDim2.new(1, -46, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
close.Text = "×"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

-- Status
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -36, 0, 55)
status.Position = UDim2.fromOffset(18, 62)
status.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
status.Text = "  ●  Ready"
status.TextColor3 = Color3.fromRGB(120, 255, 150)
status.TextSize = 14
status.Font = Enum.Font.GothamMedium
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main

Instance.new("UICorner", status).CornerRadius = UDim.new(0, 9)

-- Buttons
local function createButton(text, x, y, width)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(width, 48)
	button.Position = UDim2.fromOffset(x, y)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 235, 240)
	button.TextSize = 14
	button.Font = Enum.Font.GothamMedium
	button.Parent = main

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)

	return button
end

createButton("Button 1", 18, 132, 147)
createButton("Button 2", 175, 132, 147)
createButton("Button 3", 18, 190, 304)
createButton("Button 4", 18, 248, 304)

-- Footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -36, 0, 35)
footer.Position = UDim2.fromOffset(18, 310)
footer.BackgroundTransparency = 1
footer.Text = "Main     Player     Settings"
footer.TextColor3 = Color3.fromRGB(150, 150, 160)
footer.TextSize = 12
footer.Font = Enum.Font.GothamMedium
footer.Parent = main

-- Close / reopen
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

Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 12)

close.MouseButton1Click:Connect(function()
	main.Visible = false
	openButton.Visible = true
end)

openButton.MouseButton1Click:Connect(function()
	main.Visible = true
	openButton.Visible = false
end)