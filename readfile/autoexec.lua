-- aut in autoexec

getgenv().readfile = function(path)
	path = path:gsub('\\', '/')
	path = path:gsub(' ', ">")
	return request({
		Url = "http://localhost:8612/" .. path
	}).Body
end
