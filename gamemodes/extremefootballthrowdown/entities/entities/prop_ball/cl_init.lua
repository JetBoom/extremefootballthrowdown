include("shared.lua")

util.PrecacheSound("weapons/physcannon/energy_sing_loop4.wav")

ENT.LerpSpeed = 0

function ENT:Initialize()
	self.PreviousState = self:GetState()

	self.FlySound = CreateSound(self, "weapons/physcannon/energy_sing_loop4.wav")

	gamemode.Call("SetBall", self)
	gamemode.Call("SetBallHome", self:GetPos())
end

function ENT:Think()
	local speed = self:GetVelocity():Length()
	self.LerpSpeed = math.Approach(self.LerpSpeed, speed, FrameTime() * 3500)

	self:AlignToCarrier()
	if self:GetCarrier():IsValid() then
		self.FlySound:Stop()
	else
		self.FlySound:PlayEx(math.Clamp(self.LerpSpeed / 1000, 0.05, 0.9) ^ 0.5, 75 + math.Clamp(self.LerpSpeed / 1500, 0, 1) * 100)
	end

	if self:GetState() ~= self.PreviousState then
		local newstate = self:GetState()
		self:SetState(self.PreviousState)
		self:CallStateFunction("End")
		self:SetState(newstate)
		self:CallStateFunction("Start", false)
		self.PreviousState = newstate
	end

	self:CallStateFunction("Think")

	self:NextThink(CurTime())
	return true
end

function ENT:DrawTranslucent()
	self:AlignToCarrier()

	if not self:CallStateFunction("PreDraw") then
		self:DefaultDraw()
	end

	self:CallStateFunction("PostDraw")
end

ENT.NextEmit = 0
ENT.NextStateEmit = 0
function ENT:CreateSpeedParticles(col)
	if CurTime() < self.NextEmit and self:GetCarrier():IsValid() then return end
	self.NextEmit = CurTime() + 0.02

	local vel = self:GetVelocity()
	local speed = vel:Length()
	if speed > 200 then
		local size = math.Clamp((speed - 200) * 0.05, 8, 24)
		local pos = self:GetPos()

		local emitter = ParticleEmitter(pos)
		emitter:SetNearClip(24, 32)

		local particle = emitter:Add("effects/fire_embers"..math.random(3), pos)
		particle:SetVelocity((vel * 0.6 + VectorRand():GetNormalized()) / 3)
		particle:SetDieTime(math.Rand(0.5, 0.8))
		particle:SetStartSize(size)
		particle:SetEndSize(size * 0.25)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-15, 15))
		particle:SetColor(col.r, col.g, col.b)

		particle = emitter:Add("particles/smokey", pos)
		particle:SetDieTime(math.Rand(1, 1.25))
		particle:SetStartSize(size * 0.25)
		particle:SetEndSize(size)
		particle:SetStartAlpha(80)
		particle:SetEndAlpha(0)
		particle:SetRoll(math.Rand(0, 360))
		particle:SetRollDelta(math.Rand(-5, 5))
		particle:SetColor(col.r * 0.4, col.g * 0.4, col.b * 0.4)

		emitter:Finish()
	end
end

local matGlow = Material("sprites/light_glow02_add")
local matRing = Material("effects/select_ring")
function ENT:DefaultDraw()
	self:DrawModel()

	local col = self:CallStateFunction("GetBallColor", self:GetCarrier()) or color_white

	self:CreateSpeedParticles(col)

	render.SetMaterial(matGlow)
	local pos = self:GetPos()
	local size = 64 + math.max(0, (math.sin(CurTime() * 8) - 0.25) * 24)
	render.DrawSprite(pos, size, size, col)

	render.SetMaterial(matRing)
	render.DrawSprite(pos, 24, 24, col)
	render.DrawSprite(pos, 27, 27, col)
	render.DrawSprite(pos, 30, 30, col)
	render.DrawSprite(pos, 35, 35, col)
end
