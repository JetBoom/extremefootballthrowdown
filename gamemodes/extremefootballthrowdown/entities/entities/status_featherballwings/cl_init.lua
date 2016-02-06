include("shared.lua")

ENT.FlapTime = 0
ENT.FlapPower = 0

local NotZero = {
	"Crow.Phalanges1_L",
	"Crow.Phalanges2_L",
	"Crow.Phalanges3_L",
	"Crow.Phalanges1_R",
	"Crow.Phalanges2_R",
	"Crow.Phalanges3_R"
}
function ENT:Initialize()
	self:SharedInitialize()

	local vsmall = Vector(0.01, 0.01, 0.01)
	for i=0, self:GetBoneCount() do
		self:ManipulateBoneScale(i, vsmall)
	end
	local vnotsmall = Vector(4.5, 4.5, 4.5)
	for _, bonename in pairs(NotZero) do
		local boneid = self:LookupBone(bonename)
		if boneid and boneid > 0 then
			self:ManipulateBoneScale(boneid, vnotsmall)
		end
	end
end

function ENT:Draw()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	local boneid = owner:LookupBone("ValveBiped.Bip01_Spine4")
	if not boneid or boneid == 0 then return end

	local pos, ang = owner:GetBonePositionMatrixed(boneid)
	pos = pos - ang:Right() * 4
	ang:RotateAroundAxis(ang:Up(), -30)
	ang:RotateAroundAxis(ang:Forward(), 90)

	self.FlapPower = math.Approach(self.FlapPower, owner:OnGround() and 0 or 1, FrameTime() * 1.75)
	self.FlapTime = self.FlapTime + (0.5 + 6 * self.FlapPower) * FrameTime()

	self:SetSequence(self:LookupSequence("Fly01"))
	self:SetCycle(math.abs(math.sin(self.FlapTime)) * (0.05 + 0.035 * self.FlapPower))
	self:SetPos(pos)
	self:SetAngles(ang)
	self:DrawModel()
end
