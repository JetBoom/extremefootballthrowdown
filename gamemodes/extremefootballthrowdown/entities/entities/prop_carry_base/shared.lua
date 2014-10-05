ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Model = Model("models/Roller.mdl")

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(0, 0, 0)
ENT.AttachmentAngles = Angle(0, 0, 0)

ENT.LifeTime = 30

function ENT:GetLastCarrier()
	return self:GetDTEntity(3)
end

function ENT:SetLastCarrier(ent)
	self:SetDTEntity(3, ent)
	if ent:IsValid() and ent:IsPlayer() then
		self:SetLastCarrierTeam(ent:Team())
	end
end

function ENT:GetLastCarrierTeam()
	return self:GetDTInt(3)
end

function ENT:SetLastCarrierTeam(teamid)
	self:SetDTInt(3, teamid)
end

function ENT:SetCarrier(ent)
	local prevcarrier = self:GetCarrier()

	ent = ent or NULL

	self:SetDTEntity(1, ent)

	if CLIENT then return end

	if ent ~= prevcarrier then
		self.DieTime = CurTime() + self.LifeTime
	end

	local phys = self:GetPhysicsObject()
	if ent:IsValid() then
		local entteam = ent:Team()

		if entteam ~= self.LastCarrierTeam then
			self.LastCarrierTeam = entteam
		end

		self:Input("onpickedup", ent, ent)
		if entteam == TEAM_RED then
			self:Input("onpickedupbyred", ent, ent)
		elseif entteam == TEAM_BLUE then
			self:Input("onpickedupbyblue", ent, ent)
		end

		self:SetLastCarrier(ent)
		ent:SetCarrying(self)
		self:AlignToCarrier()
		if phys:IsValid() then phys:EnableMotion(false) end
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	else
		if phys:IsValid() then phys:EnableMotion(true) phys:Wake() end
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	end

	for _, p in pairs(player.GetAll()) do
		if p ~= ent and p:GetCarrying() == self then p:SetCarrying(NULL) end
	end
end

function ENT:GetCarrier()
	return self:GetDTEntity(1)
end

function ENT:GetAttachmentPosAng(carrier)
	if self.BoneName then
		local boneid = carrier:LookupBone(self.BoneName)
		if boneid and boneid > 0 then
			return carrier:GetBonePosition(boneid)
		end
	end

	if self.AttachmentName then
		local attachid = carrier:LookupAttachment(self.AttachmentName)
		if attachid and attachid > 0 then
			local attach = carrier:GetAttachment(attachid)
			if attach then
				return attach.Pos, attach.Ang
			end
		end
	end

	return carrier:GetPos(), carrier:GetAngles()
end

function ENT:AlignToCarrier()
	local carrier = self:GetCarrier()
	if carrier:IsValid() then
		local pos, ang = self:GetAttachmentPosAng(carrier)
		local offset = self.AttachmentOffset
		local rotate = self.AttachmentAngles

		self:SetPos(pos + offset.x * ang:Forward() + offset.y * ang:Right() + offset.z * ang:Up())

		if rotate.yaw ~= 0 then ang:RotateAroundAxis(ang:Up(), rotate.yaw) end
		if rotate.pitch ~= 0 then ang:RotateAroundAxis(ang:Right(), rotate.pitch) end
		if rotate.roll ~= 0 then ang:RotateAroundAxis(ang:Forward(), rotate.roll) end
		self:SetAngles(ang)
	end
end
