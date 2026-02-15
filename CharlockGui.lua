-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Variables
local LocalPlayer = Players.LocalPlayer
local isLocked = false
local currentTarget = nil
local lockDistance = 200 -- Distance to scan for enemies

-- SETTINGS
local prediction = 0.25 -- Sets the prediction amount

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local ButtonCorner = Instance.new("UICorner")
local ButtonStroke = Instance.new("UIStroke")

-- Protect UI
if pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

ScreenGui.Name = "CharLockGUI_Pred"
ScreenGui.ResetOnSpawn = false

-- ---------------------------------------------------------
-- BUTTON SETUP
-- ---------------------------------------------------------

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ToggleButton.Position = UDim2.new(0.5, -60, 0.2, 0)
ToggleButton.Size = UDim2.new(0, 120, 0, 50)
ToggleButton.Font = Enum.Font.GothamBlack
ToggleButton.Text = "Lock: OFF (P: 0.25)"
ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
ToggleButton.TextSize = 14
ToggleButton.Active = true
ToggleButton.AutoButtonColor = true

ButtonCorner.CornerRadius = UDim.new(0, 12)
ButtonCorner.Parent = ToggleButton

ButtonStroke.Parent = ToggleButton
ButtonStroke.Thickness = 2
ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- ---------------------------------------------------------
-- DRAGGABLE LOGIC
-- ---------------------------------------------------------
local function makeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        TweenService:Create(obj, TweenInfo.new(0.1), {Position = newPos}):Play()
    end
    
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    obj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

makeDraggable(ToggleButton)

-- ---------------------------------------------------------
-- LOGIC
-- ---------------------------------------------------------

local function getNearestEnemy()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                local targetPos = player.Character.HumanoidRootPart.Position
                local distance = (targetPos - myPos).Magnitude

                if distance < shortestDistance and distance <= lockDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

local function setAutoRotate(bool)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.AutoRotate = bool
    end
end

-- Button Click
ToggleButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked

    if isLocked then
        ToggleButton.Text = "Lock: ON (P: 0.25)"
        ToggleButton.TextColor3 = Color3.fromRGB(0, 170, 255)
        ButtonStroke.Color = Color3.fromRGB(0, 170, 255)
        
        setAutoRotate(false)
        currentTarget = getNearestEnemy()
    else
        ToggleButton.Text = "Lock: OFF (P: 0.25)"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
        ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
        
        setAutoRotate(true)
        currentTarget = nil
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    if isLocked and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") and currentTarget.Character.Humanoid.Health > 0 then
            
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local targetRoot = currentTarget.Character.HumanoidRootPart
            
            -- CALCULATE PREDICTION
            -- Target Position + (Target Velocity * Prediction Amount)
            local predictedPosition = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * prediction)

            -- IGNORE HEIGHT DIFFERENCE (Flatten Y axis to LocalPlayer's Y)
            local lookPosition = Vector3.new(predictedPosition.X, myRoot.Position.Y, predictedPosition.Z)
            
            myRoot.CFrame = CFrame.lookAt(myRoot.Position, lookPosition)
            
        else
            currentTarget = getNearestEnemy()
        end
    end
end)

-- Ensure AutoRotate resets if you die
LocalPlayer.CharacterAdded:Connect(function()
    isLocked = false
    ToggleButton.Text = "Lock: OFF (P: 0.25)"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
    ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
end)
