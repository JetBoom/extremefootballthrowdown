AddCSLuaFile()

SWEP.PrintName = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 0

SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel	= ""

function SWEP:Think()
	if not self.Owner:CallCarryFunction("ThinkCompensatable") then
		self.Owner:CallStateFunction("ThinkCompensatable")
	end

	self:NextThink(CurTime())
	return true
end

function SWEP:PrimaryAttack()
	local owner = self.Owner

	if owner:CallStateFunction("PrimaryAttack") then return end
	if owner:CallCarryFunction("PrimaryAttack") then return end

	if owner:CanMelee() then
		local state = STATE_PUNCH1
		--[[for _, tr in pairs(owner:GetTargets()) do
			local hitent = tr.Entity
			if hitent:IsPlayer() and hitent:GetState() == STATE_KNOCKEDDOWN then
				state = STATE_KICK1
				break
			end
		end]]

		owner:SetState(state, STATES[state].Time)
	end
end

function SWEP:SecondaryAttack()
	local owner = self.Owner

	if owner:CallStateFunction("SecondaryAttack") then return end
	if owner:CallCarryFunction("SecondaryAttack") then return end

	if owner:CanMelee() then
		local vel = owner:GetVelocity()
		local dir = vel:GetNormalized()
		local speed = vel:Length() * dir:Dot(owner:GetForward())
		if speed >= 290 and CurTime() >= owner:GetLastChargeHit() + 0.4 and owner:GetCarry() ~= GAMEMODE:GetBall() then
			owner:SetState(STATE_DIVETACKLE)
		end
	end
end

function SWEP:Reload()
	local owner = self.Owner

	if owner:KeyPressed(IN_RELOAD) then
		if owner:CallStateFunction("Reload") then return end
		--[[if]] owner:CallCarryFunction("Reload") --then return end
	end
end

if not CLIENT then return end

function SWEP:DrawWeaponSelection()
end

function SWEP:PreDrawViewModel(vm, wep, pl)
	vm:SetMaterial("engine/occlusionproxy")
end
