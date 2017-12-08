AddCSLuaFile()

ENT.Type = "anim"

ENT.LifeTime = 2.5

AccessorFuncDT(ENT, "DieTime", "Float", 0)

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	if SERVER then
		local owner = self:GetOwner()
		if owner:IsValid() then
			owner:SetGravity(-0.15)
			owner:SetState(STATE_SPINNYKNOCKDOWN, STATES[STATE_SPINNYKNOCKDOWN].Time)
			owner:SetGroundEntity(NULL)
			owner:SetVelocity(Vector(0, 0, 32))
			owner:SetDSP(23)
		end

		self:SetDieTime(CurTime() + self.LifeTime)
		self:Fire("kill", "", self.LifeTime)
	end

	if CLIENT then
		hook.Add("CreateMove", self, self.CreateMove)
		hook.Add("RenderScreenspaceEffects", self, self.RenderScreenspaceEffects)
	end
end

if SERVER then
function ENT:OnRemove()
	local owner = self:GetParent()
	if owner:IsValid() then
		owner:SetGravity(1)
		owner:SetDSP(0)
	end
end
end

if not CLIENT then return end

ENT.RenderGroup = RENDERGROUP_OPAQUE

local matOverlay = Material("Effects/tp_eyefx/tpeye3")
function ENT:RenderScreenspaceEffects()
	if LocalPlayer() ~= self:GetOwner() then return end

	render.SetBlend(math.Clamp((self:GetDieTime() - CurTime()) * 3, 0, 1))
	render.SetMaterial(matOverlay)
	render.DrawScreenQuad()
	render.SetBlend(1)
end

function ENT:Draw()
end
