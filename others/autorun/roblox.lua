util = {}
util.allocateMemory = allocateMemory;
util.startThread = executeCode;
util.freeMemory = deAlloc;

local quite = true

local fprint = print -- forceprint (ignores quite)
local print = print
if quite then
	print = function()end
end

function clearOutput()
	GetLuaEngine().MenuItem5.doClick()
end

function replaceString(string_in,string_out,ignore_length)
	local bytes_in = {};
	local bytes_out = {};
	for i=1,(#string_in >= #string_out and #string_in or #string_out) do -- lazy to copy paste same loop for string_out so just looping both and inserting if possible
		if (i <= #string_in) then
			table.insert(bytes_in,string.format("%x", tonumber(string.byte(string.sub(string_in,i,i)))));
		end
		if (i <= #string_out) then
			table.insert(bytes_out,tonumber(string.byte(string.sub(string_out,i,i))));
		end
	end

	local object = AOBScan(table.concat(bytes_in," "));
	if object then
		for entry = 0, object.Count -1 do
			local str = readString(object.getString(entry), 1000);

			if str then
				writeBytes(object.getString(entry), unpack(bytes_out));
			end
		end
		object.destroy();
		return true
	end
	return false
end -- from forum post :skull:

local function ExecuteString(str)
	str = str .. string.rep(" ", (999 - #str)) .. string.char(0);

	return str;
end

util.aobScan = function(aob, code)
	local new_results = {}
	local results = AOBScan(aob, "*X*C*W")
	if not results then
		return new_results
	end
	for i = 1,results.Count do
		local x = getAddress(results[i - 1])
		table.insert(new_results, x)
	end
	return new_results
end

util.intToBytes = function(val)
	if val == nil then
		error'Cannot convert nil value to byte table'
	end
	local t = { val & 0xFF }
	for i = 1,7 do
		table.insert(t, (val >> (8 * i)) & 0xFF)
	end
	return t
end

util.stringToBytes = function(str)
	local result = {}
	for i = 1, #str do
		table.insert(result, string.byte(str, i))
	end
	return result
end

util.bytesToString = function(b)
	local result = ""
	for i = 1, #b do
		result = result .. string.char(b[i])
	end
	return result
end

local strexecg, game = ''


local players, nameOffset, valid, game, parentOffset, childrenOffset, dataModel, childrenOffset, localPlayerOffset, localPlayer

local rapi = {}
rapi.toInstance = function(address)
	return setmetatable({}, {
		__index = function(self, name)
			if name == "self" then
				return address
			elseif name == "Name" then
				local ptr = readQword(self.self + nameOffset)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end

					if readString(readQword(ptr)) then
						return readString(readQword(ptr))
					end

					return readString(ptr)
				else
					return "???"
				end
			elseif name == "JobId" then
				if self.self == dataModel then
					return readString(readQword(dataModel + jobIdOffset))
				end

				return self:findFirstChild(name)
			elseif name == "className" or name == "ClassName" then
				local ptr = readQword(self.self + 0x18) or 0
				ptr = readQword(ptr + 0x8)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end
					return readString(ptr)
				else
					return "???"
				end
			elseif name == "Parent" then
				return rapi.toInstance(readQword(self.self + parentOffset))
			elseif name == "getChildren" or name == "GetChildren" then
				return function(self)
					local instances = {}
					local ptr = readQword(self.self + childrenOffset)
					if ptr then
						local childrenStart = readQword(ptr + 0)
						local childrenEnd = readQword(ptr + 8)
						local at = childrenStart
						if not at or not childrenEnd then
							return instances
						end
						while at < childrenEnd do
							local child = readQword(at)
							table.insert(instances, rapi.toInstance(child))
							at = at + 16
						end
					end
					return instances
				end
			elseif name == "findFirstChild" or name == "FindFirstChild" then
				return function(self, name)
					for _, v in pairs(self:getChildren()) do
						if v.Name == name then
							return v
						end
					end
					return nil
				end
			elseif name == "findFirstClass" or name == "FindFirstClass" then
				return function(self, name)
					for _, v in pairs(self:getChildren()) do
						if v.className == name then
							return v
						end
					end
					return nil
				end
			elseif name == "setParent" or name == "SetParent" then
				return function(self, other)

					writeQword(self.self + parentOffset, other.self)

					local newChildren = util.allocateMemory(0x400)
					writeQword(newChildren + 0, newChildren + 0x40)

					local ptr = readQword(other.self + childrenOffset)
					local childrenStart = readQword(ptr + 0)
					local childrenEnd = readQword(ptr + 8)
					if not childrenEnd then
						childrenEnd = 0
					end
					if not childrenStart then
						childrenStart = 0
					end
					local b = readBytes(childrenStart, childrenEnd - childrenStart, true)
					writeBytes(newChildren + 0x40, b)
					local e = newChildren + 0x40 + (childrenEnd - childrenStart)
					writeQword(e, self.self)
					writeQword(e + 8, readQword(self.self + 0x10))
					e = e + 0x10

					writeQword(newChildren + 0x8, e)
					writeQword(newChildren + 0x10, e)

					print("Set parent")
				end
			elseif name == "value" or name == "Value" then
				if self.className == "StringValue" then
					return readString(self.self + 0xC0)
				elseif self.className == "BoolValue" then
					return readByte(self.self + 0xC0) == 1
				elseif self.className == "IntValue" then
					return readInteger(self.self + 0xC0)
				elseif self.className == "NumberValue" then
					return readDouble(self.self + 0xC0)
				elseif self.className == "ObjectValue" then
					return rapi.toInstance(readQword(self.self + 0xC0))
				elseif self.className == "Vector3Value" then
					local x = readFloat(self.self + 0xC0)
					local y = readFloat(self.self + 0xC4)
					local z = readFloat(self.self + 0xC8)
					return {
						X = x,
						Y = y,
						Z = z
					}
				else
					print("Value read failed, indexing Instance instead")
					return self:findFirstChild(name)
				end
			elseif name == "Disabled" then
				if self.className == "LocalScript" then
					return readByte(self.self + 0x1EC) == 1
				end

				return self:findFirstChild(name)
			elseif name == "Enabled" then
				if self.className == "LocalScript" then
					return readByte(self.self + 0x1EC) == 0
				end

				return self:findFirstChild(name)
			elseif name == "DisplayName" then
				if self.className == "Humanoid" then
					return readString(self.self + 728)
				end

				return self:findFirstChild(name)
			elseif name == "LocalPlayer" or name == "localPlayer" then
				return rapi.toInstance(readQword(players.self + localPlayerOffset))
			elseif name == "GetService" or name == "getService" then
				return function(self, name)
					return self:findFirstChild(name)
				end
			elseif name == "Locked" then
				return readByte(self.self + 0x1BA) == 1
			else
				return self:findFirstChild(name)
			end
		end,
		__newindex = function(self, name, value)
			if name == "value" or name == "Value" then
				if self.className == "StringValue" then
					writeString(self.self + 0xC0, value)
				elseif self.className == "BoolValue" then
					writeByte(self.self + 0xC0, value and 1 or 0)
				elseif self.className == "IntValue" then
					writeInteger(self.self + 0xC0, value)
				elseif self.className == "NumberValue" then
					writeDouble(self.self + 0xC0, value)
				elseif self.className == "ObjectValue" then
					writeQword(self.self + 0xC0, value.self)
				elseif self.className == "Vector3Value" then
					writeFloat(self.self + 0xC0, value.X)
					writeFloat(self.self + 0xC4, value.Y)
					writeFloat(self.self + 0xC8, value.Z)
				else
					print("Value write failed, indexing Instance instead")
					self:findFirstChild(name)
				end
			elseif name == "Disabled" then
				if self.className == "LocalScript" then
					writeByte(self.self + 0x1EC, value and 1 or 0)
				end

				self:findFirstChild(name)
			elseif name == "Enabled" then
				if self.className == "LocalScript" then
					writeByte(self.self + 0x1EC, value and 0 or 1)
				end
			elseif name == "DisplayName" then
				if self.className == "Humanoid" then
					writeString(self.self + 728, value)
				end
			elseif name == "Locked" then
				writeByte(self.self + 0x1BA, value and 1 or 0)
			elseif name == "Parent" then
				self:setParent(value)
			elseif name == "Name" then
				local ptr = readQword(self.self + nameOffset)
				if ptr then
					local fl = readQword(ptr + 0x18)
					if fl == 0x1F then
						ptr = readQword(ptr)
					end

					if readString(readQword(ptr)) then
						writeString(readQword(ptr), value)
					else
						writeString(ptr, value)
					end
				end
			end
		end,
		__metatable = "The metatable is locked",
		__tostring = function(self)
			return string.format("Instance: %s", self.Name)
		end
	})
end

loader = {}

local pid;

loader.inject = function()
	openProcess("RobloxPlayerBeta.exe")
	openProcess("Windows10Universal.exe")

	if pid == getOpenedProcessID() then
		return
	end
	
	clearOutput()
	fprint('Injecting...')
	
	pid = getOpenedProcessID()

	local results = util.aobScan("506C6179657273??????????????????07000000000000000F")
	for rn = 1,#results do
		local result = results[rn];

		if not result then
			return false
		end

		local bres = util.intToBytes(result);
		local aobs = ""
		for i = 1,8 do
			aobs = aobs .. string.format("%02X", bres[i])
		end

		local first = false
		local res = util.aobScan(aobs)
		if res then
			valid = false
			for i = 1,#res do
				result = res[i]
				for j = 1,10 do
					local ptr = readQword(result - (8 * j))
					if ptr then
						ptr = readQword(ptr + 8)
						-- if readString(ptr) == "Players" then -- V1.8.9
						if readString(ptr) == "Players" and readString(readQword(readQword(((result-(8*j))-0x18)+0x60)+0x48))== "Game" then -- v1.8.10
							print(string.format("Got result: %08X", result))
							-- go to where the vftable is, 0x18 before classname offset (always)
							players = (result - (8 * j)) - 0x18
							-- calculate where we just were
							nameOffset = result - players
							value = true
							break

						end
					end
				end
				if valid then break end
			end
		end

		if valid then break end
	end

	print(string.format("Players: %08X", players))
	print(string.format("Name offset: %02X", nameOffset))

	for i = 0x10, 0x120, 8 do
		local ptr = readQword(players + i)
		if ptr ~= 0 and ptr % 4 == 0 then
			if (readQword(ptr + 8) == ptr) then
				parentOffset = i
				break
			end
		end
	end
	print(string.format("Parent offset: %02X", parentOffset))

	dataModel = readQword(players + parentOffset)

	print(string.format("DataModel: %08X", dataModel))

	for i = 0x10, 0x200, 8 do
		local ptr = readQword(dataModel + i)
		if ptr then
			local childrenStart = readQword(ptr)
			local childrenEnd = readQword(ptr + 8)
			if childrenStart and childrenEnd then
				if childrenEnd > childrenStart --[[and ((childrenEnd - childrenStart) % 16) == 0]] and childrenEnd - childrenStart > 1 and childrenEnd - childrenStart < 0x1000 then
					childrenOffset = i
					break
				end
			end
		end
	end
	print(string.format("Children offset: %02X", childrenOffset))
	

	players = rapi.toInstance(players)
	game = rapi.toInstance(dataModel)

	for i = 0x10,0x600,4 do
		local ptr = readQword(players.self + i)
		if readQword(ptr + parentOffset) == players.self then
			localPlayerOffset = i
			break
		end
	end
	print(string.format("Players->LocalPlayer offset: %02X", localPlayerOffset))

	localPlayer = rapi.toInstance(readQword(players.self + localPlayerOffset));
	print(string.format("Got localplayer: %08X", localPlayer.self))
	print(string.format("Got localplayer: %s", localPlayer.Name))
end


loader.start2 = function()
	loader.inject()

	local localBackpack, PlayerGui;

	for i, v in pairs(localPlayer:GetChildren()) do
		if v.ClassName == "Backpack" then
			localBackpack = v
		elseif v.ClassName == "PlayerGui" then
			PlayerGui = v
		end

		if localBackpack and PlayerGui then
			break
		end
	end

	print(string.format("Got backpack: %08X", localBackpack.self))
	local tools = localBackpack:GetChildren()
	if #tools == 0 then
		error'No tools found :('
	end
	
	local tool, targetScript;

	for _,v in pairs(tools) do
		tool = v
		targetScript =  v:findFirstClass("LocalScript")
		
		if targetScript then
			break
		end
	end
	
	print("Got tool: ", tool.Name)
	print("Got tool script: ", targetScript.Name)

	injectScript = nil
	
	local results = util.aobScan("2E6578656375746F72??????????????09") -- originally 496E6A656374????????????????????06
	for rn = 1,#results do
		local result = results[rn];
		local bres = util.intToBytes(result);
		local aobs = ""
		for i = 1,8 do
			aobs = aobs .. string.format("%02X", bres[i])
		end

		local first = false
		local res = util.aobScan(aobs)
		if res then
			valid = false
			for i = 1,#res do
				result = res[i]
				print(string.format("Result: %08X", result))

				if (readQword(result - nameOffset + 8) == result - nameOffset) then
					injectScript = result - nameOffset
					valid = true
					break
				end
			end
		end

		if valid then break end
	end
	
	if not injectScript then
		fprint("Inject script not found!")
		return
	end

	injectScript = rapi.toInstance(injectScript)
	print(string.format("Inject Script: %08X", injectScript.self))

	local b = readBytes(injectScript.self + 0x100, 0x150, true)
	writeBytes(targetScript.self + 0x100, b)


	fprint("Equip the \"" .. tool.Name .. "\" tool.")

	createNativeThread(function()
		repeat
			sleep(300)
		until PlayerGui:FindFirstChild("LoadstringGUI")

		fprint("Injected!")

		local GUI = PlayerGui:FindFirstChild("LoadstringGUI")
		GUI.Name = "Freecam"
		-- GUI:SetParent(game.CoreGui)
	end) -- thread so it doesn't freeze the ui
end

local function split(str, s)
	local t = {}

	for i in string.gmatch(str, "([^"..s.."]+)") do
		table.insert(t, i)
	end

	return t
end

-- The Main Form
f = createForm()
f.Width = 500
f.Height = 500 - 300
f.Position = 'poScreenCenter'
f.Color = '0x232323'
f.BorderStyle = 'bsNone'
f.onMouseDown = f.dragNow
f.FormStyle = 'fsStayonTop'

fTitle = createLabel(f)
fTitle.setPosition(10,5)
fTitle.Font.Color = '0xFFFFFF'
fTitle.Font.Size = 11
fTitle.Font.Name = 'Verdana'
fTitle.Caption = 'Byfron Injector'
fTitle.Anchors = '[akTop,akLeft]'


img_BtnMax = createButton(f)
img_BtnMax.Caption = "Open Dex"
img_BtnMax.setSize(70,20)
img_BtnMax.setPosition(130,4)
img_BtnMax.onClick = function()
	loader.inject()

	f = createForm()
	f.Width = 500
	f.Height = 1000
	f.Position = 'poScreenCenter'
	f.Color = '0x232323'

	fTitle = createLabel(f)
	fTitle.setPosition(10,5)
	fTitle.Font.Color = '0xFFFFFF'
	fTitle.Font.Size = 11
	fTitle.Font.Name = 'Verdana'
	fTitle.Caption = "Explorer"
	fTitle.Anchors = '[akTop,akLeft]'

	explorer = createTreeview(f)

	explorer.setSize(500,975)
	explorer.setPosition(0,25)
	explorer.Images = imageList

	search = createEdit(f)
	search.setSize(500,20)
	search.setPosition(0,0)
	search.Anchors = '[akTop,akLeft,akRight]'

	function indexChildren(obj, main)
		for i,v in pairs(obj:GetChildren()) do
			if v.Name ~= "???" then
				local rootNode = main.add(
					string.format("%s | (%s)", tostring(v.Name), v.ClassName)
				)

				indexChildren(v, rootNode)
			end
		end
	end

	indexChildren(game, explorer.Items)
end

fCredit = createLabel(f)
fCredit.Font.Color = '0x505050'
fCredit.Font.Size = 7
fCredit.Font.Name = 'Verdana'
fCredit.setPosition(214 + 36, 8)
fCredit.Caption = ".gg/runesoftware"

img_BtnMax = createButton(f)
img_BtnMax.Caption = "Inject"
img_BtnMax.setSize(70,20)
img_BtnMax.setPosition(390 - 75 + 75,4)
img_BtnMax.onClick = loader.start2

local txt = createMemo(f)
txt.setSize(480, 400 - 300 + 30 * 2)
txt.setPosition(10, 30)
txt.Color = '0x232323'
txt.Font.Color = '0xFFFFFF'
txt.Font.Size = 11
txt.Font.Name = 'Inconsolata'
txt.Anchors = '[akTop,akLeft,akRight,akBottom]'
txt.ScrollBars = 'ssVertical'
txt.Lines.Text = [[-- Use Web Roblox.

-- Try closing Developer Console
-- if it fails to find Inject script.
]]

--img_BtnMax = createButton(f)
--img_BtnMax.Caption = "Execute"
--img_BtnMax.setSize(70,20)
--img_BtnMax.setPosition(390,4)
--img_BtnMax.onClick = function()
--	-- replaceString("/execute @s |[V3RY]|R4ND0M|[S7R1N6]|{-=1337=-}", ExecuteString("-execute|" .. txt.Lines.Text), true)
--	replaceString("+execute|".. string.rep(" ", 999) .. string.char(0), ExecuteString("-execute|" .. txt.Lines.Text), true)
--end

img_BtnClose = createButton(f)
img_BtnClose.Caption = "X"
img_BtnClose.setSize(22,22)
img_BtnClose.setPosition(475,4)
img_BtnClose.Stretch = true
img_BtnClose.Cursor = -21
img_BtnClose.Anchors = '[akTop,akRight]'
img_BtnClose.onClick = function()
	f.Close()
end
