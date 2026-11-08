-- AURORA HUB v5.0 | Touch-first Roblox UI
-- Touch Fling is restricted to NPCs / training dummies (Models with a Humanoid)
-- Use only in your own experience or where you have permission.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local THEME = {
    bg = Color3.fromRGB(10, 12, 19),
    panel = Color3.fromRGB(17, 20, 30),
    card = Color3.fromRGB(25, 29, 43),
    card2 = Color3.fromRGB(35, 40, 57),
    accent = Color3.fromRGB(151, 105, 255),
    accent2 = Color3.fromRGB(105, 70, 205),
    white = Color3.fromRGB(246, 244, 252),
    muted = Color3.fromRGB(151, 157, 178),
    green = Color3.fromRGB(80, 220, 155),
    orange = Color3.fromRGB(255, 184, 90),
    red = Color3.fromRGB(255, 100, 125),
    border = Color3.fromRGB(58, 64, 85)
}

-- Remove an earlier copy
pcall(function()
    local cg = game:GetService("CoreGui")
    local previous = cg:FindFirstChild("AuroraHubV5")
    if previous then previous:Destroy() end
end)

local function make(className, props, parent)
    local instance = Instance.new(className)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(instance, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 14)}, instance)
end

local function outline(instance, color, transparency)
    make("UIStroke", {
        Color = color or THEME.border,
        Transparency = transparency or 0.25,
        Thickness = 1
    }, instance)
end

local function animate(instance, props, duration)
    TweenService:Create(instance, TweenInfo.new(duration or 0.17, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local gui = make("ScreenGui", {
    Name = "AuroraHubV5",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
local parented = pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not parented then gui.Parent = LP:WaitForChild("PlayerGui") end

-- Live FPS counter
local fpsPill = make("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -14, 0, 13),
    Size = UDim2.fromOffset(116, 39),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0,
    ZIndex = 30
}, gui)
corner(fpsPill, 20)
outline(fpsPill, THEME.accent, 0.18)
local fpsDot = make("Frame", {
    Position = UDim2.fromOffset(13, 15),
    Size = UDim2.fromOffset(9, 9),
    BackgroundColor3 = THEME.green,
    BorderSizePixel = 0,
    ZIndex = 31
}, fpsPill)
corner(fpsDot, 8)
local fpsLabel = make("TextLabel", {
    Position = UDim2.fromOffset(30, 0),
    Size = UDim2.new(1, -34, 1, 0),
    BackgroundTransparency = 1,
    Text = "-- FPS",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = THEME.white,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 31
}, fpsPill)

local fpsFrames, fpsTime = 0, 0
local fpsConnection = RunService.RenderStepped:Connect(function(dt)
    fpsFrames += 1
    fpsTime += dt
    if fpsTime >= 0.5 then
        local fps = math.floor(fpsFrames / fpsTime + 0.5)
        fpsLabel.Text = tostring(fps) .. " FPS"
        fpsDot.BackgroundColor3 = fps >= 50 and THEME.green or (fps >= 30 and THEME.orange or THEME.red)
        fpsFrames, fpsTime = 0, 0
    end
end)

-- Main window
local window = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.53),
    Size = UDim2.fromOffset(370, 535),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)
corner(window, 23)
outline(window, THEME.accent, 0.18)
make("UISizeConstraint", {
    MinSize = Vector2.new(300, 430),
    MaxSize = Vector2.new(430, 650)
}, window)
local uiScale = make("UIScale", {Scale = 1}, window)

local function fitWindow()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    uiScale.Scale = math.clamp(math.min(viewport.X / 430, viewport.Y / 760), 0.72, 1)
end
fitWindow()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitWindow)
end

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 82),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0
}, window)
local brand = make("TextLabel", {
    Position = UDim2.fromOffset(18, 12),
    Size = UDim2.new(1, -112, 0, 28),
    BackgroundTransparency = 1,
    Text = "AURORA  HUB",
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextColor3 = THEME.white,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)
local subtitle = make("TextLabel", {
    Position = UDim2.fromOffset(20, 43),
    Size = UDim2.new(1, -112, 0, 17),
    BackgroundTransparency = 1,
    Text = "MOBILE EDITION  •  BUILD 5.0",
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextColor3 = THEME.muted,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)
local minimizeButton = make("TextButton", {
    Position = UDim2.new(1, -78, 0, 21),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = THEME.card2,
    Text = "−",
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextColor3 = THEME.white,
    AutoButtonColor = false
}, header)
corner(minimizeButton, 9)
local closeButton = make("TextButton", {
    Position = UDim2.new(1, -43, 0, 21),
    Size = UDim2.fromOffset(27, 27),
    BackgroundColor3 = THEME.card2,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = THEME.white,
    AutoButtonColor = false
}, header)
corner(closeButton, 9)

local nav = make("Frame", {
    Position = UDim2.fromOffset(12, 92),
    Size = UDim2.new(1, -24, 0, 43),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0
}, window)
corner(nav, 13)

local pageHost = make("Frame", {
    Position = UDim2.fromOffset(12, 146),
    Size = UDim2.new(1, -24, 1, -158),
    BackgroundTransparency = 1
}, window)

local pageNames = {"ESP", "Movement", "Fling", "Settings"}
local pages, tabButtons = {}, {}
for index, name in ipairs(pageNames) do
    local button = make("TextButton", {
        Position = UDim2.new((index - 1) / 4, 3, 0, 4),
        Size = UDim2.new(1 / 4, -6, 1, -8),
        BackgroundColor3 = THEME.panel,
        Text = name,
        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
        TextColor3 = THEME.muted,
        AutoButtonColor = false
    }, nav)
    corner(button, 10)
    tabButtons[name] = button

    local page = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false
    }, pageHost)
    make("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 4)
    }, page)
    pages[name] = page
end

local function selectPage(name)
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end
    for tabName, button in pairs(tabButtons) do
        local active = tabName == name
        animate(button, {BackgroundColor3 = active and THEME.accent2 or THEME.panel})
        button.TextColor3 = active and THEME.white or THEME.muted
    end
end
for name, button in pairs(tabButtons) do
    button.Activated:Connect(function() selectPage(name) end)
end

local function section(page, title, description)
    local holder = make("Frame", {
        Size = UDim2.new(1, 0, 0, 41),
        BackgroundTransparency = 1
    }, page)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = THEME.accent,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)
    make("TextLabel", {
        Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = description or "",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = THEME.muted,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)
end

local function card(page, height)
    local frame = make("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = THEME.card,
        BorderSizePixel = 0
    }, page)
    corner(frame, 14)
    outline(frame, THEME.border, 0.48)
    return frame
end

local function toggle(page, title, hint, callback, initial)
    local frame = card(page, 61)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 8),
        Size = UDim2.new(1, -82, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = THEME.white,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 31),
        Size = UDim2.new(1, -82, 0, 16),
        BackgroundTransparency = 1,
        Text = hint or "",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = THEME.muted,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    local state = initial == true
    local switch = make("TextButton", {
        Position = UDim2.new(1, -58, 0.5, -13),
        Size = UDim2.fromOffset(44, 26),
        BackgroundColor3 = state and THEME.accent or THEME.card2,
        Text = "",
        AutoButtonColor = false
    }, frame)
    corner(switch, 14)
    local knob = make("Frame", {
        Position = state and UDim2.new(1, -23, 0, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = THEME.white,
        BorderSizePixel = 0
    }, switch)
    corner(knob, 10)
    local function set(value, silent)
        state = value
        animate(switch, {BackgroundColor3 = state and THEME.accent or THEME.card2})
        animate(knob, {Position = state and UDim2.new(1, -23, 0, 3) or UDim2.fromOffset(3, 3)})
        if callback and not silent then
            local success, err = pcall(callback, state)
            if not success then warn("[Aurora] " .. tostring(err)) end
        end
    end
    switch.Activated:Connect(function() set(not state) end)
    return set
end

local function slider(page, title, minValue, maxValue, startValue, suffix, callback)
    local frame = card(page, 77)
    make("TextLabel", {
        Position = UDim2.fromOffset(13, 8),
        Size = UDim2.new(1, -95, 0, 19),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = THEME.white,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    local valueText = make("TextLabel", {
        Position = UDim2.new(1, -83, 0, 8),
        Size = UDim2.fromOffset(70, 19),
        BackgroundTransparency = 1,
        Text = tostring(startValue) .. (suffix or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.accent,
        TextXAlignment = Enum.TextXAlignment.Right
    }, frame)
    local bar = make("Frame", {
        Position = UDim2.fromOffset(13, 44),
        Size = UDim2.new(1, -26, 0, 9),
        BackgroundColor3 = THEME.card2,
        BorderSizePixel = 0
    }, frame)
    corner(bar, 6)
    local percent = (startValue - minValue) / (maxValue - minValue)
    local fill = make("Frame", {
        Size = UDim2.new(percent, 0, 1, 0),
        BackgroundColor3 = THEME.accent,
        BorderSizePixel = 0
    }, bar)
    corner(fill, 6)
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(percent, 0, 0.5, 0),
        Size = UDim2.fromOffset(19, 19),
        BackgroundColor3 = THEME.white,
        BorderSizePixel = 0
    }, bar)
    corner(knob, 10)
    outline(knob, THEME.accent, 0)
    local value, dragging = startValue, false
    local function setAt(x)
        local p = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        value = math.floor(minValue + (maxValue - minValue) * p + 0.5)
        p = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        valueText.Text = tostring(value) .. (suffix or "")
        if callback then callback(value) end
    end
    local function begin(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setAt(input.Position.X)
        end
    end
    bar.InputBegan:Connect(begin)
    knob.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            setAt(input.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    return function() return value end
end

local function characterParts()
    local character = LP.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

-- ESP tab
section(pages.ESP, "Player visuals", "Visual overlays for players in the current session")
local espEnabled = false
local espItems = {}
local function clearESP(player)
    local items = espItems[player]
    if items then
        for _, item in ipairs(items) do
            if item then pcall(function() item:Destroy() end) end
        end
        espItems[player] = nil
    end
end
local function addESP(player)
    clearESP(player)
    if not espEnabled or player == LP or not player.Character then return end
    local character = player.Character
    local highlight = make("Highlight", {
        Name = "AuroraPlayerHighlight",
        FillColor = THEME.accent,
        OutlineColor = THEME.white,
        FillTransparency = 0.72,
        OutlineTransparency = 0.05,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    }, character)
    local head = character:FindFirstChild("Head")
    local billboard
    if head then
        billboard = make("BillboardGui", {
            Name = "AuroraNameTag",
            Adornee = head,
            Size = UDim2.fromOffset(140, 26),
            StudsOffset = Vector3.new(0, 2.5, 0),
            AlwaysOnTop = true
        }, head)
        make("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = player.DisplayName,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = THEME.white,
            TextStrokeTransparency = 0.35
        }, billboard)
    end
    espItems[player] = {highlight, billboard}
end
local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if espEnabled then addESP(player) else clearESP(player) end
        end
    end
end
toggle(pages.ESP, "Player ESP", "Highlight + display names", function(value)
    espEnabled = value
    refreshESP()
end)
section(pages.ESP, "Display options", "Additional labels are kept lightweight")
local espDistance = false
toggle(pages.ESP, "Distance labels", "Show distance above tagged players", function(value)
    espDistance = value
    -- Rebuild tags so the label reflects the selected option.
    refreshESP()
end)
-- Rebuild ESP tag text with optional distance using a small update loop.
local distanceLoop = RunService.Heartbeat:Connect(function()
    if not espEnabled or not espDistance then return end
    local _, _, localRoot = characterParts()
    if not localRoot then return end
    for player, items in pairs(espItems) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        local billboard = head and head:FindFirstChild("AuroraNameTag")
        local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
        if root and label then
            label.Text = player.DisplayName .. "  •  " .. math.floor((root.Position - localRoot.Position).Magnitude) .. "m"
        end
    end
end)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.8)
        if espEnabled then addESP(player) end
    end)
end)
Players.PlayerRemoving:Connect(clearESP)

-- Movement tab
section(pages.Movement, "Movement controls", "Adjustable local character controls")
local walkSpeed, speedEnabled = 28, false
local flySpeed, flyEnabled = 55, false
local savedWalkSpeed = 16
local flyVelocity, flyGyro, flyConnection
local verticalDirection = 0
local flyControls

toggle(pages.Movement, "Speed Boost", "Set your character walking speed", function(value)
    speedEnabled = value
    local _, humanoid = characterParts()
    if humanoid then humanoid.WalkSpeed = value and walkSpeed or savedWalkSpeed end
end)
slider(pages.Movement, "Walk speed", 16, 100, walkSpeed, " WS", function(value)
    walkSpeed = value
    if speedEnabled then
        local _, humanoid = characterParts()
        if humanoid then humanoid.WalkSpeed = value end
    end
end)

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    local _, humanoid = characterParts()
    if humanoid then humanoid.PlatformStand = false end
    verticalDirection = 0
    if flyControls then flyControls.Visible = false end
end

local function startFly()
    stopFly()
    local _, humanoid, root = characterParts()
    if not humanoid or not root then return false end
    humanoid.PlatformStand = false
    flyVelocity = make("BodyVelocity", {
        Name = "AuroraFlyVelocity",
        MaxForce = Vector3.new(1e6, 1e6, 1e6),
        P = 1e4,
        Velocity = Vector3.zero
    }, root)
    flyGyro = make("BodyGyro", {
        Name = "AuroraFlyGyro",
        MaxTorque = Vector3.new(1e6, 1e6, 1e6),
        P = 1e4,
        CFrame = root.CFrame
    }, root)
    flyControls.Visible = true
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not root.Parent then return end
        local camera = workspace.CurrentCamera
        local move = humanoid.MoveDirection
        flyVelocity.Velocity = (move * flySpeed) + Vector3.new(0, verticalDirection * flySpeed, 0)
        if camera then flyGyro.CFrame = camera.CFrame end
    end)
    return true
end

toggle(pages.Movement, "Fly", "Move with joystick and screen arrows", function(value)
    flyEnabled = value
    if value then
        if not startFly() then flyEnabled = false end
    else
        stopFly()
    end
end)
slider(pages.Movement, "Fly speed", 10, 120, flySpeed, " SPD", function(value)
    flySpeed = value
end)

section(pages.Movement, "Collision", "Restore original collision settings when disabled")
local noclipEnabled, noclipConnection = false, nil
local originalCollision = {}
toggle(pages.Movement, "Noclip", "Temporarily disable character collisions", function(value)
    noclipEnabled = value
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if value then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LP.Character
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if originalCollision[part] == nil then originalCollision[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end)
    else
        for part, oldValue in pairs(originalCollision) do
            if part and part.Parent then pcall(function() part.CanCollide = oldValue end) end
        end
        table.clear(originalCollision)
    end
end)

-- Fly vertical touch controls are outside the menu for thumb access.
flyControls = make("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.58, 0),
    Size = UDim2.fromOffset(58, 128),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 40
}, gui)
local function makeVerticalButton(text, y, direction)
    local button = make("TextButton", {
        Position = UDim2.fromOffset(0, y),
        Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = THEME.panel,
        Text = text,
        Font = Enum.Font.GothamBlack,
        TextSize = 19,
        TextColor3 = THEME.white,
        AutoButtonColor = false,
        ZIndex = 41
    }, flyControls)
    corner(button, 18)
    outline(button, THEME.accent, 0.12)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalDirection = direction
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalDirection = 0
        end
    end)
end
makeVerticalButton("▲", 0, 1)
makeVerticalButton("▼", 70, -1)

-- Fling tab: only target NPCs / dummies, never player characters.
section(pages.Fling, "Touch fling", "Select and move NPCs / training dummies in your own game")
local selectedNPC
local flingPower = 85
local selectedLabel = card(pages.Fling, 54)
local selectedText = make("TextLabel", {
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -24, 1, 0),
    BackgroundTransparency = 1,
    Text = "Selected target: none",
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextColor3 = THEME.white,
    TextXAlignment = Enum.TextXAlignment.Left
}, selectedLabel)

local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    return humanoid ~= nil and root ~= nil
end

local function findNPCFromPart(part)
    local current = part
    while current and current ~= workspace do
        if current:IsA("Model") and isNPC(current) then return current end
        current = current.Parent
    end
    return nil
end

local function selectNPC(model)
    selectedNPC = model
    selectedText.Text = model and ("Selected target: " .. model.Name) or "Selected target: none"
end

local hintCard = card(pages.Fling, 74)
make("TextLabel", {
    Position = UDim2.fromOffset(12, 8),
    Size = UDim2.new(1, -24, 1, -16),
    BackgroundTransparency = 1,
    Text = "Tap an NPC or training dummy in the 3D world to select it. Player characters are ignored.",
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextColor3 = THEME.muted,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
}, hintCard)

local selectMode = false
toggle(pages.Fling, "Touch select mode", "Tap an NPC in the world while this is enabled", function(value)
    selectMode = value
end)
slider(pages.Fling, "Fling impulse", 20, 160, flingPower, " PWR", function(value)
    flingPower = value
end)

local flingButtonCard = card(pages.Fling, 60)
local flingButton = make("TextButton", {
    Position = UDim2.fromOffset(10, 8),
    Size = UDim2.new(1, -20, 1, -16),
    BackgroundColor3 = THEME.accent2,
    Text = "FLING SELECTED NPC",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = THEME.white,
    AutoButtonColor = false
}, flingButtonCard)
corner(flingButton, 12)
flingButton.Activated:Connect(function()
    if not selectedNPC or not isNPC(selectedNPC) then
        selectedText.Text = "Select a valid NPC first"
        return
    end
    local root = selectedNPC:FindFirstChild("HumanoidRootPart") or selectedNPC.PrimaryPart
    if not root or root.Anchored then
        selectedText.Text = "NPC root is anchored"
        return
    end
    -- Apply a one-shot impulse only to the selected NPC model.
    local direction = (root.Position - (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or root.Position))
    if direction.Magnitude < 0.01 then direction = Vector3.new(0, 1, 0) end
    direction = (direction.Unit + Vector3.new(0, 0.65, 0)).Unit
    local success = pcall(function()
        root:ApplyImpulse(direction * root.AssemblyMass * flingPower)
    end)
    selectedText.Text = success and ("Impulse sent to: " .. selectedNPC.Name) or "Impulse failed (network ownership)"
end)

-- Tap selection through camera raycast
local function trySelectAt(screenPosition)
    if not selectMode then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = LP.Character
    params.FilterDescendantsInstances = character and {character} or {}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then
        local model = findNPCFromPart(result.Instance)
        if model then
            selectNPC(model)
        else
            selectedText.Text = "No NPC at that position"
        end
    end
end
UIS.InputBegan:Connect(function(input, processed)
    if processed or not selectMode then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        trySelectAt(input.Position)
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        trySelectAt(input.Position)
    end
end)

-- Settings tab
section(pages.Settings, "Performance", "Live counter is pinned to the top-right corner")
local fpsCap = 120
slider(pages.Settings, "FPS cap value", 30, 240, fpsCap, " FPS", function(value)
    fpsCap = value
end)
local applyCard = card(pages.Settings, 56)
make("TextLabel", {
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -105, 1, 0),
    BackgroundTransparency = 1,
    Text = "Apply executor FPS cap",
    Font = Enum.Font.GothamSemibold,
    TextSize = 11,
    TextColor3 = THEME.white,
    TextXAlignment = Enum.TextXAlignment.Left
}, applyCard)
local applyButton = make("TextButton", {
    Position = UDim2.new(1, -88, 0.5, -15),
    Size = UDim2.fromOffset(75, 30),
    BackgroundColor3 = THEME.accent2,
    Text = "APPLY",
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextColor3 = THEME.white,
    AutoButtonColor = false
}, applyCard)
corner(applyButton, 10)
applyButton.Activated:Connect(function()
    if type(setfpscap) == "function" then
        local success = pcall(setfpscap, fpsCap)
        if success then
            applyButton.Text = "DONE"
        else
            applyButton.Text = "ERROR"
        end
    else
        applyButton.Text = "N/A"
    end
    task.delay(1.2, function()
        if applyButton.Parent then applyButton.Text = "APPLY" end
    end)
end)

section(pages.Settings, "Interface", "Move the panel or collapse it to a floating icon")
local compactButtonCard = card(pages.Settings, 56)
local compactButton = make("TextButton", {
    Position = UDim2.fromOffset(10, 8),
    Size = UDim2.new(1, -20, 1, -16),
    BackgroundColor3 = THEME.card2,
    Text = "MINIMIZE WINDOW",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = THEME.white,
    AutoButtonColor = false
}, compactButtonCard)
corner(compactButton, 11)

local floating = make("TextButton", {
    Visible = false,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 13, 0.5, 0),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = THEME.accent2,
    Text = "A",
    Font = Enum.Font.GothamBlack,
    TextSize = 23,
    TextColor3 = THEME.white,
    AutoButtonColor = false,
    ZIndex = 50
}, gui)
corner(floating, 20)
outline(floating, THEME.white, 0.72)

local function setMinimized(value)
    window.Visible = not value
    floating.Visible = value
end
minimizeButton.Activated:Connect(function() setMinimized(true) end)
compactButton.Activated:Connect(function() setMinimized(true) end)
floating.Activated:Connect(function() setMinimized(false) end)

-- Drag panel from header
do
    local dragging, startInput, startPosition
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = input.Position
            startPosition = window.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - startInput
            window.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function cleanup()
    espEnabled = false
    for player in pairs(espItems) do clearESP(player) end
    if distanceLoop then distanceLoop:Disconnect() end
    flyEnabled = false
    stopFly()
    if noclipConnection then noclipConnection:Disconnect() end
    for part, oldValue in pairs(originalCollision) do
        if part and part.Parent then pcall(function() part.CanCollide = oldValue end) end
    end
    table.clear(originalCollision)
    local _, humanoid = characterParts()
    if humanoid then
        humanoid.WalkSpeed = savedWalkSpeed
        humanoid.PlatformStand = false
    end
    if fpsConnection then fpsConnection:Disconnect() end
    gui:Destroy()
end
closeButton.Activated:Connect(cleanup)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    local _, humanoid = characterParts()
    if humanoid and speedEnabled then humanoid.WalkSpeed = walkSpeed end
    if espEnabled then refreshESP() end
    if flyEnabled then startFly() end
end)

selectPage("ESP")
