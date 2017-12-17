AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Touch(ent)
	if (self.EndTime) <= CurTime() then return end
	local ball = GAMEMODE:GetBall()
	if ent:IsPlayer() and ent:Team() ~= ball:GetLastCarrierTeam() then
		local AlreadyBoozed = false
		for __, v in pairs(ents.FindByClass("status_boozed")) do
			if v:GetOwner() == ent then AlreadyBoozed = true break end
		end
		if not AlreadyBoozed then
			local status = ents.Create("status_boozed")
			if status:IsValid() then
				status:SetPos(ent:LocalToWorld(ent:OBBCenter()))
				status:SetOwner(ent)
				status:SetParent(ent)
				status:Spawn()
			end
		end
	end
end

