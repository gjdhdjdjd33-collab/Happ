-- AURORA HUB v6.0 | Mobile-friendly Roblox client UI
-- Aim assist + ESP are intended for experiences where you have permission to use them.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local C = {
    bg=Color3.fromRGB(10,12,19), panel=Color3.fromRGB(17,20,30),
    card=Color3.fromRGB(25,29,43), card2=Color3.fromRGB(37,42,60),
    accent=Color3.fromRGB(151,105,255), accent2=Color3.fromRGB(105,70,205),
    white=Color3.fromRGB(246,244,252), muted=Color3.fromRGB(151,157,178),
    green=Color3.fromRGB(75,225,145), red=Color3.fromRGB(255,85,105),
    border=Color3.fromRGB(58,64,85)
}
local old
pcall(function() old=game:GetService("CoreGui"):FindFirstChild("AuroraHubV6"); if old then old:Destroy() end end)
local function make(class, props, parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function round(o,r) make("UICorner",{CornerRadius=UDim.new(0,r or 12)},o) end
local function stroke(o,col,t) make("UIStroke",{Color=col or C.border,Transparency=t or .35,Thickness=1},o) end
local function tween(o,props)
    TweenService:Create(o,TweenInfo.new(.16,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),props):Play()
end
local gui=make("ScreenGui",{Name="AuroraHubV6",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local ok=pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not ok then gui.Parent=LP:WaitForChild("PlayerGui") end

local fps=make("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,12),Size=UDim2.fromOffset(92,30),BackgroundColor3=C.panel,Text="-- FPS",TextColor3=C.green,Font=Enum.Font.GothamBold,TextSize=12},gui)
round(fps,15); stroke(fps,C.accent,.2)
local frames,elapsed=0,0
local fpsConn=RunService.RenderStepped:Connect(function(dt)
    frames+=1; elapsed+=dt
    if elapsed>=.5 then fps.Text=tostring(math.floor(frames/elapsed+.5)).." FPS"; frames,elapsed=0,0 end
end)

local win=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromOffset(370,555),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true},gui)
round(win,22); stroke(win,C.accent,.18)
local scale=make("UIScale",{Scale=1},win)
local function fit()
    Camera=workspace.CurrentCamera
    if Camera then local v=Camera.ViewportSize; scale.Scale=math.clamp(math.min(v.X/410,v.Y/730),.72,1) end
end
fit()
if Camera then Camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
local header=make("Frame",{Size=UDim2.new(1,0,0,76),BackgroundColor3=C.panel,BorderSizePixel=0},win)
make("TextLabel",{Position=UDim2.fromOffset(17,10),Size=UDim2.new(1,-105,0,29),BackgroundTransparency=1,Text="AURORA  HUB",TextColor3=C.white,Font=Enum.Font.GothamBlack,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},header)
make("TextLabel",{Position=UDim2.fromOffset(19,42),Size=UDim2.new(1,-110,0,16),BackgroundTransparency=1,Text="MOBILE EDITION  •  BUILD 6.0",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},header)
local mini=make("TextButton",{Position=UDim2.new(1,-76,0,20),Size=UDim2.fromOffset(27,27),BackgroundColor3=C.card2,Text="−",TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=18},header); round(mini,9)
local close=make("TextButton",{Position=UDim2.new(1,-42,0,20),Size=UDim2.fromOffset(27,27),BackgroundColor3=C.card2,Text="×",TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=17},header); round(close,9)
local nav=make("Frame",{Position=UDim2.fromOffset(11,86),Size=UDim2.new(1,-22,0,42),BackgroundColor3=C.panel},win); round(nav,12)
local host=make("Frame",{Position=UDim2.fromOffset(11,138),Size=UDim2.new(1,-22,1,-149),BackgroundTransparency=1},win)
local names={"Aim","ESP","Movement","Settings"}
local pages,buttons={},{}
for i,n in ipairs(names) do
    local b=make("TextButton",{Position=UDim2.new((i-1)/4,3,0,4),Size=UDim2.new(1/4,-6,1,-8),BackgroundColor3=C.panel,Text=n,TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=11,AutoButtonColor=false},nav)
    round(b,9); buttons[n]=b
    local pg=make("ScrollingFrame",{Name=n,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},host)
    make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},pg)
    make("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,4)},pg)
    pages[n]=pg
end
local function page(name)
    for n,p in pairs(pages) do p.Visible=n==name end
    for n,b in pairs(buttons) do tween(b,{BackgroundColor3=n==name and C.accent2 or C.panel}); b.TextColor3=n==name and C.white or C.muted end
end
for n,b in pairs(buttons) do b.Activated:Connect(function() page(n) end) end
page("Aim")
local function section(pg,title,desc)
    local f=make("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1},pg)
    make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=string.upper(title),TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},f)
    make("TextLabel",{Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text=desc or "",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},f)
end
local function card(pg,h)
    local f=make("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=C.card,BorderSizePixel=0},pg); round(f,13); stroke(f,C.border,.5); return f
end
local function toggle(pg,title,hint,callback,default)
    local f=card(pg,60)
    make("TextLabel",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-80,0,21),BackgroundTransparency=1,Text=title,TextColor3=C.white,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},f)
    make("TextLabel",{Position=UDim2.fromOffset(12,31),Size=UDim2.new(1,-80,0,16),BackgroundTransparency=1,Text=hint or "",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},f)
    local state=default==true
    local sw=make("TextButton",{Position=UDim2.new(1,-57,.5,-13),Size=UDim2.fromOffset(44,26),BackgroundColor3=state and C.accent or C.card2,Text="",AutoButtonColor=false},f); round(sw,14)
    local dot=make("Frame",{Position=state and UDim2.new(1,-23,0,3) or UDim2.fromOffset(3,3),Size=UDim2.fromOffset(20,20),BackgroundColor3=C.white},sw); round(dot,10)
    local function set(v)
        state=v; tween(sw,{BackgroundColor3=v and C.accent or C.card2}); tween(dot,{Position=v and UDim2.new(1,-23,0,3) or UDim2.fromOffset(3,3)})
        if callback then callback(v) end
    end
    sw.Activated:Connect(function() set(not state) end)
    return set
end
local function slider(pg,title,minv,maxv,start,suffix,callback)
    local f=card(pg,76)
    make("TextLabel",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-90,0,20),BackgroundTransparency=1,Text=title,TextColor3=C.white,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},f)
    local val=make("TextLabel",{Position=UDim2.new(1,-80,0,7),Size=UDim2.fromOffset(68,20),BackgroundTransparency=1,Text=tostring(start)..(suffix or ""),TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right},f)
    local bar=make("Frame",{Position=UDim2.fromOffset(12,43),Size=UDim2.new(1,-24,0,9),BackgroundColor3=C.card2},f); round(bar,6)
    local pct=(start-minv)/(maxv-minv)
    local fill=make("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.accent},bar); round(fill,6)
    local knob=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(pct,0,.5,0),Size=UDim2.fromOffset(18,18),BackgroundColor3=C.white},bar); round(knob,10); stroke(knob,C.accent,0)
    local value,drag=start,false
    local function setx(x)
        local p=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        value=math.floor(minv+(maxv-minv)*p+.5); p=(value-minv)/(maxv-minv)
        fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,.5,0); val.Text=tostring(value)..(suffix or "")
        if callback then callback(value) end
    end
    local function begin(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setx(i.Position.X) end end
    bar.InputBegan:Connect(begin); knob.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then setx(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    return function() return value end
end

-- AIM ASSIST
section(pages.Aim,"Aim assist","Camera assistance with configurable target selection")
local aimOn,visibleOnly,smart=true,true,true
local fov,smooth=120,12
local aimPart="Head"
local showFov=true
toggle(pages.Aim,"Enable aim assist","Hold right mouse / aim button to activate",function(v) aimOn=v end,false)
slider(pages.Aim,"FOV radius",30,350,fov," px",function(v) fov=v end)
slider(pages.Aim,"Smoothness",1,30,smooth,"",function(v) smooth=v end)
toggle(pages.Aim,"Only visible targets","Ignore targets blocked by walls",function(v) visibleOnly=v end,true)
toggle(pages.Aim,"Smart target","Prioritize nearest target to the crosshair",function(v) smart=v end,true)
toggle(pages.Aim,"Show FOV circle","Display the active selection radius",function(v) showFov=v end,true)
local fovCircle=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(fov*2,fov*2),BackgroundTransparency=1,Visible=true},gui)
round(fovCircle,500); stroke(fovCircle,C.accent,.2)
make("TextLabel",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-24,0,35),BackgroundTransparency=1,Text="Aim activates while holding the on-screen AIM button.",TextWrapped=true,TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},card(pages.Aim,48))
local aimButton=make("TextButton",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-110),Size=UDim2.fromOffset(76,48),BackgroundColor3=C.accent2,Text="AIM: OFF",TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=11,Visible=UIS.TouchEnabled},gui); round(aimButton,14); stroke(aimButton,C.accent,.1)
local holding=false
aimButton.Activated:Connect(function() holding=not holding; aimButton.Text=holding and "AIM: ON" or "AIM: OFF"; tween(aimButton,{BackgroundColor3=holding and C.green or C.accent2}) end)
UIS.InputBegan:Connect(function(i,gp) if not gp and i.UserInputType==Enum.UserInputType.MouseButton2 then holding=true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then holding=false end end)

-- ESP
section(pages.ESP,"Player visuals","Team filtering and line-of-sight colors")
local espOn,teamCheck,espNames,espDistance=false,true,true,false
local esp={}
local function sameTeam(p) return LP.Team~=nil and p.Team==LP.Team end
local function clear(p)
    local h=esp[p]; if h then pcall(function() h:Destroy() end); esp[p]=nil end
end
local function add(p)
    clear(p)
    if not espOn or p==LP or not p.Character or (teamCheck and sameTeam(p)) then return end
    local h=make("Highlight",{Name="AuroraESP",Adornee=p.Character,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillTransparency=.72,OutlineTransparency=.05,FillColor=C.green,OutlineColor=C.green},p.Character)
    esp[p]=h
end
local function refresh()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then if espOn then add(p) else clear(p) end end end
end
toggle(pages.ESP,"Enable player ESP","Highlight enemies in the current server",function(v) espOn=v; refresh() end,false)
toggle(pages.ESP,"Hide teammates","Do not draw ESP for your own team",function(v) teamCheck=v; refresh() end,true)
toggle(pages.ESP,"Name labels","Show player display names",function(v) espNames=v end,true)
toggle(pages.ESP,"Distance labels","Include distance in the name label",function(v) espDistance=v end,false)
local rayParams=RaycastParams.new(); rayParams.FilterType=Enum.RaycastFilterType.Exclude
local function visible(character,part)
    local origin=Camera.CFrame.Position
    rayParams.FilterDescendantsInstances={LP.Character,character}
    local result=workspace:Raycast(origin,part.Position-origin,rayParams)
    return result==nil
end
local function lineOfSight(p)
    local ch=p.Character; local head=ch and ch:FindFirstChild("Head")
    if not head then return false end
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={LP.Character}
    local hit=workspace:Raycast(Camera.CFrame.Position,head.Position-Camera.CFrame.Position,params)
    return hit==nil or hit.Instance:IsDescendantOf(ch)
end
local aimTarget
local espLoop=RunService.Heartbeat:Connect(function()
    if not espOn then return end
    local _,_,root= (function() local c=LP.Character; return c,c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart") end)()
    for p,h in pairs(esp) do
        if not p.Parent or not p.Character or (teamCheck and sameTeam(p)) then clear(p)
        else
            local seen=lineOfSight(p)
            local col=seen and C.green or C.red
            h.FillColor=col; h.OutlineColor=col
        end
    end
end)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(.5); add(p) end) end)
Players.PlayerRemoving:Connect(clear)

-- Movement
section(pages.Movement,"Movement","Local character movement options")
local speedOn=false; local speed=28; local savedSpeed=16
toggle(pages.Movement,"Speed boost","Set local WalkSpeed",function(v)
    speedOn=v; local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then if v then savedSpeed=h.WalkSpeed; h.WalkSpeed=speed else h.WalkSpeed=savedSpeed end end
end,false)
slider(pages.Movement,"Walk speed",16,100,speed," WS",function(v) speed=v; local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if speedOn and h then h.WalkSpeed=v end end)
local noclip=false; local oldColl={}
toggle(pages.Movement,"Noclip","Restore collision values when disabled",function(v)
    noclip=v
    if not v then for part,val in pairs(oldColl) do if part and part.Parent then pcall(function() part.CanCollide=val end) end end; table.clear(oldColl) end
end,false)
local noclipConn=RunService.Stepped:Connect(function()
    if not noclip then return end
    local ch=LP.Character; if not ch then return end
    for _,part in ipairs(ch:GetDescendants()) do if part:IsA("BasePart") then if oldColl[part]==nil then oldColl[part]=part.CanCollide end; part.CanCollide=false end end
end)

-- Settings
section(pages.Settings,"Interface","Small quality-of-life controls")
toggle(pages.Settings,"FPS counter","Show live frame rate at the top",function(v) fps.Visible=v end,true)
toggle(pages.Settings,"FOV circle","Show aim selection radius",function(v) showFov=v end,true)
local info=card(pages.Settings,66)
make("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),BackgroundTransparency=1,Text="AURORA HUB 6.0\nMobile layout • Touch controls • Team-aware ESP",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},info)

-- Aim render loop
local aimConn=RunService.RenderStepped:Connect(function()
    Camera=workspace.CurrentCamera
    if not Camera then return end
    local vp=Camera.ViewportSize
    fovCircle.Position=UDim2.fromOffset(vp.X/2,vp.Y/2)
    fovCircle.Size=UDim2.fromOffset(fov*2,fov*2)
    fovCircle.Visible=showFov and aimOn
    if not (aimOn and holding) then return end
    local center=Vector2.new(vp.X/2,vp.Y/2)
    local best,bestScore=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and not (teamCheck and sameTeam(p)) then
            local ch=p.Character; local hum=ch and ch:FindFirstChildOfClass("Humanoid")
            local part=ch and (ch:FindFirstChild(aimPart) or ch:FindFirstChild("HumanoidRootPart"))
            if hum and hum.Health>0 and part then
                local pos,onScreen=Camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z>0 then
                    local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                    if d<=fov and (not visibleOnly or lineOfSight(p)) then
                        local score=smart and d or (part.Position-Camera.CFrame.Position).Magnitude
                        if score<bestScore then best,bestScore=part,score end
                    end
                end
            end
        end
    end
    if best then
        local desired=CFrame.new(Camera.CFrame.Position,best.Position)
        Camera.CFrame=Camera.CFrame:Lerp(desired,math.clamp(1/smooth,.03,.65))
    end
end)

local dragging,dragStart,startPos=false,nil,nil
header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=win.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-dragStart; win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
local minimized=false
mini.Activated:Connect(function() minimized=not minimized; host.Visible=not minimized; nav.Visible=not minimized; win.Size=minimized and UDim2.fromOffset(370,76) or UDim2.fromOffset(370,555); mini.Text=minimized and "+" or "−" end)
close.Activated:Connect(function()
    pcall(function() aimConn:Disconnect(); espLoop:Disconnect(); noclipConn:Disconnect(); fpsConn:Disconnect() end)
    for p in pairs(esp) do clear(p) end
    gui:Destroy()
end)
LP.CharacterAdded:Connect(function()
    task.wait(.5)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and speedOn then h.WalkSpeed=speed end
end)
