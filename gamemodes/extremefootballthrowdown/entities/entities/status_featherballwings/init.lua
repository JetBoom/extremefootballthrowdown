AddCSLuaFile("shared.lua")
AddCSLuaFile("init.lua")

include("shared.lua")

function ENT:Initialize()
	self:SharedInitialize()
end
