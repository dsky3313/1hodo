-- ==============================
-- 테이블
-- ==============================
---@diagnostic disable: lowercase-global
local addonName, dodo = ...
dodoDB = dodoDB or {}

-- ==============================
-- 동작
-- ==============================
local function cameraTilt()
    if not dodoDB then return end

    local base = dodoDB.cameraBase or 1.00
    local baseDown = dodoDB.cameraDown or 1.00
    local baseFlying = dodoDB.cameraFlying or 1.00

    if GetCVar("test_cameraDynamicPitch") ~= "1" then
        UIParent:UnregisterEvent("EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED")
        SetCVar("test_cameraDynamicPitch", 1)
        SetCVar("CameraKeepCharacterCentered", 0)
    end

    if GetCVar("test_cameraDynamicPitch") == "1" then
        SetCVar("test_cameraDynamicPitchBaseFovPad", base)
        SetCVar("test_cameraDynamicPitchBaseFovPadDownScale", baseDown)
        SetCVar("test_cameraDynamicPitchBaseFovPadFlying", baseFlying)
    end
end

-- ==============================
-- 이벤트
-- ==============================
local initCamera = CreateFrame("Frame")
initCamera:RegisterEvent("ADDON_LOADED")
initCamera:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        dodoDB = dodoDB or {}
        self:RegisterEvent("PLAYER_LOGIN")
    elseif event == "PLAYER_LOGIN" then
        if cameraTilt then cameraTilt() end
        self:UnregisterAllEvents()
        self:SetScript("OnEvent", nil)
    end
end)

dodo.CameraTilt = cameraTilt