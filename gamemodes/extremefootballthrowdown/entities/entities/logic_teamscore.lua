ENT.Type = "point"

function ENT:Initialize()
	if self.Enabled == nil then self.Enabled = true end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	elseif key == "enabled" then
		self.Enabled = tonumber(value) == 1
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	elseif name == "setenabled" then
		self:SetKeyValue("enabled", args)
		return true
	elseif name == "getscore" then
		self:Input("ongetredscore", activator, caller, team.GetScore(TEAM_RED))
		self:Input("ongetbluescore", activator, caller, team.GetScore(TEAM_BLUE))
	end
end
