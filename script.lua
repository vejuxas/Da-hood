
print("Compkiller UI library loaded successfully!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Kill Aura globals
getgenv().KillAuraUseAimbot = false
getgenv().KillAuraPrediction = 0.165

-- Settings
local Settings = {
    hitboxSize = 20,
    hitboxTransparency = 0.3,
    hitboxColor = Color3.fromRGB(255, 255, 255),
    outlineColor = Color3.fromRGB(255, 255, 255),
    hitboxEnabled = false,
    streamable = false,
    carSpeed = 80,
    noClip = false
}

-- Store original sizes
local originalSizes = {}
local selectionBoxes = {}

-- Rapid Fire Variables
local rapidFireEnabled = false
local rapidFireRate = 0.05
local isFiring = false
local lastRapidShot = 0

-- Notification
local Notifier = Compkiller.newNotify();

-- Loading UI
Compkiller:Loader("rbxassetid://120245531583106", 1.5).yield();

-- Creating Window
local MenuKey = "LeftAlt";

local Window = Compkiller.new({
	Name = "AntiV4",
	Keybind = MenuKey,
	Logo = "rbxassetid://120245531583106",
	Scale = Compkiller.Scale.Window,
	TextSize = 15,
});

-- Watermark
local Watermark = Window:Watermark();

Watermark:AddText({
	Icon = "user",
	Text = "Hi, " .. LocalPlayer.Name .. "! Welcome to AntiV4.",
});

-- Fly function variables (define BEFORE UI)
local flyEnabled = false
local flySpeed = 50
local flying = false
local speed = 10
local baseSpeed = 10 -- Base speed from slider
local keys = {a=false, d=false, w=false, s=false}
local e1, e2
local Core

local function setupCore()
    if workspace:FindFirstChild("Core") then
        workspace.Core:Destroy()
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("LowerTorso") then
        return false
    end
    
    Core = Instance.new("Part")
    Core.Name = "Core"
    Core.Size = Vector3.new(0.05, 0.05, 0.05)
    Core.Transparency = 1
    Core.CanCollide = false
    Core.Parent = workspace
    
    local Weld = Instance.new("Weld", Core)
    Weld.Part0 = Core
    Weld.Part1 = LocalPlayer.Character.LowerTorso
    Weld.C0 = CFrame.new(0, 0, 0)
    
    return true
end

local function startFly()
    if not setupCore() then return end
    
    workspace:WaitForChild("Core")
    local torso = workspace.Core
    
    local pos = Instance.new("BodyPosition", torso)
    local gyro = Instance.new("BodyGyro", torso)
    pos.Name = "EPIXPOS"
    pos.maxForce = Vector3.new(math.huge, math.huge, math.huge)
    pos.position = torso.Position
    gyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    gyro.cframe = torso.CFrame
    
    spawn(function()
        repeat
            wait()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then break end
            LocalPlayer.Character.Humanoid.PlatformStand = true
            local new = gyro.cframe - gyro.cframe.p + pos.position
            
            -- Use baseSpeed from slider
            speed = baseSpeed
            
            if keys.w then
                new = new + workspace.CurrentCamera.CoordinateFrame.lookVector * speed
            end
            if keys.s then
                new = new - workspace.CurrentCamera.CoordinateFrame.lookVector * speed
            end
            if keys.d then
                new = new * CFrame.new(speed, 0, 0)
            end
            if keys.a then
                new = new * CFrame.new(-speed, 0, 0)
            end
            
            pos.position = new.p
            if keys.w then
                gyro.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad(speed*0), 0, 0)
            elseif keys.s then
                gyro.cframe = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(math.rad(speed*0), 0, 0)
            else
                gyro.cframe = workspace.CurrentCamera.CoordinateFrame
            end
        until flying == false
        
        if gyro then gyro:Destroy() end
        if pos then pos:Destroy() end
        flying = false
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end)
end

local function stopFly()
    flying = false
    if Core then
        Core:Destroy()
        Core = nil
    end
end

-- Setup mouse controls
local mouse = LocalPlayer:GetMouse()

e1 = mouse.KeyDown:connect(function(key)
    if key == "w" then
        keys.w = true
    elseif key == "s" then
        keys.s = true
    elseif key == "a" then
        keys.a = true
    elseif key == "d" then
        keys.d = true
    elseif key == "c" then
        if flying == true then
            flying = false
            flyEnabled = false
            stopFly()
        else
            flying = true
            flyEnabled = true
            startFly()
        end
    end
end)

e2 = mouse.KeyUp:connect(function(key)
    if key == "w" then
        keys.w = false
    elseif key == "s" then
        keys.s = false
    elseif key == "a" then
        keys.a = false
    elseif key == "d" then
        keys.d = false
    end
end)

-- Creating Tab Category
Window:DrawCategory({
	Name = "Main"
});

-- Creating Main Tab
local MainTab = Window:DrawTab({
	Name = "Main",
	Icon = "target",
	Type = "Double",
	EnableScrolling = true
});

-- Creating Player Tab
local PlayerTab = Window:DrawTab({
	Name = "Player",
	Icon = "user",
	Type = "Double",
	EnableScrolling = true
});

-- Creating Aim Tab
local AimTab = Window:DrawTab({
	Name = "Aim",
	Icon = "crosshair",
	Type = "Double",
	EnableScrolling = true
});

-- Creating Legit Tab
local LegitTab = Window:DrawTab({
	Name = "Legit",
	Icon = "activity",
	Type = "Double",
	EnableScrolling = true
});

-- ===== AIM TAB CONTENT =====
-- Kill Aura Section
local KillAuraSection = AimTab:DrawSection({
	Name = "Kill Aura",
	Position = 'left'
});

local killAuraEnabled = false
local killAuraDistance = 200
local shootDelay = 0
local killAuraMode = ""
local prioritizeLowHealth = false
local onlyTargetMoving = false
local targetArmedPlayers = false

-- Track current target (declare here so toggle can access)
local CurrentTarget = nil
local TargetHighlight = nil

KillAuraSection:AddToggle({
	Name = "Kill Aura",
	Flag = "KillAura",
	Default = false,
	Callback = function(v) 
		killAuraEnabled = v
		if not v then
			-- Clear target and highlight when disabled
			CurrentTarget = nil
			if TargetHighlight then
				TargetHighlight:Destroy()
				TargetHighlight = nil
			end
		end
	end,
});

KillAuraSection:AddSlider({
	Name = "Kill Aura Distance",
	Min = 0,
	Max = 500,
	Default = 200,
	Round = 0,
	Flag = "KillAuraDistance",
	Callback = function(v) killAuraDistance = v end
});

KillAuraSection:AddSlider({
	Name = "Shoot Delay",
	Min = 0,
	Max = 100,
	Default = 0,
	Round = 0,
	Flag = "ShootDelay",
	Callback = function(v) shootDelay = v end
});

KillAuraSection:AddDropdown({
	Name = "kill aura Mode (Optional)",
	Default = "Default",
	Values = {"Default", "Prioritize Low Health", "Only Target Moving Players", "Target Armed Players"},
	Callback = function(v) 
		killAuraMode = v
		
		-- Reset all options
		prioritizeLowHealth = false
		onlyTargetMoving = false
		targetArmedPlayers = false
		
		-- Apply selected mode
		if v == "Prioritize Low Health" then
			prioritizeLowHealth = true
		elseif v == "Only Target Moving Players" then
			onlyTargetMoving = true
		elseif v == "Target Armed Players" then
			targetArmedPlayers = true
		end
	end
})

KillAuraSection:AddDropdown({
	Name = "Camera View",
	Default = "No",
	Values = {"Yes", "No"},
	Callback = function(v)
		if v == "Yes" then
			-- Use Aimbot (Camera-based aiming)
			getgenv().KillAuraUseAimbot = true
		else
			-- Use Silent Aim (Hook-based aiming)
			getgenv().KillAuraUseAimbot = false
		end
	end
})

-- Add prediction slider
KillAuraSection:AddSlider({
	Name = "Prediction",
	Min = 0,
	Max = 200,
	Default = 165,
	Round = 1,
	Flag = "KillAuraPrediction",
	Callback = function(v) 
		getgenv().KillAuraPrediction = v / 1000 -- Convert to decimal (165 = 0.165)
	end
});

-- Tools Section
local ToolsSection = AimTab:DrawSection({
	Name = "Section",
	Position = 'left'
});

-- Lock Tool Variables
local lockedTarget = nil
local lockHighlight = nil

-- Rapid Fire Variables
local rapidFireActive = false

-- HyperFire Variables
local hyperFireActive = false

-- Lock Target Auto-Aim System
local lockAimConnection = nil

local function setupLockAim()
	if lockAimConnection then
		lockAimConnection:Disconnect()
	end
	
	lockAimConnection = RunService.RenderStepped:Connect(function()
		if lockedTarget and lockedTarget.Character then
			local targetChar = lockedTarget.Character
			local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
			local targetHead = targetChar:FindFirstChild("Head")
			
			if targetHRP and targetHead then
				-- Check if player is holding a gun
				local character = LocalPlayer.Character
				if character then
					local currentTool = character:FindFirstChildOfClass("Tool")
					
					if currentTool and currentTool.Name ~= "LockAim" then
						-- Check if it's a gun (has Ammo or gun keywords)
						local isGun = false
						local toolName = currentTool.Name:lower()
						local gunKeywords = {
							"gun", "rifle", "pistol", "shotgun", "smg", "ak", "ar",
							"glock", "deagle", "sniper", "uzi", "mac", "revolver"
						}
						
						for _, keyword in pairs(gunKeywords) do
							if toolName:find(keyword) then
								isGun = true
								break
							end
						end
						
						if not isGun and (currentTool:FindFirstChild("Ammo") or currentTool:FindFirstChild("MaxAmmo")) then
							isGun = true
						end
						
						-- If holding a gun, aim camera at locked target
						if isGun then
							Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
						end
					end
				end
			else
				-- Target invalid, unlock
				if lockedTarget then
					lockedTarget = nil
					if lockHighlight then
						lockHighlight:Destroy()
						lockHighlight = nil
					end
				end
			end
		end
	end)
end

setupLockAim()

-- Rapid Fire System
local function getCurrentTool()
	local character = LocalPlayer.Character
	if not character then return nil end
	
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local rapidFireConnection = nil
local function setupRapidFire()
	if rapidFireConnection then
		rapidFireConnection:Disconnect()
		rapidFireConnection = nil
	end
	
	if not rapidFireActive then return end
	
	local lastShot = 0
	rapidFireConnection = RunService.RenderStepped:Connect(function()
		if not rapidFireActive then
			if rapidFireConnection then
				rapidFireConnection:Disconnect()
				rapidFireConnection = nil
			end
			return
		end
		
		local currentTime = tick()
		if currentTime - lastShot < rapidFireRate then return end
		
		local tool = getCurrentTool()
		if not tool then return end
		
		-- Check if mouse is held down
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
		
		lastShot = currentTime
		
		-- Fire the weapon
		pcall(function()
			local remoteEvent = tool:FindFirstChild("RemoteEvent", true)
			if remoteEvent and remoteEvent:IsA("RemoteEvent") then
				remoteEvent:FireServer("Shoot")
			end
		end)
		
		pcall(function()
			tool:Activate()
		end)
	end)
end

-- HyperFire System (EXTREME SPEED - INSTANT MAX SPEED)
local hyperFireConnection = nil
local hyperFireConnection2 = nil
local function setupHyperFire()
	if hyperFireConnection then
		hyperFireConnection:Disconnect()
		hyperFireConnection = nil
	end
	if hyperFireConnection2 then
		hyperFireConnection2:Disconnect()
		hyperFireConnection2 = nil
	end
	
	if not hyperFireActive then return end
	
	-- Connection 1: RenderStepped (runs every frame ~60 FPS)
	hyperFireConnection = RunService.RenderStepped:Connect(function()
		if not hyperFireActive then
			if hyperFireConnection then
				hyperFireConnection:Disconnect()
				hyperFireConnection = nil
			end
			if hyperFireConnection2 then
				hyperFireConnection2:Disconnect()
				hyperFireConnection2 = nil
			end
			return
		end
		
		local tool = getCurrentTool()
		if not tool then return end
		
		-- Check if mouse is held down
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
		
		-- SPAM FIRE - 10 times per frame for instant max speed
		for i = 1, 10 do
			pcall(function()
				local remoteEvent = tool:FindFirstChild("RemoteEvent", true)
				if remoteEvent and remoteEvent:IsA("RemoteEvent") then
					remoteEvent:FireServer("Shoot")
				end
			end)
			
			pcall(function()
				tool:Activate()
			end)
		end
	end)
	
	-- Connection 2: Heartbeat for even MORE spam
	hyperFireConnection2 = RunService.Heartbeat:Connect(function()
		if not hyperFireActive then return end
		
		local tool = getCurrentTool()
		if not tool then return end
		
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
		
		-- Additional spam on Heartbeat
		for i = 1, 5 do
			pcall(function()
				local remoteEvent = tool:FindFirstChild("RemoteEvent", true)
				if remoteEvent and remoteEvent:IsA("RemoteEvent") then
					remoteEvent:FireServer("Shoot")
				end
			end)
		end
	end)
end

ToolsSection:AddButton({
	Name = "Lock Tool",
	Callback = function()
		local character = LocalPlayer.Character
		local backpack = LocalPlayer.Backpack
		
		if not character or not backpack then
			Notifier.new({
				Title = "Lock Tool",
				Content = "Character not found!",
				Duration = 2
			});
			return
		end
		
		-- Check if LockAim tool already exists
		if backpack:FindFirstChild("LockAim") or character:FindFirstChild("LockAim") then
			Notifier.new({
				Title = "Lock Tool",
				Content = "LockAim already exists!",
				Duration = 2
			});
			return
		end
		
		-- Create LockAim tool
		local lockTool = Instance.new("Tool")
		lockTool.Name = "LockAim"
		lockTool.RequiresHandle = false
		lockTool.CanBeDropped = false
		
		-- Create handle for the tool (optional visual)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1)
		handle.Transparency = 1
		handle.CanCollide = false
		handle.Parent = lockTool
		
		-- Tool activation (left click)
		lockTool.Activated:Connect(function()
			local mouse = LocalPlayer:GetMouse()
			local target = mouse.Target
			
			if target then
				local clickedCharacter = target.Parent
				local clickedPlayer = Players:GetPlayerFromCharacter(clickedCharacter)
				
				if clickedPlayer and clickedPlayer ~= LocalPlayer then
					-- Lock onto this player
					lockedTarget = clickedPlayer
					
					-- Remove old highlight if exists
					if lockHighlight then
						lockHighlight:Destroy()
					end
					
					-- Create new highlight
					lockHighlight = Instance.new("Highlight")
					lockHighlight.Name = "LockTargetHighlight"
					lockHighlight.FillColor = Color3.fromRGB(255, 0, 0)
					lockHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
					lockHighlight.FillTransparency = 0.5
					lockHighlight.OutlineTransparency = 0
					lockHighlight.Parent = clickedCharacter
					
					Notifier.new({
						Title = "Lock Tool",
						Content = "Locked onto " .. clickedPlayer.Name,
						Duration = 2
					});
					
					-- Monitor if target leaves or dies
					local humanoid = clickedCharacter:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.Died:Connect(function()
							if lockedTarget == clickedPlayer then
								lockedTarget = nil
								if lockHighlight then
									lockHighlight:Destroy()
									lockHighlight = nil
								end
								Notifier.new({
									Title = "Lock Tool",
									Content = "Target died - unlocked",
									Duration = 2
								});
							end
						end)
					end
				else
					-- Unlock if clicked anywhere else
					lockedTarget = nil
					if lockHighlight then
						lockHighlight:Destroy()
						lockHighlight = nil
					end
					
					Notifier.new({
						Title = "Lock Tool",
						Content = "Unlocked target",
						Duration = 2
					});
				end
			else
				-- Unlock if clicked on nothing
				lockedTarget = nil
				if lockHighlight then
					lockHighlight:Destroy()
					lockHighlight = nil
				end
				
				Notifier.new({
					Title = "Lock Tool",
					Content = "Unlocked target",
					Duration = 2
				});
			end
		end)
		
		-- Cleanup when tool is unequipped
		lockTool.Unequipped:Connect(function()
			-- Keep target locked even when unequipped
		end)
		
		-- Monitor target leaving game
		Players.PlayerRemoving:Connect(function(player)
			if lockedTarget == player then
				lockedTarget = nil
				if lockHighlight then
					lockHighlight:Destroy()
					lockHighlight = nil
				end
			end
		end)
		
		-- Give tool to player
		lockTool.Parent = backpack
		
		Notifier.new({
			Title = "Lock Tool",
			Content = "LockAim tool created! Equip and click on a player to lock.",
			Duration = 3
		});
	end,
})

ToolsSection:AddButton({
	Name = "Multi gun",
	Callback = function()
		local character = LocalPlayer.Character
		local backpack = LocalPlayer.Backpack
		
		if character and backpack then
			local equippedCount = 0
			
			-- Function to check if tool is a gun
			local function isGun(tool)
				if not tool:IsA("Tool") then return false end
				
				local name = tool.Name:lower()
				local gunKeywords = {
					"gun", "rifle", "pistol", "shotgun", "smg", "ak", "ar",
					"glock", "deagle", "sniper", "uzi", "mac", "revolver",
					"carbine", "assault", "dmr", "lmg", "tommy", "draco"
				}
				
				-- Exclude non-gun items
				local excludeKeywords = {
					"money", "cash", "fist", "wallet", "phone", "radio",
					"spray", "bat", "knife", "armor", "vest", "tip", "jar"
				}
				
				-- Check if excluded
				for _, keyword in pairs(excludeKeywords) do
					if name:find(keyword) then
						return false
					end
				end
				
				-- Check if it's a gun
				for _, keyword in pairs(gunKeywords) do
					if name:find(keyword) then
						return true
					end
				end
				
				-- Additional check: guns typically have ammo-related children
				if tool:FindFirstChild("Ammo") or tool:FindFirstChild("MaxAmmo") then
					return true
				end
				
				return false
			end
			
			-- Equip all guns from backpack
			for _, tool in pairs(backpack:GetChildren()) do
				if isGun(tool) then
					tool.Parent = character
					equippedCount = equippedCount + 1
				end
			end
			
			-- Count already equipped guns
			for _, tool in pairs(character:GetChildren()) do
				if isGun(tool) then
					equippedCount = equippedCount + 1
				end
			end
			
			Notifier.new({
				Title = "Multi Gun",
				Content = "Equipped " .. equippedCount .. " gun(s)!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Multi Gun",
				Content = "Character or Backpack not found!",
				Duration = 2
			});
		end
	end,
})

ToolsSection:AddButton({
	Name = "Rapid Fire",
	Callback = function()
		rapidFireActive = not rapidFireActive
		
		if rapidFireActive then
			-- Disable HyperFire if it's active
			if hyperFireActive then
				hyperFireActive = false
				if hyperFireConnection then
					hyperFireConnection:Disconnect()
					hyperFireConnection = nil
				end
			end
			
			setupRapidFire()
			Notifier.new({
				Title = "Rapid Fire",
				Content = "Rapid Fire ON! Hold mouse to shoot.",
				Duration = 2
			});
		else
			if rapidFireConnection then
				rapidFireConnection:Disconnect()
				rapidFireConnection = nil
			end
			Notifier.new({
				Title = "Rapid Fire",
				Content = "Rapid Fire OFF!",
				Duration = 2
			});
		end
	end,
})

ToolsSection:AddButton({
	Name = "HyperFire",
	Callback = function()
		hyperFireActive = not hyperFireActive
		
		if hyperFireActive then
			-- Disable rapid fire if it's active
			if rapidFireActive then
				rapidFireActive = false
				if rapidFireConnection then
					rapidFireConnection:Disconnect()
					rapidFireConnection = nil
				end
			end
			
			setupHyperFire()
			Notifier.new({
				Title = "HyperFire",
				Content = "HyperFire ON! EXTREME SPEED! Hold mouse to obliterate.",
				Duration = 2
			});
		else
			if hyperFireConnection then
				hyperFireConnection:Disconnect()
				hyperFireConnection = nil
			end
			if hyperFireConnection2 then
				hyperFireConnection2:Disconnect()
				hyperFireConnection2 = nil
			end
			Notifier.new({
				Title = "HyperFire",
				Content = "HyperFire OFF!",
				Duration = 2
			});
		end
	end,
})

--[[
	Visuals Section
	
	Features: Hit Sound, Weeb Mode, Bullet Tracers
	
	Status: COMING SOON
]]

-- Visuals Section Left
local VisualsLeftSection = AimTab:DrawSection({
	Name = "Section",
	Position = 'left'
});

local hitSound = ""
local weebMode = "Weeb"
local bulletTracers = false
local tracerColor = Color3.fromRGB(255, 255, 255)

VisualsLeftSection:AddParagraph({
	Title = "COMING SOON ",
	Content = "Currently under development."
})

VisualsLeftSection:AddTextBox({
	Name = "Hit Sound",
	Default = "",
	Placeholder = "Sound ID...",
	Callback = function(v) hitSound = v end
})

VisualsLeftSection:AddDropdown({
	Name = "Weeb",
	Default = "Weeb",
	Values = {"Weeb", "Normal", "Custom"},
	Callback = function(v) weebMode = v end
})

VisualsLeftSection:AddToggle({
	Name = "Bullet Tracers",
	Flag = "BulletTracers",
	Default = false,
	Callback = function(v) bulletTracers = v end,
});

VisualsLeftSection:AddColorPicker({
	Name = "Tracer color",
	Default = tracerColor,
	Flag = "TracerColor",
	Callback = function(v) tracerColor = v end
})

-- Silent Aim Section Right
local SilentAimSection = AimTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

-- Silent Aim Variables
local legitSilentAim = false
local silentAimHitPart = "Head"
local silentAimMaxDistance = 200
local silentAimCameraView = false
local silentAimAllowKnocked = false
local fov = 200
local showFOV = false
local fovPosition = "Mouse" -- "Mouse" or "Center"

-- Target Highlight
local currentSilentTarget = nil
local targetHighlight = nil
local highlightRemoveTime = 0

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 50
FOVCircle.Radius = fov
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.ZIndex = 999
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

-- Silent Aim: Get Closest Player Function
local function GetClosestPlayerSilentAim()
	if not legitSilentAim then return nil end
	
	local ClosestPlayer = nil
	local ShortestDistance = fov
	
	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		local character = player.Character
		if not character then continue end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end
		
		-- Check if knocked
		if not silentAimAllowKnocked then
			local bodyEffects = character:FindFirstChild("BodyEffects")
			if bodyEffects then
				local ko = bodyEffects:FindFirstChild("K.O")
				local dead = bodyEffects:FindFirstChild("Dead")
				if (ko and ko.Value) or (dead and dead.Value) then continue end
			end
		end
		
		local targetPart = character:FindFirstChild(silentAimHitPart)
		if not targetPart then continue end
		
		-- Camera view check
		if silentAimCameraView then
			local _, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			if not onScreen then continue end
		end
		
		-- Distance check
		local distance = (targetPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
		if distance > silentAimMaxDistance then continue end
		
		-- FOV check (distance from mouse or center)
		local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
		if onScreen then
			local mousePos = fovPosition == "Mouse" and Vector2.new(Mouse.X, Mouse.Y) or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
			local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
			
			if screenDistance < ShortestDistance then
				ShortestDistance = screenDistance
				ClosestPlayer = player
			end
		end
	end
	
	return ClosestPlayer
end

-- Silent Aim Toggle
SilentAimSection:AddToggle({
	Name = "Legit Silent Aim",
	Flag = "LegitSilentAim",
	Default = false,
	Callback = function(v) 
		legitSilentAim = v
		
		-- Remove highlight when toggled off
		if not v and targetHighlight then
			targetHighlight:Destroy()
			targetHighlight = nil
			currentSilentTarget = nil
		end
	end,
});

-- Hit Part Dropdown
SilentAimSection:AddDropdown({
	Name = "Hit Part",
	Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
	Default = "Head",
	Flag = "SilentAimHitPart",
	Callback = function(v) silentAimHitPart = v end
})

-- Max Distance Slider
SilentAimSection:AddSlider({
	Name = "Max Distance",
	Min = 50,
	Max = 1000,
	Default = 200,
	Round = 10,
	Flag = "SilentAimMaxDistance",
	Callback = function(v) silentAimMaxDistance = v end
});

-- FOV Slider
SilentAimSection:AddSlider({
	Name = "FOV Circle Size",
	Min = 50,
	Max = 500,
	Default = 200,
	Round = 10,
	Flag = "FOV",
	Callback = function(v) 
		fov = v
		FOVCircle.Radius = v
	end
});

-- FOV Position Dropdown
SilentAimSection:AddDropdown({
	Name = "FOV Position",
	Values = {"Mouse", "Center"},
	Default = "Mouse",
	Flag = "FOVPosition",
	Callback = function(v) fovPosition = v end
})

-- Show FOV Toggle
SilentAimSection:AddToggle({
	Name = "Show FOV Circle",
	Flag = "ShowFOV",
	Default = false,
	Callback = function(v) 
		showFOV = v
		FOVCircle.Visible = v
	end,
});

-- Camera View Only Toggle
SilentAimSection:AddToggle({
	Name = "Camera View Only",
	Flag = "SilentAimCameraView",
	Default = false,
	Callback = function(v) silentAimCameraView = v end,
});

-- Allow Knocked Toggle
SilentAimSection:AddToggle({
	Name = "Target Knocked Players",
	Flag = "SilentAimAllowKnocked",
	Default = false,
	Callback = function(v) silentAimAllowKnocked = v end,
});

-- Update FOV Circle Position
RunService.RenderStepped:Connect(function()
	if showFOV and FOVCircle then
		FOVCircle.Visible = true
		FOVCircle.Radius = fov
		
		if fovPosition == "Mouse" then
			FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
		else
			FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		end
	else
		FOVCircle.Visible = false
	end
end)

-- Function to highlight target when shooting
local function HighlightTarget(player)
	if not player or not player.Character then return end
	
	-- Remove old highlight
	if targetHighlight then
		targetHighlight:Destroy()
		targetHighlight = nil
	end
	
	-- Create new highlight
	targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "SilentAimTarget"
	targetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
	targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
	targetHighlight.FillTransparency = 0.5
	targetHighlight.OutlineTransparency = 0
	targetHighlight.Parent = player.Character
	
	-- Set time to remove highlight (0.5 seconds)
	highlightRemoveTime = tick() + 0.5
end

-- Update loop to remove highlight after time
RunService.RenderStepped:Connect(function()
	if targetHighlight and tick() >= highlightRemoveTime then
		targetHighlight:Destroy()
		targetHighlight = nil
		currentSilentTarget = nil
	end
end)

-- Cleanup highlight when target leaves
Players.PlayerRemoving:Connect(function(player)
	if currentSilentTarget == player then
		if targetHighlight then
			targetHighlight:Destroy()
			targetHighlight = nil
		end
		currentSilentTarget = nil
	end
end)

-- Combined Hook for Silent Aim (Will be merged with Kill Aura hook later)

-- Combat Section Right
local CombatSection = AimTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

local rageBot = false
local autoStomp = false
local showStatus = false
local showDot = false

-- RageBot Variables
local rageBotTarget = nil
local rageBotHighlight = nil
local rageBotTracer = Drawing.new("Line")
rageBotTracer.Visible = false
rageBotTracer.Color = Color3.fromRGB(255, 0, 0)
rageBotTracer.Thickness = 2
rageBotTracer.Transparency = 1
local rageBotAutoShoot = true
local isRageBotHolding = false

-- Automatic weapons that should hold instead of click
local automaticWeapons = {
    ["[SMG]"] = true,
    ["[AR]"] = true,
    ["[P90]"] = true,
    ["[SilencerAR]"] = true,
    ["[AK47]"] = true,
    ["[Flamethrower]"] = true,
    ["[AUG]"] = true,
    ["[LMG]"] = true,
    ["[Drum-Shotgun]"] = true
}

-- Function to check if weapon is automatic
local function isAutomaticWeapon(tool)
	if not tool then return false end
	
	for weaponName, _ in pairs(automaticWeapons) do
		if tool.Name == weaponName then
			return true
		end
	end
	
	return false
end

-- Function to check if target is knocked
local function IsTargetKnocked(player)
	if not player or not player.Character then return false end
	
	local bodyEffects = player.Character:FindFirstChild("BodyEffects")
	if not bodyEffects then return false end
	
	local ko = bodyEffects:FindFirstChild("K.O")
	return ko and ko.Value == true
end

-- Function to select RageBot target
local function SelectRageBotTarget()
	if not rageBot then return end
	
	local mouseTarget = Mouse.Target
	if not mouseTarget then return end
	
	local clickedCharacter = mouseTarget.Parent
	local clickedPlayer = Players:GetPlayerFromCharacter(clickedCharacter)
	
	if clickedPlayer and clickedPlayer ~= LocalPlayer then
		-- Check if already targeting this player
		if rageBotTarget == clickedPlayer then
			return -- Don't notify again
		end
		
		-- Set new target
		rageBotTarget = clickedPlayer
		hasStompedTarget = false -- Reset stomp flag for new target
		
		-- Remove old highlight
		if rageBotHighlight then
			rageBotHighlight:Destroy()
			rageBotHighlight = nil
		end
		
		-- Create new highlight
		rageBotHighlight = Instance.new("Highlight")
		rageBotHighlight.Name = "RageBotTarget"
		rageBotHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		rageBotHighlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		rageBotHighlight.FillTransparency = 0.5
		rageBotHighlight.OutlineTransparency = 0
		rageBotHighlight.Parent = clickedCharacter
		
		-- Update status GUI
		if showStatus then
			UpdateStatusGUI()
		end
		
		Notifier.new({
			Title = "RageBot",
			Content = "Locked onto " .. clickedPlayer.Name,
			Duration = 2
		});
	end
end

-- Mouse click detection for target selection
Mouse.Button1Down:Connect(function()
	if rageBot then
		SelectRageBotTarget()
	end
end)

-- RageBot auto-shoot system
local lastRageBotShot = 0
local rageBotShootDelay = 0.1

-- Function to hold trigger for automatic weapons
local function holdRageBotTrigger()
	if isRageBotHolding then return end
	isRageBotHolding = true
	pcall(function() mouse1press() end)
end

-- Function to release trigger
local function releaseRageBotTrigger()
	if not isRageBotHolding then return end
	isRageBotHolding = false
	pcall(function() mouse1release() end)
end

-- Function to click for semi-automatic weapons
local function clickRageBotTrigger()
	pcall(function()
		mouse1press()
		task.wait(0.01)
		mouse1release()
	end)
end

RunService.RenderStepped:Connect(function()
	if not rageBot or not rageBotAutoShoot or not rageBotTarget then
		if isRageBotHolding then releaseRageBotTrigger() end
		return
	end
	
	local targetChar = rageBotTarget.Character
	if not targetChar then 
		rageBotTarget = nil
		if rageBotHighlight then rageBotHighlight:Destroy() rageBotHighlight = nil end
		if isRageBotHolding then releaseRageBotTrigger() end
		return 
	end
	
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
	local targetHead = targetChar:FindFirstChild("Head")
	local targetHumanoid = targetChar:FindFirstChild("Humanoid")
	
	if not targetHRP or not targetHead or not targetHumanoid or targetHumanoid.Health <= 0 then
		rageBotTarget = nil
		if rageBotHighlight then rageBotHighlight:Destroy() rageBotHighlight = nil end
		if isRageBotHolding then releaseRageBotTrigger() end
		return
	end
	
	-- Check if target is knocked - STOP shooting
	if IsTargetKnocked(rageBotTarget) then
		if isRageBotHolding then releaseRageBotTrigger() end
		return
	end
	
	-- Check if we have a gun equipped
	local character = LocalPlayer.Character
	if not character then 
		if isRageBotHolding then releaseRageBotTrigger() end
		return 
	end
	
	local currentTool = nil
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") then
			currentTool = child
			break
		end
	end
	
	if not currentTool then 
		if isRageBotHolding then releaseRageBotTrigger() end
		return 
	end
	
	-- Check distance
	local myHRP = character:FindFirstChild("HumanoidRootPart")
	if not myHRP then 
		if isRageBotHolding then releaseRageBotTrigger() end
		return 
	end
	
	local distance = (targetHRP.Position - myHRP.Position).Magnitude
	
	-- Auto shoot when nearby (within 200 studs)
	if distance <= 200 then
		-- Check if weapon is automatic
		if isAutomaticWeapon(currentTool) then
			-- Hold trigger for automatic weapons (SMG, AR, etc.)
			holdRageBotTrigger()
		else
			-- Click for semi-automatic weapons
			local currentTime = tick()
			if currentTime - lastRageBotShot >= rageBotShootDelay then
				lastRageBotShot = currentTime
				clickRageBotTrigger()
			end
		end
	else
		-- Out of range, release trigger
		if isRageBotHolding then releaseRageBotTrigger() end
	end
end)

-- Update tracer visual
RunService.RenderStepped:Connect(function()
	if rageBot and rageBotTarget and rageBotTarget.Character then
		local targetHRP = rageBotTarget.Character:FindFirstChild("HumanoidRootPart")
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		if targetHRP and myHRP then
			local targetPos, targetOnScreen = Camera:WorldToViewportPoint(targetHRP.Position)
			local myPos, myOnScreen = Camera:WorldToViewportPoint(myHRP.Position)
			
			if targetOnScreen and myOnScreen then
				rageBotTracer.From = Vector2.new(myPos.X, myPos.Y)
				rageBotTracer.To = Vector2.new(targetPos.X, targetPos.Y)
				rageBotTracer.Visible = true
			else
				rageBotTracer.Visible = false
			end
		else
			rageBotTracer.Visible = false
		end
	else
		rageBotTracer.Visible = false
	end
end)

-- Cleanup when target leaves
Players.PlayerRemoving:Connect(function(player)
	if rageBotTarget == player then
		rageBotTarget = nil
		if rageBotHighlight then
			rageBotHighlight:Destroy()
			rageBotHighlight = nil
		end
		rageBotTracer.Visible = false
	end
end)

CombatSection:AddToggle({
	Name = "RageBot",
	Flag = "RageBot",
	Default = false,
	Callback = function(v) 
		rageBot = v
		
		-- Cleanup when disabled
		if not v then
			rageBotTarget = nil
			rageBotAutoShoot = false
			hasStompedTarget = false
			
			if rageBotHighlight then
				rageBotHighlight:Destroy()
				rageBotHighlight = nil
			end
			rageBotTracer.Visible = false
			
			-- Reset variables to ensure clean state
			task.wait(0.1)
			rageBotAutoShoot = true
			
			Notifier.new({
				Title = "RageBot",
				Content = "RageBot disabled",
				Duration = 2
			});
		else
			rageBotAutoShoot = true
			hasStompedTarget = false
			
			Notifier.new({
				Title = "RageBot",
				Content = "Click on a player to lock onto them!",
				Duration = 3
			});
		end
	end,
});

-- Auto Stomp System (Only stomps RageBot target)
local hasStompedTarget = false

local function IsPlayerKnocked(player)
	if not player or not player.Character then return false end
	
	local bodyEffects = player.Character:FindFirstChild("BodyEffects")
	if not bodyEffects then return false end
	
	local ko = bodyEffects:FindFirstChild("K.O")
	return ko and ko.Value == true
end

local function StompRageBotTarget()
	if not rageBotTarget or not rageBotTarget.Character then return end
	
	local targetHRP = rageBotTarget.Character:FindFirstChild("HumanoidRootPart")
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	
	if targetHRP and myHRP then
		-- Save original position
		local originalPos = myHRP.CFrame
		
		-- Teleport on top of knocked player
		myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 3, 0)
		
		task.wait(0.1)
		
		-- Fire stomp remote 3 times for reliability
		local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
		if mainEvent then
			for i = 1, 3 do
				mainEvent:FireServer("Stomp")
				task.wait(0.05)
			end
		end
		
		task.wait(0.2)
		
		-- Return to original position
		myHRP.CFrame = originalPos
		
		hasStompedTarget = true
	end
end

-- Monitor RageBot target for knock state
RunService.Heartbeat:Connect(function()
	if autoStomp and rageBotTarget and rageBotTarget.Character then
		if IsPlayerKnocked(rageBotTarget) and not hasStompedTarget then
			StompRageBotTarget()
		elseif not IsPlayerKnocked(rageBotTarget) then
			hasStompedTarget = false -- Reset when they get revived or respawn
		end
	end
end)

CombatSection:AddToggle({
	Name = "Auto Stomp",
	Flag = "AutoStomp",
	Default = false,
	Callback = function(v) 
		autoStomp = v
		
		if v then
			Notifier.new({
				Title = "Auto Stomp",
				Content = "Auto Stomp enabled! Will stomp RageBot target when knocked.",
				Duration = 3
			});
		else
			Notifier.new({
				Title = "Auto Stomp",
				Content = "Auto Stomp disabled!",
				Duration = 2
			});
			hasStompedTarget = false
		end
	end,
});

-- Target Status GUI
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local StatusGui = Instance.new("ScreenGui")
StatusGui.Name = "RageBotStatus"
StatusGui.ResetOnSpawn = false
StatusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
StatusGui.Parent = PlayerGui

local StatusFrame = Instance.new("Frame")
StatusFrame.Name = "StatusFrame"
StatusFrame.Size = UDim2.new(0, 200, 0, 80)
StatusFrame.Position = UDim2.new(1, -220, 0, 100)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusFrame.BorderSizePixel = 2
StatusFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
StatusFrame.Visible = false
StatusFrame.Parent = StatusGui

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusFrame

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Name = "Avatar"
AvatarImage.Size = UDim2.new(0, 60, 0, 60)
AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AvatarImage.BorderSizePixel = 1
AvatarImage.BorderColor3 = Color3.fromRGB(255, 0, 0)
AvatarImage.Image = ""
AvatarImage.Parent = StatusFrame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 8)
AvatarCorner.Parent = AvatarImage

local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Name = "Username"
UsernameLabel.Size = UDim2.new(0, 115, 0, 30)
UsernameLabel.Position = UDim2.new(0, 75, 0, 15)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = "No Target"
UsernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameLabel.TextScaled = true
UsernameLabel.Font = Enum.Font.GothamBold
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.Parent = StatusFrame

local UsernameConstraint = Instance.new("UITextSizeConstraint")
UsernameConstraint.MaxTextSize = 16
UsernameConstraint.MinTextSize = 10
UsernameConstraint.Parent = UsernameLabel

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(0, 115, 0, 25)
StatusLabel.Position = UDim2.new(0, 75, 0, 45)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

-- Function to update status GUI
local function UpdateStatusGUI()
	if not showStatus then
		StatusFrame.Visible = false
		return
	end
	
	if rageBotTarget and rageBotTarget.Character then
		StatusFrame.Visible = true
		
		-- Update avatar
		local userId = rageBotTarget.UserId
		AvatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=60&height=60&format=png"
		
		-- Update username
		UsernameLabel.Text = rageBotTarget.Name
		
		-- Update status
		local targetHumanoid = rageBotTarget.Character:FindFirstChild("Humanoid")
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local targetHRP = rageBotTarget.Character:FindFirstChild("HumanoidRootPart")
		
		if targetHumanoid and myHRP and targetHRP then
			local distance = math.floor((targetHRP.Position - myHRP.Position).Magnitude)
			local health = math.floor(targetHumanoid.Health)
			
			if IsTargetKnocked(rageBotTarget) then
				StatusLabel.Text = "Knocked | " .. distance .. " studs"
				StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
			else
				StatusLabel.Text = "HP: " .. health .. " | " .. distance .. " studs"
				StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			end
		else
			StatusLabel.Text = "Lost Target"
			StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end
	else
		StatusFrame.Visible = true
		AvatarImage.Image = ""
		UsernameLabel.Text = "No Target"
		StatusLabel.Text = "Click a player!"
		StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

-- Update status GUI every frame
RunService.RenderStepped:Connect(function()
	if showStatus then
		UpdateStatusGUI()
	end
end)

CombatSection:AddToggle({
	Name = "Show Status",
	Flag = "ShowStatus",
	Default = false,
	Callback = function(v) 
		showStatus = v
		StatusFrame.Visible = v
		if v then
			UpdateStatusGUI()
		end
	end,
});

CombatSection:AddToggle({
	Name = "Show Dot",
	Flag = "ShowDot",
	Default = false,
	Callback = function(v) showDot = v end,
});

-- Defense Section Right
local DefenseSection = AimTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

local autoShootDamager = false
local defenseMode = false
local noRecoil = false

DefenseSection:AddToggle({
	Name = "Auto shoot damager",
	Flag = "AutoShootDamager",
	Default = false,
	Callback = function(v) autoShootDamager = v end,
});

DefenseSection:AddToggle({
	Name = "Defense Mode",
	Flag = "DefenseMode",
	Default = false,
	Callback = function(v) defenseMode = v end,
});

DefenseSection:AddToggle({
	Name = "No Recoil",
	Flag = "NoRecoil",
	Default = false,
	Callback = function(v) noRecoil = v end,
});

-- ===== LEGIT TAB CONTENT =====

-- Legit Section Left
local LegitLeftSection = LegitTab:DrawSection({
	Name = "Section",
	Position = 'left'
});

-- Camlock Variables
local camlock = false
local camlockHighlight = false
local camlockTracer = false
local camlockHealthDisplay = false
local camlockTarget = nil
local camlockHighlightObj = nil
local camlockTracerObj = Drawing.new("Line")
camlockTracerObj.Visible = false
camlockTracerObj.Color = Color3.fromRGB(255, 255, 255)
camlockTracerObj.Thickness = 2
camlockTracerObj.Transparency = 1

local camlockHealthText = Drawing.new("Text")
camlockHealthText.Visible = false
camlockHealthText.Size = 16
camlockHealthText.Center = true
camlockHealthText.Outline = true
camlockHealthText.Color = Color3.fromRGB(255, 255, 255)
camlockHealthText.Text = ""

-- Function to get closest player to mouse
local function GetClosestPlayerToMouse()
	local closestPlayer = nil
	local shortestDistance = math.huge
	
	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		local character = player.Character
		if not character then continue end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		
		local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		if onScreen then
			local mousePos = Vector2.new(Mouse.X, Mouse.Y)
			local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
			
			if distance < shortestDistance then
				shortestDistance = distance
				closestPlayer = player
			end
		end
	end
	
	return closestPlayer
end

-- Camlock toggle with X key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.X and camlock then
		if camlockTarget then
			-- Unlock
			camlockTarget = nil
			if camlockHighlightObj then
				camlockHighlightObj:Destroy()
				camlockHighlightObj = nil
			end
		else
			-- Lock onto closest player
			local target = GetClosestPlayerToMouse()
			if target then
				camlockTarget = target
				
				-- Create highlight if enabled
				if camlockHighlight and target.Character then
					camlockHighlightObj = Instance.new("Highlight")
					camlockHighlightObj.Name = "CamlockHighlight"
					camlockHighlightObj.FillColor = Color3.fromRGB(255, 255, 0)
					camlockHighlightObj.OutlineColor = Color3.fromRGB(255, 255, 0)
					camlockHighlightObj.FillTransparency = 0.5
					camlockHighlightObj.OutlineTransparency = 0
					camlockHighlightObj.Parent = target.Character
				end
			end
		end
	end
end)

-- Camlock camera tracking
RunService.RenderStepped:Connect(function()
	if camlock and camlockTarget and camlockTarget.Character then
		local targetHRP = camlockTarget.Character:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = camlockTarget.Character:FindFirstChild("Humanoid")
		
		if not targetHRP or not targetHumanoid or targetHumanoid.Health <= 0 then
			-- Target lost, unlock
			camlockTarget = nil
			if camlockHighlightObj then
				camlockHighlightObj:Destroy()
				camlockHighlightObj = nil
			end
			return
		end
		
		-- Aim camera at target
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHRP.Position)
		
		-- Update tracer
		if camlockTracer then
			local targetPos, onScreen = Camera:WorldToViewportPoint(targetHRP.Position)
			if onScreen then
				camlockTracerObj.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				camlockTracerObj.To = Vector2.new(targetPos.X, targetPos.Y)
				camlockTracerObj.Visible = true
			else
				camlockTracerObj.Visible = false
			end
		else
			camlockTracerObj.Visible = false
		end
		
		-- Update health display
		if camlockHealthDisplay then
			local targetPos, onScreen = Camera:WorldToViewportPoint(targetHRP.Position)
			if onScreen then
				local health = math.floor(targetHumanoid.Health)
				camlockHealthText.Position = Vector2.new(targetPos.X, targetPos.Y - 50)
				camlockHealthText.Text = "HP: " .. health
				camlockHealthText.Color = Color3.fromRGB(0, 255, 0)
				camlockHealthText.Visible = true
			else
				camlockHealthText.Visible = false
			end
		else
			camlockHealthText.Visible = false
		end
	else
		camlockTracerObj.Visible = false
		camlockHealthText.Visible = false
	end
end)

-- Cleanup when target leaves
Players.PlayerRemoving:Connect(function(player)
	if camlockTarget == player then
		camlockTarget = nil
		if camlockHighlightObj then
			camlockHighlightObj:Destroy()
			camlockHighlightObj = nil
		end
		camlockTracerObj.Visible = false
		camlockHealthText.Visible = false
	end
end)

LegitLeftSection:AddToggle({
	Name = "Camlock (X)",
	Flag = "Camlock",
	Default = false,
	Callback = function(v) 
		camlock = v
		
		-- Cleanup when disabled
		if not v then
			camlockTarget = nil
			if camlockHighlightObj then
				camlockHighlightObj:Destroy()
				camlockHighlightObj = nil
			end
			camlockTracerObj.Visible = false
			camlockHealthText.Visible = false
		end
	end,
});

LegitLeftSection:AddToggle({
	Name = "Highlight",
	Flag = "CamlockHighlight",
	Default = false,
	Callback = function(v) 
		camlockHighlight = v
		
		-- Create or remove highlight based on toggle
		if v and camlockTarget and camlockTarget.Character and not camlockHighlightObj then
			camlockHighlightObj = Instance.new("Highlight")
			camlockHighlightObj.Name = "CamlockHighlight"
			camlockHighlightObj.FillColor = Color3.fromRGB(255, 255, 0)
			camlockHighlightObj.OutlineColor = Color3.fromRGB(255, 255, 0)
			camlockHighlightObj.FillTransparency = 0.5
			camlockHighlightObj.OutlineTransparency = 0
			camlockHighlightObj.Parent = camlockTarget.Character
		elseif not v and camlockHighlightObj then
			camlockHighlightObj:Destroy()
			camlockHighlightObj = nil
		end
	end,
});

LegitLeftSection:AddToggle({
	Name = "Tracer",
	Flag = "CamlockTracer",
	Default = false,
	Callback = function(v) 
		camlockTracer = v
		if not v then
			camlockTracerObj.Visible = false
		end
	end,
});

LegitLeftSection:AddToggle({
	Name = "Health Display",
	Flag = "CamlockHealthDisplay",
	Default = false,
	Callback = function(v) 
		camlockHealthDisplay = v
		if not v then
			camlockHealthText.Visible = false
		end
	end,
});

-- Legit Section Right
local LegitRightSection = LegitTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

-- TriggerBot Variables
local triggerBot = false
local lastTriggerTime = 0
local triggerCooldown = 0
local isHoldingTrigger = false

-- Function to check if target is enemy
local function isTriggerEnemy(target)
	if not target then return false end
	
	local player = Players:GetPlayerFromCharacter(target.Parent)
	if not player then return false end
	if player == LocalPlayer then return false end
	
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	return true
end

-- Function to get mouse target
local function getTriggerMouseTarget()
	local target = Mouse.Target
	if not target then return nil end
	
	-- Check if it's a player part
	if target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") then
		return target
	end
	
	return nil
end

-- Function to check if target is visible
local function isTriggerTargetVisible(target)
	if not target then return false end
	
	local character = LocalPlayer.Character
	if not character then return false end
	
	local head = character:FindFirstChild("Head")
	if not head then return false end
	
	-- Create raycast parameters
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character, workspace.Ignored}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true
	
	-- Get target position
	local targetPos = target.Position
	local origin = head.Position
	local direction = (targetPos - origin)
	
	-- Perform raycast
	local rayResult = workspace:Raycast(origin, direction, rayParams)
	
	-- Check if we hit the target or nothing (clear shot)
	if not rayResult then
		return true
	end
	
	-- Check if we hit the target player
	if rayResult.Instance then
		local hitParent = rayResult.Instance.Parent
		if hitParent and hitParent:FindFirstChildOfClass("Humanoid") then
			if rayResult.Instance == target or hitParent == target.Parent then
				return true
			end
		end
	end
	
	return false
end

-- Function to hold trigger (for automatic weapons)
local function holdTriggerBot()
	if isHoldingTrigger then return end
	
	isHoldingTrigger = true
	
	pcall(function()
		mouse1press()
	end)
end

-- Function to release trigger
local function releaseTriggerBot()
	if not isHoldingTrigger then return end
	
	isHoldingTrigger = false
	
	pcall(function()
		mouse1release()
	end)
end

-- Function to simulate click (for semi-automatic weapons)
local function triggerClick()
	local currentTime = tick()
	if currentTime - lastTriggerTime < triggerCooldown then
		return
	end
	lastTriggerTime = currentTime
	
	pcall(function()
		mouse1press()
		task.wait(0.01)
		mouse1release()
	end)
end

-- Triggerbot loop
RunService.RenderStepped:Connect(function()
	if not triggerBot then
		-- Release trigger if disabled
		if isHoldingTrigger then
			releaseTriggerBot()
		end
		return
	end
	
	-- Check if player has a gun equipped
	local character = LocalPlayer.Character
	if not character then
		if isHoldingTrigger then
			releaseTriggerBot()
		end
		return
	end
	
	local currentTool = nil
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") then
			currentTool = child
			break
		end
	end
	
	if not currentTool then
		-- Release trigger if no tool
		if isHoldingTrigger then
			releaseTriggerBot()
		end
		return
	end
	
	local target = getTriggerMouseTarget()
	
	-- Check if we should shoot
	local canShoot = false
	if target and isTriggerEnemy(target) then
		canShoot = isTriggerTargetVisible(target)
	end
	
	if canShoot then
		-- Check if weapon is automatic
		if isAutomaticWeapon(currentTool) then
			-- Hold trigger for automatic weapons
			holdTriggerBot()
		else
			-- Click for semi-automatic weapons
			triggerClick()
		end
	else
		-- No valid target, release trigger if holding
		if isHoldingTrigger then
			releaseTriggerBot()
		end
	end
end)

-- Keybind T to toggle triggerbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.T then
		triggerBot = not triggerBot
		
		if not triggerBot and isHoldingTrigger then
			releaseTriggerBot()
		end
	end
end)

LegitRightSection:AddToggle({
	Name = "TriggerBot (T)",
	Flag = "TriggerBot",
	Default = false,
	Callback = function(v) 
		triggerBot = v
		
		-- Release trigger when disabled
		if not v and isHoldingTrigger then
			releaseTriggerBot()
		end
	end,
});

-- ===== KILL AURA IMPLEMENTATION (Silent Aim & Aimbot with Prediction) =====

-- Target lock time tracking
local TargetLockTime = 0

local function GetClosestPlayer()
	local ClosestDistance = killAuraDistance
	local ClosestPlayer = nil
	local LowestHealth = math.huge
	
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local MyPosition = LocalPlayer.Character.HumanoidRootPart.Position
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local Character = player.Character
			local Humanoid = Character:FindFirstChild("Humanoid")
			local RootPart = Character:FindFirstChild("HumanoidRootPart")
			
			if Humanoid and Humanoid.Health > 0 and RootPart then
				-- Check if knocked
				local BodyEffects = Character:FindFirstChild("BodyEffects")
				if BodyEffects then
					local KO = BodyEffects:FindFirstChild("K.O")
					if KO and KO.Value then
						continue
					end
				end
				
				-- Only Target Moving Players check
				if onlyTargetMoving then
					local Velocity = RootPart.Velocity.Magnitude
					if Velocity < 1 then -- Player is standing still
						continue
					end
				end
				
				-- Target Armed Players check
				if targetArmedPlayers then
					local HasWeapon = false
					for _, child in pairs(Character:GetChildren()) do
						if child:IsA("Tool") then
							HasWeapon = true
							break
						end
					end
					if not HasWeapon then
						continue
					end
				end
				
				-- Calculate distance from player
				local Distance = (RootPart.Position - MyPosition).Magnitude
				
				if Distance <= killAuraDistance then
					-- Prioritize Low Health
					if prioritizeLowHealth then
						if Humanoid.Health < LowestHealth then
							LowestHealth = Humanoid.Health
							ClosestPlayer = player
							ClosestDistance = Distance
						end
					else
						-- Normal closest distance targeting
						if Distance < ClosestDistance then
							ClosestDistance = Distance
							ClosestPlayer = player
						end
					end
				end
			end
		end
	end
	
	return ClosestPlayer, ClosestDistance
end

-- Gun detection
local CurrentGun = nil
local GunList = {
	"[Shotgun]",
	"[Drum-Shotgun]",
	"[Rifle]",
	"[TacticalShotgun]",
	"[AR]",
	"[AUG]",
	"[AK47]",
	"[LMG]",
	"[Double-Barrel SG]",
	"[SilencerAR]",
	"[Revolver]",
	"[Flintlock]"
}

-- Check if already holding a gun
local function CheckForGun()
	-- Only check character (don't auto-equip)
	for _, child in pairs(LocalPlayer.Character:GetChildren()) do
		if child:IsA("Tool") then
			for _, gunName in pairs(GunList) do
				if child.Name == gunName then
					CurrentGun = child
					return
				end
			end
		end
	end
end

-- Function to create/update highlight
local function UpdateTargetHighlight(target)
	-- Remove old highlight
	if TargetHighlight then
		TargetHighlight:Destroy()
		TargetHighlight = nil
	end
	
	-- Create new highlight if target exists
	if target and target.Character then
		TargetHighlight = Instance.new("Highlight")
		TargetHighlight.Parent = target.Character
		TargetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		TargetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		TargetHighlight.FillTransparency = 0.5
		TargetHighlight.OutlineTransparency = 0
	end
end

-- Detect when gun is equipped
LocalPlayer.Character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		for _, gunName in pairs(GunList) do
			if child.Name == gunName then
				CurrentGun = child
				break
			end
		end
	end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(child)
	if child == CurrentGun then
		CurrentGun = nil
	end
end)

-- Handle respawns
LocalPlayer.CharacterAdded:Connect(function(character)
	CurrentGun = nil
	wait(1)
	CheckForGun()
	
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			for _, gunName in pairs(GunList) do
				if child.Name == gunName then
					CurrentGun = child
					break
				end
			end
		end
	end)
	
	character.ChildRemoved:Connect(function(child)
		if child == CurrentGun then
			CurrentGun = nil
		end
	end)
end)

-- Initial check
CheckForGun()

-- Get VirtualInputManager for shooting
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Shoot function
local lastShootTime = 0
local isMouseDown = false
local function ShootGun()
	-- Only shoot if we have a gun equipped
	if not CurrentGun then 
		return 
	end
	
	local currentTime = tick()
	if currentTime - lastShootTime < math.max(0.1, shootDelay / 1000) then
		return
	end
	
	lastShootTime = currentTime
	
	-- Simulate mouse click using VirtualInputManager
	pcall(function()
		if not isMouseDown then
			isMouseDown = true
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1) -- Press
			task.wait(0.05)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1) -- Release
			task.wait(0.05)
			isMouseDown = false
		end
	end)
end

-- Combined Silent Aim Hook (handles RageBot, Legit Silent Aim, AND Kill Aura)
local OldIndex
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
	if not checkcaller() and self:IsA("Mouse") then
		if key == "Hit" or key == "Target" then
			-- Priority 1: RageBot (highest priority)
			if rageBot and rageBotTarget and rageBotTarget.Character then
				local targetHead = rageBotTarget.Character:FindFirstChild("Head")
				
				if targetHead then
					if key == "Hit" then
						return targetHead.CFrame
					elseif key == "Target" then
						return targetHead
					end
				end
			end
			
			-- Priority 2: Legit Silent Aim
			if legitSilentAim then
				local closestPlayer = GetClosestPlayerSilentAim()
				
				if closestPlayer and closestPlayer.Character then
					local targetPart = closestPlayer.Character:FindFirstChild(silentAimHitPart)
					
					if targetPart then
						-- Store current target and highlight when shooting
						currentSilentTarget = closestPlayer
						HighlightTarget(closestPlayer)
						
						if key == "Hit" then
							return targetPart.CFrame
						elseif key == "Target" then
							return targetPart
						end
					end
				end
			end
			
			-- Priority 3: Kill Aura (only if others didn't trigger)
			if killAuraEnabled and not getgenv().KillAuraUseAimbot and CurrentTarget then
				if CurrentTarget.Character then
					local TargetPart = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
					if TargetPart then
						-- Calculate predicted position
						local PredictedCFrame = TargetPart.CFrame + (TargetPart.Velocity * getgenv().KillAuraPrediction)
						
						if key == "Hit" then
							return PredictedCFrame
						elseif key == "Target" then
							return TargetPart
						end
					end
				end
			end
		end
	end
	
	return OldIndex(self, key)
end))

-- Auto-shoot loop (works for both Silent Aim and Aimbot)
RunService.RenderStepped:Connect(function()
	if not killAuraEnabled then
		CurrentTarget = nil
		UpdateTargetHighlight(nil) -- Remove highlight
		return
	end
	
	-- Always find the closest player (no locking)
	local ClosestPlayer, Distance = GetClosestPlayer()
	
	if ClosestPlayer then
		-- Update highlight if target changed
		if ClosestPlayer ~= CurrentTarget then
			CurrentTarget = ClosestPlayer
			UpdateTargetHighlight(ClosestPlayer)
		end
		
		-- Get target info
		local Character = ClosestPlayer.Character
		if Character then
			local RootPart = Character:FindFirstChild("HumanoidRootPart")
			if RootPart then
				-- Calculate predicted position
				local PredictedPosition = RootPart.Position + (RootPart.Velocity * getgenv().KillAuraPrediction)
				
				-- If using aimbot, aim camera at predicted position
				if getgenv().KillAuraUseAimbot then
					Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, PredictedPosition)
				end
				
				-- Auto shoot (only if gun is equipped)
				ShootGun()
			end
		end
	else
		-- No target found, clear everything
		if CurrentTarget then
			CurrentTarget = nil
			UpdateTargetHighlight(nil)
		end
	end
end)

-- Player Tab - Left Section (Fly)
local PlayerFlySection = PlayerTab:DrawSection({
	Name = "Section",
	Position = 'left'
});

PlayerFlySection:AddToggle({
	Name = "Fly (C)",
	Flag = "Fly",
	Default = false,
	Callback = function(v) 
		flyEnabled = v 
		if v then
			flying = true
			startFly()
		else
			stopFly()
		end
	end,
}).Link:AddKeybind({
	Default = "C",
	Flag = "FlyKey",
	Callback = function() end
});

PlayerFlySection:AddSlider({
	Name = "Flight Speed",
	Min = 1,
	Max = 20,
	Default = 10,
	Round = 1,
	Flag = "FlightSpeed",
	Callback = function(v) 
		flySpeed = v 
		baseSpeed = v -- Update the base speed variable
		speed = v -- Update current speed too
	end
});

PlayerFlySection:AddButton({
	Name = "Mobile Fly",
	Callback = function()
		flyEnabled = not flyEnabled
		if flyEnabled then
			flying = true
			startFly()
		else
			stopFly()
		end
	end,
})

-- Player Tab - Left Section (Speed)
local PlayerSpeedSection = PlayerTab:DrawSection({
	Name = "Section",
	Position = 'left'
});

local walkSpeedToggle = false
local walkSpeedMode = "Always"
local walkSpeed = 50

PlayerSpeedSection:AddToggle({
	Name = "WalkSpeed Toggle",
	Flag = "WalkSpeedToggle",
	Default = false,
	Callback = function(v) walkSpeedToggle = v end,
});

PlayerSpeedSection:AddDropdown({
	Name = "WalkSpeed Mode",
	Default = "Always",
	Values = {"Always", "On Sprint"},
	Callback = function(v) walkSpeedMode = v end
})

PlayerSpeedSection:AddSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 50,
	Round = 1,
	Flag = "WalkSpeed",
	Callback = function(v) walkSpeed = v end
});

-- Player Tab - Right Section (Spin Bot)
local PlayerSpinSection = PlayerTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

local spinBotEnabled = false
local spinSpeed = 50

PlayerSpinSection:AddToggle({
	Name = "Spin Bot",
	Flag = "SpinBot",
	Default = false,
	Callback = function(v) spinBotEnabled = v end,
});

PlayerSpinSection:AddSlider({
	Name = "Spin Speed",
	Min = 1,
	Max = 100,
	Default = 50,
	Round = 1,
	Flag = "SpinSpeed",
	Callback = function(v) spinSpeed = v end
});

-- Player Tab - Right Section (Other)
local PlayerMiscSection = PlayerTab:DrawSection({
	Name = "Section",
	Position = 'right'
});

local fakePosEnabled = false
local voidSpamEnabled = false
local voidSpamMode = "Always"
local desyncEnabled = false
local desyncMode = "Custom"

PlayerMiscSection:AddToggle({
	Name = "FakePos",
	Flag = "FakePos",
	Default = false,
	Callback = function(v) fakePosEnabled = v end,
});

PlayerMiscSection:AddToggle({
	Name = "Void Spam",
	Flag = "VoidSpam",
	Default = false,
	Callback = function(v) voidSpamEnabled = v end,
});

PlayerMiscSection:AddDropdown({
	Name = "Void Spam Mode",
	Default = "Always",
	Values = {"Always", "On Key"},
	Callback = function(v) voidSpamMode = v end
})

PlayerMiscSection:AddToggle({
	Name = "Desync",
	Flag = "Desync",
	Default = false,
	Callback = function(v) desyncEnabled = v end,
});

PlayerMiscSection:AddDropdown({
	Name = "Desync Mode",
	Default = "Custom",
	Values = {"Custom", "Prediction"},
	Callback = function(v) desyncMode = v end
})

-- Left Section - Hitbox
local HitboxSection = MainTab:DrawSection({
	Name = "Section",
	Position = 'left'	
});

local HitboxToggle = HitboxSection:AddToggle({
	Name = "Hitbox Expander",
	Flag = "HitboxEnabled",
	Default = Settings.hitboxEnabled,
	Callback = function(v) 
		Settings.hitboxEnabled = v 
		
		if v then
			Notifier.new({
				Title = "Hitbox Expander",
				Content = "Enabled!",
				Duration = 2
			});
		else
			-- Restore all hitboxes
			for _, player in pairs(Players:GetPlayers()) do
				restorePlayerHitbox(player)
			end
			Notifier.new({
				Title = "Hitbox Expander",
				Content = "Disabled!",
				Duration = 2
			});
		end
	end,
});

HitboxSection:AddSlider({
	Name = "Hitbox Size",
	Min = 5,
	Max = 50,
	Default = Settings.hitboxSize,
	Round = 1,
	Flag = "HitboxSize",
	Callback = function(v) 
		Settings.hitboxSize = v 
	end
});

HitboxSection:AddToggle({
	Name = "Streamable",
	Flag = "Streamable",
	Default = Settings.streamable,
	Callback = function(v) 
		Settings.streamable = v 
	end,
});

HitboxSection:AddColorPicker({
	Name = "Hitbox Color",
	Default = Settings.hitboxColor,
	Flag = "HitboxColor",
	Callback = function(v) 
		Settings.hitboxColor = v 
	end
})

-- Car Speed Section
local CarSection = MainTab:DrawSection({
	Name = "Section",
	Position = 'left'	
});

CarSection:AddSlider({
	Name = "Car Speed",
	Min = 0,
	Max = 200,
	Default = Settings.carSpeed,
	Round = 1,
	Flag = "CarSpeed",
	Callback = function(v) 
		Settings.carSpeed = v 
	end
});

-- NoClip Section
local MovementSection = MainTab:DrawSection({
	Name = "Section",
	Position = 'left'	
});

MovementSection:AddToggle({
	Name = "NoClip",
	Flag = "NoClip",
	Default = Settings.noClip,
	Callback = function(v) 
		Settings.noClip = v 
		
		if v then
			Notifier.new({
				Title = "NoClip",
				Content = "Enabled!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "NoClip",
				Content = "Disabled!",
				Duration = 2
			});
		end
	end,
});

-- Right Section - Buttons
local UtilitySection = MainTab:DrawSection({
	Name = "Section",
	Position = 'right'	
});

local chatSpyEnabled = false
local chatSpyFrame = nil
local chatSpySetup = false

-- Hook into chat system (setup once)
local function onChatted(player, message)
	if not chatSpyEnabled or not chatSpyFrame then return end
	
	local chatLabel = Instance.new("TextLabel")
	chatLabel.Size = UDim2.new(1, -5, 0, 20)
	chatLabel.BackgroundTransparency = 1
	chatLabel.Text = player.Name .. ": " .. message
	chatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	chatLabel.Font = Enum.Font.Gotham
	chatLabel.TextSize = 12
	chatLabel.TextXAlignment = Enum.TextXAlignment.Left
	chatLabel.TextWrapped = true
	chatLabel.Parent = chatSpyFrame
	
	-- Auto-adjust height based on text
	chatLabel.Size = UDim2.new(1, -5, 0, math.max(20, chatLabel.TextBounds.Y + 4))
end

-- Setup chat spy listeners once
if not chatSpySetup then
	chatSpySetup = true
	
	-- Listen to all current players
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			player.Chatted:Connect(function(msg)
				onChatted(player, msg)
			end)
		end
	end
	
	-- Listen to new players
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(msg)
			onChatted(player, msg)
		end)
	end)
end

UtilitySection:AddButton({
	Name = "Chat Spy",
	Callback = function()
		chatSpyEnabled = not chatSpyEnabled
		
		if chatSpyEnabled then
			Notifier.new({
				Title = "Chat Spy",
				Content = "Enabled! Monitoring all chats...",
				Duration = 3
			});
			
			-- Create Chat Spy UI
			if not chatSpyFrame then
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "ChatSpyUI"
				screenGui.ResetOnSpawn = false
				screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				screenGui.Parent = game:GetService("CoreGui")
				
				local mainFrame = Instance.new("Frame")
				mainFrame.Name = "MainFrame"
				mainFrame.Size = UDim2.new(0, 350, 0, 250)
				mainFrame.Position = UDim2.new(0, 10, 1, -260) -- Bottom left
				mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				mainFrame.BorderSizePixel = 0
				mainFrame.Parent = screenGui
				
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 8)
				corner.Parent = mainFrame
				
				local title = Instance.new("TextLabel")
				title.Name = "Title"
				title.Size = UDim2.new(1, 0, 0, 30)
				title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				title.BorderSizePixel = 0
				title.Text = "Chat Spy"
				title.TextColor3 = Color3.fromRGB(255, 255, 255)
				title.Font = Enum.Font.GothamBold
				title.TextSize = 14
				title.Parent = mainFrame
				
				local titleCorner = Instance.new("UICorner")
				titleCorner.CornerRadius = UDim.new(0, 8)
				titleCorner.Parent = title
				
				local scrollFrame = Instance.new("ScrollingFrame")
				scrollFrame.Name = "ChatLog"
				scrollFrame.Size = UDim2.new(1, -10, 1, -40)
				scrollFrame.Position = UDim2.new(0, 5, 0, 35)
				scrollFrame.BackgroundTransparency = 1
				scrollFrame.BorderSizePixel = 0
				scrollFrame.ScrollBarThickness = 4
				scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
				scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				scrollFrame.Parent = mainFrame
				
				local listLayout = Instance.new("UIListLayout")
				listLayout.SortOrder = Enum.SortOrder.LayoutOrder
				listLayout.Padding = UDim.new(0, 2)
				listLayout.Parent = scrollFrame
				
				listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
					scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
				end)
				
				chatSpyFrame = scrollFrame
			else
				-- Show existing frame
				chatSpyFrame.Parent.Parent.Enabled = true
			end
			
		else
			Notifier.new({
				Title = "Chat Spy",
				Content = "Disabled!",
				Duration = 3
			});
			
			-- Hide the frame
			if chatSpyFrame then
				chatSpyFrame.Parent.Parent.Enabled = false
			end
		end
	end,
})

local antiModEnabled = false
local dahoodGroupId = 4698921

UtilitySection:AddButton({
	Name = "Anti Mod",
	Callback = function()
		antiModEnabled = not antiModEnabled
		
		if antiModEnabled then
			-- Function to check all players
			local function CheckForMods()
				for _, player in pairs(Players:GetPlayers()) do
					if player ~= LocalPlayer then
						local success, rank = pcall(function()
							return player:GetRankInGroup(dahoodGroupId)
						end)
						
						if success and rank > 1 then -- Rank > 1 means staff/mod/admin
							local roleName = player:GetRoleInGroup(dahoodGroupId)
							LocalPlayer:Kick("A moderator has joined the server!\nModerator: " .. player.Name .. " (" .. roleName .. ")\nYou have been kicked for safety.")
						end
					end
				end
			end
			
			-- Check immediately
			CheckForMods()
			
			-- Check every 10 seconds
			task.spawn(function()
				while antiModEnabled do
					wait(10)
					if antiModEnabled then
						CheckForMods()
					end
				end
			end)
			
			-- Monitor new players joining
			Players.PlayerAdded:Connect(function(player)
				if not antiModEnabled then return end
				
				task.spawn(function()
					wait(1) -- Wait for player to fully load
					
					local success, rank = pcall(function()
						return player:GetRankInGroup(dahoodGroupId)
					end)
					
					if success and rank > 1 then
						local roleName = player:GetRoleInGroup(dahoodGroupId)
						LocalPlayer:Kick("A moderator has joined the server!\nModerator: " .. player.Name .. " (" .. roleName .. ")\nYou have been kicked for safety.")
					end
				end)
			end)
		end
	end,
})

UtilitySection:AddButton({
	Name = "Force Resetv2",
	Callback = function()
		LocalPlayer.Character.Humanoid.Health = 0
		Notifier.new({
			Title = "Force Reset",
			Content = "Character reset!",
			Duration = 2
		});
	end,
})

local antiPepperSprayEnabled = false

UtilitySection:AddButton({
	Name = "Anti peperspray",
	Callback = function()
		antiPepperSprayEnabled = not antiPepperSprayEnabled
		
		if antiPepperSprayEnabled then
			Notifier.new({
				Title = "Anti Pepperspray",
				Content = "Enabled! Blocking pepperspray effects...",
				Duration = 3
			});
		else
			Notifier.new({
				Title = "Anti Pepperspray",
				Content = "Disabled!",
				Duration = 3
			});
		end
	end,
})

-- Animation Section
local AnimationSection = MainTab:DrawSection({
	Name = "Section",
	Position = 'right'	
});

-- Animation Pack IDs
local AnimationPacks = {
	Astronaut = {
		idle1 = "891621366",
		idle2 = "891621366",
		walk = "891636393",
		run = "891636393",
		jump = "891627522",
		climb = "891609353",
		fall = "891617961",
		swim = "891639666",
		swimidle = "891663592"
	},
	Bubbly = {
		idle1 = "910004836",
		idle2 = "910009958",
		walk = "910034870",
		run = "910025107",
		jump = "910016857",
		climb = "910028158",
		fall = "910001910",
		swim = "910030921",
		swimidle = "910028158"
	},
	Cartoony = {
		idle1 = "742637544",
		idle2 = "742638445",
		walk = "742640026",
		run = "742638842",
		jump = "742637942",
		climb = "742636889",
		fall = "742637151",
		swim = "742639220",
		swimidle = "742639812"
	},
	Elder = {
		idle1 = "845397899",
		idle2 = "845400520",
		walk = "845403856",
		run = "845386501",
		jump = "845398858",
		climb = "845392038",
		fall = "845397048",
		swim = "845401742",
		swimidle = "845403127"
	},
	Knight = {
		idle1 = "657595757",
		idle2 = "657568135",
		walk = "657552124",
		run = "657564596",
		jump = "658409194",
		climb = "658360781",
		fall = "657600338",
		swim = "657560551",
		swimidle = "657557095"
	},
	Levitation = {
		idle1 = "616006778",
		idle2 = "616008087",
		walk = "616013216",
		run = "616010382",
		jump = "616008936",
		climb = "616003713",
		fall = "616005863",
		swim = "616011509",
		swimidle = "616012453"
	},
	Mage = {
		idle1 = "707742142",
		idle2 = "707855907",
		walk = "707897309",
		run = "707861613",
		jump = "707853694",
		climb = "707826056",
		fall = "707829716",
		swim = "707876443",
		swimidle = "707894699"
	},
	Ninja = {
		idle1 = "656117400",
		idle2 = "656118341",
		walk = "656121766",
		run = "656118852",
		jump = "656117878",
		climb = "656114359",
		fall = "656115606",
		swim = "656119721",
		swimidle = "656121397"
	},
	Pirate = {
		idle1 = "750781874",
		idle2 = "750782770",
		walk = "750785693",
		run = "750783738",
		jump = "750782230",
		climb = "750779899",
		fall = "750780242",
		swim = "750784579",
		swimidle = "750785176"
	},
	Robot = {
		idle1 = "616088211",
		idle2 = "616089559",
		walk = "616095330",
		run = "616091570",
		jump = "616090535",
		climb = "616086039",
		fall = "616087089",
		swim = "616092998",
		swimidle = "616133006"
	},
	Superhero = {
		idle1 = "782841498",
		idle2 = "782845736",
		walk = "616168032",
		run = "616163682",
		jump = "1083218792",
		climb = "1083439238",
		fall = "707829716",
		swim = "616165109",
		swimidle = "616166655"
	},
	Toy = {
		idle1 = "782841498",
		idle2 = "782845736",
		walk = "782843345",
		run = "782842708",
		jump = "782847020",
		climb = "782843869",
		fall = "782846423",
		swim = "782844582",
		swimidle = "782845186"
	},
	Vampire = {
		idle1 = "1083445855",
		idle2 = "1083450166",
		walk = "1083473930",
		run = "1083462077",
		jump = "1083455352",
		climb = "1083439238",
		fall = "1083443587",
		swim = "1083464683",
		swimidle = "1083467779"
	},
	Zombie = {
		idle1 = "616158929",
		idle2 = "616160636",
		walk = "616168032",
		run = "616163682",
		jump = "616161997",
		climb = "616156119",
		fall = "616157476",
		swim = "616165109",
		swimidle = "616166655"
	}
}

-- Function to apply animation pack
local function ApplyAnimation(Character, packName)
	local pack = AnimationPacks[packName]
	if not pack then return end
	
	local Animate = Character:WaitForChild("Animate", 5)
	if not Animate then return end
	
	Character.HumanoidRootPart.Anchored = true
	
	pcall(function()
		Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.idle1
		Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.idle2
		Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.walk
		Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.run
		Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.jump
		Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.climb
		Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.fall
		Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.swim
		Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=" .. pack.swimidle
		Character.Humanoid.Jump = false
	end)
	
	wait(1)
	Character.HumanoidRootPart.Anchored = false
end

AnimationSection:AddDropdown({
	Name = "Animation Pack",
	Default = "Select an Animation...",
	Values = {"Astronaut", "Bubbly", "Cartoony", "Elder", "Knight", "Levitation", "Mage", "Ninja", "Pirate", "Robot", "Superhero", "Toy", "Vampire", "Zombie"},
	Callback = function(v)
		if v == "Select an Animation..." then return end
		
		Notifier.new({
			Title = "Animation Pack",
			Content = "Applied: " .. v,
			Duration = 3
		});
		
		-- Apply to current character
		if LocalPlayer.Character then
			ApplyAnimation(LocalPlayer.Character, v)
		end
		
		-- Apply to future characters
		LocalPlayer.CharacterAdded:Connect(function(char)
			ApplyAnimation(char, v)
		end)
	end
})

AnimationSection:AddButton({
	Name = "Auto Farm codes",
	Callback = function()
		Notifier.new({
			Title = "Auto Farm Codes",
			Content = "Redeeming all codes...",
			Duration = 2
		});
		
		local codes = {
			"HALLOWEEN25",
			"ADMINABUSE",
			"OCTOBER25",
			"BRAINROT",
			"LUXE",
			"TURBO",
			"BUBU",
			"MUSIC",
			"KINGPIN"
		}
		
		local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
		local redeemed = 0
		
		if not MainEvent then
			Notifier.new({
				Title = "Error",
				Content = "MainEvent not found!",
				Duration = 3
			});
			return
		end
		
		for _, code in ipairs(codes) do
			local success = pcall(function()
				local args = {
					[1] = "EnterPromoCode",
					[2] = code
				}
				MainEvent:FireServer(unpack(args))
			end)
			
			if success then
				redeemed = redeemed + 1
			end
			
			wait(0.5)
		end
		
		Notifier.new({
			Title = "Auto Farm Codes",
			Content = "Attempted to redeem " .. redeemed .. " codes!",
			Duration = 5
		});
	end,
})

AnimationSection:AddButton({
	Name = "Auto Farm codes (HIGH EXECUTOR)",
	Callback = function()
		if not request then
			Notifier.new({
				Title = "Error",
				Content = "Your executor doesn't support request function!",
				Duration = 5
			});
			return
		end
		
		Notifier.new({
			Title = "Auto Farm Codes",
			Content = "Fetching latest codes from website...",
			Duration = 3
		});
		
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		
		local success, response = pcall(request, {
			Url = "https://gamerant.com/roblox-da-hood-codes/",
			Method = "GET",
		})
		
		if success and response.StatusCode == 200 then
			local html = response.Body
			local codes = {}
			
			local activeSection = string.match(html, "All Active Da Hood Codes(.-)All Expired Da Hood Codes")
			if activeSection then
				for code in string.gmatch(activeSection, "<strong>(.-)</strong>") do
					if not code:find("%(NEW%)") then
						code = code:gsub("%s+", "")
						table.insert(codes, code)
					end
				end
				
				Notifier.new({
					Title = "Auto Farm Codes",
					Content = "Found " .. #codes .. " codes! Redeeming...",
					Duration = 3
				});
				
				local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")
				
				for _, code in ipairs(codes) do
					pcall(function()
						local args = {[1] = "EnterPromoCode", [2] = code}
						MainEvent:FireServer(unpack(args))
					end)
					print(code)
					wait(5)
				end
				
				Notifier.new({
					Title = "Auto Farm Codes",
					Content = "All codes redeemed!",
					Duration = 5
				});
			else
				Notifier.new({
					Title = "Error",
					Content = "Could not parse codes from website!",
					Duration = 5
				});
			end
		else
			Notifier.new({
				Title = "Error",
				Content = "Failed to get website (executor problem)",
				Duration = 5
			});
		end
	end,
})

-- Localizations
local Lower, Sub, SFind, Byte, Gsub = string.lower, string.sub, string.find, string.byte, string.gsub
local Find, Insert, Remove = table.find, table.insert, table.remove
local Wait, Spawn = task.wait, task.spawn

local GunList = {
	"[Shotgun]",
	"[Drum-Shotgun]",
	"[Rifle]",
	"[TacticalShotgun]",
	"[AR]",
	"[AUG]",
	"[AK47]",
	"[LMG]",
    "[Double-Barrel SG]",
	"[SilencerAR]",
    "[Revolver]",
    "[Flintlock]"
}

-- Load Skins (wait for it to exist first)
local Skins = require(ReplicatedStorage:WaitForChild("SkinModules"))

-- Skin changer function (from working script)
local function CreateMesh(Tool, Original)
    if not Original then return false end
    if not Tool then return end

    local Default = Tool.Default
    local SkinHolder = Default:FindFirstChild("Skin_Holder")

    if SkinHolder then SkinHolder:Destroy() end

    if typeof(Original) ~= "Instance" then
        Default.TextureID = Original
    else
        if Original.ClassName ~= "MeshPart" then
            return false
        else
            Default.TextureID = Original.TextureID
            local Clone = Original:Clone()
            Clone.Name = "Skin_Holder"
            Clone.Parent = Default
        end
    end

    return true
end

local SkinList = {}

local function UseSkin(Tool, SkinName)
    Tool = Tool or ToolEquipped

    if not Tool then return end

    local Skin = (Skins[Tool.Name] or {})[SkinName] or SkinList[Tool.Name];
    
    if not Skin then return end

    if SkinName then Skin.Name = SkinName else SkinName = Skin.Name end

    local ShootSounds = ReplicatedStorage.SkinAssets.GunShootSounds
    local GunSounds = ShootSounds:FindFirstChild(Tool.Name)

    local Sound = GunSounds and GunSounds:FindFirstChild(SkinName)
    local Handle = Tool.Handle

    local Shoot = Handle:FindFirstChild("ShootSound")

    Tool.Handle:SetAttribute("SkinName", SkinName)

    if Shoot then
        if Sound then
            Shoot:SetAttribute("Old", Shoot:GetAttribute("Old") or Shoot.SoundId)
            Shoot.SoundId = Sound.Value
        else
            Shoot.SoundId = Shoot:GetAttribute("Old") or Shoot.SoundId
        end
    end

    if CreateMesh(Tool, Skin.TextureID) then SkinList[Tool.Name] = Skin end
end

print("DEBUG: Creating Utility category...")

-- Creating Utility Category and Tab
Window:DrawCategory({
	Name = "Utility"
});

print("DEBUG: Creating Utility tab...")

local UtilityTab = Window:DrawTab({
	Name = "Utility",
	Icon = "shield",
	Type = "Double",
	EnableScrolling = true
});

print("DEBUG: Utility tab created, adding sections...")

-- ===== UTILITY TAB CONTENT =====

-- Utility Left Section 1 - Anti Features
local UtilityAntiSection = UtilityTab:DrawSection({
	Name = "Anti Features",
	Position = 'left'
});

print("DEBUG: Anti Features section created...")

UtilityAntiSection:AddToggle({
	Name = "Anti Slow",
	Flag = "AntiSlow",
	Default = false,
	Callback = function(v) end,
});

UtilityAntiSection:AddToggle({
	Name = "Anti stomp",
	Flag = "AntiStompUtil",
	Default = false,
	Callback = function(v) end,
});

UtilityAntiSection:AddToggle({
	Name = "Anti Void",
	Flag = "AntiVoid",
	Default = false,
	Callback = function(v) end,
});

-- Utility Left Section 2 - Aspect Ratio
local UtilityAspectSection = UtilityTab:DrawSection({
	Name = "Aspect Ratio",
	Position = 'left'
});

local aspectRatioToggle = false
local horizontalStretch = 29
local verticalStretch = 10

UtilityAspectSection:AddToggle({
	Name = "Aspect Ratio Toggle",
	Flag = "AspectRatioToggle",
	Default = false,
	Callback = function(v) aspectRatioToggle = v end,
});

UtilityAspectSection:AddSlider({
	Name = "Horizontal Stretch",
	Min = 0,
	Max = 100,
	Default = 29,
	Round = 0,
	Flag = "HorizontalStretch",
	Callback = function(v) horizontalStretch = v end
});

UtilityAspectSection:AddSlider({
	Name = "Vertical Stretch",
	Min = 0,
	Max = 100,
	Default = 10,
	Round = 0,
	Flag = "VerticalStretch",
	Callback = function(v) verticalStretch = v end
});

-- Utility Left Section 3 - Visual
local UtilityVisualSection = UtilityTab:DrawSection({
	Name = "Visual",
	Position = 'left'
});

local noFog = false
local fovToggle = false
local fovSlider = 16

UtilityVisualSection:AddToggle({
	Name = "No fog",
	Flag = "NoFog",
	Default = false,
	Callback = function(v) noFog = v end,
});

UtilityVisualSection:AddToggle({
	Name = "fovToggle",
	Flag = "FovToggle",
	Default = false,
	Callback = function(v) fovToggle = v end,
});

UtilityVisualSection:AddSlider({
	Name = "fov slider",
	Min = 1,
	Max = 120,
	Default = 16,
	Round = 0,
	Flag = "FovSlider",
	Callback = function(v) fovSlider = v end
});

-- Utility Right Section 1 - Auto Features
local UtilityAutoSection = UtilityTab:DrawSection({
	Name = "Auto Features",
	Position = 'right'
});

UtilityAutoSection:AddToggle({
	Name = "Auto Stomp",
	Flag = "UtilityAutoStomp",
	Default = false,
	Callback = function(v) end,
});

UtilityAutoSection:AddToggle({
	Name = "Auto Reload",
	Flag = "UtilityAutoReload",
	Default = false,
	Callback = function(v) end,
});

-- Utility Right Section 2 - Gear
local UtilityGearSection = UtilityTab:DrawSection({
	Name = "Gear",
	Position = 'right'
});

UtilityGearSection:AddToggle({
	Name = "Auto Armor",
	Flag = "AutoArmor",
	Default = false,
	Callback = function(v) end,
});

UtilityGearSection:AddToggle({
	Name = "Auto mask",
	Flag = "AutoMask",
	Default = false,
	Callback = function(v) end,
});

-- Utility Right Section 3 - Cash
local UtilityCashSection = UtilityTab:DrawSection({
	Name = "Cash",
	Position = 'right'
});

UtilityCashSection:AddToggle({
	Name = "Auto drop cash",
	Flag = "AutoDropCash",
	Default = false,
	Callback = function(v) end,
});

UtilityCashSection:AddToggle({
	Name = "Cash Aura",
	Flag = "CashAura",
	Default = false,
	Callback = function(v) end,
});

-- Utility Right Section 4 - Anti Combat
local UtilityAntiSection2 = UtilityTab:DrawSection({
	Name = "Anti Combat",
	Position = 'right'
});

UtilityAntiSection2:AddToggle({
	Name = "Anti Sit",
	Flag = "AntiSit",
	Default = false,
	Callback = function(v) end,
});

UtilityAntiSection2:AddToggle({
	Name = "Anti RPG",
	Flag = "AntiRPG",
	Default = false,
	Callback = function(v) end,
});

UtilityAntiSection2:AddToggle({
	Name = "Anti Grenade",
	Flag = "AntiGrenade",
	Default = false,
	Callback = function(v) end,
});

-- Add Misc category and tab (from working script)
Window:DrawCategory({
	Name = "Misc"
});

local SkinsTab = Window:DrawTab({
	Name = "Weapon Skins",
	Icon = "sword",
	EnableScrolling = true
});

local SkinsSection = SkinsTab:DrawSection({
	Name = "Skins",
	Position = 'left'
});

-- Create dropdowns for all weapons with skins (from working script)
local HasSkins = table.clone(GunList)
Insert(HasSkins, "[Wallet]")
Insert(HasSkins, "[Knife]")

table.sort(HasSkins, function(a, b) return Byte(Sub(a, 2, 2)) < Byte(Sub(b, 2, 2)) end)

for _, v in next, HasSkins do
    local List = {};

    for n in next, Skins[v] or {"No Skins Available"} do Insert(List, n) end
    table.sort(List, function(a, b) return Byte(a) < Byte(b) end)

    local SkinsDropdown = SkinsSection:AddDropdown({
        Values = List,
        Default = "None",
        Flag = v .. "_Skin",
        Name = Gsub(v, "[%[%]]", "") .. " Skins",
        Callback = function(selectedSkin)
            local Tool = LocalPlayer.Character:FindFirstChild(v) or LocalPlayer.Backpack:FindFirstChild(v)
            if Tool then
                UseSkin(Tool, selectedSkin)
                Notifier.new({
                    Title = "Skin Applied",
                    Content = Gsub(v, "[%[%]]", "") .. " - " .. selectedSkin,
                    Duration = 2
                });
            else
                Notifier.new({
                    Title = "Warning",
                    Content = "Equip " .. Gsub(v, "[%[%]]", "") .. " first to apply skin!",
                    Duration = 3
                });
            end
        end
    })
end

local ToolEquipped, IsGun

local function CharacterChildAdded(child)
    if child:IsA("Tool") then
        ToolEquipped, IsGun = child, Find(GunList, child.Name)
        UseSkin(ToolEquipped)
    end
end

local function CharacterChildRemoved(child)
    if child:IsA("Tool") then ToolEquipped, IsGun = nil, false end
end

LocalPlayer.Character.ChildAdded:Connect(CharacterChildAdded)
LocalPlayer.Character.ChildRemoved:Connect(CharacterChildRemoved)

-- Create Dahood Animations tab in Misc category
local DahoodAnimTab = Window:DrawTab({
	Name = "Dahood Animations",
	Icon = "activity",
	EnableScrolling = true
});

local DahoodAnimSection = DahoodAnimTab:DrawSection({
	Name = "Animation Packs",
	Position = 'left'
});

-- Animation Pack function
local animationPackEnabled = false

local function SetupAnimationPack(Character)
    Character:WaitForChild('Humanoid')
    
    repeat wait() until Character:FindFirstChild("FULLY_LOADED_CHAR") and LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")

    -- Delete existing animations
    local ClientAnimations = ReplicatedStorage.ClientAnimations
    
    if ClientAnimations:FindFirstChild("Lean") then ClientAnimations.Lean:Destroy() end
    if ClientAnimations:FindFirstChild("Lay") then ClientAnimations.Lay:Destroy() end
    if ClientAnimations:FindFirstChild("Dance1") then ClientAnimations.Dance1:Destroy() end
    if ClientAnimations:FindFirstChild("Dance2") then ClientAnimations.Dance2:Destroy() end
    if ClientAnimations:FindFirstChild("Greet") then ClientAnimations.Greet:Destroy() end
    if ClientAnimations:FindFirstChild("Chest Pump") then ClientAnimations["Chest Pump"]:Destroy() end
    if ClientAnimations:FindFirstChild("Praying") then ClientAnimations.Praying:Destroy() end

    -- Create new animations
    local LeanAnimation = Instance.new("Animation", ClientAnimations)
    LeanAnimation.Name = "Lean"
    LeanAnimation.AnimationId = "rbxassetid://3152375249"

    local LayAnimation = Instance.new("Animation", ClientAnimations)
    LayAnimation.Name = "Lay"
    LayAnimation.AnimationId = "rbxassetid://3152378852"

    local Dance1Animation = Instance.new("Animation", ClientAnimations)
    Dance1Animation.Name = "Dance1"
    Dance1Animation.AnimationId = "rbxassetid://3189773368"

    local Dance2Animation = Instance.new("Animation", ClientAnimations)
    Dance2Animation.Name = "Dance2"
    Dance2Animation.AnimationId = "rbxassetid://3189776546"

    local GreetAnimation = Instance.new("Animation", ClientAnimations)
    GreetAnimation.Name = "Greet"
    GreetAnimation.AnimationId = "rbxassetid://3189777795"

    local ChestPumpAnimation = Instance.new("Animation", ClientAnimations)
    ChestPumpAnimation.Name = "Chest Pump"
    ChestPumpAnimation.AnimationId = "rbxassetid://3189779152"

    local PrayingAnimation = Instance.new("Animation", ClientAnimations)
    PrayingAnimation.Name = "Praying"
    PrayingAnimation.AnimationId = "rbxassetid://3487719500"

    local AnimationPack = LocalPlayer.PlayerGui.MainScreenGui.AnimationPack
    local ScrollingFrame = AnimationPack.ScrollingFrame
    local CloseButton = AnimationPack.CloseButton

    local Lean = Character.Humanoid:LoadAnimation(LeanAnimation)
    local Lay = Character.Humanoid:LoadAnimation(LayAnimation)
    local Dance1 = Character.Humanoid:LoadAnimation(Dance1Animation)
    local Dance2 = Character.Humanoid:LoadAnimation(Dance2Animation)
    local Greet = Character.Humanoid:LoadAnimation(GreetAnimation)
    local ChestPump = Character.Humanoid:LoadAnimation(ChestPumpAnimation)
    local Praying = Character.Humanoid:LoadAnimation(PrayingAnimation)

    AnimationPack.Visible = true
    ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Rename buttons
    for i,v in pairs(ScrollingFrame:GetChildren()) do
        if v.Name == "TextButton" then
            if v.Text == "Lean" then v.Name = "LeanButton"
            elseif v.Text == "Lay" then v.Name = "LayButton"
            elseif v.Text == "Dance1" then v.Name = "Dance1Button"
            elseif v.Text == "Dance2" then v.Name = "Dance2Button"
            elseif v.Text == "Greet" then v.Name = "GreetButton"
            elseif v.Text == "Chest Pump" then v.Name = "ChestPumpButton"
            elseif v.Text == "Praying" then v.Name = "PrayingButton"
            end
        end
    end

    local function StopAll()
        Lean:Stop()
        Lay:Stop()
        Dance1:Stop()
        Dance2:Stop()
        Greet:Stop()
        ChestPump:Stop()
        Praying:Stop()
    end

    local LeanTextButton = ScrollingFrame.LeanButton
    local LayTextButton = ScrollingFrame.LayButton
    local Dance1TextButton = ScrollingFrame.Dance1Button
    local Dance2TextButton = ScrollingFrame.Dance2Button
    local GreetTextButton = ScrollingFrame.GreetButton
    local ChestPumpTextButton = ScrollingFrame.ChestPumpButton
    local PrayingTextButton = ScrollingFrame.PrayingButton

    AnimationPack.MouseButton1Click:Connect(function()
        if ScrollingFrame.Visible == false then
            ScrollingFrame.Visible = true
            CloseButton.Visible = true
        end
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        if ScrollingFrame.Visible == true then
            ScrollingFrame.Visible = false
            CloseButton.Visible = false
        end
    end)
    
    LeanTextButton.MouseButton1Click:Connect(function() StopAll() Lean:Play() end)
    LayTextButton.MouseButton1Click:Connect(function() StopAll() Lay:Play() end)
    Dance1TextButton.MouseButton1Click:Connect(function() StopAll() Dance1:Play() end)
    Dance2TextButton.MouseButton1Click:Connect(function() StopAll() Dance2:Play() end)
    GreetTextButton.MouseButton1Click:Connect(function() StopAll() Greet:Play() end)
    ChestPumpTextButton.MouseButton1Click:Connect(function() StopAll() ChestPump:Play() end)
    PrayingTextButton.MouseButton1Click:Connect(function() StopAll() Praying:Play() end)

    Character.Humanoid.Running:Connect(function() StopAll() end)
end

DahoodAnimSection:AddButton({
	Name = "Animation Pack",
	Callback = function()
		if not animationPackEnabled then
			animationPackEnabled = true
			SetupAnimationPack(LocalPlayer.Character)
			LocalPlayer.CharacterAdded:Connect(SetupAnimationPack)
		end
	end,
})

-- Animation Pack++ function (with extra animations)
local animationPackPlusEnabled = false

local function SetupAnimationPackPlus(Character)
    Character:WaitForChild('Humanoid')
    
    repeat wait() until Character:FindFirstChild("FULLY_LOADED_CHAR") and LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack") and LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")

    -- Delete existing animations
    local ClientAnimations = ReplicatedStorage.ClientAnimations
    
    if ClientAnimations:FindFirstChild("Lean") then ClientAnimations.Lean:Destroy() end
    if ClientAnimations:FindFirstChild("Lay") then ClientAnimations.Lay:Destroy() end
    if ClientAnimations:FindFirstChild("Dance1") then ClientAnimations.Dance1:Destroy() end
    if ClientAnimations:FindFirstChild("Dance2") then ClientAnimations.Dance2:Destroy() end
    if ClientAnimations:FindFirstChild("Greet") then ClientAnimations.Greet:Destroy() end
    if ClientAnimations:FindFirstChild("Chest Pump") then ClientAnimations["Chest Pump"]:Destroy() end
    if ClientAnimations:FindFirstChild("Praying") then ClientAnimations.Praying:Destroy() end
    if ClientAnimations:FindFirstChild("TheDefault") then ClientAnimations.TheDefault:Destroy() end
    if ClientAnimations:FindFirstChild("Sturdy") then ClientAnimations.Sturdy:Destroy() end
    if ClientAnimations:FindFirstChild("Rossy") then ClientAnimations.Rossy:Destroy() end
    if ClientAnimations:FindFirstChild("Griddy") then ClientAnimations.Griddy:Destroy() end
    if ClientAnimations:FindFirstChild("TPose") then ClientAnimations.TPose:Destroy() end
    if ClientAnimations:FindFirstChild("SpeedBlitz") then ClientAnimations.SpeedBlitz:Destroy() end

    -- Create animations (Pack 1)
    local LeanAnimation = Instance.new("Animation", ClientAnimations)
    LeanAnimation.Name = "Lean"
    LeanAnimation.AnimationId = "rbxassetid://3152375249"

    local LayAnimation = Instance.new("Animation", ClientAnimations)
    LayAnimation.Name = "Lay"
    LayAnimation.AnimationId = "rbxassetid://3152378852"

    local Dance1Animation = Instance.new("Animation", ClientAnimations)
    Dance1Animation.Name = "Dance1"
    Dance1Animation.AnimationId = "rbxassetid://3189773368"

    local Dance2Animation = Instance.new("Animation", ClientAnimations)
    Dance2Animation.Name = "Dance2"
    Dance2Animation.AnimationId = "rbxassetid://3189776546"

    local GreetAnimation = Instance.new("Animation", ClientAnimations)
    GreetAnimation.Name = "Greet"
    GreetAnimation.AnimationId = "rbxassetid://3189777795"

    local ChestPumpAnimation = Instance.new("Animation", ClientAnimations)
    ChestPumpAnimation.Name = "Chest Pump"
    ChestPumpAnimation.AnimationId = "rbxassetid://3189779152"

    local PrayingAnimation = Instance.new("Animation", ClientAnimations)
    PrayingAnimation.Name = "Praying"
    PrayingAnimation.AnimationId = "rbxassetid://3487719500"

    -- Create animations (Pack++)
    local TheDefaultAnimation = Instance.new("Animation", ClientAnimations)
    TheDefaultAnimation.Name = "TheDefault"
    TheDefaultAnimation.AnimationId = "rbxassetid://11710529975"

    local SturdyAnimation = Instance.new("Animation", ClientAnimations)
    SturdyAnimation.Name = "Sturdy"
    SturdyAnimation.AnimationId = "rbxassetid://11710524717"

    local RossyAnimation = Instance.new("Animation", ClientAnimations)
    RossyAnimation.Name = "Rossy"
    RossyAnimation.AnimationId = "rbxassetid://11710527244"

    local GriddyAnimation = Instance.new("Animation", ClientAnimations)
    GriddyAnimation.Name = "Griddy"
    GriddyAnimation.AnimationId = "rbxassetid://11710529220"

    local TPoseAnimation = Instance.new("Animation", ClientAnimations)
    TPoseAnimation.Name = "TPose"
    TPoseAnimation.AnimationId = "rbxassetid://11710524200"

    local SpeedBlitzAnimation = Instance.new("Animation", ClientAnimations)
    SpeedBlitzAnimation.Name = "SpeedBlitz"
    SpeedBlitzAnimation.AnimationId = "rbxassetid://11710541744"

    local AnimationPack = LocalPlayer.PlayerGui.MainScreenGui.AnimationPack
    local AnimationPackPlus = LocalPlayer.PlayerGui.MainScreenGui.AnimationPlusPack
    local ScrollingFrame = AnimationPack.ScrollingFrame
    local CloseButton = AnimationPack.CloseButton
    local ScrollingFramePlus = AnimationPackPlus.ScrollingFrame
    local CloseButtonPlus = AnimationPackPlus.CloseButton

    local Lean = Character.Humanoid:LoadAnimation(LeanAnimation)
    local Lay = Character.Humanoid:LoadAnimation(LayAnimation)
    local Dance1 = Character.Humanoid:LoadAnimation(Dance1Animation)
    local Dance2 = Character.Humanoid:LoadAnimation(Dance2Animation)
    local Greet = Character.Humanoid:LoadAnimation(GreetAnimation)
    local ChestPump = Character.Humanoid:LoadAnimation(ChestPumpAnimation)
    local Praying = Character.Humanoid:LoadAnimation(PrayingAnimation)
    local TheDefault = Character.Humanoid:LoadAnimation(TheDefaultAnimation)
    local Sturdy = Character.Humanoid:LoadAnimation(SturdyAnimation)
    local Rossy = Character.Humanoid:LoadAnimation(RossyAnimation)
    local Griddy = Character.Humanoid:LoadAnimation(GriddyAnimation)
    local TPose = Character.Humanoid:LoadAnimation(TPoseAnimation)
    local SpeedBlitz = Character.Humanoid:LoadAnimation(SpeedBlitzAnimation)

    AnimationPack.Visible = true
    AnimationPackPlus.Visible = true
    ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ScrollingFramePlus.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Rename buttons
    for i,v in pairs(ScrollingFrame:GetChildren()) do
        if v.Name == "TextButton" then
            if v.Text == "Lean" then v.Name = "LeanButton"
            elseif v.Text == "Lay" then v.Name = "LayButton"
            elseif v.Text == "Dance1" then v.Name = "Dance1Button"
            elseif v.Text == "Dance2" then v.Name = "Dance2Button"
            elseif v.Text == "Greet" then v.Name = "GreetButton"
            elseif v.Text == "Chest Pump" then v.Name = "ChestPumpButton"
            elseif v.Text == "Praying" then v.Name = "PrayingButton"
            end
        end
    end

    for i,v in pairs(ScrollingFramePlus:GetChildren()) do
        if v.Name == "TextButton" then
            if v.Text == "The Default" then v.Name = "TheDefaultButton"
            elseif v.Text == "Sturdy" then v.Name = "SturdyButton"
            elseif v.Text == "Rossy" then v.Name = "RossyButton"
            elseif v.Text == "Griddy" then v.Name = "GriddyButton"
            elseif v.Text == "T Pose" then v.Name = "TPoseButton"
            elseif v.Text == "Speed Blitz" then v.Name = "SpeedBlitzButton"
            end
        end
    end

    local function StopAll()
        Lean:Stop()
        Lay:Stop()
        Dance1:Stop()
        Dance2:Stop()
        Greet:Stop()
        ChestPump:Stop()
        Praying:Stop()
        TheDefault:Stop()
        Sturdy:Stop()
        Rossy:Stop()
        Griddy:Stop()
        TPose:Stop()
        SpeedBlitz:Stop()
    end

    local LeanTextButton = ScrollingFrame.LeanButton
    local LayTextButton = ScrollingFrame.LayButton
    local Dance1TextButton = ScrollingFrame.Dance1Button
    local Dance2TextButton = ScrollingFrame.Dance2Button
    local GreetTextButton = ScrollingFrame.GreetButton
    local ChestPumpTextButton = ScrollingFrame.ChestPumpButton
    local PrayingTextButton = ScrollingFrame.PrayingButton
    local TheDefaultTextButton = ScrollingFramePlus.TheDefaultButton
    local SturdyTextButton = ScrollingFramePlus.SturdyButton
    local RossyTextButton = ScrollingFramePlus.RossyButton
    local GriddyTextButton = ScrollingFramePlus.GriddyButton
    local TPoseTextButton = ScrollingFramePlus.TPoseButton
    local SpeedBlitzTextButton = ScrollingFramePlus.SpeedBlitzButton

    AnimationPack.MouseButton1Click:Connect(function()
        if ScrollingFrame.Visible == false then
            ScrollingFrame.Visible = true
            CloseButton.Visible = true
            AnimationPackPlus.Visible = false
        end
    end)
    
    AnimationPackPlus.MouseButton1Click:Connect(function()
        if ScrollingFramePlus.Visible == false then
            ScrollingFramePlus.Visible = true
            CloseButtonPlus.Visible = true
            AnimationPack.Visible = false
        end
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        if ScrollingFrame.Visible == true then
            ScrollingFrame.Visible = false
            CloseButton.Visible = false
            AnimationPackPlus.Visible = true
        end
    end)
    
    CloseButtonPlus.MouseButton1Click:Connect(function()
        if ScrollingFramePlus.Visible == true then
            ScrollingFramePlus.Visible = false
            CloseButtonPlus.Visible = false
            AnimationPack.Visible = true
        end
    end)
    
    LeanTextButton.MouseButton1Click:Connect(function() StopAll() Lean:Play() end)
    LayTextButton.MouseButton1Click:Connect(function() StopAll() Lay:Play() end)
    Dance1TextButton.MouseButton1Click:Connect(function() StopAll() Dance1:Play() end)
    Dance2TextButton.MouseButton1Click:Connect(function() StopAll() Dance2:Play() end)
    GreetTextButton.MouseButton1Click:Connect(function() StopAll() Greet:Play() end)
    ChestPumpTextButton.MouseButton1Click:Connect(function() StopAll() ChestPump:Play() end)
    PrayingTextButton.MouseButton1Click:Connect(function() StopAll() Praying:Play() end)
    TheDefaultTextButton.MouseButton1Click:Connect(function() StopAll() TheDefault:Play() end)
    SturdyTextButton.MouseButton1Click:Connect(function() StopAll() Sturdy:Play() end)
    RossyTextButton.MouseButton1Click:Connect(function() StopAll() Rossy:Play() end)
    GriddyTextButton.MouseButton1Click:Connect(function() StopAll() Griddy:Play() end)
    TPoseTextButton.MouseButton1Click:Connect(function() StopAll() TPose:Play() end)
    SpeedBlitzTextButton.MouseButton1Click:Connect(function() StopAll() SpeedBlitz:Play() end)

    Character.Humanoid.Running:Connect(function() StopAll() end)
end

DahoodAnimSection:AddButton({
	Name = "Animation Pack++",
	Callback = function()
		if not animationPackPlusEnabled then
			animationPackPlusEnabled = true
			SetupAnimationPackPlus(LocalPlayer.Character)
			LocalPlayer.CharacterAdded:Connect(SetupAnimationPackPlus)
		end
	end,
})


-- Hitbox Functions
function expandPlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local playerId = tostring(player.UserId)
        
        if not originalSizes[playerId] then
            originalSizes[playerId] = humanoidRootPart.Size
        end
        
        humanoidRootPart.Size = Vector3.new(Settings.hitboxSize, Settings.hitboxSize, Settings.hitboxSize)
        humanoidRootPart.Transparency = Settings.streamable and 1 or Settings.hitboxTransparency
        humanoidRootPart.CanCollide = false
        humanoidRootPart.Material = Enum.Material.ForceField
        humanoidRootPart.Color = Settings.hitboxColor
        
        if not Settings.streamable and not selectionBoxes[playerId] then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = humanoidRootPart
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 0
            highlight.OutlineColor = Settings.outlineColor
            highlight.Parent = humanoidRootPart
            selectionBoxes[playerId] = highlight
        elseif Settings.streamable and selectionBoxes[playerId] then
            selectionBoxes[playerId]:Destroy()
            selectionBoxes[playerId] = nil
        end
    end
end

function restorePlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local playerId = tostring(player.UserId)
        
        if originalSizes[playerId] then
            humanoidRootPart.Size = originalSizes[playerId]
            humanoidRootPart.Transparency = 1
            humanoidRootPart.CanCollide = false
            humanoidRootPart.Material = Enum.Material.Plastic
        end
        
        if selectionBoxes[playerId] then
            selectionBoxes[playerId]:Destroy()
            selectionBoxes[playerId] = nil
        end
    end
end

-- Keep hitboxes expanded when enabled
RunService.Heartbeat:Connect(function()
    if Settings.hitboxEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            expandPlayerHitbox(player)
        end
    end
end)

-- Car Speed function (moves player faster using CFrame when in vehicle)
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            -- Check if player is sitting in a vehicle
            if humanoid.Sit and humanoid.SeatPart then
                local seat = humanoid.SeatPart
                local vehicle = seat.Parent
                
                if Settings.carSpeed > 0 and vehicle then
                    -- Get movement direction from humanoid
                    local moveDirection = humanoid.MoveDirection
                    
                    if moveDirection.Magnitude > 0 then
                        -- Calculate speed multiplier (normalize to make it feel right)
                        local speedMultiplier = Settings.carSpeed / 16
                        
                        -- Move the character's root part in the direction they're moving
                        local moveSpeed = moveDirection * speedMultiplier
                        rootPart.CFrame = rootPart.CFrame + moveSpeed
                        
                        -- Also try to move the vehicle part if it exists
                        local vehiclePart = vehicle.PrimaryPart or vehicle:FindFirstChild("Body") or vehicle:FindFirstChild("Main")
                        if vehiclePart and vehiclePart:IsA("BasePart") then
                            vehiclePart.CFrame = vehiclePart.CFrame + moveSpeed
                        end
                    end
                end
            end
        end
    end
end)

-- WalkSpeed function
local originalWalkSpeed = 16

RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        
        -- WalkSpeed Toggle
        if walkSpeedToggle then
            if walkSpeedMode == "Always" then
                humanoid.WalkSpeed = walkSpeed
            elseif walkSpeedMode == "On Sprint" and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                humanoid.WalkSpeed = walkSpeed
            else
                humanoid.WalkSpeed = originalWalkSpeed
            end
        end
    end
end)

-- Spin Bot function
RunService.RenderStepped:Connect(function()
    if spinBotEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end
end)

-- FakePos function
RunService.Heartbeat:Connect(function()
    if fakePosEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
        end
    end
end)

-- Void Spam function
RunService.Heartbeat:Connect(function()
    if voidSpamEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            if voidSpamMode == "Always" or (voidSpamMode == "On Key" and UserInputService:IsKeyDown(Enum.KeyCode.X)) then
                character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -500, 0)
                wait(0.1)
                character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 500, 0)
            end
        end
    end
end)

-- Desync function
RunService.Heartbeat:Connect(function()
    if desyncEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            if desyncMode == "Custom" then
                character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
            elseif desyncMode == "Prediction" then
                character.HumanoidRootPart.Velocity = Vector3.new(9e9, 9e9, 9e9)
            end
        end
    end
end)

-- NoClip function
RunService.Stepped:Connect(function()
    if Settings.noClip then
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Character respawn handler (for Player tab features)
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    
    -- Reapply fly if enabled
    if flyEnabled then
        character:WaitForChild("Humanoid")
        character:WaitForChild("LowerTorso")
        wait(0.5)
        
        -- Stop old fly
        stopFly()
        
        -- Restart fly
        flying = true
        startFly()
    end
    
    -- Store original walkspeed
    if character:FindFirstChild("Humanoid") then
        originalWalkSpeed = character.Humanoid.WalkSpeed
    end
end)

-- Anti Pepperspray function
RunService.Heartbeat:Connect(function()
    if antiPepperSprayEnabled then
        -- Delete PepperSpray GUI
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local mainScreenGui = playerGui:FindFirstChild("MainScreenGui")
            if mainScreenGui then
                local pepperSpray = mainScreenGui:FindFirstChild("PepperSpray")
                if pepperSpray then
                    pepperSpray:Destroy()
                end
            end
        end
        
        -- Delete PepperSpray Blur
        local lighting = game:GetService("Lighting")
        local pepperSprayBlur = lighting:FindFirstChild("PepperSprayBlur")
        if pepperSprayBlur then
            pepperSprayBlur:Destroy()
        end
    end
end)

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if Settings.hitboxEnabled then
            expandPlayerHitbox(player)
        end
    end)
end)

-- Handle player respawning
for _, player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if Settings.hitboxEnabled then
            expandPlayerHitbox(player)
        end
    end)
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    originalSizes[playerId] = nil
    if selectionBoxes[playerId] then
        selectionBoxes[playerId]:Destroy()
        selectionBoxes[playerId] = nil
    end
end)

Notifier.new({
	Title = "Script Loaded",
	Content = "AntiV4 loaded successfully!",
	Duration = 5,
	Icon = "rbxassetid://120245531583106"
});

