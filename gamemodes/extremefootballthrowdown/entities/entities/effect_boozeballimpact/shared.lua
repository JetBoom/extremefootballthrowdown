ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OTHER

ENT.m_IsProjectile = true

AccessorFuncDT(ENT, "Player", "Entity", 0)
AccessorFuncDT(ENT, "Team", "Int", 0)

function ENT:Think()
	if not self.Played and CLIENT then
		self:EmitSound("ambient/water/water_splash"..math.random(1, 3)..".wav", 100, math.random(160, 180))
	end
	self.Played = true
	
	local timetomax = math.max(0.005,(self.MaxScaleTime - CurTime()))
	if timetomax > 0.05 then
		self:SetModelScale(	(1 - timetomax) * self.MaxScale, 0)
	elseif not self.fullsize then
		self:SetModelScale(	(1 - 0.05) * self.MaxScale, 0)
		if SERVER then
			self:PhysicsInit(SOLID_VPHYSICS)
			self:SetSolid(SOLID_VPHYSICS)
			self:SetMoveType(MOVETYPE_NONE)
			
			self:SetTrigger(true)
			self:SetNotSolid(true)
			
			self:Activate()
			self.fullsize = true
		end
	end
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_phx/construct/glass/glass_angle360.mdl")
		self:Fire("kill", "", 0.2)
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end

	end
	
	self.MaxScale = self:GetModelScale()
	self.MaxScaleTime = CurTime()
	self.EndTime = CurTime() + 0.2
end
