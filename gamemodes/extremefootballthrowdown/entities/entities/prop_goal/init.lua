AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.m_TeamID = TEAM_RED
ENT.m_Points = 1

function ENT:Initialize()
	self:SetModel("models/props_lab/teleplatform.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetTrigger(true)
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:EnableMotion(false) end
end

function ENT:KeyValue(key, value)
	if key == "points" then
		self:SetPoints(tonumber(value) or 1)
	elseif key == "teamid" then
		self:SetTeamID(tonumber(value) or TEAM_RED)
	end
end

function ENT:Touch(ent)
	if ent:IsPlayer() and not GAMEMODE:IsWarmUp() then
		local carry = ent:GetCarry()
		if carry:IsValid() and GAMEMODE:GetBall() == carry then
			local myteam = self:GetTeamID()
			local opposite = GAMEMODE:GetOppositeTeam(myteam)
			if ent:Team() == opposite then
				gamemode.Call("TeamScored", opposite, ent, self:GetPoints())
			end
		end
	end
end

function ENT:SetPoints(points)
	self.m_Points = points
end

function ENT:GetPoints()
	return self.m_Points
end

function ENT:SetTeamID(id)
	self.m_TeamID = id
	local col = team.GetColor(id)
	if col then
		local mycol = self:GetColor()
		mycol.r = col.r
		mycol.g = col.g
		mycol.b = col.b
		self:SetColor(mycol)
	end
end

function ENT:GetTeamID()
	return self.m_TeamID
end
