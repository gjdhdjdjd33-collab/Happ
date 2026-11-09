--[[
    AURORA HUB v7
    Mobile-first UI | Black + Violet | Roblox Luau
    Targeting is intentionally restricted to NPC models/dummies in Workspace.
    Use only in experiences you own or are authorized to test.

    Features:
      - Animated mobile GUI, draggable header, minimize/close
      - Aim tab: NPC-only target selection, FOV, smoothness, visibility, range,
        Smart Aim, body-part selection, FOV circle
      - ESP tab: NPC highlights (green visible / red occluded), name, distance,
        box, health bar, tracers
      - Movement tab: WalkSpeed, Fly, Noclip, Jump Boost
      - Settings tab: FPS counter, UI scale, cleanup
]]

if _G.AuroraHubV7 then
    pcall(function() _G.AuroraHubV7:Destroy() end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG = {
    Accent = Color3.fromRGB(157, 92, 255),
    AccentDark = Color3.fromRGB(104, 54, 190),
    Background = Color3.fromRGB(12, 11, 18),
    Panel = Color3.fromRGB(20, 18, 29),
    Card = Color3.fromRGB(28, 25, 39),
    Text = Color3.fromRGB(245, 242, 255),
    Muted = Color3.fromRGB(151, 145, 169),
    Green = Color3.fromRGB(75, 235, 145),
    Red = Color3.fromRGB(255, 86, 105),
    AimEnabled = false,
    FOV = 150,
    Smoothness = 0.18,
    MaxDistance = 1200,
    OnlyVisible = false,
    SmartAim = true,
    AimPart = "Head",
    ShowFOV = true,
    ESPEnabled = false,
    ThroughWalls = true,
    HighlightESP = true,
    BoxAdornmentESP = true,
    NameESP = true,
    DistanceESP = true,
    BoxESP = true,
    HealthESP = true,
    Tracers = false,
    HideFriendlyNPCs = false,
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 55,
    FlyEnabled = false,
    NoclipEnabled = false,
    FPS = false,
    UIScale = 1,
}

local connections = {}
local espObjects = {}
local destroyed = false
local flyVelocity, flyGyro
local noclipOriginal = {}

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function tween(object, duration, properties, style)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tw = TweenService:Create(object, info, properties)
    tw:Play()
    return tw
end

local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or CONFIG.Accent,
        Transparency = transparency or 0.5,
        Thickness = thickness or 1,
    }, parent)
end

local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not humanoid or not root or humanoid.Health <= 0 then return false end
    if model == LocalPlayer.Character then return false end
    return true
end

local npcCache = {}
local npcCacheUpdated = 0
local function getNPCs()
    local now = os.clock()
    if now - npcCacheUpdated >= 0.65 then
        local result = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isNPC(obj) then
                table.insert(result, obj)
            end
        end
        npcCache = result
        npcCacheUpdated = now
    end
    return npcCache
end

local function getRoot(model)
    return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function visibleFromCamera(model, part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, model}
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin, direction, params)
    return hit == nil
end

local function getAimScreenPoint()
    local viewport = Camera.ViewportSize
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    end
    return UserInputService:GetMouseLocation()
end

local function getAimTarget()
    local mousePos = getAimScreenPoint()
    local best, bestScore = nil, math.huge
    for _, npc in ipairs(getNPCs()) do
        local humanoid = npc:FindFirstChildOfClass("Humanoid")
        local root = getRoot(npc)
        local part = npc:FindFirstChild(CONFIG.AimPart) or root
        if humanoid and root and part and humanoid.Health > 0 then
            local distance = (root.Position - Camera.CFrame.Position).Magnitude
            if distance <= CONFIG.MaxDistance then
                local point, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and point.Z > 0 then
                    local screenDistance = (Vector2.new(point.X, point.Y) - mousePos).Magnitude
                    local allowed = screenDistance <= CONFIG.FOV
                    if CONFIG.SmartAim then
                        allowed = allowed and visibleFromCamera(npc, part)
                    elseif CONFIG.OnlyVisible then
                        allowed = allowed and visibleFromCamera(npc, part)
                    end
                    if allowed and screenDistance < bestScore then
                        best, bestScore = part, screenDistance
                    end
                end
            end
        end
    end
    return best
end

-- Screen GUI
local screenGui = make("ScreenGui", {
    Name = "AuroraHubV7",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
}, LocalPlayer:WaitForChild("PlayerGui"))

local scale = make("UIScale", {Scale = CONFIG.UIScale}, screenGui)

-- Aurora startup splash with a staged progress indicator.
local loading = make("Frame", {
    Name = "AuroraLoading", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 7, 13), BorderSizePixel = 0, ZIndex = 100,
}, screenGui)
local loadingCard = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(290, 174), BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0, ZIndex = 101,
}, loading)
round(loadingCard, 20)
stroke(loadingCard, CONFIG.Accent, 0.2, 1.5)
make("TextLabel", {
    Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 38),
    BackgroundTransparency = 1, Text = "AURORA HUB", TextColor3 = CONFIG.Text,
    TextSize = 22, Font = Enum.Font.GothamBlack, ZIndex = 102,
}, loadingCard)
local loadingStatus = make("TextLabel", {
    Position = UDim2.fromOffset(0, 65), Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1, Text = "Preparing interface...", TextColor3 = CONFIG.Muted,
    TextSize = 11, Font = Enum.Font.Gotham, ZIndex = 102,
}, loadingCard)
local loadingPercent = make("TextLabel", {
    Position = UDim2.fromOffset(0, 89), Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1, Text = "0%", TextColor3 = CONFIG.Accent,
    TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 102,
}, loadingCard)
local loadingTrack = make("Frame", {
    Position = UDim2.fromOffset(24, 124), Size = UDim2.new(1, -48, 0, 9),
    BackgroundColor3 = Color3.fromRGB(55, 49, 68), BorderSizePixel = 0, ZIndex = 102,
}, loadingCard)
round(loadingTrack, 8)
local loadingFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = CONFIG.Accent,
    BorderSizePixel = 0, ZIndex = 103,
}, loadingTrack)
round(loadingFill, 8)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(560, 390),
    Position = UDim2.new(0.5, -280, 0.5, -195),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, screenGui)
round(main, 18)
stroke(main, CONFIG.Accent, 0.25, 1.4)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundColor3 = Color3.fromRGB(17, 14, 25),
    BorderSizePixel = 0,
}, main)
round(top, 18)

local topCover = make("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = Color3.fromRGB(17, 14, 25),
    BorderSizePixel = 0,
}, top)

local logo = make("Frame", {
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.fromOffset(16, 12),
    BackgroundColor3 = CONFIG.AccentDark,
    BorderSizePixel = 0,
}, top)
round(logo, 12)
make("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Text = "A",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 23,
    Font = Enum.Font.GothamBlack,
}, logo)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(64, 10),
    Size = UDim2.fromOffset(220, 24),
    Text = "AURORA HUB",
    TextColor3 = CONFIG.Text,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
}, top)
make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(65, 33),
    Size = UDim2.fromOffset(250, 17),
    Text = "V7.1  •  MOBILE EDITION",
    TextColor3 = CONFIG.Muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamMedium,
}, top)

local function topButton(textValue, x, color)
    local b = make("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, x, 0, 14),
        BackgroundColor3 = color,
        Text = textValue,
        TextColor3 = CONFIG.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, top)
    round(b, 10)
    return b
end

local minimizeButton = topButton("–", -86, CONFIG.Card)
local closeButton = topButton("×", -44, Color3.fromRGB(75, 35, 55))

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(14, 78),
    Size = UDim2.new(0, 132, 1, -92),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, main)
round(sidebar, 14)

local content = make("Frame", {
    Position = UDim2.fromOffset(158, 78),
    Size = UDim2.new(1, -172, 1, -92),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, main)

local pageTitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    Text = "Aim Assist",
    TextColor3 = CONFIG.Text,
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
}, content)

local pageSubtitle = make("TextLabel", {
    Position = UDim2.fromOffset(0, 28),
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "NPC training controls",
    TextColor3 = CONFIG.Muted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
}, content)

local pageHolder = make("Frame", {
    Position = UDim2.fromOffset(0, 56),
    Size = UDim2.new(1, 0, 1, -56),
    BackgroundTransparency = 1,
}, content)

local pages, tabButtons = {}, {}
local currentPage = "Aim"

local function createPage(name)
    local page = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, pageHolder)
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 5),
    }, page)
    pages[name] = page
    return page
end

local function showPage(name)
    currentPage = name
    for pageName, page in pairs(pages) do
        if pageName == name then
            page.Visible = true
            page.Position = UDim2.fromOffset(12, 0)
            page.BackgroundTransparency = 1
            tween(page, 0.2, {Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quint)
        else
            page.Visible = false
        end
    end
    for tabName, button in pairs(tabButtons) do
        local active = tabName == name
        tween(button, 0.18, {
            BackgroundColor3 = active and CONFIG.AccentDark or CONFIG.Card,
            TextColor3 = active and Color3.new(1, 1, 1) or CONFIG.Muted,
        })
    end
    pageTitle.Text = ({
        Aim = "Aim Assist",
        ESP = "NPC Visuals",
        Movement = "Movement",
        Settings = "Settings",
    })[name] or name
    pageSubtitle.Text = ({
        Aim = "NPC-only training controls",
        ESP = "Visual information for NPC models",
        Movement = "Character movement settings",
        Settings = "Interface and performance",
    })[name] or ""
end

local tabNames = {"Aim", "ESP", "Movement", "Settings"}
for index, name in ipairs(tabNames) do
    local button = make("TextButton", {
        Position = UDim2.fromOffset(9, 12 + (index - 1) * 53),
        Size = UDim2.new(1, -18, 0, 43),
        BackgroundColor3 = CONFIG.Card,
        Text = "   " .. name,
        TextColor3 = CONFIG.Muted,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
    }, sidebar)
    round(button, 11)
    tabButtons[name] = button
    track(button.Activated:Connect(function()
        tween(button, 0.08, {Size = UDim2.new(1, -22, 0, 41)})
        task.delay(0.08, function()
            if button.Parent then tween(button, 0.12, {Size = UDim2.new(1, -18, 0, 43)}) end
        end)
        showPage(name)
    end))
    createPage(name)
end

for _, stage in ipairs({
    {22, "Loading interface..."},
    {45, "Building mobile controls..."},
    {68, "Preparing NPC visual systems..."},
    {88, "Connecting movement controls..."},
    {100, "Aurora is ready"},
}) do
    loadingStatus.Text = stage[2]
    loadingPercent.Text = tostring(stage[1]) .. "%"
    tween(loadingFill, 0.22, {Size = UDim2.new(stage[1] / 100, 0, 1, 0)})
    task.wait(0.18)
end
tween(loading, 0.25, {BackgroundTransparency = 1})
task.wait(0.26)
loading:Destroy()

local function section(parent, titleText, subtitleText)
    local holder = make("Frame", {
        Size = UDim2.new(1, -2, 0, 48),
        BackgroundTransparency = 1,
    }, parent)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = CONFIG.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
    }, holder)
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = subtitleText or "",
        TextColor3 = CONFIG.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
    }, holder)
end

local function card(parent, height)
    local frame = make("Frame", {
        Size = UDim2.new(1, -2, 0, height or 54),
        BackgroundColor3 = CONFIG.Card,
        BorderSizePixel = 0,
    }, parent)
    round(frame, 12)
    return frame
end

local function toggle(parent, titleText, description, initial, callback)
    local frame = card(parent, 58)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 8),
        Size = UDim2.new(1, -85, 0, 20),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = CONFIG.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
    }, frame)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 29),
        Size = UDim2.new(1, -85, 0, 17),
        BackgroundTransparency = 1,
        Text = description or "",
        TextColor3 = CONFIG.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
    }, frame)
    local switch = make("TextButton", {
        Position = UDim2.new(1, -61, 0.5, -12),
        Size = UDim2.fromOffset(48, 24),
        BackgroundColor3 = initial and CONFIG.Accent or Color3.fromRGB(65, 60, 76),
        Text = "",
        AutoButtonColor = false,
    }, frame)
    round(switch, 20)
    local knob = make("Frame", {
        Position = initial and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, switch)
    round(knob, 20)
    local value = initial
    local function set(nextValue)
        value = nextValue
        tween(switch, 0.16, {BackgroundColor3 = value and CONFIG.Accent or Color3.fromRGB(65, 60, 76)})
        tween(knob, 0.16, {Position = value and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3)})
        if callback then callback(value) end
    end
    track(switch.Activated:Connect(function()
        tween(switch, 0.08, {Size = UDim2.fromOffset(44, 22)})
        task.delay(0.08, function()
            if switch.Parent then tween(switch, 0.12, {Size = UDim2.fromOffset(48, 24)}) end
        end)
        set(not value)
    end))
    return set
end

local function slider(parent, titleText, minValue, maxValue, initial, callback)
    local frame = card(parent, 76)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 8),
        Size = UDim2.new(1, -70, 0, 20),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = CONFIG.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
    }, frame)
    local valueLabel = make("TextLabel", {
        Position = UDim2.new(1, -58, 0, 8),
        Size = UDim2.fromOffset(45, 20),
        BackgroundTransparency = 1,
        Text = tostring(initial),
        TextColor3 = CONFIG.Accent,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
    }, frame)
    local bar = make("Frame", {
        Position = UDim2.fromOffset(13, 43),
        Size = UDim2.new(1, -26, 0, 7),
        BackgroundColor3 = Color3.fromRGB(62, 56, 76),
    }, frame)
    round(bar, 8)
    local fill = make("Frame", {
        Size = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = CONFIG.Accent,
    }, bar)
    round(fill, 8)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 0.5, 0),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = Color3.new(1, 1, 1),
    }, bar)
    round(knob, 10)
    local dragging = false
    local value = initial
    local function update(inputX)
        local alpha = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor((minValue + (maxValue - minValue) * alpha) * 100 + 0.5) / 100
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end
    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

local function dropdown(parent, titleText, options, initial, callback)
    local frame = card(parent, 58)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 0),
        Size = UDim2.new(0.48, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = CONFIG.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamSemibold,
    }, frame)
    local button = make("TextButton", {
        Position = UDim2.new(0.5, 0, 0.5, -17),
        Size = UDim2.new(0.5, -10, 0, 34),
        BackgroundColor3 = Color3.fromRGB(45, 39, 60),
        Text = initial .. "  ▾",
        TextColor3 = CONFIG.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
    }, frame)
    round(button, 9)
    local index = table.find(options, initial) or 1
    track(button.Activated:Connect(function()
        index = index % #options + 1
        button.Text = options[index] .. "  ▾"
        if callback then callback(options[index]) end
    end))
end

-- Aim page
local touchAimButton
local aimPage = pages.Aim
section(aimPage, "TARGETING", "Target selection is limited to NPCs / training dummies.")
toggle(aimPage, "Enable NPC Aim Assist", "Does not target player characters.", CONFIG.AimEnabled, function(v)
    CONFIG.AimEnabled = v
    if touchAimButton then
        touchAimButton.Visible = UserInputService.TouchEnabled and v and not CONFIG.FlyEnabled
    end
end)
slider(aimPage, "FOV Radius", 40, 500, CONFIG.FOV, function(v) CONFIG.FOV = v end)
slider(aimPage, "Smoothness", 0.02, 1, CONFIG.Smoothness, function(v) CONFIG.Smoothness = v end)
slider(aimPage, "Maximum Distance", 50, 3000, CONFIG.MaxDistance, function(v) CONFIG.MaxDistance = v end)
toggle(aimPage, "Only Visible", "Ignore NPCs behind obstacles.", CONFIG.OnlyVisible, function(v) CONFIG.OnlyVisible = v end)
toggle(aimPage, "Smart Aim", "Prioritize visible NPC targets.", CONFIG.SmartAim, function(v) CONFIG.SmartAim = v end)
toggle(aimPage, "Show FOV Circle", "Display the aim radius on screen.", CONFIG.ShowFOV, function(v) CONFIG.ShowFOV = v end)
dropdown(aimPage, "Target Part", {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}, CONFIG.AimPart, function(v) CONFIG.AimPart = v end)

-- ESP page
local espPage = pages.ESP
section(espPage, "NPC ESP", "Highlights and labels for NPC models only.")
toggle(espPage, "Enable NPC ESP", "Green = visible • Red = blocked.", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
toggle(espPage, "Through Walls", "Show NPC overlays behind map geometry.", CONFIG.ThroughWalls, function(v) CONFIG.ThroughWalls = v end)
toggle(espPage, "Highlight Method", "Roblox Highlight outline and fill.", CONFIG.HighlightESP, function(v) CONFIG.HighlightESP = v end)
toggle(espPage, "3D Box Method", "AlwaysOnTop box around NPC models.", CONFIG.BoxAdornmentESP, function(v) CONFIG.BoxAdornmentESP = v end)
toggle(espPage, "Name ESP", "Show NPC name.", CONFIG.NameESP, function(v) CONFIG.NameESP = v end)
toggle(espPage, "Distance ESP", "Show distance in studs.", CONFIG.DistanceESP, function(v) CONFIG.DistanceESP = v end)
toggle(espPage, "Box ESP", "Highlight NPC model outline.", CONFIG.BoxESP, function(v) CONFIG.BoxESP = v end)
toggle(espPage, "Health Bar", "Show NPC health above the model.", CONFIG.HealthESP, function(v) CONFIG.HealthESP = v end)
toggle(espPage, "Tracers", "Draw a line to each NPC.", CONFIG.Tracers, function(v) CONFIG.Tracers = v end)

-- Movement page
local movementPage = pages.Movement
section(movementPage, "CHARACTER", "Movement values apply to your own character.")
slider(movementPage, "Walk Speed", 16, 150, CONFIG.WalkSpeed, function(v)
    CONFIG.WalkSpeed = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
slider(movementPage, "Jump Power", 50, 200, CONFIG.JumpPower, function(v)
    CONFIG.JumpPower = v
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true hum.JumpPower = v end
end)
slider(movementPage, "Fly Speed", 10, 150, CONFIG.FlySpeed, function(v) CONFIG.FlySpeed = v end)
toggle(movementPage, "Fly", "Use WASD / joystick; touch controls appear while flying.", false, function(v)
    CONFIG.FlyEnabled = v
end)
toggle(movementPage, "Noclip", "Disable character collisions locally.", false, function(v)
    CONFIG.NoclipEnabled = v
end)

-- Settings page
local settingsPage = pages.Settings
section(settingsPage, "INTERFACE", "Adjust the panel and performance display.")
toggle(settingsPage, "FPS Counter", "Show current frame rate.", false, function(v) CONFIG.FPS = v end)
slider(settingsPage, "UI Scale", 0.75, 1.2, CONFIG.UIScale, function(v) scale.Scale = v end)

local fpsLabel = make("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 70),
    Size = UDim2.fromOffset(100, 22),
    BackgroundColor3 = CONFIG.Panel,
    BackgroundTransparency = 0.1,
    Text = "FPS: --",
    TextColor3 = CONFIG.Green,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    Visible = false,
}, screenGui)
round(fpsLabel, 8)

-- FOV circle
local fovCircle = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2),
    Position = UDim2.fromOffset(0, 0),
    Visible = false,
}, screenGui)
round(fovCircle, 500)
stroke(fovCircle, CONFIG.Accent, 0.25, 1.5)

-- Mobile aim is activated by holding this on-screen control.
touchAimButton = make("TextButton", {
    Name = "TouchAimButton",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -34),
    Size = UDim2.fromOffset(132, 48),
    BackgroundColor3 = CONFIG.AccentDark,
    Text = "HOLD  •  AIM",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Visible = UserInputService.TouchEnabled and CONFIG.AimEnabled,
    ZIndex = 20,
}, screenGui)
round(touchAimButton, 15)
stroke(touchAimButton, CONFIG.Accent, 0.15, 1.5)
local touchAimHeld = false
local function setTouchAim(held)
    touchAimHeld = held
    tween(touchAimButton, 0.12, {
        BackgroundColor3 = held and CONFIG.Accent or CONFIG.AccentDark,
        Size = held and UDim2.fromOffset(140, 52) or UDim2.fromOffset(132, 48),
    })
end
track(touchAimButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setTouchAim(true)
    end
end))
track(touchAimButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        setTouchAim(false)
    end
end))
track(UserInputService.WindowFocusReleased:Connect(function() setTouchAim(false) end))

-- Drag panel
do
    local dragging, dragStart, startPos = false, nil, nil
    track(top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- Minimize to a compact floating Aurora orb, not a clipped 560px-wide strip.
local minimized = false
local savedMainSize = main.Size
local savedMainPosition = main.Position
local miniOrb = make("TextButton", {
    Name = "AuroraMiniOrb",
    AnchorPoint = Vector2.new(0, 0),
    Size = UDim2.fromOffset(58, 58),
    Position = UDim2.new(0.5, -29, 0.5, -29),
    BackgroundColor3 = CONFIG.AccentDark,
    Text = "A",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 50,
}, screenGui)
round(miniOrb, 20)
stroke(miniOrb, CONFIG.Accent, 0.08, 2)

local function setMinimized(value)
    if minimized == value then return end
    minimized = value
    if value then
        savedMainSize = main.Size
        savedMainPosition = main.Position
        sidebar.Visible = false
        content.Visible = false
        topCover.Visible = false
        logo.Visible = false
        minimizeButton.Visible = false
        closeButton.Visible = false
        tween(main, 0.28, {
            Size = UDim2.fromOffset(58, 58),
            Position = UDim2.new(0.5, -29, 0.5, -29),
        }, Enum.EasingStyle.Back)
        task.delay(0.12, function()
            if not destroyed and minimized then
                main.Visible = false
                miniOrb.Visible = true
                tween(miniOrb, 0.22, {Size = UDim2.fromOffset(58, 58)}, Enum.EasingStyle.Back)
            end
        end)
    else
        miniOrb.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(58, 58)
        main.Position = savedMainPosition
        logo.Visible = true
        minimizeButton.Visible = true
        closeButton.Visible = true
        topCover.Visible = true
        sidebar.Visible = true
        content.Visible = true
        tween(main, 0.3, {Size = savedMainSize}, Enum.EasingStyle.Back)
    end
end

track(minimizeButton.Activated:Connect(function() setMinimized(true) end))
track(miniOrb.Activated:Connect(function() setMinimized(false) end))

-- The minimized orb can be dragged independently on touch or desktop.
do
    local dragging, startInput, startPosition
    track(miniOrb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = input.Position
            startPosition = miniOrb.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - startInput
            miniOrb.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

local function cleanupESP(model)
    local data = espObjects[model]
    if data then
        for _, obj in pairs(data) do
            if typeof(obj) == "Instance" then pcall(function() obj:Destroy() end) end
        end
        espObjects[model] = nil
    end
end

local function cleanup()
    if destroyed then return end
    destroyed = true
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for model in pairs(espObjects) do cleanupESP(model) end
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    touchAimHeld = false
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and noclipOriginal[part] ~= nil then
                part.CanCollide = noclipOriginal[part]
            end
        end
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    pcall(function() screenGui:Destroy() end)
    _G.AuroraHubV7 = nil
end

track(closeButton.Activated:Connect(cleanup))

local function getESP(model)
    if espObjects[model] then return espObjects[model] end
    local rootPart = getRoot(model)
    local highlight = make("Highlight", {
        Name = "AuroraNPC_Highlight", Adornee = model,
        FillTransparency = 0.86, OutlineTransparency = 0.02,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = true,
    }, Workspace)
    local box = make("BoxHandleAdornment", {
        Name = "AuroraNPC_3DBox", Adornee = rootPart,
        Size = rootPart and (rootPart.Size + Vector3.new(2.2, 3.2, 1.6)) or Vector3.new(4, 6, 3),
        Color3 = CONFIG.Green, Transparency = 0.18, AlwaysOnTop = true,
        ZIndex = 10, Visible = true,
    }, Workspace)
    local billboard = make("BillboardGui", {
        Name = "AuroraNPC_Info", Adornee = rootPart,
        Size = UDim2.fromOffset(170, 52), StudsOffset = Vector3.new(0, 3.5, 0),
        AlwaysOnTop = true, Enabled = true, MaxDistance = 10000,
    }, LocalPlayer:WaitForChild("PlayerGui"))
    local label = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1,
        Text = model.Name, TextColor3 = CONFIG.Text, TextStrokeTransparency = 0.2,
        TextSize = 12, Font = Enum.Font.GothamBold,
    }, billboard)
    local healthBack = make("Frame", {
        Position = UDim2.fromOffset(25, 32), Size = UDim2.fromOffset(120, 7),
        BackgroundColor3 = Color3.fromRGB(55, 50, 65), BorderSizePixel = 0,
    }, billboard)
    round(healthBack, 5)
    local healthFill = make("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = CONFIG.Green, BorderSizePixel = 0,
    }, healthBack)
    round(healthFill, 5)
    local tracer = make("Frame", {
        Name = "AuroraNPC_Tracer",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(0, 2),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 5,
    }, screenGui)
    round(tracer, 2)
    local data = {
        Highlight = highlight, Box = box, Billboard = billboard,
        Label = label, HealthBack = healthBack, HealthFill = healthFill,
        Tracer = tracer,
    }
    espObjects[model] = data
    return data
end

local touchFlyGui = make("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -24),
    Size = UDim2.fromOffset(120, 90),
    BackgroundTransparency = 1,
    Visible = false,
}, screenGui)

local upButton = make("TextButton", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = CONFIG.AccentDark,
    Text = "UP",
    TextColor3 = CONFIG.Text,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
}, touchFlyGui)
round(upButton, 12)
local downButton = make("TextButton", {
    Position = UDim2.fromOffset(80, 0),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = CONFIG.AccentDark,
    Text = "DN",
    TextColor3 = CONFIG.Text,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
}, touchFlyGui)
round(downButton, 12)
local verticalFly = 0
local flyForward = 0
local flySide = 0

local function makeFlyDirection(textValue, position, axis, amount)
    local button = make("TextButton", {
        Position = position, Size = UDim2.fromOffset(36, 36),
        BackgroundColor3 = CONFIG.Card, Text = textValue, TextColor3 = CONFIG.Text,
        TextSize = 14, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, touchFlyGui)
    round(button, 10)
    local function begin()
        if axis == "forward" then flyForward = amount else flySide = amount end
        tween(button, 0.1, {BackgroundColor3 = CONFIG.Accent})
    end
    local function finish()
        if axis == "forward" and flyForward == amount then flyForward = 0 end
        if axis == "side" and flySide == amount then flySide = 0 end
        tween(button, 0.1, {BackgroundColor3 = CONFIG.Card})
    end
    track(button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then begin() end
    end))
    track(button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then finish() end
    end))
end

makeFlyDirection("▲", UDim2.fromOffset(42, 0), "forward", 1)
makeFlyDirection("▼", UDim2.fromOffset(42, 48), "forward", -1)
makeFlyDirection("◀", UDim2.fromOffset(2, 48), "side", -1)
makeFlyDirection("▶", UDim2.fromOffset(82, 48), "side", 1)

track(upButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then verticalFly = 1 end
end))
track(downButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then verticalFly = -1 end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then verticalFly = 0 end
end))

local fpsFrames, fpsElapsed = 0, 0
track(RunService.RenderStepped:Connect(function(dt)
    if destroyed then return end
    Camera = Workspace.CurrentCamera or Camera
    local mouse = UserInputService:GetMouseLocation()
    local aimPoint = getAimScreenPoint()
    fovCircle.Position = UDim2.fromOffset(aimPoint.X, aimPoint.Y)
    fovCircle.Size = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2)
    fovCircle.Visible = CONFIG.ShowFOV and CONFIG.AimEnabled and (not UserInputService.TouchEnabled or CONFIG.AimEnabled)
    fpsFrames += 1
    fpsElapsed += dt
    if fpsElapsed >= 0.5 then
        fpsLabel.Text = "FPS: " .. tostring(math.floor(fpsFrames / fpsElapsed))
        fpsLabel.Visible = CONFIG.FPS
        fpsFrames, fpsElapsed = 0, 0
    end

    local aimHeld = (UserInputService.MouseEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        or (UserInputService.TouchEnabled and touchAimHeld)
    if CONFIG.AimEnabled and aimHeld then
        local target = getAimTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local desired = CFrame.lookAt(camPos, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(desired, math.clamp(CONFIG.Smoothness, 0.02, 1))
        end
    end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        if CONFIG.NoclipEnabled and character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if noclipOriginal[part] == nil then noclipOriginal[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        elseif character then
            for part, oldValue in pairs(noclipOriginal) do
                if part and part.Parent then part.CanCollide = oldValue end
                noclipOriginal[part] = nil
            end
        end
    end

    if CONFIG.FlyEnabled and root and humanoid then
        touchFlyGui.Visible = true
        touchAimButton.Visible = false
        humanoid.PlatformStand = false
        if not flyVelocity or not flyVelocity.Parent then
            flyVelocity = Instance.new("BodyVelocity")
            flyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            flyVelocity.Parent = root
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            flyGyro.P = 9000
            flyGyro.Parent = root
        end
        local cf = Camera.CFrame
        local forward, side = 0, 0
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then forward += 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then forward -= 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then side -= 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then side += 1 end
        if UserInputService.TouchEnabled and humanoid.MoveDirection.Magnitude > 0.05 then
            forward += humanoid.MoveDirection:Dot(cf.LookVector)
            side += humanoid.MoveDirection:Dot(cf.RightVector)
        end
        forward += flyForward
        side += flySide
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalFly = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then verticalFly = -1 end
        local flatForward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
        local flatRight = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if flatForward.Magnitude > 0 then flatForward = flatForward.Unit end
        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
        local move = flatForward * forward + flatRight * side + Vector3.new(0, verticalFly, 0)
        flyVelocity.Velocity = move.Magnitude > 0.05 and move.Unit * CONFIG.FlySpeed or Vector3.zero
        flyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + cf.LookVector)
    else
        touchFlyGui.Visible = false
        touchAimButton.Visible = UserInputService.TouchEnabled and CONFIG.AimEnabled
        verticalFly = 0
        flyForward = 0
        flySide = 0
        if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
        if humanoid then humanoid.PlatformStand = false end
    end

    if CONFIG.ESPEnabled then
        local seen = {}
        for _, npc in ipairs(getNPCs()) do
            seen[npc] = true
            local data = getESP(npc)
            local rootPart = getRoot(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local dist = rootPart and (rootPart.Position - Camera.CFrame.Position).Magnitude or 0
            local visible = rootPart and visibleFromCamera(npc, rootPart) or false
            local tint = visible and CONFIG.Green or CONFIG.Red
            data.Highlight.Enabled = CONFIG.HighlightESP and CONFIG.BoxESP
            data.Highlight.DepthMode = CONFIG.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            data.Highlight.FillColor = tint
            data.Highlight.OutlineColor = tint
            data.Box.Visible = CONFIG.BoxAdornmentESP and CONFIG.BoxESP
            data.Box.AlwaysOnTop = CONFIG.ThroughWalls
            data.Box.Color3 = tint
            if rootPart then
                data.Box.Adornee = rootPart
                data.Box.Size = rootPart.Size + Vector3.new(2.2, 3.2, 1.6)
            end
            data.Billboard.Enabled = CONFIG.NameESP or CONFIG.DistanceESP or CONFIG.HealthESP
            local name = CONFIG.NameESP and npc.Name or ""
            local distanceText = CONFIG.DistanceESP and ("  [" .. tostring(math.floor(dist)) .. " studs]") or ""
            data.Label.Text = name .. distanceText
            data.Label.Visible = CONFIG.NameESP or CONFIG.DistanceESP
            data.HealthBack.Visible = CONFIG.HealthESP
            if hum then
                local ratio = hum.MaxHealth > 0 and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 0
                data.HealthFill.Size = UDim2.new(ratio, 0, 1, 0)
                data.HealthFill.BackgroundColor3 = ratio > 0.5 and CONFIG.Green or CONFIG.Red
            end
            if rootPart then
                data.Billboard.Adornee = rootPart
                local viewport, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local screenSize = Camera.ViewportSize
                local startPoint = Vector2.new(screenSize.X * 0.5, screenSize.Y - 8)
                local endPoint = Vector2.new(viewport.X, viewport.Y)
                local delta = endPoint - startPoint
                data.Tracer.Visible = CONFIG.Tracers and onScreen and viewport.Z > 0
                if data.Tracer.Visible then
                    data.Tracer.Position = UDim2.fromOffset(startPoint.X, startPoint.Y)
                    data.Tracer.Size = UDim2.fromOffset(delta.Magnitude, 2)
                    data.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                    data.Tracer.BackgroundColor3 = tint
                end
            else
                data.Tracer.Visible = false
            end
        end
        for model in pairs(espObjects) do
            if not seen[model] or not model.Parent then cleanupESP(model) end
        end
    else
        for model in pairs(espObjects) do cleanupESP(model) end
    end
end))

-- Touch-friendly default sizing for portrait screens.
local function updateViewport()
    local viewport = Camera.ViewportSize
    if viewport.X < 700 then
        local width = math.max(300, math.min(560, viewport.X - 18))
        local height = math.max(300, math.min(520, viewport.Y - 90))
        savedMainSize = UDim2.fromOffset(width, height)
        if not minimized then
            main.Size = savedMainSize
            main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
        end
        sidebar.Size = UDim2.new(0, 104, 1, -92)
        content.Position = UDim2.fromOffset(122, 78)
        content.Size = UDim2.new(1, -136, 1, -92)
        for _, button in pairs(tabButtons) do button.TextSize = 10 end
        touchAimButton.Position = UDim2.new(0.5, 0, 1, -24)
    else
        savedMainSize = UDim2.fromOffset(560, 390)
        if not minimized then main.Size = savedMainSize end
        sidebar.Size = UDim2.new(0, 132, 1, -92)
        content.Position = UDim2.fromOffset(158, 78)
        content.Size = UDim2.new(1, -172, 1, -92)
    end
end
updateViewport()
track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
    if Camera then updateViewport() end
end))

_G.AuroraHubV7 = {
    Destroy = cleanup,
    Version = "7.1",
}

showPage("Aim")
tween(main, 0.28, {Position = main.Position}, Enum.EasingStyle.Back)
