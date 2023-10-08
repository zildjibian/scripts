--/stop

local _typeof = typeof

getgenv().settype = function(obj, type)
	local mt = getrawmetatable(obj)
	if mt then
		local prev = mt.__type
		mt.__type = type or prev
		return
	end
	setrawmetatable(obj, {__type = type})
end

getgenv()._typeof = _typeof

getgenv().typeof = function(obj)
	if obj == nil then return 'nil' end

	local mt = getrawmetatable(obj)
	if mt and mt.__type then
		return mt.__type
	end
	return _typeof(obj)
end