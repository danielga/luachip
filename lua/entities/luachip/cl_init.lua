include("shared.lua")

local fmt = "LuaChip\nOwner: %s\nTime spent: %i/%i μs"
local fmterr = "LuaChip\nOwner: %s\nErrored"
local white = Color(255, 255, 255, 255)
function ENT:Think()
	if self:BeingLookedAtByLocalPlayer() then
		local owner = self:GetPlayer()
		local nick = "unknown"
		if IsValid(owner) and owner:IsPlayer() then
			nick = owner:Nick()
		end

		if self:GetErrored() then
			AddWorldTip(self:EntIndex(), fmterr:format(nick), 0.5, self:GetPos(), self)
		else
			AddWorldTip(self:EntIndex(), fmt:format(nick, self:GetExecutionTime(0), self.MaxExecutionTimeInt), 0.5, self:GetPos(), self)
		end

		halo.Add({self}, white, 1, 1, 1, true, true)
	end
end