--[[
	Aim Category Content
	Loadstring-ready module
]]

-- Required services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Assume these are passed from main script (or create them here if needed)
-- You'll need to replace 'AimTab' and 'Notifier' with actual references
-- For now, this assumes they exist in the global scope

-- Kill Aura globals
getgenv().KillAuraUseAimbot = false
getgenv().KillAuraPrediction = 0.165

-- Rapid Fire Variables
local rapidFireRate = 0.05

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

