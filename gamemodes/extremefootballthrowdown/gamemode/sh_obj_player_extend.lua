local meta = FindMetaTable("Player")
if not meta then return end

function meta:SetState(state, duration, ent, nocallended)
	local oldstate = self:GetState()
	if oldstate ~= state and not nocallended then
		self:CallForcedStateFunction(oldstate, "Ended", state)
	end
	self:SetDTInt(0, state)
	self:SetStateStart(CurTime())
	if duration then
		self:SetStateEnd(CurTime() + duration)
	else
		self:SetStateEnd(0)
	end
	if ent then
		self:SetStateEntity(ent)
	else
		self:SetStateEntity(NULL)
	end

	if oldstate == state then
		self:CallForcedStateFunction(state, "Restarted")
	else
		self:CallForcedStateFunction(state, "Started", oldstate)
	end
end
function meta:GetState() return self:GetDTInt(0) end
function meta:GetStateTable() return STATES[self:GetState()] end
function meta:GetStateStart() return self:GetDTFloat(0) end
function meta:GetStateEnd() return self:GetDTFloat(1) end
function meta:GetStateNumber() return self:GetDTFloat(2) end
function meta:GetStateInteger() return self:GetDTInt(2) end
function meta:GetStateEntity() return self:GetDTEntity(0) end
function meta:GetStateVector() return self:GetDTVector(0) end
function meta:GetStateAngles() return self:GetDTAngle(0) end
function meta:GetStateBool() return self:GetDTBool(0) end
function meta:GetStateBool2() return self:GetDTBool(1) end
function meta:SetStateStart(time) self:SetDTFloat(0, time) end
function meta:SetStateEnd(time) self:SetDTFloat(1, time) end
function meta:SetStateNumber(num) self:SetDTFloat(2, num) end
function meta:SetStateInteger(int) self:SetDTInt(2, int) end
function meta:SetStateEntity(ent) self:SetDTEntity(0, ent) end
function meta:SetStateVector(vec) self:SetDTVector(0, vec) end
function meta:SetStateAngles(ang) self:SetDTAngle(0, ang) end
function meta:SetStateBool(bool) self:SetDTBool(0, bool) end
function meta:SetStateBool2(bool) self:SetDTBool(1, bool) end

function meta:SetCollisionMode(mode)
	if mode ~= self:GetDTInt(3) then
		self:SetDTInt(3, mode)
		--self:SetCustomCollisionCheck(mode > COLLISION_NORMAL)
		self:CollisionRulesChanged()
	end
end

function meta:GetCollisionMode(mode)
	return self:GetDTInt(3)
end

function meta:MaxCollisionMode(mode)
	self:SetCollisionMode(math.max(self:GetCollisionMode(), mode))
end

function meta:MinCollisionMode(mode)
	self:SetCollisionMode(math.min(self:GetCollisionMode(), mode))
end

local STATES = STATES
function meta:CallStateFunction(name, ...)
	local statetab = STATES[self:GetState()]
	local func = statetab[name]
	if func then
		return func(statetab, self, ...)
	end
end

function meta:CallForcedStateFunction(state, name, ...)
	local statetab = STATES[state]
	local func = statetab[name]
	if func then
		return func(statetab, self, ...)
	end
end

function meta:ThinkSelf()
	if self:GetState() ~= STATE_NONE and self:GetStateEnd() > 0 and CurTime() >= self:GetStateEnd() and not self:CallStateFunction("GoToNextState") then
		self:EndState()
	end

	self:CallStateFunction("Think")
end

function meta:IsOnPlayer()
	local pos = self:GetPos()

	local hitent = util.TraceLine({start = pos, endpos = pos + Vector(0, 0, -16), mins = self:OBBMins() * 0.9, maxs = self:OBBMaxs() * 0.9, filter = team.GetPlayers(self:Team()), ignoreworld = true}).Entity

	return hitent and hitent:IsValid() and hitent:IsPlayer()
end

function meta:ChargingSpeedSqr()
	if self:OnGround() then
		return self:GetVelocity():LengthSqr()
	end

	return self:GetVelocity():Length2DSqr()
end

function meta:ChargingSpeed()
	if self:OnGround() then
		return self:GetVelocity():Length()
	end

	return self:GetVelocity():Length2D()
end

function meta:GetCarry()
	return self:GetDTEntity(3)
end
meta.GetCarrying = meta.GetCarry

function meta:SetCarry(ent)
	self:SetDTEntity(3, ent)
end
meta.SetCarrying = meta.SetCarry

function meta:HasPity()
	return team.HasPity(self:Team())
end

function meta:IsCarrying()
	return self:GetCarry():IsValid()
end

function meta:IsCarryingBall()
	return self:IsCarrying() and self:GetCarry() == GAMEMODE.Ball
end

function meta:CanThrow()
	return self:IsIdle() and self:IsCarrying() and self:OnGround() --and self:GetVelocity():LengthSqr() <= 75625
end

function meta:SetNextMoveVelocity(vel)
	self:SetDTVector(3, vel)
end

function meta:GetNextMoveVelocity()
	return self:GetDTVector(3)
end

function meta:IsIdle()
	return self:CallStateFunction("IsIdle")
end

function meta:CanMelee()
	return (self:OnGround() or self:IsSwimming()) and self:IsIdle()
end

function meta:CanDodge()
	return self:IsIdle() and self:OnGround()
end

function meta:CallCarryFunction(name, ...)
	local carry = self:GetCarry()
	if carry:IsValid() and carry[name] then
		return carry[name](carry, self, ...)
	end
end

function meta:SetLastChargeHit(time)
	self:SetDTFloat(3, time)
end

function meta:GetLastChargeHit()
	return self:GetDTFloat(3)
end

function meta:GetTraceFilter(excludeball)
	local filter = team.GetPlayers(self:Team())
	if not excludeball then
		filter[#filter + 1] = GAMEMODE.Ball
	end
	filter[#filter + 1] = GAMEMODE.BallTrigger
	return filter
end

function meta:GetLaunchPos(offset)
	return self:GetPos() + Vector(0, 0, -(offset or 18))
end

function meta:ImmuneToAll()
	return self:CallStateFunction("ImmuneToAll")
end

function meta:GetTargetTrace()
	local start = self:LocalToWorld(self:OBBCenter())
	return util.TraceHull({start = start, endpos = start + self:GetForward() * self:BoundingRadius(), mins = self:OBBMins() * 0.75, maxs = self:OBBMaxs() * 0.75, filter = self:GetTraceFilter(), mask = MASK_SHOT})
end

local P_Team = meta.Team
local E_IsValid = FindMetaTable("Entity").IsValid
local P_GetCollisionMode = meta.GetCollisionMode
local COLLISION_NORMAL = COLLISION_NORMAL
local COLLISION_PASSTHROUGH = COLLISION_PASSTHROUGH
local COLLISION_AVOID = COLLISION_AVOID
function meta:ShouldNotCollide(ent)
	if P_GetCollisionMode(self) > COLLISION_NORMAL then
		return E_IsValid(ent) and ent:IsPlayer()
	end

	return E_IsValid(ent) and ent:IsPlayer() and P_Team(ent) == P_Team(self)
end

local function InvalidateCompensatedTrace(tr, start, distance)
	-- Need to do this or people with 300 ping will be hitting people across rooms
	if tr.Entity:IsValid() and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(start) > distance * distance + 144 then -- Give just a little bit of leeway
		tr.Hit = false
		tr.HitNonWorld = false
		tr.Entity = NULL
	end
end

function meta:GetSweepTargets(range, fov, addfilter, cross, excludeball, compensate)
	local traces = {}

	range = range or self:BoundingRadius()
	fov = fov or 45
	size = size or 8

	local ang = self:EyeAngles()
	local up = ang:Up()
	local maxs = size * 0.5 * Vector(1, 1, 1)

	ang:RotateAroundAxis(up, fov * -0.5)

	local filter = self:GetTraceFilter(excludeball)
	if addfilter then
		table.Add(filter, addfilter)
	end

	local uncompstart = self:WorldSpaceCenter()

	if compensate then
		self:LagCompensation(true)
	end

	local start = self:WorldSpaceCenter()
	local trace = {start = start, mins = maxs * -1, maxs = maxs, filter = filter, mask = MASK_SHOT}

	for a=0, fov, 2 do
		ang:RotateAroundAxis(up, 2)
		trace.endpos = start + ang:Forward() * (range - size / 2)

		for i=1, 20 do
			local tr = util.TraceHull(trace)
			local ent = tr.Entity
			if ent and ent:IsValid() then
				table.insert(traces, tr)
				table.insert(filter, ent)
			else
				break
			end
		end

		for i=1, 20 do
			local tr = util.TraceLine(trace)
			local ent = tr.Entity
			if ent and ent:IsValid() then
				table.insert(traces, tr)
				table.insert(filter, ent)
			else
				break
			end
		end
	end

	if cross then
		ang = self:EyeAngles()
		local right = ang:Up()

		ang:RotateAroundAxis(right, fov * -0.5)

		for a=0, fov, 2 do
			ang:RotateAroundAxis(right, 2)
			trace.endpos = start + ang:Forward() * (range - size / 2)

			for i=1, 20 do
				local tr = util.TraceHull(trace)
				local ent = tr.Entity
				if ent and ent:IsValid() then
					table.insert(traces, tr)
					table.insert(filter, ent)
				else
					break
				end
			end

			for i=1, 20 do
				local tr = util.TraceLine(trace)
				local ent = tr.Entity
				if ent and ent:IsValid() then
					table.insert(traces, tr)
					table.insert(filter, ent)
				else
					break
				end
			end
		end
	end

	if compensate then
		self:LagCompensation(false)

		for _, trr in pairs(traces) do
			InvalidateCompensatedTrace(trr, uncompstart, range)
		end
	end

	return traces
end

function meta:GetTargets(range, addfilter, fatness, excludeball, compensate)
	fatness = fatness or 0.75

	local traces = {}

	local filter = self:GetTraceFilter(excludeball)
	if addfilter then
		table.Add(filter, addfilter)
	end

	range = range or self:BoundingRadius()

	local uncompstart = self:WorldSpaceCenter()

	if compensate then
		self:LagCompensation(true)
	end

	local start = self:WorldSpaceCenter()
	local trace = {start = start, endpos = start + self:GetForward() * range, mins = self:OBBMins() * fatness, maxs = self:OBBMaxs() * fatness, filter = filter, mask = MASK_SHOT}

	local tr, ent

	for i=1, 20 do
		tr = util.TraceHull(trace)
		ent = tr.Entity
		if ent and ent:IsValid() then
			table.insert(traces, tr)
			table.insert(trace.filter, ent)
		else
			break
		end
	end

	-- Fixes being able to hide in tight spaces.
	for i=1, 20 do
		tr = util.TraceLine(trace)
		ent = tr.Entity
		if ent and ent:IsValid() then
			table.insert(traces, tr)
			table.insert(trace.filter, ent)
		else
			break
		end
	end

	if compensate then
		self:LagCompensation(false)

		for _, trr in pairs(traces) do
			InvalidateCompensatedTrace(trr, uncompstart, range)
		end
	end

	return traces
end

function meta:TargetsContain(ent, range, addfilter)
	for _, tr in pairs(self:GetTargets(range, addfilter)) do
		if tr.Entity == ent then return tr end
	end
end

function meta:GetPotentialCarry()
	return self:GetDTEntity(2)
end

function meta:SetPotentialCarry(ent)
	self:SetDTEntity(2, ent)
end

function meta:PenetratingTraceHull(distance, mask, size, filter, maxpenetrate, noworldifhitent)
	local t = {}

	local vStart = self:GetShootPos()
	local trace = {start = vStart, endpos = vStart + self:GetAimVector() * distance, filter = filter or {self}, mask = mask, mins = Vector(-size, -size, -size), maxs = Vector(size, size, size)}
	local worldtrace
	while not maxpenetrate or #t < maxpenetrate do
		local tr = util.TraceHull(trace)
		local ent = tr.Entity
		if ent and ent:IsValid() then
			table.insert(t, tr)
			table.insert(trace.filter, ent)
		else
			worldtrace = tr
			break
		end
	end

	if worldtrace and not (noworldifhitent and #t > 0) then
		table.insert(t, worldtrace)
	end

	return t
end

function meta:ResetJumpPower(power)
	power = power or self:GetPlayerClass().JumpPower

	if power then
		self:SetJumpPower(power)
	end
end

function meta:GetLastAttacker()
	local ent = self.LastAttacker
	if ent then
		if ent:IsValid() and ent:Team() ~= self:Team() and CurTime() <= self.LastAttacked + 10 then
			return ent
		end

		self:SetLastAttacker()
	end
end

function meta:ShouldBeFrozen()
	return GAMEMODE.IsEndOfGame
end

function meta:TranslateWeaponActivity(act)
	return act
end

function meta:ShouldCompensate()
	return self:Ping() <= 150
end

local OldFreeze = meta.Freeze
function meta:Freeze(freeze)
	if freeze == nil then freeze = true end

	if not freeze and self:ShouldBeFrozen() then
		freeze = true
	end

	OldFreeze(self, freeze)
end

function meta:SetLastAttacker(ent)
	if ent then
		self.LastAttacker = ent
		self.LastAttacked = CurTime()
	else
		self.LastAttacker = nil
		self.LastAttacked = nil
	end
end
