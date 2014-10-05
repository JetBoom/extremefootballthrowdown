VOICESET_PAIN_LIGHT = 1
VOICESET_PAIN_MED = 2
VOICESET_PAIN_HEAVY = 3
VOICESET_DEATH = 4
VOICESET_HAPPY = 5
VOICESET_MAD = 6
VOICESET_TAUNT = 7
VOICESET_TAKEBALL = 8
VOICESET_THROW = 9
VOICESET_OVERHERE = 10

local VoiceSets = {}

VoiceSets[0] = {
	[VOICESET_THROW] = {
		Sound("vo/npc/male01/headsup01.wav"),
		Sound("vo/npc/male01/headsup02.wav")
	}
}

VoiceSets[TEAM_RED] = {
	[VOICESET_PAIN_LIGHT] = {
		Sound("vo/npc/Barney/ba_pain02.wav"),
		Sound("vo/npc/Barney/ba_pain07.wav"),
		Sound("vo/npc/Barney/ba_pain04.wav")
	},
	[VOICESET_PAIN_MED] = {
		Sound("vo/npc/Barney/ba_pain01.wav"),
		Sound("vo/npc/Barney/ba_pain08.wav"),
		Sound("vo/npc/Barney/ba_pain10.wav")
	},
	[VOICESET_PAIN_HEAVY] = {
		Sound("vo/npc/Barney/ba_pain05.wav"),
		Sound("vo/npc/Barney/ba_pain06.wav"),
		Sound("vo/npc/Barney/ba_pain09.wav")
	},
	[VOICESET_DEATH] = {
		Sound("vo/npc/Barney/ba_ohshit03.wav"),
		Sound("vo/npc/Barney/ba_no01.wav"),
		Sound("vo/npc/Barney/ba_no02.wav"),
		Sound("vo/npc/Barney/ba_pain03.wav"),
		Sound("vo/npc/Barney/ba_pain10.wav")
	},
	[VOICESET_HAPPY] = {
		Sound("vo/Streetwar/nexus/ba_done.wav"),
		Sound("vo/npc/Barney/ba_gotone.wav"),
		Sound("vo/npc/Barney/ba_yell.wav"),
		Sound("vo/npc/Barney/ba_bringiton.wav"),
		Sound("vo/npc/Barney/ba_laugh01.wav"),
		Sound("vo/npc/Barney/ba_laugh03.wav"),
		Sound("vo/Streetwar/rubble/ba_tellbreen.wav")
	},
	[VOICESET_MAD] = {
		Sound("vo/k_lab/ba_getitoff01.wav"),
		Sound("vo/k_lab/ba_whoops.wav"),
		Sound("vo/npc/Barney/ba_damnit.wav"),
		Sound("vo/k_lab/ba_thingaway02.wav"),
		Sound("vo/k_lab/ba_cantlook.wav"),
		Sound("vo/k_lab/ba_whatthehell.wav"),
		Sound("vo/k_lab/ba_guh.wav"),
		Sound("vo/Streetwar/rubble/ba_damnitall.wav"),
		Sound("vo/npc/Barney/ba_no02.wav"),
		Sound("vo/npc/Barney/ba_no01.wav")
	},
	[VOICESET_TAUNT] = {
		Sound("vo/npc/Barney/ba_yell.wav"),
		Sound("vo/npc/Barney/ba_downyougo.wav"),
		Sound("vo/npc/Barney/ba_laugh02.wav"),
		Sound("vo/npc/Barney/ba_laugh04.wav"),
		Sound("vo/npc/Barney/ba_getoutofway.wav"),
		Sound("vo/npc/Barney/ba_gotone.wav"),
		Sound("vo/npc/Barney/ba_ohyeah.wav")
	},
	[VOICESET_TAKEBALL] = {
		Sound("vo/npc/Barney/ba_letsdoit.wav"),
		Sound("vo/npc/Barney/ba_letsgo.wav"),
		Sound("vo/npc/Barney/ba_bringiton.wav")
	},
	[VOICESET_OVERHERE] = {
		Sound("vo/Streetwar/sniper/ba_overhere.wav")
	}
}

VoiceSets[TEAM_BLUE] = {
	[VOICESET_PAIN_LIGHT] = {
		Sound("vo/npc/male01/ow01.wav"),
		Sound("vo/npc/male01/ow02.wav"),
		Sound("vo/npc/male01/pain01.wav"),
		Sound("vo/npc/male01/pain02.wav"),
		Sound("vo/npc/male01/pain03.wav")
	},
	[VOICESET_PAIN_MED] = {
		Sound("vo/npc/male01/pain04.wav"),
		Sound("vo/npc/male01/pain05.wav"),
		Sound("vo/npc/male01/pain06.wav")
	},
	[VOICESET_PAIN_HEAVY] = {
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav"),
		Sound("vo/npc/male01/pain09.wav"),
		Sound("vo/npc/male01/help01.wav")
	},
	[VOICESET_DEATH] = {
		Sound("vo/npc/male01/no02.wav"),
		Sound("ambient/voices/citizen_beaten1.wav"),
		Sound("ambient/voices/citizen_beaten3.wav"),
		Sound("ambient/voices/citizen_beaten4.wav"),
		Sound("ambient/voices/citizen_beaten5.wav"),
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav")
	},
	[VOICESET_HAPPY] = {
		Sound("vo/Citadel/br_laugh01.wav"),
		Sound("vo/Citadel/br_gravgun.wav"),
		Sound("vo/NovaProspekt/br_outoftime.wav"),
		Sound("vo/Citadel/br_mock06.wav"),
		Sound("vo/Citadel/br_mock09.wav"),
		Sound("vo/Citadel/br_mock13.wav"),
		Sound("vo/Citadel/br_mock05.wav")
	},
	[VOICESET_MAD] = {
		Sound("vo/Citadel/br_no.wav"),
		Sound("vo/Citadel/br_youfool.wav"),
		Sound("vo/Citadel/br_failing11.wav"),
		Sound("vo/k_lab/br_tele_02.wav"),
		Sound("vo/Citadel/br_ohshit.wav"),
		Sound("vo/npc/male01/gethellout.wav")
	},
	[VOICESET_TAUNT] = {
		Sound("vo/Citadel/br_youfool.wav"),
		Sound("vo/Citadel/br_laugh01.wav"),
		Sound("vo/Citadel/br_mock09.wav"),
		Sound("vo/Citadel/br_mock06.wav"),
		Sound("vo/npc/male01/excuseme02.wav")
	},
	[VOICESET_TAKEBALL] = {
		Sound("vo/npc/male01/ok01.wav"),
		Sound("vo/npc/male01/ok02.wav"),
		Sound("vo/npc/male01/pardonme01.wav"),
		Sound("vo/npc/male01/strider_run.wav")
	},
	[VOICESET_OVERHERE] = {
		Sound("vo/npc/male01/overhere01.wav")
	}
}

local meta = FindMetaTable("Player")
if not meta then return end

local empty = {}
function meta:GetVoiceSet(set)
	local baseset = VoiceSets[self:Team()]
	if baseset then
		if baseset[set] then return baseset[set] end
		if VoiceSets[0][set] then return VoiceSets[0][set] end
	end

	return empty
end

function meta:PlayVoiceSet(set, level, pitch, volume)
	local snd = table.Random(self:GetVoiceSet(set))
	level = level or 80
	pitch = pitch or math.Rand(95, 105)
	volume = volume or 0.8

	if snd then
		self:EmitSound(snd, level, pitch, volume)
	end

	return snd
end

function meta:PlayPainSound()
	if CurTime() < self.NextPainSound then return end

	local snds
	local health = self:Health()
	if 70 <= health then
		snds = VOICESET_PAIN_LIGHT
	elseif 35 <= health then
		snds = VOICESET_PAIN_MED
	else
		snds = VOICESET_PAIN_HEAVY
	end

	snd = self:PlayVoiceSet(snds)

	if snd then
		self.NextPainSound = CurTime() + SoundDuration(snd) - 0.1
	end
end