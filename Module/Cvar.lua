-- ==============================
-- 테이블
-- ==============================
---@diagnostic disable: lowercase-global
local addonName, dodo = ...
dodoDB = dodoDB or {}

-- ==============================
-- 동작
-- ==============================
local function nameplateFriendly()
    if not dodoDB then return end
    local isEnabled = (dodoDB.useNameplateFriendly ~= false)

    if isEnabled then
        SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 1)
        SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 1)
        -- print("|cff00ff00[dodo]|r 아군 이름표 : 활성화") -- 디버깅
    else
        SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 0)
        SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 0)
        -- print("|cff00ff00[dodo]|r 아군 이름표 : |cffff0000비활성화|r") -- 디버깅
    end
end

-- ==============================
-- 이벤트
-- ==============================
local initNameplate = CreateFrame("Frame")
initNameplate:RegisterEvent("ADDON_LOADED")
initNameplate:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        dodoDB = dodoDB or {}
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if nameplateFriendly then nameplateFriendly() end
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
    end
end)

dodo.nameplateFriendly = nameplateFriendly