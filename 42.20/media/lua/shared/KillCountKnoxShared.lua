KillCountKnox = KillCountKnox or {}

KillCountKnox.MOD_DATA_KEY = "RafalesKillcount"
KillCountKnox.VERSION = "0.2.0"

function KillCountKnox.getPlayerData(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    local data = modData[KillCountKnox.MOD_DATA_KEY]

    if not data then
        data = {
            hostileKnoxKills = 0,
            knoxShellKills = 0,
            countedKnoxProfiles = {},
            lastHostileKnoxName = "",
            hudVisible = true,
        }
        modData[KillCountKnox.MOD_DATA_KEY] = data
    end

    return data
end

function KillCountKnox.getThreatLevel(hostileKills)
    hostileKills = tonumber(hostileKills) or 0
    if hostileKills >= 150 then return "Legend" end
    if hostileKills >= 100 then return "Warlord" end
    if hostileKills >= 30 then return "Hunter" end
    if hostileKills >= 20 then return "Survivor" end
    return "Unknown"
end

function KillCountKnox.getUndeadRank(zombieKills)
    zombieKills = tonumber(zombieKills) or 0
    if zombieKills >= 1500 then return "Cold-Blooded" end
    if zombieKills >= 900 then return "Reaper" end
    if zombieKills >= 600 then return "Veteran" end
    if zombieKills >= 300 then return "Hardened" end
    return "Greenhorn"
end

function KillCountKnox.areGameplayEffectsEnabled()
    local options = SandboxVars and SandboxVars.RafalesKillcount or nil
    if not options or options.EnableRankEffects == nil then
        return true
    end
    return options.EnableRankEffects == true
end

function KillCountKnox.getDisplayedZombieKills(playerObj)
    local rawKills = KillCountKnox.safeCall(playerObj, "getZombieKills") or 0
    local data = KillCountKnox.getPlayerData(playerObj)
    return math.max(0, rawKills - (data.knoxShellKills or 0))
end

function KillCountKnox.safeCall(target, methodName)
    if not target or not methodName or not target[methodName] then
        return nil
    end

    local ok, result = pcall(target[methodName], target)
    if ok then
        return result
    end

    return nil
end

function KillCountKnox.readModDataFlag(modData, keys)
    if not modData then
        return nil
    end

    for i = 1, #keys do
        local value = modData[keys[i]]
        if value ~= nil then
            return value
        end
    end

    return nil
end

function KillCountKnox.boolish(value)
    if value == nil then
        return nil
    end

    if type(value) == "boolean" then
        return value
    end

    if type(value) == "number" then
        return value ~= 0
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "true" or normalized == "yes" or normalized == "hostile" or normalized == "enemy" then
            return true
        end
        if normalized == "false" or normalized == "no" or normalized == "friendly" then
            return false
        end
    end

    return nil
end
