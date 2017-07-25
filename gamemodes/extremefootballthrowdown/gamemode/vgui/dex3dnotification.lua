GM.NotifyFadeTime = 8

local DefaultFont = "eft_3dnotice"
local DefaultFontEntity = "eft_3dnotice"

local PANEL  = {}

function PANEL:Init()
	self:SetPaintedManually(true)
	self:NoClipping(false)
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)
end

--local matGrad = Material("VGUI/gradient-r")
function PANEL:Paint()
	--[[surface.SetMaterial(matGrad)
	surface.SetDrawColor(0, 0, 0, 180)

	local align = self:GetParent():GetAlign()
	if align == RIGHT then
		surface.DrawTexturedRect(self:GetWide() * 0.25, 0, self:GetWide(), self:GetTall())
	elseif align == CENTER then
		surface.DrawTexturedRect(self:GetWide() * 0.25, 0, self:GetWide() * 0.25, self:GetTall())
		surface.DrawTexturedRectRotated(self:GetWide() * 0.625, self:GetTall() / 2, self:GetWide() * 0.25, self:GetTall(), 180)
	else
		surface.DrawTexturedRectRotated(self:GetWide() * 0.25, self:GetTall() / 2, self:GetWide() / 2, self:GetTall(), 180)
	end]]
end

function PANEL:AddLabel(text, col, font)
	local label = vgui.Create("DEX3DLabel", self)
	label:SetText(text)
	label:SetFont(font or DefaultFont)
	label:SetTextColor(col or color_white)
	label:SizeToContents()
	if extramargin then
		label:SetContentAlignment(7)
		label:DockMargin(0, label:GetTall() * 0.2, 0, 0)
	else
		label:SetContentAlignment(4)
	end
	label:Dock(LEFT)
end

function PANEL:AddImage(mat, col)
	local img = vgui.Create("DImage", self)
	img:SetImage(mat)
	if col then
		img:SetImageColor(col)
	end
	img:SizeToContents()
	local height = img:GetTall()
	if height > self:GetTall() then
		img:SetSize(self:GetTall() / height * img:GetWide(), self:GetTall())
	end
	img:DockMargin(0, (self:GetTall() - img:GetTall()) / 2, 0, 0)
	img:Dock(LEFT)
end

function PANEL:AddKillIcon(class)
	local icondata = killicon.GetIcon(class)

	if icondata then
		self:AddImage(icondata[1], icondata[2])
	else
		local fontdata = killicon.GetFont(class) or killicon.GetFont("default")
		if fontdata then
			self:AddLabel(fontdata[2], fontdata[3], fontdata[1])
		end
	end
end

function PANEL:SetNotification(...)
	local args = {...}

	local defaultcol = color_white
	local defaultfont
	for k, v in ipairs(args) do
		local vtype = type(v)

		if vtype == "table" then
			if v.r and v.g and v.b then
				defaultcol = v
			elseif v.font then
				if v.font == "" then
					defaultfont = nil
				else
					local th = draw.GetFontHeight(v.font)
					if th then
						defaultfont = v.font
					end
				end
			elseif v.killicon then
				self:AddKillIcon(v.killicon)
				if v.headshot then
					self:AddKillIcon("headshot")
				end
			elseif v.image then
				self:AddImage(v.image, v.color)
			end
		elseif vtype == "Player" then
			--[[local avatar = vgui.Create("AvatarImage", self)
			local size = 128
			avatar:SetSize(size, size)
			if v:IsValid() then
				avatar:SetPlayer(v, size)
			end
			avatar:SetAlpha(220)
			avatar:Dock(LEFT)
			avatar:DockMargin(0, (self:GetTall() - avatar:GetTall()) / 2, 0, 0)]]

			if v:IsValid() then
				self:AddLabel(" "..v:Name(), team.GetColor(v:Team()), DefaultFontEntity)
			else
				self:AddLabel(" ?", team.GetColor(TEAM_UNASSIGNED), DefaultFontEntity)
			end
		elseif vtype == "Entity" then
			self:AddLabel("["..(v:IsValid() and v:GetClass() or "?").."]", COLOR_RED, DefaultFontEntity)
		else
			local text = tostring(v)

			self:AddLabel(text, defaultcol, defaultfont)
		end
	end

	local w = 0
	local h = 8
	for _, p in pairs(self:GetChildren()) do
		w = w + p:GetWide()
		h = math.max(h, p:GetTall())
	end
	--self:DockPadding((self:GetWide() - w) / 2, 0, 0, 0)
	self:SetSize(w, h)
	self:SetPos(w * -0.5, 0)
	self:InvalidateLayout()
end

vgui.Register("DEX3DNotification", PANEL, "Panel")

PANEL = {}

function PANEL:Paint()
	--[[surface.DisableClipping(true)
	DisableClipping(true)]]

	draw.DrawTextBlurBG(self:GetText(), self:GetFont(), 0, 0, self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	--[[DisableClipping(false)
	surface.DisableClipping(false)]]

	return true
end

vgui.Register("DEX3DLabel", PANEL, "DLabel")
