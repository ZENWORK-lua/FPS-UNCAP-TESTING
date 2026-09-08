-- [[ HYPER|HUB - STABLE ]]
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- 
local env = (getgenv and getgenv()) or _G
local function getSafeGuiParent()
    local p = nil; if gethui then pcall(function() p = gethui() end) end
    if not p then pcall(function() p = game:GetService("CoreGui") end) end
    if not p or not pcall(function() local _ = p.Name end) then p = Players.LocalPlayer:WaitForChild("PlayerGui") end
    return p
end
local targetGui = getSafeGuiParent()

if env.SYROX_RUNNING and targetGui:FindFirstChild("FPSCapUI") then
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPER", Text="Script is already running, but you can restart it from settings.", Duration=4}) end)
    return
end
if env.FPSCapUIConnections then for _, c in ipairs(env.FPSCapUIConnections) do if c and c.Connected then c:Disconnect() end end end
if targetGui:FindFirstChild("FPSCapUI") then targetGui.FPSCapUI:Destroy() end
env.FPSCapUIConnections = {}; local connections = env.FPSCapUIConnections
env.SYROX_RUNNING = true

-- [[ DATA SAVING ]]
env.HYPER_SAVE = {Remember = false, Toggles = {}, Switches = {}}
if isfile and readfile and isfile("HYPER_HUB.json") then pcall(function() env.HYPER_SAVE = HttpService:JSONDecode(readfile("HYPER_HUB.json")) end) end
if not env.HYPER_SAVE.Toggles then env.HYPER_SAVE.Toggles = {} end
if not env.HYPER_SAVE.Switches then env.HYPER_SAVE.Switches = {} end
env.saveHubData = function() if env.HYPER_SAVE.Remember and writefile then pcall(function() writefile("HYPER_HUB.json", HttpService:JSONEncode(env.HYPER_SAVE)) end) end end

local origSettings = { GlobalShadows = Lighting.GlobalShadows, QualityLevel = settings().Rendering.QualityLevel, WaterWaveSize = workspace.Terrain.WaterWaveSize, WaterWaveSpeed = workspace.Terrain.WaterWaveSpeed, WaterReflectance = workspace.Terrain.WaterReflectance }
local MIN_FPS, MAX_FPS = 5, 500; local currentTargetFps = setfpscap and 120
local function applyAppleTween(obj, props, dur) TweenService:Create(obj, TweenInfo.new(dur or 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play() end
-- [[ UI: MAIN ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSCapUI"; screenGui.ResetOnSpawn = false; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local afkScreen = Instance.new("Frame")
afkScreen.Size = UDim2.new(1, 0, 1, 0); afkScreen.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
afkScreen.ZIndex = 999; afkScreen.Visible = false; afkScreen.Parent = screenGui
local afkText = Instance.new("TextLabel")
afkText.Size = UDim2.new(1, 0, 1, 0); afkText.BackgroundTransparency = 1; afkText.Font = Enum.Font.GothamBold
afkText.Text = "AFK optimization activated.\nClick anywhere to stop"; afkText.TextColor3 = Color3.fromRGB(20, 20, 20); afkText.TextSize = 24; afkText.Parent = afkScreen
local fpsMonFrame = Instance.new("Frame"); fpsMonFrame.Size = UDim2.new(0, 100, 0, 26); fpsMonFrame.Position = UDim2.new(0.5, 0, 0, 10); fpsMonFrame.AnchorPoint = Vector2.new(0.5, 0); fpsMonFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); fpsMonFrame.BackgroundTransparency = 0.4; fpsMonFrame.Visible = false; fpsMonFrame.Parent = screenGui
Instance.new("UICorner", fpsMonFrame).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", fpsMonFrame).Color = Color3.fromRGB(0, 162, 255)
local fpsMonText = Instance.new("TextLabel"); fpsMonText.Size = UDim2.new(1, 0, 1, 0); fpsMonText.BackgroundTransparency = 1; fpsMonText.Font = Enum.Font.GothamBold; fpsMonText.Text = "FPS: 60"; fpsMonText.TextColor3 = Color3.fromRGB(255, 255, 255); fpsMonText.TextSize = 13; fpsMonText.Parent = fpsMonFrame

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0, 0, 0, 0); mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5); mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BackgroundTransparency = 0.25; mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.ClipsDescendants = false; mainFrame.Parent = screenGui

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 52)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))})
bgGradient.Rotation = 45; bgGradient.Parent = mainFrame
local uiCorner = Instance.new("UICorner"); uiCorner.CornerRadius = UDim.new(1, 0); uiCorner.Parent = mainFrame

local outerAura = Instance.new("Frame"); outerAura.Size = UDim2.new(1, 6, 1, 6); outerAura.Position = UDim2.new(0.5, 0, 0.5, 0); outerAura.AnchorPoint = Vector2.new(0.5, 0.5); outerAura.BackgroundTransparency = 1; outerAura.Active = false; outerAura.Parent = mainFrame
Instance.new("UICorner", outerAura).CornerRadius = UDim.new(0, 19)
local auraStroke = Instance.new("UIStroke"); auraStroke.Color = Color3.fromRGB(0, 162, 255); auraStroke.Thickness = 1.2; auraStroke.Transparency = 1; auraStroke.Parent = outerAura

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(1, 0, 1, 0); introText.BackgroundTransparency = 1; introText.Font = Enum.Font.GothamBold
introText.Text = "HYPER|FPS"; introText.TextColor3 = Color3.fromRGB(255, 255, 255); introText.TextSize = 17; introText.TextTransparency = 1; introText.ZIndex = 100; introText.Parent = mainFrame
-- [[ EXTERNAL NAVIGATION ]]
local extBtnClose = Instance.new("TextButton"); extBtnClose.Size = UDim2.new(0, 36, 0, 36); extBtnClose.AnchorPoint = Vector2.new(0.5, 0.5); extBtnClose.Position = UDim2.new(1, 30, 0, 24); extBtnClose.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
extBtnClose.Text = "×"; extBtnClose.Font = Enum.Font.GothamBold; extBtnClose.TextSize = 22; extBtnClose.TextColor3 = Color3.fromRGB(220, 220, 220); extBtnClose.Visible = false; extBtnClose.Parent = mainFrame
Instance.new("UICorner", extBtnClose).CornerRadius = UDim.new(1, 0)
local extCloseScale = Instance.new("UIScale", extBtnClose)

local extBtnMin = Instance.new("TextButton"); extBtnMin.Size = UDim2.new(0, 36, 0, 36); extBtnMin.AnchorPoint = Vector2.new(0.5, 0.5); extBtnMin.Position = UDim2.new(1, 30, 0, 64); extBtnMin.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
extBtnMin.Text = "-"; extBtnMin.Font = Enum.Font.GothamBold; extBtnMin.TextSize = 26; extBtnMin.TextColor3 = Color3.fromRGB(220, 220, 220); extBtnMin.Visible = false; extBtnMin.Parent = mainFrame
Instance.new("UICorner", extBtnMin).CornerRadius = UDim.new(1, 0)
local extMinScale = Instance.new("UIScale", extBtnMin)

local function attachScaleHoldAnim(btn, scaleObj)
    table.insert(connections, btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then applyAppleTween(scaleObj, {Scale = 1.08}, 0.15) end end))
    table.insert(connections, btn.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then applyAppleTween(scaleObj, {Scale = 1}, 0.25) end end))
end

attachScaleHoldAnim(extBtnClose, extCloseScale); attachScaleHoldAnim(extBtnMin, extMinScale)
-- [[ UI: HEADER & CONTAINERS ]]
local headerPillTouch = Instance.new("TextButton"); headerPillTouch.Size = UDim2.new(0, 150, 0, 32); headerPillTouch.Position = UDim2.new(0.5, 0, 0, 0); headerPillTouch.AnchorPoint = Vector2.new(0.5, 0); headerPillTouch.BackgroundTransparency = 1; headerPillTouch.Text = ""; headerPillTouch.ZIndex = 50; headerPillTouch.Parent = mainFrame
local headerPill = Instance.new("Frame"); headerPill.Size = UDim2.new(0, 50, 0, 5); headerPill.Position = UDim2.new(0.5, 0, 0, 12); headerPill.AnchorPoint = Vector2.new(0.5, 0.5); headerPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); headerPill.BackgroundTransparency = 1; headerPill.ZIndex = 1; headerPill.Active = false; headerPill.Parent = mainFrame
Instance.new("UICorner", headerPill).CornerRadius = UDim.new(1, 0)

local contentContainer = Instance.new("Frame"); contentContainer.Size = UDim2.new(1, 0, 1, 0); contentContainer.BackgroundTransparency = 1; contentContainer.ClipsDescendants = true; contentContainer.Visible = false; contentContainer.Parent = mainFrame

local infoOverlay = Instance.new("Frame"); infoOverlay.Size = UDim2.new(1, 0, 1, 0); infoOverlay.BackgroundColor3 = Color3.fromRGB(15, 15, 20); infoOverlay.BackgroundTransparency = 0.1; infoOverlay.ZIndex = 60; infoOverlay.Visible = false; infoOverlay.Parent = mainFrame
Instance.new("UICorner", infoOverlay).CornerRadius = UDim.new(0, 16)
local infoBody = Instance.new("TextLabel"); infoBody.Size = UDim2.new(1, -20, 1, -50); infoBody.Position = UDim2.new(0, 10, 0, 10); infoBody.BackgroundTransparency = 1; infoBody.Font = Enum.Font.SourceSansBold; infoBody.TextWrapped = true; infoBody.TextColor3 = Color3.fromRGB(240, 240, 250); infoBody.TextSize = 13; infoBody.Text = "Information:\n\nTo close the script:\nFirst minimize the menu, then double-tap the circle icon."; infoBody.Parent = infoOverlay
local btnCloseInfo = Instance.new("TextButton"); btnCloseInfo.Size = UDim2.new(0, 160, 0, 28); btnCloseInfo.Position = UDim2.new(0.5, -80, 1, -38); btnCloseInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 50); btnCloseInfo.BackgroundTransparency = 0.3; btnCloseInfo.Font = Enum.Font.SourceSansBold; btnCloseInfo.Text = "Close this information"; btnCloseInfo.TextColor3 = Color3.fromRGB(255, 255, 255); btnCloseInfo.TextSize = 12; btnCloseInfo.Parent = infoOverlay
Instance.new("UICorner", btnCloseInfo).CornerRadius = UDim.new(0, 8)
local infoScale = Instance.new("UIScale", btnCloseInfo); attachScaleHoldAnim(btnCloseInfo, infoScale)
local mainPage = Instance.new("Frame"); mainPage.Size = UDim2.new(1, 0, 1, 0); mainPage.BackgroundTransparency = 1; mainPage.Parent = contentContainer
local themePage = Instance.new("Frame"); themePage.Size = UDim2.new(1, 0, 1, 0); themePage.BackgroundTransparency = 1; themePage.Visible = false; themePage.Parent = contentContainer
local settingsPage = Instance.new("Frame"); settingsPage.Size = UDim2.new(1, 0, 1, 0); settingsPage.BackgroundTransparency = 1; settingsPage.Visible = false; settingsPage.Parent = contentContainer
local confirmPage = Instance.new("Frame"); confirmPage.Size = UDim2.new(1, 0, 1, 0); confirmPage.BackgroundTransparency = 1; confirmPage.Visible = false; confirmPage.Parent = contentContainer
local fadeCurtain = Instance.new("Frame"); fadeCurtain.Size = UDim2.new(1, 0, 1, 0); fadeCurtain.BackgroundColor3 = Color3.fromRGB(10, 10, 15); fadeCurtain.BackgroundTransparency = 1; fadeCurtain.ZIndex = 10; fadeCurtain.Parent = contentContainer; Instance.new("UICorner", fadeCurtain).CornerRadius = UDim.new(0, 16)

local btnTheme = Instance.new("ImageButton"); btnTheme.Size = UDim2.new(0, 20, 0, 20); btnTheme.Position = UDim2.new(1, -60, 0, 18); btnTheme.BackgroundTransparency = 1; btnTheme.Image = "rbxassetid://3926307971"; btnTheme.ImageRectOffset = Vector2.new(764, 244); btnTheme.ImageRectSize = Vector2.new(36, 36); btnTheme.ImageColor3 = Color3.fromRGB(255, 255, 255); btnTheme.ImageTransparency = 0.3; btnTheme.ZIndex = 11; btnTheme.AnchorPoint = Vector2.new(0.5, 0.5); btnTheme.Position = UDim2.new(1, -50, 0, 28); btnTheme.Parent = contentContainer
local btnSettings = Instance.new("ImageButton"); btnSettings.Size = UDim2.new(0, 20, 0, 20); btnSettings.BackgroundTransparency = 1; btnSettings.Image = "rbxassetid://3926307971"; btnSettings.ImageRectOffset = Vector2.new(324, 124); btnSettings.ImageRectSize = Vector2.new(36, 36); btnSettings.ImageColor3 = Color3.fromRGB(255, 255, 255); btnSettings.ImageTransparency = 0.3; btnSettings.ZIndex = 11; btnSettings.AnchorPoint = Vector2.new(0.5, 0.5); btnSettings.Position = UDim2.new(1, -24, 0, 28); btnSettings.Parent = contentContainer

local titleLabel = Instance.new("TextLabel"); titleLabel.Size = UDim2.new(1, -24, 0, 22); titleLabel.Position = UDim2.new(0, 12, 0, 20); titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.SourceSansBold; titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240); titleLabel.TextSize = 15; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Text = string.format("Target FPS: %d FPS", currentTargetFps); titleLabel.Parent = mainPage
local effectBarBg = Instance.new("Frame"); effectBarBg.Size = UDim2.new(1, -24, 0, 5); effectBarBg.Position = UDim2.new(0, 12, 0, 66); effectBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50); effectBarBg.BackgroundTransparency = 0.3; effectBarBg.BorderSizePixel = 0; effectBarBg.Parent = mainPage; Instance.new("UICorner", effectBarBg).CornerRadius = UDim.new(1, 0)
local sliderTrack = Instance.new("Frame"); sliderTrack.Size = UDim2.new(1, -24, 0, 6); sliderTrack.Position = UDim2.new(0, 12, 0, 85); sliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 55); sliderTrack.BorderSizePixel = 0; sliderTrack.Parent = mainPage; Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)
local initialRatio = math.clamp((currentTargetFps - MIN_FPS) / (MAX_FPS - MIN_FPS), 0, 1)
local effectBarGlow = Instance.new("Frame"); effectBarGlow.Size = UDim2.new(initialRatio, 0, 1, 0); effectBarGlow.BackgroundColor3 = Color3.fromRGB(0, 162, 255); effectBarGlow.Parent = effectBarBg; Instance.new("UICorner", effectBarGlow).CornerRadius = UDim.new(1, 0)
local sliderFill = Instance.new("Frame"); sliderFill.Size = UDim2.new(initialRatio, 0, 1, 0); sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255); sliderFill.Parent = sliderTrack; Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
local sliderKnob = Instance.new("Frame"); sliderKnob.Size = UDim2.new(0, 18, 0, 18); sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5); sliderKnob.Position = UDim2.new(initialRatio, 0, 0.5, 0); sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); sliderKnob.Parent = sliderTrack; Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)
local fpsDisplay = Instance.new("TextLabel"); fpsDisplay.Size = UDim2.new(1, -24, 0, 18); fpsDisplay.Position = UDim2.new(0, 12, 0, 42); fpsDisplay.BackgroundTransparency = 1; fpsDisplay.Font = Enum.Font.SourceSansSemibold; fpsDisplay.TextColor3 = Color3.fromRGB(160, 160, 175); fpsDisplay.TextSize = 13; fpsDisplay.TextXAlignment = Enum.TextXAlignment.Left; fpsDisplay.Text = "Current FPS: 0"; fpsDisplay.Parent = mainPage

local stabTitle = Instance.new("TextLabel"); stabTitle.Size = UDim2.new(1, -24, 0, 16); stabTitle.Position = UDim2.new(0, 12, 0, 110); stabTitle.BackgroundTransparency = 1; stabTitle.Font = Enum.Font.SourceSansBold; stabTitle.Text = "FEATURES (SWIPE RIGHT ->)"; stabTitle.TextColor3 = Color3.fromRGB(0, 200, 255); stabTitle.TextSize = 11; stabTitle.TextXAlignment = Enum.TextXAlignment.Left; stabTitle.Parent = mainPage
local hMask = Instance.new("CanvasGroup"); hMask.Size = UDim2.new(1, -24, 0, 65); hMask.Position = UDim2.new(0, 12, 0, 130); hMask.BackgroundTransparency = 1; hMask.BorderSizePixel = 0; hMask.Parent = mainPage
local hGrad = Instance.new("UIGradient"); hGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1)}); hGrad.Parent = hMask
local scrollFrame = Instance.new("ScrollingFrame"); scrollFrame.Size = UDim2.new(1, 0, 1, 0); scrollFrame.BackgroundTransparency = 1; scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 0; scrollFrame.ScrollingDirection = Enum.ScrollingDirection.X; scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.X; scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0); scrollFrame.Parent = hMask 
local gridLayout = Instance.new("UIGridLayout"); gridLayout.CellSize = UDim2.new(0, 115, 0, 28); gridLayout.CellPadding = UDim2.new(0, 8, 0, 8); gridLayout.FillDirection = Enum.FillDirection.Vertical; gridLayout.Parent = scrollFrame

local segmentBg = Instance.new("Frame"); segmentBg.Size = UDim2.new(0, 160, 0, 26); segmentBg.Position = UDim2.new(0, 12, 0, 14); segmentBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30); segmentBg.Parent = settingsPage; Instance.new("UICorner", segmentBg).CornerRadius = UDim.new(1, 0)
local segmentSlider = Instance.new("Frame"); segmentSlider.Size = UDim2.new(0, 95, 1, -4); segmentSlider.Position = UDim2.new(0, 2, 0, 2); segmentSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 70); segmentSlider.Parent = segmentBg; Instance.new("UICorner", segmentSlider).CornerRadius = UDim.new(1, 0)
local btnSysTab = Instance.new("TextButton"); btnSysTab.Size = UDim2.new(0, 95, 1, 0); btnSysTab.Position = UDim2.new(0, 0, 0, 0); btnSysTab.BackgroundTransparency = 1; btnSysTab.Font = Enum.Font.SourceSansBold; btnSysTab.Text = "SYSTEM"; btnSysTab.TextColor3 = Color3.fromRGB(255, 255, 255); btnSysTab.TextSize = 11; btnSysTab.Parent = segmentBg
local btnFeatTab = Instance.new("TextButton"); btnFeatTab.Size = UDim2.new(0, 65, 1, 0); btnFeatTab.Position = UDim2.new(0, 95, 0, 0); btnFeatTab.BackgroundTransparency = 1; btnFeatTab.Font = Enum.Font.SourceSansBold; btnFeatTab.Text = "MORE"; btnFeatTab.TextColor3 = Color3.fromRGB(150, 150, 160); btnFeatTab.TextSize = 11; btnFeatTab.Parent = segmentBg

local vMask = Instance.new("CanvasGroup"); vMask.Size = UDim2.new(1, -24, 0, 140); vMask.Position = UDim2.new(0, 12, 0, 55); vMask.BackgroundTransparency = 1; vMask.BorderSizePixel = 0; vMask.Parent = settingsPage
local vGrad = Instance.new("UIGradient"); vGrad.Rotation = 90; vGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1)}); vGrad.Parent = vMask
local sysScroll = Instance.new("ScrollingFrame"); sysScroll.Size = UDim2.new(1, 0, 1, 0); sysScroll.BackgroundTransparency = 1; sysScroll.BorderSizePixel = 0; sysScroll.ScrollBarThickness = 0; sysScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; sysScroll.CanvasSize = UDim2.new(0, 0, 0, 0); sysScroll.Parent = vMask
local featScroll = Instance.new("ScrollingFrame"); featScroll.Size = UDim2.new(1, 0, 1, 0); featScroll.BackgroundTransparency = 1; featScroll.BorderSizePixel = 0; featScroll.ScrollBarThickness = 0; featScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; featScroll.CanvasSize = UDim2.new(0, 0, 0, 0); featScroll.Visible = false; featScroll.Parent = vMask
local sysList = Instance.new("UIListLayout", sysScroll); sysList.Padding = UDim.new(0, 10); sysList.SortOrder = Enum.SortOrder.LayoutOrder
local featList = Instance.new("UIListLayout", featScroll); featList.Padding = UDim.new(0, 10); featList.SortOrder = Enum.SortOrder.LayoutOrder
local globalAccentColor = Color3.fromRGB(0, 162, 255)
local activeModules = {}
local switchRegistry = {}

local function createBtn(name, text, p)
    local btn = Instance.new("TextButton"); btn.Name = name; btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); btn.BackgroundTransparency = 0.3; btn.Font = Enum.Font.SourceSansBold; btn.Text = text; btn.TextColor3 = Color3.fromRGB(200, 200, 210); btn.TextSize = 11; btn.Parent = p or scrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local str = Instance.new("UIStroke", btn); str.Color = Color3.fromRGB(255, 255, 255); str.Thickness = 1; str.Transparency = 0.8
    local scale = Instance.new("UIScale", btn); attachScaleHoldAnim(btn, scale)
    activeModules[name] = {Btn = btn, Stroke = str, IsActive = false}; return btn, str
end

local btnRejoin = createBtn("BtnRejoin", "REJOIN SERVER")
local btnGfxLvl = createBtn("BtnGfx", "GFX LVL: AUTO"); local btnLowGfx = createBtn("BtnLowGfx", "LOW GFX: OFF")
local btnShadows = createBtn("BtnShadows", "SHADOWS: ON"); local btnCastS = createBtn("BtnCastS", "CAST-SHDW: ON")
local btnTex = createBtn("BtnTex", "TEXTURES: HIGH"); local btnPart = createBtn("BtnPart", "PARTICLES: ON")
local btnHigh = createBtn("BtnHigh", "HIGHLIGHTS: ON"); local btnWater = createBtn("BtnWater", "WATER: HIGH")
local btnGlow = createBtn("BtnGlow", "POST-FX: ON"); local btnAudio = createBtn("BtnAudio", "3D AUDIO: ON")
local btnGui = createBtn("BtnGui", "HIDE GUIS: OFF"); local btn3d = createBtn("Btn3d", "NO RENDER: OFF")

local function createSwitch(text, parent)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -8, 0, 30); f.BackgroundTransparency = 1; f.Parent = parent
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -50, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.SourceSansBold; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(200, 200, 210); lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -40, 0.5, -10); btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70); btn.Text = ""; btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 16, 0, 16); knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.new(0, 10, 0.5, 0); knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255); knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    return btn, knob, f
end
-- [[ HYPER|HUB - EXPANDABLE MULTI-LANG MODULE ]]
local currentLang = env.HYPER_SAVE.Language or "EN"

local langData = {
    EN = {
        SysTab = "SYSTEM", MoreTab = "MORE", ThemeTitle = "MY THEMES",
        Restart = "RESTART SCRIPT", DiscordText = "Report bugs on Discord: lowkeyzenith",
        TargetFps = "Target FPS: %d FPS", CurrentFps = "Current FPS: %d",
        FeaturesTitle = "FEATURES (SWIPE RIGHT ->)",
        
        Remember = "Remember Changes", MaxFps = "Remove 500 FPS Limit",
        AutoExec = "Auto-Execute On Teleport", ExtNav = "External Navigation",
        FpsMon = "Live FPS Monitor", Afk = "AFK Optimization",
        DynRes = "Dynamic Res Scaler (BETA)", DistCull = "Distance Quality Culling",
        AnimLim = "Distance Anim Limiter", DeepRam = "Deep RAM Flush",
        
        Rejoin = "REJOIN SERVER", GfxLvl = "GFX LVL: AUTO",
        LowGfx_OFF = "LOW GFX: OFF", LowGfx_ON = "LOW GFX: ON",
        Shadows_ON = "SHADOWS: ON", Shadows_OFF = "SHADOWS: OFF",
        CastS_ON = "CAST-SHDW: ON", CastS_OFF = "CAST-SHDW: OFF",
        Tex_HIGH = "TEXTURES: HIGH", Tex_LOW = "TEXTURES: LOW",
        Part_ON = "PARTICLES: ON", Part_OFF = "PARTICLES: OFF",
        High_ON = "HIGHLIGHTS: ON", High_OFF = "HIGHLIGHTS: OFF",
        Water_HIGH = "WATER: HIGH", Water_LOW = "WATER: LOW",
        Glow_ON = "POST-FX: ON", Glow_OFF = "POST-FX: OFF",
        Audio_ON = "3D AUDIO: ON", Audio_OFF = "3D AUDIO: OFF",
        Gui_OFF = "HIDE GUIS: OFF", Gui_ON = "HIDE GUIS: ON",
        Render3d_OFF = "NO RENDER: OFF", Render3d_ON = "NO RENDER: ON",
        
        InfoTitle = "Information:\n\nTo close the script:\nFirst minimize the menu, then double-tap the circle icon.",
        CloseInfo = "Close this information", ConfirmClose = "Do you want to close the script?",
        ConfirmPersist = "Do you want the changes to persist?", Yes = "Yes", Nope = "Nope"
    },
    TR = {
        SysTab = "SİSTEM", MoreTab = "DİĞER", ThemeTitle = "TEMALARIM",
        Restart = "SCRİPT'İ YENİDEN BAŞLAT", DiscordText = "Hataları Discord'dan bildirin: lowkeyzenith",
        TargetFps = "Hedef FPS: %d FPS", CurrentFps = "Mevcut FPS: %d",
        FeaturesTitle = "ÖZELLİKLER (SAĞA KAYDIR ->)",
        
        Remember = "Değişiklikleri Hatırla", MaxFps = "500 FPS Sınırını Kaldır",
        AutoExec = "Işınlanmada Oto-Çalıştır", ExtNav = "Harici Gezinme",
        FpsMon = "Canlı FPS Monitörü", Afk = "AFK Optimizasyonu",
        DynRes = "Dinamik Çözünürlük (BETA)", DistCull = "Mesafe Kalite Filtresi",
        AnimLim = "Mesafe Animasyon Sınırı", DeepRam = "Derin RAM Temizliği",
        
        Rejoin = "SUNUCUYA YENİDEN KATIL", GfxLvl = "GFX SEVİYE: OTO",
        LowGfx_OFF = "DÜŞÜK GFX: KAPALI", LowGfx_ON = "DÜŞÜK GFX: AÇIK",
        Shadows_ON = "GÖLGELER: AÇIK", Shadows_OFF = "GÖLGELER: KAPALI",
        CastS_ON = "GÖLGE DÜŞÜRME: AÇIK", CastS_OFF = "GÖLGE DÜŞÜRME: KAPALI",
        Tex_HIGH = "DOKULAR: YÜKSEK", Tex_LOW = "DOKULAR: DÜŞÜK",
        Part_ON = "PARÇACIKLAR: AÇIK", Part_OFF = "PARÇACIKLAR: KAPALI",
        High_ON = "VURGULAR: AÇIK", High_OFF = "VURGULAR: KAPALI",
        Water_HIGH = "SU KALİTESİ: YÜKSEK", Water_LOW = "SU KALİTESİ: DÜŞÜK",
        Glow_ON = "EFEKTLER: AÇIK", Glow_OFF = "EFEKTLER: KAPALI",
        Audio_ON = "3D SES: AÇIK", Audio_OFF = "3D SES: KAPALI",
        Gui_OFF = "ARAYÜZ HİZALA: KAPALI", Gui_ON = "ARAYÜZ HİZALA: AÇIK",
        Render3d_OFF = "RENDER YOK: KAPALI", Render3d_ON = "RENDER YOK: AÇIK",
        
        InfoTitle = "Bilgilendirme:\n\nScripti kapatmak için:\nÖnce menüyü küçültün, ardından yuvarlak simgeye çift dokunun.",
        CloseInfo = "Bilgilendirmeyi Kapat", ConfirmClose = "Scripti kapatmak istiyor musunuz?",
        ConfirmPersist = "Değişiklikler kalıcı olsun mu?", Yes = "Evet", Nope = "Hayır"
    },
    ES = {
        SysTab = "SISTEMA", MoreTab = "MÁS", ThemeTitle = "MIS TEMAS",
        Restart = "REINICIAR SCRIPT", DiscordText = "Reportar errores en Discord: lowkeyzenith",
        TargetFps = "FPS Objetivo: %d FPS", CurrentFps = "FPS Actual: %d",
        FeaturesTitle = "FUNCIONES (DESLIZA DERECHA ->)",
        
        Remember = "Recordar Cambios", MaxFps = "Sin Límite de 500 FPS",
        AutoExec = "Auto-Ejecutar al Teletransportar", ExtNav = "Navegación Externa",
        FpsMon = "Monitor de FPS en Vivo", Afk = "Optimización AFK",
        DynRes = "Escalador Dinámico (BETA)", DistCull = "Filtro por Distancia",
        AnimLim = "Limitador de Animación", DeepRam = "Limpieza Profunda de RAM",
        
        Rejoin = "REUNIRSE AL SERVIDOR", GfxLvl = "NIVEL GFX: AUTO",
        LowGfx_OFF = "GFX BAJO: OFF", LowGfx_ON = "GFX BAJO: ON",
        Shadows_ON = "SOMBRAS: ON", Shadows_OFF = "SOMBRAS: OFF",
        CastS_ON = "PROYECTAR SOMBRAS: ON", CastS_OFF = "PROYECTAR SOMBRAS: OFF",
        Tex_HIGH = "TEXTURAS: ALTAS", Tex_LOW = "TEXTURAS: BAJAS",
        Part_ON = "PARTÍCULAS: ON", Part_OFF = "PARTÍCULAS: OFF",
        High_ON = "DESTACADOS: ON", High_OFF = "DESTACADOS: OFF",
        Water_HIGH = "AGUA: ALTA", Water_LOW = "AGUA: BAJA",
        Glow_ON = "POST-FX: ON", Glow_OFF = "POST-FX: OFF",
        Audio_ON = "AUDIO 3D: ON", Audio_OFF = "AUDIO 3D: OFF",
        Gui_OFF = "OCULTAR GUIS: OFF", Gui_ON = "OCULTAR GUIS: ON",
        Render3d_OFF = "SIN RENDER: OFF", Render3d_ON = "SIN RENDER: ON",
        
        InfoTitle = "Información:\n\nPara cerrar el script:\nPrimero minimice el menú, luego toque dos veces el ícono circular.",
        CloseInfo = "Cerrar esta información", ConfirmClose = "¿Quieres cerrar el script?",
        ConfirmPersist = "¿Quieres que los cambios persistan?", Yes = "Sí", Nope = "No"
    },
    RU = {
        SysTab = "СИСТЕМА", MoreTab = "ЕЩЕ", ThemeTitle = "МОИ ТЕМЫ",
        Restart = "ПЕРЕЗАПУСТИТЬ СКРИПТ", DiscordText = "Ошибки в Discord: lowkeyzenith",
        TargetFps = "Целевой FPS: %d FPS", CurrentFps = "Текущий FPS: %d",
        FeaturesTitle = "ФУНКЦИИ (СМАЙП ВПРАВО ->)",
        
        Remember = "Запомнить Изменения", MaxFps = "Снять Лимит 500 FPS",
        AutoExec = "Авто-Запуск при Телепорте", ExtNav = "Внешняя Навигация",
        FpsMon = "Монитор FPS", Afk = "Оптимизация AFK",
        DynRes = "Динамическое Разрешение", DistCull = "Фильтр Дальности",
        AnimLim = "Ограничитель Анимаций", DeepRam = "Глубокая Очистка ОЗУ",
        
        Rejoin = "ПЕРЕПОДКЛЮЧИТЬСЯ", GfxLvl = "ГРАФИКА: АВТО",
        LowGfx_OFF = "НИЗК. ГРАФИКА: ВЫКЛ", LowGfx_ON = "НИЗК. ГРАФИКА: ВКЛ",
        Shadows_ON = "ТЕНИ: ВКЛ", Shadows_OFF = "ТЕНИ: ВЫКЛ",
        CastS_ON = "ОТБРАСЫВАТЬ ТЕНИ: ВКЛ", CastS_OFF = "ОТБРАСЫВАТЬ ТЕНИ: ВЫКЛ",
        Tex_HIGH = "ТЕКСТУРЫ: ВЫСОКИЕ", Tex_LOW = "ТЕКСТУРЫ: НИЗКИЕ",
        Part_ON = "ЧАСТИЦЫ: ВКЛ", Part_OFF = "ЧАСТИЦЫ: ВЫКЛ",
        High_ON = "ПОДСВЕТКА: ВКЛ", High_OFF = "ПОДСВЕТКА: ВЫКЛ",
        Water_HIGH = "ВОДА: ВЫСОКАЯ", Water_LOW = "ВОДА: НИЗКАЯ",
        Glow_ON = "ПОСТ-ЭФФЕКТЫ: ВКЛ", Glow_OFF = "ПОСТ-ЭФФЕКТЫ: ВЫКЛ",
        Audio_ON = "3D ЗВУК: ВКЛ", Audio_OFF = "3D ЗВУК: ВЫКЛ",
        Gui_OFF = "СКРЫТЬ GUI: ВЫКЛ", Gui_ON = "СКРЫТЬ GUI: ВКЛ",
        Render3d_OFF = "БЕЗ РЕНДЕРА: ВЫКЛ", Render3d_ON = "БЕЗ РЕНДЕРА: ВКЛ",
        
        InfoTitle = "Информация:\n\nЧтобы закрыть скрипт:\nСначала сверните меню, затем дважды нажмите на круглую иконку.",
        CloseInfo = "Закрыть информацию", ConfirmClose = "Вы хотите закрыть скрипт?",
        ConfirmPersist = "Сохранить изменения?", Yes = "Да", Nope = "Нет"
    }
}
-- KUTU AKORDİYON YAPISI (HİÇBİR ŞEYİ KESMEZ)
local langFrame = Instance.new("Frame")
langFrame.Size = UDim2.new(1, -8, 0, 30)
langFrame.BackgroundTransparency = 1
langFrame.ClipsDescendants = true
langFrame.Parent = sysScroll

local langHeader = Instance.new("Frame")
langHeader.Size = UDim2.new(1, 0, 0, 30)
langHeader.BackgroundTransparency = 1
langHeader.Parent = langFrame

local langLabel = Instance.new("TextLabel")
langLabel.Size = UDim2.new(0.4, 0, 1, 0)
langLabel.BackgroundTransparency = 1
langLabel.Font = Enum.Font.SourceSansBold
langLabel.Text = "Language / Dil:"
langLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
langLabel.TextSize = 12
langLabel.TextXAlignment = Enum.TextXAlignment.Left
langLabel.Parent = langHeader

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.new(0.55, 0, 1, 0)
langBtn.Position = UDim2.new(0.45, 0, 0, 0)
langBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
langBtn.Font = Enum.Font.SourceSansBold
langBtn.Text = "English"
langBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
langBtn.TextSize = 12
langBtn.Parent = langHeader
Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 6)
local langStroke = Instance.new("UIStroke", langBtn)
langStroke.Color = Color3.fromRGB(60, 60, 70)

local langDropFrame = Instance.new("Frame")
langDropFrame.Size = UDim2.new(0.55, 0, 0, 100)
langDropFrame.Position = UDim2.new(0.45, 0, 0, 34)
langDropFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
langDropFrame.Parent = langFrame
Instance.new("UICorner", langDropFrame).CornerRadius = UDim.new(0, 6)

local langList = Instance.new("UIListLayout", langDropFrame)
langList.SortOrder = Enum.SortOrder.LayoutOrder

local languages = {
    {Code = "EN", Name = "English"},
    {Code = "TR", Name = "Türkçe"},
    {Code = "ES", Name = "Español"},
    {Code = "RU", Name = "Русский"}
}

local function updateLanguageUI(code)
    local t = langData[code] or langData.EN
    env.HYPER_SAVE.Language = code
    env.saveHubData()

    if btnSysTab then btnSysTab.Text = t.SysTab end
    if btnFeatTab then btnFeatTab.Text = t.MoreTab end
    if themeTitle then themeTitle.Text = t.ThemeTitle end
    if stabTitle then stabTitle.Text = t.FeaturesTitle end
    if btnRestartScript then btnRestartScript.Text = t.Restart end
    if dText then dText.Text = t.DiscordText end
    
    if infoBody then infoBody.Text = t.InfoTitle end
    if btnCloseInfo then btnCloseInfo.Text = t.CloseInfo end
    if btnConfirmYes then btnConfirmYes.Text = t.Yes end
    if btnConfirmNope then btnConfirmNope.Text = t.Nope end

    local function setSwitchLbl(btnObj, text)
        if btnObj and btnObj.Parent then
            local lbl = btnObj.Parent:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.Text = text end
        end
    end
    
    setSwitchLbl(btnRemember, t.Remember)
    setSwitchLbl(btnMaxFps, t.MaxFps)
    setSwitchLbl(btnAutoExec, t.AutoExec)
    setSwitchLbl(btnNavPref, t.ExtNav)
    setSwitchLbl(btnFpsMon, t.FpsMon)
    setSwitchLbl(btnAfk, t.Afk)
    setSwitchLbl(btnDynRes, t.DynRes)
    setSwitchLbl(btnDistCull, t.DistCull)
    setSwitchLbl(btnAnimLimit, t.AnimLim)
    setSwitchLbl(btnDeepRam, t.DeepRam)

    if btnRejoin then btnRejoin.Text = t.Rejoin end
    
    local function updateModuleText(name, offText, onText)
        local m = activeModules[name]
        if m and m.Btn then
            m.Btn.Text = m.IsActive and onText or offText
        end
    end

    updateModuleText("BtnGfx", t.GfxLvl, t.GfxLvl)
    updateModuleText("BtnLowGfx", t.LowGfx_OFF, t.LowGfx_ON)
    updateModuleText("BtnShadows", t.Shadows_ON, t.Shadows_OFF)
    updateModuleText("BtnCastS", t.CastS_ON, t.CastS_OFF)
    updateModuleText("BtnTex", t.Tex_HIGH, t.Tex_LOW)
    updateModuleText("BtnPart", t.Part_ON, t.Part_OFF)
    updateModuleText("BtnHigh", t.High_ON, t.High_OFF)
    updateModuleText("BtnWater", t.Water_HIGH, t.Water_LOW)
    updateModuleText("BtnGlow", t.Glow_ON, t.Glow_OFF)
    updateModuleText("BtnAudio", t.Audio_ON, t.Audio_OFF)
    updateModuleText("BtnGui", t.Gui_OFF, t.Gui_ON)
    updateModuleText("Btn3d", t.Render3d_OFF, t.Render3d_ON)
end

local isLangOpen = false
table.insert(connections, langBtn.MouseButton1Click:Connect(function()
    isLangOpen = not isLangOpen
    -- Ana kutuyu genişleterek alttaki switch'leri aşağı iter
    applyAppleTween(langFrame, {Size = isLangOpen and UDim2.new(1, -8, 0, 138) or UDim2.new(1, -8, 0, 30)}, 0.25)
end))

for _, l in ipairs(languages) do
    local optBtn = Instance.new("TextButton")
    optBtn.Size = UDim2.new(1, 0, 0, 25)
    optBtn.BackgroundTransparency = 1
    optBtn.Font = Enum.Font.SourceSansBold
    optBtn.Text = l.Name
    optBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    optBtn.TextSize = 11
    optBtn.Parent = langDropFrame

    table.insert(connections, optBtn.MouseButton1Click:Connect(function()
        langBtn.Text = l.Name
        isLangOpen = false
        applyAppleTween(langFrame, {Size = UDim2.new(1, -8, 0, 30)}, 0.25)
        updateLanguageUI(l.Code)
    end))
end

for _, l in ipairs(languages) do
    if l.Code == currentLang then langBtn.Text = l.Name end
end
updateLanguageUI(currentLang)
local btnRemember, knobRemember = createSwitch("Remember Changes", sysScroll)
local btnMaxFps, knobMaxFps = createSwitch("Remove 500 FPS Limit", sysScroll)
local btnAutoExec, knobAutoExec = createSwitch("Auto-Execute On Teleport", sysScroll)
local btnNavPref, knobNavPref = createSwitch("External Navigation", sysScroll)
local btnFpsMon, knobFpsMon = createSwitch("Live FPS Monitor", featScroll)

local btnRestartScript = Instance.new("TextButton"); btnRestartScript.Size = UDim2.new(1, -8, 0, 30); btnRestartScript.BackgroundColor3 = Color3.fromRGB(180, 50, 50); btnRestartScript.Font = Enum.Font.SourceSansBold; btnRestartScript.Text = "RESTART SCRIPT"; btnRestartScript.TextColor3 = Color3.fromRGB(255, 255, 255); btnRestartScript.TextSize = 12; btnRestartScript.LayoutOrder = 9998; btnRestartScript.Parent = sysScroll; Instance.new("UICorner", btnRestartScript).CornerRadius = UDim.new(0, 8)
local scaleRestart = Instance.new("UIScale", btnRestartScript); attachScaleHoldAnim(btnRestartScript, scaleRestart)
table.insert(connections, btnRestartScript.MouseButton1Click:Connect(function() env.SYROX_RUNNING = false; if screenGui then screenGui:Destroy() end; pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPERWORK", Text="Restarting script...", Duration=2}) end); task.delay(0.5, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ZENWORK-lua/FPS-UNCAP/refs/heads/main/Main.lua"))() end) end))

local discordFrame = Instance.new("Frame"); discordFrame.Size = UDim2.new(1, -8, 0, 22); discordFrame.BackgroundTransparency = 1; discordFrame.LayoutOrder = 9999; discordFrame.Parent = sysScroll
local dCenter = Instance.new("Frame", discordFrame); dCenter.Size = UDim2.new(0, 195, 1, 0); dCenter.Position = UDim2.new(0.5, 0, 0, 0); dCenter.AnchorPoint = Vector2.new(0.5, 0); dCenter.BackgroundTransparency = 1
local dIcon = Instance.new("ImageLabel", dCenter); dIcon.Size = UDim2.new(0, 16, 0, 16); dIcon.Position = UDim2.new(0, 0, 0.5, 0); dIcon.AnchorPoint = Vector2.new(0, 0.5); dIcon.BackgroundTransparency = 1; dIcon.Image = "rbxassetid://14896791845"; dIcon.ImageColor3 = Color3.fromRGB(130, 130, 140)
local dText = Instance.new("TextLabel", dCenter); dText.Size = UDim2.new(1, -22, 1, 0); dText.Position = UDim2.new(0, 22, 0, 0); dText.BackgroundTransparency = 1; dText.Font = Enum.Font.SourceSansBold; dText.Text = "Report bugs on Discord: lowkeyzenith"; dText.TextColor3 = Color3.fromRGB(130, 130, 140); dText.TextSize = 11; dText.TextXAlignment = Enum.TextXAlignment.Left

local btnAfk, knobAfk = createSwitch("AFK Optimization", featScroll)
local btnDynRes, knobDynRes = createSwitch("Dynamic Res Scaler (BETA)", featScroll)
local btnDistCull, knobDistCull = createSwitch("Distance Quality Culling", featScroll)
local btnAnimLimit, knobAnimLimit = createSwitch("Distance Anim Limiter", featScroll)
local btnDeepRam, knobDeepRam = createSwitch("Deep RAM Flush", featScroll)

local themeTitle = Instance.new("TextLabel"); themeTitle.Size = UDim2.new(1, -24, 0, 22); themeTitle.Position = UDim2.new(0, 12, 0, 20); themeTitle.BackgroundTransparency = 1; themeTitle.Font = Enum.Font.SourceSansBold; themeTitle.TextColor3 = Color3.fromRGB(255, 255, 255); themeTitle.TextSize = 16; themeTitle.TextXAlignment = Enum.TextXAlignment.Center; themeTitle.Text = "MY THEMES"; themeTitle.Parent = themePage
local tMask = Instance.new("CanvasGroup"); tMask.Size = UDim2.new(1, -24, 0, 150); tMask.Position = UDim2.new(0, 12, 0, 50); tMask.BackgroundTransparency = 1; tMask.BorderSizePixel = 0; tMask.Parent = themePage
local tGrad = Instance.new("UIGradient"); tGrad.Rotation = 90; tGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1)}); tGrad.Parent = tMask
local themeScroll = Instance.new("ScrollingFrame"); themeScroll.Size = UDim2.new(1, 0, 1, 0); themeScroll.BackgroundTransparency = 1; themeScroll.BorderSizePixel = 0; themeScroll.ScrollBarThickness = 2; themeScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255); themeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; themeScroll.CanvasSize = UDim2.new(0, 0, 0, 0); themeScroll.Parent = tMask
local themeGrid = Instance.new("UIGridLayout"); themeGrid.CellSize = UDim2.new(0, 110, 0, 32); themeGrid.CellPadding = UDim2.new(0, 8, 0, 8); themeGrid.Parent = themeScroll

local themes = {
    {Name = "Aura(default)", Accent = Color3.fromRGB(0, 162, 255), Bg1 = Color3.fromRGB(45, 45, 52), Bg2 = Color3.fromRGB(10, 10, 15)},
    {Name = "bloody", Accent = Color3.fromRGB(255, 40, 60), Bg1 = Color3.fromRGB(50, 20, 25), Bg2 = Color3.fromRGB(15, 5, 5)},
    {Name = "Gold Sun", Accent = Color3.fromRGB(255, 200, 30), Bg1 = Color3.fromRGB(50, 45, 30), Bg2 = Color3.fromRGB(15, 12, 5)},
    {Name = "Fresh Mint", Accent = Color3.fromRGB(0, 255, 150), Bg1 = Color3.fromRGB(20, 50, 40), Bg2 = Color3.fromRGB(5, 15, 10)},
    {Name = "Aubergine", Accent = Color3.fromRGB(180, 50, 255), Bg1 = Color3.fromRGB(35, 20, 45), Bg2 = Color3.fromRGB(10, 5, 15)},
    {Name = "Volcano", Accent = Color3.fromRGB(255, 100, 0), Bg1 = Color3.fromRGB(50, 25, 10), Bg2 = Color3.fromRGB(15, 5, 0)},
    {Name = "Ghosts", Accent = Color3.fromRGB(230, 230, 240), Bg1 = Color3.fromRGB(60, 60, 65), Bg2 = Color3.fromRGB(25, 25, 30)},
    {Name = "Slimey", Accent = Color3.fromRGB(150, 255, 0), Bg1 = Color3.fromRGB(30, 40, 20), Bg2 = Color3.fromRGB(10, 15, 5)}
}
local confirmTitle = Instance.new("TextLabel"); confirmTitle.Size = UDim2.new(1, -24, 0, 45); confirmTitle.Position = UDim2.new(0, 12, 0, 40); confirmTitle.BackgroundTransparency = 1; confirmTitle.Font = Enum.Font.SourceSansBold; confirmTitle.TextWrapped = true; confirmTitle.TextColor3 = Color3.fromRGB(255, 255, 255); confirmTitle.TextSize = 15; confirmTitle.TextXAlignment = Enum.TextXAlignment.Center; confirmTitle.Text = "Do you want to close the script?"; confirmTitle.Parent = confirmPage
local btnConfirmYes = Instance.new("TextButton"); btnConfirmYes.Size = UDim2.new(0, 100, 0, 32); btnConfirmYes.Position = UDim2.new(0.5, -110, 0, 115); btnConfirmYes.BackgroundColor3 = Color3.fromRGB(46, 204, 113); btnConfirmYes.Font = Enum.Font.SourceSansBold; btnConfirmYes.Text = "Yes"; btnConfirmYes.TextColor3 = Color3.fromRGB(255, 255, 255); btnConfirmYes.TextSize = 14; btnConfirmYes.Parent = confirmPage; Instance.new("UICorner", btnConfirmYes).CornerRadius = UDim.new(0, 8)
local btnConfirmNope = Instance.new("TextButton"); btnConfirmNope.Size = UDim2.new(0, 100, 0, 32); btnConfirmNope.Position = UDim2.new(0.5, 10, 0, 115); btnConfirmNope.BackgroundColor3 = Color3.fromRGB(231, 76, 60); btnConfirmNope.Font = Enum.Font.SourceSansBold; btnConfirmNope.Text = "Nope"; btnConfirmNope.TextColor3 = Color3.fromRGB(255, 255, 255); btnConfirmNope.TextSize = 14; btnConfirmNope.Parent = confirmPage; Instance.new("UICorner", btnConfirmNope).CornerRadius = UDim.new(0, 8)
local scYes = Instance.new("UIScale", btnConfirmYes); attachScaleHoldAnim(btnConfirmYes, scYes)
local scNope = Instance.new("UIScale", btnConfirmNope); attachScaleHoldAnim(btnConfirmNope, scNope)
-- [[ MENU ANIMATIONS & EFFECTS ]]
local currentState = 0
local currentPage = mainPage

local function openPage(target)
    if currentPage == target then target = mainPage end
    if currentState == 0 then
        if target == settingsPage then
            applyAppleTween(headerPill, {Position = UDim2.new(0.5, 0, 0, -6)})
            applyAppleTween(headerPillTouch, {Position = UDim2.new(0.5, 0, 0, -14)})
        else
            applyAppleTween(headerPill, {Position = UDim2.new(0.5, 0, 0, 12)})
            applyAppleTween(headerPillTouch, {Position = UDim2.new(0.5, 0, 0, 0)})
        end
    end
    local fadeOut = TweenService:Create(fadeCurtain, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0}); fadeOut:Play()
    fadeOut.Completed:Connect(function() currentPage.Visible = false; target.Visible = true; currentPage = target; local fadeIn = TweenService:Create(fadeCurtain, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {BackgroundTransparency = 1}); fadeIn:Play() end)
end

local currentSettingsRot = 0
table.insert(connections, btnTheme.MouseButton1Click:Connect(function() applyAppleTween(btnTheme, {ImageTransparency = 0}, 0.1); openPage(themePage); applyAppleTween(btnTheme, {Size = UDim2.new(0, 0, 0, 20)}, 0.15); task.delay(0.15, function() applyAppleTween(btnTheme, {Size = UDim2.new(0, 20, 0, 20)}, 0.15) end); task.delay(0.2, function() applyAppleTween(btnTheme, {ImageTransparency = 0.3}, 0.3) end) end))
table.insert(connections, btnSettings.MouseButton1Click:Connect(function() currentSettingsRot = currentSettingsRot + 360; applyAppleTween(btnSettings, {Rotation = currentSettingsRot}, 0.5); applyAppleTween(btnSettings, {ImageTransparency = 0}, 0.1); openPage(settingsPage); task.delay(0.2, function() applyAppleTween(btnSettings, {ImageTransparency = 0.3}, 0.3) end) end))
table.insert(connections, btnSysTab.MouseButton1Click:Connect(function() btnSysTab.Text = "SYSTEM"; btnFeatTab.Text = "MRFT"; applyAppleTween(btnSysTab, {Size = UDim2.new(0, 95, 1, 0)}); applyAppleTween(btnFeatTab, {Size = UDim2.new(0, 65, 1, 0), Position = UDim2.new(0, 95, 0, 0)}); applyAppleTween(segmentSlider, {Size = UDim2.new(0, 95, 1, -4), Position = UDim2.new(0, 2, 0, 2)}, 0.3); btnSysTab.TextColor3 = Color3.fromRGB(255,255,255); btnFeatTab.TextColor3 = Color3.fromRGB(150,150,160); featScroll.Visible = false; sysScroll.Visible = true end))
table.insert(connections, btnFeatTab.MouseButton1Click:Connect(function() btnSysTab.Text = "SYTM"; btnFeatTab.Text = "MORE FEATURES"; applyAppleTween(btnSysTab, {Size = UDim2.new(0, 45, 1, 0)}); applyAppleTween(btnFeatTab, {Size = UDim2.new(0, 115, 1, 0), Position = UDim2.new(0, 45, 0, 0)}); applyAppleTween(segmentSlider, {Size = UDim2.new(0, 115, 1, -4), Position = UDim2.new(0, 45, 0, 2)}, 0.3); btnFeatTab.TextColor3 = Color3.fromRGB(255,255,255); btnSysTab.TextColor3 = Color3.fromRGB(150,150,160); sysScroll.Visible = false; featScroll.Visible = true end))

local function tweenGradient(grad, c1, c2, duration)
    local val = Instance.new("NumberValue"); val.Value = 0
    local tw = TweenService:Create(val, TweenInfo.new(duration, Enum.EasingStyle.Sine), {Value = 1}); tw:Play()
    local c; c = val.Changed:Connect(function(v) grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, grad.Color.Keypoints[1].Value:Lerp(c1, v)), ColorSequenceKeypoint.new(1, grad.Color.Keypoints[2].Value:Lerp(c2, v))}) end)
    tw.Completed:Connect(function() c:Disconnect(); val:Destroy() end)
end

for _, td in ipairs(themes) do
    local tb = Instance.new("TextButton"); tb.Size = UDim2.new(0, 110, 0, 32); tb.BackgroundColor3 = Color3.fromRGB(30, 30, 40); tb.BackgroundTransparency = 0.4; tb.Font = Enum.Font.GothamMedium; tb.Text = td.Name; tb.TextColor3 = td.Accent; tb.TextSize = 13; tb.Parent = themeScroll; Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", tb); s.Color = td.Accent; s.Transparency = 0.5; s.Thickness = 1
    local tsc = Instance.new("UIScale", tb); attachScaleHoldAnim(tb, tsc)
    table.insert(connections, tb.MouseButton1Click:Connect(function() globalAccentColor = td.Accent; tweenGradient(bgGradient, td.Bg1, td.Bg2, 0.6); applyAppleTween(auraStroke, {Color = td.Accent}, 0.6); applyAppleTween(effectBarGlow, {BackgroundColor3 = td.Accent}, 0.6); applyAppleTween(sliderFill, {BackgroundColor3 = td.Accent}, 0.6); applyAppleTween(segmentSlider, {BackgroundColor3 = td.Accent}, 0.6); applyAppleTween(stabTitle, {TextColor3 = td.Accent}, 0.6); applyAppleTween(fpsMonFrame.UIStroke, {Color = td.Accent}, 0.6)
        for _, m in pairs(activeModules) do if m.IsActive then applyAppleTween(m.Btn, {TextColor3 = td.Accent}, 0.6); applyAppleTween(m.Stroke, {Color = td.Accent}, 0.6) end end
        for _, sw in pairs(switchRegistry) do if sw.State then applyAppleTween(sw.Btn, {BackgroundColor3 = td.Accent}, 0.6) end end
    end))
end

local function handleSwitch(btn, knob, state) applyAppleTween(btn, {BackgroundColor3 = state and globalAccentColor or Color3.fromRGB(60, 60, 70)}); applyAppleTween(knob, {Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 0.5}, 0.15); applyAppleTween(knob, {Position = state and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)}, 0.3); task.delay(0.15, function() applyAppleTween(knob, {Size = UDim2.new(0, 16, 0, 16), BackgroundTransparency = 0}, 0.15) end) end
local function toggleSt(name, state, tOn, tOff) local m = activeModules[name]; m.IsActive = state; m.Btn.Text = state and tOn or tOff; applyAppleTween(m.Btn, {TextColor3 = state and globalAccentColor or Color3.fromRGB(200, 200, 210)}, 0.3); applyAppleTween(m.Stroke, {Color = state and globalAccentColor or Color3.fromRGB(255, 255, 255), Transparency = state and 0.5 or 0.8}, 0.3) end

local function bindSwitch(btn, knob, swName, cb) switchRegistry[swName] = {Btn = btn, Knob = knob, State = env.HYPER_SAVE.Switches[swName] or false}; local state = switchRegistry[swName].State; if state then handleSwitch(btn, knob, true); task.spawn(cb, true) end
    table.insert(connections, btn.MouseButton1Click:Connect(function() state = not state; switchRegistry[swName].State = state; handleSwitch(btn, knob, state); cb(state); env.HYPER_SAVE.Switches[swName] = state; env.saveHubData() end)) end
local function bindToggle(name, tOn, tOff, cb) local m = activeModules[name]; if env.HYPER_SAVE.Toggles[name] then m.IsActive = true; toggleSt(name, true, tOn, tOff); task.spawn(cb, true) end
    table.insert(connections, m.Btn.MouseButton1Click:Connect(function() m.IsActive = not m.IsActive; toggleSt(name, m.IsActive, tOn, tOff); cb(m.IsActive); env.HYPER_SAVE.Toggles[name] = m.IsActive; env.saveHubData() end)) end

local unlockFps, autoExec, isAfkEngine, isDynRes, isDistCull, isAnimLim, isExtNav = false, false, false, false, false, false, false
local isLow, isShdw, isCast, isTex, isPart, isHigh, isWater, isGlow, isAud, is3d = false, true, true, false, false, true, true, true, true, true
local isDraggingMoved, isIntroPlaying = false, true
local draggingPill = false; local pillDragStart, startPos = nil, nil
local confirmStep = 0
bindSwitch(btnNavPref, knobNavPref, "NavPref", function(s) isExtNav = s; if currentState == 0 then extBtnClose.Visible = s; extBtnMin.Visible = s end end)
bindSwitch(btnFpsMon, knobFpsMon, "FpsMon", function(s) fpsMonFrame.Visible = s end)
bindSwitch(btnRemember, knobRemember, "Remember", function(s) env.HYPER_SAVE.Remember = s; if not s and writefile then pcall(function() writefile("HYPER_HUB.json", HttpService:JSONEncode({Remember=false, Toggles={}, Switches={}})) end) else env.saveHubData() end end)
bindSwitch(btnMaxFps, knobMaxFps, "MaxFps", function(s) unlockFps = s; MAX_FPS = s and 10000 or 500 end)
bindSwitch(btnAutoExec, knobAutoExec, "AutoExec", function(s) autoExec = s; local qot = (syn and syn.queue_on_teleport) or queue_on_teleport; if qot then qot([[loadstring(game:HttpGet("https://raw.githubusercontent.com/ZENWORK-lua/FPS-UNCAP/refs/heads/main/Main.lua"))()]]) end end)
bindSwitch(btnAfk, knobAfk, "Afk", function(s) isAfkEngine = s; if s then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="HYPERWORK", Text="AFK Optimization Activated!", Duration=3}) end) end end)
bindSwitch(btnDynRes, knobDynRes, "DynRes", function(s) isDynRes = s end)
bindSwitch(btnDeepRam, knobDeepRam, "DeepRam", function(s) if s then task.wait(0.2); pcall(function() collectgarbage("collect") end); handleSwitch(btnDeepRam, knobDeepRam, false); switchRegistry["DeepRam"].State = false; env.HYPER_SAVE.Switches["DeepRam"] = false end end)

bindSwitch(btnDistCull, knobDistCull, "DistCull", function(s) isDistCull = s; if not s then task.spawn(function() for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end end end) end end)
bindSwitch(btnAnimLimit, knobAnimLimit, "AnimLim", function(s) isAnimLim = s; if not s then task.spawn(function() for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("Humanoid") then v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer; for _, t in ipairs(v:GetPlayingAnimationTracks()) do if t.Speed == 0 then t:AdjustSpeed(1) end end end end end) end end)

local function asyncProcessDescendants(cb) task.spawn(function() for i, v in ipairs(workspace:GetDescendants()) do pcall(cb, v); if i % 150 == 0 then RunService.Heartbeat:Wait() end end end) end
bindToggle("BtnLowGfx", "LOW GFX: OFF", "LOW GFX: ON", function(s) isLow = s; asyncProcessDescendants(function(v) if v:IsA("BasePart") then v.Material = s and Enum.Material.SmoothPlastic or Enum.Material.Plastic end end) end)
bindToggle("BtnShadows", "SHADOWS: ON", "SHADOWS: OFF", function(s) isShdw = s; pcall(function() Lighting.GlobalShadows = s end) end)
bindToggle("BtnCastS", "CAST-SHDW: ON", "CAST-SHDW: OFF", function(s) isCast = s; asyncProcessDescendants(function(v) if v:IsA("BasePart") then v.CastShadow = s end end) end)
bindToggle("BtnTex", "TEXTURES: LOW", "TEXTURES: HIGH", function(s) isTex = s; asyncProcessDescendants(function(v) if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = s and 1 or 0 end end) end)
bindToggle("BtnPart", "PARTICLES: ON", "PARTICLES: OFF", function(s) isPart = s; asyncProcessDescendants(function(v) if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = not s end end) end)
bindToggle("BtnHigh", "HIGHLIGHTS: ON", "HIGHLIGHTS: OFF", function(s) isHigh = s; asyncProcessDescendants(function(v) if v:IsA("Highlight") then v.Enabled = s end end) end)
bindToggle("BtnWater", "WATER: HIGH", "WATER: LOW", function(s) isWater = s; pcall(function() local t = workspace.Terrain; t.WaterWaveSize = s and 0.15 or 0; t.WaterWaveSpeed = s and 10 or 0; t.WaterReflectance = s and 1 or 0 end) end)
bindToggle("BtnGlow", "POST-FX: ON", "POST-FX: OFF", function(s) isGlow = s; asyncProcessDescendants(function(v) if v:IsA("PostEffect") then v.Enabled = s end end) end)
bindToggle("BtnAudio", "3D AUDIO: ON", "3D AUDIO: OFF", function(s) isAud = s; pcall(function() game:GetService("SoundService").AmbientReverb = s and Enum.ReverbType.NoReverb or Enum.ReverbType.NoReverb end) end)
bindToggle("Btn3d", "NO RENDER: ON", "NO RENDER: OFF", function(s) is3d = s; pcall(function() RunService:Set3dRenderingEnabled(not s) end) end)
table.insert(connections, btnRejoin.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer) end))
local function minimizeMenu() currentState = 1; contentContainer.Visible = false; local cPos = mainFrame.Position; applyAppleTween(mainFrame, {Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(cPos.X.Scale, cPos.X.Offset, cPos.Y.Scale, cPos.Y.Offset - 83)}); applyAppleTween(uiCorner, {CornerRadius = UDim.new(1, 0)}); applyAppleTween(outerAura, {Size = UDim2.new(1, 4, 1, 4)}); applyAppleTween(headerPillTouch, {Size = UDim2.new(1, 20, 1, 20), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5)}); applyAppleTween(headerPill, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0.5, 0, 0.5, 0)}); if isExtNav then extBtnClose.Visible = true; extBtnMin.Visible = false; applyAppleTween(extBtnClose, {Position = UDim2.new(1, 35, 0.5, 0)}) else extBtnClose.Visible = false; extBtnMin.Visible = false end end
local function maximizeMenu() currentState = 0; local cPos = mainFrame.Position; applyAppleTween(mainFrame, {Size = UDim2.new(0, 270, 0, 210), Position = UDim2.new(cPos.X.Scale, cPos.X.Offset, cPos.Y.Scale, cPos.Y.Offset + 83)}); applyAppleTween(uiCorner, {CornerRadius = UDim.new(0, 16)}); applyAppleTween(outerAura, {Size = UDim2.new(1, 6, 1, 6)}); applyAppleTween(headerPillTouch, {Size = UDim2.new(0, 150, 0, 32), Position = UDim2.new(0.5, 0, 0, (currentPage == settingsPage and -14 or 0)), AnchorPoint = Vector2.new(0.5, 0)}); applyAppleTween(headerPill, {Size = UDim2.new(0, 50, 0, 5), Position = UDim2.new(0.5, 0, 0, (currentPage == settingsPage and -6 or 12))}); if isExtNav then extBtnClose.Visible = true; extBtnMin.Visible = true; applyAppleTween(extBtnClose, {Position = UDim2.new(1, 30, 0, 24)}); applyAppleTween(extBtnMin, {Position = UDim2.new(1, 30, 0, 64)}) end; task.delay(0.1, function() if currentState == 0 then contentContainer.Visible = true end end) end

-- [[ CLOSE ANIM & BUG FIX  ]]
local function playClosingAnimation(persist)
    env.SYROX_RUNNING = false
    if not persist then 
        pcall(function() 
            Lighting.GlobalShadows = origSettings.GlobalShadows; settings().Rendering.QualityLevel = origSettings.QualityLevel
            local t = workspace.Terrain; t.WaterWaveSize = origSettings.WaterWaveSize; t.WaterWaveSpeed = origSettings.WaterWaveSpeed; t.WaterReflectance = origSettings.WaterReflectance
            RunService:Set3dRenderingEnabled(true); if setfpscap then pcall(setfpscap, 60) elseif set_fps_cap then pcall(set_fps_cap, 60) end
            
            task.spawn(function()
                for i, v in ipairs(workspace:GetDescendants()) do
                    pcall(function()
                        if v:IsA("BasePart") then
                            if v.LocalTransparencyModifier > 0 and v.Transparency < 1 then v.LocalTransparencyModifier = 0 end 
                            if isLow and v.Material == Enum.Material.SmoothPlastic then v.Material = Enum.Material.Plastic end
                        elseif v:IsA("Humanoid") then 
                            v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                            for _, tr in ipairs(v:GetPlayingAnimationTracks()) do if tr.Speed == 0 then tr:AdjustSpeed(1) end end
                        end
                    end)
                    if i % 250 == 0 then RunService.RenderStepped:Wait() end
                end
            end)
        end) 
    end
    
    btnConfirmYes.Visible = false; btnConfirmNope.Visible = false
    if isExtNav then extBtnClose.Visible = false; extBtnMin.Visible = false end
    headerPill.Visible = false; headerPillTouch.Visible = false
    isIntroPlaying = true 
    
    TweenService:Create(btnSettings, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
    TweenService:Create(btnTheme, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
    TweenService:Create(auraStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
    
    confirmTitle.Text = "thank you for using"
    confirmTitle.TextSize = 13
    confirmTitle.TextTransparency = 1
    confirmTitle.Position = UDim2.new(0, 12, 0, 20)
    
    local hText = Instance.new("TextLabel")
    hText.Size = UDim2.new(1, 0, 0, 30); hText.Position = UDim2.new(0, 0, 0, 90)
    hText.BackgroundTransparency = 1; hText.Font = Enum.Font.GothamBold
    hText.Text = "HYPER|FPS"; hText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hText.TextSize = 24; hText.TextTransparency = 1; hText.Parent = confirmPage
    
    applyAppleTween(confirmTitle, {Position = UDim2.new(0, 12, 0, 40), TextTransparency = 0}, 0.5)
    applyAppleTween(hText, {Position = UDim2.new(0, 0, 0, 70), TextTransparency = 0}, 0.5)
    task.wait(1.5)
    
    TweenService:Create(confirmTitle, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    task.wait(0.3)
    
    applyAppleTween(uiCorner, {CornerRadius = UDim.new(1, 0)}, 0.6)
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 130, 0, 130)}, 0.6)
    applyAppleTween(hText, {Position = UDim2.new(0, 0, 0, 50), TextSize = 18}, 0.6)
    applyAppleTween(outerAura, {Size = UDim2.new(1, 4, 1, 4)}, 0.6)
    task.wait(0.7)
    
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.4)
    TweenService:Create(hText, TweenInfo.new(0.3), {TextTransparency = 1, TextSize = 1}):Play()
    task.wait(0.4)

    for _, c in ipairs(env.FPSCapUIConnections) do if c and c.Connected then c:Disconnect() end end
    table.clear(env.FPSCapUIConnections)
    if screenGui then screenGui:Destroy() end
end

local function startCloseSequence() confirmStep = 1; confirmTitle.Text = "Do you want to close the script?"; openPage(confirmPage) end
table.insert(connections, extBtnMin.MouseButton1Click:Connect(minimizeMenu)); table.insert(connections, extBtnClose.MouseButton1Click:Connect(startCloseSequence))
table.insert(connections, btnConfirmNope.MouseButton1Click:Connect(function() if confirmStep == 1 then openPage(mainPage); confirmStep = 0 elseif confirmStep == 2 then playClosingAnimation(false) end end))
table.insert(connections, btnConfirmYes.MouseButton1Click:Connect(function() if confirmStep == 1 then confirmStep = 2; TweenService:Create(fadeCurtain, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play(); task.delay(0.2, function() confirmTitle.Text = "Do you want the changes to persist?"; TweenService:Create(fadeCurtain, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play() end) elseif confirmStep == 2 then playClosingAnimation(true) end end))

table.insert(connections, headerPillTouch.InputBegan:Connect(function(input) if isIntroPlaying then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingPill = true; isDraggingMoved = false; pillDragStart = input.Position; startPos = mainFrame.Position end end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if draggingPill and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - pillDragStart; if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then isDraggingMoved = true end 
        local cam = workspace.CurrentCamera; local viewportSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local frameSize = mainFrame.AbsoluteSize; local anchor = mainFrame.AnchorPoint
        local rawX = startPos.X.Offset + delta.X; local rawY = startPos.Y.Offset + delta.Y
        local minX = (anchor.X * frameSize.X) - (viewportSize.X * 0.5); local maxX = (viewportSize.X * 0.5) - ((1 - anchor.X) * frameSize.X)
        local minY = (anchor.Y * frameSize.Y) - (viewportSize.Y * 0.5); local maxY = (viewportSize.Y * 0.5) - ((1 - anchor.Y) * frameSize.Y)
        mainFrame.Position = UDim2.new(startPos.X.Scale, math.clamp(rawX, minX, maxX), startPos.Y.Scale, math.clamp(rawY, minY, maxY))
    end
end))

local lastClickTime = 0
table.insert(connections, headerPillTouch.InputEnded:Connect(function(input)
    if draggingPill and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        draggingPill = false; 
        if not isDraggingMoved then
            if isExtNav and currentState == 0 then return end
            if currentState == 0 then minimizeMenu()
            elseif currentState == 1 then
                local now = os.clock()
                if now - lastClickTime < 0.225 then
                    lastClickTime = 0; maximizeMenu(); startCloseSequence()
                else
                    lastClickTime = now
                    task.delay(0.25, function() if lastClickTime == now then maximizeMenu() end end)
                end
            end
        end
    end
end))

local function updateSlider(x) local tPos = sliderTrack.AbsolutePosition.X; local tSz = sliderTrack.AbsoluteSize.X; local ratio = math.clamp((x - tPos) / tSz, 0, 1); local fps = math.floor(MIN_FPS + (ratio * (MAX_FPS - MIN_FPS))); sliderFill.Size = UDim2.new(ratio, 0, 1, 0); sliderKnob.Position = UDim2.new(ratio, 0, 0.5, 0); titleLabel.Text = string.format("Target FPS: %d FPS", fps); return fps end
table.insert(connections, UserInputService.InputBegan:Connect(function(input) if isIntroPlaying or currentState == 1 or not mainPage.Visible then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then local pos, tPos, tSz = input.Position, sliderTrack.AbsolutePosition, sliderTrack.AbsoluteSize; if pos.X >= tPos.X-15 and pos.X <= tPos.X+tSz.X+15 and pos.Y >= tPos.Y-20 and pos.Y <= tPos.Y+tSz.Y+20 then draggingSlider = true; updateSlider(pos.X); applyAppleTween(sliderKnob, {Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 0.5}, 0.15) end end end))
table.insert(connections, UserInputService.InputChanged:Connect(function(input) if draggingSlider then updateSlider(input.Position.X) end end))
table.insert(connections, UserInputService.InputEnded:Connect(function(input) if draggingSlider then draggingSlider = false; local f = updateSlider(input.Position.X); if setfpscap then pcall(setfpscap, f) elseif set_fps_cap then pcall(set_fps_cap, f) end; applyAppleTween(sliderKnob, {Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 0}, 0.15); applyAppleTween(effectBarGlow, {Size = UDim2.new(math.clamp((f-MIN_FPS)/(MAX_FPS-MIN_FPS),0,1),0,1,0), BackgroundColor3 = Color3.fromRGB(0,255,180)}); task.delay(0.3, function() TweenService:Create(effectBarGlow, TweenInfo.new(0.4), {BackgroundColor3 = globalAccentColor}):Play() end) end end))

local lastInputTime = os.clock()
table.insert(connections, UserInputService.InputBegan:Connect(function() lastInputTime = os.clock(); if afkScreen.Visible then afkScreen.Visible = false; RunService:Set3dRenderingEnabled(not is3d) end end))

local lastTime, fCount, currentRealFps = os.clock(), 0, 60
local dynResScanFrames, maxPanelFps, dynResCalibrated, lowFpsSeconds = 0, 60, false, 0
table.insert(connections, RunService.RenderStepped:Connect(function()
    fCount = fCount + 1; local curr = os.clock()
    if curr - lastTime >= 1 then
        currentRealFps = math.floor(fCount / (curr - lastTime)); fpsDisplay.Text = string.format("Current FPS: %d", currentRealFps); fpsMonText.Text = "FPS: " .. tostring(currentRealFps); fCount = 0; lastTime = curr
        if isAfkEngine and (curr - lastInputTime > 60) and not afkScreen.Visible then afkScreen.Visible = true; RunService:Set3dRenderingEnabled(false) end
        if isDynRes then
            if not dynResCalibrated then dynResScanFrames = dynResScanFrames + 1; if currentRealFps > maxPanelFps then maxPanelFps = currentRealFps end; if dynResScanFrames >= 4 then dynResCalibrated = true end
            else local target = (maxPanelFps > 70) and 80 or 40; if currentRealFps < target then lowFpsSeconds = lowFpsSeconds + 1 else lowFpsSeconds = 0; pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end) end
            if lowFpsSeconds >= 5 then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level05 end) end end
        end
    end
end))

task.spawn(function()
    while env.SYROX_RUNNING do
        task.wait(1)
        if not isDistCull and not isAnimLim then continue end
        local lp = Players.LocalPlayer; local char = lp.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local pos = root.Position; local count = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if isDistCull and v:IsA("BasePart") then
                local dist = (v.Position - pos).Magnitude
                if dist > 350 then v.LocalTransparencyModifier = 1
                elseif dist > 150 then v.LocalTransparencyModifier = 0; v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false
                else v.LocalTransparencyModifier = 0 end
            end
            if isAnimLim and v:IsA("Humanoid") and v.Parent ~= char then
                local pRoot = v.Parent:FindFirstChild("HumanoidRootPart") or v.Parent:FindFirstChild("Torso")
                if pRoot then
                    local dist = (pRoot.Position - pos).Magnitude
                    if dist > 150 then v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; for _, track in ipairs(v:GetPlayingAnimationTracks()) do track:AdjustSpeed(0) end
                    else v.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer; for _, track in ipairs(v:GetPlayingAnimationTracks()) do if track.Speed == 0 then track:AdjustSpeed(1) end end end
                end
            end
            count = count + 1; if count % 200 == 0 then RunService.RenderStepped:Wait() end
        end
    end
end)

table.insert(connections, btnCloseInfo.MouseButton1Click:Connect(function() TweenService:Create(infoOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play(); TweenService:Create(infoBody, TweenInfo.new(0.3), {TextTransparency = 1}):Play(); TweenService:Create(btnCloseInfo, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play(); task.delay(0.3, function() infoOverlay.Visible = false; contentContainer.Visible = true; isIntroPlaying = false end) end))

screenGui.Parent = targetGui
task.spawn(function()
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 130, 0, 130)}, 0.6); task.wait(0.5); TweenService:Create(introText, TweenInfo.new(0.6), {TextTransparency = 0}):Play(); task.wait(1.5); TweenService:Create(introText, TweenInfo.new(0.4), {TextTransparency = 1}):Play(); task.wait(0.3)
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 80, 0, 80)}, 0.4); task.wait(0.3); applyAppleTween(mainFrame, {Size = UDim2.new(0, 90, 0, 16)}, 0.5); applyAppleTween(uiCorner, {CornerRadius = UDim.new(0, 8)}, 0.5); task.wait(0.4)
    TweenService:Create(auraStroke, TweenInfo.new(0.3), {Transparency = 0.65}):Play(); TweenService:Create(headerPill, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play(); introText:Destroy(); task.wait(0.2)
    applyAppleTween(mainFrame, {Size = UDim2.new(0, 270, 0, 210)}, 0.5); applyAppleTween(uiCorner, {CornerRadius = UDim.new(0, 16)}, 0.5); applyAppleTween(headerPill, {Size = UDim2.new(0, 50, 0, 5), Position = UDim2.new(0.5, 0, 0, 12)}, 0.5); task.wait(0.3)
    infoOverlay.Visible = true; if isExtNav then extBtnClose.Visible = true; extBtnMin.Visible = true end
end)

