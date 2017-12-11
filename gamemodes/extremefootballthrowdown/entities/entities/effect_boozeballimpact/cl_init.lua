include("shared.lua")

util.PrecacheSound("physics/glass/glass_largesheet_break1.wav")
util.PrecacheSound("physics/glass/glass_largesheet_break2.wav")
util.PrecacheSound("physics/glass/glass_largesheet_break3.wav")

function ENT:Draw()
	local fadescale = math.max(0,self.EndTime - CurTime())
	if fadescale < 1 then 
		self:SetColor(Color(100,50,50,fadescale*255))
	else
		self:SetColor(Color(100, 50, 50, 255))
	end
	self:DrawModel()
end

function ENT:OnRemove()
end
