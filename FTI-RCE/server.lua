-- this is used to change the game without having to publish it, which is really helpful

local scp = workspace:WaitForChild(""):WaitForChild("Collectables"):WaitForChild("SCP-096")

local function ch(v)
  if v:IsA("Decal") then
    v.Texture = "rbxassetid://146134073"
  end
end

for _,v in pairs(scp:GetChildren()) do ch(v) end
scp.ChildAdded:Connect(ch)
