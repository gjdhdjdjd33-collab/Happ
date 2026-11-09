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
local names={"Aim","ESP","Fling","Movement","Settings"}
local nTabs=#names
local pages,buttons={},{}
for i,n in ipairs(names) do
    local b=make("TextButton",{Position=UDim2.new((i-1)/nTabs,3,0,4),Size=UDim2.new(1/nTabs,-6,1,-8),BackgroundColor3=C.panel,Text=n,TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false},nav)
    round(b,9); buttons[n]=b
    local pg=make("ScrollingFrame",{Name=n,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},host)
    make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},pg)
    make("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,1),PaddingRight=UDim.new(0,4)},pg)
    pages[n]=pg
end
local tabInd=make("Frame",{Position=UDim2.new(0,3,1,-5),Size=UDim2.new(1/nTabs,-6,0,3),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=3},nav); round(tabInd,2)
local function page(name)
    for n,p in pairs(pages) do p.Visible=n==name end
    for i,n in ipairs(names) do
        local b=buttons[n]
        local on=n==name
        tween(b,{BackgroundColor3=on and C.accent2 or C.panel}); b.TextColor3=on and C.white or C.muted
        if on then tween(tabInd,{Position=UDim2.new((i-1)/nTabs,3,1,-5)}) end
    end
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

-- AIM ASSIST (rework)
section(pages.Aim,"Aim assist","Camera lock with target selection and smoothing")
local aimCfg={enabled=false,mode="Hold",fov=120,smooth=8,part="Head",target="Crosshair",predict=true,showFov=true}
local visibleOnly=true
local holding=false
local function cycler(pg,title,hint,options,start,callback)
    local f=card(pg,62)
    make("TextLabel",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-100,0,20),BackgroundTransparency=1,Text=title,TextColor3=C.white,Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},f)
    make("TextLabel",{Position=UDim2.fromOffset(12,30),Size=UDim2.new(1,-100,0,16),BackgroundTransparency=1,Text=hint or "",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},f)
    local idx=1
    for i,v in ipairs(options) do if v==start then idx=i end end
    local b=make("TextButton",{Position=UDim2.new(1,-92,.5,-13),Size=UDim2.fromOffset(80,26),BackgroundColor3=C.card2,Text=options[idx],TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=11,AutoButtonColor=false},f); round(b,9)
    b.Activated:Connect(function()
        idx=idx%#options+1
        b.Text=options[idx]
        if callback then callback(options[idx]) end
    end)
    return function() return options[idx] end
end
toggle(pages.Aim,"Enable aim assist","Activate with the AIM key or on-screen button",function(v) aimCfg.enabled=v end,false)
cycler(pages.Aim,"Activation","Hold to aim, or toggle on press",{"Hold","Toggle"},aimCfg.mode,function(v) aimCfg.mode=v end)
slider(pages.Aim,"FOV radius",30,400,aimCfg.fov," px",function(v) aimCfg.fov=v end)
slider(pages.Aim,"Smoothness",1,30,aimCfg.smooth,"",function(v) aimCfg.smooth=v end)
cycler(pages.Aim,"Target bone","Which body part to lock onto",{"Head","Torso","Nearest"},aimCfg.part,function(v) aimCfg.part=v end)
cycler(pages.Aim,"Target mode","How the best target is picked",{"Crosshair","Distance","Low health"},aimCfg.target,function(v) aimCfg.target=v end)
toggle(pages.Aim,"Only visible targets","Ignore targets blocked by walls",function(v) visibleOnly=v end,true)
toggle(pages.Aim,"Prediction","Lead moving targets",function(v) aimCfg.predict=v end,true)
toggle(pages.Aim,"Show FOV circle","Display the active selection radius",function(v) aimCfg.showFov=v end,true)
local fovCircle=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(aimCfg.fov*2,aimCfg.fov*2),BackgroundTransparency=1,Visible=true},gui)
round(fovCircle,500); stroke(fovCircle,C.accent,.2)
make("TextLabel",{Position=UDim2.fromOffset(12,7),Size=UDim2.new(1,-24,0,40),BackgroundTransparency=1,Text="Activates while the AIM key is held (or toggled). Right mouse on desktop.",TextWrapped=true,TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},card(pages.Aim,54))
local aimButton=make("TextButton",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-110),Size=UDim2.fromOffset(76,48),BackgroundColor3=C.accent2,Text="AIM",TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,Visible=UIS.TouchEnabled},gui); round(aimButton,14); stroke(aimButton,C.accent,.1)
local function setHold(v)
    holding=v
    aimButton.Text=v and "AIM: ON" or "AIM"
    tween(aimButton,{BackgroundColor3=v and C.green or C.accent2})
end
aimButton.Activated:Connect(function()
    if aimCfg.mode=="Toggle" then setHold(not holding) else setHold(true) end
end)
aimButton.InputEnded:Connect(function(i) if aimCfg.mode=="Hold" and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) then setHold(false) end end)
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType==Enum.UserInputType.MouseButton2 then
        if aimCfg.mode=="Toggle" then setHold(not holding) else setHold(true) end
    end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 and aimCfg.mode=="Hold" then setHold(false) end end)

-- ESP (rework)
section(pages.ESP,"Player visuals","Boxes, names, health bars, tracers and team filtering")
local esp={}
local DRAW=typeof(Drawing)=="table"
local teamCheck=true
local espCol={seen=C.green,hidden=C.red,team=Color3.fromRGB(96,146,255)}
local espCfg={enabled=false,chams=true,box=true,names=true,dist=true,health=true,tracer=false,maxDist=2000}
local function sameTeam(p) return LP.Team~=nil and p.Team==LP.Team end
local function clear(p)
    local d=esp[p]; if not d then return end
    if d.chams then pcall(function() d.chams:Destroy() end) end
    if DRAW then
        for _,k in ipairs({"box","name","dist","hpbg","hpfill","tracer"}) do
            local o=d[k]; if o and o.Remove then pcall(function() o:Remove() end) end
        end
    end
    esp[p]=nil
end
local function hideEsp(d)
    if not DRAW then return end
    for _,k in ipairs({"box","name","dist","hpbg","hpfill","tracer"}) do if d[k] then d[k].Visible=false end end
end
local function ensureEsp(p)
    local d=esp[p]
    if not d then
        d={}
        if DRAW then
            d.box=Drawing.new("Square"); d.box.Thickness=1; d.box.Filled=false
            d.hpbg=Drawing.new("Square"); d.hpbg.Filled=true; d.hpbg.Thickness=0; d.hpbg.Color=Color3.new(0,0,0)
            d.hpfill=Drawing.new("Square"); d.hpfill.Filled=true; d.hpfill.Thickness=0
            d.name=Drawing.new("Text"); d.name.Center=true; d.name.Outline=true; d.name.Size=14; d.name.Font=Drawing.Fonts.UI
            d.dist=Drawing.new("Text"); d.dist.Center=true; d.dist.Outline=true; d.dist.Size=13; d.dist.Font=Drawing.Fonts.UI
            d.tracer=Drawing.new("Line"); d.tracer.Thickness=1
        end
        esp[p]=d
    end
    local ch=p.Character
    if ch and not d.chams then
        d.chams=make("Highlight",{Name="AuroraChams",Adornee=ch,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,FillTransparency=.72,OutlineTransparency=.05,FillColor=espCol.seen,OutlineColor=espCol.seen},ch)
    end
    return d
end
local rayParams=RaycastParams.new(); rayParams.FilterType=Enum.RaycastFilterType.Exclude
local function lineOfSight(p)
    local ch=p.Character; local head=ch and ch:FindFirstChild("Head")
    if not head then return false end
    rayParams.FilterDescendantsInstances={LP.Character}
    local hit=workspace:Raycast(Camera.CFrame.Position,head.Position-Camera.CFrame.Position,rayParams)
    return hit==nil or hit.Instance:IsDescendantOf(ch)
end
local function boxBounds(p)
    local ch=p.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local head=ch and ch:FindFirstChild("Head")
    if not root or not head then return nil end
    local top=head.Position+Vector3.new(0,head.Size.Y*.5,0)
    local bot=root.Position-Vector3.new(0,root.Size.Y*.5+1.4,0)
    local w=math.max(root.Size.X*1.7,2)
    local dp=math.max(root.Size.Z*1.7,2)
    local h=(top-bot).Magnitude
    local center=(top+bot)*.5
    local cf=CFrame.new(center,center+Camera.CFrame.LookVector)
    local pts={}
    for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
        pts[#pts+1]=cf*Vector3.new(w*.5*x,h*.5*y,dp*.5*z)
    end end end
    return pts
end
local function projectBox(p)
    local pts=boxBounds(p); if not pts then return nil end
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    local anyFront,anyOn=false,false
    for _,c in ipairs(pts) do
        local sp,on=Camera:WorldToViewportPoint(c)
        if sp.Z>0 then
            anyFront=true
            minX=math.min(minX,sp.X); minY=math.min(minY,sp.Y)
            maxX=math.max(maxX,sp.X); maxY=math.max(maxY,sp.Y)
            if on then anyOn=true end
        end
    end
    if not anyFront then return nil end
    return minX,minY,maxX,maxY,anyOn
end
local function drawEsp(p,d,col,dist)
    local minX,minY,maxX,maxY,on=projectBox(p)
    if not minX then hideEsp(d); return end
    local w,h=maxX-minX,maxY-minY
    local c=on and col or espCol.hidden
    d.box.Visible=espCfg.box; d.box.Color=c; d.box.Size=Vector2.new(w,h); d.box.Position=Vector2.new(minX,minY)
    if espCfg.names then
        d.name.Visible=true; d.name.Color=c
        d.name.Text=(p.DisplayName~="" and p.DisplayName or p.Name)
        d.name.Position=Vector2.new(minX+w*.5,minY-16)
    else d.name.Visible=false end
    if espCfg.dist then
        d.dist.Visible=true; d.dist.Color=c; d.dist.Text=string.format("%d m",math.floor(dist))
        d.dist.Position=Vector2.new(minX+w*.5,maxY+3)
    else d.dist.Visible=false end
    if espCfg.health then
        local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        local frac=hum and math.clamp(hum.Health/hum.MaxHealth,0,1) or 1
        local bw=3
        d.hpbg.Visible=true; d.hpbg.Color=Color3.new(0,0,0); d.hpbg.Size=Vector2.new(bw+2,h+2); d.hpbg.Position=Vector2.new(minX-5,minY)
        d.hpfill.Visible=true; d.hpfill.Color=Color3.fromRGB(75,225,145); d.hpfill.Size=Vector2.new(bw,h*frac); d.hpfill.Position=Vector2.new(minX-4,minY+(h-h*frac))
    else d.hpbg.Visible=false; d.hpfill.Visible=false end
    if espCfg.tracer then
        local vp=Camera.ViewportSize
        d.tracer.Visible=true; d.tracer.Color=c
        d.tracer.From=Vector2.new(vp.X*.5,vp.Y); d.tracer.To=Vector2.new(minX+w*.5,maxY)
    else d.tracer.Visible=false end
end
toggle(pages.ESP,"Enable player ESP","Draw boxes, chams and labels for other players",function(v) espCfg.enabled=v; if not v then for p in pairs(esp) do clear(p) end end end,false)
toggle(pages.ESP,"Boxes","2D box around each character",function(v) espCfg.box=v end,true)
toggle(pages.ESP,"Chams","Body highlight through walls",function(v) espCfg.chams=v; for _,d in pairs(esp) do if d.chams then d.chams.Enabled=v end end end,true)
toggle(pages.ESP,"Names","Show player names",function(v) espCfg.names=v end,true)
toggle(pages.ESP,"Distance","Show distance in meters",function(v) espCfg.dist=v end,true)
toggle(pages.ESP,"Health bar","Vertical health bar beside the box",function(v) espCfg.health=v end,true)
toggle(pages.ESP,"Tracers","Line from screen bottom to target",function(v) espCfg.tracer=v end,false)
toggle(pages.ESP,"Hide teammates","Skip players on your own team",function(v) teamCheck=v end,true)
slider(pages.ESP,"Max distance",200,5000,espCfg.maxDist," m",function(v) espCfg.maxDist=v end)
local espLoop=RunService.RenderStepped:Connect(function()
    if not espCfg.enabled then return end
    Camera=workspace.CurrentCamera
    if not Camera then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local ch=p.Character
            local root=ch and ch:FindFirstChild("HumanoidRootPart")
            local hum=ch and ch:FindFirstChildOfClass("Humanoid")
            local isTeam=teamCheck and sameTeam(p)
            local dist=(myRoot and root) and (myRoot.Position-root.Position).Magnitude or 99999
            if ch and root and hum and hum.Health>0 and not isTeam and dist<=espCfg.maxDist then
                local d=ensureEsp(p)
                local seen=lineOfSight(p)
                local col=seen and espCol.seen or espCol.hidden
                if d.chams then d.chams.Enabled=espCfg.chams; d.chams.Adornee=ch; d.chams.FillColor=col; d.chams.OutlineColor=col end
                if DRAW then drawEsp(p,d,col,dist) end
            else
                clear(p)
            end
        end
    end
end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(.4); if espCfg.enabled then ensureEsp(p) end end)
end)
Players.PlayerRemoving:Connect(function(p) clear(p) end)

-- FLING (touch-triggered, all players)
section(pages.Fling,"Fling","Fling players you touch - no target picking")
local flingCfg={enabled=false,range=6}
local flingTool,flingHandle=nil,nil
local function destroyFling()
    if flingTool then pcall(function() flingTool:Destroy() end) end
    flingTool,flingHandle=nil,nil
end
local function buildFling()
    destroyFling()
    local char=LP.Character; if not char then return end
    local tool=Instance.new("Tool")
    tool.Name="AuroraFling"
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool.ToolTip=""
    local handle=Instance.new("Part")
    handle.Name="Handle"
    handle.Size=Vector3.new(2,2,2)
    handle.Transparency=1
    handle.CanCollide=false
    handle.Massless=false
    handle.Parent=tool
    tool.Parent=char
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:EquipTool(tool) end) end
    flingTool,flingHandle=tool,handle
end
local flingFlip=1
local flingLoop=RunService.Heartbeat:Connect(function()
    if not flingCfg.enabled then return end
    local char=LP.Character; if not char then return end
    if not flingTool or flingTool.Parent~=char then buildFling() end
    if not flingHandle or not flingHandle.Parent then return end
    local myRoot=char:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    local near=false
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position-myRoot.Position).Magnitude<=flingCfg.range then near=true; break end
        end
    end
    if near then
        flingFlip=-flingFlip
        flingHandle.AssemblyLinearVelocity=Vector3.new(flingFlip*1e6,flingFlip*1e6,flingFlip*1e6)
    else
        flingHandle.AssemblyLinearVelocity=Vector3.new()
    end
end)
toggle(pages.Fling,"Enable fling","Flings every player you touch, no targeting",function(v) flingCfg.enabled=v; if v then buildFling() else destroyFling() end end,false)
slider(pages.Fling,"Touch range",2,20,flingCfg.range," studs",function(v) flingCfg.range=v end)
local flingInfo=card(pages.Fling,58)
make("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),BackgroundTransparency=1,Text="Runs automatically: fires when any player is inside touch range and hits all of them at once. No target list.",TextWrapped=true,TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},flingInfo)

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
toggle(pages.Settings,"FOV circle","Show aim selection radius",function(v) aimCfg.showFov=v end,true)
local info=card(pages.Settings,66)
make("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),BackgroundTransparency=1,Text="AURORA HUB 6.0\nMobile layout • Touch controls • Team-aware ESP",TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},info)

-- Aim render loop (rework)
local function aimPartOf(ch)
    if aimCfg.part=="Head" then return ch:FindFirstChild("Head") end
    if aimCfg.part=="Torso" then return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart") end
    local o=Camera.CFrame.Position; local best,bd=nil,math.huge
    for _,d in ipairs(ch:GetDescendants()) do
        if d:IsA("BasePart") then
            local dd=(d.Position-o).Magnitude
            if dd<bd then bd,best=dd,d end
        end
    end
    return best
end
local aimConn=RunService.RenderStepped:Connect(function()
    Camera=workspace.CurrentCamera
    if not Camera then return end
    local vp=Camera.ViewportSize
    fovCircle.Position=UDim2.fromOffset(vp.X/2,vp.Y/2)
    fovCircle.Size=UDim2.fromOffset(aimCfg.fov*2,aimCfg.fov*2)
    fovCircle.Visible=aimCfg.showFov and aimCfg.enabled
    if not (aimCfg.enabled and holding) then return end
    local center=Vector2.new(vp.X/2,vp.Y/2)
    local best,bestScore=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and not (teamCheck and sameTeam(p)) then
            local ch=p.Character
            local hum=ch and ch:FindFirstChildOfClass("Humanoid")
            local part=ch and aimPartOf(ch)
            if hum and hum.Health>0 and part then
                local aimPos=part.Position
                if aimCfg.predict then
                    aimPos=aimPos+part.AssemblyLinearVelocity*(1/60)*(1+aimCfg.smooth*.05)
                end
                local pos=Camera:WorldToViewportPoint(aimPos)
                if pos.Z>0 then
                    local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
                    if d<=aimCfg.fov and (not visibleOnly or lineOfSight(p)) then
                        local score
                        if aimCfg.target=="Distance" then score=(part.Position-Camera.CFrame.Position).Magnitude
                        elseif aimCfg.target=="Low health" then score=hum.Health
                        else score=d end
                        if score<bestScore then best,bestScore=aimPos,score end
                    end
                end
            end
        end
    end
    if best then
        local desired=CFrame.new(Camera.CFrame.Position,best)
        Camera.CFrame=Camera.CFrame:Lerp(desired,math.clamp(1/aimCfg.smooth,.03,.65))
    end
end)

local dragging,dragStart,startPos=false,nil,nil
header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=win.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-dragStart; win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
local minimized=false
mini.Activated:Connect(function() minimized=not minimized; host.Visible=not minimized; nav.Visible=not minimized; win.Size=minimized and UDim2.fromOffset(370,76) or UDim2.fromOffset(370,555); mini.Text=minimized and "+" or "−" end)
close.Activated:Connect(function()
    pcall(function() aimConn:Disconnect(); espLoop:Disconnect(); flingLoop:Disconnect(); noclipConn:Disconnect(); fpsConn:Disconnect() end)
    destroyFling()
    for p in pairs(esp) do clear(p) end
    gui:Destroy()
end)
LP.CharacterAdded:Connect(function()
    task.wait(.5)
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h and speedOn then h.WalkSpeed=speed end
    if flingCfg.enabled then buildFling() end
end)
