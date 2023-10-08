--/stop

local Signal = {}

Signal.doDebug = false

local Connection__index = {} Connection__index.__index = Connection__index do
	function Connection__index:Disconnect()
		local i = table.find(self.Signal.Connections, self)
		if i then
			table.remove(self.Signal.Connections, i)
		end
		self.Connected = false
	end
end

function newConnection(sign, func)
	local Connection = {
		Signal = sign,
		Connected = true
	}
	
	return setmetatable(Connection, Connection__index)

end

local Signal__index = {} Signal__index.__index = Signal__index do
	function Signal__index:Connect(func)
		assert(type(func) == 'function', 'Attempt to connect failed: Passed value is not a function')

		local c = newConnection(self, func)

		table.insert(self.Connections, c)

		return c
	end

	function Signal__index:Once(func)
		local Connection
		Connection = self:Connect(function(...)
			func(...)
			Connection:Disconnect()
		end)
	end

	function Signal__index:Wait()
		local pass
		local values

		local Connection
		Connection = self:Connect(function(...)
			pass = true
			values = {...}
			Connection:Disconnect()
		end)

		repeat
			wait()
		until pass

		return unpack(values)
	end

	function Signal__index:Fire(...)
		for _,Connection in pairs(self.Connections) do
			if Connection.func then
				local data = {...}

				local s,r = pcall(function()
					Connection.func(unpack(data))
				end)

				if Signal.doDebug and not s then
					warn('Error while firing Signal "' .. self.Name .. '":',r)
				end
			end
		end
	end
end

function Signal.new(name)
	assert(typeof(name) == 'string' or typeof(name) == 'number', 'Invalid name!')
	
	name = tostring(name)
	
	local self = {
		Name = name,
		Connections = {}
	}
	
	return setmetatable(self, Signal__index)
end

getgenv().Signal = Signal