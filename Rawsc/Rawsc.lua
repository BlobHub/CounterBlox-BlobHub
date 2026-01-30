-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- [[ Variables ]]
local aimbotEnabled = false
local teamCheckEnabled = false
local espEnabled = false
local headAimEnabled = true 
local fovSize = 100
local fovVisible = false
local walkSpeedValue = 16 
local currentTarget = nil

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ FOV Circle Drawing ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(255, 182, 193)
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

-- [[ Core Functions ]]
local function setupHighlight(character, player)
    if player == LocalPlayer then return end
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 182, 193)
    highlight.Enabled = espEnabled
    highlight.Parent = character
end

local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local screenCenter = Camera.ViewportSize / 2

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if teamCheckEnabled and player.Team == LocalPlayer.Team then continue end

            local partName = headAimEnabled and "Head" or "HumanoidRootPart"
            local targetPart = player.Character:FindFirstChild(partName)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local distanceOnScreen = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude

                if onScreen and distanceOnScreen < shortestDistance and distanceOnScreen <= fovSize then
                    closestTarget = player
                    shortestDistance = distanceOnScreen
                end
            end
        end
    end
    return closestTarget
end

-- [[ Main Window & Key System ]]
local Window = Rayfield:CreateWindow({
   Name = "Blob Rookie Hub",
   LoadingTitle = "Welcome to Blob Rookie Hub",
   LoadingSubtitle = "by Blob",
   ConfigurationSaving = { Enabled = true, FolderName = "BlobHub", FileName = "BlobConfig" },
   KeySystem = true,
   KeySettings = {
      Title = "Key System",
      Subtitle = "Join Discord for Key",
      Note = "discord.gg/WYga5sst9n",
      FileName = "BlobKey", 
      SaveKey = true,
      GrabKeyFromSite = true,
      Key = {"https://pastebin.com/raw/rUvPEVJK"},
      Actions = {
            {
                Text = "Get Key",
                Callback = function()
                    setclipboard("https://pastebin.com/raw/rUvPEVJK")
                    -- Fallback notification
                    print("Key Link Copied to Clipboard")
                end
            }
      }
   }
})

-- [[ Tabs ]]
local MainTab = Window:CreateTab("🏡 Home", nil)
local MiscTab = Window:CreateTab("⚙️ Settings", nil)

-- [[ Home Section ]]
local MainSection = MainTab:CreateSection("Combat & Movement")

MainTab:CreateToggle({
   Name = "Autoaim",
   CurrentValue = false,
   Flag = "AutoaimToggle",
   Callback = function(Value) aimbotEnabled = Value end,
})

MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheckToggle",
    Callback = function(Value) teamCheckEnabled = Value end,
})

MainTab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
       espEnabled = Value
       for _, player in pairs(Players:GetPlayers()) do
           if player.Character and player.Character:FindFirstChild("Highlight") then
               player.Character.Highlight.Enabled = Value
           end
       end
   end,
})

MainTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head","Body"},
   CurrentOption = {"Head"},
   Callback = function(Options) headAimEnabled = (Options[1] == "Head") end,
})

MainTab:CreateToggle({
   Name = "FOV Visible",
   CurrentValue = false,
   Flag = "FOVVisibleToggle",
   Callback = function(Value) fovVisible = Value end,
})

MainTab:CreateSlider({
   Name = "FOV Size",
   Range = {0, 500},
   Increment = 1,
   CurrentValue = 100,
   Flag = "FOVSlider",
   Callback = function(Value) fovSize = Value end,
})

MainTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 16,
   Flag = "SpeedSlider",
   Callback = function(Value) walkSpeedValue = Value end,
})

-- [[ Settings Section ]]
local MiscSect = MiscTab:CreateSection("Interface Settings")

-- FIXED THEME LOGIC
MiscTab:CreateDropdown({
   Name = "Theme",
   Options = {"Default","AmberGlow","Amethyst","Bloom","DarkBlue","Green","Light","Ocean","Serenity"},
   CurrentOption = {"Ocean"},
   Callback = function(Options)
       local selectedTheme = tostring(Options[1])
       -- Rayfield modification requires the exact string identifier
       Rayfield:ModifyTheme(selectedTheme)
   end,
})

MiscTab:CreateButton({
   Name = "Copy Discord Link",
   Callback = function()
       setclipboard("https://discord.gg/WYga5sst9n")
       Rayfield:Notify({Title = "Copied!", Content = "Discord link copied to clipboard.", Duration = 3})
   end,
})

-- [[ Main Logic Loop ]]
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeedValue
    end

    FOVCircle.Visible = fovVisible
    FOVCircle.Radius = fovSize
    FOVCircle.Position = Camera.ViewportSize / 2

    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not player.Character:FindFirstChild("Highlight") then
                    setupHighlight(player.Character, player)
                else
                    player.Character.Highlight.Enabled = true
                end
            end
        end
    end

    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        currentTarget = getClosestTarget()
        if currentTarget and currentTarget.Character then
            local partName = headAimEnabled and "Head" or "HumanoidRootPart"
            local targetPart = currentTarget.Character:FindFirstChild(partName)
            if targetPart then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), 0.15)
            end
        end
    end
end)

Rayfield:Notify({Title = "Hub Loaded", Content = "Welcome back, Blob!", Duration = 5})
