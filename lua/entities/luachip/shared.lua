DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Author = "MetaMan"
ENT.PrintName = "LuaChip"
ENT.Purpose = "A chip that allows you to run Lua (sandboxed) on the server"
ENT.RenderGroup	= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.NONE = 0
ENT.RUNNING = 1
ENT.FINISHED = 2
ENT.ERRORED = 3

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Player")
	self:NetworkVar("Int", 0, "ExecutionTime")
	self:NetworkVar("Int", 1, "State")
end