require "KillCountKnoxShared"

local function getLocalPlayer()
    return getPlayer and getPlayer() or nil
end

local function getKnoxApi()
    local api = rawget(_G, "KnoxSurvivors")
    return type(api) == "table" and api or nil
end

local function getKnoxProfile(victim)
    local knox = getKnoxApi()
    if not knox or type(knox.IsActor) ~= "function" or type(knox.GetActorProfile) ~= "function" then
        return nil, nil
    end

    local okActor, isActor = pcall(knox.IsActor, victim)
    if not okActor or isActor ~= true then
        return nil, nil
    end

    local okProfile, profile = pcall(knox.GetActorProfile, victim)
    if not okProfile or type(profile) ~= "table" or not profile.id then
        return nil, nil
    end
    return knox, profile
end

local function wasKilledByPlayer(victim, playerObj)
    local attacker = KillCountKnox.safeCall(victim, "getAttackedBy")
    if attacker == playerObj then
        return true
    end

    -- Some B42 death paths retain the latest hit source under this name.
    return KillCountKnox.safeCall(victim, "getLastHitFrom") == playerObj
end

local function isHostileToPlayer(knox, profile, playerObj)
    local relationships = knox and knox.Relationships
    if type(relationships) ~= "table" or type(relationships.IsHostileToPlayer) ~= "function" then
        return false
    end

    local ok, hostile = pcall(relationships.IsHostileToPlayer, profile, playerObj)
    return ok and hostile == true
end

local function onZombieDead(victim)
    local playerObj = getLocalPlayer()
    if not playerObj or not victim or not wasKilledByPlayer(victim, playerObj) then
        return
    end

    local knox, profile = getKnoxProfile(victim)
    if not profile then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    data.countedKnoxProfiles = data.countedKnoxProfiles or {}
    if data.countedKnoxProfiles[profile.id] then
        return
    end

    -- Knox actors are IsoZombie shells, so vanilla includes them in zombie kills.
    data.countedKnoxProfiles[profile.id] = true
    data.knoxShellKills = (data.knoxShellKills or 0) + 1

    if isHostileToPlayer(knox, profile, playerObj) then
        data.hostileKnoxKills = (data.hostileKnoxKills or 0) + 1
        data.lastHostileKnoxName = tostring(profile.name or "Unknown Survivor")
    end

    playerObj:transmitModData()
end

local debugZombieKillTargets = {
    [Keyboard.KEY_F5] = 0,
    [Keyboard.KEY_F6] = 300,
    [Keyboard.KEY_F7] = 600,
    [Keyboard.KEY_F8] = 900,
    [Keyboard.KEY_F9] = 1500,
}

local debugHostileKillTargets = {
    [Keyboard.KEY_F3] = 0,
    [Keyboard.KEY_F4] = 20,
    [Keyboard.KEY_F10] = 30,
    [Keyboard.KEY_F11] = 100,
    [Keyboard.KEY_F12] = 150,
}

local function applyDebugZombieKillTarget(playerObj, key)
    if not getCore or not getCore():getDebug() then
        return false
    end

    local target = debugZombieKillTargets[key]
    if target == nil then
        return false
    end

    -- Match the displayed total even if the save has counted Knox zombie shells.
    local data = KillCountKnox.getPlayerData(playerObj)
    playerObj:setZombieKills(target + (data.knoxShellKills or 0))

    if HaloTextHelper then
        HaloTextHelper.addTextWithArrow(playerObj, "Test zombie kills: " .. tostring(target), true, HaloTextHelper.getColorGreen())
    end
    return true
end

local function applyDebugHostileKillTarget(playerObj, key)
    if not getCore or not getCore():getDebug() then
        return false
    end

    local target = debugHostileKillTargets[key]
    if target == nil then
        return false
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    data.hostileKnoxKills = target
    playerObj:transmitModData()

    if HaloTextHelper then
        HaloTextHelper.addTextWithArrow(playerObj, "Test hostile survivors: " .. tostring(target), true, HaloTextHelper.getColorGreen())
    end
    return true
end

local function onKeyPressed(key)
    local playerObj = getLocalPlayer()
    if not playerObj then
        return
    end

    if applyDebugZombieKillTarget(playerObj, key) then
        return
    end

    if applyDebugHostileKillTarget(playerObj, key) then
        return
    end

    if key ~= Keyboard.KEY_K then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    data.hudVisible = not data.hudVisible
    playerObj:transmitModData()

    if HaloTextHelper then
        HaloTextHelper.addTextWithArrow(playerObj, "Rafales Killcount: " .. (data.hudVisible and "ON" or "OFF"), true, HaloTextHelper.getColorGreen())
    end
end

local function isRealZombieNear(playerObj, radius)
    if not playerObj or not getCell then
        return false
    end

    local cell = getCell()
    if not cell or not cell.getZombieList then
        return false
    end
    local list = cell:getZombieList()
    local px, py, pz = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    local radiusSquared = radius * radius
    local knox = getKnoxApi()
    for index = 0, list:size() - 1 do
        local zombie = list:get(index)
        local isAlive = KillCountKnox.safeCall(zombie, "isAlive")
        local isKnox = false
        if knox and type(knox.IsActor) == "function" then
            local ok, result = pcall(knox.IsActor, zombie)
            isKnox = ok and result == true
        end
        if isAlive ~= false and not isKnox then
            local dx = zombie:getX() - px
            local dy = zombie:getY() - py
            local sameFloor = math.abs((zombie:getZ() or 0) - pz) <= 0.2
            if sameFloor and dx * dx + dy * dy <= radiusSquared then
                return true
            end
        end
    end
    return false
end

local function applyColdBloodedGuard(playerObj)
    if not KillCountKnox.areGameplayEffectsEnabled() then
        return
    end

    local zombieKills = KillCountKnox.getDisplayedZombieKills(playerObj)
    if KillCountKnox.getUndeadRank(zombieKills) ~= "Cold-Blooded" then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    local now = getGameTime and getGameTime():getWorldAgeHours() * 3600000 or 0
    if now < (data.nextColdBloodedCheck or 0) then
        return
    end
    data.nextColdBloodedCheck = now + 500

    if not isRealZombieNear(playerObj, 12) then
        return
    end

    local stats = playerObj:getStats()
    local panic = KillCountKnox.safeCall(stats, "getPanic")
    if panic and panic > 0 then
        pcall(function() stats:setPanic(0) end)
    end
end

local function onPlayerUpdate(playerObj)
    if playerObj == getLocalPlayer() then
        applyColdBloodedGuard(playerObj)
    end
end

Events.OnZombieDead.Add(onZombieDead)
Events.OnKeyPressed.Add(onKeyPressed)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
