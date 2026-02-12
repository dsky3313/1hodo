-- ------------------------------------------------------------ --
-- GreyOnCooldown (Unified & Taint-Free Version)                --
-- ✅ 작동하는 버전                                              --
-- ------------------------------------------------------------ --

local AddonName, ns = ...

-- 1. 기본 설정
local Config = {
    Enabled = true,
    DesaturateUnusable = true,
    DesaturatePet = true,
    GCD = 1.88,
}

-- API 캐싱
local _G = _G
local GetActionInfo = GetActionInfo
local GetPetActionInfo = GetPetActionInfo
local GetPetActionSlotUsable = GetPetActionSlotUsable
local GetPetActionCooldown = GetPetActionCooldown
local C_ActionBar_IsUsableAction = C_ActionBar.IsUsableAction
local C_ActionBar_GetActionCooldown = C_ActionBar.GetActionCooldown
local C_ActionBar_GetActionCooldownDuration = C_ActionBar.GetActionCooldownDuration
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_Spell_GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration

local GOC = CreateFrame("Frame")
GOC.RegisteredButtons = {}

-- 2. Desaturation Curves (Taint 해결의 핵심)
local DesaturationCurve = C_CurveUtil.CreateCurve()
DesaturationCurve:SetType(Enum.LuaCurveType.Step)
DesaturationCurve:AddPoint(0, 0)
DesaturationCurve:AddPoint(0.001, 1)

-- ------------------------------------------------------------ --
-- Core Logic: Action Button Update
-- ------------------------------------------------------------ --
local function UpdateActionButton(self)
    if not Config.Enabled or not self.icon then return end

    local action = self.action
    local spellID = self.spellID -- StanceButton 등은 action 대신 spellID 사용 가능

    -- 1. 사용 불가능 체크 (액션바 또는 스펠 기준)
    if Config.DesaturateUnusable then
        local isUsable, notEnoughMana
        if action then
            isUsable, notEnoughMana = C_ActionBar_IsUsableAction(action)
        elseif spellID then
            isUsable, notEnoughMana = C_Spell_IsSpellUsable(spellID)
        end
        
        if isUsable ~= nil and not (isUsable or notEnoughMana) then
            self.icon:SetDesaturation(1)
            return
        end
    end

    -- 2. 쿨타임 처리 (Taint-Free)
    local duration
    local isOnGCD = false

    if action then
        local cdInfo = C_ActionBar_GetActionCooldown(action)
        isOnGCD = cdInfo and cdInfo.isOnGCD or false
        duration = C_ActionBar_GetActionCooldownDuration(action)
    elseif spellID then
        -- 태세바 버튼 등을 위한 스펠 기반 처리
        local cdInfo = C_Spell.GetSpellCooldown(spellID)
        isOnGCD = cdInfo and cdInfo.isOnGCD or false
        duration = C_Spell_GetSpellCooldownDuration(spellID)
    end

    if duration then
        if isOnGCD then
            self.icon:SetDesaturation(0)
        elseif duration:HasSecretValues() then
            self.icon:SetDesaturation(duration:EvaluateRemainingDuration(DesaturationCurve))
        else
            self.icon:SetDesaturation(duration:GetRemainingDuration() > 0 and 1 or 0)
        end
    else
        self.icon:SetDesaturation(0)
    end
end

-- ------------------------------------------------------------ --
-- Core Logic: Pet Action Button Update
-- ------------------------------------------------------------ --
local function UpdatePetActionButton(self)
    if not Config.DesaturatePet or not self.icon then return end
    
    local index = self.index or self.id
    if not (index and GetPetActionInfo(index)) then return end

    if Config.DesaturateUnusable then
        if not GetPetActionSlotUsable(index) then
            self.icon:SetDesaturation(1)
            return
        end
    end

    local _, duration, enable = GetPetActionCooldown(index)
    if enable and duration and duration > Config.GCD then
        self.icon:SetDesaturation(1)
    else
        self.icon:SetDesaturation(0)
    end
end

-- ------------------------------------------------------------ --
-- Hooking Mechanisms (에러 방지 안전장치 추가)
-- ------------------------------------------------------------ --
local function HookButton(button, isPet)
    if not button or GOC.RegisteredButtons[button] then return end
    GOC.RegisteredButtons[button] = true

    if isPet then
        button.IsPetButton = true
        if type(button.Update) == "function" then
            hooksecurefunc(button, "Update", UpdatePetActionButton)
        end
    else
        -- 함수가 존재할 때만 후킹 (Update is not a function 에러 해결)
        if type(button.Update) == "function" then
            hooksecurefunc(button, "Update", UpdateActionButton)
        end
        if type(button.UpdateUsable) == "function" then
            hooksecurefunc(button, "UpdateUsable", UpdateActionButton)
        end
        
        -- Cooldown 객체 처리
        if button.cooldown then
            button.cooldown:HookScript("OnCooldownDone", function(s) 
                local parent = s:GetParent()
                if parent.IsPetButton then UpdatePetActionButton(parent) else UpdateActionButton(parent) end
            end)
        end
    end
end

-- ------------------------------------------------------------ --
-- Initialization
-- ------------------------------------------------------------ --
GOC:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00[GreyOnCooldown]|r 초기화 중...")
        
        -- 액션바 버튼들
        local bars = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", 
                       "MultiBarLeftButton", "MultiBarRightButton", "MultiBar5Button", 
                       "MultiBar6Button", "MultiBar7Button", "StanceButton", "ExtraActionButton" }
        for _, bar in ipairs(bars) do
            for i = 1, 12 do
                HookButton(_G[bar..i])
            end
        end

        -- 펫바
        for i = 1, 10 do
            HookButton(_G["PetActionButton"..i], true)
        end

        -- 플라이아웃
        if SpellFlyout then
            hooksecurefunc(SpellFlyout, "Toggle", function()
                local i = 1
                while _G["SpellFlyoutPopupButton"..i] do
                    HookButton(_G["SpellFlyoutPopupButton"..i])
                    i = i + 1
                end
            end)
        end

        print("|cFF00FF00[GreyOnCooldown]|r 활성화됨")

    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_STATE" then
        for button in pairs(GOC.RegisteredButtons) do
            if button:IsVisible() then
                if button.IsPetButton then UpdatePetActionButton(button) else UpdateActionButton(button) end
            end
        end
    end
end)

GOC:RegisterEvent("PLAYER_LOGIN")
GOC:RegisterEvent("SPELL_UPDATE_COOLDOWN")
GOC:RegisterEvent("ACTIONBAR_UPDATE_STATE")

print("|cFF00FF00[GreyOnCooldown]|r 로드됨")