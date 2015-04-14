include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:DrawTranslucent()
	local col = self:GetColor()
	--self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	cam.Start3D2D(pos, ang, 0.1)
		draw.SimpleText("00", "eft_3djerseytext", 0, -32, col, TEXT_ALIGN_CENTER)
		draw.SimpleText("ALLENS", "eft_3djerseytext", 0, 32, col, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
