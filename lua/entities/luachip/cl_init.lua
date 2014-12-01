include("core/client.lua")
include("shared.lua")

local fmt = "LuaChip\nOwner: %s\nTime spent: %i μs"
local fmtfin = "LuaChip\nOwner: %s\nTime spent: %i μs\nFinished"
local fmterr = "LuaChip\nOwner: %s\nTime spent: %i μs\nErrored"
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

		AddWorldTip(self:EntIndex(), fmt:format(nick, self:GetExecutionTime()), 0.5, self:GetPos(), self)

		if not self.HaloEnts then
			self.HaloEnts = {self}
		end

		halo.Add(self.HaloEnts, white, 1, 1, 1, true, true)
	end
end