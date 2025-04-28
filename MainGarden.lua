-- Main Tab
local MainTab = Window:CreateTab("🌟 Main", nil)

-- Movement Section
MainTab:CreateSection("Movement")

-- WalkSpeed Setup
local originalWalkSpeed = 16
local customWalkSpeed = 16
local WalkSpeedEnabled = false

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    originalWalkSpeed = character.Humanoid.WalkSpeed
    if WalkSpeedEnabled then
        character.Humanoid.WalkSpeed = customWalkSpeed
    end
end)

MainTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Callback = function(Value)
        WalkSpeedEnabled = Value
        if game.Players.LocalPlayer.Character then
            if Value then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = customWalkSpeed
            else
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = originalWalkSpeed
            end
        end
    end,
})

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        customWalkSpeed = Value
        if WalkSpeedEnabled and game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

-- Fly Setup
local FlySpeed = 50
local FlyEnabled = false
local flyConnection = nil

local function toggleFly(value)
    FlyEnabled = value
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = character.HumanoidRootPart
    
    for _, name in pairs({"FlyBV", "FlyAG"}) do
        local part = hrp:FindFirstChild(name)
        if part then part:Destroy() end
    end
    
    if value then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyBV"
        bv.Velocity = Vector3.new(0, 0.1, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.P = 1100
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyAG"
        bg.P = 9e3
        bg.D = 45
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        
        flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not character:FindFirstChild("HumanoidRootPart") or not FlyEnabled then
                return
            end
            
            local camera = workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            
            local UserInputService = game:GetService("UserInputService")
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + (camera.CFrame.LookVector * FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - (camera.CFrame.LookVector * FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - (camera.CFrame.RightVector * FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + (camera.CFrame.RightVector * FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + (camera.CFrame.UpVector * FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDir = moveDir - (camera.CFrame.UpVector * FlySpeed)
            end
            
            local randomOffset = Vector3.new(
                (math.random() - 0.5) * 0.05,
                (math.random() - 0.5) * 0.05,
                (math.random() - 0.5) * 0.05
            )
            
            local bv = hrp:FindFirstChild("FlyBV")
            if bv then
                bv.Velocity = moveDir + randomOffset
                local bg = hrp:FindFirstChild("FlyAG")
                if bg and (moveDir.X ~= 0 or moveDir.Z ~= 0) then
                    bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(moveDir.X, 0, moveDir.Z))
                end
            end
        end)
    end
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if FlyEnabled then
        task.wait(0.5)
        toggleFly(true)
    end
end)

MainTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Callback = function(Value)
        toggleFly(Value)
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 50,
    Callback = function(Value)
        FlySpeed = Value
    end,
})

-- NoClip Setup
local NoClipEnabled = false
local noClipConnection = nil

local function toggleNoClip(value)
    NoClipEnabled = value
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end

    if game.Players.LocalPlayer.Character then
        for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not value
            end
        end
    end

    if value then
        noClipConnection = game:GetService("RunService").Stepped:Connect(function()
            if game.Players.LocalPlayer.Character and NoClipEnabled then
                for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

MainTab:CreateToggle({
    Name = "Enable NoClip",
    CurrentValue = false,
    Callback = function(Value)
        toggleNoClip(Value)
    end,
})

-- ESP Section
MainTab:CreateSection("ESP")

local ESPSettings = {
    Nametag = false,
    TwoDBox = false,
    TwoDBoxColor = Color3.new(1, 1, 1),
    Chams = false,
    ChamsVisibleColor = Color3.new(1, 1, 1),
    ChamsBehindColor = Color3.new(0, 0, 0)
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_2DBoxGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer.PlayerGui
local boxFrames = {}
local highlightModels = {}
local playerConnections = {}

local function CreateNametag(player)
    if not player or not player.Character then return end
    if player.Character:FindFirstChild("NameTag") then 
        player.Character.NameTag:Destroy()
    end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "NameTag"
    Billboard.Size = UDim2.new(0, 100, 0, 40)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = player.Character

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = player.Name
    Label.TextColor3 = Color3.new(1, 1, 1)
    Label.TextStrokeTransparency = 0.5
    Label.Font = Enum.Font.SourceSansBold
    Label.TextScaled = true
    Label.Parent = Billboard

    if ESPSettings.TwoDBox then
        local _, size = player.Character:GetBoundingBox()
        Billboard.StudsOffset = Vector3.new(0, size.Y/2 + 1.5, 0)
    end
end

local function UpdateNametagPositions()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local billboard = player.Character:FindFirstChild("NameTag")
            if billboard then
                if ESPSettings.TwoDBox then
                    local _, size = player.Character:GetBoundingBox()
                    billboard.StudsOffset = Vector3.new(0, size.Y/2 + 1.5, 0)
                else
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                end
            end
        end
    end
end

local function createFramesForPlayer(player)
    if not player or not player.Character then return end
    
    if boxFrames[player] then
        for _, frame in pairs(boxFrames[player]) do
            frame:Destroy()
        end
    end
    
    local frameSet = {
        top = Instance.new("Frame"),
        bottom = Instance.new("Frame"),
        left = Instance.new("Frame"),
        right = Instance.new("Frame")
    }
    for _, frame in pairs(frameSet) do
        frame.BackgroundTransparency = 0
        frame.Visible = false
        frame.BackgroundColor3 = ESPSettings.TwoDBoxColor
        frame.Parent = screenGui

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.new(0, 0, 0)
        stroke.Thickness = 1
        stroke.Transparency = 0
        stroke.Parent = frame
    end
    frameSet.top.Name = "ESPBoxTop_" .. player.Name
    frameSet.bottom.Name = "ESPBoxBottom_" .. player.Name
    frameSet.left.Name = "ESPBoxLeft_" .. player.Name
    frameSet.right.Name = "ESPBoxRight_" .. player.Name
    boxFrames[player] = frameSet
end

local function updateFramePosition(player, frameSet)
    if not player or not player.Character or not frameSet then
        if frameSet then
            for _, frame in pairs(frameSet) do
                frame.Visible = false
            end
        end
        return
    end
    
    local success, cframe, size = pcall(function() return player.Character:GetBoundingBox() end)
    if not success then
        for _, frame in pairs(frameSet) do
            frame.Visible = false
        end
        return
    end
    
    local camera = workspace.CurrentCamera
    local centerPos = cframe.Position
    local distance = (camera.CFrame.Position - centerPos).Magnitude
    local screenPos, onScreen = camera:WorldToViewportPoint(centerPos)
    
    if not onScreen then
        for _, frame in pairs(frameSet) do
            frame.Visible = false
        end
        return
    end

    local referenceDistance = 10
    local pixelPerStudAtReference = 50
    local scaleFactor = referenceDistance / distance
    local width = size.X * pixelPerStudAtReference * scaleFactor
    local height = size.Y * pixelPerStudAtReference * scaleFactor
    local verticalScale = 1.2
    height = height * verticalScale
    local padding = 5

    width = width + padding * 2
    height = height + padding * 2

    local minX = screenPos.X - width / 2
    local maxX = screenPos.X + width / 2
    local minY = screenPos.Y - height / 2
    local maxY = screenPos.Y + height / 2

    frameSet.top.Visible = true
    frameSet.top.Position = UDim2.new(0, minX, 0, minY)
    frameSet.top.Size = UDim2.new(0, width, 0, 2)
    frameSet.bottom.Visible = true
    frameSet.bottom.Position = UDim2.new(0, minX, 0, maxY - 2)
    frameSet.bottom.Size = UDim2.new(0, width, 0, 2)
    frameSet.left.Visible = true
    frameSet.left.Position = UDim2.new(0, minX, 0, minY)
    frameSet.left.Size = UDim2.new(0, 2, 0, height)
    frameSet.right.Visible = true
    frameSet.right.Position = UDim2.new(0, maxX - 2, 0, minY)
    frameSet.right.Size = UDim2.new(0, 2, 0, height)
end

local function CreateHighlightModel(player)
    if not player or not player.Character then return end
    
    if highlightModels[player] then
        highlightModels[player]:Destroy()
        highlightModels[player] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight_" .. player.Name
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.FillColor = ESPSettings.ChamsVisibleColor
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = ESPSettings.ChamsVisibleColor
    highlight.Adornee = player.Character
    highlight.Parent = player.Character

    highlightModels[player] = highlight
end

local function CheckVisibility(player)
    if not player or not player.Character or not ESPSettings.Chams then return end
    if not highlightModels[player] then return end
    
    local camera = workspace.CurrentCamera
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local ray = Ray.new(camera.CFrame.Position, (humanoidRootPart.Position - camera.CFrame.Position).Unit * 100)
    local hit, _ = workspace:FindPartOnRayWithIgnoreList(ray, {game.Players.LocalPlayer.Character or {}})
    
    local isBehindWall = hit and hit:IsDescendantOf(workspace) and not hit:IsDescendantOf(player.Character)
    local color = isBehindWall and ESPSettings.ChamsBehindColor or ESPSettings.ChamsVisibleColor

    highlightModels[player].FillColor = color
    highlightModels[player].OutlineColor = color
end

local function cleanupPlayerEffects(player)
    if player and player.Character then
        if player.Character:FindFirstChild("NameTag") then
            player.Character.NameTag:Destroy()
        end
    end
    
    if boxFrames[player] then
        for _, frame in pairs(boxFrames[player]) do
            frame:Destroy()
        end
        boxFrames[player] = nil
    end
    
    if highlightModels[player] then
        highlightModels[player]:Destroy()
        highlightModels[player] = nil
    end
end

local function applyESPEffects(player)
    if not player or not player.Character then return end
    
    if ESPSettings.Nametag then
        CreateNametag(player)
    end
    
    if ESPSettings.TwoDBox then
        createFramesForPlayer(player)
    end
    
    if ESPSettings.Chams then
        CreateHighlightModel(player)
    end
end

MainTab:CreateToggle({
    Name = "Enable Nametags",
    CurrentValue = false,
    Callback = function(Value)
        ESPSettings.Nametag = Value
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                if Value then
                    CreateNametag(player)
                elseif player.Character:FindFirstChild("NameTag") then
                    player.Character.NameTag:Destroy()
                end
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = "Enable 2D Box",
    CurrentValue = false,
    Callback = function(Value)
        ESPSettings.TwoDBox = Value
        if Value then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    createFramesForPlayer(player)
                end
            end
        else
            for _, frameSet in pairs(boxFrames) do
                for _, frame in pairs(frameSet) do
                    frame:Destroy()
                end
            end
            boxFrames = {}
        end
        UpdateNametagPositions()
    end,
})

MainTab:CreateColorPicker({
    Name = "2D Box Color",
    Color = Color3.new(1, 1, 1),
    Callback = function(Value)
        ESPSettings.TwoDBoxColor = Value
        for _, frameSet in pairs(boxFrames) do
            for _, frame in pairs(frameSet) do
                frame.BackgroundColor3 = Value
            end
        end
    end,
})

MainTab:CreateToggle({
    Name = "Enable Chams",
    CurrentValue = false,
    Callback = function(Value)
        ESPSettings.Chams = Value
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                if Value then
                    CreateHighlightModel(player)
                elseif highlightModels[player] then
                    highlightModels[player]:Destroy()
                    highlightModels[player] = nil
                end
            end
        end
    end,
})

MainTab:CreateColorPicker({
    Name = "Chams Visible Color",
    Color = Color3.new(1, 1, 1),
    Callback = function(Value)
        ESPSettings.ChamsVisibleColor = Value
        if ESPSettings.Chams then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    CheckVisibility(player)
                end
            end
        end
    end,
})

MainTab:CreateColorPicker({
    Name = "Chams Behind Walls Color",
    Color = Color3.new(0, 0, 0),
    Callback = function(Value)
        ESPSettings.ChamsBehindColor = Value
        if ESPSettings.Chams then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    CheckVisibility(player)
                end
            end
        end
    end,
})
