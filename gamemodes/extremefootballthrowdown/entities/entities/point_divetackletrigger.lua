ENT.Type = "anim"

function ENT:Initialize()
	self:PhysicsInitBox(Vector(-16, -16, -16), Vector(16, 16, 72))
	self:SetCollisionBounds(Vector(-16, -16, -16), Vector(16, 16, 72))
	self:SetMoveType(MOVETYPE_NONE)
	self:SetCustomCollisionCheck(true)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
		phys:EnableCollisions(false)
	end

	self:SetTrigger(true)

	--self.Hit = {}
	self.Hit = NULL
end

function ENT:StartTouch(hitent)
	local pl = self:GetOwner()
	if not pl:IsValid() or pl:IsCarryingBall() then return end

	if hitent:IsPlayer() and hitent:GetChargeImmunity(pl) <= CurTime() and not hitent:ImmuneToAll() and hitent:Team() ~= pl:Team() and hitent:Alive() and not (self.Hit:IsValid() and self.Hit:Alive()) then
		if hitent:CallStateFunction("OnChargedInto", pl) then
			return
		end

		if hitent:GetState() == STATE_DIVETACKLE and math.abs(math.AngleDifference(hitent:GetAngles().yaw, (pl:GetPos() - hitent:GetPos()):Angle().yaw)) <= 25 then
			--[[local myspeed = pl:GetVelocity():Length2D()
			local otherspeed = hitent:GetVelocity():Length2D()
			if math.abs(myspeed - otherspeed) < 24 then
				pl:SetState(STATE_POWERSTRUGGLE, nil, hitent)
				hitent:SetState(STATE_POWERSTRUGGLE, nil, pl)
				return
			else
				pl:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..myspeed.." Their speed: "..otherspeed)
				hitent:PrintMessage(HUD_PRINTTALK, "HEAD ON! - My speed: "..otherspeed.." Their speed: "..myspeed)
				if myspeed < otherspeed then
					hitent:ChargeHit(pl)
					return
				end
			end]]
			--[[pl:SetLocalVelocity(vector_origin)
			hitent:SetLocalVelocity(vector_origin)
			pl:ThrowFromPosition(hitent:GetLaunchPos(), 400, true, hitent)
			hitent:ThrowFromPosition(pl:GetLaunchPos(), 400, true, pl)]]
			pl:ChargeHit(hitent)
			hitent:ChargeHit(pl)
		elseif hitent:CanCharge() and math.abs(math.AngleDifference(hitent:GetAngles().yaw, (pl:GetPos() - hitent:GetPos()):Angle().yaw)) <= 18 then
			hitent:ChargeHit(pl)
		elseif CurTime() < hitent:GetDiveTackleThrowAwayTime() or CurTime() < hitent:GetKnockdownImmunity(pl) then
			pl:ChargeHit(hitent)
			self.DidChargeHit = true
		else
			self.Hit = hitent --self.Hit[hitent] = true
			--pl:ChargeHit(hitent)
			--if hitent:Alive() then
				pl:ChargeLaunch(hitent, true)
				hitent:SetLastAttacker(pl)
				hitent:SetStateInteger(KD_STATE_DIVETACKLED)
				hitent:SetStateEntity(pl)
				pl:SetStateEntity(hitent)
			--end
		end
	end
end

function ENT:ProcessTackles()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	if not owner:Alive() then
		--self:Remove()
		owner:EndState()
		return
	end

	local procd = self.DidChargeHit
	local ent = self.Hit
	if ent:IsValid() and ent:GetState() == STATE_KNOCKEDDOWN and ent:GetStateInteger() == KD_STATE_DIVETACKLED and ent:GetStateEntity() == owner then
		procd = true

		ent:KnockDown(3)
		ent:TakeSpecialDamage(10, DMG_FALL, owner, owner, owner:GetPos())
		ent:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and "3" or "1")..".wav")
		ent:SetChargeImmunity(owner, CurTime() + 4)
		ent:TriggerKnockdownImmunity(owner)
		ent:SetDiveTackleThrowAwayTime(CurTime() + 4)
	end

	if procd then
		owner:KnockDown(2.75)
	else
		owner:KnockDown(3)
		owner:TakeSpecialDamage(10, DMG_FALL, game.GetWorld(), game.GetWorld(), owner:GetPos())
		owner:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and "3" or "1")..".wav")
	end
end

function ENT:Think()
	local pl = self:GetOwner()
	if not pl:IsValid() or not pl:Alive() or pl:GetObserverMode() ~= 0 or pl:GetState() ~= STATE_DIVETACKLE then
		self:Remove()
	end

	self:NextThink(CurTime())
	return true
end

function ENT:ShouldNotCollide(ent)
	return true
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end
