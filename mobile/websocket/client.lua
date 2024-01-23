local wso = WebSocket.connect("ws://YOUR_IPV4:8765")

-- .OnMessage  : RBXScriptSignal: (content: string)
-- :Send       : (content: string) -> ()

local function print(...)
	local t = {...}
	for i, v in t do t[i] = tostring(v) end
	wso:Send(table.concat(t, ", "))
end

print("A", "B", "C")
