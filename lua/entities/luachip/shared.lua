DEFINE_BASECLASS("base_gmodentity")

ENT.Type = "anim"
ENT.Author = "MetaMan"
ENT.PrintName = "LuaChip"
ENT.Purpose = "A chip that allows you to run Lua (sandboxed) on the server"
ENT.RenderGroup	= RENDERGROUP_OPAQUE
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Player")
	self:NetworkVar("Int", 0, "TimeSpent")
end