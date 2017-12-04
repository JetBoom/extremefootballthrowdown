AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Beatdown Stick"

ENT.IsPropWeapon = true

ENT.Model = Model("models/weapons/w_stunbaton.mdl")
ENT.ThrowForce = 850

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(4.5, 1.5, -15)
ENT.AttachmentAngles = Angle(80, 180, 10)

ENT.Mass = 40

ENT.AllowDuringOverTime = true
ENT.AllowInCompetitive = true

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self:SetModelScale(2, 0)

	self.NextTouch = {}
end

function ENT:PrimaryAttack(pl)
	if pl:CanMelee() then
		pl:SetState(STATE_BEATINGSTICKATTACK, STATES[STATE_BEATINGSTICKATTACK].Time)
	end

	return true
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.8)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.8)
end

local Translated = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_MELEE,
	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_MELEE,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_MELEE,
	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_MELEE,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_MELEE
}
function ENT:TranslateActivity(pl)
	pl.CalcIdeal = Translated[pl.CalcIdeal] or pl.CalcIdeal
end

function ENT:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true)
		return ACT_INVALID
	end
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 300 or 600
end

if CLIENT then return end

function ENT:OnThink()
	if self.PhysicsData then
		self:HitObject(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	elseif self.TouchedEnemy then
		self:HitObject(nil, nil, self.TouchedEnemy)
	end
end

function ENT:HitObject(hitpos, hitnormal, hitent)
	self.PhysicsData = nil
	self.TouchedEnemy = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or Vector(0, 0, 1)

	if IsValid(hitent) and hitent:IsPlayer() and hitent:Team() ~= self:GetLastCarrierTeam() then
		hitent:EmitSound("npc/zombie/zombie_hit.wav", 75, math.Rand(90, 140))
		hitent:ThrowFromPosition(hitent:GetPos() + Vector(0, 0, -16), 200, true, self:GetLastCarrier())
		hitent:TakeDamage(5, self:GetLastCarrier(), self)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			local vel = phys:GetVelocity() * 0.15
			vel.z = 300
			phys:SetVelocityInstantaneous(vel)
			phys:AddAngleVelocity(VectorRand():GetNormalized() * 420)
		end
	end

	self:EmitSound("physics/metal/metal_canister_impact_hard"..math.random(3)..".wav")
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= 200 then
		self:EmitSound("physics/metal/weapon_impact_hard"..math.random(3)..".wav")

		self:NextThink(CurTime())
	end
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() and CurTime() >= (self.NextTouch[ent] or 0) then
		self.NextTouch[ent] = CurTime() + 0.5
		self.TouchedEnemy = ent
	end
end
