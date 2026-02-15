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
local prediction = 0.25 -- Default prediction amount

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local ButtonCorner = Instance.new("UICorner")
local ButtonStroke = Instance.new("UIStroke")

-- NEW PREDICTION INPUT VARIABLES
local PredBox = Instance.new("TextBox")
local PredCorner = Instance.new("UICorner")
local PredStroke = Instance.new("UIStroke")

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
ToggleButton.Text = "Char Lock: Off"
ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
ToggleButton.TextSize = 16
ToggleButton.Active = true
ToggleButton.AutoButtonColor = true
ToggleButton.ClipsDescendants = false -- Important so the box shows below

ButtonCorner.CornerRadius = UDim.new(0, 12)
ButtonCorner.Parent = ToggleButton

ButtonStroke.Parent = ToggleButton
ButtonStroke.Thickness = 2
ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
ButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- ---------------------------------------------------------
-- PREDICTION BOX SETUP (New)
-- ---------------------------------------------------------

PredBox.Name = "PredictionInput"
PredBox.Parent = ToggleButton -- Attached to button so they move together
PredBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
PredBox.Position = UDim2.new(0, 0, 1, 5) -- Positioned right below the button
PredBox.Size = UDim2.new(1, 0, 0, 30) -- Matches width of button
PredBox.Font = Enum.Font.GothamBold
PredBox.Text = tostring(prediction) -- Shows current prediction
PredBox.PlaceholderText = "Enter Pred"
PredBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PredBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
PredBox.TextSize = 14

PredCorner.CornerRadius = UDim.new(0, 8)
PredCorner.Parent = PredBox

PredStroke.Parent = PredBox
PredStroke.Thickness = 1
PredStroke.Color = Color3.fromRGB(255, 60, 60) -- Matches theme
PredStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

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

-- Update Prediction when typing inside the box
PredBox.FocusLost:Connect(function(enterPressed)
    local inputNum = tonumber(PredBox.Text)
    if inputNum then
        prediction = inputNum
        PredBox.Text = tostring(inputNum) -- Format text
        -- Visual feedback
        PredStroke.Color = Color3.fromRGB(0, 255, 100)
        task.wait(0.5)
        if isLocked then
            PredStroke.Color = Color3.fromRGB(0, 170, 255)
        else
            PredStroke.Color = Color3.fromRGB(255, 60, 60)
        end
    else
        -- Invalid number, reset to old value
        PredBox.Text = tostring(prediction)
    end
end)

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
        ToggleButton.Text = "Char Lock: ON"
        ToggleButton.TextColor3 = Color3.fromRGB(0, 170, 255)
        ButtonStroke.Color = Color3.fromRGB(0, 170, 255)
        PredStroke.Color = Color3.fromRGB(0, 170, 255) -- Update box color too
        
        setAutoRotate(false)
        currentTarget = getNearestEnemy()
    else
        ToggleButton.Text = "Char Lock: Of"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
        ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
        PredStroke.Color = Color3.fromRGB(255, 60, 60) -- Update box color too
        
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
    ToggleButton.Text = "Char Lock: Off"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 60, 60)
    ButtonStroke.Color = Color3.fromRGB(255, 60, 60)
    PredStroke.Color = Color3.fromRGB(255, 60, 60)
end)end)
