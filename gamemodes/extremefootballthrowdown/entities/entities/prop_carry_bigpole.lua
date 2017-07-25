AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Big Pole"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_docks/dock01_pole01a_128.mdl")
ENT.ThrowForce = 250

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(0, 0, -50)
ENT.AttachmentAngles = Angle(0, 0, 180)

ENT.Mass = 150

ENT.AllowDuringOverTime = true
ENT.AllowInCompetitive = true

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.NextTouch = {}
end

function ENT:PrimaryAttack(pl)
	if pl:CanMelee() then
		pl:SetState(STATE_BIGPOLEATTACK, STATES[STATE_BIGPOLEATTACK].Time)
	end

	return true
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
	elseif pl:GetState() == STATE_BIGPOLEATTACK and not pl:GetStateBool() and CurTime() < pl:GetStateStart() + STATES[STATE_BIGPOLEATTACK].HitTime then
		pl:EndState()
	end

	return true
end

function ENT:CalcMainActivity(pl, velocity)
	local r = pl:GetState() == STATE_BIGPOLEATTACK and not pl:GetStateBool()

	if not pl:OnGround() then
		pl.CalcIdeal = r and ACT_HL2MP_JUMP_MELEE or ACT_HL2MP_JUMP_MELEE2
	elseif pl:Crouching() then
		if velocity:LengthSqr() > 0.5 then
			pl.CalcIdeal = r and ACT_HL2MP_WALK_CROUCH_MELEE or ACT_HL2MP_WALK_CROUCH_MELEE2
		else
			pl.CalcIdeal = ACT_HL2MP_IDLE_CROUCH_MELEE or ACT_HL2MP_IDLE_CROUCH_MELEE2
		end
	elseif velocity:LengthSqr() > 0.5 then
		pl.CalcIdeal = r and ACT_HL2MP_RUN_MELEE or ACT_HL2MP_RUN_MELEE2
	else
		pl.CalcIdeal = r and ACT_HL2MP_RUN_MELEE or ACT_HL2MP_IDLE_MELEE2
	end

	pl.CalcSeqOverride = -1
end

function ENT:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2, true)
		return ACT_INVALID
	end
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.666)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.666)
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 200 or 450
end

if CLIENT then return end

function ENT:OnThink()
	if self.PhysicsData then
		self:HitObject(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	elseif self.TouchedEnemy then
		self:HitObject(nil, nil, self.TouchedEnemy)
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= self:GetImpactSpeed() then
		self.PhysicsData = data
		self:NextThink(CurTime())
	end
end

function ENT:HitObject(hitpos, hitnormal, hitent)
	self.PhysicsData = nil
	self.TouchedEnemy = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or Vector(0, 0, 1)

	if IsValid(hitent) and hitent:IsPlayer() and hitent:Team() ~= self:GetLastCarrierTeam() then
		hitent:EmitSound("physics/body/body_medium_impact_hard"..math.random(3)..".wav")
		hitent:ThrowFromPosition(hitpos + Vector(0, 0, -24), math.Clamp(self:GetVelocity():Length() * 1.2, 350, 750), true, self:GetLastCarrier())
		hitent:TakeDamage(20, self:GetLastCarrier(), self)
	end

	self:EmitSound("physics/wood/wood_solid_impact_hard"..math.random(3)..".wav")
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() and CurTime() >= (self.NextTouch[ent] or 0) then
		self.NextTouch[ent] = CurTime() + 0.5
		self.TouchedEnemy = ent
	end
end
