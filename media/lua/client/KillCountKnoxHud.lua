require "KillCountKnoxShared"

local function drawHud()
    local playerObj = getPlayer and getPlayer() or nil
    if not playerObj then
        return
    end

    local data = KillCountKnox.getPlayerData(playerObj)
    if data.hudVisible == false then
        return
    end

    local zombieKills = playerObj:getZombieKills()
    local hostileNpcKills = data.hostileNpcKills or 0

    local x = 24
    local y = 160
    local lineHeight = 18

    if getCore and getTextManager then
        local font = UIFont.Small

        getTextManager():DrawString(font, x, y, "Zombie Kills: " .. tostring(zombieKills), 0.90, 0.95, 0.90, 1.00)
        getTextManager():DrawString(font, x, y + lineHeight, "Hostile NPC Kills: " .. tostring(hostileNpcKills), 0.95, 0.80, 0.65, 1.00)
    end
end

Events.OnPostUIDraw.Add(drawHud)
