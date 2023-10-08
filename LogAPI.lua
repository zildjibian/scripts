--/stop

-- usage: log(text, type?)

local LogConsole = false

local ls = game:GetService('LogService')

if not isfolder('Logs') then
	makefolder('Logs')
end

local function createfile(i)
	i = i or 1
	local fileName = ('Logs/%s %s %s - %d.lua'):format(os.date('%d'), os.date('%B'), os.date('%Y'), i)
	if isfile(fileName) then
		fileName = createfile(i + 1)
	else
		writefile(fileName, '')
	end
	return fileName
end

local queue = ''

local fileName = createfile()

function Log(text : string, type : Enum.MessageType | string)
	if typeof(type) == "EnumItem" and tostring(type.Enum) == 'MessageType' then
		type = type.Name
	else
		type = type or 'Output'
	end
	
	queue ..= ('[%s] [%s] %s'):format(os.date('%X'), (type:gsub('Message', '')), text) .. '\n'
end

ls.MessageOut:Connect(function(...)
	if LogConsole then
		Log({...})
	end
end)

getgenv().log = Log
getgenv().Log = Log

spawn(function()
	while true do
		if #queue > 0 then
			appendfile(fileName, queue)
		end
		queue = ''
		wait(1/2)
	end
end)
