KillCountKnox = KillCountKnox or {}

KillCountKnox.MOD_DATA_KEY = "KillCountKnoxHostiles"
KillCountKnox.VERSION = "0.1.0"

function KillCountKnox.getPlayerData(playerObj)
    if not playerObj then
        return nil
    end

    local modData = playerObj:getModData()
    local data = modData[KillCountKnox.MOD_DATA_KEY]

    if not data then
        data = {
            hostileNpcKills = 0,
            lastZombieKills = 0,
            lastNpcKillStamp = "",
            hudVisible = true,
        }
        modData[KillCountKnox.MOD_DATA_KEY] = data
    end

    return data
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
