-- ==============================
-- 테이블
-- ==============================
---@diagnostic disable: lowercase-global
local addonName, dodo = ...
dodoDB = dodoDB or {}

-- ==============================
-- 동작
-- ==============================
local function audioSync()
    if not dodoDB then return end
    if not (CinematicFrame and CinematicFrame:IsShown()) and not (MovieFrame and MovieFrame:IsShown()) then
        local isEnabled = (dodoDB.useAudioSync ~= false)
        if isEnabled then
            SetCVar("Sound_OutputDriverIndex", "0")
            Sound_GameSystem_RestartSoundSystem()
            -- print("|cff00ff00[dodo]|r 음성 출력장치 변경") -- 디버깅
        end
    end
end

-- ==============================
-- 이벤트
-- ==============================
local initAudioSync = CreateFrame("Frame")
initAudioSync:RegisterEvent("ADDON_LOADED")
initAudioSync:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        dodoDB = dodoDB or {}
        self:RegisterEvent("VOICE_CHAT_OUTPUT_DEVICES_UPDATED")
    elseif event == "VOICE_CHAT_OUTPUT_DEVICES_UPDATED" then
        if audioSync then audioSync() end
    end
end)

dodo.audioSync = audioSync