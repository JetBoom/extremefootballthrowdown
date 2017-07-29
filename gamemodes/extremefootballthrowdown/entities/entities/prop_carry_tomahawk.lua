AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Tomahawk Missile"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_phx/amraam.mdl")
ENT.ThrowForce = 900

ENT.DropChance = 0.4
ENT.MaxActiveSets = 1

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(10, 0, -10)
ENT.AttachmentAngles = Angle(90, 0, 0)

ENT.MaxTurningAngle = 60

ENT.GravityThrowMul = 0

AccessorFuncDT(ENT, "Thrown", "Bool", 0)


ENT.LastThink = 0

function ENT:Initialize()
	self:SetModelScale(0.8, 0)

	self.LastThink = CurTime()

	self.BaseClass.Initialize(self)

	if CLIENT then
		self.FireSound = CreateSound(self, "thrusters/rocket04.wav")
	end
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
		pl:SetStateNumber(1)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.5)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.5)
end

function ENT:GetImpactSpeed()
	return self:GetThrown() and 1 or 450
end

if CLIENT then
function ENT:OnRemove()
	self.FireSound:Stop()
end

local matRope = Material("cable/rope")
local matGlow = Material("sprites/light_glow02_add")
function ENT:DrawTranslucent()
	if not self:GetThrown() then
		self:DrawModel()
		return
	end

	local vel = self:GetVelocity()
	if vel:Length() > 0 then
		self:SetRenderAngles(vel:Angle())
		self:DrawModel()
	end

	local owner = self:GetOwner()
	local col
	if owner:IsValid() and owner:IsPlayer() then
		col = team.GetColor(owner:Team())
	else
		col = color_white
	end

	local pos1 = self:GetPos() - vel:GetNormalized() * 32
	render.SetMaterial(matGlow)
	render.DrawSprite(pos1, 92, 92, col)
	render.DrawSprite(pos1, 64, 64, color_white)

	local r, g, b = col.r, col.g, col.b

	local emitter = ParticleEmitter(pos1)
	emitter:SetNearClip(45, 55)

	for i=1, 2 do
		local particle = emitter:Add("sprites/light_glow02_add", pos1 + VectorRand():GetNormalized() * math.Rand(2, 6))
		particle:SetDieTime(math.Rand(0.6, 1))
		particle:SetStartAlpha(230)
		particle:SetEndAlpha(50)
		particle:SetStartSize(math.Rand(28, 35))
		particle:SetEndSize(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-8, 8))
		particle:SetColor(r, g, b)

		particle = emitter:Add("effects/muzzleflash2", pos1)
		particle:SetVelocity(VectorRand():GetNormalized() * math.Rand(16, 32))
		particle:SetDieTime(math.Rand(1.6, 2))
		particle:SetStartAlpha(230)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(20, 28))
		particle:SetEndSize(16)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2.8, 2.8))
		particle:SetColor(r, g, b)
		particle:SetAirResistance(10)

		particle = emitter:Add("particles/smokey", pos1 + VectorRand():GetNormalized() * math.Rand(2, 14))
		particle:SetDieTime(math.Rand(1.6, 2))
		particle:SetStartAlpha(120)
		particle:SetEndAlpha(0)
		particle:SetStartSize(10)
		particle:SetEndSize(math.Rand(20, 28))
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-2.8, 2.8))
		particle:SetColor(45, 45, 45)
	end

	emitter:Finish()

	if owner:IsValid() and owner:IsPlayer() and owner:GetState() == STATE_TOMAHAWKRIDE then
		local rag = owner:GetRagdollEntity()
		if rag and rag:IsValid() then
			local boneid = rag:LookupBone("ValveBiped.Bip01_R_Hand")
			if boneid and boneid > 0 then
				local pos, ang = rag:GetBonePosition(boneid)
				if pos then
					local endpos = self:LocalToWorld(self:OBBCenter())
					render.SetMaterial(matRope)
					render.DrawBeam(pos, endpos, 2, 0, endpos:Distance(pos) / 64, color_white)
				end
			end
		end
	end
end

function ENT:OnThink()
	if self:GetThrown() then
		self.FireSound:PlayEx(0.85, 135 + math.sin(CurTime()))
	else
		self.FireSound:Stop()
	end
end

end

if CLIENT then return end

local function Thrown(pl, ent)
	if IsValid(pl) and IsValid(ent) then
		pl:SetState(STATE_TOMAHAWKRIDE)
		pl:SetStateEntity(ent)
	end
end

function ENT:OnThrown(carrier)
	self:SetOwner(carrier)
	self:SetThrown(true)

	timer.Simple(0, function()
		Thrown(carrier, self)
	end)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		phys:AddAngleVelocity(phys:GetAngleVelocity() * -1)
		phys:SetAngleDragCoefficient(50000)
	end
end

function ENT:OnThink()
	if self.Exploded then
		self:Remove()
	elseif self.PhysicsData then
		self:Explode(self.PhysicsData.HitPos, self.PhysicsData.HitNormal)
		self:Remove()
	elseif self.TouchedEnemy then
		self:Explode()
		self:Remove()
	elseif self:GetThrown() then
		local owner = self:GetOwner()
		if owner:IsValid() and owner:IsPlayer() and owner:GetState() == STATE_TOMAHAWKRIDE then
			local curtime = CurTime()
			local ang = owner:EyeAngles()

			if not self.m_GuideAngles then
				self.m_GuideAngles = ang
			end

			ang = util.LimitTurning(self.m_GuideAngles, ang, self.MaxTurningAngle, curtime - self.LastThink)

			--ang.roll = (CurTime() * 360) % 360

			self.m_GuideAngles = ang

			--phys:SetAngles(ang)
			local phys = self:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocityInstantaneous(ang:Forward() * self.ThrowForce)
			end

			self.LastThink = curtime
			self.DieTime = curtime + 30

			self:NextThink(curtime)
			return true
		end
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.Speed >= self:GetImpactSpeed() then
		self.PhysicsData = data
		self:NextThink(CurTime())
	end
end

function ENT:Explode(hitpos, hitnormal)
	if self.Exploded then return end
	self.Exploded = true
	self.PhysicsData = nil

	self:NextThink(CurTime())

	hitpos = hitpos or self:GetPos()
	hitnormal = (hitnormal or Vector(0, 0, -1)) * -1

	if self:GetThrown() then
		local owner = self:GetOwner()
		if owner:IsValid() then
			owner:TakeSpecialDamage(200, DMG_BLAST, owner, self)
		end
	end

	util.BlastDamage(self, self:GetLastCarrier():IsValid() and self:GetLastCarrier() or self, hitpos, 440, 70)
	util.ScreenShake(hitpos, 500, 0.5, 1, 300)

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("barrelexplosion", effectdata)
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetVelocity():Length() >= self:GetImpactSpeed() and ent:Team() ~= self:GetLastCarrierTeam() then
		self.TouchedEnemy = true
	end
end
