AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.OffsetPosition = Vector(5, 3, 0)
ENT.OffsetAngles = Angle(180, -30, -20)
ENT.BoneName = "ValveBiped.Bip01_Spine1"

local function MoveOffset(pos, ang, offset)
	pos:Set(pos + offset.x * ang:Forward() + offset.y * ang:Right() + offset.z * ang:Up())
end

local function RotateAngles(ang, offset)
	if offset.yaw ~= 0 then ang:RotateAroundAxis(ang:Up(), offset.yaw) end
	if offset.pitch ~= 0 then ang:RotateAroundAxis(ang:Right(), offset.pitch) end
	if offset.roll ~= 0 then ang:RotateAroundAxis(ang:Forward(), offset.roll) end
end

function ENT:SetPlayer(pPlayer)
	self:SetOwner(pPlayer)
	self:SetColor(team.GetColor(pPlayer:Team()))

	--[[local pos
	local ang
	local boneid = pPlayer:LookupBone(self.BoneName)

	if boneid and boneid > 0 then
		local m = pPlayer:GetBoneMatrix(boneid)
		if m then
			pos, ang = m:GetTranslation(), m:GetAngles()
		else
			pos, ang = Vector(0,0,0), Angle(0,0,0)
		end

		self:SetParent(NULL)
		self:FollowBone(pPlayer, boneid)
	else
		pos = pPlayer:GetPos()
		ang = pPlayer:GetAngles()

		self:SetParent(pPlayer)
	end

	MoveOffset(pos, ang, self.OffsetPosition)
	RotateAngles(ang, self.OffsetAngles)

	self:SetPos(pos)
	self:SetAngles(ang)]]
end
