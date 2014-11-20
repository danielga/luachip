AddCSLuaFile("shared.lua")
AddCSLuaFile("client.lua")

include("shared.lua")

util.AddNetworkString("luachip_requestcode")
util.AddNetworkString("luachip_sendcode")
util.AddNetworkString("luachip_openeditor")

function luachip.RequestCode(ply, chip)
	if not IsValid(chip) or chip:GetClass() ~= "luachip" then
		return false, "not_luachip"
	end

	local owns, msg = luachip.IsOwner(ply, chip)
	if not owns then
		return false, "not_owner", msg
	end

	net.Start("luachip_requestcode")
	net.WriteUInt(chip:EntIndex(), 16)
	net.Send(ply)
	return true
end

function luachip.SendCode(ply, chip)
	if not IsValid(chip) or chip:GetClass() ~= "luachip" then
		return false, "not_luachip"
	end

	local owns, msg = luachip.IsOwner(ply, chip)
	if not owns then
		return false, "not_owner", msg
	end

	net.Start("luachip_sendcode")
	net.WriteEntity(chip)
	local code = util.Compress(chip:GetCode()) or ""
	local codelen = #code
	net.WriteUInt(codelen, 32)
	net.WriteData(code, codelen)
	net.Send(ply)
	return true
end

function luachip.OpenEditor(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false, "not_player"
	end

	net.Start("luachip_openeditor")
	net.Send(ply)
	return true
end

net.Receive("luachip_sendcode", function(len, ply)
	local chip = Entity(net.ReadUInt(16))
	if IsValid(chip) and chip:GetClass() == "luachip" and luachip.IsOwner(ply, chip) then
		chip:SetCode(util.Decompress(net.ReadData(net.ReadUInt(32))))
	end
end)