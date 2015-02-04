function TRANSITION:In(delta, scrw, scrh)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, scrw * delta ^ 2, scrh)
end

function TRANSITION:Out(delta, scrw, scrh)
	local start = scrw * delta ^ 2

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(start, 0, scrw - start, scrh)
end
