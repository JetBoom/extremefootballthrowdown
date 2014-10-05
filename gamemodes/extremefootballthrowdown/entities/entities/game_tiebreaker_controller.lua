AddCSLuaFile()

ENT.Type = "point"

ENT.RoundsToWin = 2
ENT.RoundTime = 90
ENT.SpectateRadius = 350

AccessorFuncDT(ENT, "RedPlayer", "Entity", 0)
AccessorFuncDT(ENT, "BluePlayer", "Entity", 1)
AccessorFuncDT(ENT, "Round", "Int", 0)
AccessorFuncDT(ENT, "RedPlayerWins", "Int", 1)
AccessorFuncDT(ENT, "BluePlayerWins", "Int", 2)
AccessorFuncDT(ENT, "RoundStart", "Float", 0)
AccessorFuncDT(ENT, "RoundEnd", "Float", 1)

function ENT:Initialize()
	GAMEMODE.TieBreaker = self

	if SERVER then
		self:SetRound(1)

		hook.Add("PlayerSpawn", self, self.PlayerSpawn)

		self:Setup()

		self:NextThink(CurTime() + 5)
	end
end

function ENT:OnRemove()
	GAMEMODE.TieBreaker = nil
end

if CLIENT then return end

function ENT:Think()
	local ent = ents.Create("prop_carry_melon")
	if ent:IsValid() then
		ent:SetPos(self:GetPos() + Vector(math.Rand(-256, 256), 0, 256))
		ent:Spawn()
		ent:Fire("kill", "", 5)
	end

	self:NextThink(CurTime() + math.Rand(0.5, 5))
	return true
end

local function DoPlayerSpawn(self, pl)
	if not IsValid(self) or not IsValid(pl) then return end

	if team.Joinable(pl:Team()) and pl:Alive() then
		pl:SetPos(self:GetPos() + Angle(0, math.Rand(0, 180), 0):Forward() * self.SpectateRadius)
		pl:SetState(STATE_FIGHTER2D_WATCH)
	end
end

function ENT:PlayerSpawn(pl)
	timer.Simple(0, function()
		DoPlayerSpawn(self, pl)
	end)
end

function ENT:Setup()
	local specs = {}
	for _, pl in pairs(player.GetAll()) do
		if team.Joinable(pl:Team()) then
			pl:Spawn()

			if pl:Alive() and pl ~= self:GetRedPlayer() and pl ~= self:GetBluePlayer() then
				table.insert(specs, pl)
			end
		end
	end

	local numspecs = #specs
	if numspecs == 0 then return end

	local rot = 120 / numspecs
	local ang = Angle(0, 30, 0)
	for k, pl in pairs(specs) do
		print("spec", pl)
		ang.yaw = (k - 1) * rot
		pl:SetPos(self:GetPos() + ang:Forward() * self.SpectateRadius)
		pl:SetState(STATE_FIGHTER2D_WATCH)
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end
