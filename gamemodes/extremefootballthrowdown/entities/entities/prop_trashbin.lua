AddCSLuaFile()

ENT.Type = "anim"

ENT.BoneName="ValveBiped.Bip01_Spine2"
ENT.AttachmentOffset=Vector(10, 0, 0)
ENT.AttachmentAngles=Angle(0, 90, 270)

if SERVER then
function ENT:Initialize()
	self:SetModel("models/props_trainstation/trashcan_indoor001b.mdl")
	self:SetSolid(SOLID_NONE)

	self:Fire("kill", "", 15)
end
end

function ENT:Think()
	if SERVER then
		local owner = self:GetOwner()
		if not owner:IsValid() or not owner:Alive() then self:Remove() return end
	end

	self:AlignToOwner()
end

function ENT:GetAttachmentPosAng(carrier)
	if self.BoneName then
		local boneid = carrier:LookupBone(self.BoneName)
		if boneid and boneid > 0 then
			return carrier:GetBonePositionMatrixed(boneid)
		end
	end

	return carrier:GetPos(), carrier:GetAngles()
end

function ENT:AlignToOwner()
	local carrier = self:GetOwner()
	if carrier:IsValid() then
		local pos, ang = self:GetAttachmentPosAng(carrier)
		local offset = self.AttachmentOffset
		local rotate = self.AttachmentAngles

		self:SetPos(pos + offset.x * ang:Forward() + offset.y * ang:Right() + offset.z * ang:Up())

		if rotate.yaw ~= 0 then ang:RotateAroundAxis(ang:Up(), rotate.yaw) end
		if rotate.pitch ~= 0 then ang:RotateAroundAxis(ang:Right(), rotate.pitch) end
		if rotate.roll ~= 0 then ang:RotateAroundAxis(ang:Forward(), rotate.roll) end
		self:SetAngles(ang)

		if CLIENT and MySelf == carrier and IsValid(self.ScreenBlocker) then
			self.ScreenBlocker:SetPos(EyePos())
			self.ScreenBlocker:SetAngles(EyeAngles())
		end
	end
end

if SERVER then return end

function ENT:Initialize()
	local ent = ClientsideModel("models/props_trainstation/trashcan_indoor001b.mdl", RENDERGROUP_OPAQUE)
	if ent:IsValid() then
		ent:SetPos(self:GetPos())
		ent:SetParent(self)

		self.ScreenBlocker = ent
	end
end

function ENT:OnRemove()
	if IsValid(self.ScreenBlocker) then
		self.ScreenBlocker:Remove()
	end
end

function ENT:Draw()
	self:AlignToOwner()
	self:DrawModel()
end
