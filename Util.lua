--/waitfor LogAPI.lua
--/stop

function blank()end

function reverseTable(t)local r={}for i=#t,1,-1 do r[#r+1]=t[i]end;return(r)end
function deepcopy(orig, copies)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
			end
			setmetatable(copy, deepcopy(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function rotateVector(V: Vector3, Rotation: Vector3)
	local rad = math.pi/180
	local cf = CFrame.Angles(Rotation.X * rad, Rotation.Y * rad, Rotation.Z * rad)
	return (cf * CFrame.new(V)).Position
end

function d()assert(nil,'This object is destroyed!')end
function destroy(obj)
	if typeof(obj) == 'nil' then return end
	setrawmetatable(obj, {__index = d, __newindex = d})
end

function avarageVectors(Vectors: {Vector3})
	local min, max

	for _,v in pairs(Vectors) do
		if not min then
			min = v
		else
			if v.X < min.X then min = Vector3.new(v.X,min.Y,min.Z) end
			if v.Y < min.Y then min = Vector3.new(min.X, v.Y,min.Z) end
			if v.Z < min.Z then min = Vector3.new(min.X,min.Y,v.Z) end
		end

		if not max then
			max = v
		else
			if v.X > max.X then max = Vector3.new(v.X,max.Y,max.Z) end
			if v.Y > max.Y then max = Vector3.new(max.X, v.Y,max.Z) end
			if v.Z > max.Z then max = Vector3.new(max.X,max.Y,v.Z) end
		end	
	end

	min = min or Vector3.new()
	max = max or Vector3.new()

	return max:Lerp(min, 0.5)
end

local stepped = game:GetService('RunService').Stepped
function createCollider(params, touched, touchEnded)
	params = params or {}
	params.Size = params.Size or Vector3.new(5, 5, 5)
	params.Position = params.Position or Vector3.new()
	params.Rotation = params.Rotation or Vector3.new()
	-- CFrame is also supported (params.CFrame)

	touched = touched or blank
	touchEnded = touchEnded or blank

	local collider = {}

	local stop = false
	local pause = false

	local p = Instance.new('Part')
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = params.Size

	if params.CFrame then
		p.CFrame = params.CFrame
	else
		p.Position = params.Position
		p.Rotation = params.Rotation
	end

	p.Parent = workspace

	function collider:Start()
		pause = false
	end

	function collider:Stop()
		pause = true
	end

	function collider:Destroy()
		stop = true
		p:Destroy()
	end

	spawn(function()
		local touching = {}

		while not stop do
			if not pause then
				local touching2 = {}

				for _,v in pairs(workspace:GetPartsInPart(p)) do
					if not touching[v] then
						touching2[v] = true
					end
				end

				local function c(ins)
					if touching2[ins] and not touching[ins] then
						touchEnded(ins)
					end
					touching2[ins] = touching[ins]
				end

				for p in pairs(touching) do c(p)end
				for p in pairs(touching2) do c(p)end
			end

			stepped:Wait()
		end
	end)

	return collider
end

local faceOpposite = {
	[Enum.NormalId.Top] = Enum.NormalId.Bottom,
	[Enum.NormalId.Bottom] = Enum.NormalId.Top,
	[Enum.NormalId.Right] = Enum.NormalId.Left,
	[Enum.NormalId.Left] = Enum.NormalId.Right,
	[Enum.NormalId.Front] = Enum.NormalId.Back,
	[Enum.NormalId.Back] = Enum.NormalId.Front
}

local instancenamecall

do -- instance manipulation group
	local mt = getrawmetatable(game)
	setreadonly(mt, false)

	local instanceStorage = {}
	local methodStorage = {}

	local orig = mt.__namecall
	instancenamecall = orig
	mt.__namecall = function(...)
		local method = getnamecallmethod()
		
		if method ~= 'IsA' then
			local self = ...
		
			local t = methodStorage[method]
			if t then
				if self:IsA(t.class) then
					return t.callback(...)
				end
				
				setnamecallmethod(method)
			end
		end
		
		return orig(...)
	end

	local oldIndex = mt.__index
	mt.__index = function(s, k)
		if instanceStorage[s] and instanceStorage[s][k] ~= nil then return instanceStorage[s][k] end
		return oldIndex(s, k)
	end
	
	function setClassMethod(className, method, callback)
		assert(className ~= nil, 'Argument 1 missing or nil')
		assert(method ~= nil, 'Argument 2 missing or nil')
		
		if methodStorage[method] then
			warn(('Method "%s" alreay exists for class "%s"'):format(method, className))
			return
		end

		methodStorage[method] = {
			class = className,
			callback = callback
		}
	end

	function setInstanceProperty(instance: Instance, property, value)
		assert(false, 'disabled')
		assert(instance ~= nil, 'Argument 1 missing or nil')
		assert(property ~= nil, 'Argument 2 missing or nil')

		instanceStorage[instance] = instanceStorage[instance] or {}
		instanceStorage[instance][property] = value
	end
end

local validTypes = {
	["nil"] = true,
	["boolean"] = true,
	["number"] = true,
	["string"] = true,
	["function"] = true,
	["userdata"] = true,
	["thread"] = true,
	["table"] = true,
	
	["Axes"] = true;
	["BrickColor"] = true;
	["CatalogSearchParams"] = true;
	["CFrame"] = true;
	["Color3"] = true;
	["ColorSequence"] = true;
	["ColorSequenceKeypoint"] = true;
	["Content"] = true;
	["DateTime"] = true;
	["DockWidgetPluginGuiInfo"] = true;
	["Enum"] = true;
	["EnumItem"] = true;
	["Enums"] = true;
	["Faces"] = true;
	["FloatCurveKey"] = true;
	["Font"] = true;
	["Instance"] = true;
	["NumberRange"] = true;
	["NumberSequence"] = true;
	["NumberSequenceKeypoint"] = true;
	["OverlapParams"] = true;
	["PathWaypoint"] = true;
	["PhysicalProperties"] = true;
	["Random"] = true;
	["Ray"] = true;
	["RaycastParams"] = true;
	["RaycastResult"] = true;
	["RBXScriptConnection"] = true;
	["RBXScriptSignal"] = true;
	["Rect"] = true;
	["Region3"] = true;
	["Region3int16"] = true;
	["SharedTable"] = true;
	["TweenInfo"] = true;
	["UDim"] = true;
	["UDim2"] = true;
	["Vector2"] = true;
	["Vector2int16"] = true;
	["Vector3"] = true;
	["Vector3int16"] = true;
}

function makeAssert(idx: number, value, expected)
	assert(idx ~= nil, 'Argument 1 missing or nil')
	
	local eMsg
	local success = true
	
	if typeof(value) == 'nil' then
		eMsg = 'Argument ' .. idx .. ' missing or nil'
	else
		if typeof(expected) ~= 'nil' then
			assert(typeof(expected) == 'string', 'Invalid argument #3 (string expected, got ' .. typeof(expected) .. ')')
			assert(validTypes[expected], tostring(expected) .. ' is not a valid type')
			
			eMsg = 'Invalid argument #' .. idx .. ' (' .. expected .. ' expected, got ' .. typeof(value) .. ')'
		else
			eMsg = 'Argument ' .. idx .. ' missing or nil'
		end
	end
	
	return typeof(value) == expected, eMsg
end

function calculateNormal(A, B, C)
	assert(makeAssert(1, A, 'Vector3'))
	assert(makeAssert(2, B, 'Vector3'))
	
	return (B - A):Cross(C - A)
end

function propertyExists(instance, property)
	assert(makeAssert(1, instance, 'Instance'))
	assert(makeAssert(2, property, 'string'))
	
	return (pcall(function()
		return instance[property]
	end))
end

function lerp(a,b,t)return a+(b-a)*(1-t)end

function generateUrlParams(params: {[string | number]: string | number})
	local str = ''
	for param, value in pairs(params) do
		if typeof(param) ~= 'string' and typeof(param) ~= 'number' then
			warn('Unsupported param type "' .. typeof(value) .. '"')
			continue
		end
		if typeof(value) ~= 'string' and typeof(value) ~= 'number' then
			warn('Unsupported value type "' .. typeof(value) .. '"')
			continue
		end
		
		str ..= '&' .. param .. '=' .. http:UrlEncode(tostring(value))
	end
	return str:sub(2)
end

local genv = getgenv()

genv.genv = genv
genv.localplayer = game:GetService('Players').LocalPlayer

genv.Util = {
	deepcopy = deepcopy,
	reverseTable = reverseTable,
	rotateVector = rotateVector,
	destroy = destroy,
	avarageVectors = avarageVectors,
	blank = blank,
	createCollider = createCollider,
	faceOpposite = faceOpposite,
	setInstanceProperty = setInstanceProperty,
	validTypes = validTypes,
	makeAssert = makeAssert,
	calculateNormal = calculateNormal,
	propertyExists = propertyExists,
	lerp = lerp,
	generateUrlParams = generateUrlParams,
	setClassMethod = setClassMethod
}


-- globals

do -- Remote Analyzer (or remotespy) -- dont use this yet
	local analyzing = {}
	
	local __index = {}; __index.__index = __index do
		function __index:Start()
			self.Log = true
		end
		
		function __index:Stop()
			self.Log = false
		end
	end
	
	--[[
		setClassMethod('RemoteEvent', 'FireServer', function(self, ...)
			
			
			instancenamecall(self, ...)
		end)
	]]
	
	
	local function analyzingclass(remote)
		local self = {
			Remote = remote,
			Log = true
		}
		
		setmetatable(self, __index)
		
		if remote:IsA('RemoteEvent') then
			remote.OnClientEvent:Connect(function(...)
				if not self.Log then return end
				log(tableread({...}))
			end)
		end
		
		return self
	end
	
	function genv.spyremote(remote)
		makeAssert(1, remote, 'Instance')

		if analyzing[remote] then return end
		
		local a = analyzingclass(remote)
		analyzing[remote] = a
		
		return a
	end
end



