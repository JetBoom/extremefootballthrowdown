AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "prop_carry_base"

ENT.Name = "Clown Car"

ENT.IsPropWeapon = true

ENT.Model = Model("models/props_vehicles/car002a.mdl")
ENT.ThrowForce = 1000
ENT.AccelTime = 1

ENT.BoneName = "ValveBiped.Bip01_R_Hand"
ENT.AttachmentOffset = Vector(4, 4, 0)
ENT.AttachmentAngles = Angle(90, 0, 90)

ENT.GravityThrowMul = 0.4

local RandomProps = {
	Model("models/props_vehicles/carparts_axel01a.mdl"),
	Model("models/props_vehicles/carparts_door01a.mdl"),
	Model("models/props_vehicles/carparts_door01a.mdl"),
	Model("models/props_vehicles/carparts_muffler01a.mdl"),
	Model("models/props_c17/pulleywheels_large01.mdl"),
	Model("models/props_c17/trappropeller_engine.mdl"),
	Model("models/props_vehicles/carparts_wheel01a.mdl"),
	"models/props_vehicles/carparts_wheel01a.mdl",
	"models/props_vehicles/carparts_wheel01a.mdl",
	"models/props_vehicles/carparts_wheel01a.mdl"
}

if SERVER then
function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.NextTouch = {}

	self:SetModelScale(0.2, 0)
	self:SetCustomCollisionCheck(true)
	self:CollisionRulesChanged()

	self:SetColor(Color(255, 60, 255))

	self.Created = CurTime()
end
end

function ENT:ShouldNotCollide(ent)
	if ent:IsWorld() and self:GetThrown() then return true end
end

function ENT:SecondaryAttack(pl)
	if pl:CanThrow() then
		pl:SetState(STATE_THROW)
		pl:SetStateNumber(1)
	end

	return true
end

function ENT:Move(pl, move)
	move:SetMaxSpeed(move:GetMaxSpeed() * 0.75)
	move:SetMaxClientSpeed(move:GetMaxClientSpeed() * 0.75)
end

function ENT:OnThrown(carrier)
	self:SetThrown(true)

	if carrier:IsValid() then self.Dir = carrier:GetAimVector() end
end

function ENT:PhysicsUpdate(phys)
	if self:GetThrown() and self.Dir then
		--phys:SetAngles(self.Dir:Angle())
		phys:SetVelocityInstantaneous((0.1 + math.Clamp((CurTime() - self.Created) / self.AccelTime, 0, 1) * 0.9) * self.ThrowForce * self.Dir)

		self.Dir.z = self.Dir.z - FrameTime() * 0.2
		self.Dir:Normalize()
	end
end

function ENT:SetThrown(m)
	self:SetDTBool(0, m)

	self:CollisionRulesChanged()

	if SERVER then
		self:SetModelScale(m and 0.85 or 0.2, 0)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableGravity(false)
			phys:EnableDrag(false)
		end
	end
end

function ENT:GetThrown()
	return self:GetDTBool(0)
end

if CLIENT then

util.PrecacheSound("vehicles/v8/v8_start_loop1.wav")
util.PrecacheSound("vehicles/v8/v8_turbo_on_loop1.wav")

local matLight = Material("sprites/light_ignorez")
function ENT:DrawSpotlight(offset)
	local epos = self:LocalToWorld(offset)
	local LightNrm = self:GetForward()
	local ViewNormal = epos - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )

	if ViewDot >= 0 then
		local LightPos = epos + LightNrm * 5

		render.SetMaterial(matLight)
		local Visibile = util.PixelVisible(LightPos, 16, self.PixVis)

		if not Visibile then return end

		local Size = math.Clamp(Distance * Visibile * ViewDot * 1.8, 40, 420) * self:GetModelScale()

		Distance = math.Clamp(Distance, 32, 800)
		local Alpha = math.Clamp((1000 - Distance) * Visibile * ViewDot, 0, 100)
		local Col = Color(255, 255, 255, Alpha)

		render.DrawSprite(LightPos, Size, Size, Col, Visibile * ViewDot)
		render.DrawSprite(LightPos, Size * 0.4, Size * 0.4, Col, Visibile * ViewDot)
	end
end

local matShiny = Material("models/shiny")
function ENT:Draw()
	if self:GetThrown() then
		self:SetRenderAngles(self:GetVelocity():Angle())
	end

	self.BaseClass.Draw(self)

	render.ModelMaterialOverride(matShiny)
	render.SetBlend(0.2)
	self:DrawModel()
	render.SetBlend(1)
	render.ModelMaterialOverride()

	self:DrawSpotlight(Vector(48, 30, 4) * self:GetModelScale())
	self:DrawSpotlight(Vector(48, -30, 4) * self:GetModelScale())
end
ENT.DrawTranslucent = ENT.Draw

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	self.PixVis = util.GetPixelVisibleHandle()

	self.AmbientSound = CreateSound(self, "vehicles/v8/v8_start_loop1.wav")
	self.ThrownSound = CreateSound(self, "vehicles/v8/v8_turbo_on_loop1.wav")
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	self.AmbientSound:Stop()
	self.ThrownSound:Stop()
end

function ENT:Think()
	self.BaseClass.Think(self)

	if self:GetThrown() then
		self.ThrownSound:Play(0.8, 150 + CurTime() % 1)
		self.AmbientSound:Stop()
	else
		self.ThrownSound:Stop()
		self.AmbientSound:PlayEx(0.7, 150 + CurTime() % 1)
	end
end

return end

function ENT:SetCarrier(ent)
	if self:GetThrown() and IsValid(ent) then return end

	self.BaseClass.SetCarrier(self, ent)
end

function ENT:OnThink()
	if self.PhysicsData then
		self:HitObject(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	elseif self.TouchedEnemy then
		self:HitObject(nil, nil, self.TouchedEnemy)
	end

	if not self.Exploded then
		local pos = self:GetPos()
		if not self:GetCarrier():IsValid() then
			local oldpos = self.LastPos
			if oldpos then
				local tr = util.TraceLine({start = oldpos, endpos = pos, mask = MASK_SOLID_BRUSHONLY})
				if tr.Hit then
					self:Explode(tr.HitPos, tr.HitNormal)
				end
			end
		end

		self.LastPos = pos
	end
end

function ENT:Explode(hitpos, hitnormal)
	hitpos = hitpos or self:GetPos()
	hitnormal = hitnormal or self:GetForward()

	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
	util.Effect("barrelexplosion", effectdata)

	util.BlastDamage(self, self:GetLastCarrier():IsValid() and self:GetLastCarrier() or self, hitpos, 300, 20)
	util.ScreenShake(hitpos, 500, 0.5, 1, 300)

	local basepos = hitpos + hitnormal * 64

	for _, model in pairs(RandomProps) do
		local ent = ents.Create("prop_physics_multiplayer")
		if ent:IsValid() then
			ent:SetPos(basepos + Vector(math.Rand(-64, 64), math.Rand(-64, 64), math.Rand(0, 48)))
			ent:SetAngles(AngleRand())
			ent:SetModel(model)
			ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocityInstantaneous((Vector(0, 0, 1) + VectorRand():GetNormalized()):GetNormalized() * math.Rand(600, 1300))
				phys:AddAngleVelocity(VectorRand() * math.Rand(300, 1200))
			end

			ent:Fire("kill", "", math.random(8, 12))

			if math.random(3) == 1 then
				ent:Ignite(15, 0)
				local fire = ents.Create("env_fire_trail")
				if fire:IsValid() then
					fire:SetPos(ent:GetPos())
					fire:Spawn()
					fire:SetParent(ent)
				end
			end
		end
	end

	self:Remove()
end

function ENT:PhysicsCollide(data, phys)
	if self:GetThrown() then
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
		hitent:EmitSound("vehicles/v8/vehicle_impact_medium"..math.random(4)..".wav")
		hitent:KnockDown()
		hitent:SetGroundEntity(NULL)
		hitent:SetVelocity((self:GetVelocity():GetNormalized() + Vector(0, 0, 1)):GetNormalized() * 1100)
		hitent:TakeDamage(30, self:GetLastCarrier(), self)
	end
end

function ENT:OnTouch(ent)
	if ent:IsPlayer() and ent:Alive() and self:GetThrown() and ent:Team() ~= self:GetLastCarrierTeam() and CurTime() >= (self.NextTouch[ent] or 0) then
		self.NextTouch[ent] = CurTime() + 0.5
		self.TouchedEnemy = ent
	end
end
