-- server runs in Luau
-- client runs in vLua

local scp = workspace:WaitForChild("Collectables"):WaitForChild("SCP-096")

local function ch(v)
  if v:IsA("Decal") then
    v.Texture = "rbxassetid://146134073"
  end
end

for _,v in scp:GetChildren() do ch(v) end
scp.ChildAdded:Connect(ch)
