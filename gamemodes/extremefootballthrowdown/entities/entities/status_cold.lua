AddCSLuaFile()

ENT.Type = "anim"

ENT.LifeTime = 5

AccessorFuncDT(ENT, "DieTime", "Float", 0)

function ENT:Initialize()
	self.StartTime = CurTime()
	self:DrawShadow(false)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)

	self:SetDieTime(self.StartTime + self.LifeTime)

	local owner = self:GetOwner()
	if not owner:IsValid() or not owner:Alive() then self:Remove() return end

	if SERVER then
		owner:Freeze(true)
		hook.Add("KeyPress", self, self.KeyPress)
		hook.Add("PrimaryAttack", self, self.KeyPress)
		hook.Add("SecondaryAttack", self, self.KeyPress)
		hook.Add("Reload", self, self.KeyPress)
	end
	if CLIENT then
		hook.Add("RenderScreenspaceEffects", self, self.RenderScreenspaceEffects)
	end
end

if SERVER then

function ENT:Think()
	local owner = self:GetOwner()
	if not owner:IsValid() or not owner:Alive() or CurTime() >= self:GetDieTime() then self:Remove() end

	local col = team.GetColor(owner:Team())
	owner:SetMaterial("models/debug/debugwhite")
	owner:SetColor(col)
	self:NextThink(CurTime())

	return true
end

function ENT:KeyPress(pl, key)
	if pl ~= self:GetOwner() then return end
	return true
end

end

function ENT:OnRemove()
	local owner = self:GetOwner()
	if not owner:IsValid() or not owner:Alive() then self:Remove() return end
	owner:SetColor(Color(255,255,255,255))
	owner:SetMaterial()
	owner:Freeze(false)
end

if not CLIENT then return end

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

local mat = Material("overlays/statuscold")
function ENT:RenderScreenspaceEffects()
	if LocalPlayer() ~= self:GetOwner() then return end

	local startalpha = CurTime() - self.StartTime
	local delta = 1
	local alpha = 0

	if startalpha <= 1 then
		alpha = startalpha
	else
		delta = math.Clamp(self:GetDieTime() - CurTime(), 0, 1)
		alpha = delta * (1 + math.abs(math.sin(CurTime())) * 0.1)
	end
	mat:SetFloat("$alpha", alpha)

	render.SetBlend(delta)
	render.SetMaterial(mat)
	render.DrawScreenQuad()
end

function ENT:DrawTranslucent()
end
