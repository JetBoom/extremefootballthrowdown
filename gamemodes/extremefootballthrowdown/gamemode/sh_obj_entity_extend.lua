local meta = FindMetaTable("Entity")
if not meta then return end

function meta:CollisionRulesChanged()
	if not self.m_OldCollisionGroup then self.m_OldCollisionGroup = self:GetCollisionGroup() end
	self:SetCollisionGroup(self.m_OldCollisionGroup == COLLISION_GROUP_DEBRIS and COLLISION_GROUP_WORLD or COLLISION_GROUP_DEBRIS)
	self:SetCollisionGroup(self.m_OldCollisionGroup)
	self.m_OldCollisionGroup = nil
end

function meta:GetBonePositionMatrixed(index)
	local matrix = self:GetBoneMatrix(index)
	if matrix then
		return matrix:GetTranslation(), matrix:GetAngles()
	end

	return self:GetPos(), self:GetAngles()
end

function meta:TakeSpecialDamage(damage, damagetype, attacker, inflictor, hitpos)
	attacker = attacker or self
	if not attacker:IsValid() then attacker = self end
	inflictor = inflictor or attacker
	if not inflictor:IsValid() then inflictor = attacker end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	dmginfo:SetDamagePosition(hitpos or self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter()))))
	dmginfo:SetDamageType(damagetype)
	self:TakeDamageInfo(dmginfo)

	return dmginfo
end

function meta:ThrowFromPosition(pos, force, knockdown, attacker)
	if force == 0 then return end

	local movetype = self:GetMoveType()

	if movetype == MOVETYPE_VPHYSICS then
		local phys = self:GetPhysicsObject()
		if phys:IsValid() and phys:IsMoveable() then
			local nearest = self:NearestPoint(pos)
			phys:ApplyForceOffset(force * 50 * (nearest - pos):GetNormalized(), nearest)
		end
	elseif movetype == MOVETYPE_WALK or movetype == MOVETYPE_STEP or movetype == MOVETYPE_LADDER or movetype == MOVETYPE_FLY or movetype == MOVETYPE_FLYGRAVITY then
		self:SetGroundEntity(NULL)
		self:SetVelocity(force * (self:LocalToWorld(self:OBBCenter()) - pos):GetNormalized())
		if knockdown and self.KnockDown then
			return self:KnockDown(nil, attacker, true)
		end
	end
end

function meta:GetNamedAttachment(name)
	local attachid = self:LookupAttachment(name)
	if attachid and attachid > 0 then
		return self:GetAttachment(attachid)
	end
end

function meta:IsInWater()
	return self:WaterLevel() > 0
end

function meta:IsSwimming()
	return self:WaterLevel() >= 2
end

function meta:IsSubmerged()
	return self:WaterLevel() >= 4
end

function meta:FireOutput(outpt, activator, caller, args)
	local intab = self[outpt]
	if intab then
		for key, tab in pairs(intab) do
			for __, subent in pairs(self:FindByNameHammer(tab.entityname, activator, caller)) do
				local delay = tonumber(tab.delay)
				if delay == nil or delay <= 0 then
					subent:Input(tab.input, activator, caller, ((tab.args == "") and args) or tab.args)
				else
					timer.Simple(delay, function() if subent:IsValid() then subent:Input(tab.input, activator, caller,((tab.args == "") and args) or tab.args) end end)
				end
			end
		end
	end
end

function meta:AddOnOutput(key, value)
	self[key] = self[key] or {}
	local tab = string.Explode(",", value)
	table.insert(self[key], {entityname=tab[1], input=tab[2], args=tab[3], delay=tab[4], reps=tab[5]})
end

function meta:FindByNameHammer(name, activator, caller)
	if name == "!self" then return {self} end
	if name == "!activator" then return {activator} end
	if name == "!caller" then return {caller} end
	return ents.FindByName(name)
end
