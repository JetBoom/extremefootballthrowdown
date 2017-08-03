AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Arcane Wand"

ENT.IsPropWeapon = true

ENT.DropChance = 0.75

ENT.Model = Model("models/weapons/w_stunbaton.mdl")
ENT.ThrowForce = 1000

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(4, 1, -7.5)
ENT.AttachmentAngles = Angle(90, 180, 0)

ENT.Mass = 25

function ENT:PrimaryAttack(pl)
	if pl:CanMelee() then
		pl:SetState(STATE_ARCANEWANDATTACK, STATES[STATE_ARCANEWANDATTACK].Time)
	end

	return true
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	elseif pl:GetState() == STATE_ARCANEWANDATTACK then
		self.Canceled = true
		pl:EndState()
		self.Canceled = nil
	end

	return true
end

function ENT:Move(pl, move)
	if pl:GetState() == STATE_ARCANEWANDATTACK then
		move:SetMaxSpeed(SPEED_ATTACK)
		move:SetMaxClientSpeed(SPEED_ATTACK)

		return MOVE_STOP
	end

	move:SetMaxSpeed(move:GetMaxSpeed() * 0.7)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.7)
end

local Translated = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_SLAM,

	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_SLAM,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_SLAM,

	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_SLAM,

	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_SLAM,

	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_SLAM,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_SLAM,

	[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM,

	[ACT_MP_SWIM] = ACT_HL2MP_SWIM_SLAM
}
local TranslatedFiring = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_GRENADE,

	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_GRENADE,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_GRENADE,

	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_GRENADE,

	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_GRENADE,

	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_GRENADE,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_GRENADE,

	[ACT_MP_JUMP] = ACT_HL2MP_JUMP_GRENADE,

	[ACT_MP_SWIM] = ACT_HL2MP_SWIM_GRENADE
}
function ENT:TranslateActivity(pl)
	if pl:GetState() == STATE_ARCANEWANDATTACK or CurTime() < self:GetDTFloat(5) then
		pl.CalcIdeal = TranslatedFiring[pl.CalcIdeal] or pl.CalcIdeal
	else
		pl.CalcIdeal = Translated[pl.CalcIdeal] or pl.CalcIdeal
	end
end

function ENT:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true)
		return ACT_INVALID
	end
end

if SERVER then
function ENT:PhysicsCollide(data, phys)
	if data.Speed >= 200 then
		self:EmitSound("physics/metal/weapon_impact_hard"..math.random(3)..".wav")

		self:NextThink(CurTime())
	end
end
end

if not CLIENT then return end

ENT.Rotation = 0

local matGlow = Material("sprites/glow04_noz")
function ENT:DrawTranslucent()
	self:DrawModel()

	local pos = self:LocalToWorld(Vector(-11, 1, 1))
	local carrier = self:GetCarrier()
	local delta = carrier:IsValid() and carrier:GetState() == STATE_ARCANEWANDATTACK and (1 - math.Clamp((carrier:GetStateEnd() - CurTime()) / carrier:GetStateTable().Time, 0, 1)) or 0

	self.Rotation = (self.Rotation + FrameTime() * (1 + delta * 5) * 30) % 360

	local mainsize = 14 + delta * 24

	local sep = 15
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Right(), 90)

	render.SetMaterial(matGlow)
	render.DrawSprite(pos, mainsize, mainsize, color_white)

	for i=0, 360, sep do
		ang:RotateAroundAxis(ang:Up(), sep)

		local size = 0.5 + math.abs(math.sin(self.Rotation + i * 0.1)) * 1.5 + delta * 16
		render.DrawSprite(pos + ang:Forward() * (4 + delta * 10) + ang:Up() * math.cos(self.Rotation * 0.05 + i * 0.2) * 2, size, size, color_white)
	end
end
