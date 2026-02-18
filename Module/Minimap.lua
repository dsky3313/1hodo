-- ==============================
-- 테이블
-- ==============================
---@diagnostic disable: lowercase-global
local addonName, dodo = ...

local function isIns() -- 인스확인
    local _, instanceType, difficultyID = GetInstanceInfo()
    return (difficultyID == 8 or instanceType == "raid") -- 1 일반 / 8 쐐기 / raid 레이드
end

-- ==============================
-- 동작
-- ==============================
local function resetMinimapZoom()
    local isEnabled = (dodoDB.useResetMinimapZoom ~= false)
    local isZoomTimerRunning = false -- 중복 실행 방지

    if not dodoDB or not isEnabled or isIns() or isZoomTimerRunning then return end

    isZoomTimerRunning = true
    C_Timer.After(10, function()
        isZoomTimerRunning = false -- 타이머 종료 알림

        -- 10초 후 실행 시점에 다시 한번 상태 확인 (쐐기 진입 등 변수 고려)
        if not isIns() and Minimap:GetZoom() ~= 0 then
            Minimap:SetZoom(0)
            PlaySound(113, "Master")
        end
    end)
end

-- ==============================
-- 이벤트
-- ==============================
local initResetMinimapZoom = CreateFrame("Frame")
initResetMinimapZoom:RegisterEvent("ADDON_LOADED")

initResetMinimapZoom:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        dodoDB = dodoDB or {}
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("MINIMAP_UPDATE_ZOOM")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if isIns() then
            self:UnregisterEvent("MINIMAP_UPDATE_ZOOM")
        else
            self:RegisterEvent("MINIMAP_UPDATE_ZOOM")
        end
    elseif event == "MINIMAP_UPDATE_ZOOM" then
        resetMinimapZoom()
    end
end)

dodo.resetMinimapZoom = resetMinimapZoom