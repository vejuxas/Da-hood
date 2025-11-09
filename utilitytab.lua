-- Utility Tab Script (Loadstring Compatible)
-- Make sure UtilityTab is available from main script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get UtilityTab and Notifier from global environment
local UtilityTab = getgenv().UtilityTab
local Notifier = getgenv().Notifier

if not UtilityTab then
	warn("UtilityTab not found! Make sure it's created in main script.")
	return
end

-- Utility Left Section 1 - Anti Features
local UtilityAntiSection = UtilityTab:DrawSection({
	Name = "Anti Features",
	Position = 'left'
});

local antiSlowEnabled = false

UtilityAntiSection:AddToggle({
	Name = "Anti Slow",
	Flag = "AntiSlow",
	Default = false,
	Callback = function(v) 
		antiSlowEnabled = v
		
		if v then
			Notifier.new({
				Title = "Anti Slow",
				Content = "Anti Slow enabled!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Anti Slow",
				Content = "Anti Slow disabled!",
				Duration = 2
			});
		end
	end,
});

local antiStompEnabled = false

UtilityAntiSection:AddToggle({
	Name = "Anti stomp",
	Flag = "AntiStompUtil",
	Default = false,
	Callback = function(v) 
		antiStompEnabled = v
		
		if v then
			Notifier.new({
				Title = "Anti Stomp",
				Content = "Anti Stomp enabled! Will auto reset when knocked.",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Anti Stomp",
				Content = "Anti Stomp disabled!",
				Duration = 2
			});
		end
	end,
});

local antiVoidEnabled = false

UtilityAntiSection:AddToggle({
	Name = "Anti Void",
	Flag = "AntiVoid",
	Default = false,
	Callback = function(v) 
		antiVoidEnabled = v
		
		if v then
			Notifier.new({
				Title = "Anti Void",
				Content = "Anti Void enabled! You won't fall through the map.",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Anti Void",
				Content = "Anti Void disabled!",
				Duration = 2
			});
		end
	end,
});

-- Utility Left Section 2 - Aspect Ratio
local UtilityAspectSection = UtilityTab:DrawSection({
	Name = "Aspect Ratio",
	Position = 'left'
});

UtilityAspectSection:AddParagraph({
	Title = "COMING SOON",
	Content = "Currently under development."
});

-- Utility Left Section 3 - Visual
local UtilityVisualSection = UtilityTab:DrawSection({
	Name = "Visual",
	Position = 'left'
});

local noFog = false
local fovToggle = false
local fovSlider = 70

UtilityVisualSection:AddToggle({
	Name = "No fog",
	Flag = "NoFog",
	Default = false,
	Callback = function(v) 
		noFog = v
		
		if v then
			game.Lighting.GlobalShadows = true
			game.Lighting.Ambient = Color3.new(0, 0, 0)
			game.Lighting.FogEnd = 10000000
			
			Notifier.new({
				Title = "No Fog",
				Content = "Fog removed!",
				Duration = 2
			});
		else
			-- Reset to defaults
			game.Lighting.GlobalShadows = false
			game.Lighting.Ambient = Color3.new(0, 0, 0)
			game.Lighting.FogEnd = 100000
			
			Notifier.new({
				Title = "No Fog",
				Content = "Fog restored!",
				Duration = 2
			});
		end
	end,
});

UtilityVisualSection:AddToggle({
	Name = "FOV Toggle",
	Flag = "FovToggle",
	Default = false,
	Callback = function(v) 
		fovToggle = v
		
		if v then
			Camera.FieldOfView = fovSlider
			
			Notifier.new({
				Title = "FOV",
				Content = "Custom FOV enabled!",
				Duration = 2
			});
		else
			Camera.FieldOfView = 70 -- Reset to default
			
			Notifier.new({
				Title = "FOV",
				Content = "FOV reset to default!",
				Duration = 2
			});
		end
	end,
});

UtilityVisualSection:AddSlider({
	Name = "FOV Amount",
	Min = 1,
	Max = 120,
	Default = 70,
	Round = 0,
	Flag = "FovSlider",
	Callback = function(v) 
		fovSlider = v
		if fovToggle then
			Camera.FieldOfView = fovSlider
		end
	end
});

-- Utility Right Section 1 - Auto Features
local UtilityAutoSection = UtilityTab:DrawSection({
	Name = "Auto Features",
	Position = 'right'
});

local autoStompEnabled = false
local lastTargetShot = nil
local autoReloadEnabled = false
local lastReload = 0
local reloadCooldown = 0.5

UtilityAutoSection:AddToggle({
	Name = "Auto Stomp",
	Flag = "UtilityAutoStomp",
	Default = false,
	Callback = function(v) 
		autoStompEnabled = v
		
		if v then
			Notifier.new({
				Title = "Auto Stomp",
				Content = "Will stomp target you're shooting at!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Auto Stomp",
				Content = "Auto Stomp disabled!",
				Duration = 2
			});
		end
	end,
});

UtilityAutoSection:AddToggle({
	Name = "Auto Reload",
	Flag = "UtilityAutoReload",
	Default = false,
	Callback = function(v) 
		autoReloadEnabled = v
		
		if v then
			Notifier.new({
				Title = "Auto Reload",
				Content = "Auto Reload enabled!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Auto Reload",
				Content = "Auto Reload disabled!",
				Duration = 2
			});
		end
	end,
});

-- Utility Right Section 2 - Gear
local UtilityGearSection = UtilityTab:DrawSection({
	Name = "Gear",
	Position = 'right'
});

local autoArmorEnabled = false
local autoMaskEnabled = false
local buyArmor
local buyMask
local lastArmorValue = nil
local maskWasEquipped = false

UtilityGearSection:AddToggle({
	Name = "Auto Armor",
	Flag = "AutoArmor",
	Default = false,
	Callback = function(v) 
		autoArmorEnabled = v
		
		if v then
			-- Buy armor immediately when toggled on
			task.spawn(function()
				task.wait(0.5)
				if buyArmor then
					buyArmor()
				end
			end)
			
			-- Reset tracking
			lastArmorValue = nil
			
			Notifier.new({
				Title = "Auto Armor",
				Content = "Auto Armor enabled!",
				Duration = 2
			});
		else
			-- Reset tracking when disabled
			lastArmorValue = nil
			
			Notifier.new({
				Title = "Auto Armor",
				Content = "Auto Armor disabled!",
				Duration = 2
			});
		end
	end,
});

UtilityGearSection:AddToggle({
	Name = "Auto mask",
	Flag = "AutoMask",
	Default = false,
	Callback = function(v) 
		autoMaskEnabled = v
		
		if v then
			-- Reset tracking
			maskWasEquipped = false
			
			-- Try to equip mask immediately when toggled on
			task.spawn(function()
				task.wait(0.5)
				if buyMask then
					buyMask()
				end
			end)
			
			Notifier.new({
				Title = "Auto Mask",
				Content = "Auto Mask enabled!",
				Duration = 2
			});
		else
			-- Reset tracking when disabled
			maskWasEquipped = false
			
			Notifier.new({
				Title = "Auto Mask",
				Content = "Auto Mask disabled!",
				Duration = 2
			});
		end
	end,
});

-- Utility Right Section 3 - Cash
local UtilityCashSection = UtilityTab:DrawSection({
	Name = "Cash",
	Position = 'right'
});

local autoDropCashEnabled = false

UtilityCashSection:AddToggle({
	Name = "Auto drop cash",
	Flag = "AutoDropCash",
	Default = false,
	Callback = function(v) 
		autoDropCashEnabled = v
		
		if v then
			Notifier.new({
				Title = "Auto Drop Cash",
				Content = "Auto Drop Cash enabled!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Auto Drop Cash",
				Content = "Auto Drop Cash disabled!",
				Duration = 2
			});
		end
	end,
});

-- Utility Right Section 4 - Anti Combat
local UtilityAntiSection2 = UtilityTab:DrawSection({
	Name = "Anti Combat",
	Position = 'right'
});

local antiSitEnabled = false

UtilityAntiSection2:AddToggle({
	Name = "Anti Sit",
	Flag = "AntiSit",
	Default = false,
	Callback = function(v) 
		antiSitEnabled = v
		
		if v then
			Notifier.new({
				Title = "Anti Sit",
				Content = "Anti Sit enabled!",
				Duration = 2
			});
		else
			Notifier.new({
				Title = "Anti Sit",
				Content = "Anti Sit disabled!",
				Duration = 2
			});
		end
	end,
});

UtilityAntiSection2:AddParagraph({
	Title = "COMING SOON",
	Content = "Currently under development."
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

-- ===== UTILITY TAB LOOPS AND FUNCTIONS =====

-- Anti Slow function
RunService.Heartbeat:Connect(function()
	if antiSlowEnabled then
		local character = LocalPlayer.Character
		if character then
			local bodyEffects = character:FindFirstChild("BodyEffects")
			if bodyEffects then
				local movement = bodyEffects:FindFirstChild("Movement")
				if movement then
					-- Reset slowdown effect
					movement.Value = 0
				end
				
				-- Also check for "Reload" slowdown
				local reload = bodyEffects:FindFirstChild("Reload")
				if reload then
					reload.Value = false
				end
			end
			
			-- Ensure normal walkspeed isn't affected
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid.WalkSpeed < 16 then
				humanoid.WalkSpeed = 16
			end
		end
	end
end)

-- Anti Stomp function (force reset immediately when knocked)
RunService.Heartbeat:Connect(function()
	if antiStompEnabled then
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			local bodyEffects = character:FindFirstChild("BodyEffects")
			
			if humanoid and bodyEffects then
				local ko = bodyEffects:FindFirstChild("K.O")
				
				-- Reset ONLY when knocked
				if ko and ko.Value == true then
					-- Force reset immediately to avoid stomp
					humanoid.Health = 0
				end
			end
		end
	end
end)

-- Anti Void function
local lastSafePosition = nil

RunService.Heartbeat:Connect(function()
	if antiVoidEnabled then
		local character = LocalPlayer.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			
			if hrp then
				-- Check if player is falling into void (Y position below -50)
				if hrp.Position.Y > -50 then
					-- Store last safe position
					lastSafePosition = hrp.CFrame
				elseif hrp.Position.Y <= -50 and lastSafePosition then
					-- Teleport back to last safe position
					hrp.CFrame = lastSafePosition
				end
			end
		end
	end
end)

-- Auto Stomp - Track shooting target and stomp when knocked
local function getClosestPlayerToCursor()
	local closestPlayer = nil
	local shortestDistance = math.huge
	
	local UserInputService = game:GetService("UserInputService")
	local mousePos = UserInputService:GetMouseLocation()
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local character = player.Character
			local humanoid = character:FindFirstChild("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and hrp and humanoid.Health > 0 then
				local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
				
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					
					if distance < shortestDistance and distance < 500 then -- Within 500 pixels
						shortestDistance = distance
						closestPlayer = player
					end
				end
			end
		end
	end
	
	return closestPlayer
end

-- Detect shooting to track target
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and autoStompEnabled then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Player is shooting, get closest player to cursor
			local target = getClosestPlayerToCursor()
			if target then
				lastTargetShot = target
			end
		end
	end
end)

-- Monitor target for knock and auto stomp
RunService.Heartbeat:Connect(function()
	if autoStompEnabled and lastTargetShot then
		local character = LocalPlayer.Character
		local target = lastTargetShot
		
		if character and target and target.Character then
			local myHrp = character:FindFirstChild("HumanoidRootPart")
			local targetChar = target.Character
			local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
			local targetBodyEffects = targetChar:FindFirstChild("BodyEffects")
			
			if myHrp and targetHrp and targetBodyEffects then
				local ko = targetBodyEffects:FindFirstChild("K.O")
				
				-- Check if target is knocked
				if ko and ko.Value == true then
					-- Teleport to target and stomp
					local oldPos = myHrp.CFrame
					myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 2, 0)
					task.wait(0.1)
					
					-- Fire stomp remote
					local stompRemote = ReplicatedStorage:FindFirstChild("MainEvent")
					if stompRemote then
						stompRemote:FireServer("Stomp")
					end
					
					task.wait(0.2)
					myHrp.CFrame = oldPos
					
					-- Clear target after stomping
					lastTargetShot = nil
				end
			end
		end
	end
end)

-- FOV Update Loop
RunService.RenderStepped:Connect(function()
	if fovToggle then
		Camera.FieldOfView = fovSlider
	end
end)

-- Auto Reload Helper Functions
local VirtualInputManager = game:GetService("VirtualInputManager")
local weaponNames = {
	"[Glock]", "[Silencer]", "[Shotgun]", "[Rifle]", "[SMG]", "[AR]",
	"[RPG]", "[GrenadeLauncher]", "[P90]", "[SilencerAR]", "[Revolver]",
	"[AK47]", "[TacticalShotgun]", "[DrumGun]", "[Flamethrower]",
	"[AUG]", "[LMG]", "[Double-Barrel SG]", "[Drum-Shotgun]", "[Flintlock]"
}

local function getCurrentTool()
	local character = LocalPlayer.Character
	if not character then return nil end
	
	-- Check for standard tool
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	
	-- Check for custom weapons (game-specific)
	for _, weaponName in pairs(weaponNames) do
		local weapon = character:FindFirstChild(weaponName)
		if weapon then
			return weapon
		end
	end
	
	return nil
end

local function getAmmo(tool)
	if not tool then return nil, nil end
	
	-- Method 1: Check for Ammo IntValue
	local ammo = tool:FindFirstChild("Ammo")
	if ammo and ammo:IsA("IntValue") then
		return ammo.Value, ammo
	end
	
	-- Method 2: Check for Ammo NumberValue
	if ammo and ammo:IsA("NumberValue") then
		return ammo.Value, ammo
	end
	
	-- Method 3: Check in tool's children recursively
	for _, child in pairs(tool:GetDescendants()) do
		if child.Name == "Ammo" and (child:IsA("IntValue") or child:IsA("NumberValue")) then
			return child.Value, child
		end
	end
	
	return nil, nil
end

local function reloadWeapon()
	local currentTime = tick()
	if currentTime - lastReload < reloadCooldown then
		return false
	end
	lastReload = currentTime
	
	local tool = getCurrentTool()
	if not tool then return false end
	
	-- Method 1: Press R key
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
	end)
	
	-- Method 2: Fire reload remote if it exists
	pcall(function()
		local reloadRemote = tool:FindFirstChild("RemoteEvent", true)
		if reloadRemote and reloadRemote:IsA("RemoteEvent") then
			reloadRemote:FireServer("Reload")
		end
	end)
	
	return true
end

-- Auto Reload Loop
RunService.RenderStepped:Connect(function()
	if not autoReloadEnabled then return end
	
	local tool = getCurrentTool()
	if not tool then return end
	
	local ammoValue, ammoObject = getAmmo(tool)
	
	-- Only reload when ammo is at or below 0
	if ammoValue and ammoValue <= 0 then
		reloadWeapon()
	end
end)

-- Auto Armor Function
local lastArmorBuy = 0
local armorBuyCooldown = 3

buyArmor = function()
	local currentTime = tick()
	if currentTime - lastArmorBuy < armorBuyCooldown then
		return false
	end
	
	local character = LocalPlayer.Character
	if not character then return false end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	
	-- Find armor in shop
	local armorShop = workspace.Ignored.Shop:FindFirstChild("[High-Medium Armor] - $2513")
	if not armorShop then return false end
	
	local armorHead = armorShop:FindFirstChild("Head")
	local clickDetector = armorShop:FindFirstChild("ClickDetector")
	
	if not armorHead or not clickDetector then return false end
	
	-- Save current position
	local oldPos = hrp.CFrame
	
	-- Teleport to armor
	hrp.CFrame = armorHead.CFrame * CFrame.new(0, 3, 0)
	task.wait(0.2)
	
	-- Click to buy
	pcall(function()
		fireclickdetector(clickDetector)
	end)
	
	task.wait(0.2)
	
	-- Teleport back
	hrp.CFrame = oldPos
	
	lastArmorBuy = currentTime
	return true
end

-- Auto Armor Loop - Buy when hit
RunService.Heartbeat:Connect(function()
	if not autoArmorEnabled then return end
	
	local character = LocalPlayer.Character
	if not character then return end
	
	local bodyEffects = character:FindFirstChild("BodyEffects")
	if not bodyEffects then return end
	
	local armor = bodyEffects:FindFirstChild("Armor")
	if not armor then return end
	
	local currentArmor = armor.Value
	
	-- Initialize last armor value if not set
	if lastArmorValue == nil then
		lastArmorValue = currentArmor
	end
	
	-- Check if armor decreased (player got hit)
	if currentArmor < lastArmorValue then
		-- Armor decreased, buy new armor
		buyArmor()
	end
	
	-- Update last armor value
	lastArmorValue = currentArmor
end)

-- Auto Mask Function
local lastMaskBuy = 0
local maskBuyCooldown = 2
local maskName = "[Mask]"

buyMask = function()
	local currentTime = tick()
	if currentTime - lastMaskBuy < maskBuyCooldown then
		return false
	end
	
	local character = LocalPlayer.Character
	if not character then return false end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	
	local backpack = LocalPlayer.Backpack
	if not backpack then return false end
	
	-- Check if mask is already equipped
	local equippedMask = character:FindFirstChild(maskName)
	if equippedMask then
		lastMaskBuy = currentTime
		maskWasEquipped = true
		return true -- Already equipped
	end
	
	-- Check if mask is in backpack
	local maskInBackpack = backpack:FindFirstChild(maskName)
	
	if not maskInBackpack then
		-- Need to buy mask from shop
		local maskShop = workspace.Ignored.Shop:GetChildren()[105]
		if not maskShop then return false end
		
		local maskHead = maskShop:FindFirstChild("Head")
		local clickDetector = maskShop:FindFirstChild("ClickDetector")
		
		if not maskHead or not clickDetector then return false end
		
		-- Save current position
		local oldPos = hrp.CFrame
		
		-- Teleport to mask shop
		hrp.CFrame = maskHead.CFrame * CFrame.new(0, 3, 0)
		task.wait(0.2)
		
		-- Buy mask
		pcall(function()
			fireclickdetector(clickDetector)
		end)
		
		task.wait(0.2)
		
		-- Teleport back
		hrp.CFrame = oldPos
		
		task.wait(0.3)
		
		-- Check if mask is now in backpack
		maskInBackpack = backpack:FindFirstChild(maskName)
	end
	
	-- Equip mask from backpack
	if maskInBackpack then
		pcall(function()
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:EquipTool(maskInBackpack)
			end
		end)
		
		task.wait(0.2)
		
		-- Find the equipped mask in character and activate it
		local equippedMask = character:FindFirstChild(maskName)
		if equippedMask and equippedMask:IsA("Tool") then
			-- Method 1: Activate the tool
			pcall(function()
				equippedMask:Activate()
			end)
			
			task.wait(0.1)
			
			-- Method 2: Fire remote if it exists
			pcall(function()
				local remote = equippedMask:FindFirstChild("RemoteEvent", true)
				if remote then
					remote:FireServer()
				end
			end)
			
			-- Method 3: Click any ClickDetector in the tool
			pcall(function()
				for _, child in pairs(equippedMask:GetDescendants()) do
					if child:IsA("ClickDetector") then
						fireclickdetector(child)
						break
					end
				end
			end)
			
			-- Mark mask as equipped after activation
			maskWasEquipped = true
		end
	end
	
	lastMaskBuy = currentTime
	return true
end

-- Auto Mask Loop - Always check if mask is equipped
RunService.Heartbeat:Connect(function()
	if not autoMaskEnabled then 
		maskWasEquipped = false
		return 
	end
	
	local character = LocalPlayer.Character
	if not character then return end
	
	-- Check if mask is equipped
	local equippedMask = character:FindFirstChild(maskName)
	
	if equippedMask then
		-- Mask is equipped, mark it
		maskWasEquipped = true
	else
		-- Mask is not equipped
		if maskWasEquipped then
			-- Mask was equipped but now it's not (got stomped or unequipped)
			-- Buy/equip it again
			buyMask()
		else
			-- Mask was never equipped, try to equip it
			buyMask()
		end
		maskWasEquipped = false
	end
end)

-- Auto Drop Cash Loop
RunService.Heartbeat:Connect(function()
	if not autoDropCashEnabled then return end
	
	-- Check if player has DataFolder with Currency
	local dataFolder = LocalPlayer:FindFirstChild("DataFolder")
	if not dataFolder then return end
	
	local currency = dataFolder:FindFirstChild("Currency")
	if not currency then return end
	
	-- Determine drop amount
	local dropAmount
	if currency.Value > 15000 then
		dropAmount = '15000'
	else
		dropAmount = tostring(currency.Value)
	end
	
	-- Drop cash using MainEvent
	pcall(function()
		local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
		if mainEvent then
			mainEvent:FireServer('DropMoney', dropAmount)
		end
	end)
end)

-- Anti Sit - Prevent sitting
local function setupAntiSit(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	humanoid.Seated:Connect(function(active, seat)
		if antiSitEnabled then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

-- Setup anti sit for current character
if LocalPlayer.Character then
	setupAntiSit(LocalPlayer.Character)
end

-- Setup anti sit for future characters (respawn)
LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	setupAntiSit(character)
end)

print("[Utility Tab] Loaded successfully!")

