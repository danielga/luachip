include("shared.lua")

local white = Color(255, 255, 255, 255)
function ENT:Think()
	if self:BeingLookedAtByLocalPlayer() then
		local owner = self:GetPlayer()
		local nick = "unknown"
		if IsValid(owner) and owner:IsPlayer() then
			nick = owner:Nick()
		end

		AddWorldTip(self:EntIndex(), "Owner: " .. nick .. "\nTime spent: " .. self:GetExecutionTime(0) .. "/" .. self.MaxExecutionTimeInt .. " μs", 0.5, self:GetPos(), self)
		halo.Add({self}, white, 1, 1, 1, true, true)
	end
end