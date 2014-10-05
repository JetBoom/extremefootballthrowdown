include("shared.lua")

function ENT:Initialize()
	local ent = ClientsideModel("models/props_c17/trappropeller_blade.mdl")
	if ent:IsValid() then
		ent:SetPos(self:LocalToWorld(Vector(0, 0, 24)))
		ent:SetAngles(self:GetAngles())
		ent:Spawn()
		ent:SetColor(self:GetColor())
		self.Blade = ent
	end

	self.AmbientSound = CreateSound(self, "ambient/machines/spin_loop.wav")
end

function ENT:OnRemove()
	local blade = self.Blade
	if blade and blade:IsValid() then
		blade:Remove()
	end

	self.AmbientSound:Stop()
end

function ENT:Think()
	local blade = self.Blade
	if blade and blade:IsValid() and CurTime() >= self:GetStartTime() then
		local spinup = math.min(1, CurTime() - self:GetStartTime()) ^ 0.3
		self.AmbientSound:PlayEx(spinup * 0.65, 40 + spinup * 60)

		local ang = blade:GetAngles()
		ang.yaw = (ang.yaw + FrameTime() * spinup * 1080) % 360
		blade:SetAngles(ang)

		self:NextThink(CurTime())
		return true
	end
end

function ENT:Draw()
	self:DrawModel()
end
