local CLASS = {}

CLASS.DisplayName = "Player"
CLASS.CrouchedWalkSpeed = 0.5
CLASS.WalkSpeed = 350
CLASS.RunSpeed = 350
CLASS.JumpPower	= 200 --286
CLASS.DrawTeamRing = true
CLASS.CanUseFlashlight = false

function CLASS:Loadout(pl)
end

function CLASS:OnSpawn(pl)
end

player_class.Register("Default", CLASS)
