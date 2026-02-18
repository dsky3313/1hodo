-- ============================================================
-- [Actionbar] Cooldown Return Fix & Performance Optimized
-- ============================================================
---@diagnostic disable: lowercase-global, undefined-field, undefined-global
local addonName, dodo = ...

local actionbarConfig = {
    Enabled = true,
    DesaturateUnusable = true,
    Colors = {
        Range = { r = 0.9, g = 0.1, b = 0.1 },
        Mana = { r = 0.1, g = 0.3, b = 1.0 },
        Normal = { r = 1, g = 1, b = 1 },
    }
}

local actionbar = CreateFrame("Frame")

-- 보안 곡선 (0.001초라도 남으면 1, 아니면 0 반환)
local DesaturationCurve = C_CurveUtil.CreateCurve()
DesaturationCurve:SetType(Enum.LuaCurveType.Step)
DesaturationCurve:AddPoint(0, 0)
DesaturationCurve:AddPoint(0.001, 1)

-- ==============================
-- 1. 아이콘 색상 및 흑백 적용
-- ==============================
local function UpdateIconColor(button)
    if not actionbarConfig.Enabled or not button.icon then return end

    local icon = button.icon
    local desat = 0

    -- [색상 우선순위] 사거리 > 마나 > 일반
    if button.__isOutOfRange then
        desat = 1
        icon:SetVertexColor(actionbarConfig.Colors.Range.r, actionbarConfig.Colors.Range.g, actionbarConfig.Colors.Range.b)
    elseif button.__isNotEnoughMana then
        desat = 1
        icon:SetVertexColor(actionbarConfig.Colors.Mana.r, actionbarConfig.Colors.Mana.g, actionbarConfig.Colors.Mana.b)
    else
        icon:SetVertexColor(actionbarConfig.Colors.Normal.r, actionbarConfig.Colors.Normal.g, actionbarConfig.Colors.Normal.b)
    end

    -- [흑백 처리]
    if desat == 0 then
        if actionbarConfig.DesaturateUnusable and button.__isUsable == false then
            desat = 1
        else
            desat = button.__cdVal or 0
        end
    end

    icon:SetDesaturation(desat)
end

-- ==============================
-- 2. 상태 업데이트 (사거리/마나)
-- ==============================
local function UpdateState(button)
    local action = button.action
    if not action then return end

    local isUsable, notEnoughMana = C_ActionBar.IsUsableAction(action)
    local inRange = C_ActionBar.IsActionInRange(action)

    button.__isUsable = isUsable
    button.__isNotEnoughMana = notEnoughMana
    button.__isOutOfRange = (inRange == false)

    UpdateIconColor(button)
end

-- ==============================
-- 3. 쿨다운 업데이트
-- ==============================
local function UpdateCooldownState(button)
    local action = button.action
    if not action then return end

    local duration = C_ActionBar.GetActionCooldownDuration(action)
    local cdInfo = C_ActionBar.GetActionCooldown(action)

    if duration and cdInfo and not cdInfo.isOnGCD then
        button.__cdVal = duration:EvaluateRemainingDuration(DesaturationCurve)
    else
        button.__cdVal = 0
    end
    
    UpdateIconColor(button)
end

-- ==============================
-- 4. Hook 및 최적화
-- ==============================
local function OnRangeUpdate(slot)
    local buttons = ActionBarButtonRangeCheckFrame.actions and ActionBarButtonRangeCheckFrame.actions[slot]
    if buttons then
        for _, button in pairs(buttons) do
            if button:IsVisible() then UpdateState(button) end
        end
    end
end

local function Hook_ApplyCooldown(cooldownFrame)
    local button = cooldownFrame:GetParent()
    if not button or not button.action then return end
    
    C_Timer.After(0, function() 
        if button:IsVisible() then
            UpdateCooldownState(button)
        end
    end)
end

local function HookButton(button)
    if not button then return end
    if button.Update then hooksecurefunc(button, "Update", UpdateState) end
    if button.UpdateUsable then hooksecurefunc(button, "UpdateUsable", UpdateState) end
    
    -- [추가] 쿨다운이 끝나는 순간 즉시 갱신하기 위한 스크립트 훅
    if button.cooldown then
        button.cooldown:HookScript("OnCooldownDone", function(self)
            local p = self:GetParent()
            if p then
                p.__cdVal = 0
                UpdateIconColor(p)
            end
        end)
    end
    
    UpdateState(button)
    UpdateCooldownState(button)
end

-- ==============================
-- 5. 이벤트 핸들러
-- ==============================
actionbar:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        local bars = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton", "StanceButton" }
        for _, bar in ipairs(bars) do 
            for i = 1, 12 do HookButton(_G[bar..i]) end 
        end
        
        if ActionButton_ApplyCooldown then
            hooksecurefunc("ActionButton_ApplyCooldown", Hook_ApplyCooldown)
        end
        
    elseif event == "ACTION_RANGE_CHECK_UPDATE" then
        OnRangeUpdate(...)
    elseif event == "PLAYER_TARGET_CHANGED" then -- 대상 변경 시 즉시 갱신 (사거리 색상용)
        for button in pairs(actionbar.RegisteredButtons or {}) do
            if button:IsVisible() then UpdateState(button) end
        end
    end
end)

actionbar:RegisterEvent("PLAYER_LOGIN")
actionbar:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
actionbar:RegisterEvent("PLAYER_TARGET_CHANGED")