local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SimpleAFKGui") then
    playerGui:FindFirstChild("SimpleAFKGui"):Destroy()
end

local environment = {
    isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    isPC = UserInputService.KeyboardEnabled,
    hasVirtualUser = pcall(function() return VirtualUser:CaptureController() end),
    hasCamera = workspace.CurrentCamera ~= nil,
    executor = identifyexecutor and identifyexecutor() or "Unknown"
}

print("=== AFK Guardian Environment ===")
print("Platform:", environment.isMobile and "Mobile" or "PC")
print("Executor:", environment.executor)
print("VirtualUser:", environment.hasVirtualUser and "Available" or "Unavailable")
print("Camera:", environment.hasCamera and "Available" or "Unavailable")
print("===============================")

local settings = {
    enabled = false,
    baseInterval = 60,
    jitter = 0.4,
    burstChance = 0.15,
    toggleKey = Enum.KeyCode.F4,
    isWindowFocused = true,
    unfocusedMultiplier = 0.7
}

local connections = {}
local isInitialized = false

local function randRange(a, b)
    return a + math.random() * (b - a)
end

local function nextWait()
    local base = settings.baseInterval
    local jitter = base * settings.jitter
    local wait = base + randRange(-jitter, jitter)
    
    if math.random() < 0.1 then
        wait = wait + randRange(15, 45)
    end
    
    if not settings.isWindowFocused then
        wait = wait * settings.unfocusedMultiplier
    end
    
    return math.max(8, wait)
end

local function showNotification(title, text, duration)
    local success, err = pcall(function()
        local notifGui = Instance.new("ScreenGui")
        notifGui.Name = "CustomNotification"
        notifGui.DisplayOrder = 200
        notifGui.Parent = playerGui
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 320, 0, 80)
        notif.Position = UDim2.new(0.5, -160, 0, -100)
        notif.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
        notif.BorderSizePixel = 0
        notif.Parent = notifGui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 12)
        notifCorner.Parent = notif
        
        local notifGradient = Instance.new("UIGradient")
        notifGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 28))
        }
        notifGradient.Rotation = 135
        notifGradient.Parent = notif
        
        local notifStroke = Instance.new("UIStroke")
        notifStroke.Color = Color3.fromRGB(100, 150, 255)
        notifStroke.Thickness = 2
        notifStroke.Transparency = 0.3
        notifStroke.Parent = notif
        
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 40, 1, 40)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Color3.fromRGB(100, 150, 255)
        glow.ImageTransparency = 0.7
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(24, 24, 276, 276)
        glow.ZIndex = -1
        glow.Parent = notif
        
        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.new(0, 50, 0, 50)
        iconBg.Position = UDim2.new(0, 15, 0.5, -25)
        iconBg.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        iconBg.BorderSizePixel = 0
        iconBg.Parent = notif
        
        local iconBgCorner = Instance.new("UICorner")
        iconBgCorner.CornerRadius = UDim.new(0, 10)
        iconBgCorner.Parent = iconBg
        
        local iconBgGradient = Instance.new("UIGradient")
        iconBgGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
        }
        iconBgGradient.Rotation = 135
        iconBgGradient.Parent = iconBg
        
        local notifIcon = Instance.new("TextLabel")
        notifIcon.Size = UDim2.new(1, 0, 1, 0)
        notifIcon.BackgroundTransparency = 1
        notifIcon.Text = "🛡️"
        notifIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
        notifIcon.Font = Enum.Font.GothamBold
        notifIcon.TextSize = 28
        notifIcon.Parent = iconBg
        
        local textContainer = Instance.new("Frame")
        textContainer.Size = UDim2.new(1, -80, 1, -20)
        textContainer.Position = UDim2.new(0, 75, 0, 10)
        textContainer.BackgroundTransparency = 1
        textContainer.Parent = notif
        
        local notifTitle = Instance.new("TextLabel")
        notifTitle.Size = UDim2.new(1, 0, 0, 20)
        notifTitle.Position = UDim2.new(0, 0, 0, 8)
        notifTitle.BackgroundTransparency = 1
        notifTitle.Text = title
        notifTitle.TextColor3 = Color3.fromRGB(245, 245, 250)
        notifTitle.Font = Enum.Font.GothamBold
        notifTitle.TextSize = 16
        notifTitle.TextXAlignment = Enum.TextXAlignment.Left
        notifTitle.Parent = textContainer
        
        local notifText = Instance.new("TextLabel")
        notifText.Size = UDim2.new(1, 0, 0, 35)
        notifText.Position = UDim2.new(0, 0, 0, 30)
        notifText.BackgroundTransparency = 1
        notifText.Text = text
        notifText.TextColor3 = Color3.fromRGB(190, 190, 195)
        notifText.Font = Enum.Font.Gotham
        notifText.TextSize = 13
        notifText.TextXAlignment = Enum.TextXAlignment.Left
        notifText.TextYAlignment = Enum.TextYAlignment.Top
        notifText.TextWrapped = true
        notifText.Parent = textContainer
        
        local slideIn = TweenService:Create(notif,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = UDim2.new(0.5, -160, 0, 20)}
        )
        
        local pulse = TweenService:Create(iconBg,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 13, 0.5, -27)}
        )
        
        local glowPulse = TweenService:Create(glow,
            TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {ImageTransparency = 0.85}
        )
        
        slideIn:Play()
        wait(0.3)
        pulse:Play()
        glowPulse:Play()
        
        wait(duration or 5)
        
        pulse:Cancel()
        glowPulse:Cancel()
        
        local slideOut = TweenService:Create(notif,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -160, 0, -100)}
        )
        
        slideOut:Play()
        slideOut.Completed:Wait()
        notifGui:Destroy()
    end)
    
    if not success then
        warn("Notification error:", err)
    end
end

local function makeDraggable(frame)
    local success, err = pcall(function()
        local dragging, dragStart, startPos
        
        table.insert(connections, frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end))
        
        table.insert(connections, frame.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end))
    end)
    
    if not success then
        warn("Draggable error:", err)
    end
end

local function createUI()
    local success, result = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "SimpleAFKGui"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 100
        gui.Parent = playerGui

        local shadow = Instance.new("Frame")
        shadow.Size = UDim2.new(0, 260, 0, 90)
        shadow.Position = environment.isMobile and UDim2.new(0.5, -130, 0, 18) or UDim2.new(0, 18, 0, 18)
        shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        shadow.BackgroundTransparency = 0.7
        shadow.BorderSizePixel = 0
        shadow.Parent = gui
        
        local shadowCorner = Instance.new("UICorner")
        shadowCorner.CornerRadius = UDim.new(0, 12)
        shadowCorner.Parent = shadow

        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(0, 260, 0, 90)
        panel.Position = environment.isMobile and UDim2.new(0.5, -130, 0, 20) or UDim2.new(0, 20, 0, 20)
        panel.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
        panel.BorderSizePixel = 0
        panel.Active = true
        panel.Parent = gui
        
        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = UDim.new(0, 10)
        panelCorner.Parent = panel
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 28))
        }
        gradient.Rotation = 135
        gradient.Parent = panel
        
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(1, 0, 0, 2)
        accent.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        accent.BorderSizePixel = 0
        accent.Parent = panel
        
        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(0, 10)
        accentCorner.Parent = accent
        
        local accentGradient = Instance.new("UIGradient")
        accentGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255))
        }
        accentGradient.Parent = accent

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 32, 0, 32)
        icon.Position = UDim2.new(0, 12, 0, 14)
        icon.BackgroundTransparency = 1
        icon.Text = environment.isMobile and "📱" or "🛡️"
        icon.TextColor3 = Color3.fromRGB(100, 150, 255)
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 20
        icon.ClipsDescendants = true
        icon.ZIndex = 2
        icon.Parent = panel
        
        local iconShine = Instance.new("Frame")
        iconShine.Size = UDim2.new(0, 6, 1.2, 0)
        iconShine.Position = UDim2.new(0, -8, -0.1, 0)
        iconShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iconShine.BorderSizePixel = 0
        iconShine.Rotation = 20
        iconShine.BackgroundTransparency = 0.5
        iconShine.ZIndex = 3
        iconShine.Parent = icon
        
        local shineGradient = Instance.new("UIGradient")
        shineGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0),
            NumberSequenceKeypoint.new(0.7, 0),
            NumberSequenceKeypoint.new(1, 1)
        }
        shineGradient.Rotation = 90
        shineGradient.Parent = iconShine

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -140, 0, 28)
        title.Position = UDim2.new(0, 48, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "AFK Guardian"
        title.TextColor3 = Color3.fromRGB(245, 245, 250)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = panel

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 80, 0, 32)
        toggle.Position = UDim2.new(1, -92, 0, 11)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 14
        toggle.Text = "OFF"
        toggle.AutoButtonColor = false
        toggle.Parent = panel
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 8)
        toggleCorner.Parent = toggle
        
        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(80, 80, 85)
        toggleStroke.Thickness = 1.5
        toggleStroke.Transparency = 0.5
        toggleStroke.Parent = toggle

        local statusBar = Instance.new("Frame")
        statusBar.Size = UDim2.new(1, -24, 0, 32)
        statusBar.Position = UDim2.new(0, 12, 0, 50)
        statusBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        statusBar.BorderSizePixel = 0
        statusBar.Parent = panel
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(0, 6)
        statusCorner.Parent = statusBar

        local statusDot = Instance.new("Frame")
        statusDot.Size = UDim2.new(0, 8, 0, 8)
        statusDot.Position = UDim2.new(0, 10, 0.5, -4)
        statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 105)
        statusDot.BorderSizePixel = 0
        statusDot.Parent = statusBar
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = statusDot

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -30, 1, 0)
        status.Position = UDim2.new(0, 24, 0, 0)
        status.BackgroundTransparency = 1
        status.Text = "System Idle"
        status.TextColor3 = Color3.fromRGB(180, 180, 185)
        status.Font = Enum.Font.GothamMedium
        status.TextSize = environment.isMobile and 11 or 12
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = statusBar

        return {
            gui = gui, 
            panel = panel, 
            shadow = shadow,
            toggle = toggle, 
            toggleStroke = toggleStroke,
            status = status,
            statusDot = statusDot,
            accent = accent,
            icon = icon,
            iconShine = iconShine
        }
    end)
    
    if not success then
        warn("UI creation error:", result)
        return nil
    end
    
    return result
end

local ui = createUI()
if not ui then
    error("Failed to create UI")
    return
end

makeDraggable(ui.panel)

pcall(function()
    table.insert(connections, ui.panel:GetPropertyChangedSignal("Position"):Connect(function()
        ui.shadow.Position = UDim2.new(
            ui.panel.Position.X.Scale,
            ui.panel.Position.X.Offset - 2,
            ui.panel.Position.Y.Scale,
            ui.panel.Position.Y.Offset - 2
        )
    end))
end)

local function cameraNudge()
    pcall(function()
        local camera = workspace.CurrentCamera
        if not camera or not environment.hasCamera then return end
        
        local original = camera.CFrame
        local pattern = math.random(1, 3)
        
        if pattern == 1 then
            local yaw = math.rad(randRange(-1.5, 1.5))
            local pitch = math.rad(randRange(-0.8, 0.8))
            local target = original * CFrame.Angles(pitch, yaw, 0)
            
            local success = pcall(function()
                local tween = TweenService:Create(camera,
                    TweenInfo.new(randRange(0.15, 0.3), Enum.EasingStyle.Sine),
                    {CFrame = target}
                )
                tween:Play()
                tween.Completed:Wait()
            end)
            
            if not success then
                camera.CFrame = camera.CFrame:Lerp(target, 0.5)
            end
            
            wait(randRange(0.1, 0.2))
            
            pcall(function()
                TweenService:Create(camera, TweenInfo.new(randRange(0.15, 0.3), Enum.EasingStyle.Sine),
                    {CFrame = original}):Play()
            end)
                
        elseif pattern == 2 then
            local yaw = math.rad(randRange(-2.5, 2.5))
            local pitch = math.rad(randRange(-1, 1))
            local target = original * CFrame.Angles(pitch, yaw, 0)
            
            local success = pcall(function()
                local tween = TweenService:Create(camera,
                    TweenInfo.new(randRange(1.5, 2.5), Enum.EasingStyle.Linear),
                    {CFrame = target}
                )
                tween:Play()
                tween.Completed:Wait()
            end)
            
            if not success then
                for i = 1, 10 do
                    camera.CFrame = camera.CFrame:Lerp(target, 0.1)
                    wait(0.15)
                end
            end
            
            pcall(function()
                TweenService:Create(camera, TweenInfo.new(randRange(1, 1.5), Enum.EasingStyle.Sine),
                    {CFrame = original}):Play()
            end)
                
        else
            local steps = math.random(8, 12)
            for i = 1, steps do
                if not settings.enabled then break end
                local angle = (i / steps) * math.pi * 2
                local yaw = math.rad(math.sin(angle) * 1.5)
                local pitch = math.rad(math.cos(angle) * 0.7)
                local target = original * CFrame.Angles(pitch, yaw, 0)
                camera.CFrame = camera.CFrame:Lerp(target, 0.25)
                wait(randRange(0.08, 0.15))
            end
            camera.CFrame = camera.CFrame:Lerp(original, 0.4)
        end
    end)
end

local function characterMovement()
    pcall(function()
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            local moveDirection = math.random(1, 4)
            local directions = {
                Vector3.new(1, 0, 0),
                Vector3.new(-1, 0, 0),
                Vector3.new(0, 0, 1),
                Vector3.new(0, 0, -1)
            }
            
            humanoid:Move(directions[moveDirection], false)
            wait(randRange(0.05, 0.15))
            humanoid:Move(Vector3.new(0, 0, 0), false)
            
            if math.random() < 0.3 then
                pcall(function()
                    humanoid.Jump = true
                end)
            end
        end
    end)
end

local function virtualAction()
    pcall(function()
        local count = math.random(1, 2)
        for i = 1, count do
            if not settings.enabled then break end
            
            local success = false
            
            if environment.hasVirtualUser then
                success = pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                end)
            end
            
            if not success then
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace)
                    wait(0.05)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace)
                end)
            end
            
            if not success and environment.isMobile then
                pcall(function()
                    local touch = Instance.new("TouchInputObject")
                    touch.Position = Vector2.new(0, 0)
                end)
            end
            
            wait(randRange(0.4, 1.2))
        end
    end)
end

local function performAction()
    if not settings.enabled then return end
    
    pcall(function()
        local methods = {}
        
        if environment.hasCamera then
            table.insert(methods, cameraNudge)
        end
        
        if environment.hasVirtualUser then
            table.insert(methods, virtualAction)
        end
        
        table.insert(methods, characterMovement)
        
        if #methods == 0 then
            warn("No AFK prevention methods available")
            return
        end
        
        local action = math.random(1, 10)
        
        if action <= 5 then
            if environment.hasCamera then
                cameraNudge()
            else
                methods[math.random(#methods)]()
            end
        elseif action <= 8 then
            if environment.hasVirtualUser then
                virtualAction()
            elseif environment.hasCamera then
                cameraNudge()
            else
                characterMovement()
            end
        else
            if environment.hasCamera then
                cameraNudge()
                wait(randRange(0.5, 1))
            end
            
            if environment.hasVirtualUser then
                virtualAction()
            else
                characterMovement()
            end
        end
    end)
end

local function setEnabled(state)
    if not ui or not ui.toggle then return end
    
    pcall(function()
        settings.enabled = state
        ui.toggle.Text = state and "ON" or "OFF"
        
        local statusText = "System Idle"
        if state then
            if settings.isWindowFocused then
                statusText = "Active Protection"
            else
                statusText = "Active (Tab Unfocused)"
            end
        end
        ui.status.Text = statusText
        
        local toggleColor = state and Color3.fromRGB(70, 160, 90) or Color3.fromRGB(60, 60, 65)
        local strokeColor = state and Color3.fromRGB(90, 200, 120) or Color3.fromRGB(80, 80, 85)
        local dotColor = state and Color3.fromRGB(90, 220, 120) or Color3.fromRGB(100, 100, 105)
        local statusColor = state and Color3.fromRGB(200, 220, 210) or Color3.fromRGB(180, 180, 185)
        
        TweenService:Create(ui.toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), 
            {BackgroundColor3 = toggleColor}):Play()
        TweenService:Create(ui.toggleStroke, TweenInfo.new(0.3), 
            {Color = strokeColor}):Play()
        TweenService:Create(ui.statusDot, TweenInfo.new(0.3), 
            {BackgroundColor3 = dotColor}):Play()
        TweenService:Create(ui.status, TweenInfo.new(0.3), 
            {TextColor3 = statusColor}):Play()
        
        if state then
            local original = ui.toggle.Size
            ui.toggle.Size = UDim2.new(0, 76, 0, 30)
            TweenService:Create(ui.toggle, TweenInfo.new(0.2, Enum.EasingStyle.Back), 
                {Size = original}):Play()
        end
    end)
end

if ui and ui.toggle then
    table.insert(connections, ui.toggle.MouseButton1Click:Connect(function()
        setEnabled(not settings.enabled)
    end))

    if environment.isPC then
        table.insert(connections, ui.toggle.MouseEnter:Connect(function()
            pcall(function()
                TweenService:Create(ui.toggle, TweenInfo.new(0.15), 
                    {Size = UDim2.new(0, 84, 0, 34)}):Play()
                TweenService:Create(ui.toggleStroke, TweenInfo.new(0.15), 
                    {Transparency = 0.2, Thickness = 2}):Play()
            end)
        end))

        table.insert(connections, ui.toggle.MouseLeave:Connect(function()
            pcall(function()
                TweenService:Create(ui.toggle, TweenInfo.new(0.15), 
                    {Size = UDim2.new(0, 80, 0, 32)}):Play()
                TweenService:Create(ui.toggleStroke, TweenInfo.new(0.15), 
                    {Transparency = 0.5, Thickness = 1.5}):Play()
            end)
        end))
    else
        table.insert(connections, ui.toggle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                pcall(function()
                    TweenService:Create(ui.toggle, TweenInfo.new(0.1), 
                        {Size = UDim2.new(0, 84, 0, 34)}):Play()
                    TweenService:Create(ui.toggleStroke, TweenInfo.new(0.1), 
                        {Transparency = 0.2, Thickness = 2}):Play()
                end)
            end
        end))
        
        table.insert(connections, ui.toggle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                pcall(function()
                    wait(0.15)
                    TweenService:Create(ui.toggle, TweenInfo.new(0.15), 
                        {Size = UDim2.new(0, 80, 0, 32)}):Play()
                    TweenService:Create(ui.toggleStroke, TweenInfo.new(0.15), 
                        {Transparency = 0.5, Thickness = 1.5}):Play()
                end)
            end
        end))
    end
end

local function connectIdled()
    pcall(function()
        table.insert(connections, player.Idled:Connect(function()
            if settings.enabled then
                task.spawn(function()
                    performAction()
                    if not settings.isWindowFocused then
                        wait(randRange(2, 4))
                        performAction()
                    end
                end)
            end
        end))
    end)
end
connectIdled()

table.insert(connections, player.CharacterAdded:Connect(function()
    wait(1)
    connectIdled()
end))

task.spawn(function()
    while task.wait(1) do
        if not settings.enabled or not ui or not ui.gui or not ui.gui.Parent then break end
        
        pcall(function()
            if math.random() < settings.burstChance then
                for i = 1, math.random(2, 3) do
                    if not settings.enabled then break end
                    performAction()
                    wait(randRange(1, 2))
                end
            else
                performAction()
            end
        end)
        
        local waitTime = nextWait()
        for i = 1, waitTime do
            if not settings.enabled or not ui or not ui.gui or not ui.gui.Parent then break end
            wait(1)
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if not settings.enabled or not ui or not ui.gui or not ui.gui.Parent then break end
        
        pcall(function()
            if not settings.isWindowFocused then
                performAction()
            end
        end)
        
        if not settings.isWindowFocused then
            wait(randRange(15, 30))
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if not ui or not ui.statusDot or not ui.gui or not ui.gui.Parent then break end
        
        pcall(function()
            if settings.enabled then
                TweenService:Create(ui.statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine), 
                    {BackgroundTransparency = 0.3}):Play()
                wait(0.8)
                if ui and ui.statusDot then
                    TweenService:Create(ui.statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine), 
                        {BackgroundTransparency = 0}):Play()
                end
            else
                if ui and ui.statusDot then
                    ui.statusDot.BackgroundTransparency = 0
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(2.5) do
        if not ui or not ui.iconShine or not ui.gui or not ui.gui.Parent then break end
        
        pcall(function()
            ui.iconShine.Position = UDim2.new(0, -8, -0.1, 0)
            local shine = TweenService:Create(ui.iconShine,
                TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                {Position = UDim2.new(1, 8, -0.1, 0)}
            )
            shine:Play()
            shine.Completed:Wait()
            wait(1.8)
        end)
    end
end)

task.spawn(function()
    while task.wait(3) do
        if not ui or not ui.accent or not ui.gui or not ui.gui.Parent then break end
        
        pcall(function()
            local gradient = ui.accent:FindFirstChildOfClass("UIGradient")
            if gradient then
                local shimmer = TweenService:Create(gradient,
                    TweenInfo.new(2, Enum.EasingStyle.Sine),
                    {Offset = Vector2.new(1, 0)}
                )
                shimmer:Play()
                shimmer.Completed:Wait()
                if gradient then
                    gradient.Offset = Vector2.new(-1, 0)
                end
            end
        end)
    end
end)

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == settings.toggleKey and environment.isPC then
        setEnabled(not settings.enabled)
    end
end))

table.insert(connections, UserInputService.WindowFocusReleased:Connect(function()
    settings.isWindowFocused = false
    if settings.enabled and ui and ui.status then
        pcall(function()
            ui.status.Text = "Active (Tab Unfocused)"
            TweenService:Create(ui.status, TweenInfo.new(0.3), 
                {TextColor3 = Color3.fromRGB(255, 200, 100)}):Play()
        end)
    end
end))

table.insert(connections, UserInputService.WindowFocused:Connect(function()
    settings.isWindowFocused = true
    if settings.enabled and ui and ui.status then
        pcall(function()
            ui.status.Text = "Active Protection"
            TweenService:Create(ui.status, TweenInfo.new(0.3), 
                {TextColor3 = Color3.fromRGB(200, 220, 210)}):Play()
        end)
    end
end))

local lastHeartbeatAction = tick()
local nextActionTime = 0

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not settings.enabled then return end
    
    local currentTime = tick()
    if currentTime >= nextActionTime then
        nextActionTime = currentTime + nextWait()
        task.spawn(function()
            performAction()
        end)
    end
end))

local function cleanup()
    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    
    if ui and ui.gui then
        pcall(function()
            ui.gui:Destroy()
        end)
    end
end

table.insert(connections, game:GetService("Players").PlayerRemoving:Connect(function(plr)
    if plr == player then
        cleanup()
    end
end))

isInitialized = true
wait(1)

local platformText = environment.isMobile and "Mobile" or "PC"
local toggleHint = environment.isMobile and "Tap button to toggle" or "Press F4 or click to toggle"
local methodsText = ""
if environment.hasCamera and environment.hasVirtualUser then
    methodsText = "All methods"
elseif environment.hasCamera then
    methodsText = "Camera + Movement"
elseif environment.hasVirtualUser then
    methodsText = "Virtual + Movement"
else
    methodsText = "Movement only"
end

showNotification("AFK Guardian", string.format("%s | %s | %s", platformText, methodsText, toggleHint), 8)
