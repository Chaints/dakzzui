print("[Bounty Hunter] Menjalankan Bundle Skrip SEA 2 + UI Dashboard Estetik...")

-- ==========================================
-- 1. UTILITY: SERVICES & SMART UI PARENTING
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local SafeUIParent
pcall(function()
    SafeUIParent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
end)
if not SafeUIParent or not pcall(function() return SafeUIParent.Name end) then
    SafeUIParent = LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- Cleanup UI lama jika ada
pcall(function()
    if SafeUIParent:FindFirstChild("BountyHunterDashboard") then SafeUIParent.BountyHunterDashboard:Destroy() end
    if SafeUIParent:FindFirstChild("BountyBadge") then SafeUIParent.BountyBadge:Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("ZDLoading") then LocalPlayer.PlayerGui.ZDLoading:Destroy() end
    if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end
end)

-- ==========================================
-- 2. ANIMASI LOADING SCREEN ("Z x D")
-- ==========================================
pcall(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local guiLoading = Instance.new("ScreenGui")
    guiLoading.Name = "ZDLoading"
    guiLoading.IgnoreGuiInset = true
    guiLoading.ResetOnSpawn = false
    guiLoading.DisplayOrder = 9999
    guiLoading.Parent = playerGui

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 0
    backdrop.Parent = guiLoading

    local cellSize = 12
    local gap = 3
    local colUnit = cellSize + gap

    local Z_OFFSET, X_OFFSET, D_OFFSET = 0, 5, 9
    local PATTERN_COLS, PATTERN_ROWS = D_OFFSET + 4, 5
    local patternWidth = PATTERN_COLS * colUnit - gap
    local patternHeight = PATTERN_ROWS * colUnit - gap

    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(patternWidth, patternHeight)
    holder.Position = UDim2.fromScale(0.5, 0.5)
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 1
    holder.Parent = guiLoading

    local Z = {{1,1,1,1},{0,0,0,1},{0,0,1,0},{0,1,0,0},{1,1,1,1}}
    local X = {{0,0,0},{1,0,1},{0,1,0},{1,0,1},{0,0,0}}
    local D = {{1,1,1,0},{1,0,0,1},{1,0,0,1},{1,0,0,1},{1,1,1,0}}

    local cells = {}
    local function createCell(colOffset, x, y)
        local cell = Instance.new("Frame")
        cell.Size = UDim2.fromOffset(cellSize, cellSize)
        local targetX = (colOffset + x) * colUnit
        local targetY = y * colUnit
        cell.Position = UDim2.fromOffset(targetX, targetY)
        cell.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        cell.BorderSizePixel = 0
        cell.ZIndex = 2
        cell.Parent = holder
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 3)
        corner.Parent = cell
        table.insert(cells, {obj = cell, target = Vector2.new(targetX, targetY)})
        return cell
    end

    for y = 1, #Z do for x = 1, #Z[y] do if Z[y][x] == 1 then createCell(Z_OFFSET, x - 1, y - 1) end end end
    for y = 1, #X do for x = 1, #X[y] do if X[y][x] == 1 then
        local c = createCell(X_OFFSET, x - 1, y - 1)
        c.Size = UDim2.fromOffset(cellSize * 0.7, cellSize * 0.7)
        local data = cells[#cells]
        c.Position = UDim2.fromOffset(data.target.X + (cellSize * 0.3) / 2, data.target.Y + (cellSize * 0.3) / 2)
    end end end
    for y = 1, #D do for x = 1, #D[y] do if D[y][x] == 1 then createCell(D_OFFSET, x - 1, y - 1) end end end

    local function shuffle(tbl)
        for i = #tbl, 2, -1 do local j = math.random(i) tbl[i], tbl[j] = tbl[j], tbl[i] end
    end

    math.randomseed(tick() * 1000)
    shuffle(cells)

    pcall(function()
        for _, data in ipairs(cells) do
            local cell, target = data.obj, data.target
            cell.Position = UDim2.fromOffset(target.X + math.random(-70, 70), math.random(-150, -70))
            cell.Rotation = math.random(-30, 30)
            task.delay(math.random() * 0.55, function()
                TweenService:Create(cell, TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(target.X, target.Y), Rotation = 0 }):Play()
            end)
        end
        task.wait(1.4)
        TweenService:Create(backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.35 }):Play()
        task.wait(0.9)
        TweenService:Create(backdrop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
        task.wait(0.35)
        shuffle(cells)
        for _, data in ipairs(cells) do
            task.delay(math.random() * 0.45, function()
                TweenService:Create(data.obj, TweenInfo.new(math.random(55, 85) / 100, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(data.target.X + math.random(-150, 150), math.random(500, 900)), Rotation = math.random(-90, 90) }):Play()
            end)
        end
        task.wait(1.4)
    end)
    guiLoading:Destroy()
end)

-- ==========================================
-- 3. GLOBAL CONFIG & SYSTEM STATE
-- ==========================================
_G.AutoHuntEnabled = _G.AutoHuntEnabled ~= nil and _G.AutoHuntEnabled or false
_G.CustomFlightSpeed = _G.CustomFlightSpeed or 300
_G.CombatConfig = _G.CombatConfig or {
    ["Sword"] = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Fruit"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}},
    ["Gun"]   = {Z = {On=true}, X = {On=true}, C = {On=false}, V = {On=false}, F = {On=false}},
    ["Melee"] = {Z = {On=true}, X = {On=true}, C = {On=true}, V = {On=false}, F = {On=false}}
}

local ConfigFileName = "BountyHunterConfig.json"
local function saveConfig()
    pcall(function()
        if writefile then
            local data = { AutoHunt = _G.AutoHuntEnabled, FlightSpeed = _G.CustomFlightSpeed, Combat = _G.CombatConfig }
            writefile(ConfigFileName, HttpService:JSONEncode(data))
        end
    end)
end
local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(ConfigFileName) then
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(decoded) == "table" then
                if decoded.AutoHunt ~= nil then _G.AutoHuntEnabled = decoded.AutoHunt end
                if decoded.FlightSpeed then _G.CustomFlightSpeed = decoded.FlightSpeed end
                if type(decoded.Combat) == "table" then _G.CombatConfig = decoded.Combat end
            end
        end
    end)
end
loadConfig()

-- ==========================================
-- 4. MODULE DASHBOARD UI INLINED
-- ==========================================
local UIModule = {}
function UIModule.Init(SafeUIParent, state)
    local UI_NAME = "BountyHunterDashboard"
    local BG = Color3.fromRGB(20, 20, 20)
    local CARD = Color3.fromRGB(51, 51, 51)
    local CARD2 = Color3.fromRGB(70, 70, 70)
    local STROKE = Color3.fromRGB(112, 108, 97)
    local TEXT = Color3.fromRGB(255, 255, 255)
    local MUTED = Color3.fromRGB(180, 176, 166)
    local ACCENT = Color3.fromRGB(255, 255, 255)
    local ACCENT_2 = Color3.fromRGB(112, 108, 97)
    local ACCENT_TEXT = Color3.fromRGB(51, 51, 51)
    local GREEN = Color3.fromRGB(120, 200, 130)
    local ORANGE = Color3.fromRGB(230, 165, 90)
    local RED = Color3.fromRGB(220, 90, 90)

    local function corner(obj, radius) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius or 10) c.Parent = obj return c end
    local function uistroke(obj, color, thickness, transparency) local s = Instance.new("UIStroke") s.Color = color or STROKE s.Thickness = thickness or 1 s.Transparency = transparency or 0.35 s.Parent = obj return s end
    local function gradient(obj, c1, c2, rotation) local g = Instance.new("UIGradient") g.Color = ColorSequence.new(c1, c2) g.Rotation = rotation or 90 g.Parent = obj return g end

    local shadowTemplate = Instance.new("ImageLabel")
    shadowTemplate.Name = "Shadow" shadowTemplate.BackgroundTransparency = 1 shadowTemplate.Image = "rbxassetid://5028857084" shadowTemplate.ImageColor3 = Color3.fromRGB(0, 0, 0) shadowTemplate.ImageTransparency = 0.55 shadowTemplate.ScaleType = Enum.ScaleType.Slice shadowTemplate.SliceCenter = Rect.new(24, 24, 276, 276) shadowTemplate.Size = UDim2.new(1, 18, 1, 18) shadowTemplate.AnchorPoint = Vector2.new(0.5, 0.5) shadowTemplate.Position = UDim2.new(0.5, 0, 0.5, 4) shadowTemplate.ZIndex = -1
    local function addShadow(obj, intensity) local shadow = shadowTemplate:Clone() shadow.ImageTransparency = intensity or 0.55 shadow.Parent = obj return shadow end
    local function tween(obj, duration, props, style, direction) local t = TweenService:Create(obj, TweenInfo.new(duration or 0.12, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props) t:Play() return t end
    local function pressFeedback(button, normalColor, pressColor)
        button.MouseButton1Down:Connect(function() tween(button, 0.08, { BackgroundColor3 = pressColor }) end)
        button.MouseButton1Up:Connect(function() tween(button, 0.12, { BackgroundColor3 = normalColor }) end)
        button.MouseLeave:Connect(function() tween(button, 0.12, { BackgroundColor3 = normalColor }) end)
    end

    local UIRefs = {}
    local function createNewLayoutUI()
        if not SafeUIParent or SafeUIParent:FindFirstChild(UI_NAME) then return end
        local gui = Instance.new("ScreenGui") gui.Name = UI_NAME gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.DisplayOrder = 999 gui.Parent = SafeUIParent

        local ANCHOR_X, ANCHOR_Y_TABBAR, TABBAR_TO_CARD_GAP = 0.5, 0.14, 14
        local tabBarFrame = Instance.new("Frame") tabBarFrame.Name = "TabBar" tabBarFrame.Size = UDim2.fromOffset(390, 46) tabBarFrame.AnchorPoint = Vector2.new(ANCHOR_X, 0) tabBarFrame.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 0) tabBarFrame.BackgroundColor3 = CARD tabBarFrame.BorderSizePixel = 0 tabBarFrame.Parent = gui
        corner(tabBarFrame, 23) addShadow(tabBarFrame, 0.5) uistroke(tabBarFrame, STROKE, 1, 0.25) gradient(tabBarFrame, Color3.fromRGB(60, 60, 60), Color3.fromRGB(38, 38, 38), 90)

        local tabBarStatusDot = Instance.new("Frame") tabBarStatusDot.Size = UDim2.fromOffset(8, 8) tabBarStatusDot.AnchorPoint = Vector2.new(0, 0.5) tabBarStatusDot.Position = UDim2.new(0, 16, 0.5, 0) tabBarStatusDot.BackgroundColor3 = MUTED tabBarStatusDot.BorderSizePixel = 0 tabBarStatusDot.Parent = tabBarFrame corner(tabBarStatusDot, 99)

        local tabHolder = Instance.new("Frame") tabHolder.Size = UDim2.fromOffset(280, 32) tabHolder.AnchorPoint = Vector2.new(0, 0.5) tabHolder.Position = UDim2.new(0, 32, 0.5, 0) tabHolder.BackgroundTransparency = 1 tabHolder.Parent = tabBarFrame
        local tabLayout = Instance.new("UIListLayout") tabLayout.FillDirection = Enum.FillDirection.Horizontal tabLayout.Padding = UDim.new(0, 6) tabLayout.SortOrder = Enum.SortOrder.LayoutOrder tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center tabLayout.Parent = tabHolder

        local tabButtons, tabContainers, activeTabName, cardHidden = {}, {}, "DASHBOARD", false
        local function createTabButton(key, displayText, order)
            local b = Instance.new("TextButton") b.Size = UDim2.new(0, 64, 0, 28) b.LayoutOrder = order b.BackgroundColor3 = CARD2 b.AutoButtonColor = false b.Text = displayText b.TextColor3 = MUTED b.TextSize = 8 b.Font = Enum.Font.GothamBold b.Parent = tabHolder corner(b, 14) tabButtons[key] = b return b
        end
        createTabButton("DASHBOARD", "DASH", 1) createTabButton("TARGETS", "TARGET", 2) createTabButton("COMBAT", "COMBAT", 3) createTabButton("HOP", "HOP", 4)

        local function tabBarButton(icon, xOffsetFromRight, size)
            local b = Instance.new("TextButton") b.Size = UDim2.fromOffset(size or 28, size or 28) b.AnchorPoint = Vector2.new(1, 0.5) b.Position = UDim2.new(1, -xOffsetFromRight, 0.5, 0) b.BackgroundColor3 = CARD2 b.BackgroundTransparency = 0.3 b.Text = icon b.TextColor3 = TEXT b.TextSize = 13 b.Font = Enum.Font.GothamBold b.AutoButtonColor = false b.Parent = tabBarFrame corner(b, 99)
            b.MouseButton1Down:Connect(function() tween(b, 0.08, { BackgroundTransparency = 0 }) end)
            b.MouseButton1Up:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.3 }) end)
            b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.3 }) end)
            return b
        end
        local stopBtn = tabBarButton("×", 12, 28) local hideBtn = tabBarButton("▾", 46, 26)

        local main = Instance.new("Frame") main.Name = "Main" main.Size = UDim2.fromOffset(390, 264) main.AnchorPoint = Vector2.new(ANCHOR_X, 0) main.Position = UDim2.new(ANCHOR_X, 0, ANCHOR_Y_TABBAR, 46 + TABBAR_TO_CARD_GAP) main.BackgroundColor3 = BG main.BorderSizePixel = 0 main.Parent = gui corner(main, 22) addShadow(main, 0.5) uistroke(main, STROKE, 1, 0.2) gradient(main, Color3.fromRGB(60, 60, 60), Color3.fromRGB(38, 38, 38), 90)

        local dragging, dragInputStart, dragTabBarStart = false, nil, nil
        tabBarFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragInputStart = input.Position dragTabBarStart = tabBarFrame.Position end end)
        tabBarFrame.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragInputStart
                local newTabBarPos = UDim2.new(dragTabBarStart.X.Scale, dragTabBarStart.X.Offset + delta.X, dragTabBarStart.Y.Scale, dragTabBarStart.Y.Offset + delta.Y)
                tabBarFrame.Position = newTabBarPos
                main.Position = UDim2.new(newTabBarPos.X.Scale, newTabBarPos.X.Offset, newTabBarPos.Y.Scale, newTabBarPos.Y.Offset + 46 + TABBAR_TO_CARD_GAP)
            end
        end)

        local tabContentHeight = 232
        local function newTabContainer(name)
            local c = Instance.new("Frame") c.Size = UDim2.new(1, -28, 0, tabContentHeight) c.Position = UDim2.fromOffset(14, 16) c.BackgroundTransparency = 1 c.Visible = (name == "DASHBOARD") c.Parent = main tabContainers[name] = c return c
        end
        local function setActiveTab(name)
            if not tabContainers[name] then return end activeTabName = name
            for tabName, container in pairs(tabContainers) do container.Visible = (tabName == name) end
            for tabName, btn in pairs(tabButtons) do
                if tabName == name then tween(btn, 0.12, { BackgroundColor3 = ACCENT }) btn.TextColor3 = ACCENT_TEXT else tween(btn, 0.12, { BackgroundColor3 = CARD2 }) btn.TextColor3 = MUTED end
            end
        end

        local dashTab = newTabContainer("DASHBOARD")
        local info = Instance.new("Frame") info.Size = UDim2.new(1, 0, 1, 0) info.BackgroundColor3 = CARD info.BorderSizePixel = 0 info.Parent = dashTab corner(info, 18) addShadow(info, 0.6) uistroke(info, STROKE, 1, 0.5)

        local infoTitle = Instance.new("TextLabel") infoTitle.Size = UDim2.new(1, -78, 0, 18) infoTitle.Position = UDim2.fromOffset(14, 10) infoTitle.BackgroundTransparency = 1 infoTitle.Text = "TARGET INFO" infoTitle.TextColor3 = MUTED infoTitle.TextSize = 9 infoTitle.Font = Enum.Font.GothamBold infoTitle.TextXAlignment = Enum.TextXAlignment.Left infoTitle.Parent = info

        local startToggleBG = Instance.new("Frame") startToggleBG.Name = "StartToggle" startToggleBG.Size = UDim2.fromOffset(40, 20) startToggleBG.AnchorPoint = Vector2.new(1, 0) startToggleBG.Position = UDim2.new(1, -14, 0, 9) startToggleBG.BackgroundColor3 = Color3.fromRGB(70, 70, 70) startToggleBG.Parent = info corner(startToggleBG, 99) uistroke(startToggleBG, STROKE, 1, 0.4)
        local startToggleKnob = Instance.new("Frame") startToggleKnob.Size = UDim2.fromOffset(16, 16) startToggleKnob.AnchorPoint = Vector2.new(0, 0.5) startToggleKnob.Position = UDim2.new(0, 2, 0.5, 0) startToggleKnob.BackgroundColor3 = Color3.new(1, 1, 1) startToggleKnob.Parent = startToggleBG corner(startToggleKnob, 99)
        local startToggleBtn = Instance.new("TextButton") startToggleBtn.Size = UDim2.new(1, 0, 1, 0) startToggleBtn.BackgroundTransparency = 1 startToggleBtn.Text = "" startToggleBtn.Parent = startToggleBG

        local function setStartToggleVisual(on)
            if on then tween(startToggleBG, 0.14, { BackgroundColor3 = GREEN }) tween(startToggleKnob, 0.14, { Position = UDim2.new(1, -18, 0.5, 0) })
            else tween(startToggleBG, 0.14, { BackgroundColor3 = Color3.fromRGB(70, 70, 70) }) tween(startToggleKnob, 0.14, { Position = UDim2.new(0, 2, 0.5, 0) }) end
        end
        setStartToggleVisual(_G.AutoHuntEnabled or false)
        startToggleBtn.MouseButton1Click:Connect(function()
            local newState = not _G.AutoHuntEnabled
            _G.AutoHuntEnabled = newState
            setStartToggleVisual(newState)
            if state.OnToggleHunt then state.OnToggleHunt(newState) end
        end)

        local skipBtn = Instance.new("TextButton") skipBtn.Size = UDim2.new(1, -28, 0, 30) skipBtn.Position = UDim2.fromOffset(14, 32) skipBtn.BackgroundColor3 = CARD2 skipBtn.AutoButtonColor = false skipBtn.Text = "" skipBtn.Parent = info corner(skipBtn, 14) uistroke(skipBtn, STROKE, 1, 0.4)
        local skipLabel = Instance.new("TextLabel") skipLabel.Size = UDim2.new(1, 0, 1, 0) skipLabel.BackgroundTransparency = 1 skipLabel.Text = "SKIP TARGET" skipLabel.TextColor3 = TEXT skipLabel.TextSize = 10 skipLabel.Font = Enum.Font.GothamMedium skipLabel.Parent = skipBtn
        pressFeedback(skipBtn, CARD2, CARD)

        local infoValues = {}
        local function infoRow(name, value, y)
            local row = Instance.new("Frame") row.Size = UDim2.new(1, -28, 0, 19) row.Position = UDim2.fromOffset(14, y) row.BackgroundTransparency = 1 row.Parent = info
            local a = Instance.new("TextLabel") a.Size = UDim2.new(0.4, 0, 1, 0) a.BackgroundTransparency = 1 a.Text = name a.TextColor3 = MUTED a.TextSize = 9 a.Font = Enum.Font.Gotham a.TextXAlignment = Enum.TextXAlignment.Left a.Parent = row
            local b = Instance.new("TextLabel") b.Size = UDim2.new(0.6, 0, 1, 0) b.Position = UDim2.new(0.4, 0, 0, 0) b.BackgroundTransparency = 1 b.Text = value b.TextColor3 = TEXT b.TextSize = 9 b.Font = Enum.Font.GothamMedium b.TextXAlignment = Enum.TextXAlignment.Right b.Parent = row
            infoValues[name] = b return b
        end
        infoRow("STATUS", "Idle / Mencari...", 74) infoRow("NAMA", "-", 95) infoRow("LEVEL", "-", 116) infoRow("JARAK", "-", 137)

        local bountyRow = Instance.new("Frame") bountyRow.Size = UDim2.new(1, -28, 0, 19) bountyRow.Position = UDim2.fromOffset(14, 158) bountyRow.BackgroundTransparency = 1 bountyRow.Parent = info
        local bountyLabel = Instance.new("TextLabel") bountyLabel.Size = UDim2.new(0.4, 0, 1, 0) bountyLabel.BackgroundTransparency = 1 bountyLabel.Text = "BOUNTY" bountyLabel.TextColor3 = MUTED bountyLabel.TextSize = 9 bountyLabel.Font = Enum.Font.Gotham bountyLabel.TextXAlignment = Enum.TextXAlignment.Left bountyLabel.Parent = bountyRow
        local bountyValue = Instance.new("TextLabel") bountyValue.Size = UDim2.new(0.6, 0, 1, 0) bountyValue.Position = UDim2.new(0.4, 0, 0, 0) bountyValue.BackgroundTransparency = 1 bountyValue.Text = "◈ -" bountyValue.TextColor3 = TEXT bountyValue.TextSize = 9 bountyValue.Font = Enum.Font.GothamMedium bountyValue.TextXAlignment = Enum.TextXAlignment.Right bountyValue.Parent = bountyRow
        infoValues["BOUNTY"] = bountyValue

        local miniDivider = Instance.new("Frame") miniDivider.Size = UDim2.new(1, -28, 0, 1) miniDivider.Position = UDim2.fromOffset(14, 186) miniDivider.BackgroundColor3 = STROKE miniDivider.BackgroundTransparency = 0.4 miniDivider.Parent = info

        local totalRow = Instance.new("Frame") totalRow.Size = UDim2.new(1, -28, 0, 26) totalRow.Position = UDim2.fromOffset(14, 192) totalRow.BackgroundTransparency = 1 totalRow.Parent = info
        local totalLabel = Instance.new("TextLabel") totalLabel.Size = UDim2.new(0.55, 0, 1, 0) totalLabel.BackgroundTransparency = 1 totalLabel.Text = "TOTAL PENDAPATAN" totalLabel.TextColor3 = MUTED totalLabel.TextSize = 9 totalLabel.Font = Enum.Font.GothamBold totalLabel.TextXAlignment = Enum.TextXAlignment.Left totalLabel.Parent = totalRow
        local totalValue = Instance.new("TextLabel") totalValue.Size = UDim2.new(0.45, 0, 1, 0) totalValue.Position = UDim2.new(0.55, 0, 0, 0) totalValue.BackgroundTransparency = 1 totalValue.Text = "◈ 0" totalValue.TextColor3 = ACCENT totalValue.TextSize = 12 totalValue.Font = Enum.Font.GothamBold totalValue.TextXAlignment = Enum.TextXAlignment.Right totalValue.Parent = totalRow
        infoValues["TOTAL"] = totalValue

        -- ==========================================
        -- TAB "TARGETS": KARTU PROFIL TARGET ESTETIK
        -- ==========================================
        local targetsTab = newTabContainer("TARGETS")
        local targetCard = Instance.new("Frame") targetCard.Size = UDim2.new(1, 0, 0, 110) targetCard.BackgroundColor3 = CARD targetCard.Parent = targetsTab corner(targetCard, 18) addShadow(targetCard, 0.5) uistroke(targetCard, STROKE, 1, 0.4)

        local avatarImg = Instance.new("ImageLabel") avatarImg.Name = "AvatarImg" avatarImg.Size = UDim2.fromOffset(76, 76) avatarImg.Position = UDim2.fromOffset(16, 16) avatarImg.BackgroundColor3 = CARD2 avatarImg.Image = "rbxassetid://0" avatarImg.Parent = targetCard corner(avatarImg, 12) uistroke(avatarImg, STROKE, 1, 0.3)

        local targetNameLabel = Instance.new("TextLabel") targetNameLabel.Name = "TargetName" targetNameLabel.Size = UDim2.new(1, -108, 0, 20) targetNameLabel.Position = UDim2.fromOffset(102, 14) targetNameLabel.BackgroundTransparency = 1 targetNameLabel.Text = "Mencari Target..." targetNameLabel.TextColor3 = TEXT targetNameLabel.TextSize = 12 targetNameLabel.Font = Enum.Font.GothamBold targetNameLabel.TextXAlignment = Enum.TextXAlignment.Left targetNameLabel.Parent = targetCard

        local targetBountyLabel = Instance.new("TextLabel") targetBountyLabel.Name = "TargetBounty" targetBountyLabel.Size = UDim2.new(1, -108, 0, 16) targetBountyLabel.Position = UDim2.fromOffset(102, 34) targetBountyLabel.BackgroundTransparency = 1 targetBountyLabel.Text = "Bounty: -" targetBountyLabel.TextColor3 = MUTED targetBountyLabel.TextSize = 10 targetBountyLabel.Font = Enum.Font.GothamMedium targetBountyLabel.TextXAlignment = Enum.TextXAlignment.Left targetBountyLabel.Parent = targetCard

        local targetRankLabel = Instance.new("TextLabel") targetRankLabel.Name = "TargetRank" targetRankLabel.Size = UDim2.new(1, -108, 0, 16) targetRankLabel.Position = UDim2.fromOffset(102, 50) targetRankLabel.BackgroundTransparency = 1 targetRankLabel.Text = "Level: -" targetRankLabel.TextColor3 = MUTED targetRankLabel.TextSize = 10 targetRankLabel.Font = Enum.Font.GothamMedium targetRankLabel.TextXAlignment = Enum.TextXAlignment.Left targetRankLabel.Parent = targetCard

        local hpBarBg = Instance.new("Frame") hpBarBg.Size = UDim2.new(1, -108, 0, 16) hpBarBg.Position = UDim2.fromOffset(102, 70) hpBarBg.BackgroundColor3 = CARD2 hpBarBg.Parent = targetCard corner(hpBarBg, 8)
        local hpBarFill = Instance.new("Frame") hpBarFill.Name = "HPFill" hpBarFill.Size = UDim2.new(1, 0, 1, 0) hpBarFill.BackgroundColor3 = GREEN hpBarFill.Parent = hpBarBg corner(hpBarFill, 8)
        local hpTextLabel = Instance.new("TextLabel") hpTextLabel.Name = "HPText" hpTextLabel.Size = UDim2.new(1, 0, 1, 0) hpTextLabel.BackgroundTransparency = 1 hpTextLabel.Text = "HP: 100%" hpTextLabel.TextColor3 = Color3.fromRGB(30,30,30) hpTextLabel.TextSize = 9 hpTextLabel.Font = Enum.Font.GothamBold hpTextLabel.Parent = hpBarBg

        local statsCard = Instance.new("Frame") statsCard.Size = UDim2.new(1, 0, 0, 85) statsCard.Position = UDim2.fromOffset(0, 122) statsCard.BackgroundColor3 = CARD statsCard.Parent = targetsTab corner(statsCard, 18) addShadow(statsCard, 0.5) uistroke(statsCard, STROKE, 1, 0.4)

        local killsRowVal = Instance.new("TextLabel") killsRowVal.Name = "TotalKillsVal" killsRowVal.Size = UDim2.new(1, -28, 0, 20) killsRowVal.Position = UDim2.fromOffset(14, 16) killsRowVal.BackgroundTransparency = 1 killsRowVal.Text = "Total Kills: 0" killsRowVal.TextColor3 = TEXT killsRowVal.TextSize = 11 killsRowVal.Font = Enum.Font.GothamBold killsRowVal.TextXAlignment = Enum.TextXAlignment.Left killsRowVal.Parent = statsCard

        local bountyEarnedVal = Instance.new("TextLabel") bountyEarnedVal.Name = "BountyEarnedVal" bountyEarnedVal.Size = UDim2.new(1, -28, 0, 20) bountyEarnedVal.Position = UDim2.fromOffset(14, 44) bountyEarnedVal.BackgroundTransparency = 1 bountyEarnedVal.Text = "Bounty Earned Today: +0" bountyEarnedVal.TextColor3 = ORANGE bountyEarnedVal.TextSize = 11 bountyEarnedVal.Font = Enum.Font.GothamBold bountyEarnedVal.TextXAlignment = Enum.TextXAlignment.Left bountyEarnedVal.Parent = statsCard

        local totalKillsCount = 0
        local function addTargetLogEntry(entryText)
            totalKillsCount = totalKillsCount + 1
            if killsRowVal then killsRowVal.Text = "Total Kills: " .. totalKillsCount end
        end

        local combatTab = newTabContainer("COMBAT")
        local combatCard = Instance.new("Frame") combatCard.Size = UDim2.new(1, 0, 1, 0) combatCard.BackgroundColor3 = CARD combatCard.Parent = combatTab corner(combatCard, 18) addShadow(combatCard, 0.6) uistroke(combatCard, STROKE, 1, 0.5)
        local combatTitle = Instance.new("TextLabel") combatTitle.Size = UDim2.new(1, -20, 0, 16) combatTitle.Position = UDim2.fromOffset(14, 10) combatTitle.BackgroundTransparency = 1 combatTitle.Text = "PENGATURAN COMBAT" combatTitle.TextColor3 = MUTED combatTitle.TextSize = 8 combatTitle.Font = Enum.Font.GothamBold combatTitle.TextXAlignment = Enum.TextXAlignment.Left combatTitle.Parent = combatCard

        local speedRow = Instance.new("Frame") speedRow.Size = UDim2.new(1, -28, 0, 34) speedRow.Position = UDim2.fromOffset(14, 34) speedRow.BackgroundTransparency = 1 speedRow.Parent = combatCard
        local speedText = Instance.new("TextLabel") speedText.Size = UDim2.fromOffset(62, 34) speedText.BackgroundTransparency = 1 speedText.Text = "Speed" speedText.TextColor3 = MUTED speedText.TextSize = 9 speedText.Font = Enum.Font.GothamMedium speedText.TextXAlignment = Enum.TextXAlignment.Left speedText.Parent = speedRow
        local speedValueLabel = Instance.new("TextLabel") speedValueLabel.Size = UDim2.fromOffset(62, 34) speedValueLabel.Position = UDim2.fromOffset(0, 12) speedValueLabel.BackgroundTransparency = 1 speedValueLabel.Text = tostring(_G.CustomFlightSpeed) speedValueLabel.TextColor3 = TEXT speedValueLabel.TextSize = 11 speedValueLabel.Font = Enum.Font.GothamBold speedValueLabel.TextXAlignment = Enum.TextXAlignment.Left speedValueLabel.Parent = speedRow

        local speedTouchZone = Instance.new("TextButton") speedTouchZone.Size = UDim2.new(1, -62, 0, 34) speedTouchZone.Position = UDim2.fromOffset(62, 0) speedTouchZone.BackgroundTransparency = 1 speedTouchZone.Text = "" speedTouchZone.Parent = speedRow
        local speedBar = Instance.new("Frame") speedBar.Size = UDim2.new(1, 0, 0, 6) speedBar.AnchorPoint = Vector2.new(0, 0.5) speedBar.Position = UDim2.new(0, 0, 0.5, 0) speedBar.BackgroundColor3 = Color3.fromRGB(60, 25, 32) speedBar.Parent = speedTouchZone corner(speedBar, 99)

        local MAX_SPEED = 350
        local initialRel = math.clamp(_G.CustomFlightSpeed / MAX_SPEED, 0, 1)
        local speedFill = Instance.new("Frame") speedFill.Size = UDim2.new(initialRel, 0, 1, 0) speedFill.BackgroundColor3 = ACCENT speedFill.Parent = speedBar corner(speedFill, 99) gradient(speedFill, ACCENT, ACCENT_2, 0)
        local knob = Instance.new("Frame") knob.Size = UDim2.fromOffset(16, 16) knob.AnchorPoint = Vector2.new(0.5, 0.5) knob.Position = UDim2.new(initialRel, 0, 0.5, 0) knob.BackgroundColor3 = Color3.new(1, 1, 1) knob.ZIndex = 2 knob.Parent = speedBar corner(knob, 99) uistroke(knob, ACCENT, 2, 0)

        local draggingSpeedUI = false
        local function setSpeedFromX(x)
            local relative = math.clamp((x - speedBar.AbsolutePosition.X) / speedBar.AbsoluteSize.X, 0, 1)
            speedFill.Size = UDim2.new(relative, 0, 1, 0) knob.Position = UDim2.new(relative, 0, 0.5, 0)
            local newSpeed = math.max(1, math.floor(relative * MAX_SPEED))
            _G.CustomFlightSpeed = newSpeed
            speedValueLabel.Text = tostring(newSpeed)
        end
        speedTouchZone.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSpeedUI = true setSpeedFromX(input.Position.X) tween(knob, 0.1, { Size = UDim2.fromOffset(19, 19) })
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and draggingSpeedUI then
                tween(knob, 0.1, { Size = UDim2.fromOffset(16, 16) }) if state.SaveConfig then state.SaveConfig() end draggingSpeedUI = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if draggingSpeedUI and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then setSpeedFromX(input.Position.X) end
        end)

        local skillDivider = Instance.new("Frame") skillDivider.Size = UDim2.new(1, -28, 0, 1) skillDivider.Position = UDim2.fromOffset(14, 74) skillDivider.BackgroundColor3 = STROKE skillDivider.BackgroundTransparency = 0.4 skillDivider.Parent = combatCard
        local skillSectionTitle = Instance.new("TextLabel") skillSectionTitle.Size = UDim2.new(1, -28, 0, 14) skillSectionTitle.Position = UDim2.fromOffset(14, 82) skillSectionTitle.BackgroundTransparency = 1 skillSectionTitle.Text = "SELECT SKILL" skillSectionTitle.TextColor3 = MUTED skillSectionTitle.TextSize = 8 skillSectionTitle.Font = Enum.Font.GothamBold skillSectionTitle.TextXAlignment = Enum.TextXAlignment.Left skillSectionTitle.Parent = combatCard
        local skillScroll = Instance.new("ScrollingFrame") skillScroll.Size = UDim2.new(1, -28, 1, -102) skillScroll.Position = UDim2.fromOffset(14, 100) skillScroll.BackgroundTransparency = 1 skillScroll.ScrollBarThickness = 3 skillScroll.ScrollBarImageColor3 = ACCENT skillScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y skillScroll.Parent = combatCard
        local skillListLayout = Instance.new("UIListLayout") skillListLayout.Padding = UDim.new(0, 8) skillListLayout.SortOrder = Enum.SortOrder.LayoutOrder skillListLayout.Parent = skillScroll

        local SKILL_CATEGORIES = {
            { name = "Melee", keys = { "Z", "X", "C" } },
            { name = "Sword", keys = { "Z", "X" } },
            { name = "Gun",   keys = { "Z", "X" } },
            { name = "Fruit", keys = { "Z", "X", "C", "V", "F" } },
        }
        _G.CombatConfig = _G.CombatConfig or {}
        local function ensureCombatConfigEntry(category, key)
            _G.CombatConfig[category] = _G.CombatConfig[category] or {}
            _G.CombatConfig[category][key] = _G.CombatConfig[category][key] or { On = true }
            return _G.CombatConfig[category][key]
        end

        local function createKeyToggle(parent, category, key, layoutOrder)
            local cfg = ensureCombatConfigEntry(category, key)
            local chip = Instance.new("Frame") chip.Size = UDim2.fromOffset(50, 26) chip.LayoutOrder = layoutOrder chip.BackgroundColor3 = cfg.On and GREEN or CARD2 chip.Parent = parent corner(chip, 10) uistroke(chip, STROKE, 1, 0.5)
            local chipLabel = Instance.new("TextLabel") chipLabel.Size = UDim2.new(1, 0, 1, 0) chipLabel.BackgroundTransparency = 1 chipLabel.Text = key chipLabel.TextColor3 = cfg.On and ACCENT_TEXT or TEXT chipLabel.TextSize = 11 chipLabel.Font = Enum.Font.GothamBold chipLabel.Parent = chip
            local chipBtn = Instance.new("TextButton") chipBtn.Size = UDim2.new(1, 0, 1, 0) chipBtn.BackgroundTransparency = 1 chipBtn.Text = "" chipBtn.Parent = chip
            chipBtn.MouseButton1Click:Connect(function()
                cfg.On = not cfg.On
                if cfg.On then tween(chip, 0.12, { BackgroundColor3 = GREEN }) chipLabel.TextColor3 = ACCENT_TEXT
                else tween(chip, 0.12, { BackgroundColor3 = CARD2 }) chipLabel.TextColor3 = TEXT end
                if state.SaveConfig then state.SaveConfig() end
            end)
            return chip
        end

        for catOrder, catData in ipairs(SKILL_CATEGORIES) do
            local catRow = Instance.new("Frame") catRow.Size = UDim2.new(1, 0, 0, 44) catRow.LayoutOrder = catOrder catRow.BackgroundTransparency = 1 catRow.Parent = skillScroll
            local catLabel = Instance.new("TextLabel") catLabel.Size = UDim2.new(1, 0, 0, 14) catLabel.BackgroundTransparency = 1 catLabel.Text = catData.name:upper() catLabel.TextColor3 = MUTED catLabel.TextSize = 9 catLabel.Font = Enum.Font.GothamMedium catLabel.TextXAlignment = Enum.TextXAlignment.Left catLabel.Parent = catRow
            local chipHolder = Instance.new("Frame") chipHolder.Size = UDim2.new(1, 0, 0, 26) chipHolder.Position = UDim2.fromOffset(0, 18) chipHolder.BackgroundTransparency = 1 chipHolder.Parent = catRow
            local chipLayout = Instance.new("UIListLayout") chipLayout.FillDirection = Enum.FillDirection.Horizontal chipLayout.Padding = UDim.new(0, 8) chipLayout.SortOrder = Enum.SortOrder.LayoutOrder chipLayout.Parent = chipHolder
            for keyOrder, key in ipairs(catData.keys) do createKeyToggle(chipHolder, catData.name, key, keyOrder) end
        end

        local hopTab = newTabContainer("HOP")
        local hopBtn = Instance.new("TextButton") hopBtn.Size = UDim2.new(1, 0, 1, 0) hopBtn.BackgroundColor3 = CARD hopBtn.AutoButtonColor = false hopBtn.Text = "" hopBtn.Parent = hopTab corner(hopBtn, 18) addShadow(hopBtn, 0.6) uistroke(hopBtn, STROKE, 1, 0.5)
        local hopDot = Instance.new("Frame") hopDot.Size = UDim2.fromOffset(10, 10) hopDot.AnchorPoint = Vector2.new(0.5, 0.5) hopDot.Position = UDim2.new(0.5, 0, 0.38, 0) hopDot.BackgroundColor3 = ORANGE hopDot.Parent = hopBtn corner(hopDot, 99)
        local hopLabel = Instance.new("TextLabel") hopLabel.Size = UDim2.new(1, -20, 0, 20) hopLabel.AnchorPoint = Vector2.new(0.5, 0.5) hopLabel.Position = UDim2.new(0.5, 0, 0.65, 0) hopLabel.BackgroundTransparency = 1 hopLabel.Text = "MENCARI..." hopLabel.TextColor3 = TEXT hopLabel.TextSize = 12 hopLabel.Font = Enum.Font.GothamBold hopLabel.Parent = hopBtn
        pressFeedback(hopBtn, CARD, CARD2)

        for tabName, btn in pairs(tabButtons) do btn.MouseButton1Click:Connect(function() setActiveTab(tabName) end) end
        setActiveTab("DASHBOARD")

        hideBtn.MouseButton1Click:Connect(function()
            cardHidden = not cardHidden main.Visible = not cardHidden hideBtn.Text = cardHidden and "▸" or "▾"
        end)

        local logo = Instance.new("TextButton") logo.Name = "ZDLogo" logo.Size = UDim2.fromOffset(52, 52) logo.AnchorPoint = Vector2.new(0.5, 0.5) logo.Position = UDim2.new(0, 46, 0, 90) logo.BackgroundColor3 = BG logo.AutoButtonColor = false logo.Text = "" logo.Visible = true logo.ZIndex = 50 logo.Parent = gui corner(logo, 26) uistroke(logo, STROKE, 1, 0.15) gradient(logo, Color3.fromRGB(60, 60, 60), Color3.fromRGB(30, 30, 30), 90)
        local logoZ = Instance.new("TextLabel") logoZ.Size = UDim2.fromOffset(36, 36) logoZ.AnchorPoint = Vector2.new(0.5, 0.5) logoZ.Position = UDim2.new(0.5, -5, 0.5, -2) logoZ.BackgroundTransparency = 1 logoZ.Text = "Z" logoZ.TextColor3 = ACCENT logoZ.TextTransparency = 0.15 logoZ.TextSize = 22 logoZ.Font = Enum.Font.GothamBlack logoZ.ZIndex = 51 logoZ.Parent = logo
        local logoD = Instance.new("TextLabel") logoD.Size = UDim2.fromOffset(36, 36) logoD.AnchorPoint = Vector2.new(0.5, 0.5) logoD.Position = UDim2.new(0.5, 6, 0.5, 3) logoD.BackgroundTransparency = 1 logoD.Text = "D" logoD.TextColor3 = TEXT logoD.TextSize = 22 logoD.Font = Enum.Font.GothamBlack logoD.ZIndex = 52 logoD.Parent = logo
        local logoStatusDot = Instance.new("Frame") logoStatusDot.Size = UDim2.fromOffset(9, 9) logoStatusDot.AnchorPoint = Vector2.new(0.5, 0.5) logoStatusDot.Position = UDim2.new(1, -8, 0, 8) logoStatusDot.BackgroundColor3 = MUTED logoStatusDot.ZIndex = 53 logoStatusDot.Parent = logo corner(logoStatusDot, 99) uistroke(logoStatusDot, BG, 2, 0)

        local burstColors = { ACCENT, TEXT, ACCENT_2 }
        local function playLogoBurst()
            for i = 1, 9 do
                local angle, dist = (i / 9) * math.pi * 2, 34
                local particle = Instance.new("Frame") particle.Size = UDim2.fromOffset(6, 6) particle.AnchorPoint = Vector2.new(0.5, 0.5) particle.Position = UDim2.new(0.5, 0, 0.5, 0) particle.BackgroundColor3 = burstColors[(i % 3) + 1] particle.ZIndex = 49 particle.Parent = logo corner(particle, 2)
                tween(particle, 0.28, { Position = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist), BackgroundTransparency = 1, Rotation = math.random(-60, 60) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.28, function() particle:Destroy() end)
            end
            tween(logo, 0.08, { Size = UDim2.fromOffset(46, 46) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(0.08, function() tween(logo, 0.12, { Size = UDim2.fromOffset(52, 52) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end)
        end

        local everythingHidden = false
        local logoDragging, logoDragStart, logoStartPos, logoMoved = false, nil, nil, false
        logo.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                logoDragging = true logoMoved = false logoDragStart = input.Position logoStartPos = logo.Position
            end
        end)
        logo.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then logoDragging = false end end)
        UserInputService.InputChanged:Connect(function(input)
            if logoDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - logoDragStart
                if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then logoMoved = true end
                if logoMoved then logo.Position = UDim2.new(logoStartPos.X.Scale, logoStartPos.X.Offset + delta.X, logoStartPos.Y.Scale, logoStartPos.Y.Offset + delta.Y) end
            end
        end)
        logo.MouseButton1Click:Connect(function()
            if logoMoved then return end
            playLogoBurst() everythingHidden = not everythingHidden
            tabBarFrame.Visible = not everythingHidden main.Visible = not everythingHidden and not cardHidden
        end)

        task.spawn(function()
            while gui.Parent do
                task.wait(0.3)
                logoStatusDot.BackgroundColor3 = state.isHunting and (state.currentTargetPlayer and RED or GREEN) or MUTED
            end
        end)

        local confirmBackdrop = Instance.new("TextButton") confirmBackdrop.Size = UDim2.fromScale(1, 1) confirmBackdrop.BackgroundColor3 = Color3.new(0, 0, 0) confirmBackdrop.BackgroundTransparency = 1 confirmBackdrop.Text = "" confirmBackdrop.Visible = false confirmBackdrop.ZIndex = 90 confirmBackdrop.Parent = gui
        local confirmPopup = Instance.new("Frame") confirmPopup.Size = UDim2.fromOffset(240, 140) confirmPopup.AnchorPoint = Vector2.new(0.5, 0.5) confirmPopup.Position = UDim2.new(0.5, 0, 0.46, 0) confirmPopup.BackgroundColor3 = CARD confirmPopup.Visible = false confirmPopup.ZIndex = 91 confirmPopup.Parent = gui corner(confirmPopup, 14) uistroke(confirmPopup, STROKE, 1, 0.15) gradient(confirmPopup, Color3.fromRGB(45, 45, 45), Color3.fromRGB(25, 25, 25), 90)
        local confirmTitle = Instance.new("TextLabel") confirmTitle.Size = UDim2.new(1, -32, 0, 20) confirmTitle.Position = UDim2.fromOffset(16, 18) confirmTitle.BackgroundTransparency = 1 confirmTitle.Text = "Hapus Script?" confirmTitle.TextColor3 = TEXT confirmTitle.TextSize = 14 confirmTitle.Font = Enum.Font.GothamBold confirmTitle.TextXAlignment = Enum.TextXAlignment.Left confirmTitle.ZIndex = 92 confirmTitle.Parent = confirmPopup
        local confirmDesc = Instance.new("TextLabel") confirmDesc.Size = UDim2.new(1, -32, 0, 34) confirmDesc.Position = UDim2.fromOffset(16, 42) confirmDesc.BackgroundTransparency = 1 confirmDesc.Text = "Script akan berhenti total dan dashboard akan ditutup. Yakin?" confirmDesc.TextColor3 = MUTED confirmDesc.TextSize = 10 confirmDesc.Font = Enum.Font.Gotham confirmDesc.TextXAlignment = Enum.TextXAlignment.Left confirmDesc.TextWrapped = true confirmDesc.ZIndex = 92 confirmDesc.Parent = confirmPopup

        local function confirmButton(text, xOffset, bgColor, textColor)
            local b = Instance.new("TextButton") b.Size = UDim2.new(0.5, -20, 0, 34) b.Position = UDim2.new(0, xOffset, 1, -50) b.BackgroundColor3 = bgColor b.Text = text b.TextColor3 = textColor b.TextSize = 11 b.Font = Enum.Font.GothamBold b.ZIndex = 92 b.Parent = confirmPopup corner(b, 9) pressFeedback(b, bgColor, bgColor == RED and Color3.fromRGB(190, 75, 80) or CARD2) return b
        end
        local yesBtn = confirmButton("YA, HAPUS", 16, RED, Color3.fromRGB(255, 255, 255))
        local noBtn = confirmButton("BATAL", 128, CARD2, TEXT) uistroke(noBtn, STROKE, 1, 0.4)

        local function openConfirm() confirmBackdrop.Visible = true confirmPopup.Visible = true confirmBackdrop.BackgroundTransparency = 1 confirmPopup.Size = UDim2.fromOffset(220, 126) tween(confirmBackdrop, 0.15, { BackgroundTransparency = 0.5 }) tween(confirmPopup, 0.16, { Size = UDim2.fromOffset(240, 140) }) end
        local function closeConfirm() tween(confirmBackdrop, 0.15, { BackgroundTransparency = 1 }) local t = tween(confirmPopup, 0.14, { Size = UDim2.fromOffset(220, 126) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) t.Completed:Connect(function() confirmPopup.Visible = false confirmBackdrop.Visible = false end) end
        stopBtn.MouseButton1Click:Connect(openConfirm) confirmBackdrop.MouseButton1Click:Connect(closeConfirm) noBtn.MouseButton1Click:Connect(closeConfirm)
        yesBtn.MouseButton1Click:Connect(function() state.stopRequested = true closeConfirm() tween(main, 0.14, { Size = UDim2.fromOffset(6, 6) }) tween(logo, 0.14, { Size = UDim2.fromOffset(6, 6) }) task.delay(0.14, function() gui:Destroy() end) end)

        skipBtn.MouseButton1Click:Connect(function()
            if state.currentTargetPlayer then state.manualSkipList[state.currentTargetPlayer.Name] = true state.manualSkipRequested = true skipLabel.Text = "SKIPPED!" tween(skipBtn, 0.1, { BackgroundColor3 = CARD2 }) task.wait(0.3) skipLabel.Text = "SKIP TARGET" tween(skipBtn, 0.1, { BackgroundColor3 = CARD }) end
        end)

        _G.PersistentReadyJobIds = _G.PersistentReadyJobIds or {}
        local isHoppingNow = false
        task.spawn(function()
            while task.wait(0.3) do
                if not isHoppingNow then
                    local count = #_G.PersistentReadyJobIds
                    if count > 0 then hopLabel.Text = "HOP (" .. count .. " SIAP)" tween(hopDot, 0.15, { BackgroundColor3 = GREEN })
                    else hopLabel.Text = "MENCARI..." tween(hopDot, 0.15, { BackgroundColor3 = ORANGE }) end
                end
            end
        end)

        hopBtn.MouseButton1Click:Connect(function()
            if isHoppingNow or #_G.PersistentReadyJobIds == 0 then return end
            isHoppingNow = true
            local function attemptHop()
                local targetJobId = table.remove(_G.PersistentReadyJobIds, 1)
                if not targetJobId then hopLabel.Text = "GAGAL, ULANGI" tween(hopDot, 0.15, { BackgroundColor3 = RED }) task.wait(1.2) isHoppingNow = false return end
                hopLabel.Text = "JOINING..." tween(hopDot, 0.15, { BackgroundColor3 = GREEN })
                local ok = pcall(function() local serverBrowser = ReplicatedStorage:FindFirstChild("__ServerBrowser") if serverBrowser then serverBrowser:InvokeServer("teleport", targetJobId) end end)
                task.wait(2)
                if not ok then
                    if #_G.PersistentReadyJobIds > 0 then hopLabel.Text = "SERVER PENUH, COBA LAGI..." attemptHop() return
                    else hopLabel.Text = "GAGAL, ULANGI" tween(hopDot, 0.15, { BackgroundColor3 = RED }) task.wait(1.2) end
                end
                isHoppingNow = false
            end
            attemptHop()
        end)

        local lastKnownHuntFlag = _G.AutoHuntEnabled or false
        task.spawn(function()
            while gui.Parent do
                task.wait(0.3)
                tabBarStatusDot.BackgroundColor3 = state.isHunting and (state.currentTargetPlayer and RED or GREEN) or MUTED
                local huntFlag = _G.AutoHuntEnabled or false
                if huntFlag ~= lastKnownHuntFlag then lastKnownHuntFlag = huntFlag setStartToggleVisual(huntFlag) end
                if infoValues["TOTAL"] then
                    local total = state.totalHadiah or 0
                    local formattedTotal = tostring(math.floor(total))
                    if total >= 1000000 then formattedTotal = string.format("%.1fM", total / 1000000)
                    elseif total >= 1000 then formattedTotal = string.format("%.1fK", total / 1000) end
                    infoValues["TOTAL"].Text = "◈ " .. formattedTotal
                end
                
                pcall(function()
                    local tPlayer = state.currentTargetPlayer
                    if tPlayer and tPlayer.Parent then
                        targetNameLabel.Text = tPlayer.Name
                        local leaderstats = tPlayer:FindFirstChild("leaderstats")
                        local bountyVal = leaderstats and (leaderstats:FindFirstChild("Bounty/Honor") or leaderstats:FindFirstChild("Bounty"))
                        local bNum = bountyVal and bountyVal.Value or 0
                        local bStr = tostring(bNum)
                        if bNum >= 1000000 then bStr = string.format("%.1fM+", bNum / 1000000)
                        elseif bNum >= 1000 then bStr = string.format("%.1fK+", bNum / 1000) end
                        targetBountyLabel.Text = "Bounty: " .. bStr

                        local dataFolder = tPlayer:FindFirstChild("Data")
                        local lvVal = tPlayer:FindFirstChild("Level") or (dataFolder and dataFolder:FindFirstChild("Level"))
                        targetRankLabel.Text = "Level: " .. tostring(lvVal and lvVal.Value or "1500")

                        local tChar = tPlayer.Character
                        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                        if tHum and tHum.MaxHealth > 0 then
                            local hpPct = math.clamp(tHum.Health / tHum.MaxHealth, 0, 1)
                            hpBarFill.Size = UDim2.new(hpPct, 0, 1, 0)
                            hpTextLabel.Text = string.format("HP: %d%%", math.floor(hpPct * 100))
                        else
                            hpBarFill.Size = UDim2.new(1, 0, 1, 0)
                            hpTextLabel.Text = "HP: 100%"
                        end

                        pcall(function()
                            if avatarImg.Image == "rbxassetid://0" or avatarImg:GetAttribute("LoadedUser") ~= tPlayer.UserId then
                                avatarImg:SetAttribute("LoadedUser", tPlayer.UserId)
                                local thumbType = Enum.ThumbnailType.HeadShot
                                local thumbSize = Enum.ThumbnailSize.Size150x150
                                local content, isReady = Players:GetUserThumbnailAsync(tPlayer.UserId, thumbType, thumbSize)
                                if isReady then avatarImg.Image = content end
                            end
                        end)
                    else
                        targetNameLabel.Text = "Tidak Ada Target"
                        targetBountyLabel.Text = "Bounty: -"
                        targetRankLabel.Text = "Level: -"
                        hpBarFill.Size = UDim2.new(1, 0, 1, 0)
                        hpTextLabel.Text = "HP: 0%"
                        avatarImg.Image = "rbxassetid://0"
                        avatarImg:SetAttribute("LoadedUser", nil)
                    end

                    if bountyEarnedVal then
                        local total = state.totalHadiah or 0
                        local fTotal = tostring(math.floor(total))
                        if total >= 1000000 then fTotal = string.format("%.1fM", total / 1000000)
                        elseif total >= 1000 then fTotal = string.format("%.1fK", total / 1000) end
                        bountyEarnedVal.Text = "Bounty Earned Today: +" .. fTotal
                    end
                end)
            end
        end)

        local JARAK_UPDATE_INTERVAL, IDLE_POLL_INTERVAL, lastJarakText = 5, 1, nil
        task.spawn(function()
            while gui.Parent do
                if not state.currentTargetPlayer then lastJarakText = nil task.wait(IDLE_POLL_INTERVAL)
                else
                    task.wait(JARAK_UPDATE_INTERVAL)
                    if infoValues["JARAK"] and state.currentTargetPlayer and state.currentTargetPlayer.Parent then
                        pcall(function()
                            local myChar, targetChar = LocalPlayer.Character, state.currentTargetPlayer.Character
                            local myRoot, targetRoot = myChar and myChar:FindFirstChild("HumanoidRootPart"), targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                            if myRoot and targetRoot then
                                local newText = tostring(math.floor((myRoot.Position - targetRoot.Position).Magnitude)) .. " studs"
                                if newText ~= lastJarakText then infoValues["JARAK"].Text = newText lastJarakText = newText end
                            end
                        end)
                    end
                end
            end
        end)

        UIRefs.infoValues = infoValues
        UIRefs.addTargetLogEntry = addTargetLogEntry
    end

    local function updateHUDDisplay(player)
        pcall(function()
            if not UIRefs.infoValues then return end
            local iv = UIRefs.infoValues
            if player and player.Parent then
                local leaderstats, dataFolder = player:FindFirstChild("leaderstats"), player:FindFirstChild("Data")
                local lvVal = player:FindFirstChild("Level") or (dataFolder and dataFolder:FindFirstChild("Level")) or "1500"
                local bountyVal = leaderstats and (leaderstats:FindFirstChild("Bounty/Honor") or leaderstats:FindFirstChild("Bounty"))
                local formattedBounty = bountyVal and tostring(bountyVal.Value) or "-"
                if bountyVal and bountyVal.Value >= 1000000 then formattedBounty = string.format("%.1fM", bountyVal.Value / 1000000)
                elseif bountyVal and bountyVal.Value >= 1000 then formattedBounty = string.format("%.1fK", bountyVal.Value / 1000) end
                local distanceText = "-"
                pcall(function()
                    local myRoot, targetRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and targetRoot then distanceText = tostring(math.floor((myRoot.Position - targetRoot.Position).Magnitude)) .. " studs" end
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

    local function addTargetLogEntry(entryText)
        pcall(function() createNewLayoutUI() if UIRefs.addTargetLogEntry then UIRefs.addTargetLogEntry(entryText) end end)
    end

    createNewLayoutUI()
    return { createNewLayoutUI = createNewLayoutUI, updateHUDDisplay = updateHUDDisplay, addTargetLogEntry = addTargetLogEntry, UIRefs = UIRefs }
end

-- ==========================================
-- 5. BACK-END LOGIC & SEA 2 CORE ENGINE
-- ==========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local NetFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = NetFolder:WaitForChild("RE/RegisterAttack")
local RegisterHit = NetFolder:WaitForChild("RE/RegisterHit")

local JedaSenjataAsli = 0.4000000059604645
local TokenKeamanan = "083cf9b7"

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
local CommF = RemotesFolder and RemotesFolder:WaitForChild("CommF_", 3)
local CommE = RemotesFolder and RemotesFolder:WaitForChild("CommE", 3)
local ClockFolder = RemotesFolder and RemotesFolder:FindFirstChild("Clock")
local MasterClockRemote = ClockFolder and ClockFolder:WaitForChild("DelayedRequestFunction", 3)

local M1_ATTACK_RANGE = 17.0   
local SKILL_ATTACK_RANGE = 10.0 
local MAGNET_RANGE = 8.0       

local totalHadiahDiperoleh = 0  

local combatConnection = nil
local noclipConnection = nil
local skillThread = nil
local m1Thread = nil 
local currentTargetPlayer = nil 
local manualSkipRequested = false 
local hasTeleportedToIsland = false 
local isHunting = false
local isEmergencyRetreating = false

local manualSkipList = {} 
local bountyBlacklist = {} 
local activeESP = {}
local isTargetInActiveFight = false 

local state = {
    manualSkipList = manualSkipList,
    manualSkipRequested = false,
    isHunting = false,
    currentTargetPlayer = nil,
    totalHadiah = 0,
    stopRequested = false,
    SaveConfig = saveConfig,
}

local UI = UIModule.Init(SafeUIParent, state)
local function updateHUDDisplay(player) if UI and UI.updateHUDDisplay then UI.updateHUDDisplay(player) end end

-- ESP SYSTEM
local function createPlayerESP(player)
    if player == LocalPlayer or not SafeUIParent then return end
    pcall(function()
        local guiName = "ESP_" .. player.Name
        local existingGui = SafeUIParent:FindFirstChild(guiName)
        if existingGui then existingGui:Destroy() end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = guiName
        billboardGui.AlwaysOnTop = true
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.Parent = SafeUIParent

        local textLabel = Instance.new("TextLabel", billboardGui)
        textLabel.Name = "InfoText"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0.2
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextSize = 14
        textLabel.Text = player.Name

        activeESP[player] = {Gui = billboardGui, Label = textLabel}

        local connection
        connection = RunService.RenderStepped:Connect(function()
            pcall(function()
                if not player or not player.Parent then
                    billboardGui:Destroy() activeESP[player] = nil connection:Disconnect() return
                end
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

                if char and root and myRoot then
                    billboardGui.Adornee = root
                    local distance = math.floor((myRoot.Position - root.Position).Magnitude)
                    if player == state.currentTargetPlayer then
                        textLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                        textLabel.Text = "[TARGET] " .. player.Name .. " [" .. distance .. " studs]"
                    else
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        textLabel.Text = player.Name .. " [" .. distance .. " studs]"
                    end
                else
                    billboardGui.Adornee = nil
                end
            end)
        end)
    end)
end

for _, p in pairs(Players:GetPlayers()) do createPlayerESP(p) end
Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(function(p)
    if activeESP[p] then pcall(function() activeESP[p].Gui:Destroy() end) activeESP[p] = nil end
end)

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    end)
end

local function disableNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function applyTargetHighlight(targetChar)
    pcall(function()
        if not targetChar then return end
        if not targetChar:FindFirstChild("TargetHighlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "TargetHighlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 0) 
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.4
            highlight.OutlineTransparency = 0
            highlight.Parent = targetChar
        end
    end)
end

local function removeTargetHighlight(targetChar)
    pcall(function()
        if targetChar and targetChar:FindFirstChild("TargetHighlight") then targetChar.TargetHighlight:Destroy() end
    end)
end

local function getOrCreatePlatform()
    local platform = Workspace:FindFirstChild("AntiWaterPlatform")
    if not platform then
        platform = Instance.new("Part")
        platform.Name = "AntiWaterPlatform"
        platform.Size = Vector3.new(10, 1, 10)
        platform.Transparency = 1
        platform.Anchored = true
        platform.CanCollide = true
        platform.Parent = Workspace
    end
    return platform
end

local function autoOnHakiAndInstinct()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        if not char:FindFirstChild("HasBuso") then
            if CommF then CommF:InvokeServer("Buso") end
        end
        if CommE then CommE:FireServer("Ken", true) end
    end)
end

local function activateRaceV3AndV4()
    pcall(function() 
        if CommE then 
            CommE:FireServer("ActivateAbility") 
            CommE:FireServer("ActivateAwakening") 
        end 
    end)
end

local function equipWeaponCategory(categoryName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not backpack or not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        local itemType = currentTool:FindFirstChild("ToolTip") and tostring(currentTool.ToolTip.Value) or tostring(currentTool.ToolTip) or ""
        if itemType:lower():find(categoryName:lower()) or currentTool.Name:lower():find(categoryName:lower()) then return currentTool end
    end

    for _, item in pairs(backpack:GetChildren()) do
        if item and item:IsA("Tool") then
            local itemType = item:FindFirstChild("ToolTip") and tostring(item.ToolTip.Value) or tostring(item.ToolTip) or ""
            if itemType:lower():find(categoryName:lower()) or item.Name:lower():find(categoryName:lower()) then
                local hum = char:WaitForChild("Humanoid", 2)
                if hum then hum:EquipTool(item) task.wait(0.05) return item end
            end
        end
    end
    return nil
end

local function isAlly(targetPlayer)
    if not targetPlayer then return true end
    if LocalPlayer.Team and targetPlayer.Team and LocalPlayer.Team == targetPlayer.Team then
        if LocalPlayer.Team.Name == "Marines" then return true end
    end
    local myCrew = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Crew")
    local targetCrew = targetPlayer:FindFirstChild("Data") and targetPlayer.Data:FindFirstChild("Crew")
    if myCrew and targetCrew and myCrew.Value ~= "" and myCrew.Value == targetCrew.Value then return true end
    return false
end

local function isBuddhaOrPortalUser(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local char = targetPlayer.Character
    if char:FindFirstChild("buddha") or char:FindFirstChild("Big") or char:FindFirstChild("Transformation") then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root.Size.Y > 5 then return true end

    local backpack = targetPlayer:FindFirstChild("Backpack")
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool and (equippedTool.Name:lower():find("portal") or equippedTool.Name:lower():find("buddha")) then return true end

    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item and (item.Name:lower():find("portal") or item.Name:lower():find("buddha")) then return true end
        end
    end
    return false
end

local function isPlayerEligibleForPvP(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent or not targetPlayer:IsA("Player") or targetPlayer == LocalPlayer then return false end
    
    if isTargetInActiveFight and targetPlayer == currentTargetPlayer then
        local char = targetPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if char and hum and hum.Health > 0 then return true end
    end

    local dataFolder = targetPlayer:FindFirstChild("Data")
    if manualSkipList[targetPlayer.Name] then return false end
    if bountyBlacklist[targetPlayer.Name] and os.time() < bountyBlacklist[targetPlayer.Name] then return false end
    
    if targetPlayer:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    if targetPlayer:FindFirstChild("PlayerStats") and targetPlayer.PlayerStats:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    
    local char = targetPlayer.Character
    if not char then return false end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root then return false end
    
    if char:FindFirstChild("DiedRecently") then 
        bountyBlacklist[targetPlayer.Name] = os.time() + 900
        return false 
    end
    if char:FindFirstChildOfClass("ForceField") then return false end
    
    if char:GetAttribute("SafeZone") or targetPlayer:GetAttribute("SafeZone") then return false end
    if char:FindFirstChild("SafeZone") then return false end
    local pvpDisabledAttr = char:GetAttribute("PvPDisabled") or targetPlayer:GetAttribute("PvPDisabled")
    if pvpDisabledAttr == true then return false end
    
    if targetPlayer:FindFirstChild("PvPDisabled") and targetPlayer.PvPDisabled.Value == true then return false end
    if dataFolder then
        local safeZoneVal = dataFolder:FindFirstChild("SafeZone")
        if safeZoneVal and safeZoneVal.Value == true then return false end
        local pvpVal = dataFolder:FindFirstChild("PvP") or dataFolder:FindFirstChild("PvPDisabled") or dataFolder:FindFirstChild("PvpDisabled")
        if pvpVal and (pvpVal.Value == false or (pvpVal.Value == true and pvpVal.Name:lower().find("disabled"))) then return false end
    end

    if isAlly(targetPlayer) or isBuddhaOrPortalUser(targetPlayer) then return false end
    
    local safeZones = { Vector3.new(-377.46, 73.08, 293.16) }
    for _, safePos in ipairs(safeZones) do
        if (root.Position - safePos).Magnitude < 350 then return false end
    end
    
    return true
end

local function startM1Loop(targetPlayer)
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    m1Thread = task.spawn(function()
        while isHunting and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tChar = targetPlayer and targetPlayer.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.MaxHealth > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                if currentHPPercent <= 80 and currentHPPercent >= 50 then
                    isTargetInActiveFight = true
                    equipWeaponCategory("Melee")
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    if dist <= M1_ATTACK_RANGE then
                        for comboKe = 1, 4 do
                            RegisterAttack:FireServer(JedaSenjataAsli, comboKe)
                            local partTarget = tRoot or tChar:FindFirstChild("UpperTorso")
                            if partTarget then
                                local argsHit = { [1] = partTarget, [2] = {}, [4] = TokenKeamanan }
                                RegisterHit:FireServer(unpack(argsHit))
                            end
                        end
                    end
                end
            end
            task.wait(0.01) 
        end
    end)
end

local function executeToolRemoteInstant(targetPosition, skillType, toolRemote)
    pcall(function()
        pcall(function() game:GetService("ReplicatedStorage").Remotes.GetSetting:InvokeServer("MobileSchemeMode") end)
        if MasterClockRemote then pcall(function() MasterClockRemote:InvokeServer() end) end

        local keyCodeMap = { ["Z"] = Enum.KeyCode.Z, ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C, ["V"] = Enum.KeyCode.V, ["F"] = Enum.KeyCode.F }
        local targetKey = keyCodeMap[skillType]

        if skillType == "X" then toolRemote:FireServer("X", false) else toolRemote:FireServer(skillType, targetPosition) end

        if targetKey and VirtualInputManager then
            task.spawn(function()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, targetKey, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, targetKey, false, game)
                end)
            end)
        end
    end)
end

local function startSkillLoop(targetPlayer)
    if skillThread then task.cancel(skillThread) skillThread = nil end
    skillThread = task.spawn(function()
        local weaponCategories = {"Melee", "Fruit", "Sword", "Gun"}
        local skillKeys = {"Z", "X", "C", "V", "F"}
        local noVFruits = {"tiger", "yeti", "mammoth", "trex", "t-rex", "kitsune", "dragon", "gas", "buddha", "phoenix", "venom"}

        while isHunting and currentTargetPlayer == targetPlayer and isPlayerEligibleForPvP(targetPlayer) do
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tChar = targetPlayer and targetPlayer.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

            if myRoot and tRoot and tHum and tHum.MaxHealth > 0 then
                local currentHPPercent = (tHum.Health / tHum.MaxHealth) * 100
                
                if (currentHPPercent > 80 and currentHPPercent <= 100) or (currentHPPercent < 50) then
                    isTargetInActiveFight = true
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    if dist <= SKILL_ATTACK_RANGE then 
                        autoOnHakiAndInstinct()
                        activateRaceV3AndV4()

                        for _, category in ipairs(weaponCategories) do
                            if not currentTargetPlayer or not isPlayerEligibleForPvP(currentTargetPlayer) then break end
                            local equippedTool = equipWeaponCategory(category)
                            if equippedTool then
                                local targetPos = tRoot.Position
                                local toolName = equippedTool.Name:lower()
                                local isTransformFruit = false
                                if category == "Fruit" then
                                    for _, fruitName in ipairs(noVFruits) do
                                        if toolName:find(fruitName) then isTransformFruit = true break end
                                    end
                                end
                                local toolRemote = equippedTool:FindFirstChild("RemoteEvent") or equippedTool:FindFirstChildOfClass("RemoteEvent")
                                if toolRemote then
                                    for _, key in ipairs(skillKeys) do
                                        local catConfig = _G.CombatConfig[category]
                                        local skillSubCfg = catConfig and catConfig[key]
                                        if skillSubCfg and skillSubCfg.On then
                                            if not (key == "V" and isTransformFruit) then
                                                executeToolRemoteInstant(targetPos, key, toolRemote)
                                                task.wait(0.08)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1) 
        end
    end)
end

local function handleEmergencyRetreat()
    if isEmergencyRetreating then return end
    isEmergencyRetreating = true
    enableNoclip()
    
    local escapeConnection
    escapeConnection = RunService.RenderStepped:Connect(function(deltaTime)
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not hum or not root or hum.Health <= 0 then return end
            if (hum.Health / hum.MaxHealth) * 100 >= 50 or not isHunting then
                if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
                return
            end
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            root.Velocity = Vector3.new(0, 0, 0)
            root.CFrame = root.CFrame + Vector3.new(0, _G.CustomFlightSpeed * deltaTime, 0)
        end)
    end)

    while escapeConnection and isHunting do task.wait(0.2) end
    isEmergencyRetreating = false
    disableNoclip()
end

local PortalPositions = {
    ["Kapal Terkutuk"] = Vector3.new(-6508.55810546875, 89.03500366210938, -132.83999633789062),
    ["Rumah Mewah"]    = Vector3.new(2284.9091796875, 15.537796020507812, 905.7056884765625)
}

local function handleSmartPortalBypass(targetRoot)
    if not currentTargetPlayer or not currentTargetPlayer.Parent then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot or not targetRoot.Parent or hasTeleportedToIsland then return end

    local targetPos = targetRoot.Position
    local myPos = myRoot.Position

    if targetPos.Z > 20000 and myPos.Z < 20000 then
        hasTeleportedToIsland = true
        pcall(function() CommF:InvokeServer("requestEntrance", PortalPositions["Kapal Terkutuk"]) end)
        task.wait(2)
        return
    elseif targetPos.Z < 20000 and myPos.Z > 20000 then
        hasTeleportedToIsland = true
        pcall(function() CommF:InvokeServer("requestEntrance", PortalPositions["Kapal Terkutuk"]) end)
        task.wait(2)
        return
    end

    local distanceDirect = (myRoot.Position - targetPos).Magnitude
    if distanceDirect > 3000 then
        local portalSwanTarget = Vector3.new(2284.9, 15.5, 905.7)
        local distViaPortal = (targetPos - portalSwanTarget).Magnitude
        if distViaPortal < distanceDirect - 1000 then 
            hasTeleportedToIsland = true
            pcall(function() CommF:InvokeServer("requestEntrance", PortalPositions["Rumah Mewah"]) end)
            task.wait(2)
        end
    end
end

local function flyTowardsTarget(targetRoot)
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    enableNoclip()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:WaitForChild("Humanoid", 5)
    if not myRoot or not myHumanoid then return end

    myHumanoid.AutoRotate = false
    combatConnection = RunService.RenderStepped:Connect(function(deltaTime)
        pcall(function()
            if not isPlayerEligibleForPvP(currentTargetPlayer) or manualSkipRequested or isEmergencyRetreating then
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end 
                return
            end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")

            if root and humanoid and humanoid.Health > 0 and targetRoot and targetRoot.Parent then
                if root.Anchored then root.Anchored = false end
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                root.Velocity = Vector3.new(0, 0, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                local targetPos = targetRoot.Position
                local currentPos = root.Position
                local distance = (targetPos - currentPos).Magnitude
                
                local camera = workspace.CurrentCamera
                if camera then
                    local camPos = camera.CFrame.Position
                    camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camPos, targetPos), 0.75)
                end

                local straightLockCFrame = targetRoot.CFrame * CFrame.new(0, 0, MAGNET_RANGE)
                local targetGoalPos = straightLockCFrame.Position
                local safeDelta = math.clamp(deltaTime, 0.01, 0.033)

                if distance > MAGNET_RANGE then
                    local direction = (targetGoalPos - currentPos)
                    local maxStep = math.min(_G.CustomFlightSpeed * safeDelta, direction.Magnitude)
                    local hoverPos = currentPos + (direction.Unit * maxStep)
                    root.CFrame = CFrame.new(hoverPos) * CFrame.lookAt(hoverPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)).Rotation
                else
                    root.CFrame = CFrame.new(targetGoalPos) * CFrame.lookAt(targetGoalPos, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)).Rotation
                end

                getOrCreatePlatform().CFrame = CFrame.new(root.Position - Vector3.new(0, 4.2, 0))
            else
                if combatConnection then combatConnection:Disconnect() combatConnection = nil end
            end
        end)
    end)
end

local function stopAllThreads()
    if combatConnection then combatConnection:Disconnect() combatConnection = nil end
    if skillThread then task.cancel(skillThread) skillThread = nil end
    if m1Thread then task.cancel(m1Thread) m1Thread = nil end
    disableNoclip()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
    if myHumanoid then myHumanoid.AutoRotate = true end 
    if currentTargetPlayer and currentTargetPlayer.Character then removeTargetHighlight(currentTargetPlayer.Character) end
    currentTargetPlayer = nil 
    isTargetInActiveFight = false 
    pcall(function() if workspace:FindFirstChild("AntiWaterPlatform") then workspace.AntiWaterPlatform:Destroy() end end)
end

local function startHuntingLoop()
    if isHunting then return end
    isHunting = true
    task.spawn(function()
        while isHunting do
            task.wait(0.2)
            if not _G.AutoHuntEnabled then
                stopAllThreads()
                isHunting = false
                break
            end

            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChild("Humanoid")

            if char and humanoid and humanoid.Health > 0 then
                if (humanoid.Health / humanoid.MaxHealth) * 100 <= 20 then
                    stopAllThreads()
                    handleEmergencyRetreat()
                end

                autoOnHakiAndInstinct()
                
                if not currentTargetPlayer then
                    for _, player in pairs(Players:GetPlayers()) do
                        if isPlayerEligibleForPvP(player) then
                            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                            if targetRoot and targetHumanoid then
                                currentTargetPlayer = player
                                manualSkipRequested = false
                                hasTeleportedToIsland = false
                                isTargetInActiveFight = false
                                updateHUDDisplay(player)
                                applyTargetHighlight(player.Character)
                                break
                            end
                        end
                    end
                end
                
                if currentTargetPlayer and currentTargetPlayer.Parent then
                    local targetChar = currentTargetPlayer.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                    
                    if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                        if not hasTeleportedToIsland then
                            handleSmartPortalBypass(targetRoot)
                        end
                        
                        flyTowardsTarget(targetRoot)
                        startM1Loop(currentTargetPlayer)
                        startSkillLoop(currentTargetPlayer)
                        
                        local statsAwal = LocalPlayer:FindFirstChild("leaderstats")
                        local valBountyAwal = statsAwal and (statsAwal:FindFirstChild("Bounty/Honor") or statsAwal:FindFirstChild("Bounty"))
                        local bountySebelumKill = valBountyAwal and valBountyAwal.Value or 0

                        while isHunting and currentTargetPlayer and currentTargetPlayer.Parent do
                            if manualSkipRequested or not _G.AutoHuntEnabled then break end
                            targetChar = currentTargetPlayer.Character
                            targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                            if not targetHumanoid or targetHumanoid.Health <= 0 or humanoid.Health <= 0 then break end
                            task.wait(0.2)
                        end
                        
                        if currentTargetPlayer and not manualSkipRequested then
                            targetChar = currentTargetPlayer.Character
                            targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                            if targetHumanoid and targetHumanoid.Health <= 0 then
                                bountyBlacklist[currentTargetPlayer.Name] = os.time() + 900
                                task.wait(1.0)
                                local statsAkhir = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Data")
                                local valBountyAkhir = statsAkhir and (statsAkhir:FindFirstChild("Bounty/Honor") or statsAkhir:FindFirstChild("Bounty") or statsAkhir:FindFirstChild("Honor"))
                                local bountySesudahKill = valBountyAkhir and valBountyAkhir.Value or bountySebelumKill
                                local selisih = bountySesudahKill - bountySebelumKill
                                if selisih > 0 then
                                    totalHadiahDiperoleh = totalHadiahDiperoleh + selisih
                                    if UI and UI.addTargetLogEntry then UI.addTargetLogEntry("Kill") end
                                end
                            end
                        end
                        
                        stopAllThreads()
                        updateHUDDisplay(nil)
                        currentTargetPlayer = nil
                        manualSkipRequested = false
                        hasTeleportedToIsland = false
                        task.wait(0.5)
                    else
                        currentTargetPlayer = nil
                        hasTeleportedToIsland = false
                    end
                else
                    currentTargetPlayer = nil
                    hasTeleportedToIsland = false
                end
            end
        end
    end)
end

state.OnToggleHunt = function(newValue)
    _G.AutoHuntEnabled = newValue
    if newValue then startHuntingLoop() else stopAllThreads() isHunting = false end
end

task.spawn(function()
    while true do
        state.currentTargetPlayer = currentTargetPlayer
        state.isHunting = isHunting
        state.totalHadiah = totalHadiahDiperoleh
        if state.manualSkipRequested then manualSkipRequested = true state.manualSkipRequested = false end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while not state.stopRequested do task.wait(0.3) end
    _G.AutoHuntEnabled = false stopAllThreads() isHunting = false
end)

if _G.AutoHuntEnabled then startHuntingLoop() end

LocalPlayer.CharacterRemoving:Connect(function() isHunting = false stopAllThreads() end)
LocalPlayer.CharacterAdded:Connect(function(newChar)
    stopAllThreads() newChar:WaitForChild("HumanoidRootPart", 10)
    local hum = newChar:WaitForChild("Humanoid", 10) if hum then hum.AutoRotate = true end
    task.wait(1.0) autoOnHakiAndInstinct() isHunting = false
    if _G.AutoHuntEnabled then startHuntingLoop() end
end)

print("[Bounty Hunter] Skrip SEA 2 + UI Dashboard Berhasil Dijalankan!")