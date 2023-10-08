-- to play bad apple:
--   download: https://github.com/zildjibian/scripts/raw/main/others/Bad%20Apple.rar
--   extract it to your exploit's workspace folder
--   then, run: if not DrawSpace then loadstring(game:GetService('HttpService'):JSONDecode(game:HttpGet("https://github.com/zildjibian/scripts/raw/main/inits.json")).DrawSpaceAPI)() end
--   finally, run this script

-------

-- if you wanna play your own video,
--   change the path variable to a folder with frame{frameStart}.txt ~ frame{frameEnd}.txt
--   each frameStart's data must be "[ SHAPE[ POINT[X: number, Y: number], ... ], ... ]"
-- if you dont get what i mean, just open a file in the bad apple video

DrawSpace.shouldFire = true

local frameStart = 1
local frameEnd = 6572

local fps = 30
local path = 'Bad Apple' -- this variable
local size = Vector3.new(480, 0, 360)
local scale = 1/8

--

if _G.playingvideo then
	_G.playingvideo = nil
	wait(1)
end

size *= scale

local http = game:GetService("HttpService")
local decode = http.JSONDecode
function jsondecode(str)
	return decode(http, str)
end

local center = Vector3.new(22.64, 20, 318.69)-- + Vector3.new(0,40,0)

function loadFrame(frameStart)
	local d = 0
	local a = DrawSpace:CreateActions()
	
	local fileName = (path .. '/frame' .. frameStart .. '.txt')
	local s, file = pcall(function()
		return readfile(fileName)
	end)
	
	if not s then
		warn(fileName,'not found!')
		return
	end
	
	local decoded = jsondecode(file)
	
	if #decoded == 0 then
		DrawSpace:ClearAll()
		return
	end

	a:Add(DrawSpace:CreateAction('clearall'))
	
	for _,points in pairs(decoded) do
		if #points > 1 then
			local args = {
				Points = {},
				Size = scale
			}
			
			table.insert(points, points[1])
			
			for _,point in pairs(points) do
				point = Vector3.new(point[1] * scale, 0, point[2] * scale)
				table.insert(args.Points, center + point - size/2)
			end

			a:Add(DrawSpace:CreateAction('draw.line', args))
		end
	end

	a:Fire()
end

local prevFrame = frameStart - 1

local start = tick()

local step = game:GetService('RunService').RenderStepped

_G.playingvideo = true

print(' Playing', ('"%s"'):format(path))
while _G.playingvideo do
	frameStart += step:Wait() * fps

	local aFrame = math.round(frameStart)
	
	if aFrame >= frameEnd then
		print(' Finished, took', math.round((tick() - start) * 100) / 100, 'seconds.')
		break
	end
	
	if aFrame ~= prevFrame then
		loadFrame(aFrame)
	end
	
	prevFrame = aFrame
end
