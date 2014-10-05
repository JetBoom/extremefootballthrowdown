AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:DrawShadow(false)

	self:SetModel("models/props_phx/construct/plastic/plastic_panel8x8.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCustomCollisionCheck(true)
	self:CollisionRulesChanged()

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:EnableMotion(false) end
end

function ENT:Think()
	local pl = self:GetPlayer()
	if pl:IsValid() and (pl:GetCarry() ~= GAMEMODE:GetBall() or GAMEMODE:GetBall():GetState() ~= BALL_STATE_WATERBALL) then
		self:Remove()
	else
		self:AlignToCarrier()

		self:NextThink(CurTime())
		return true
	end
end

function ENT:AlignToCarrier()
	local ball = self:GetOwner()
	if not ball:IsValid() then return end

	local carrier = ball:GetCarrier()
	if not carrier:IsValid() then return end

	if carrier:WaterLevel() >= 2 then
		carrier:SetVelocity(Vector(0, 0, 1024 * FrameTime()))
	else
		local tr = util.TraceLine({start = carrier:GetPos() + Vector(0, 0, 8), endpos = carrier:GetPos() + Vector(0, 0, -256), mask = MASK_WATER})
		if tr.Hit and tr.MatType == MAT_SLOSH and bit.band(util.PointContents(tr.HitPos + Vector(0, 0, -2)), CONTENTS_WATER) > 0 then
			self:SetPos(tr.HitPos - tr.HitNormal * 5)
			return
		end
	end

	self:SetPos(carrier:GetPos() + Vector(0, 0, -10240))
end
