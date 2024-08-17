-- server runs in Luau
-- client runs in vLua

local colls = workspace:WaitForChild("Collectables")

local function changeCollectable(name, target, desc, hint)
	spawn(function()
		local coll = colls:WaitForChild(name)

		if target then
			local function ch(v) if v:IsA("Decal") then v.Texture = target end end

			for _,v in coll:GetChildren() do ch(v) end
			coll.ChildAdded:Connect(ch)
		end

		if desc then require(coll:WaitForChild("Config")).Description = desc end
		if hint then require(coll:WaitForChild("Config")).Hint = hint end
	end)
end

changeCollectable("SCP-096", "rbxassetid://146134073", "boo\n\ndecal uploaded by @joelwari")
changeCollectable("Meow Skulls", "rbxassetid://12243376450", "fortnite\n\ndecal uploaded by @Solar_Elimz2") -- i never knew the og was... uhhh...

local specialLaunchDatas = {
	["AscendiaHills"] = function(plr)
		game:GetService("TeleportService"):Teleport(18979668460, plr)
	end,
}

game:GetService('Players').PlayerAdded:Connect(function(plr)
	local jd = plr:GetJoinData()
	if jd and jd.LaunchData then
		local cb = specialLaunchDatas[jd.LaunchData]
		if cb then cb(plr) end
	end
end)