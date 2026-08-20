require "XpSystem/ISUI/ISCharacterScreen"
require "KillCountKnoxShared"

if not ISCharacterScreen or not ISCharacterScreen.render then
    print("[RafalesKillcount] ISCharacterScreen is unavailable; panel integration is inactive.")
    return
end

if not RafalesKillcountCharacterScreenHooked then
    RafalesKillcountCharacterScreenHooked = true

    local originalRender = ISCharacterScreen.render
    local uiBase = __classmetatables[UIElement.class].__index
    local drawText = uiBase.DrawText
    local textBase = __classmetatables[TextManager.class].__index
    local getFontHeight = textBase.getFontHeight

    function ISCharacterScreen:render()
        originalRender(self)

        local playerObj = self.char or (getPlayer and getPlayer())
        if not playerObj or not self.javaObject then
            return
        end

        local data = KillCountKnox.getPlayerData(playerObj)
        local zombieKills = KillCountKnox.getDisplayedZombieKills(playerObj)
        local hostileKills = data.hostileKnoxKills or 0
        local threatLevel = KillCountKnox.getThreatLevel(hostileKills)
        local undeadRank = KillCountKnox.getUndeadRank(zombieKills)
        local lineHeight = getFontHeight(getTextManager(), UIFont.Small)
        -- The character preview occupies the lower-left corner of the Info tab.
        local x = 150
        -- The right column below the recipe text stays clear of vanilla bottom rows.
        local y = 180

        drawText(self.javaObject, UIFont.Small,
            "Undead Rank  " .. undeadRank,
            x, y, 0.78, 0.88, 0.95, 1)
        drawText(self.javaObject, UIFont.Small,
            "Hostile Survivors Killed  " .. tostring(hostileKills),
            x, y + lineHeight, 1, 0.78, 0.52, 1)
        drawText(self.javaObject, UIFont.Small,
            "Knox Threat Rank  " .. threatLevel,
            x, y + lineHeight * 2, 0.92, 0.68, 0.34, 1)
    end
end
