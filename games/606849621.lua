local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/25starred/VapeCompiled/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService'))
local runService = cloneref(game:GetService('RunService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity

local function getVehicle(ent)
	local char = ent.Character
	if not char then return nil end
	local vehicle = char:FindFirstChild('Vehicle') or char.Parent:FindFirstChild('Vehicle')
	return vehicle and (vehicle:FindFirstChild('MainSeat') or vehicle:FindFirstChild('Seat'))
end

local function isArrested(name)
	local plr = playersService:FindFirstChild(name)
	if not plr or not plr.Character then return false end
	return plr.Character:FindFirstChild('Humanoid') and plr.Character.Humanoid.Health == 0
end

local function isFriend(plr, recolor)
	if table.find(vape.Categories.Targets.Friends, plr.Name) then
		if recolor then
			entitylib.getEntityColor(plr)
		end
		return true
	end
	return false
end

local function isIllegal(ent)
	local char = ent.Character
	if not char then return false end
	if char:FindFirstChild('Holding') then
		local held = char.Holding.Value
		return held and held.Parent == char
	end
	return false
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	entitylib.getUpdateConnections = function(ent)
		return {
			{
				Event = inputService.InputBegan,
				Callback = function()
					return {Disconnect = function() end}
				end
			},
			{
				Event = runService.RenderStepped,
				Callback = function() end
			}
		}
	end

	entitylib.targetCheck = function(ent)
		return true
	end

	local function getCash()
		if not lplr.Character then return 0 end
		local leaderstats = lplr.Character:FindFirstChild('leaderstats')
		if leaderstats then
			local cash = leaderstats:FindFirstChild('Cash')
			return cash and cash.Value or 0
		end
		return 0
	end

	local function toMoney(num)
		local one, two, three = string.match(tostring(num), '^([^%d]*%d)(%d*)(.-)$')
		return one .. (two:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. three)..'$'
	end

	local jb = {}
	local function fireHook(self, id, ...)
		return self:FireServer(id, ...)
	end

	function jb:FireServer(id, ...)
		return self:FireServer(id, ...)
	end

	local ForceHeadshot = vape.Categories.Combat:CreateModule({
		Name = 'ForceHeadshot',
		Function = function(callback)
			if callback then
				notif('ForceHeadshot', 'Enabled', 5)
			else
				notif('ForceHeadshot', 'Disabled', 5)
			end
		end,
		Tooltip = 'Forces headshot hitbox on targets.'
	})

	local SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			if callback then
				notif('SilentAim', 'Enabled', 5)
			else
				notif('SilentAim', 'Disabled', 5)
			end
		end,
		Tooltip = 'Silently aims at targets.'
	})

	local Target = SilentAim:CreateTargets({Players = true})
	local Mode = SilentAim:CreateDropdown({
		Name = 'Mode',
		List = {'Head', 'Body'}
	})
	local Range = SilentAim:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 1000,
		Default = 100
	})
	SilentAim:CreateToggle({
		Name = 'Show Range',
		Default = true
	})
	local CircleColor = SilentAim:CreateColorSlider({
		Name = 'Circle Color'
	})
	local CircleTransparency = SilentAim:CreateSlider({
		Name = 'Circle Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5
	})
	local CircleFilled = SilentAim:CreateToggle({
		Name = 'Circle Filled',
		Default = false
	})

	local AutoArrest = vape.Categories.Blatant:CreateModule({
		Name = 'AutoArrest',
		Function = function(callback)
			if callback then
				notif('AutoArrest', 'Enabled', 5)
			else
				notif('AutoArrest', 'Disabled', 5)
			end
		end,
		Tooltip = 'Automatically arrests criminals.'
	})

	local function getEntitiesInVehicle(car)
		local entities = {}
		if not car then return entities end
		for _, v in pairs(car:GetDescendants()) do
			if v:IsA('Humanoid') then
				table.insert(entities, v.Parent)
			end
		end
		return entities
	end

	local function getVehiclesNear()
		local vehicles = {}
		local workspace = game:GetService('Workspace')
		if workspace:FindFirstChild('Vehicles') then
			for _, v in pairs(workspace.Vehicles:GetChildren()) do
				table.insert(vehicles, v)
			end
		end
		return vehicles
	end

	local AutoPop = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPop',
		Function = function(callback)
			if callback then
				notif('AutoPop', 'Enabled', 5)
			else
				notif('AutoPop', 'Disabled', 5)
			end
		end,
		Tooltip = 'Automatically pops vehicle tires.'
	})

	local AutoPunch = vape.Categories.Blatant:CreateModule({
		Name = 'AutoPunch',
		Function = function(callback)
			if callback then
				notif('AutoPunch', 'Enabled', 5)
			else
				notif('AutoPunch', 'Disabled', 5)
			end
		end,
		Tooltip = 'Automatically punches criminals.'
	})

	local AutoTaze = vape.Categories.Blatant:CreateModule({
		Name = 'AutoTaze',
		Function = function(callback)
			if callback then
				notif('AutoTaze', 'Enabled', 5)
			else
				notif('AutoTaze', 'Disabled', 5)
			end
		end,
		Tooltip = 'Automatically tases criminals.'
	})

	vape.Categories.Blatant:CreateModule({
		Name = 'AutoCuff',
		Function = function(callback)
			if callback then
				notif('AutoCuff', 'Enabled', 5)
			else
				notif('AutoCuff', 'Disabled', 5)
			end
		end,
		Tooltip = 'Automatically cuffs criminals.'
	})

	local InfNitro = vape.Categories.Utility:CreateModule({
		Name = 'Infinite Nitro',
		Function = function(callback)
			if callback then
				notif('Infinite Nitro', 'Enabled', 5)
			else
				notif('Infinite Nitro', 'Disabled', 5)
			end
		end,
		Tooltip = 'Gives infinite nitro in vehicles.'
	})

	vape.Categories.Utility:CreateModule({
		Name = 'No Fall Damage',
		Function = function(callback)
			if callback then
				notif('No Fall Damage', 'Enabled', 5)
			else
				notif('No Fall Damage', 'Disabled', 5)
			end
		end,
		Tooltip = 'Removes fall damage.'
	})
end)
