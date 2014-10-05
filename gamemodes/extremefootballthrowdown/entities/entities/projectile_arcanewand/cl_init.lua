include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
	self:DrawShadow(false)

	self.AmbientSound = CreateSound(self, "ambient/energy/force_field_loop1.wav")
end

function ENT:Think()
	self.AmbientSound:PlayEx(0.7, math.max(120, 230 - EyePos():Distance(self:GetPos()) * 0.12))
end

function ENT:OnRemove()
	self.AmbientSound:Stop()
end

local matRefract = Material("refract_ring")
local matRing = Material("effects/select_ring")
function ENT:Draw()
	local pos = self:GetPos()
	local col = self:GetColor()

	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.Pos = pos
		dlight.r = col.r
		dlight.g = col.g
		dlight.b = col.b
		dlight.Brightness = 5
		dlight.Size = 200
		dlight.Decay = 800
		dlight.DieTime = CurTime() + 1
	end

	local basesize = 58
	local size1 = basesize + math.sin(RealTime() * 35) * 12
	local size2 = basesize + math.cos(RealTime() * 38) * 8
	render.SetMaterial(matRing)
	render.DrawSprite(pos, size1, size1, col)
	render.DrawSprite(pos, size2, size2, col)

	matRefract:SetFloat("$refractamount", 0.75 + math.abs(math.sin(CurTime() * 5)) * math.pi * 0.25)
	render.SetMaterial(matRefract)
	render.UpdateRefractTexture()
	render.DrawSprite(pos, basesize, basesize, color_white)
end
