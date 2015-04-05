ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.m_IsProjectile = true

function ENT:Think()
	if not self.Played and CLIENT then
		self:EmitSound("physics/glass/glass_largesheet_break"..math.random(1, 3)..".wav", 80, math.random(160, 180))
	end
	self.Played = true
	
	local timetomax = math.max(0.05,(self.MaxScaleTime - CurTime()))
	if timetomax > 0.5 then
		self:SetModelScale(	(1 - timetomax) * self.MaxScale, 0)
	elseif not self.fullsize then
		self:SetModelScale(	(1 - 0.5) * self.MaxScale, 0)
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
		if math.random(1, 2) == 1 then
			self:SetModel("models/props_wasteland/rockcliff01b.mdl")
		else
			self:SetModel("models/props_wasteland/rockcliff01c.mdl")
		end
		self:Fire("kill", "", 5)
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end

	end

	
	self.MaxScale = self:GetModelScale()
	self.MaxScaleTime = CurTime() + 1
	self.EndTime = CurTime() + 5
	
	self:SetMaterial("models/debug/debugwhite")
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	
end
