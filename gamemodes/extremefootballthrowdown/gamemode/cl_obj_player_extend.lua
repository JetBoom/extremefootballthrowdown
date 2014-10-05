local meta = FindMetaTable("Player")
if not meta then return end

function meta:FixModelAngles(velocity)
	local eye = self:EyeAngles()
	self:SetLocalAngles(eye)
	self:SetRenderAngles(eye)
	self:SetPoseParameter("move_yaw", math.NormalizeAngle(velocity:Angle().yaw - eye.y))
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

timer.Create("checkfriend", 1, 0, function()
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
