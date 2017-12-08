AddCSLuaFile()

ENT.Type = "anim"

ENT.LifeTime = 8

AccessorFuncDT(ENT, "DieTime", "Float", 0)

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	self:SetDieTime(CurTime() + self.LifeTime)

	if SERVER and self:GetOwner():IsValid() then
		self:GetOwner():SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)
	end

	if CLIENT then
		hook.Add("CreateMove", self, self.CreateMove)
		hook.Add("RenderScreenspaceEffects", self, self.RenderScreenspaceEffects)
	end
end

if SERVER then
function ENT:Think()
	local owner = self:GetOwner()
	if not owner:IsValid() or not owner:Alive() or CurTime() >= self:GetDieTime() then self:Remove() end
	owner:SetDSP(7)

	self:NextThink(CurTime())
	return true
end

function ENT:OnRemove()
	local owner = self:GetOwner()
	owner:SetDSP(0)
end
end

if not CLIENT then return end

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:CreateMove(cmd)
	if LocalPlayer() ~= self:GetOwner() then return end

	local delta = math.Clamp(self:GetDieTime() - CurTime(), 0, 1) * FrameTime() * 60

	local ang = cmd:GetViewAngles()

	ang:RotateAroundAxis(ang:Right(), math.sin(CurTime() * 2) * delta * 0.75)
	ang:RotateAroundAxis(ang:Up(), math.cos(CurTime() * 2) * delta)

	ang.pitch = math.Clamp(ang.pitch, -179, 179)
	ang.roll = 0

	cmd:SetViewAngles(ang)
end

local matBooze = Material("Effects/tp_refract")
function ENT:RenderScreenspaceEffects()
	if LocalPlayer() ~= self:GetOwner() then return end

	local delta = math.Clamp(self:GetDieTime() - CurTime(), 0, 1)

	matBooze:SetFloat("$refractamount", delta * (1 + math.abs(math.sin(CurTime())) * 0.1))
	render.UpdateRefractTexture()

	render.SetBlend(delta)
	render.SetMaterial(matBooze)
	render.DrawScreenQuad()
	render.SetBlend(1)
end

function ENT:DrawTranslucent()

end
