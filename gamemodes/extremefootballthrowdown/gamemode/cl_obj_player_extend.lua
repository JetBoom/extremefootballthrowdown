local meta = FindMetaTable("Player")
if not meta then return end

local IN_FORWARD = IN_FORWARD
local LocalPlayer = LocalPlayer
local SPEED_CHARGE_SQR = SPEED_CHARGE_SQR

function meta:CanCharge()
	return self:GetState() == STATE_NONE and self:GetStateInteger() == 0
	--[[and self:OnGround()]] and not self:Crouching() and self:WaterLevel() <= 1
	and (LocalPlayer() ~= self or self:KeyDown(IN_FORWARD))
	and self:ChargingSpeedSqr() >= SPEED_CHARGE_SQR
end

function meta:GetStatus(sType)
	for _, ent in pairs(ents.FindByClass("status_"..sType)) do
		if ent:GetOwner() == self then return ent end
	end
end

function meta:RemoveAllStatus(bSilent, bInstant)
end

function meta:RemoveStatus(sType, bSilent, bInstant)
end

function meta:GiveStatus(sType, fDie)
end

function meta:IsFriend()
	return self.m_IsFriend
end

timer.Create("checkfriend", 5, 0, function()
	-- This probably isn't the fastest function in the world so I cache it.
	for _, pl in pairs(player.GetAll()) do
		pl.m_IsFriend = pl:GetFriendStatus() == "friend"
	end
end)

function meta:EndState(nocallended)
	if self == MySelf then
		self:SetState(STATE_NONE, nil, nil, nocallended)
	end
end

function meta:ThirdPersonCamera(camerapos, origin, angles, fov, znear, zfar, lerp, right)
	lerp = lerp or 1
	right = right or 16

	local newcamerapos = origin + angles:Right() * right + angles:Forward() * -16

	camerapos:Set(camerapos * (1 - lerp) + newcamerapos * lerp)
end
