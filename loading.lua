local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("ZDLoading")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZDLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = playerGui

-- ==========================================
-- BACKDROP (fades in AFTER logo assembles, fades out BEFORE it disperses)
-- ==========================================

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.ZIndex = 0
backdrop.Parent = gui

local cellSize = 12
local gap = 3
local colUnit = cellSize + gap

-- Layout offsets (in cell-columns) so Z, x, D sit side by side with spacing
local Z_OFFSET = 0   -- columns 0-3
local X_OFFSET = 5   -- columns 5-7 (small, centered gap after Z)
local D_OFFSET = 9   -- columns 9-12

-- Total pattern width/height computed from the grid itself (not guessed),
-- so `holder` truly centers the assembled "Z x D" logo on screen.
local PATTERN_COLS = D_OFFSET + 4 -- D is 4 columns wide, starts at D_OFFSET
local PATTERN_ROWS = 5            -- Z, X, D are all 5 rows tall
local patternWidth = PATTERN_COLS * colUnit - gap
local patternHeight = PATTERN_ROWS * colUnit - gap

local holder = Instance.new("Frame")
holder.Size = UDim2.fromOffset(patternWidth, patternHeight)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.BackgroundTransparency = 1
holder.ZIndex = 1
holder.Parent = gui

-- ==========================================
-- POLA "Z x D"
-- 1 = ada kotak, 0 = kosong
-- ==========================================

local Z = {
	{1,1,1,1},
	{0,0,0,1},
	{0,0,1,0},
	{0,1,0,0},
	{1,1,1,1},
}

-- small "x" separator, offset down/centered to sit visually mid-height
local X = {
	{0,0,0},
	{1,0,1},
	{0,1,0},
	{1,0,1},
	{0,0,0},
}

local D = {
	{1,1,1,0},
	{1,0,0,1},
	{1,0,0,1},
	{1,0,0,1},
	{1,1,1,0},
}

local cells = {}

local function createCell(colOffset, x, y)
	local cell = Instance.new("Frame")
	cell.Size = UDim2.fromOffset(cellSize, cellSize)

	local targetX = (colOffset + x) * colUnit
	local targetY = y * colUnit

	cell.Position = UDim2.fromOffset(targetX, targetY)
	cell.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	cell.BackgroundTransparency = 0
	cell.BorderSizePixel = 0
	cell.ZIndex = 2
	cell.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = cell

	table.insert(cells, {
		obj = cell,
		target = Vector2.new(targetX, targetY),
	})

	return cell
end

-- BUAT Z
for y = 1, #Z do
	for x = 1, #Z[y] do
		if Z[y][x] == 1 then
			createCell(Z_OFFSET, x - 1, y - 1)
		end
	end
end

-- BUAT x (kecil, di tengah)
local xCellsStart = #cells + 1
for y = 1, #X do
	for x = 1, #X[y] do
		if X[y][x] == 1 then
			local c = createCell(X_OFFSET, x - 1, y - 1)
			c.Size = UDim2.fromOffset(cellSize * 0.7, cellSize * 0.7)
			-- re-center the smaller cell within its cell-grid slot
			local data = cells[#cells]
			local sizeDiff = cellSize * 0.3
			c.Position = UDim2.fromOffset(data.target.X + sizeDiff / 2, data.target.Y + sizeDiff / 2)
		end
	end
end

-- BUAT D
for y = 1, #D do
	for x = 1, #D[y] do
		if D[y][x] == 1 then
			createCell(D_OFFSET, x - 1, y - 1)
		end
	end
end

-- ==========================================
-- RANDOMIZE
-- ==========================================

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

math.randomseed(tick() * 1000)
shuffle(cells)

-- ==========================================
-- FASE 1: JATUH DARI ATAS, ASSEMBLE JADI "Z x D"
-- ==========================================

for _, data in ipairs(cells) do
	local cell = data.obj
	local target = data.target

	local startX = target.X + math.random(-70, 70)
	local startY = math.random(-150, -70)

	cell.Position = UDim2.fromOffset(startX, startY)
	cell.Rotation = math.random(-30, 30)

	task.delay(math.random() * 0.55, function()
		local tween = TweenService:Create(
			cell,
			TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(target.X, target.Y), Rotation = 0 }
		)
		tween:Play()

		-- simple landing flash: quick brighten then settle back
		tween.Completed:Connect(function()
			local flash = TweenService:Create(
				cell,
				TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundColor3 = Color3.fromRGB(255, 255, 255) }
			)
			flash:Play()
			task.delay(0.12, function()
				TweenService:Create(
					cell,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ BackgroundColor3 = Color3.fromRGB(245, 245, 245) }
				):Play()
			end)
		end)
	end)
end

-- tunggu sampai "Z x D" selesai assemble
task.wait(1.4)

-- ==========================================
-- FASE 2: BACKDROP FADE IN (logo sudah jadi, sekarang di-highlight)
-- ==========================================

TweenService:Create(
	backdrop,
	TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{ BackgroundTransparency = 0.35 }
):Play()

task.wait(0.9) -- hold, logo terpampang jelas dengan backdrop

-- ==========================================
-- FASE 3: BACKDROP FADE OUT DULU, BARU CELLS AMBYAR
-- ==========================================

TweenService:Create(
	backdrop,
	TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{ BackgroundTransparency = 1 }
):Play()

task.wait(0.35)

shuffle(cells)

for _, data in ipairs(cells) do
	local cell = data.obj

	task.delay(math.random() * 0.45, function()
		local fallX = data.target.X + math.random(-150, 150)
		local fallY = math.random(500, 900)

		local tween = TweenService:Create(
			cell,
			TweenInfo.new(math.random(55, 85) / 100, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromOffset(fallX, fallY), Rotation = math.random(-90, 90) }
		)
		tween:Play()
	end)
end

task.wait(1.4)

gui:Destroy()
