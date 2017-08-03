STATE.Name = "Magnet Ball"

if SERVER then
	function STATE:Start(ball, samestate)
		ball:EmitSound("vehicles/Crane/crane_magnet_switchon.wav", 100, 120)
		ball:SetStateVector(vector_origin)
		ball:SetStateEntity(NULL)
	end

	function STATE:End(ball)
		ball:EmitSound("npc/barnacle/barnacle_die1.wav", 100, 100)
	end

	function STATE:PhysicsCollide(ball, data, phys)
		local ent = data.HitEntity
		local oldpos = self:GetMagnetPos(ball)

		if ent:IsValid() then
			ball:SetStateVector(ent:WorldToLocal(data.HitPos + data.HitNormal * 4))
			ball:SetStateEntity(data.HitEntity)
		elseif not data.HitSky then
			ball:SetStateVector(data.HitPos + data.HitNormal * 4)
			ball:SetStateEntity(NULL)
		end

		local newpos = self:GetMagnetPos(ball)
		if newpos and (not oldpos or oldpos:Distance(newpos) >= 128) or oldpos and not newpos then
			ball:EmitSound("vehicles/Crane/crane_magnet_release.wav", 80, 120)
		end
	end

	function STATE:Think(ball)
		if self:GetMagnetPos(ball) and ball:GetCarrier():IsValid() then
			ball:SetStateVector(vector_origin)
			ball:SetStateEntity(NULL)
		end
	end

	function STATE:PhysicsUpdate(ball, phys)
		local homepos = self:GetMagnetPos(ball)
		if not homepos then return end

		local ballpos = phys:GetPos()

		local force = 300 - homepos:Distance(ballpos) / 2
		if force < 0 then return end
		force = force ^ 1.5

		phys:AddVelocity(FrameTime() * force * (homepos - ballpos):GetNormalized())
	end
end

function STATE:GetMagnetPos(ball)
	if ball:GetStateEntity() == NULL and ball:GetStateVector() ~= vector_origin then
		return ball:GetStateVector()
	elseif ball:GetStateEntity():IsValid() then
		return ball:GetStateEntity():LocalToWorld(ball:GetStateVector())
	end
end

if not CLIENT then return end

local colBall = Color(255, 255, 255)
function STATE:GetBallColor(ball, carrier)
	local r, g, b = HSVtoRGB((CurTime() * 180) % 360)

	colBall.r = 255 - r * 0.2
	colBall.g = 255 - g * 0.2
	colBall.b = 255 - b * 0.2

	return colBall
end

local lerpdir
local matShiny = Material("models/shiny")
local matRefraction	= Material("refract_ring")
local matRing = Material("effects/select_ring")
function STATE:PreDraw(ball)
	self:GetBallColor(ball)

	local homepos = self:GetMagnetPos(ball)
	if homepos then
		local dir = homepos - ball:GetPos()
		dir:Normalize()

		if lerpdir then
			lerpdir.x = math.Approach(lerpdir.x, dir.x, FrameTime() * math.max(0.2, math.abs(lerpdir.x - dir.x)) * 5)
			lerpdir.y = math.Approach(lerpdir.y, dir.y, FrameTime() * math.max(0.2, math.abs(lerpdir.y - dir.y)) * 5)
			lerpdir.z = math.Approach(lerpdir.z, dir.z, FrameTime() * math.max(0.2, math.abs(lerpdir.z - dir.z)) * 5)
		else
			lerpdir = Vector()
			lerpdir:Set(dir)
		end

		local rot = CurTime() * 360 % 1
		local delta = math.abs(math.sin(CurTime() * math.pi)) ^ 3
		local size = 20 + delta * 40

		render.SetMaterial(matRing)
		render.DrawQuadEasy(homepos, dir, size, size, colBall, rot)
		render.DrawQuadEasy(homepos, dir * -1, size, size, colBall, rot)

		matRefraction:SetFloat("$refractamount", delta / 2)
		render.SetMaterial(matRefraction)
		render.UpdateRefractTexture()
		render.DrawQuadEasy(homepos, dir, size, size, color_white, rot)
		render.DrawQuadEasy(homepos, dir * -1, size, size, color_white, rot)
	else
		lerpdir = nil
	end

	render.SetColorModulation(colBall.r / 255, colBall.g / 255, colBall.b / 255)
	render.ModelMaterialOverride(matShiny)
end

function STATE:PostDraw(ball)
	render.ModelMaterialOverride()
	render.SetColorModulation(1, 1, 1)
end
