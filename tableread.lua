--/waitfor typeof.lua
--/stop

-- usage: local str = tableread({'anything', 'here', 'even', 'metatables'}, {maxLevel = -1, comments = true, shouldGetPath = true, header = ''})

function reverseTable(t)local r={}for i=#t,1,-1 do r[#r+1]=t[i]end;return(r)end

--

local errMessage = {
	maxlevel = 'max level reached'
}

local nis = {}
local nisn = 0
local functions = {}
local functionsn = 0

function generateId(func)
	if func then
		return ('func-%x'):format(functionsn)
	end
	return ('nil-%x'):format(nisn)
end
function getnil(id)
	return nis[id]
end
function getfunction(id)
	return functions[id]
end
--

local customtypeof = typeof
local typeof = _typeof

function fix1(s)
	return (((((s
	:gsub('\\', '\\\\')
	:gsub('\t', '\\t'))
	:gsub('\n', '\\n'))
	:gsub('\v', '\\v'))
	:gsub('\f', '\\f'))
	:gsub('\r', '\\r'))
end

function fixString(s)
	local new = ''
	for _,v in pairs(s:split('')) do
		if (v:match('%c') or v:byte(1) >= 127 ) and not v:match('%s') then
			new..='\\' .. v:byte(1)
		elseif v:match('%s') then
			new..=fix1(v)
		else
			new..=v
		end
	end
	return new
end

local special = {
	[game] = 'game',
	[workspace.CurrentCamera] = 'workspace.CurrentCamera',
	[gethui()] = 'gethui()'
}

function getPath(ins: Instance)
	if typeof(ins) == 'nil' then warn('Instance is nil!')return end
	if typeof(ins) ~= 'Instance' then warn('Instance is not an Instance!')return end

	if special[ins] then return special[ins]end
	if nis[ins] then return ('tableread.getnil("%s")'):format(nis[ins])end

	local path = {}

	while true do
		if ins == game then table.insert(path, 'game')break;end
		if ins.Parent == nil then
			local id = generateId()
			nisn += 1
			nis[ins] = id
			table.insert(path, {id = id, instance = ins})
			break
		else
			table.insert(path, ins.Name)
		end

		ins = ins.Parent
	end
	path = reverseTable(path)

	local str = '.'
	local getService = false
	local dir

	for i,v in pairs(path) do
		if typeof(v) == 'table' then
			dir = v.instance
			str = ('tableread.getnil("%s")'):format(v.id)
			continue
		end
		if i == 1 and #path > 1 then
			if typeof(v) == 'table' and v.id then
				dir = v.instance
				str ..= 'tableread.getnil("' .. v.id .. '")'
				break
			end
			
			local ins = game:FindFirstChild(path[i + 1])
			if ins then
				local service = game:GetService(ins.ClassName)

				if service then
					if service == workspace then
						str ..= 'workspace'
					else
						str ..= 'game:GetService("' .. service.ClassName .. '")'
					end
					getService = true
					dir = service
				else
					str ..= 'game'
					dir = game
				end
			else
				dir = game
			end
		elseif i == 2 and getService then else
			local bl = "/.,?<>';\":\\[]|{}=-+!@#$%^&*()`~"

			local b = false
			for _,s in pairs(v:split('')) do
				if bl:find(s) then
					b = true break
				end
			end

			if b or v:find(' ') or v:find('\t') or tonumber(v:sub(1,1)) then
				local _v = v:gsub('\\', '\\\\'):gsub("\"", "\\\"")
				str ..= ('["%s"]'):format(_v)
			else
				str ..= '.' .. v
			end

			if dir.Parent == gethui() then
				str ..= '.gethui()'
				break
			else
				dir = dir[v]
			end
		end
	end
	
	return fixString(str:sub(2))
end

function str(val)
	local function round(v,n)n=10^n;return(math.round(v*n)/n)end
	local type = typeof(val)

	if type == 'Instance' then
		return getPath(val)
	elseif type == 'string' then
		return ('"%s"'):format(fixString(val):gsub('"', '\\"'))
	elseif type == 'Color3' then
		return ('Color3.fromHex("%s")'):format(val:ToHex():upper())
	elseif type == 'Vector2' then
		return ('Vector2.new(%s, %s)'):format(str(round(val.X, 8)), str(round(val.Y, 8)))
	elseif type == 'Vector3' then
		return ('Vector3.new(%s, %s, %s)'):format(str(round(val.X, 8)), str(round(val.Y, 8)), str(round(val.Z, 8)))
	elseif type == 'CFrame' then
		return ('CFrame.new(%s)'):format(tostring(val))
	elseif type == 'function' then
		if getfunction(val) then
			return 'tableread.getfunction("' .. getfunction(val) .. '")'
		end
		local id = generateId(true)
		functionsn += 1
		functions[id] = val
		functions[val] = id
		return 'tableread.getfunction("' .. id .. '")'
	elseif type == 'userdata' then
		return '"' .. tostring(val) .. '"'
	elseif type == 'number' then
		local str = tostring(val)
		if str == 'inf' then return '1/0'
		elseif str == '-inf' then return '-1/0'
		elseif str == 'nan' then return '0/0' end
	elseif type == 'Enums' then
		return 'Enum'
	elseif type == 'UDim' then
		return ('UDim.new(%s, %s)'):format(str(round(val.Offset, 8)), str(round(val.Scale, 8)))
	elseif type == 'UDim2' then
		return ('UDim2.new(%s, %s, %s, %s)'):format(
			str(round(val.X.Offset, 8)),
			str(round(val.X.Scale, 8)),
			str(round(val.Y.Offset, 8)),
			str(round(val.Y.Scale, 8))
			)
	end

	return tostring(val)
end

function tableread(t, config, _checked, level)
	if typeof(t) ~= 'table' then
		return str(t)
	end

	config = config or {}
		config.maxLevel = config.maxLevel or -1
		config.comments = config.comments == nil and true or config.comments
		config.shouldGetPath = config.shouldGetPath == nil and true or config.shouldGetPath
		config.header = config.header or ''

	local nothing=true
	for _,v in pairs(t) do nothing=false break end
	if(nothing)then return config.header .. ' {}';end

	level = level or 1
	local checked = _checked and _checked or {}
	
	if config.maxLevel > 0 and level > config.maxLevel then return'{}','maxlevel' end

	local ret = checked and '{\n' or ''

	if type(_checked) ~= 'table' then
		ret = config.header .. ' {\n'
	end
	
	local function add(i, v)
		local s, r = pcall(function()
			local ct = typeof(v) ~= customtypeof(v) and customtypeof(v)
			local idx = ('[%s]'):format(str(i, true))

			if typeof(v) == 'table' then
				if checked[str(v)] then
					ret ..= '\t' .. idx .. ' = {}, -- ' .. str(v) .. ' (recursion detected)\n'
				else
					checked[str(v)] = true
					local t_str, err = tableread(v, config, checked, level + 1)
					checked[str(v)] = nil

					ret ..= '\t' .. idx .. ' = '

					local i_ = 1
					for _,v in pairs(t_str:split('\n')) do
						if i_ > 1 then
							ret ..= '\t' .. v .. '\n'
						else
							ret ..= v .. '\n'
						end
						i_ += 1
					end
					
					local em
					if err and errMessage[err] then
						em = errMessage[err]
					end
					
					local comment = ' -- ' .. str(v) .. (em and '(' .. em .. ')' or '')
					local custom = ct and (' (Custom Type: ' .. ct .. ')') or ''
					
					local str = ret:sub(1, #ret - 1) .. ','
					str ..= config.comments and comment or ''
					str ..= config.comments and custom or ''
					
					ret = str .. '\n'
				end
			else
				local func = typeof(v) == 'function'
				
				local comment = ((func or ct) and ' -- ' .. tostring(v) or '') or ''
				local custom = ct and (' (Custom Type: ' .. ct .. ')') or ''
				
				local str = idx .. ' = ' .. str(v) .. ','
				str ..= config.comments and comment or ''
				str ..= config.comments and custom or ''
				
				ret ..= '\t' .. str .. '\n'
			end
		end)

		if not s then
			warn(r)
		end
	end

	for i, v in pairs(t) do
		add(i, v)
	end
	
	local mt = getrawmetatable(t)
	if mt ~= nil then
		add('@metatable', mt)
	end

	return ret .. '}'
end

local origTable
function iterate(t, func, config, _checked, level, path) -- iterate(table, (path: {any}, value: any) -> (setValue: boolean?, value: any)?, config: {maxLevel: number?}?) -> boolean?
	local nothing = true
	for i in pairs(t) do nothing = false break end
	if nothing then return end

	level = level or 1
	path = path or {}
	local checked = _checked and _checked or {}
	
	config = config or {}
		config.maxLevel = config.maxLevel or -1

	if level == 1 then origTable = t end

	if config.maxLevel > 0 and level > config.maxLevel then func(path, t) return end

	for i, v in pairs(t) do
		local s, r = pcall(function()
			path[#path + 1] = i
			
			if typeof(v) == 'table' then
				if checked[str(v)] == nil then
					checked[str(v)] = true
					iterate(v, func, config, checked, level + 1, path)
					checked[str(v)] = nil
				end
			else
				local setTo, value = func(path, v)
				if setTo == true then
					local dir = origTable
					for i,v in pairs(path) do
						if i == #path then dir[v] = value break end
						dir = dir[v]
					end
				end
			end
			
			path[#path] = nil
		end)

		if not s then
			warn(r)
		end
	end

	return true
end

getgenv().tableread = setmetatable({}, {
	__index = {
		getInstancePath = getPath,
		-- setHeader = setHeader,
		-- getHeader = getHeader,
		-- setMaxLevel = setMaxLevel,
		-- getMaxLevel = getMaxLevel,
		-- setShouldGetPath = setShouldGetPath,
		-- setComments = setComments,
		getfunction = getfunction,
		getnil = getnil,
		iterate = function(t, f)
			iterate(t, f)
		end
	},
	__call = function(self, t, p)return tableread(t, p)end
})