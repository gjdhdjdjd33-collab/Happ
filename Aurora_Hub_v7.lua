--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 1/6 — Config, services, state, utilities
================================================================================
]]

local CONFIG = {
    Name = "AURORA",
    Subtitle = "MOBILE INTERFACE",
    Version = "10.1",
    WindowWidth = 690,
    WindowHeight = 500,
    MinWidth = 320,
    MinHeight = 280,
    Accent       = Color3.fromRGB(124, 160, 255),
    AccentBright = Color3.fromRGB(172, 198, 255),
    AccentDark   = Color3.fromRGB( 72, 102, 182),
    Background   = Color3.fromRGB(  9,  10,  16),
    Surface      = Color3.fromRGB( 17,  19,  28),
    Surface2     = Color3.fromRGB( 24,  27,  38),
    Surface3     = Color3.fromRGB( 34,  38,  54),
    Text         = Color3.fromRGB(238, 241, 250),
    Muted        = Color3.fromRGB(136, 145, 168),
    Good         = Color3.fromRGB( 96, 220, 160),
    Warning      = Color3.fromRGB(255, 200,  96),
    Danger       = Color3.fromRGB(255, 100, 122),
    Critical     = Color3.fromRGB(255,  70,  92),
    Radius = 14,
    AnimationSpeed = 0.18,
    ShowIntro = true,
    IntroDuration = 1.45,
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[Aurora] LocalPlayer is unavailable in this execution context.")
    return
end

local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if not PlayerGui then
    PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 8)
end
if not PlayerGui then
    warn("[Aurora] PlayerGui was not found.")
    return
end

local State = {
    Page = "Dashboard",
    WindowOpen = true,
    Minimized = false,
    Destroyed = false,
    SearchText = "",
    Notifications = true,
    SoundEffects = false,
    ReducedMotion = false,
    Scale = 1,
    LastAction = "Interface initialized",
    StartedAt = os.clock(),
    ErrorCount = 0,
    ActionCount = 0,
    RefreshCount = 0,
    ProfileName = "Default",
    Preferences = {
        CompactSidebar = false,
        ShowClock = true,
        ShowFPS = true,
        ShowSession = true,
        BlurCards = false,
        Animations = true,
        AccentGlow = true,
        ShowHints = true,
        ConfirmReset = true,
        AutoSave = false,
    },
    Modules = {
        Visuals = false,
        AimLab = false,
        PlayerTools = false,
        MovementTools = false,
        Notifications = true,
        Monitor = true,
        AntiMonitor = true,
        AntiFling = false,
        TouchFling = false,
    },
    LocalFlags = {},
    Connections = {},
    ToggleObjects = {},
    SliderObjects = {},
}

local function addConnection(connection)
    table.insert(State.Connections, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(State.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(State.Connections)
end

local function logError(where, message)
    State.ErrorCount += 1
    State.LastAction = "Error in " .. tostring(where)
    warn("[Aurora/" .. tostring(where) .. "] " .. tostring(message))
end

local function safe(where, callback)
    local ok, result = pcall(callback)
    if not ok then
        logError(where, result)
        return false, result
    end
    return true, result
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        local ok, err = pcall(function()
            object[property] = value
        end)
        if not ok then
            warn("[Aurora] Property " .. tostring(property) .. ": " .. tostring(err))
        end
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or CONFIG.Radius)
    }, parent)
end

local function outline(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or CONFIG.Accent,
        Transparency = transparency == nil and 0.65 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function listLayout(parent, direction, gap, horizontalAlignment)
    return create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 8),
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
    }, parent)
end

local function animate(object, duration, properties, style)
    if State.ReducedMotion or not State.Preferences.Animations then
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
        return nil
    end
    local info = TweenInfo.new(
        duration or CONFIG.AnimationSpeed,
        style or Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function text(parent, value, size, color, font, xAlignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or CONFIG.Text,
        TextSize = size or 12,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = xAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        RichText = false,
    }, parent)
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remaining = seconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, remaining)
    end
    return string.format("%02d:%02d", minutes, remaining)
end

local function countPlayers()
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            count += 1
        end
    end
    return count
end

local function viewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(900, 700)
end--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 2/6 — Root GUI, intro, window structure, drag, mini, notifications
================================================================================
]]

local old = PlayerGui:FindFirstChild("AuroraHubV10")
if old then
    old:Destroy()
end

local Screen = create("ScreenGui", {
    Name = "AuroraHubV10",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local Root = create("Frame", {
    Name = "Root",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(CONFIG.WindowWidth, CONFIG.WindowHeight),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, Screen)
corner(Root, 19)
outline(Root, CONFIG.Accent, 0.28, 1.35)

local RootScale = create("UIScale", { Scale = 1 }, Root)

local function updateResponsiveScale()
    local size = viewport()
    local scaleX = (size.X - 22) / CONFIG.WindowWidth
    local scaleY = (size.Y - 28) / CONFIG.WindowHeight
    local scale = math.clamp(math.min(scaleX, scaleY, 1), 0.46, 1)
    State.Scale = scale
    RootScale.Scale = scale
end

updateResponsiveScale()

addConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(updateResponsiveScale)
    local camera = workspace.CurrentCamera
    if camera then
        addConnection(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale))
    end
end))

local Intro
if CONFIG.ShowIntro then
    Intro = create("Frame", {
        Name = "Intro",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = CONFIG.Background,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, Screen)
    corner(Intro, 19)

    local introTitle = text(Intro, "A U R O R A", 25, CONFIG.Text, Enum.Font.GothamBlack)
    introTitle.AnchorPoint = Vector2.new(0.5, 0.5)
    introTitle.Position = UDim2.fromScale(0.5, 0.43)
    introTitle.Size = UDim2.new(0.8, 0, 0, 42)
    introTitle.TextXAlignment = Enum.TextXAlignment.Center
    introTitle.ZIndex = 101

    local introSub = text(Intro, "MOBILE INTERFACE  •  v" .. CONFIG.Version, 10, CONFIG.Muted)
    introSub.AnchorPoint = Vector2.new(0.5, 0.5)
    introSub.Position = UDim2.fromScale(0.5, 0.51)
    introSub.Size = UDim2.new(0.8, 0, 0, 22)
    introSub.TextXAlignment = Enum.TextXAlignment.Center
    introSub.ZIndex = 101

    local progressBack = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.62),
        Size = UDim2.new(0.62, 0, 0, 7),
        BackgroundColor3 = CONFIG.Surface3,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, Intro)
    corner(progressBack, 8)

    local progressFill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, progressBack)
    corner(progressFill, 8)

    local progressText = text(Intro, "INITIALIZING  0%", 9, CONFIG.Muted)
    progressText.AnchorPoint = Vector2.new(0.5, 0.5)
    progressText.Position = UDim2.fromScale(0.5, 0.68)
    progressText.Size = UDim2.new(0.8, 0, 0, 20)
    progressText.TextXAlignment = Enum.TextXAlignment.Center
    progressText.ZIndex = 101

    task.spawn(function()
        local steps = {12, 27, 44, 61, 78, 91, 100}
        for _, percent in ipairs(steps) do
            if State.Destroyed then return end
            animate(progressFill, 0.12, {Size = UDim2.new(percent / 100, 0, 1, 0)})
            progressText.Text = "INITIALIZING  " .. percent .. "%"
            task.wait(CONFIG.IntroDuration / #steps)
        end
        task.wait(0.12)
        if Intro and Intro.Parent then
            animate(Intro, 0.2, {BackgroundTransparency = 1})
            task.wait(0.22)
            Intro:Destroy()
        end
    end)
end

local Topbar = create("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0,
}, Root)

create("Frame", {
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = CONFIG.Accent,
    BorderSizePixel = 0,
}, Topbar)

local Brand = text(Topbar, "A U R O R A", 18, CONFIG.Text, Enum.Font.GothamBlack)
Brand.Position = UDim2.new(0, 19, 0, 9)
Brand.Size = UDim2.new(0, 210, 0, 28)

local BrandSub = text(Topbar, "MOBILE INTERFACE  •  v" .. CONFIG.Version, 9, CONFIG.Muted)
BrandSub.Position = UDim2.new(0, 20, 0, 38)
BrandSub.Size = UDim2.new(0, 240, 0, 15)

local ClockLabel = text(Topbar, "--:--", 10, CONFIG.Muted, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
ClockLabel.AnchorPoint = Vector2.new(1, 0.5)
ClockLabel.Position = UDim2.new(1, -112, 0.5, 0)
ClockLabel.Size = UDim2.new(0, 80, 0, 24)

local Minimize = create("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -17, 0.5, 0),
    Size = UDim2.fromOffset(38, 36),
    BackgroundColor3 = CONFIG.Surface3,
    Text = "—",
    TextColor3 = CONFIG.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    AutoButtonColor = false,
}, Topbar)
corner(Minimize, 10)

local Sidebar = create("Frame", {
    Name = "Sidebar",
    Position = UDim2.new(0, 11, 0, 80),
    Size = UDim2.new(0, 154, 1, -91),
    BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0,
}, Root)
corner(Sidebar, 14)
padding(Sidebar, 8, 8, 9, 9)

local SidebarScroll = create("ScrollingFrame", {
    Name = "Navigation",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = CONFIG.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Sidebar)
listLayout(SidebarScroll, Enum.FillDirection.Vertical, 6)

local ContentShell = create("Frame", {
    Name = "ContentShell",
    Position = UDim2.new(0, 176, 0, 80),
    Size = UDim2.new(1, -187, 1, -91),
    BackgroundColor3 = CONFIG.Surface,
    BorderSizePixel = 0,
}, Root)
corner(ContentShell, 14)

local PageTitle = text(ContentShell, "Dashboard", 16, CONFIG.Text, Enum.Font.GothamBold)
PageTitle.Position = UDim2.new(0, 15, 0, 9)
PageTitle.Size = UDim2.new(1, -30, 0, 25)

local PageHint = text(ContentShell, "Overview and quick actions", 9, CONFIG.Muted)
PageHint.Position = UDim2.new(0, 16, 0, 34)
PageHint.Size = UDim2.new(1, -30, 0, 17)

local PageScroll = create("ScrollingFrame", {
    Name = "PageScroll",
    Position = UDim2.new(0, 8, 0, 58),
    Size = UDim2.new(1, -16, 1, -66),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CONFIG.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, ContentShell)
padding(PageScroll, 7, 7, 6, 12)
local PageLayout = listLayout(PageScroll, Enum.FillDirection.Vertical, 9)

local dragging = false
local dragInput
local dragStart
local startPosition

Topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Root.Position
        dragInput = input
    end
end)

Topbar.InputEnded:Connect(function(input)
    if input == dragInput then
        dragging = false
        dragInput = nil
    end
end)

addConnection(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Root.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end))

local Mini = create("TextButton", {
    Name = "AuroraMini",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 15, 0.5, 0),
    Size = UDim2.fromOffset(56, 56),
    BackgroundColor3 = CONFIG.AccentDark,
    Text = "A",
    TextColor3 = CONFIG.Text,
    TextSize = 21,
    Font = Enum.Font.GothamBlack,
    Visible = false,
    AutoButtonColor = false,
}, Screen)
corner(Mini, 100)
outline(Mini, CONFIG.AccentBright, 0.1, 1.5)

local function minimizeWindow()
    if State.Minimized then return end
    State.Minimized = true
    animate(Root, 0.16, {BackgroundTransparency = 1})
    task.delay(0.16, function()
        if Root.Parent and State.Minimized then
            Root.Visible = false
            Mini.Visible = true
            Mini.Size = UDim2.fromOffset(10, 10)
            animate(Mini, 0.22, {Size = UDim2.fromOffset(56, 56)}, Enum.EasingStyle.Back)
        end
    end)
end

local function restoreWindow()
    State.Minimized = false
    Mini.Visible = false
    Root.Visible = true
    Root.BackgroundTransparency = 1
    animate(Root, 0.18, {BackgroundTransparency = 0})
end

Minimize.Activated:Connect(minimizeWindow)
Mini.Activated:Connect(restoreWindow)

local NotificationLayer = create("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -13, 0, 14),
    Size = UDim2.new(0, 265, 1, -28),
    BackgroundTransparency = 1,
}, Screen)
listLayout(NotificationLayer, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)

local function notify(title, message, kind)
    if not State.Notifications or not State.Modules.Notifications then
        return
    end
    local color = CONFIG.Accent
    if kind == "success" then color = CONFIG.Good end
    if kind == "warning" then color = CONFIG.Warning end
    if kind == "error" then color = CONFIG.Danger end

    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 69),
        BackgroundColor3 = CONFIG.Surface2,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
    }, NotificationLayer)
    corner(frame, 11)
    outline(frame, color, 0.38, 1)

    local bar = create("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.new(0, 8, 0, 9),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, frame)
    corner(bar, 4)

    local heading = text(frame, title, 11, CONFIG.Text, Enum.Font.GothamBold)
    heading.Position = UDim2.new(0, 19, 0, 8)
    heading.Size = UDim2.new(1, -28, 0, 20)

    local body = text(frame, message, 9, CONFIG.Muted)
    body.Position = UDim2.new(0, 19, 0, 29)
    body.Size = UDim2.new(1, -28, 0, 31)
    body.TextYAlignment = Enum.TextYAlignment.Top

    frame.Position = UDim2.new(1, 20, 0, 0)
    animate(frame, 0.2, {Position = UDim2.new(0, 0, 0, 0)})
    task.delay(3.2, function()
        if frame.Parent then
            animate(frame, 0.18, {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 25, 0, 0),
            })
            task.wait(0.2)
            if frame.Parent then frame:Destroy() end
        end
    end)
end--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 3/6 — UI components + navigation
================================================================================
]]

local function clearPage()
    for _, child in ipairs(PageScroll:GetChildren()) do
        if child ~= PageLayout then
            child:Destroy()
        end
    end
    table.clear(State.ToggleObjects)
    table.clear(State.SliderObjects)
end

local function section(title, description)
    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, description and 45 or 27),
    }, PageScroll)
    local heading = text(holder, title, 13, CONFIG.Text, Enum.Font.GothamBold)
    heading.Size = UDim2.new(1, 0, 0, 22)
    if description then
        local sub = text(holder, description, 9, CONFIG.Muted)
        sub.Position = UDim2.new(0, 0, 0, 23)
        sub.Size = UDim2.new(1, 0, 0, 19)
    end
    return holder
end

local function card(height)
    local frame = create("Frame", {
        BackgroundColor3 = CONFIG.Surface2,
        Size = UDim2.new(1, 0, 0, height or 58),
        BorderSizePixel = 0,
    }, PageScroll)
    corner(frame, 11)
    return frame
end

local function cardLabel(parent, value, position, size, fontSize, color, font)
    local item = text(parent, value, fontSize or 11, color or CONFIG.Text, font)
    item.Position = position or UDim2.new(0, 12, 0, 0)
    item.Size = size or UDim2.new(1, -24, 1, 0)
    return item
end

local function actionButton(parent, caption, callback, width)
    local button = create("TextButton", {
        Size = UDim2.new(0, width or 110, 0, 35),
        BackgroundColor3 = CONFIG.Surface3,
        BorderSizePixel = 0,
        Text = caption,
        TextColor3 = CONFIG.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
    }, parent)
    corner(button, 9)
    outline(button, CONFIG.Accent, 0.78, 1)

    button.MouseEnter:Connect(function()
        animate(button, 0.1, {BackgroundColor3 = Color3.fromRGB(53, 45, 72)})
    end)
    button.MouseLeave:Connect(function()
        animate(button, 0.1, {BackgroundColor3 = CONFIG.Surface3})
    end)
    button.Activated:Connect(function()
        State.ActionCount += 1
        State.LastAction = caption
        safe("button:" .. caption, callback)
    end)
    return button
end

local function toggle(title, description, key, callback)
    local row = card(62)
    cardLabel(row, title, UDim2.new(0, 12, 0, 6), UDim2.new(1, -100, 0, 20), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    if description then
        cardLabel(row, description, UDim2.new(0, 12, 0, 29), UDim2.new(1, -100, 0, 24), 8, CONFIG.Muted)
    end
    local switch = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(48, 26),
        BackgroundColor3 = State.Preferences[key] and CONFIG.Accent or CONFIG.Surface3,
        Text = "",
        AutoButtonColor = false,
    }, row)
    corner(switch, 20)
    local knob = create("Frame", {
        Position = State.Preferences[key] and UDim2.new(1, -22, 0, 4) or UDim2.new(0, 4, 0, 4),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, switch)
    corner(knob, 20)

    local function refresh()
        local enabled = State.Preferences[key] == true
        animate(switch, 0.14, {
            BackgroundColor3 = enabled and CONFIG.Accent or CONFIG.Surface3
        })
        animate(knob, 0.14, {
            Position = enabled and UDim2.new(1, -22, 0, 4) or UDim2.new(0, 4, 0, 4)
        })
    end

    switch.Activated:Connect(function()
        State.Preferences[key] = not State.Preferences[key]
        refresh()
        if callback then callback(State.Preferences[key]) end
    end)
    State.ToggleObjects[key] = refresh
    return row
end

local function slider(title, key, minimum, maximum, suffix, callback)
    local row = card(75)
    cardLabel(row, title, UDim2.new(0, 12, 0, 6), UDim2.new(0.7, 0, 0, 19), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    local valueText = cardLabel(row, "", UDim2.new(1, -96, 0, 6), UDim2.new(0, 84, 0, 19), 10, CONFIG.AccentBright, Enum.Font.GothamBold)
    valueText.TextXAlignment = Enum.TextXAlignment.Right

    local track = create("TextButton", {
        Position = UDim2.new(0, 12, 0, 43),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = CONFIG.Surface3,
        Text = "",
        AutoButtonColor = false,
    }, row)
    corner(track, 8)
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 8)

    local current = State.LocalFlags[key]
    if current == nil then current = minimum end

    local function setValue(value)
        value = math.clamp(value, minimum, maximum)
        if suffix == " px" or suffix == " studs" then
            value = math.floor(value + 0.5)
        else
            value = math.floor(value * 100 + 0.5) / 100
        end
        State.LocalFlags[key] = value
        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        valueText.Text = tostring(value) .. (suffix or "")
        if callback then callback(value) end
    end

    setValue(current)

    local sliding = false
    local function fromInput(input)
        local alpha = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        setValue(minimum + math.clamp(alpha, 0, 1) * (maximum - minimum))
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            fromInput(input)
        end
    end)

    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    local connection = UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    addConnection(connection)
    State.SliderObjects[key] = setValue
    return row
end

local function dropdown(title, key, options, callback)
    local row = card(76)
    cardLabel(row, title, UDim2.new(0, 12, 0, 5), UDim2.new(1, -24, 0, 20), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    local selector = create("TextButton", {
        Position = UDim2.new(0, 11, 0, 34),
        Size = UDim2.new(1, -22, 0, 32),
        BackgroundColor3 = CONFIG.Surface3,
        BorderSizePixel = 0,
        Text = tostring(State.LocalFlags[key] or options[1]) .. "   ▾",
        TextColor3 = CONFIG.Text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
    }, row)
    corner(selector, 8)
    local index = 1
    for i, option in ipairs(options) do
        if option == State.LocalFlags[key] then index = i end
    end
    selector.Activated:Connect(function()
        index += 1
        if index > #options then index = 1 end
        State.LocalFlags[key] = options[index]
        selector.Text = tostring(options[index]) .. "   ▾"
        if callback then callback(options[index]) end
    end)
    return row
end

local function infoCard(title, body, height)
    local row = card(height or 76)
    cardLabel(row, title, UDim2.new(0, 12, 0, 7), UDim2.new(1, -24, 0, 19), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    cardLabel(row, body, UDim2.new(0, 12, 0, 29), UDim2.new(1, -24, 1, -35), 9, CONFIG.Muted)
    return row
end

local function metricCard(title, value, accent)
    local row = card(73)
    local left = text(row, title, 9, CONFIG.Muted, Enum.Font.GothamMedium)
    left.Position = UDim2.new(0, 12, 0, 9)
    left.Size = UDim2.new(1, -24, 0, 18)
    local right = text(row, value, 19, accent or CONFIG.Text, Enum.Font.GothamBold)
    right.Position = UDim2.new(0, 12, 0, 30)
    right.Size = UDim2.new(1, -24, 0, 29)
    return right
end

local NAVIGATION = {
    {Name = "Dashboard",     Icon = "⌂", Hint = "Overview and quick actions"},
    {Name = "Monitor",       Icon = "◈", Hint = "Local activity and diagnostics"},
    {Name = "Anti-Monitor",  Icon = "⚠", Hint = "Heuristic risk scan (local-only)"},
    {Name = "Visuals",       Icon = "◉", Hint = "Visual preferences and QA hooks"},
    {Name = "Aim Lab",       Icon = "⌖", Hint = "Aim training integration area"},
    {Name = "Player",        Icon = "◎", Hint = "Player information and QA tools"},
    {Name = "Movement",      Icon = "↗", Hint = "Anti-fling and movement QA"},
    {Name = "Profiles",      Icon = "▤", Hint = "Local configuration profiles"},
    {Name = "Settings",      Icon = "⚙", Hint = "Interface preferences"},
    {Name = "Diagnostics",   Icon = "⌁", Hint = "Runtime checks and information"},
}

local NavigationButtons = {}

local function makeNavigationButton(entry, order)
    local button = create("TextButton", {
        Name = entry.Name:gsub("%s+", ""),
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = entry.Name == State.Page and CONFIG.AccentDark or CONFIG.Surface2,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
    }, SidebarScroll)
    corner(button, 9)

    local activeBar = create("Frame", {
        Name = "ActiveBar",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0, entry.Name == State.Page and 22 or 0),
        BackgroundColor3 = CONFIG.AccentBright,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, button)
    corner(activeBar, 2)

    local icon = text(button, entry.Icon, 15, CONFIG.AccentBright, Enum.Font.GothamBold)
    icon.Position = UDim2.new(0, 10, 0, 0)
    icon.Size = UDim2.new(0, 23, 1, 0)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local caption = text(button, entry.Name, 10, CONFIG.Text, Enum.Font.GothamSemibold)
    caption.Position = UDim2.new(0, 39, 0, 0)
    caption.Size = UDim2.new(1, -45, 1, 0)

    button.Activated:Connect(function()
        State.Page = entry.Name
        State.ActionCount += 1
        State.LastAction = "Opened " .. entry.Name
        if State.RenderPage then
            State.RenderPage(entry.Name)
        end
    end)

    NavigationButtons[entry.Name] = button
end

for index, entry in ipairs(NAVIGATION) do
    makeNavigationButton(entry, index)
end--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 4/6 — Anti-Monitor core + Anti-Fling core
================================================================================
]]

local RiskState = {
    Place = {Id = game.PlaceId, Name = "—", Creator = "—", JobId = "—"},
    DetectionScore = 0,
    Indicators = {},
    FeatureRisks = {},
    ScanCount = 0,
    ScanRunning = false,
}

local FEATURE_DEFS = {
    {id = "visuals",   name = "Visual overlays (ESP, boxes)",  base = 10,
     note = "Rendered locally. Server cannot see client GUI."},
    {id = "cameraAim", name = "Camera-only aim assist",        base = 40,
     note = "Only visible if server logs view direction."},
    {id = "speed",     name = "Movement speed boost",          base = 55,
     note = "Position delta is a standard server check."},
    {id = "fly",       name = "Fly / PlatformStand",           base = 70,
     note = "Vertical velocity anomalies are easy to flag."},
    {id = "teleport",  name = "Teleport (CFrame shift)",       base = 65,
     note = "Range checks on movement are common."},
    {id = "noclip",    name = "Noclip / collision bypass",     base = 60,
     note = "Region/hitbox validators trip on wall-clip."},
    {id = "autofarm",  name = "Auto-farm / auto-clicker",      base = 75,
     note = "Repetitive timing is trivially detectable."},
    {id = "remote",    name = "Remote call spam",              base = 85,
     note = "Rate limits and server-side replay catch this."},
    {id = "statEdit",  name = "Character stat edits",          base = 50,
     note = "Server may re-validate health/speed/inventory."},
    {id = "serverX",   name = "Server-side exploit (remote abuse)", base = 95,
     note = "Server logs everything. Ban is when, not if."},
    {id = "fling",     name = "Touch-fling (other players)",   base = 90,
     note = "Forced movement of another client. Griefing class, ToS violation."},
    {id = "antiFling", name = "Anti-fling (self-defense)",     base = 5,
     note = "Protects your own character. Defensive, no other player affected."},
}

local function riskColor(score)
    if score <= 25 then return CONFIG.Good,     "LOW"      end
    if score <= 50 then return CONFIG.Warning,  "MODERATE" end
    if score <= 75 then return CONFIG.Danger,   "HIGH"     end
    return CONFIG.Critical, "CRITICAL"
end

local function fetchPlaceInfo()
    local place = {
        Id = game.PlaceId,
        JobId = (game.JobId ~= "" and game.JobId) or "public",
        Name = "Unknown place",
        Creator = "Unknown creator",
    }
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info then
        place.Name = info.Name or place.Name
        if info.Creator and info.Creator.Name then
            place.Creator = info.Creator.Name
        end
    end
    return place
end

local function scanDetectionSurface()
    local score, indicators = 0, {}
    local patterns = {
        {sub = "anticheat",     label = "Anti-cheat module",     weight = 30},
        {sub = "anti_cheat",    label = "Anti-cheat module",     weight = 30},
        {sub = "anti-exploit",  label = "Anti-exploit module",   weight = 30},
        {sub = "krnl",          label = "Exploit watcher",       weight = 40},
        {sub = "synapse",       label = "Exploit watcher",       weight = 40},
        {sub = "detect",        label = "Detection routine",     weight = 15},
        {sub = "adonis",        label = "Adonis admin",          weight = 45},
        {sub = "hd admin",      label = "HD Admin",              weight = 35},
        {sub = "kohls",         label = "Kohl's Admin",          weight = 40},
        {sub = "speedcheck",    label = "Speed validator",       weight = 30},
        {sub = "positioncheck", label = "Position validator",    weight = 30},
        {sub = "monitor",       label = "Monitoring script",     weight = 10},
    }
    local scanned, seen = 0, {}
    for _, obj in ipairs(game:GetDescendants()) do
        scanned += 1
        if scanned > 8000 then break end
        local name = obj.Name
        if type(name) == "string" and #name > 2 then
            local lower = name:lower()
            for _, p in ipairs(patterns) do
                if lower:find(p.sub, 1, true) and not seen[p.label .. obj:GetFullName()] then
                    seen[p.label .. obj:GetFullName()] = true
                    table.insert(indicators, {label = p.label, name = name, weight = p.weight})
                    score += p.weight
                    break
                end
            end
        end
    end
    return math.min(score, 200), indicators
end

local function placeRiskMultiplier(placeName)
    local lower = placeName:lower()
    local table_ = {
        {sub = "obby",         add = -10},
        {sub = "tycoon",       add = -5},
        {sub = "simulator",    add = -8},
        {sub = "shooter",      add = 15},
        {sub = "fps",          add = 12},
        {sub = "arena",        add = 10},
        {sub = "ranked",       add = 18},
        {sub = "competitive",  add = 18},
        {sub = "combat",       add = 10},
        {sub = "battleground", add = 10},
        {sub = "prison",       add = 8},
    }
    local delta = 0
    for _, m in ipairs(table_) do
        if lower:find(m.sub, 1, true) then delta += m.add end
    end
    return delta
end

local function computeFeatureRisks(detectionScore, placeMult)
    local out = {}
    for _, f in ipairs(FEATURE_DEFS) do
        local s = f.base + math.min(detectionScore * 0.35, 40) + placeMult
        s = math.clamp(s, 0, 100)
        table.insert(out, {id = f.id, name = f.name, note = f.note, score = s})
    end
    return out
end

------------------------------- ANTI-FLING CORE -------------------------------

local AntiFling = {
    Enabled = false,
    VelocityThreshold = 150,
    AngularThreshold = 200,
    PositionBound = 5000,
    Connections = {},
    LastGoodPos = nil,
}

local function getHumanoidRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function stopAntiFling()
    AntiFling.Enabled = false
    for _, c in ipairs(AntiFling.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(AntiFling.Connections)
end

local function startAntiFling()
    if AntiFling.Enabled then return end
    local hrp = getHumanoidRoot()
    if not hrp then
        notify("Anti-Fling", "Character not loaded yet.", "warning")
        return
    end
    AntiFling.Enabled = true
    AntiFling.LastGoodPos = hrp.Position

    local conn = RunService.Heartbeat:Connect(function()
        if not AntiFling.Enabled or State.Destroyed then return end
        local root = getHumanoidRoot()
        if not root then return end

        local v = root.AssemblyLinearVelocity
        if v.Magnitude > AntiFling.VelocityThreshold then
            root.AssemblyLinearVelocity = Vector3.zero
        end

        local av = root.AssemblyAngularVelocity
        if av.Magnitude > AntiFling.AngularThreshold then
            root.AssemblyAngularVelocity = Vector3.zero
        end

        local pos = root.Position
        if math.abs(pos.X) > AntiFling.PositionBound
            or math.abs(pos.Y) > AntiFling.PositionBound
            or math.abs(pos.Z) > AntiFling.PositionBound then
            if AntiFling.LastGoodPos then
                root.CFrame = CFrame.new(AntiFling.LastGoodPos)
            end
        else
            AntiFling.LastGoodPos = pos
        end
    end)
    table.insert(AntiFling.Connections, conn)

    local charConn = LocalPlayer.CharacterAdded:Connect(function()
        if AntiFling.Enabled then
            task.wait(0.6)
            local wasEnabled = true
            stopAntiFling()
            if wasEnabled then startAntiFling() end
        end
    end)
    table.insert(AntiFling.Connections, charConn)
end

local function setAntiFling(enabled)
    if enabled then
        startAntiFling()
        State.Modules.AntiFling = true
    else
        stopAntiFling()
        State.Modules.AntiFling = false
    end
end--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 5/6 — Page renderers
================================================================================
]]

local function renderDashboard()
    section("Welcome back", "Aurora is ready. Your local session is active.")
    local playerCard = card(88)
    local avatar = create("ImageLabel", {
        Position = UDim2.new(0, 12, 0, 13),
        Size = UDim2.fromOffset(58, 58),
        BackgroundColor3 = CONFIG.Surface3,
        BorderSizePixel = 0,
        Image = "",
    }, playerCard)
    corner(avatar, 14)
    safe("avatar thumbnail", function()
        local image = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
        avatar.Image = image
    end)
    cardLabel(playerCard, LocalPlayer.DisplayName, UDim2.new(0, 81, 0, 17), UDim2.new(1, -95, 0, 23), 13, CONFIG.Text, Enum.Font.GothamBold)
    cardLabel(playerCard, "@" .. LocalPlayer.Name .. "  •  Local session", UDim2.new(0, 82, 0, 42), UDim2.new(1, -95, 0, 20), 9, CONFIG.Muted)

    section("Session overview")
    local metrics = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 82),
    }, PageScroll)
    create("UIGridLayout", {
        CellSize = UDim2.new(0.48, 0, 0, 73),
        CellPadding = UDim2.new(0.03, 0, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, metrics)
    local sessionMetric = metricCard("SESSION TIME", "00:00", CONFIG.AccentBright)
    sessionMetric.Parent = metrics
    local playerMetric = metricCard("OTHER PLAYERS", tostring(countPlayers()), CONFIG.Text)
    playerMetric.Parent = metrics

    section("Quick navigation")
    local quick = card(56)
    local monitorButton = actionButton(quick, "Open Monitor", function()
        State.RenderPage("Monitor")
    end, 112)
    monitorButton.Position = UDim2.new(0, 10, 0, 10)
    local antiButton = actionButton(quick, "Anti-Monitor", function()
        State.RenderPage("Anti-Monitor")
    end, 100)
    antiButton.Position = UDim2.new(0, 132, 0, 10)

    infoCard(
        "Build information",
        "v" .. CONFIG.Version .. " • Anti-Fling self-defense • Anti-Monitor heuristic scan. Game-specific features require your own authorized experience.",
        72
    )

    State.DashboardSessionMetric = sessionMetric
    State.DashboardPlayerMetric = playerMetric
end

local function renderMonitor()
    section("Local Monitor", "Live information from this client UI. No server connection.")
    local uptime = metricCard("SESSION UPTIME", "00:00", CONFIG.Good)
    local players = metricCard("OTHER PLAYERS IN CLIENT", tostring(countPlayers()), CONFIG.Text)
    local errors = metricCard("LOCAL SCRIPT ERRORS", tostring(State.ErrorCount), CONFIG.Good)
    local actions = metricCard("UI ACTIONS", tostring(State.ActionCount), CONFIG.AccentBright)

    State.MonitorMetrics = {
        Uptime = uptime,
        Players = players,
        Errors = errors,
        Actions = actions,
    }

    section("Module states")
    for moduleName, enabled in pairs(State.Modules) do
        local row = card(45)
        cardLabel(row, moduleName, UDim2.new(0, 12, 0, 0), UDim2.new(0.62, 0, 1, 0), 10, CONFIG.Text)
        local status = cardLabel(row, enabled and "AVAILABLE / ON" or "IDLE / OFF",
            UDim2.new(0.62, 0, 0, 0), UDim2.new(0.34, -10, 1, 0), 9,
            enabled and CONFIG.Good or CONFIG.Muted, Enum.Font.GothamBold)
        status.TextXAlignment = Enum.TextXAlignment.Right
    end

    section("Activity estimate")
    infoCard(
        "What this monitor can see",
        "UI settings, local module flags, player count exposed to this client, uptime and errors recorded by this interface.",
        72
    )
    infoCard(
        "What this monitor cannot see",
        "Hidden server anti-cheat checks, moderation systems, private server telemetry. No risk percentage is fabricated.",
        82
    )

    local reset = card(54)
    local resetButton = actionButton(reset, "Clear local error counter", function()
        State.ErrorCount = 0
        notify("Monitor", "Local error counter cleared.", "success")
        State.RenderPage("Monitor")
    end, 180)
    resetButton.Position = UDim2.new(0, 11, 0, 9)
end

local function renderAntiMonitor()
    if RiskState.ScanCount == 0 and not RiskState.ScanRunning then
        RiskState.ScanRunning = true
        task.spawn(function()
            RiskState.Place = fetchPlaceInfo()
            RiskState.DetectionScore, RiskState.Indicators = scanDetectionSurface()
            local mult = placeRiskMultiplier(RiskState.Place.Name)
            RiskState.FeatureRisks = computeFeatureRisks(RiskState.DetectionScore, mult)
            RiskState.ScanCount += 1
            RiskState.ScanRunning = false
            if State.Page == "Anti-Monitor" and not State.Destroyed then
                State.RenderPage("Anti-Monitor")
            end
        end)
    end

    section("Anti-Monitor",
        "Heuristic risk indicators. This is NOT real anti-cheat detection.")

    local placeCard = card(114)
    cardLabel(placeCard, "CURRENT PLACE",
        UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 16), 9, CONFIG.Muted)
    cardLabel(placeCard, RiskState.Place.Name,
        UDim2.new(0, 12, 0, 24), UDim2.new(1, -24, 0, 22), 13, CONFIG.Text, Enum.Font.GothamBold)
    cardLabel(placeCard, "by " .. RiskState.Place.Creator,
        UDim2.new(0, 12, 0, 48), UDim2.new(1, -24, 0, 16), 9, CONFIG.Muted)
    cardLabel(placeCard,
        "PlaceId " .. tostring(RiskState.Place.Id) .. "  •  JobId " .. tostring(RiskState.Place.JobId),
        UDim2.new(0, 12, 0, 68), UDim2.new(1, -24, 0, 16), 9, CONFIG.Muted)
    local scanInfo = RiskState.ScanCount > 0
        and string.format("%d indicators  •  raw score %d", #RiskState.Indicators, RiskState.DetectionScore)
        or "no scan data yet"
    cardLabel(placeCard, scanInfo,
        UDim2.new(0, 12, 0, 88), UDim2.new(1, -24, 0, 16), 9, CONFIG.AccentBright)

    local overall = 0
    for _, r in ipairs(RiskState.FeatureRisks) do overall += r.score end
    if #RiskState.FeatureRisks > 0 then
        overall = math.floor(overall / #RiskState.FeatureRisks)
    end
    local oColor, oLabel = riskColor(overall)

    local overallCard = card(72)
    cardLabel(overallCard, "AVERAGE RISK ACROSS FEATURES",
        UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 16), 9, CONFIG.Muted)
    local overallValue = text(overallCard, oLabel .. "   " .. overall .. "%",
        18, oColor, Enum.Font.GothamBold)
    overallValue.Position = UDim2.new(0, 12, 0, 26)
    overallValue.Size = UDim2.new(1, -24, 0, 26)

    local actionCard = card(55)
    local refreshBtn = actionButton(actionCard, "Run detection scan", function()
        if RiskState.ScanRunning then
            notify("Anti-Monitor", "Scan already running.", "warning")
            return
        end
        RiskState.ScanRunning = true
        notify("Anti-Monitor", "Scanning place...", "success")
        task.spawn(function()
            RiskState.Place = fetchPlaceInfo()
            RiskState.DetectionScore, RiskState.Indicators = scanDetectionSurface()
            local mult = placeRiskMultiplier(RiskState.Place.Name)
            RiskState.FeatureRisks = computeFeatureRisks(RiskState.DetectionScore, mult)
            RiskState.ScanCount += 1
            RiskState.ScanRunning = false
            notify("Anti-Monitor",
                string.format("Scan done: %d indicators", #RiskState.Indicators), "success")
            if State.Page == "Anti-Monitor" then State.RenderPage("Anti-Monitor") end
        end)
    end, 160)
    refreshBtn.Position = UDim2.new(0, 10, 0, 10)

    local resetBtn = actionButton(actionCard, "Reset", function()
        RiskState.DetectionScore = 0
        RiskState.Indicators = {}
        RiskState.FeatureRisks = {}
        RiskState.ScanCount = 0
        RiskState.ScanRunning = false
        notify("Anti-Monitor", "Scan data cleared.", "success")
        State.RenderPage("Anti-Monitor")
    end, 90)
    resetBtn.Position = UDim2.new(0, 178, 0, 10)

    if #RiskState.Indicators > 0 then
        section("Detection surface indicators",
            string.format("%d suspicious scripts found", #RiskState.Indicators))
        for i, ind in ipairs(RiskState.Indicators) do
            if i > 6 then break end
            local row = card(44)
            cardLabel(row, ind.label,
                UDim2.new(0, 12, 0, 0), UDim2.new(0.55, 0, 1, 0), 10, CONFIG.Text, Enum.Font.GothamSemibold)
            local nameLabel = cardLabel(row, ind.name,
                UDim2.new(0.55, 0, 0, 0), UDim2.new(0.30, 0, 1, 0), 9, CONFIG.Muted)
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            local weightLabel = cardLabel(row, "+" .. ind.weight,
                UDim2.new(0.85, 0, 0, 0), UDim2.new(0.15, -10, 1, 0), 10,
                CONFIG.Warning, Enum.Font.GothamBold)
            weightLabel.TextXAlignment = Enum.TextXAlignment.Right
        end
    end

    section("Per-feature ban risk",
        "Feature type + place characteristics. Not actual anti-cheat data.")
    if #RiskState.FeatureRisks == 0 then
        infoCard("No scan data yet",
            "Auto-scan runs on first visit. If it's stuck, press \"Run detection scan\" above.",
            58)
    else
        for _, feat in ipairs(RiskState.FeatureRisks) do
            local row = card(72)
            local color, label = riskColor(feat.score)
            cardLabel(row, feat.name,
                UDim2.new(0, 12, 0, 6), UDim2.new(1, -110, 0, 18), 10, CONFIG.Text, Enum.Font.GothamSemibold)
            local scoreLabel = cardLabel(row, label .. "  " .. feat.score .. "%",
                UDim2.new(1, -110, 0, 6), UDim2.new(0, 98, 0, 18), 10, color, Enum.Font.GothamBold)
            scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
            local track = create("Frame", {
                Position = UDim2.new(0, 12, 0, 30),
                Size = UDim2.new(1, -24, 0, 6),
                BackgroundColor3 = CONFIG.Surface3,
                BorderSizePixel = 0,
            }, row)
            corner(track, 6)
            local fill = create("Frame", {
                Size = UDim2.new(feat.score / 100, 0, 1, 0),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
            }, track)
            corner(fill, 6)
            cardLabel(row, feat.note,
                UDim2.new(0, 12, 0, 42), UDim2.new(1, -24, 0, 24), 8, CONFIG.Muted)
        end
    end

    section("Reality check")
    infoCard("What this page actually does",
        "Reads local game instance, scans for common anti-cheat/admin script names, combines with per-feature risk table. Client-side only.",
        76)
    infoCard("What it cannot do",
        "Cannot see server checks, remote logs, moderation queues, or real ban probability. LOW does not mean safe. HIGH does not mean banned.",
        76)
end

local function renderVisuals()
    section("Visual preferences", "Interface-side options and safe QA integration points.")
    toggle("Accent glow", "Use the accent style across the interface.", "AccentGlow")
    toggle("Show hints", "Display helper text under controls.", "ShowHints")
    toggle("Compact sidebar", "Preference flag for a future compact navigation layout.", "CompactSidebar")
    toggle("Card blur preference", "Local preference flag; no external effects.", "BlurCards")
    dropdown("Accent preset", "AccentPreset", {"Blue", "Violet", "Pink", "Mint"}, function(value)
        local palette = {
            Violet = Color3.fromRGB(164, 104, 255),
            Blue = Color3.fromRGB(124, 160, 255),
            Pink = Color3.fromRGB(255, 104, 190),
            Mint = Color3.fromRGB(83, 220, 180),
        }
        CONFIG.Accent = palette[value]
        notify("Theme", value .. " selected. Reopen the page to refresh accents.", "success")
    end)
    infoCard(
        "Developer integration",
        "A real player overlay should be implemented inside the developer's own Roblox experience with server-approved test permissions.",
        90
    )
end

local function renderAimLab()
    section("Aim Lab", "Configuration surface for an authorized aim-training module.")
    infoCard(
        "Integration slot",
        "UI shell only. Does not lock camera onto players or target characters in third-party games.",
        84
    )
    slider("Practice FOV display", "PracticeFOV", 30, 350, " px")
    slider("Practice sensitivity", "PracticeSensitivity", 0.05, 1, "")
    dropdown("Practice target dummy", "PracticeDummy", {"Center", "Upper", "Lower"})
    toggle("Show practice guide", "Local preference for a training overlay in your own place.", "ShowHints")
    infoCard(
        "How to connect it safely",
        "In your own experience, create a dedicated training target and route selected settings to your training controller.",
        83
    )
end

local function renderPlayer()
    section("Player", "Local player information and client-visible session details.")
    local identity = card(76)
    cardLabel(identity, LocalPlayer.DisplayName, UDim2.new(0, 12, 0, 10), UDim2.new(1, -24, 0, 22), 13, CONFIG.Text, Enum.Font.GothamBold)
    cardLabel(identity, "Username: @" .. LocalPlayer.Name, UDim2.new(0, 12, 0, 36), UDim2.new(1, -24, 0, 18), 9, CONFIG.Muted)

    local playerId = card(49)
    cardLabel(playerId, "UserId", UDim2.new(0, 12, 0, 0), UDim2.new(0.45, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(playerId, tostring(LocalPlayer.UserId), UDim2.new(0.45, 0, 0, 0), UDim2.new(0.5, -10, 1, 0), 10, CONFIG.Text, Enum.Font.GothamBold)

    local teamCard = card(49)
    cardLabel(teamCard, "Team", UDim2.new(0, 12, 0, 0), UDim2.new(0.45, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(teamCard, LocalPlayer.Team and LocalPlayer.Team.Name or "No team", UDim2.new(0.45, 0, 0, 0), UDim2.new(0.5, -10, 1, 0), 10, CONFIG.Text, Enum.Font.GothamBold)

    infoCard(
        "Player QA slot",
        "This area can host admin and QA controls for a game you own. No fling, forced movement of other players, or unauthorized character manipulation.",
        85
    )
end

local function renderMovement()
    section("Movement QA", "Self-defense and movement tests.")

    local afCard = card(90)
    cardLabel(afCard, "Anti-Fling",
        UDim2.new(0, 12, 0, 6), UDim2.new(1, -100, 0, 20), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    cardLabel(afCard, "Zeroes extreme velocity/angular velocity on your own character. Auto-resets to last safe position if you're pushed out of bounds. Defensive only.",
        UDim2.new(0, 12, 0, 29), UDim2.new(1, -100, 0, 48), 8, CONFIG.Muted)

    local afSwitch = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(48, 26),
        BackgroundColor3 = AntiFling.Enabled and CONFIG.Accent or CONFIG.Surface3,
        Text = "",
        AutoButtonColor = false,
    }, afCard)
    corner(afSwitch, 20)

    local afKnob = create("Frame", {
        Position = AntiFling.Enabled and UDim2.new(1, -22, 0, 4) or UDim2.new(0, 4, 0, 4),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, afSwitch)
    corner(afKnob, 20)

    afSwitch.Activated:Connect(function()
        local enabled = not AntiFling.Enabled
        setAntiFling(enabled)
        animate(afSwitch, 0.14, {
            BackgroundColor3 = enabled and CONFIG.Accent or CONFIG.Surface3
        })
        animate(afKnob, 0.14, {
            Position = enabled and UDim2.new(1, -22, 0, 4) or UDim2.new(0, 4, 0, 4)
        })
        notify("Anti-Fling", enabled and "Enabled." or "Disabled.",
            enabled and "success" or "warning")
    end)

    local statusCard = card(49)
    cardLabel(statusCard, "Anti-Fling status",
        UDim2.new(0, 12, 0, 0), UDim2.new(0.55, 0, 1, 0), 10, CONFIG.Muted)
    local statusLabel = cardLabel(statusCard,
        AntiFling.Enabled and "ACTIVE" or "INACTIVE",
        UDim2.new(0.55, 0, 0, 0), UDim2.new(0.42, -10, 1, 0), 10,
        AntiFling.Enabled and CONFIG.Good or CONFIG.Muted, Enum.Font.GothamBold)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right

    section("Touch-Fling", "UI slot only. Not implemented for other players.")
    infoCard(
        "Why this is a slot",
        "Forced movement of other clients is griefing class and a ToS violation. Working code is not included. For your own authorized test place, wire it to your own training target controller.",
        90
    )

    local flingCard = card(62)
    cardLabel(flingCard, "Touch-Fling",
        UDim2.new(0, 12, 0, 6), UDim2.new(1, -100, 0, 20), 11, CONFIG.Text, Enum.Font.GothamSemibold)
    cardLabel(flingCard, "Disabled in this build. Authorized test place integration only.",
        UDim2.new(0, 12, 0, 29), UDim2.new(1, -100, 0, 24), 8, CONFIG.Muted)

    local flingSwitch = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(48, 26),
        BackgroundColor3 = CONFIG.Surface3,
        Text = "",
        AutoButtonColor = false,
    }, flingCard)
    corner(flingSwitch, 20)

    local flingKnob = create("Frame", {
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, flingSwitch)
    corner(flingKnob, 20)

    flingSwitch.Activated:Connect(function()
        notify("Touch-Fling", "Not available in this build. See Movement note.", "warning")
    end)

    section("Movement QA controls")
    dropdown("Movement test preset", "MovementPreset", {"Walk test", "Jump test", "Obstacle course"})
    slider("Local test value", "MovementTestValue", 1, 100, "")
    toggle("Show movement test hints", "Remember whether to show QA instructions.", "ShowHints")

    infoCard(
        "Developer path",
        "For your own place, implement movement test controls in server-authorized scripts and validate permissions on the server. Client-only UI state is not an authority boundary.",
        88
    )
end--[[
================================================================================
 A U R O R A   H U B   v10.1
 Part 6/6 — Profiles, Settings, Diagnostics, registry, live monitor, cleanup
================================================================================
]]

local function renderProfiles()
    section("Profiles", "Local profile selector for interface preferences.")
    local current = card(55)
    cardLabel(current, "Current profile", UDim2.new(0, 12, 0, 0), UDim2.new(0.48, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(current, State.ProfileName, UDim2.new(0.48, 0, 0, 0), UDim2.new(0.45, 0, 1, 0), 11, CONFIG.AccentBright, Enum.Font.GothamBold)

    dropdown("Select local profile", "ProfileSelector", {"Default", "Mobile", "Minimal", "QA"}, function(value)
        State.ProfileName = value
        notify("Profiles", "Selected " .. value .. " profile.", "success")
    end)

    local profileActions = card(55)
    local save = actionButton(profileActions, "Save snapshot", function()
        State.LocalFlags.LastSnapshot = os.time()
        notify("Profiles", "Local settings snapshot prepared for this session.", "success")
    end, 115)
    save.Position = UDim2.new(0, 10, 0, 9)

    local reset = actionButton(profileActions, "Reset UI flags", function()
        State.LocalFlags.LastReset = os.time()
        State.Preferences = {
            CompactSidebar = false, ShowClock = true, ShowFPS = true,
            ShowSession = true, BlurCards = false, Animations = true,
            AccentGlow = true, ShowHints = true, ConfirmReset = true,
            AutoSave = false,
        }
        notify("Profiles", "Interface preferences reset.", "success")
        State.RenderPage("Profiles")
    end, 110)
    reset.Position = UDim2.new(0, 135, 0, 9)

    infoCard(
        "Persistence note",
        "This build keeps settings in memory for the current session. Durable file storage varies by execution environment.",
        72
    )
end

local function renderSettings()
    section("Settings", "Tune the interface for your device.")
    toggle("Animations", "Enable smooth transitions and button feedback.", "Animations")
    toggle("Show clock", "Display the local session clock in the top bar.", "ShowClock")
    toggle("Show FPS", "Display client frame rate in the monitor.", "ShowFPS")
    toggle("Show session time", "Display elapsed session time in the dashboard.", "ShowSession")
    toggle("Notifications", "Allow Aurora interface notifications.", "Notifications", function(value)
        State.Notifications = value
    end)
    toggle("Confirm reset", "Keep a confirmation preference for reset actions.", "ConfirmReset")
    toggle("Auto-save preference", "Local flag only; no file is written automatically.", "AutoSave")
    slider("UI scale", "UIScale", 0.75, 1.15, "", function(value)
        RootScale.Scale = math.clamp(State.Scale * value, 0.42, 1.2)
    end)
    dropdown("Reduced motion", "MotionMode", {"Off", "On"}, function(value)
        State.ReducedMotion = value == "On"
    end)
end

local function renderDiagnostics()
    section("Diagnostics", "Client-side checks and interface health.")
    local runtimeCard = card(49)
    cardLabel(runtimeCard, "Runtime", UDim2.new(0, 12, 0, 0), UDim2.new(0.42, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(runtimeCard, RunService:IsStudio() and "Roblox Studio" or "Client session",
        UDim2.new(0.42, 0, 0, 0), UDim2.new(0.52, -10, 1, 0), 10, CONFIG.Text, Enum.Font.GothamBold)

    local inputCard = card(49)
    cardLabel(inputCard, "Touch enabled", UDim2.new(0, 12, 0, 0), UDim2.new(0.42, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(inputCard, tostring(UserInputService.TouchEnabled),
        UDim2.new(0.42, 0, 0, 0), UDim2.new(0.52, -10, 1, 0), 10, CONFIG.Text, Enum.Font.GothamBold)

    local keyboardCard = card(49)
    cardLabel(keyboardCard, "Keyboard enabled", UDim2.new(0, 12, 0, 0), UDim2.new(0.42, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(keyboardCard, tostring(UserInputService.KeyboardEnabled),
        UDim2.new(0.42, 0, 0, 0), UDim2.new(0.52, -10, 1, 0), 10, CONFIG.Text, Enum.Font.GothamBold)

    local afCard = card(49)
    cardLabel(afCard, "Anti-Fling", UDim2.new(0, 12, 0, 0), UDim2.new(0.42, 0, 1, 0), 10, CONFIG.Muted)
    cardLabel(afCard, AntiFling.Enabled and "Active" or "Inactive",
        UDim2.new(0.42, 0, 0, 0), UDim2.new(0.52, -10, 1, 0), 10,
        AntiFling.Enabled and CONFIG.Good or CONFIG.Muted, Enum.Font.GothamBold)

    local refreshCard = card(55)
    local refresh = actionButton(refreshCard, "Run local refresh", function()
        State.RefreshCount += 1
        updateResponsiveScale()
        notify("Diagnostics", "Local UI refresh completed.", "success")
    end, 145)
    refresh.Position = UDim2.new(0, 11, 0, 9)

    infoCard(
        "No network activity",
        "Aurora v10.1 does not send telemetry, call remote URLs, fetch scripts, or connect to external servers.",
        66
    )
    infoCard(
        "Error handling",
        "UI callbacks are wrapped with protected calls. Errors raised by this interface are counted in the local monitor.",
        78
    )
end

local RENDERERS = {
    Dashboard       = renderDashboard,
    Monitor         = renderMonitor,
    ["Anti-Monitor"]= renderAntiMonitor,
    Visuals         = renderVisuals,
    ["Aim Lab"]     = renderAimLab,
    Player          = renderPlayer,
    Movement        = renderMovement,
    Profiles        = renderProfiles,
    Settings        = renderSettings,
    Diagnostics     = renderDiagnostics,
}

local PAGE_HINTS = {}
for _, entry in ipairs(NAVIGATION) do
    PAGE_HINTS[entry.Name] = entry.Hint
end

State.RenderPage = function(pageName)
    if State.Destroyed then return end
    if not RENDERERS[pageName] then return end
    State.Page = pageName
    clearPage()
    PageTitle.Text = pageName
    PageHint.Text = PAGE_HINTS[pageName] or "Aurora interface"
    for name, button in pairs(NavigationButtons) do
        animate(button, 0.12, {
            BackgroundColor3 = name == pageName and CONFIG.AccentDark or CONFIG.Surface2
        })
        local bar = button:FindFirstChild("ActiveBar")
        if bar then
            animate(bar, 0.14, {
                Size = UDim2.new(0, 3, 0, name == pageName and 22 or 0)
            })
        end
    end
    safe("render:" .. pageName, RENDERERS[pageName])
    PageScroll.CanvasPosition = Vector2.new(0, 0)
end

local monitorAccumulator = 0

addConnection(RunService.RenderStepped:Connect(function(deltaTime)
    if State.Destroyed then return end
    monitorAccumulator += deltaTime
    if monitorAccumulator >= 0.5 then
        monitorAccumulator = 0
        if ClockLabel and ClockLabel.Parent then
            ClockLabel.Visible = State.Preferences.ShowClock
            ClockLabel.Text = os.date("%H:%M")
        end
        if State.DashboardSessionMetric and State.DashboardSessionMetric.Parent then
            State.DashboardSessionMetric.Text = formatTime(os.clock() - State.StartedAt)
        end
        if State.DashboardPlayerMetric and State.DashboardPlayerMetric.Parent then
            State.DashboardPlayerMetric.Text = tostring(countPlayers())
        end
        if State.MonitorMetrics then
            local m = State.MonitorMetrics
            if m.Uptime and m.Uptime.Parent then
                m.Uptime.Text = formatTime(os.clock() - State.StartedAt)
            end
            if m.Players and m.Players.Parent then
                m.Players.Text = tostring(countPlayers())
            end
            if m.Errors and m.Errors.Parent then
                m.Errors.Text = tostring(State.ErrorCount)
                m.Errors.TextColor3 = State.ErrorCount > 0 and CONFIG.Danger or CONFIG.Good
            end
            if m.Actions and m.Actions.Parent then
                m.Actions.Text = tostring(State.ActionCount)
            end
        end
    end
end))

addConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or State.Destroyed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        if State.Minimized then
            restoreWindow()
        else
            minimizeWindow()
        end
    elseif input.KeyCode == Enum.KeyCode.Home then
        State.RenderPage("Dashboard")
    end
end))

local function destroyAurora()
    if State.Destroyed then return end
    State.Destroyed = true
    stopAntiFling()
    disconnectAll()
    if Screen and Screen.Parent then
        Screen:Destroy()
    end
end

local CloseButton = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -61, 0.5, 0),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = CONFIG.Surface3,
    Text = "×",
    TextColor3 = CONFIG.Text,
    TextSize = 20,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false,
}, Topbar)
corner(CloseButton, 10)
CloseButton.Activated:Connect(function()
    notify("Aurora", "Closing interface...", "warning")
    task.delay(0.08, destroyAurora)
end)

State.RenderPage("Dashboard")
notify("Aurora Hub v" .. CONFIG.Version, "Interface initialized. Anti-Fling ready.", "success")

print(string.format(
    "[Aurora Hub v%s] Loaded for %s | Touch: %s | Players: %d | Anti-Fling: %s",
    CONFIG.Version,
    LocalPlayer.Name,
    tostring(UserInputService.TouchEnabled),
    countPlayers(),
    tostring(AntiFling.Enabled)
))

-- End of Aurora Hub v10.1