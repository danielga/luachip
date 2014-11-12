luachip = {}

local defaultmaxtime = 1000
luachip.MaxExecutionTimeInt = defaultmaxtime
luachip.MaxExecutionTime = defaultmaxtime / 1000000
CreateConVar("luachip_maxtime", defaultmaxtime, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Number of microseconds of execution time for each LuaChip.")
cvars.AddChangeCallback("luachip_maxtime", function(name, old, new)
	luachip.MaxExecutionTimeInt = tonumber(new)
	if luachip.MaxExecutionTimeInt then
		luachip.MaxExecutionTime = luachip.MaxExecutionTimeInt / 1000000
	else
		luachip.MaxExecutionTimeInt = defaultmaxtime
		luachip.MaxExecutionTime = defaultmaxtime / 1000000
	end
end)

-- check for friends?
function luachip.IsOwner(chip, ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false, "not_player"
	end

	if not IsValid(chip) or chip:GetClass() ~= "luachip" then
		return false, "not_luachip"
	end

	return chip:GetPlayer() == ply
end