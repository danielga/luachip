include("core/client.lua")
include("shared.lua")

local fmt = "LuaChip\nOwner: %s\nTime spent: %i/%i μs"
local fmtfin = "LuaChip\nOwner: %s\nTime spent: %i/%i μs\nFinished"
local fmterr = "LuaChip\nOwner: %s\nTime spent: %i/%i μs\nErrored"
local white = Color(255, 255, 255, 255)
function ENT:Think()
	if self:BeingLookedAtByLocalPlayer() then
		local owner = self:GetPlayer()
		local nick = "unknown"
		if IsValid(owner) and owner:IsPlayer() then
			nick = owner:Nick()
		end

		local state = self:GetState()
		local fmt = fmt
		if state == self.FINISHED then
			fmt = fmtfin
		elseif state == self.ERRORED then
			fmt = fmterr
		end

		AddWorldTip(self:EntIndex(), fmt:format(nick, self:GetExecutionTime(), luachip.MaxExecutionTimeInt), 0.5, self:GetPos(), self)
		halo.Add({self}, white, 1, 1, 1, true, true)
	end
end