AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Melondriver"

ENT.IsPropWeapon = true

ENT.Model = Model("models/weapons/w_rocket_launcher.mdl")
ENT.ThrowForce = 550

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(14, 0, 0)
ENT.AttachmentAngles = Angle(180, 0, 0)

ENT.ChargeTime = 2
ENT.FireDelay = 3

function ENT:PrimaryAttack(pl)
	if not pl:IsSwimming() and self:GetFireTime() == 0 and CurTime() >= self:GetNextFireTime() then
		self:SetFireTime(CurTime() + self.ChargeTime)
		self:SetNextFireTime(CurTime() + self.FireDelay)

		if SERVER then self:EmitSound("npc/strider/charging.wav", 78, 77) end
	end

	return true
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() and self:GetFireTime() == 0 then
		pl:SetState(STATE_THROW)
	elseif self:GetFireTime() > 0 then
		self:SetFireTime(0)
	end

	return true
end

function ENT:Move(pl, move)
	if self:GetFireTime() == 0 then
		move:SetMaxSpeed(move:GetMaxSpeed() * 0.7)
		move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.7)
	else
		move:SetMaxSpeed(SPEED_ATTACK)
		move:SetMaxClientSpeed(SPEED_ATTACK)

		return MOVE_STOP
	end
end

local Translated = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,

	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_PASSIVE,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,

	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_RPG,

	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,

	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_PASSIVE,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_PASSIVE,

	[ACT_MP_JUMP] = ACT_HL2MP_JUMP_PASSIVE,

	[ACT_MP_SWIM] = ACT_HL2MP_SWIM_PASSIVE
}
local TranslatedFiring = {
	[ACT_MP_RUN] = ACT_HL2MP_RUN_RPG,

	[ACT_HL2MP_WALK_SUITCASE] = ACT_HL2MP_WALK_RPG,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_RPG,

	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_RPG,

	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_RPG,

	[ACT_HL2MP_IDLE_MELEE_ANGRY] = ACT_HL2MP_IDLE_RPG,
	[ACT_HL2MP_IDLE_ANGRY] = ACT_HL2MP_IDLE_RPG,

	[ACT_MP_JUMP] = ACT_HL2MP_JUMP_RPG,

	[ACT_MP_SWIM] = ACT_HL2MP_SWIM_RPG
}
function ENT:TranslateActivity(pl)
	if self:GetFireTime() == 0 then
		pl.CalcIdeal = Translated[pl.CalcIdeal] or pl.CalcIdeal
	else
		pl.CalcIdeal = TranslatedFiring[pl.CalcIdeal] or pl.CalcIdeal
	end
end

function ENT:OnThink()
	if SERVER then
		if self.PhysicsData then
			self:HitObject(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
		elseif self.TouchedEnemy then
			self:HitObject(nil, nil, self.TouchedEnemy)
		end
	end

	local carrier = self:GetCarrier()
	if not carrier:IsValid() then return end

	if CurTime() < self:GetFireTime() and carrier:IsSwimming() then carrier:SetLocalVelocity(Vector(0,0,0)) end

	if self:GetFireTime() == 0 or CurTime() < self:GetFireTime() then return end
	self:SetFireTime(0)

	if SERVER then
		self:EmitSound("weapons/rpg/rocketfire1.wav")

		for i=1, 2 do
			local ang = carrier:EyeAngles()
			ang:RotateAroundAxis(ang:Up(), math.Rand(-3, 3))
			ang:RotateAroundAxis(ang:Right(), math.Rand(-3, 3))

			local ent = ents.Create("prop_carry_melon")
			if ent:IsValid() then
				ent:SetPos(carrier:GetShootPos())
				ent:SetAngles(ang)
				ent:SetOwner(carrier)
				ent:Spawn()
				ent:SetLastCarrier(carrier)

				local phys = ent:GetPhysicsObject()
				if phys:IsValid() then
					phys:Wake()
					phys:SetVelocityInstantaneous(ang:Forward() * 1600)
					phys:AddAngleVelocity(VectorRand() * 600)
				end
			end
		end
	end
end

if SERVER then
function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.NextTouch = {}
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
		hitent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav")
		hitent:ThrowFromPosition(hitpos + Vector(0, 0, -24), math.Clamp(self:GetVelocity():Length() * 1.2, 350, 750), true, self:GetLastCarrier())
		hitent:TakeDamage(20, self:GetLastCarrier(), self)
	end

	self:EmitSound("physics/metal/metal_canister_impact_hard"..math.random(3)..".wav")
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() and CurTime() >= (self.NextTouch[ent] or 0) then
		self.NextTouch[ent] = CurTime() + 0.5
		self.TouchedEnemy = ent
	end
end
end

function ENT:GetImpactSpeed()
	return self:GetLastCarrier():IsValid() and 200 or 450
end

function ENT:SetFireTime(time) self:SetDTFloat(0, time) end
function ENT:GetFireTime() return self:GetDTFloat(0) end
function ENT:SetNextFireTime(time) self:SetDTFloat(1, time) end
function ENT:GetNextFireTime() return self:GetDTFloat(1) end

if not CLIENT then return end

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local matRefraction	= Material("refract_ring")
local matRing = Material("effects/select_ring")
local colRing = Color(255, 120, 20, 255)
function ENT:DrawTranslucent()
	self:Draw()

	if self:GetFireTime() == 0 then return end

	local dir = self:GetForward()
	local pos = self:LocalToWorld(Vector(-5, 0, 5))
	local rot = CurTime() * 360 % 1
	local delta = (1 - CurTime() * 2 % 1) ^ 2 * math.Clamp((self:GetFireTime() - CurTime()) / self.ChargeTime, 0, 1)
	local size = delta * 200

	colRing.a = delta * 100
	render.SetMaterial(matRing)
	render.DrawQuadEasy(pos, dir, size, size, colRing, rot)
	render.DrawQuadEasy(pos, dir * -1, size, size, colRing, rot)

	colRing.a = 255
	matRefraction:SetFloat("$refractamount", delta / 2)
	render.SetMaterial(matRefraction)
	render.UpdateRefractTexture()
	render.DrawQuadEasy(pos, dir, size, size, color_white, rot)
	render.DrawQuadEasy(pos, dir * -1, size, size, color_white, rot)
end

function ENT:HUDPaint(pl)
	if self:GetFireTime() ~= 0 then
		GAMEMODE:DrawCrosshair()
	end
end

function ENT:GetCameraPos(pl, camerapos, origin, angles, fov, znear, zfar)
	if self:GetFireTime() ~= 0 then
		pl:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, nil, 16)
	end
end
