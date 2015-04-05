AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Touch(ent)
	if (self.EndTime - 1) <= CurTime() then return end
	if ent:IsPlayer() then
		local AlreadyCold = false
		for __, v in pairs(ents.FindByClass("status_cold")) do
			if v:GetOwner() == ent then AlreadyCold = true break end
		end
		if not AlreadyCold then
			local status = ents.Create("status_cold")
			if status:IsValid() then
				status:SetPos(ent:LocalToWorld(ent:OBBCenter()))
				status:SetOwner(ent)
				status:SetParent(ent)
				status:Spawn()
			end
		end
	end
end