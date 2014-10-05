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

	if oldstate ~= state then
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
function meta:SetStateStart(time) self:SetDTFloat(0, time) end
function meta:SetStateEnd(time) self:SetDTFloat(1, time) end
function meta:SetStateNumber(num) self:SetDTFloat(2, num) end
function meta:SetStateInteger(int) self:SetDTInt(2, int) end
function meta:SetStateEntity(ent) self:SetDTEntity(0, ent) end
function meta:SetStateVector(vec) self:SetDTVector(0, vec) end
function meta:SetStateAngles(ang) self:SetDTAngle(0, ang) end
function meta:SetStateBool(bool) self:SetDTBool(0, bool) end

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

function meta:CanThrow()
	return self:IsIdle() and self:IsCarrying() and self:OnGround() and self:GetVelocity():Length() <= 275
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
	return self:IsIdle() and self:OnGround()
end

function meta:CanCharge()
	return self:GetState() == STATE_NONE and self:GetStateInteger() == 1 and self:OnGround() and not self:Crouching() and self:GetVelocity():Length() > 290 and self:WaterLevel() <= 1
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

function meta:GetTraceFilter()
	local filter = team.GetPlayers(self:Team())
	filter[#filter + 1] = GAMEMODE.Ball
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

function meta:GetTargets(range, addfilter)
	local traces = {}

	local filter = self:GetTraceFilter()
	if addfilter then
		table.Add(filter, addfilter)
	end

	range = range or self:BoundingRadius()
	local start = self:LocalToWorld(self:OBBCenter())
	local trace = {start = start, endpos = start + self:GetForward() * range, mins = self:OBBMins() * 0.75, maxs = self:OBBMaxs() * 0.75, filter = filter, mask = MASK_SHOT}

	for i=1, 50 do
		local tr = util.TraceHull(trace)
		local ent = tr.Entity
		if ent and ent:IsValid() then
			table.insert(traces, tr)
			table.insert(trace.filter, ent)
		else
			break
		end
	end

	-- Fixes being able to hide in tight spaces.
	for i=1, 50 do
		local tr = util.TraceLine(trace)
		local ent = tr.Entity
		if ent and ent:IsValid() then
			table.insert(traces, tr)
			table.insert(trace.filter, ent)
		else
			break
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

function meta:SetLastAttacker(ent)
	if ent then
		self.LastAttacker = ent
		self.LastAttacked = CurTime()
	else
		self.LastAttacker = nil
		self.LastAttacked = nil
	end
end
