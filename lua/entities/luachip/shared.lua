DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Author = "MetaMan"
ENT.PrintName = "LuaChip"
ENT.Purpose = "A chip that allows you to run Lua (sandboxed) on the server"
ENT.RenderGroup	= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminSpawnable = false

local defaultmaxtime = 1000
ENT.MaxExecutionTimeInt = defaultmaxtime
ENT.MaxExecutionTime = defaultmaxtime / 1000000
CreateConVar("luachip_maxtime", defaultmaxtime, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Number of microseconds of execution time for each LuaChip.")
local ent = ENT
cvars.AddChangeCallback("luachip_maxtime", function(name, old, new)
	ent.MaxExecutionTimeInt = tonumber(new)
	if ent.MaxExecutionTimeInt then
		ent.MaxExecutionTime = ent.MaxExecutionTimeInt / 1000000
	else
		ent.MaxExecutionTimeInt = defaultmaxtime
		ent.MaxExecutionTime = defaultmaxtime / 1000000
	end
end)

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Player")
	self:NetworkVar("Int", 0, "ExecutionTime")
	self:NetworkVar("Bool", 0, "Errored")
end