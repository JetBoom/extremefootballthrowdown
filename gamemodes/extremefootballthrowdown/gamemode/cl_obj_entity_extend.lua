local meta = FindMetaTable("Entity")
if not meta then return end

function meta:SetRenderBoundsNumber(fNum)
	local fNumNegative = -fNum
	self:SetRenderBounds(Vector(fNumNegative, fNumNegative, fNumNegative), Vector(fNum, fNum, fNum))
end
