include("shared.lua")

local white = Color(255, 255, 255, 255)
function ENT:Think()
	if self:BeingLookedAtByLocalPlayer() then
		AddWorldTip(self:EntIndex(), "Time spent: " .. self:GetTimeSpent(0) .. "/1000 μs\nOwner: " .. self:GetPlayer():Nick(), 0.5, self:GetPos(), self)
		halo.Add({self}, white, 1, 1, 1, true, true)
	end
end