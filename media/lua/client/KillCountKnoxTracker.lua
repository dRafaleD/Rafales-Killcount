require "KillCountKnoxShared"

local HOSTILE_TRUE_KEYS = {
    "hostile",
    "Hostile",
    "isHostile",
    "IsHostile",
    "aggressive",
    "Aggressive",
    "isAggressive",
    "IsAggressive",
    "enemy",
    "Enemy",
    "isEnemy",
    "IsEnemy",
}

local HOSTILE_FALSE_KEYS = {
    "friendly",
    "Friendly",
    "isFriendly",
    "IsFriendly",
}

local function getLocalPlayer()
    return getPlayer and getPlayer() or nil
end

local function resolveOnlineID(character)
    local onlineID = KillCountKnox.safeCall(character, "getOnlineID")
    if onlineID ~= nil then
        return tostring(onlineID)
    end

    local descriptor = KillCountKnox.safeCall(character, "getDescriptor")
    local descriptorId = KillCountKnox.safeCall(descriptor, "getID")
    if descriptorId ~= nil then
        return tostring(descriptorId)
    end

    return tostring(character)
end

local function getVictimStamp(victim)
    local x = KillCountKnox.safeCall(victim, "getX") or 0
    local y = KillCountKnox.safeCall(victim, "getY") or 0
    local z = KillCountKnox.safeCall(victim, "getZ") or 0
    return string.format("%s@%d:%d:%d", resolveOnlineID(victim), math.floor(x), math.floor(y), math.floor(z))
end

local function isZombie(victim)
    if instanceof and instanceof(victim, "IsoZombie") then
        return true
    end

    return KillCountKnox.safeCall(victim, "isZombie") == true
end

local function isPlayer(character)
    if instanceof and instanceof(character, "IsoPlayer") then
        return true
    end

    return KillCountKnox.safeCall(character, "isLocalPlayer") ~= nil
end

local function isLikelyNpc(victim)
    if not victim or isZombie(victim) or isPlayer(victim) then
        return false
    end

    if KillCountKnox.safeCall(victim, "isAlive") == false then
        return true
    end

    return KillCountKnox.safeCall(victim, "getDescriptor") ~= nil
end

local function isHostileNpc(victim)
    if not isLikelyNpc(victim) then
        return false
    end

    local modData = KillCountKnox.safeCall(victim, "getModData")
    local friendlyFlag = KillCountKnox.boolish(KillCountKnox.readModDataFlag(modData, HOSTILE_FALSE_KEYS))
    if friendlyFlag == true then
        return false
    end

    local hostileFlag = KillCountKnox.boolish(KillCountKnox.readModDataFlag(modData, HOSTILE_TRUE_KEYS))
    if hostileFlag ~= nil then
        return hostileFlag
    end

    local hostileMethods = { "isHostile", "isAggressive", "isEnemy" }
    for i = 1, #hostileMethods do
        local result = KillCountKnox.boolish(KillCountKnox.safeCall(victim, hostileMethods[i]))
        if result ~= nil then
            return result
        end
    end

    local faction = KillCountKnox.safeCall(victim, "getFaction")
    local factionName = KillCountKnox.safeCall(faction, "getName")
    if type(factionName) == "string" then
        local normalized = string.lower(factionName)
        if string.find(normalized, "bandit", 1, true) or string.find(normalized, "raider", 1, true) or string.find(normalized, "hostile", 1, true) then
            return true
        end
    end

    return false
end

local function resolveKiller(victim)
    local directKiller = KillCountKnox.safeCall(victim, "getAttackedBy")
    if directKiller then
        return directKiller
    end

    local killer = KillCountKnox.safeCall(victim, "getKiller")
    if killer then
        return killer
    end

    return nil
end

local function updateZombieBaseline(playerObj)
    if not playerObj then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    local zombieKills = playerObj:getZombieKills()
    if zombieKills ~= data.lastZombieKills then
        data.lastZombieKills = zombieKills
        playerObj:transmitModData()
    end
end

local function onCreatePlayer(playerIndex, playerObj)
    if playerIndex ~= 0 or not playerObj then
        return
    end

    updateZombieBaseline(playerObj)
end

local function onCharacterDeath(victim)
    local playerObj = getLocalPlayer()
    if not playerObj or not victim or not isHostileNpc(victim) then
        return
    end

    local killer = resolveKiller(victim)
    if killer ~= playerObj then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    local stamp = getVictimStamp(victim)
    if data.lastNpcKillStamp == stamp then
        return
    end

    data.lastNpcKillStamp = stamp
    data.hostileNpcKills = (data.hostileNpcKills or 0) + 1
    playerObj:transmitModData()
end

local function onKeyPressed(key)
    local playerObj = getLocalPlayer()
    if not playerObj or key ~= Keyboard.KEY_K then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    data.hudVisible = not data.hudVisible
    playerObj:transmitModData()

    if HaloTextHelper then
        HaloTextHelper.addTextWithArrow(playerObj, "KillCount HUD: " .. (data.hudVisible and "ON" or "OFF"), true, HaloTextHelper.getColorGreen())
    end
end

local function onPlayerUpdate(playerObj)
    local localPlayer = getLocalPlayer()
    if not localPlayer or playerObj ~= localPlayer then
        return
    end

    updateZombieBaseline(localPlayer)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnCharacterDeath.Add(onCharacterDeath)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
