local AddonName, Addon = ...
local bit_band = bit.band

local EnemiesSeen = {}

local AllianceRaces = {
	["Draenei"] = true,
	["Dwarf"] = true,
	["Gnome"] = true,
	["Human"] = true,
	["Night Elf"] = true,
	["Worgen"] = true,
}
--TODO: Change race tables to use racefilename instead
--TODO: Notify the player if the detected unit has cast a stelth spell
--[[ Filenames
Human
Worgen
Gnome
Draenei
NightElf
Dwarf
]]
local HordeRaces = {
	["Blood Elf"] = true,
	["Goblin"] = true,
	["Orc"] = true,
	["Tauren"] = true,
	["Troll"] = true,
	["Undead"] = true,
}
--[[ Filenames
Troll
BloodElf
Orc
Tauren
Scourge
Goblin
]]


local function TekiPrint(msg)
	print("Teki: ", msg)
end

local function IsPlayerInDangerZone()
	if IsInInstance() or UnitIsPVPSanctuary("player") or UnitInBattleground("player") then
		return false
	else
		return true
	end
end

local function PlayerIsHostile(flag, event, race, srcGUID)
	local suffix = event:match(".+(_.-)$")

	if bit_band(flag, 0x548) == 0x548 then
		return true, "bit_band check with true value"
	elseif EnemyRaces[race] then
		return true, "EnemyRaces check TRUE value"
	else
		return false, "EnemyRaces check FALSE value"
	end

	--NOTE: This detects every player unit including your pc
	--[[if bit_band(srcGUID:sub(5,5), 0x7) == 0 then
		return true
	else
		return false
	end]]
end

local function WarnPlayer(name, class, classFilename, race, spellid, level)

	if level > 0 then
		PlaySoundFile("Interface\\Addons\\Teki\\player.mp3")
		print("<<Warning>> Enemy Player near: ", name, race, class, "<".. level .. ">")
	else
		PlaySoundFile("Interface\\Addons\\Teki\\player.mp3")
		print("<<Warning>> Enemy Player near: ", name, race, class)
	end
end

local function GetDelay(name)
	--return EnemiesSeen[name].spamDelay or 1
	return 30 --TODO: Add in actual spamDelay
end
function Addon:GetSubZoneText()
	local subzone = GetSubZoneText()

	if subzone == "" then
		return GetZoneText()
	else
		return subzone
	end
end

function Addon:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, ...)

	if not srcName then return end
	local class, race, sex, name, realm
	local spellid, name, school, missType, amount = ...
	local level = Addon:GetLevelFromSpellID(spellid)


	class, classFilename, race, raceFileName, sex, name, realm = GetPlayerInfoByGUID(srcGUID)

	--[[]local hostile, hostileMsg = PlayerIsHostile(srcFlags, event, race, srcGUID)

	if hostile then
		print(hostileMsg)
	end]]
	--print(select(2, PlayerIsHostile(srcFlags, event, race, srcGUID)))

	if PlayerIsHostile(srcFlags, event, race, srcGUID) and IsPlayerInDangerZone() then
		if EnemiesSeen[name] then
			--NOTE: Check if level is greater than Enemy:GetLevel and if so update level to new value
			--Don't notify the player if we've already warned them before the timeout or they are still in same subzone
			if GetTime() - EnemiesSeen[name].currentTime > GetDelay(name) and EnemiesSeen[name].currentZone ~= Addon:GetSubZoneText() then
				WarnPlayer(name, class, classFilename, race, spellid, level)
				EnemiesSeen[name] = { currentTime = GetTime(), currentZone = Addon:GetSubZoneText() }
			end
		else
			WarnPlayer(name, class, classFilename, race, spellid, level)
			EnemiesSeen[name] = { currentTime = GetTime(), currentZone = Addon:GetSubZoneText() }
		end
		--TODO: Add support for KOS. Similar to Obituary but simplier
		--TODO: Return values from if/elseif then do most of the work involving GetPlayerInfoByGUID
	end
end

function Addon:OnInitialize()
	if UnitFactionGroup("player") == "Horde" then
		EnemyRaces = AllianceRaces
	else
		EnemyRaces = HordeRaces
	end

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Addon:OnSlashCommand(msg)
end
