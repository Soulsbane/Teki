local AddonName, Addon = ...

local Enemy = {}
local EnemyMetaTable = { __index = Enemy }
local TrackedEnemies = {}
--TODO: Add metamethod for tostring
function Enemy:New(name, kos, level)
	return setmetatable( { name = name, lastSeen = GetTime(), isKOS = kos, level = 0 }, EnemyMetaTable)
end

function Enemy:GetName()
	return self.name
end

function Enemy:GetLastSeen()
	return self.lastSeen
end

function Enemy:SetLastSeen()
	self.lastSeen = GetTime()
end

function Enemy:IsKOS()
	return self.isKOS
end

function Enemy:GetLevel()
	return self.level
end
function Enemy:SetLevel(level)
	self.level = level
end

function Addon:AddEnemy(name, enemy)
	TrackedEnemies[name] = enemy
end

function Addon:GetEnemy(name)
	return TrackedEnemies[name]
end


