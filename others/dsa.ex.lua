-- example script (draws a floating dot in the middle of the room)

-- DrawSpace:ClearAll()

local pos = Vector3.new(20.68, 30, 318.69)
local normals = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 1, 0),
	Vector3.new(0, -1, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
}

for _, normal in pairs(normals) do
	DrawSpace:CreateAction('Draw.Dot', {
		Position = pos,
		Normal = normal,
		Size = 10
	}):Queue()
end

DrawSpace:FireQueue()
