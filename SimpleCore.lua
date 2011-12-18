local AddonName, Addon = ...
local AddonFrame = CreateFrame("Frame", AddonName .. "AddonFrame", UIParent)

_G[AddonName] = Addon

if AdiDebug then
	Addon.DebugPrint = AdiDebug:GetSink(AddonName)
else
	Addon.DebugPrint = function() end
end

AddonFrame:SetScript("OnEvent", function(self, event, ...)
	if Addon[event] then
		return Addon[event](Addon, event, ...)
	end
end)

local TimerDelay, TotalTimeElapsed = 1, 0
AddonFrame:SetScript("OnUpdate", function(self, elapsed)
    TotalTimeElapsed = TotalTimeElapsed + elapsed
    if TotalTimeElapsed < TimerDelay then return end

    TotalTimeElapsed = 0
    if Addon["OnTimer"] then
		Addon["OnTimer"](Addon, elapsed)
    end
end)

AddonFrame:RegisterEvent("PLAYER_LOGIN")
AddonFrame:RegisterEvent("ADDON_LOADED")

function Addon:RegisterEvent(event)
	if type(event) == "table" then
		for _,e in pairs(event) do
			AddonFrame:RegisterEvent(e)
		end
	else
		AddonFrame:RegisterEvent(event)
	end
end

function Addon:UnregisterEvent(event)
	AddonFrame:UnregisterEvent(event)
end

function Addon:PLAYER_LOGIN()
	if Addon["OnEnable"] then
		Addon["OnEnable"](Addon)
	end
end

function Addon:ADDON_LOADED(event, ...)
	Addon:StopTimer()
	Addon:RegisterSlashCommand(AddonName)
	--FIXME: Remove call to InitializeDB. This function should be called from the main addon file with defaults passed as an argument.
	Addon:InitializeDB()

	if ... == AddonName then
		Addon:UnregisterEvent("ADDON_LOADED")
		if Addon["OnInitialize"] then
			Addon["OnInitialize"](Addon)
		end

		if IsLoggedIn() and Addon["OnEnable"] then
			Addon["OnEnable"](Addon)
		end
	end
end

function Addon:RegisterSlashCommand(name, func)
	if SlashCmdList[name] then
		Addon:DebugPrint("Error: Slash command " .. command .. " already exists!")
	else
		_G["SLASH_".. name:upper().."1"] = "/" .. name

		if type(func) == "string" then
			--NOTE: Register a custom function to handle slash commands
			SlashCmdList[name:upper()] = function(msg)
				if Addon[func] then
					Addon[func](Addon, msg)
				end
			end
		else
			SlashCmdList[name:upper()] = function(msg)
				if Addon["OnSlashCommand"] then
					Addon["OnSlashCommand"](Addon, msg)
				end
			end
		end
	end
end

function Addon:InitializeDB(defaults)
	--TODO: Add support for default values
	local name = AddonName .. "DB"

	_G[name]  = _G[name]  or {}
	Addon["db"] = _G[name]
end

function Addon:Print(...)
	print("|cff33ff99" .. AddonName .. "|r: ", string.format(...))
end

function Addon:StartTimer(delay)
	if delay then
		Addon:SetTimerDelay(delay)
	end
	AddonFrame:Show()
end

function Addon:StopTimer()
	AddonFrame:Hide()
end

function Addon:SetTimerDelay(delay)
	TimerDelay = delay
end
