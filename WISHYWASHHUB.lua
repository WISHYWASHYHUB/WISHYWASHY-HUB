local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Unload any previous copy if re-executed
pcall(function()
    if getgenv and getgenv().WishyWashyUnload then
        getgenv().WishyWashyUnload()
    end
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local cast = Remotes:WaitForChild("Cast")
local train = Remotes:WaitForChild("Train")
local bossRemote = Remotes:WaitForChild("Boss")
local enemies = workspace:WaitForChild("MyEnemies")

local scriptActive = true
local connections = {}
local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

local Config = {
    AutoCombat = false,
    AutoAbilityE = false,
    AutoAbilityR = false,
    AutoBoss = false,
    AutoPops = false,
    AutoTrainArea = false,
    AutoClaim = false,
    AutoStages = false,
    AntiAfk = false,
    NoClip = false,
    AutoLoadConfig = false,
    TargetMap = "Map5",
    TargetTraining = "Training13",
    StageMap = "Map5",
    HoverHeight = 15,
}

local CONFIG_FILE_NAME = "WishyWashyHub_Config.json"

local function saveConfig()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if success and writefile then
        pcall(function()
            writefile(CONFIG_FILE_NAME, encoded)
        end)
        print("[WishyWashy Hub] Configuration successfully saved.")
    else
        warn("[WishyWashy Hub] Failed to save configuration.")
    end
end

local function loadConfig(isAuto)
    if readfile and isfile and isfile(CONFIG_FILE_NAME) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
        end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then
                    Config[k] = v
                end
            end
            if not isAuto then
                print("[WishyWashy Hub] Configuration successfully loaded.")
            end
        end
    end
end

pcall(function()
    if readfile and isfile and isfile(CONFIG_FILE_NAME) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE_NAME))
        end)
        if success and decoded.AutoLoadConfig then
            loadConfig(true)
            print("[WishyWashy Hub] Auto-loaded configuration on startup.")
        end
    end
end)

local currentPosition = nil
local inBossArena = false
local bossWasPresent = false

----------------------------------------------------------------------
-- PROFESSIONAL UI LIBRARY STYLING
----------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WishyWashyProfessionalHub"
ScreenGui.ResetOnSpawn = false
do
    local guiParent = (typeof(gethui) == "function" and gethui()) or CoreGui
    local ok = pcall(function() ScreenGui.Parent = guiParent end)
    if not ok or not ScreenGui.Parent then
        ScreenGui.Parent = playerGui
    end
end

-- Main Window Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 400)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(50, 50, 65)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Topbar Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 10)
TopBarCorner.Parent = TopBar

local TopBarCover = Instance.new("Frame")
TopBarCover.Size = UDim2.new(1, 0, 0, 10)
TopBarCover.Position = UDim2.new(0, 0, 1, -10)
TopBarCover.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
TopBarCover.BorderSizePixel = 0
TopBarCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "WISHYWASHY HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Unload / Close Button
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0, 28, 0, 28)
UnloadBtn.Position = UDim2.new(1, -37, 0.5, -14)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
UnloadBtn.Text = "×"
UnloadBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
UnloadBtn.TextSize = 18
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.Parent = TopBar

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 6)
UnloadCorner.Parent = UnloadBtn

local function unload()
    scriptActive = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    ScreenGui:Destroy()
end

pcall(function()
    if getgenv then getgenv().WishyWashyUnload = unload end
end)

track(UnloadBtn.MouseButton1Click:Connect(unload))

-- Sidebar Navigation Tabs Container
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 130, 1, -55)
Sidebar.Position = UDim2.new(0, 8, 0, 50)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.ScrollBarThickness = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 5)
SidebarLayout.Parent = Sidebar

-- Content Pages Container
local ContainerHolder = Instance.new("Frame")
ContainerHolder.Size = UDim2.new(1, -150, 1, -55)
ContainerHolder.Position = UDim2.new(0, 142, 0, 50)
ContainerHolder.BackgroundTransparency = 1
ContainerHolder.Parent = MainFrame

-- Tab Management
local tabs = {}
local activeTab = nil

local function createTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
    page.Visible = false
    page.Parent = ContainerHolder

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingRight = UDim.new(0, 8)
    pagePadding.Parent = page

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
    end)

    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(150, 150, 170)
    tabBtn.TextSize = 13
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = Sidebar

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 12)
    tabPadding.Parent = tabBtn

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.page.Visible = false
            TweenService:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 38), TextColor3 = Color3.fromRGB(150, 150, 170)}):Play()
        end
        page.Visible = true
        TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(52, 100, 235), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    if not activeTab then
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(52, 100, 235)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        activeTab = name
    end

    tabs[name] = {btn = tabBtn, page = page}
    return page
end

-- Create Tabs requested
local mainTab = createTab("Main")
local combatTab = createTab("Combat")
local trainingTab = createTab("Training")
local stagesBossTab = createTab("Stages & Boss")
local miscTab = createTab("Misc & Config")

-- UI Component Builders
local function createToggle(page, name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = ""
    btn.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(210, 210, 225)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(1, -26, 0.5, -9)
    indicator.BackgroundColor3 = default and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(45, 45, 58)
    indicator.Parent = btn

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 4)
    indCorner.Parent = indicator

    local state = default
    track(btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(45, 45, 58)
        }):Play()
        callback(state)
    end))
end

local function createButton(page, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    track(btn.MouseButton1Click:Connect(function()
        callback(btn)
    end))
    return btn
end

local function createTextBox(page, placeholder, defaultText, callback)
    local boxContainer = Instance.new("Frame")
    boxContainer.Size = UDim2.new(1, 0, 0, 34)
    boxContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    boxContainer.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = boxContainer

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 110, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = placeholder
    label.TextColor3 = Color3.fromRGB(160, 160, 180)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = boxContainer

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -125, 1, -6)
    box.Position = UDim2.new(0, 120, 0, 3)
    box.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = tostring(defaultText)
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.Parent = boxContainer

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = box

    track(box.FocusLost:Connect(function()
        callback(box.Text)
    end))
end

local function createSlider(page, name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    container.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(210, 210, 225)
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -24, 0, 6)
    sliderBar.Position = UDim2.new(0, 12, 0, 32)
    sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    sliderBar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = sliderBar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(52, 100, 235)
    fill.Parent = sliderBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local dragging = false
    local function updateInput(input)
        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + ((max - min) * pos))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = name .. ": " .. tostring(val)
        callback(val)
    end

    track(sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateInput(input)
        end
    end))

    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateInput(input)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- Populate Main Tab
createToggle(mainTab, "Auto Claim Rewards", Config.AutoClaim, function(s) Config.AutoClaim = s end)
createButton(mainTab, "Join My Discord", function(btn)
    local inviteLink = "https://discord.gg/vS63Jvh5z6"
    if setclipboard then
        setclipboard(inviteLink)
    end
    btn.Text = "Copied to Clipboard!"
    task.delay(2, function()
        if btn and btn.Parent then
            btn.Text = "Join My Discord"
        end
    end)
end)

-- Populate Combat Tab
createToggle(combatTab, "Auto Cast & Train", Config.AutoCombat, function(s) Config.AutoCombat = s end)
createToggle(combatTab, "Auto Ability (E)", Config.AutoAbilityE, function(s) Config.AutoAbilityE = s end)
createToggle(combatTab, "Auto Ability (R)", Config.AutoAbilityR, function(s) Config.AutoAbilityR = s end)

-- Populate Training Tab
createToggle(trainingTab, "Auto Training Area", Config.AutoTrainArea, function(s) Config.AutoTrainArea = s end)
createToggle(trainingTab, "Auto Click Pops", Config.AutoPops, function(s) Config.AutoPops = s end)
createTextBox(trainingTab, "Target Map", Config.TargetMap, function(t) Config.TargetMap = t end)
createTextBox(trainingTab, "Target Training", Config.TargetTraining, function(t) Config.TargetTraining = t end)

-- Populate Stages & Boss Tab
createToggle(stagesBossTab, "Auto Farm Stages", Config.AutoStages, function(s) Config.AutoStages = s end)
createTextBox(stagesBossTab, "Stage Map", Config.StageMap, function(t) Config.StageMap = t end)
createToggle(stagesBossTab, "Auto Boss Event", Config.AutoBoss, function(s) Config.AutoBoss = s end)
createSlider(stagesBossTab, "Boss Hover Height", -50, 50, Config.HoverHeight, function(v) Config.HoverHeight = v end)

-- Populate Misc & Config Tab
createToggle(miscTab, "Anti-AFK", Config.AntiAfk, function(s) Config.AntiAfk = s end)
createToggle(miscTab, "No-Clip", Config.NoClip, function(s) Config.NoClip = s end)
createToggle(miscTab, "Auto-Load Config", Config.AutoLoadConfig, function(s) Config.AutoLoadConfig = s end)
createButton(miscTab, "Save Config", function() saveConfig() end)
createButton(miscTab, "Load Config", function() loadConfig(false) end)


----------------------------------------------------------------------
-- LOOP HELPER
----------------------------------------------------------------------
local IDLE_WAIT = 0.5

local function loop(interval, fn, isActive)
    task.spawn(function()
        while scriptActive do
            if not isActive or isActive() then
                pcall(fn)
                task.wait(interval)
            else
                task.wait(IDLE_WAIT)
            end
        end
    end)
end

----------------------------------------------------------------------
-- CACHED LOOKUPS
----------------------------------------------------------------------
local function getKuramaLabel()
    local main = playerGui:FindFirstChild("Main")
    local hud = main and main:FindFirstChild("HUD")
    local top = hud and hud:FindFirstChild("Top")
    local kuramaBar = top and top:FindFirstChild("KuramaBar")
    local back = kuramaBar and kuramaBar:FindFirstChild("Back")
    return back and back:FindFirstChild("Name")
end

local cachedPopsFolder
local function getPopsFolder()
    if cachedPopsFolder and cachedPopsFolder.Parent then
        return cachedPopsFolder
    end
    local main = playerGui:FindFirstChild("Main")
    local hud = main and main:FindFirstChild("HUD")
    cachedPopsFolder = hud and hud:FindFirstChild("Pops")
    return cachedPopsFolder
end

local cachedBoss, cachedBossPart
local function getBossPart()
    local boss = workspace:FindFirstChild("Kurama")
    if not boss then
        cachedBoss, cachedBossPart = nil, nil
        return nil
    end
    if boss ~= cachedBoss or not cachedBossPart or not cachedBossPart.Parent then
        cachedBoss = boss
        cachedBossPart = boss:FindFirstChild("HumanoidRootPart", true)
            or boss:FindFirstChildWhichIsA("BasePart", true)
    end
    return cachedBossPart
end

local trainCache = { key = nil, spot = nil, cf = nil, radius = 0, heightLimit = 0 }
local TRAIN_PADDING = 35

local function getTrainingInfo()
    local key = Config.TargetMap .. "/" .. Config.TargetTraining
    if trainCache.key ~= key or not trainCache.spot or not trainCache.spot.Parent then
        trainCache.key = key
        trainCache.spot, trainCache.cf = nil, nil

        local mapFolder = workspace:FindFirstChild(Config.TargetMap)
        if mapFolder then
            local hub = mapFolder:FindFirstChild("Hub") or mapFolder
            local spot = hub:FindFirstChild(Config.TargetTraining)
            if spot then
                trainCache.spot = spot
                local cf, size
                if spot:IsA("BasePart") then
                    cf, size = spot.CFrame, spot.Size
                elseif spot:IsA("Model") then
                    local ok, bcf, bsize = pcall(function() return spot:GetBoundingBox() end)
                    if ok then cf, size = bcf, bsize end
                end
                if not cf then
                    local part = spot:FindFirstChildWhichIsA("BasePart", true)
                    if part then cf, size = part.CFrame, part.Size end
                end
                if cf then
                    trainCache.cf = cf
                    trainCache.radius = math.max(size.X, size.Z) / 2 + TRAIN_PADDING
                    trainCache.heightLimit = size.Y / 2 + 60
                end
            end
        end
    end
    return trainCache
end

local function teleportToTraining(root)
    local spot = getTrainingInfo().spot
    if not spot then return false end

    if spot:IsA("BasePart") then
        root.CFrame = spot.CFrame + Vector3.new(0, 3, 0)
    elseif spot:IsA("Model") and spot.PrimaryPart then
        root.CFrame = spot.PrimaryPart.CFrame + Vector3.new(0, 3, 0)
    else
        local part = spot:FindFirstChildWhichIsA("BasePart", true)
        if not part then return false end
        root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end
    return true
end

local function isInTrainingArea(root)
    local info = getTrainingInfo()
    if not info.cf then return true end

    local offset = root.Position - info.cf.Position
    if offset.X * offset.X + offset.Z * offset.Z > info.radius * info.radius then
        return false
    end
    return math.abs(offset.Y) <= info.heightLimit
end

local function leaveAndTeleport()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end

    bossRemote:FireServer("leave")
    task.wait(0.5)

    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    teleportToTraining(root)
end

----------------------------------------------------------------------
-- ANTI-AFK
----------------------------------------------------------------------
track(player.Idled:Connect(function()
    if not scriptActive or not Config.AntiAfk then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end))

----------------------------------------------------------------------
-- NO-CLIP
----------------------------------------------------------------------
local noclipParts = {}

local function trackCharacter(character)
    noclipParts = {}
    for _, d in ipairs(character:GetDescendants()) do
        if d:IsA("BasePart") then noclipParts[d] = true end
    end
    track(character.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then noclipParts[d] = true end
    end))
    track(character.DescendantRemoving:Connect(function(d)
        noclipParts[d] = nil
    end))
end

if player.Character then trackCharacter(player.Character) end
track(player.CharacterAdded:Connect(trackCharacter))

track(RunService.Stepped:Connect(function()
    if not Config.NoClip then return end
    for part in pairs(noclipParts) do
        if part.CanCollide then
            part.CanCollide = false
        end
    end
end))

----------------------------------------------------------------------
-- ENEMY CACHE & TARGET DETECTION
----------------------------------------------------------------------
local enemyParts = {}

for _, e in ipairs(enemies:GetChildren()) do
    enemyParts[e] = false
end
track(enemies.ChildAdded:Connect(function(e) enemyParts[e] = false end))
track(enemies.ChildRemoved:Connect(function(e) enemyParts[e] = nil end))

local function resolveEnemyPart(enemy)
    return enemy:FindFirstChild("HumanoidRootPart", true)
        or enemy:FindFirstChildWhichIsA("BasePart", true)
end

loop(0.15, function()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local rootPos = root.Position
    local closestPosition

    if Config.AutoBoss and inBossArena then
        local bossPart = getBossPart()
        if bossPart then
            closestPosition = bossPart.Position
        end
    end

    if not closestPosition then
        local shortest = math.huge
        for enemy, part in pairs(enemyParts) do
            if not part or not part.Parent then
                part = resolveEnemyPart(enemy) or false
                enemyParts[enemy] = part
            end
            if part then
                local d = rootPos - part.Position
                local distSq = d:Dot(d)
                if distSq < shortest then
                    shortest = distSq
                    closestPosition = part.Position
                end
            end
        end
    end

    currentPosition = closestPosition
end, function()
    return Config.AutoCombat or Config.AutoAbilityE or Config.AutoAbilityR
        or (Config.AutoBoss and inBossArena)
end)

----------------------------------------------------------------------
-- BOSS MONITOR & LOCK-ON
----------------------------------------------------------------------
local hasFired = false

loop(0.2, function()
    if Config.AutoBoss then
        local label = getKuramaLabel()
        if label and label:IsA("TextLabel") and label.Visible then
            local text = label.Text
            if text:upper():find("KYUBI IS HERE") then
                inBossArena = true
            else
                local minutes, seconds = text:match("IN (%d+):(%d+)")
                if minutes and seconds then
                    local totalSeconds = (tonumber(minutes) or 0) * 60 + (tonumber(seconds) or 0)
                    if totalSeconds <= 25 then
                        inBossArena = true
                        if not hasFired then
                            bossRemote:FireServer("join")
                            hasFired = true
                        end
                    end
                end
            end
        end

        if inBossArena then
            if workspace:FindFirstChild("Kurama") then
                bossWasPresent = true
            elseif bossWasPresent then
                leaveAndTeleport()
                inBossArena = false
                bossWasPresent = false
                hasFired = false
            end
        end
    elseif inBossArena then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        inBossArena = false
        bossWasPresent = false
        hasFired = false
    end
end, function()
    return Config.AutoBoss or inBossArena
end)

track(RunService.Heartbeat:Connect(function()
    if not (Config.AutoBoss and inBossArena) then return end

    local bossPart = getBossPart()
    if not bossPart then return end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if root and humanoid then
        humanoid.PlatformStand = true
        root.CFrame = CFrame.new(bossPart.Position + Vector3.new(0, Config.HoverHeight, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end))

----------------------------------------------------------------------
-- AUTO TRAINING AREA
----------------------------------------------------------------------
local lastTrainTeleport = 0

loop(1, function()
    if Config.AutoStages then return end
    if inBossArena or bossWasPresent then return end
    if tick() - lastTrainTeleport < 2 then return end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end

    if not isInTrainingArea(root) then
        lastTrainTeleport = tick()
        teleportToTraining(root)
    end
end, function()
    return Config.AutoTrainArea
end)

----------------------------------------------------------------------
-- AUTO FARM STAGES
----------------------------------------------------------------------
local STAGE_COUNT = 15
local STAGE_ENEMY_WAIT = 8
local STAGE_CLEAR_CONFIRM = 1.5
local STAGE_TIMEOUT = 180
local SPAWN_WAIT_TIMEOUT = 10
local STAGE_TP_HEIGHT = 5
local STAGE_ANCHOR_NAMES = { "Spawn", "SpawnLocation", "Start", "StartPoint", "Entrance" }

local stageState = { stage = 1, needTeleport = true, enteredAt = 0, sawEnemy = false, clearSince = nil }
local stageWasOn = false
local lastStageWarn = 0

local function stageWarn(msg)
    if tick() - lastStageWarn > 5 then
        lastStageWarn = tick()
        warn("[AutoStages] " .. msg)
    end
end

local function resetStageFarm()
    stageState.stage = 1
    stageState.needTeleport = true
    stageState.sawEnemy = false
    stageState.clearSince = nil
end

local function getStagesFolder()
    local map = workspace:FindFirstChild(Config.StageMap)
    return map and map:FindFirstChild("Stages")
end

local function getStageCFrame(stage)
    if stage:IsA("BasePart") then
        return stage.CFrame
    end
    for _, name in ipairs(STAGE_ANCHOR_NAMES) do
        local p = stage:FindFirstChild(name, true)
        if p and p:IsA("BasePart") then
            return p.CFrame
        end
    end
    if stage:IsA("Model") then
        local ok, cf = pcall(function() return (stage:GetBoundingBox()) end)
        if ok and cf then return cf end
    end
    local sum, n = Vector3.zero, 0
    for _, d in ipairs(stage:GetDescendants()) do
        if d:IsA("BasePart") then
            sum += d.Position
            n += 1
        end
    end
    if n > 0 then return CFrame.new(sum / n) end
    return nil
end

local function teleportToStage(root, stage)
    local ground = stage:FindFirstChild("Ground")
    local base = ground and ground:FindFirstChild("Base")
    local dest

    if base and base:IsA("BasePart") then
        dest = base.CFrame * CFrame.new(0, base.Size.Y / 2 + 3, 0)
    else
        stageWarn(stage.Name .. ".Ground.Base not found, using fallback position")
        local cf = getStageCFrame(base or stage)
        if not cf then return false end
        dest = cf + Vector3.new(0, STAGE_TP_HEIGHT, 0)
    end

    root.CFrame = dest
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function finishRun(stagesFolder)
    local stageObj = stagesFolder:FindFirstChild("Stage" .. STAGE_COUNT)
    local padPurple = stageObj and (stageObj:FindFirstChild("PadPurple") or stageObj:FindFirstChild("PadPurple", true))
    local pad = padPurple and (padPurple:FindFirstChild("Pad") or padPurple:FindFirstChild("Pad", true))
    
    local targetPad = pad or padPurple
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if targetPad and targetPad:IsA("BasePart") and root then
        print("[AutoStages] Stage" .. STAGE_COUNT .. " cleared, going to PadPurple.Pad")
        root.CFrame = targetPad.CFrame + Vector3.new(0, 3, 0)

        if typeof(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(root, targetPad, 0)
                task.wait(0.1)
                firetouchinterest(root, targetPad, 1)
            end)
        end

        local t0 = tick()
        while scriptActive and Config.AutoStages and tick() - t0 < SPAWN_WAIT_TIMEOUT do
            task.wait(0.25)
            local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position - targetPad.Position).Magnitude > 60 then
                break
            end
        end
        task.wait(1)
    else
        stageWarn("Stage" .. STAGE_COUNT .. ".PadPurple.Pad not found, restarting from Stage1")
        task.wait(2)
    end

    resetStageFarm()
end

local function advanceStage(stagesFolder)
    if stageState.stage >= STAGE_COUNT then
        finishRun(stagesFolder)
    else
        stageState.stage += 1
        stageState.needTeleport = true
    end
end

loop(0.25, function()
    if inBossArena or bossWasPresent then
        stageState.needTeleport = true
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        stageState.needTeleport = true
        return
    end

    local stagesFolder = getStagesFolder()
    if not stagesFolder then
        stageWarn("Workspace." .. Config.StageMap .. ".Stages not found")
        return
    end

    if stageState.needTeleport then
        local stageObj = stagesFolder:FindFirstChild("Stage" .. stageState.stage)
        if not stageObj then
            stageWarn("Stage" .. stageState.stage .. " not found, skipping")
            advanceStage(stagesFolder)
            return
        end

        if teleportToStage(root, stageObj) then
            print("[AutoStages] Entered Stage" .. stageState.stage)
            stageState.needTeleport = false
            stageState.enteredAt = tick()
            stageState.sawEnemy = false
            stageState.clearSince = nil
        else
            stageWarn("No part found to teleport to in Stage" .. stageState.stage .. ", skipping")
            advanceStage(stagesFolder)
        end
        return
    end

    local now = tick()
    if next(enemyParts) ~= nil then
        stageState.sawEnemy = true
        stageState.clearSince = nil
    elseif stageState.sawEnemy then
        stageState.clearSince = stageState.clearSince or now
        if now - stageState.clearSince >= STAGE_CLEAR_CONFIRM then
            print("[AutoStages] Stage" .. stageState.stage .. " cleared")
            advanceStage(stagesFolder)
            return
        end
    elseif now - stageState.enteredAt >= STAGE_ENEMY_WAIT then
        stageWarn("No enemies spawned in Stage" .. stageState.stage .. ", moving on")
        advanceStage(stagesFolder)
        return
    end

    if now - stageState.enteredAt > STAGE_TIMEOUT then
        stageWarn("Stage" .. stageState.stage .. " timed out, moving on")
        advanceStage(stagesFolder)
    end
end, function()
    if Config.AutoStages then
        if not stageWasOn then
            stageWasOn = true
            resetStageFarm()
        end
        return true
    end
    stageWasOn = false
    return false
end)

----------------------------------------------------------------------
-- AUTO CLAIM REWARDS
----------------------------------------------------------------------
local CLAIM_INTERVAL = 300
local REWARD_COUNT = 3
local MAX_CLAIMS_PER_REWARD = 10
local CLAIM_CLICK_DELAY = 3.5
local lastClaim = 0

local function clickScreenCenter()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2

    pcall(function() VirtualInputManager:SendMouseMoveEvent(center.X, center.Y, game) end)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    task.wait(0.03)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
end

loop(1, function()
    if tick() - lastClaim < CLAIM_INTERVAL then return end

    local remote = Remotes:FindFirstChild("ClaimReward")
    if not remote then
        warn("[AutoClaim] Remotes.ClaimReward not found.")
        lastClaim = tick() - CLAIM_INTERVAL + 10
        return
    end

    lastClaim = tick()
    print("[AutoClaim] Claiming rewards via", remote.ClassName)

    task.spawn(function()
        for i = 1, REWARD_COUNT do
            if not scriptActive then return end

            local claimed = 0
            for _ = 1, MAX_CLAIMS_PER_REWARD do
                if not scriptActive then return end
                local ok, res = pcall(function() return remote:InvokeServer(i) end)
                if ok and res == true then
                    claimed += 1
                    task.wait(0.3)
                else
                    break
                end
            end
            print("[AutoClaim] reward", i, "claimed", claimed, "time(s)")

            if claimed > 0 then
                task.wait(CLAIM_CLICK_DELAY)
                if not scriptActive then return end
                pcall(clickScreenCenter)
            end
            task.wait(0.5)
        end
    end)
end, function()
    return Config.AutoClaim
end)

----------------------------------------------------------------------
-- AUTO CLICK POPS
----------------------------------------------------------------------
local signalNames = { "MouseButton1Down", "MouseButton1Click", "MouseButton1Up", "Activated" }
local hasFiresignal = typeof(firesignal) == "function"
local hasGetConnections = typeof(getconnections) == "function"

local function fireSignals(obj)
    local buttons = {}
    if obj:IsA("GuiButton") then buttons[#buttons + 1] = obj end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("GuiButton") then buttons[#buttons + 1] = d end
    end

    for _, btn in ipairs(buttons) do
        for _, sig in ipairs(signalNames) do
            if hasFiresignal then
                pcall(function() firesignal(btn[sig]) end)
            elseif hasGetConnections then
                pcall(function()
                    for _, c in ipairs(getconnections(btn[sig])) do
                        c:Fire()
                    end
                end)
            end
        end
    end
end

local function mouseClick(obj)
    local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
    local inset = Vector2.new(0, 0)
    if not (sg and sg.IgnoreGuiInset) then
        inset = GuiService:GetGuiInset()
    end
    local center = obj.AbsolutePosition + (obj.AbsoluteSize / 2) + inset

    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    task.wait(0.03)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
end

local popState = {}

loop(0.25, function()
    local folder = getPopsFolder()
    if not folder then return end

    local seen = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("GuiObject") and child.Name:match("^Bubble%d+") then
            seen[child] = true
            local state = popState[child]
            if not state then
                state = { tries = 0, lastTry = 0, busy = false }
                popState[child] = state
            end

            if not state.busy and state.tries < 10 and (tick() - state.lastTry > 1.5) then
                state.busy = true
                state.tries += 1
                state.lastTry = tick()

                task.spawn(function()
                    pcall(fireSignals, child)
                    task.wait(0.15)
                    if child.Parent then
                        pcall(mouseClick, child)
                    end
                    state.busy = false
                end)
            end
        end
    end

    for inst in pairs(popState) do
        if not seen[inst] then
            popState[inst] = nil
        end
    end
end, function()
    return Config.AutoPops
end)

----------------------------------------------------------------------
-- MAIN COMBAT, ABILITY & TRAINING
----------------------------------------------------------------------
local lastTimeE = 0
local lastTimeR = 0

local function abilityVector(pos)
    if typeof(vector) == "table" and vector.create then
        return vector.create(pos.X, pos.Y, pos.Z)
    end
    return pos
end

loop(0.1, function()
    local now = tick()

    if currentPosition then
        if Config.AutoCombat then
            cast:FireServer("attack", currentPosition)
        end

        if Config.AutoAbilityE and (now - lastTimeE > 1.5) then
            lastTimeE = now
            pcall(function() cast:FireServer("E", abilityVector(currentPosition)) end)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end

        if Config.AutoAbilityR and (now - lastTimeR > 1.5) then
            lastTimeR = now
            pcall(function() cast:FireServer("R", abilityVector(currentPosition)) end)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end
    end

    if Config.AutoCombat then
        train:FireServer()
    end
end, function()
    return Config.AutoCombat or Config.AutoAbilityE or Config.AutoAbilityR
end)
