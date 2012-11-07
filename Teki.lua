local AddonName, Addon = ...
local bit_band = bit.band

local EnemiesSeen = {}

local AllianceRaces = {
	["Human"]  = true,
	["Worgen"] = true,
	["Gnome"] = true,
	["Draenei"] = true,
	["NightElf"] = true,
	["Dwarf"] = true,
}

--TODO: Notify the player if the detected unit has cast a stelth spell
local HordeRaces = {
	["Troll"]= true,
	["BloodElf"]  = true,
	["Orc"] = true,
	["Tauren"] = true,
	["Scourge"] = true,
	["Goblin"] = true,
}

local function IsPlayerInDangerZone()
	if IsInInstance() or UnitIsPVPSanctuary("player") or UnitInBattleground("player") then
		return false
	else
		return true
	end
end

local function PlayerIsHostile(flag, event, raceFileName, srcGUID)
	if bit_band(flag, 0x548) == 0x548 then
		return true
	elseif EnemyRaces[raceFileName] then
		return true
	else
		return false
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

function Addon:WarnPlayer(name, class, classFilename, race, spellid, level)

	if level > 0 then
		PlaySoundFile("Interface\\Addons\\Teki\\player.mp3")
		self:Print("<<Warning>> Enemy Player near: %s %s %s <%s>", name, race, class, level)
	else
		PlaySoundFile("Interface\\Addons\\Teki\\player.mp3")
		self:Print("<<Warning>> Enemy Player near: %s %s %s", name, race, class)
	end
end

function Addon:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcFlags2, dstGUID, dstName, dstFlags, dstFlags2, ...)

	if not srcName then return end
	local class, race, sex, name, realm, raceFileName, classFilename
	local spellid, name, school, missType, amount = ...
	local level = Addon:GetPlayerLevel(spellid)


	class, classFilename, race, raceFileName, sex, name, realm = GetPlayerInfoByGUID(srcGUID)

	--TODO: We should probably cache character data rather than keep calling GetPlayerInfoByGUID since this function is called so often
	if PlayerIsHostile(srcFlags, event, raceFileName, srcGUID) and IsPlayerInDangerZone() then
		if EnemiesSeen[name] then
			--NOTE: Check if level is greater than Enemy:GetLevel and if so update level to new value
			--Don't notify the player if we've already warned them before the timeout or they are still in same subzone
			if GetTime() - EnemiesSeen[name].currentTime > GetDelay(name) and EnemiesSeen[name].currentZone ~= Addon:GetSubZoneText() then
				self:WarnPlayer(name, class, classFilename, race, spellid, level)
				EnemiesSeen[name] = { currentTime = GetTime(), currentZone = Addon:GetSubZoneText() }
			end
		else
			self:WarnPlayer(name, class, classFilename, race, spellid, level)
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

function Addon:GetPlayerLevel(spellid)
	--TODO: Check if we are in a dungeon
	local mapMinLevel, mapMaxLevel = GetCurrentMapLevelRange() or 1
	local spellLevel = Addon:GetLevelFromSpellID(spellid)

	if mapMinLevel > spellLevel then
		return mapMinLevel
	else
		return spellLevel
	end
end

function Addon:OnSlashCommand(msg)
end
