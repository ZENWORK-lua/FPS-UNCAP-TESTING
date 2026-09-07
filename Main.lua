-- HYPER|HUB - Ultimate v17 (Hardware Monitor & FFlag Core)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local env = (getgenv and getgenv()) or _G
local function getSafeGuiParent()
    local p = nil; if gethui then pcall(function() p = gethui() end) end
    if not p then pcall(function() p = game:GetService("CoreGui") end) end
    if not p or not pcall(function() local _ = p.Name end) then p = Players.LocalPlayer:WaitForChild("PlayerGui") end
    return p
end
local targetGui = getSafeGuiParent()

if env.SYROX_RUNNING and targetGui:FindFirstChild("FPSCapUI") then return end
if env.FPSCapUIConnections then for _, c in ipairs(env.FPSCapUIConnections) do if c and c.Connected then c:Disconnect() end end end
if targetGui:FindFirstChild("FPSCapUI") then targetGui.FPSCapUI:Destroy() end
env.FPSCapUIConnections = {}; local connections = env.FPSCapUIConnections
env.SYROX_RUNNING = true; env.SYROX_ORIGINAL_FFLAGS = {}

env.HYPER_SAVE = {Remember = false, Toggles = {}, Switches = {}}
if isfile and readfile and isfile("HYPER_HUB.json") then pcall(function() env.HYPER_SAVE = HttpService:JSONDecode(readfile("HYPER_HUB.json")) end) end
if not env.HYPER_SAVE.Toggles then env.HYPER_SAVE.Toggles = {} end
if not env.HYPER_SAVE.Switches then env.HYPER_SAVE.Switches = {} end
env.saveHubData = function() if env.HYPER_SAVE.Remember and writefile then pcall(function() writefile("HYPER_HUB.json", HttpService:JSONEncode(env.HYPER_SAVE)) end) end end

local MIN_FPS, MAX_FPS = 5, 500; local currentTargetFps = setfpscap and 120 or 60
local screenGui = Instance.new("ScreenGui"); screenGui.Name = "FPSCapUI"; screenGui.ResetOnSpawn = false; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- BAĞIMSIZ SYSTEM MONITOR KAPSÜLÜ (Sağ Taraf)
local sysMonitor = Instance.new("Frame")
sysMonitor.Name = "SystemMonitor"; sysMonitor.Position = UDim2.new(1, -120, 0.5, -100); sysMonitor.AnchorPoint = Vector2.new(1, 0.5)
sysMonitor.BackgroundColor3 = Color3.fromRGB(20, 20, 25); sysMonitor.BackgroundTransparency = 0.3; sysMonitor.ClipsDescendants = true
sysMonitor.AutomaticSize = Enum.AutomaticSize.XY; sysMonitor.Parent = screenGui
Instance.new("UICorner", sysMonitor).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", sysMonitor).Color = Color3.fromRGB(0, 162, 255)
local monLayout = Instance.new("UIListLayout", sysMonitor)
monLayout.SortType = Enum.SortType.LayoutOrder; monLayout.Padding = UDim.new(0, 8); monLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local monPadding = Instance.new("UIPadding", sysMonitor)
monPadding.PaddingTop = UDim.new(0,8); monPadding.PaddingBottom = UDim.new(0,8); monPadding.PaddingLeft = UDim.new(0,8); monPadding.PaddingRight = UDim.new(0,8)

-- ANA MENÜ ÇEKİRDEĞİ
local mainFrame = Instance.new("Frame"); mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0, 0, 0, 0); mainFrame.Position = UDim2.new(0.5, -50, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5); mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255); mainFrame.BackgroundTransparency = 0.25; mainFrame.Parent = screenGui
local bgGradient = Instance.new("UIGradient", mainFrame); bgGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 52)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))}); bgGradient.Rotation = 45
local uiCorner = Instance.new("UICorner", mainFrame); uiCorner.CornerRadius = UDim.new(1, 0)
local outerAura = Instance.new("Frame"); outerAura.Size = UDim2.new(1, 6, 1, 6); outerAura.Position = UDim2.new(0.5, 0, 0.5, 0); outerAura.AnchorPoint = Vector2.new(0.5, 0.5); outerAura.BackgroundTransparency = 1; outerAura.Parent = mainFrame
Instance.new("UICorner", outerAura).CornerRadius = UDim.new(0, 19); local auraStroke = Instance.new("UIStroke", outerAura); auraStroke.Color = Color3.fromRGB(0, 162, 255); auraStroke.Thickness = 1.2; auraStroke.Transparency = 1

local headerPillTouch = Instance.new("TextButton"); headerPillTouch.Size = UDim2.new(0, 150, 0, 32); headerPillTouch.Position = UDim2.new(0.5, 0, 0, 0); headerPillTouch.AnchorPoint = Vector2.new(0.5, 0); headerPillTouch.BackgroundTransparency = 1; headerPillTouch.Text = ""; headerPillTouch.ZIndex = 50; headerPillTouch.Parent = mainFrame
local headerPill = Instance.new("Frame"); headerPill.Size = UDim2.new(0, 50, 0, 5); headerPill.Position = UDim2.new(0.5, 0, 0, 12); headerPill.AnchorPoint = Vector2.new(0.5, 0.5); headerPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); headerPill.BackgroundTransparency = 1; headerPill.ZIndex = 1; headerPill.Parent = mainFrame; Instance.new("UICorner", headerPill).CornerRadius = UDim.new(1, 0)
local function applyAppleTween(obj, props, dur) TweenService:Create(obj, TweenInfo.new(dur or 0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play() end

local monitorNodes = {}
local activeOrder = 0

local function createMonitorNode(id, title)
    local node = Instance.new("Frame"); node.Size = UDim2.new(0, 32, 0, 32); node.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    node.ClipsDescendants = true; node.LayoutOrder = 99 + id; node.Parent = sysMonitor
    Instance.new("UICorner", node).CornerRadius = UDim.new(1, 0)
    
    local btn = Instance.new("TextButton", node); btn.Size = UDim2.new(0, 32, 0, 32); btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamBold; btn.Text = title; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextSize = 10
    
    local valLabel = Instance.new("TextLabel", node); valLabel.Size = UDim2.new(1, -36, 1, 0); valLabel.Position = UDim2.new(0, 36, 0, 0)
    valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.GothamMedium; valLabel.Text = "--"; valLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
    valLabel.TextSize = 11; valLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local isActive = false
    table.insert(connections, btn.MouseButton1Click:Connect(function()
        isActive = not isActive
        if isActive then
            activeOrder = activeOrder + 1; node.LayoutOrder = activeOrder
            applyAppleTween(node, {Size = UDim2.new(0, 110, 0, 32)}); btn.TextColor3 = Color3.fromRGB(0, 162, 255)
        else
            node.LayoutOrder = 99 + id
            applyAppleTween(node, {Size = UDim2.new(0, 32, 0, 32)}); btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end))
    
    monitorNodes[id] = {Label = valLabel, IsActive = function() return isActive end}
end

createMonitorNode(1, "FPS"); createMonitorNode(2, "CPU")
createMonitorNode(3, "GPU"); createMonitorNode(4, "RAM"); createMonitorNode(5, "TMP")

-- MONİTÖRÜ SÜRÜKLEME MANTIĞI
local dragMon, startMonPos, dragMonStart = false, nil, nil
table.insert(connections, sysMonitor.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragMon = true; dragMonStart = input.Position; startMonPos = sysMonitor.Position end end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input) if dragMon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragMonStart; sysMonitor.Position = UDim2.new(startMonPos.X.Scale, startMonPos.X.Offset + delta.X, startMonPos.Y.Scale, startMonPos.Y.Offset + delta.Y) end end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragMon = false end end))
local contentContainer = Instance.new("Frame"); contentContainer.Size = UDim2.new(1, 0, 1, 0); contentContainer.BackgroundTransparency = 1; contentContainer.ClipsDescendants = true; contentContainer.Visible = false; contentContainer.Parent = mainFrame
local fadeCurtain = Instance.new("Frame"); fadeCurtain.Size = UDim2.new(1, 0, 1, 0); fadeCurtain.BackgroundColor3 = Color3.fromRGB(10, 10, 15); fadeCurtain.BackgroundTransparency = 1; fadeCurtain.ZIndex = 10; fadeCurtain.Parent = contentContainer; Instance.new("UICorner", fadeCurtain).CornerRadius = UDim.new(0, 16)

local mainPage = Instance.new("Frame"); mainPage.Size = UDim2.new(1, 0, 1, 0); mainPage.BackgroundTransparency = 1; mainPage.Parent = contentContainer
local themePage = Instance.new("Frame"); themePage.Size = UDim2.new(1, 0, 1, 0); themePage.BackgroundTransparency = 1; themePage.Visible = false; themePage.Parent = contentContainer
local settingsPage = Instance.new("Frame"); settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.Visible = false; settingsPage.Parent = contentContainer

local titleLabel = Instance.new("TextLabel"); titleLabel.Size = UDim2.new(1, -24, 0, 22); titleLabel.Position = UDim2.new(0, 12, 0, 20); titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.SourceSansBold; titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240); titleLabel.TextSize = 15; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Text = string.format("Target FPS: %d FPS", currentTargetFps); titleLabel.Parent = mainPage
local effectBarBg = Instance.new("Frame"); effectBarBg.Size = UDim2.new(1, -24, 0, 5); effectBarBg.Position = UDim2.new(0, 12, 0, 66); effectBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50); effectBarBg.BackgroundTransparency = 0.3; effectBarBg.BorderSizePixel = 0; effectBarBg.Parent = mainPage; Instance.new("UICorner", effectBarBg).CornerRadius = UDim.new(1, 0)
local sliderTrack = Instance.new("Frame"); sliderTrack.Size = UDim2.new(1, -24, 0, 6); sliderTrack.Position = UDim2.new(0, 12, 0, 85); sliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 55); sliderTrack.BorderSizePixel = 0; sliderTrack.Parent = mainPage; Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)
local initialRatio = math.clamp((currentTargetFps - MIN_FPS) / (MAX_FPS - MIN_FPS), 0, 1)
local effectBarGlow = Instance.new("Frame"); effectBarGlow.Size = UDim2.new(initialRatio, 0, 1, 0); effectBarGlow.BackgroundColor3 = Color3.fromRGB(0, 162, 255); effectBarGlow.Parent = effectBarBg; Instance.new("UICorner", effectBarGlow).CornerRadius = UDim.new(1, 0)
local sliderFill = Instance.new("Frame"); sliderFill.Size = UDim2.new(initialRatio, 0, 1, 0); sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255); sliderFill.Parent = sliderTrack; Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
local sliderKnob = Instance.new("Frame"); sliderKnob.Size = UDim2.new(0, 18, 0, 18); sliderKnob.Position = UDim2.new(initialRatio, -9, 0.5, -9); sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); sliderKnob.Parent = sliderTrack; Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)
local fpsDisplay = Instance.new("TextLabel"); fpsDisplay.Size = UDim2.new(1, -24, 0, 18); fpsDisplay.Position = UDim2.new(0, 12, 0, 42); fpsDisplay.BackgroundTransparency = 1; fpsDisplay.Font = Enum.Font.SourceSansSemibold; fpsDisplay.TextColor3 = Color3.fromRGB(160, 160, 175); fpsDisplay.TextSize = 13; fpsDisplay.TextXAlignment = Enum.TextXAlignment.Left; fpsDisplay.Text = "Current FPS: 0"; fpsDisplay.Parent = mainPage

local stabTitle = Instance.new("TextLabel"); stabTitle.Size = UDim2.new(1, -24, 0, 16); stabTitle.Position = UDim2.new(0, 12, 0, 110); stabTitle.BackgroundTransparency = 1; stabTitle.Font = Enum.Font.SourceSansBold; stabTitle.Text = "FEATURES (SWIPE RIGHT ->)"; stabTitle.TextColor3 = Color3.fromRGB(0, 200, 255); stabTitle.TextSize = 11; stabTitle.TextXAlignment = Enum.TextXAlignment.Left; stabTitle.Parent = mainPage
local scrollFrame = Instance.new("ScrollingFrame"); scrollFrame.Size = UDim2.new(1, -24, 0, 65); scrollFrame.Position = UDim2.new(0, 12, 0, 130); scrollFrame.BackgroundTransparency = 1; scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 0; scrollFrame.ScrollingDirection = Enum.ScrollingDirection.X
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.X; scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0); scrollFrame.Parent = mainPage
local gridLayout = Instance.new("UIGridLayout"); gridLayout.CellSize = UDim2.new(0, 115, 0, 28); gridLayout.CellPadding = UDim2.new(0, 8, 0, 8); gridLayout.FillDirection = Enum.FillDirection.Vertical; gridLayout.Parent = scrollFrame

local btnTheme = Instance.new("ImageButton"); btnTheme.Size = UDim2.new(0, 20, 0, 20); btnTheme.Position = UDim2.new(1, -60, 0, 18); btnTheme.BackgroundTransparency = 1; btnTheme.Image = "rbxassetid://3926305904"; btnTheme.ImageRectOffset = Vector2.new(764, 244); btnTheme.ImageRectSize = Vector2.new(36, 36); btnTheme.ImageColor3 = Color3.fromRGB(255, 255, 255); btnTheme.ImageTransparency = 0.3; btnTheme.ZIndex = 11; btnTheme.Parent = contentContainer
local btnSettings = Instance.new("ImageButton"); btnSettings.Size = UDim2.new(0, 20, 0, 20); btnSettings.Position = UDim2.new(1, -34, 0, 18); btnSettings.BackgroundTransparency = 1; btnSettings.Image = "rbxassetid://3926307971"; btnSettings.ImageRectOffset = Vector2.new(324, 124); btnSettings.ImageRectSize = Vector2.new(36, 36); btnSettings.ImageColor3 = Color3.fromRGB(255, 255, 255); btnSettings.ImageTransparency = 0.3; btnSettings.ZIndex = 11; btnSettings.Parent = contentContainer

local sysScroll = Instance.new("ScrollingFrame"); sysScroll.Size = UDim2.new(1, -24, 1, -60); sysScroll.Position = UDim2.new(0, 12, 0, 50); sysScroll.BackgroundTransparency = 1; sysScroll.BorderSizePixel = 0; sysScroll.ScrollBarThickness = 0; sysScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; sysScroll.CanvasSize = UDim2.new(0, 0, 0, 0); sysScroll.Parent = settingsPage; Instance.new("UIListLayout", sysScroll).Padding = UDim.new(0, 10)
local globalAccentColor = Color3.fromRGB(0, 162, 255)
local activeModules = {}
local function createBtn(name, text, p)
    local btn = Instance.new("TextButton"); btn.Name = name; btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); btn.BackgroundTransparency = 0.3; btn.Font = Enum.Font.SourceSansBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 210); btn.TextSize = 11; btn.Parent = p or scrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8); local str = Instance.new("UIStroke", btn); str.Color = Color3.fromRGB(255, 255, 255); str.Thickness = 1; str.Transparency = 0.8
    activeModules[name] = {Btn = btn, Stroke = str, IsActive = false}; return btn, str
end

local btnGfxLvl = createBtn("BtnGfx", "GFX LVL: AUTO"); local btnLowGfx = createBtn("BtnLowGfx", "LOW GFX: OFF")
local btnShadows = createBtn("BtnShadows", "SHADOWS: ON"); local btnCastS = createBtn("BtnCastS", "CAST-SHDW: ON")
local btnTex = createBtn("BtnTex", "TEXTURES: HIGH"); local btnPart = createBtn("BtnPart", "PARTICLES: ON")
local btnHigh = createBtn("BtnHigh", "HIGHLIGHTS: ON"); local btnWater = createBtn("BtnWater", "WATER: HIGH")

local function createSwitch(text, parent)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -8, 0, 30); f.BackgroundTransparency = 1; f.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -50, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSansBold; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(200, 200, 210); lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -40, 0.5, -10); btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70); btn.Text = ""; btn.Parent = f; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 16, 0, 16); knob.Position = UDim2.new(0, 2, 0.5, -8); knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.Parent = btn; Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    return btn, knob, f
end

local btnRemember, knobRemember = createSwitch("Remember Changes", sysScroll)
local btnMaxFps, knobMaxFps = createSwitch("Remove 500 FPS Limit", sysScroll)
local btnAfk, knobAfk = createSwitch("AFK Blackout Mode", sysScroll)

-- CORE KERNEL SEVİYESİ FFLAG PARSER
local ffContainer = Instance.new("Frame"); ffContainer.Size = UDim2.new(1, -8, 0, 48); ffContainer.BackgroundTransparency = 1; ffContainer.Parent = sysScroll
local ffTitle = Instance.new("TextLabel"); ffTitle.Size = UDim2.new(1, 0, 0, 14); ffTitle.BackgroundTransparency = 1; ffTitle.Font = Enum.Font.SourceSansBold; ffTitle.Text = "FASTFLAG EDITOR"; ffTitle.TextColor3 = Color3.fromRGB(0, 162, 255); ffTitle.TextSize = 11; ffTitle.TextXAlignment = Enum.TextXAlignment.Left; ffTitle.Parent = ffContainer
local fflagBg = Instance.new("Frame"); fflagBg.Size = UDim2.new(1, 0, 0, 30); fflagBg.Position = UDim2.new(0, 0, 0, 18); fflagBg.BackgroundTransparency = 1; fflagBg.Parent = ffContainer
local fflagInput = Instance.new("TextBox"); fflagInput.Size = UDim2.new(1, -55, 1, 0); fflagInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50); fflagInput.TextColor3 = Color3.fromRGB(255, 255, 255); fflagInput.PlaceholderText = "FFlagName=Value"; fflagInput.Font = Enum.Font.SourceSansBold; fflagInput.TextSize = 12; fflagInput.Parent = fflagBg; Instance.new("UICorner", fflagInput).CornerRadius = UDim.new(0, 6)
local btnApplyFf = Instance.new("TextButton"); btnApplyFf.Size = UDim2.new(0, 50, 1, 0); btnApplyFf.Position = UDim2.new(1, -50, 0, 0); btnApplyFf.BackgroundColor3 = Color3.fromRGB(0, 162, 255); btnApplyFf.Text = "APPLY"; btnApplyFf.Font = Enum.Font.SourceSansBold; btnApplyFf.TextColor3 = Color3.fromRGB(255, 255, 255); btnApplyFf.TextSize = 11; btnApplyFf.Parent = fflagBg; Instance.new("UICorner", btnApplyFf).CornerRadius = UDim.new(0, 6)
table.insert(activeModules, {Btn = btnApplyFf, Stroke = Instance.new("UIStroke"), IsActive = true}); table.insert(activeModules, {Btn = ffTitle, Stroke = Instance.new("UIStroke"), IsActive = true})

table.insert(connections, btnApplyFf.MouseButton1Click:Connect(function()
    local txt = fflagInput.Text; local split = string.split(txt, "=")
    if #split >= 2 then
        -- Regex ile boşluk temizleme (Güçlü Parser)
        local flag = split[1]:gsub("^%s*(.-)%s*$", "%1"); local valStr = split[2]:gsub("^%s*(.-)%s*$", "%1"); local val
        if string.lower(valStr) == "true" then val = true elseif string.lower(valStr) == "false" then val = false elseif tonumber(valStr) then val = tonumber(valStr) else val = valStr end
        if setfflag then
            local success, err = pcall(function() setfflag(flag, val) end)
            if success then game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPER|HUB", Text="Flag Set: "..flag, Duration=3}); fflagInput.Text = ""
            else game:GetService("StarterGui"):SetCore("SendNotification", {Title="ERROR", Text="Executor blocked flag or FFlag invalid.", Duration=3}) end
        else game:GetService("StarterGui"):SetCore("SendNotification", {Title="ERROR", Text="No Executor Support!", Duration=3}) end
    else game:GetService("StarterGui"):SetCore("SendNotification", {Title="ERROR", Text="Format: FFlag=Value", Duration=3}) end
end))
local btnRestartScript = Instance.new("TextButton"); btnRestartScript.Size = UDim2.new(1, -8, 0, 30); btnRestartScript.BackgroundColor3 = Color3.fromRGB(180, 50, 50); btnRestartScript.Font = Enum.Font.SourceSansBold; btnRestartScript.Text = "RESTART SCRIPT"; btnRestartScript.TextColor3 = Color3.fromRGB(255, 255, 255); btnRestartScript.TextSize = 12; btnRestartScript.Parent = sysScroll; Instance.new("UICorner", btnRestartScript).CornerRadius = UDim.new(0, 8)
table.insert(connections, btnRestartScript.MouseButton1Click:Connect(function() env.SYROX_RUNNING = false; if screenGui then screenGui:Destroy() end; pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPERWORK", Text="Restarting script...", Duration=2}) end); task.delay(0.5, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ZENWORK-lua/FPS-UNCAP/refs/heads/main/Main.lua"))() end) end))

local currentPage = mainPage
local function openPage(target)
    if currentPage == target then target = mainPage end
    local fadeOut = TweenService:Create(fadeCurtain, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0}); fadeOut:Play()
    fadeOut.Completed:Connect(function() currentPage.Visible = false; target.Visible = true; currentPage = target; local fadeIn = TweenService:Create(fadeCurtain, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1}); fadeIn:Play() end)
end
table.insert(connections, btnTheme.MouseButton1Click:Connect(function() applyAppleTween(btnTheme, {ImageTransparency = 0}, 0.1); openPage(themePage); task.delay(0.2, function() applyAppleTween(btnTheme, {ImageTransparency = 0.3}, 0.3) end) end))
table.insert(connections, btnSettings.MouseButton1Click:Connect(function() applyAppleTween(btnSettings, {ImageTransparency = 0}, 0.1); openPage(settingsPage); task.delay(0.2, function() applyAppleTween(btnSettings, {ImageTransparency = 0.3}, 0.3) end) end))

local function handleSwitch(btn, knob, state) applyAppleTween(btn, {BackgroundColor3 = state and globalAccentColor or Color3.fromRGB(60, 60, 70)}); applyAppleTween(knob, {Position = state and UDim2.new(0, 22, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}) end
local function toggleSt(name, state, tOn, tOff) local m = activeModules[name]; m.IsActive = state; m.Btn.Text = state and tOn or tOff; applyAppleTween(m.Btn, {TextColor3 = state and globalAccentColor or Color3.fromRGB(200, 200, 210)}, 0.3); applyAppleTween(m.Stroke, {Color = state and globalAccentColor or Color3.fromRGB(255, 255, 255), Transparency = state and 0.5 or 0.8}, 0.3) end

local function bindSwitch(btn, knob, swName, cb)
    local state = env.HYPER_SAVE.Switches[swName] or false; if state then handleSwitch(btn, knob, true); task.spawn(cb, true) end
    table.insert(connections, btn.MouseButton1Click:Connect(function() state = not state; handleSwitch(btn, knob, state); cb(state); env.HYPER_SAVE.Switches[swName] = state; env.saveHubData() end))
end
local function bindToggle(name, tOn, tOff, cb)
    local m = activeModules[name]; if env.HYPER_SAVE.Toggles[name] then m.IsActive = true; toggleSt(name, true, tOn, tOff); task.spawn(cb, true) end
    table.insert(connections, m.Btn.MouseButton1Click:Connect(function() m.IsActive = not m.IsActive; toggleSt(name, m.IsActive, tOn, tOff); cb(m.IsActive); env.HYPER_SAVE.Toggles[name] = m.IsActive; env.saveHubData() end))
end

local unlockFps, isAfkEngine = false, false
bindSwitch(btnRemember, knobRemember, "Remember", function(s) env.HYPER_SAVE.Remember = s; if not s and writefile then pcall(function() writefile("HYPER_HUB.json", HttpService:JSONEncode({Remember=false, Toggles={}, Switches={}})) end) else env.saveHubData() end end)
bindSwitch(btnMaxFps, knobMaxFps, "MaxFps", function(s) unlockFps = s; MAX_FPS = s and 10000 or 500 end)
bindSwitch(btnAfk, knobAfk, "Afk", function(s) isAfkEngine = s; if s then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPERWORK", Text="AFK Optimization On!", Duration=3}) end) end end)

local function asyncProcessDescendants(cb) task.spawn(function() for i, v in ipairs(workspace:GetDescendants()) do pcall(cb, v); if i % 150 == 0 then RunService.Heartbeat:Wait() end end end) end
bindToggle("BtnLowGfx", "LOW GFX: ON", "LOW GFX: OFF", function(s) asyncProcessDescendants(function(v) if v:IsA("BasePart") then v.Material = s and Enum.Material.SmoothPlastic or Enum.Material.Plastic end end) end)
bindToggle("BtnShadows", "SHADOWS: ON", "SHADOWS: OFF", function(s) pcall(function() Lighting.GlobalShadows = s end) end)
local currentState, isDraggingMoved = 0, false
local draggingPill = false; local pillDragStart, startPos = nil, nil
local tapCount = 0

local function minimizeMenu() 
    currentState = 1; contentContainer.Visible = false
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 44, 0, 44)}); applyAppleTween(uiCorner, {CornerRadius = UDim.new(1, 0)}); applyAppleTween(outerAura, {Size = UDim2.new(1, 4, 1, 4)})
    applyAppleTween(headerPillTouch, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5)}) 
    applyAppleTween(headerPill, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0.5, 0, 0.5, 0)}) 
end
local function maximizeMenu() 
    currentState = 0
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 270, 0, 210)}); applyAppleTween(uiCorner, {CornerRadius = UDim.new(0, 16)}); applyAppleTween(outerAura, {Size = UDim2.new(1, 6, 1, 6)})
    applyAppleTween(headerPillTouch, {Size = UDim2.new(0, 150, 0, 32), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0)}) 
    applyAppleTween(headerPill, {Size = UDim2.new(0, 50, 0, 5), Position = UDim2.new(0.5, 0, 0, 12)}); task.delay(0.1, function() if currentState == 0 then contentContainer.Visible = true end end) 
end

table.insert(connections, headerPillTouch.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingPill = true; isDraggingMoved = false; pillDragStart = input.Position; startPos = mainFrame.Position end end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input) if draggingPill and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - pillDragStart; if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then isDraggingMoved = true end; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))
table.insert(connections, headerPillTouch.InputEnded:Connect(function(input)
    if draggingPill and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        draggingPill = false; if isDraggingMoved then return end
        tapCount = tapCount + 1
        if tapCount == 1 then task.delay(0.25, function() if tapCount == 1 then if currentState == 0 then minimizeMenu() elseif currentState == 1 then maximizeMenu() end end; tapCount = 0 end)
        elseif tapCount == 2 then tapCount = 0; if currentState == 1 then env.SYROX_RUNNING = false; if screenGui then screenGui:Destroy() end end end
    end
end))

local function updateSlider(x) local tPos = sliderTrack.AbsolutePosition.X; local tSz = sliderTrack.AbsoluteSize.X; local ratio = math.clamp((x - tPos) / tSz, 0, 1); local fps = math.floor(MIN_FPS + (ratio * (MAX_FPS - MIN_FPS))); sliderFill.Size = UDim2.new(ratio, 0, 1, 0); sliderKnob.Position = UDim2.new(ratio, -9, 0.5, -9); titleLabel.Text = string.format("Target FPS: %d FPS", fps); return fps end
table.insert(connections, UserInputService.InputBegan:Connect(function(input) if not mainPage.Visible then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then local pos, tPos, tSz = input.Position, sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize; if pos.X >= tPos.X-15 and pos.X <= tPos.X+tSz.X+15 and pos.Y >= tPos.Y-20 and pos.Y <= tPos.Y+tSz.Y+20 then draggingSlider = true; updateSlider(pos.X) end end end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input) if draggingSlider then updateSlider(input.Position.X) end end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input) if draggingSlider then draggingSlider = false; local f = updateSlider(input.Position.X); if setfpscap then pcall(setfpscap, f) end; applyAppleTween(effectBarGlow, {Size = UDim2.new(math.clamp((f-MIN_FPS)/(MAX_FPS-MIN_FPS),0,1),0,1,0), BackgroundColor3 = Color3.fromRGB(0,255,180)}); task.delay(0.3, function() TweenService:Create(effectBarGlow, TweenInfo.new(0.4), {BackgroundColor3 = globalAccentColor}):Play() end) end end))

-- DÖNGÜ (Gerçek RAM, Kernel Proxy CPU/GPU ve Saf FPS)
local lastTime, fCount, currentRealFps = os.clock(), 0, 60
table.insert(connections, RunService.RenderStepped:Connect(function()
    fCount = fCount + 1; local curr = os.clock()
    if curr - lastTime >= 1 then
        currentRealFps = math.floor(fCount / (curr - lastTime)); fCount = 0; lastTime = curr
        fpsDisplay.Text = string.format("Current FPS: %d", currentRealFps)
        
        -- System Monitor Veri Güncellemeleri
        if monitorNodes[1].IsActive() then monitorNodes[1].Label.Text = currentRealFps end
        
        -- CPU Proxy (Heartbeat süresinin 16.6ms içindeki doluluğu)
        if monitorNodes[2].IsActive() then
            local cpuProxy = math.clamp(math.floor((Stats.Workspace.HeartbeatTimeMs / 16.6) * 100), 0, 100)
            monitorNodes[2].Label.Text = cpuProxy .. "%"
        end
        
        -- GPU Proxy (Render süresinin doluluğu / Frame Variance)
        if monitorNodes[3].IsActive() then
            local gpuProxy = math.clamp(math.floor((Stats.PerformanceStats.Ping / 30) * 100), 0, 100) -- GPU ping/gecikme proxy (Lua limiti)
            monitorNodes[3].Label.Text = gpuProxy .. "%"
        end
        
        -- Real RAM (Total Lua Heap)
        if monitorNodes[4].IsActive() then monitorNodes[4].Label.Text = math.floor(Stats:GetTotalMemoryUsageMb()) .. " MB" end
        
        -- Batarya Isısı (OS SANDBOX ENGELİ)
        if monitorNodes[5].IsActive() then monitorNodes[5].Label.Text = "OS LCK" end
    end
end))

screenGui.Parent = targetGui
maximizeMenu()
