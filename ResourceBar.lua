-- ==============================
-- 테이블 (수정)
-- ==============================
local addonName, dodo = ...
dodoDB = dodoDB or {}
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local barConfigs = {
    { name = "ResourceBar1", width = 276, height = 10, y = -220, level = 3000, template = "ResourceBar1Template" },
    { name = "ResourceBar2", width = 270, height = 8, y = -5, level = 2999, template = "ResourceBar2Template" }
}

-- ✅ 수정: 특성별로 여러 버프 배열로 관리
local ClassConfig = {
    ["WARRIOR"] = {
        [1] = {
            { spellName = L["투신"], barMode = "duration", duration = 20, color = { r = 1.0, g = 0.588, b = 0.196 } },
        },
        [2] = {
            { spellName = L["소용돌이 연마"], barMode = "stack", maxStack = 4, color = { r = 0, g = 0.82, b = 1 } },
        },
        [3] = {
            { spellName = L["고통 감내"], barMode = "stack", maxStack = 100, color = { r = 1, g = 0.588, b = 0.196 } },
        },
    },
}

-- ✅ 수정: 현재 특성의 버프 목록 저장
local currentSpecBuffs = {}

local function UpdateCurrentSpecConfig()
    local _, englishClass = UnitClass("player")
    local spec = C_SpecializationInfo.GetSpecialization()
    currentSpecBuffs = (ClassConfig[englishClass] and ClassConfig[englishClass][spec]) or {}
    
    print(string.format("[ResourceBar2] 특성 변경: %s - 추적 버프: %d개", englishClass, #currentSpecBuffs))
    for i, buff in ipairs(currentSpecBuffs) do
        print(string.format("  [%d] %s", i, buff.spellName))
    end
end

-- ==============================
-- ResourceBar2 로직
-- ==============================
local ResourceBar2Mixin = {}

function ResourceBar2Mixin:SetViewerItem(viewerItem)
    self.viewerItem = viewerItem
end

-- ✅ 추가: 버프 설정 저장 함수
function ResourceBar2Mixin:SetBuffConfig(buffConfig)
    self.buffConfig = buffConfig
end

function ResourceBar2Mixin:Update()
    -- ✅ 수정: buffConfig에서 최대값 동적으로 가져오기
    local maxValue = 100  -- 기본값
    
    if self.buffConfig then
        if self.buffConfig.barMode == "duration" then
            -- Duration 모드: duration 값 사용
            maxValue = self.buffConfig.duration or 20
        elseif self.buffConfig.barMode == "stack" then
            -- Stack 모드: maxStack 값 사용
            maxValue = self.buffConfig.maxStack or 100
        end
    end
    
    self:SetMinMaxValues(0, maxValue)
    
    -- ✅ 설정값에서 색상 가져오기
    local color = self.buffConfig and self.buffConfig.color or { r = 1.0, g = 0.588, b = 0.196 }
    self:SetStatusBarColor(color.r, color.g, color.b)

    if not self.viewerItem or not self.viewerItem.auraInstanceID then
        if self.countStack then self.countStack:SetText("0") end
        self:SetValue(0, Enum.StatusBarInterpolation.ExponentialEaseOut)
        return
    end

    local unit = self.viewerItem.auraDataUnit
    local auraInstanceID = self.viewerItem.auraInstanceID

    if unit and auraInstanceID then
        local duration = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
        if duration then
            self.Cooldown:SetCooldownFromDurationObject(duration, true)
            self.Cooldown:Show()
        else
            self.Cooldown:Hide()
        end

        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
        if auraData then
            local countBar = auraData.applications or 0
            self.countStack:SetText(countBar)
            self:SetValue(countBar, Enum.StatusBarInterpolation.ExponentialEaseOut)
            self:Show()
        end
    end
end

---@diagnostic disable: redundant-parameter

-- ==============================
-- UI 생성
-- ==============================
local bar1Frame = CreateFrame("StatusBar", "ResourceBar1", UIParent, barConfigs[1].template)
bar1Frame:SetSize(barConfigs[1].width, barConfigs[1].height)
bar1Frame:SetPoint("CENTER", UIParent, "CENTER", 0, barConfigs[1].y)
bar1Frame:SetFrameLevel(barConfigs[1].level)

local bar2Frame = CreateFrame("StatusBar", "ResourceBar2", UIParent, barConfigs[2].template)
Mixin(bar2Frame, ResourceBar2Mixin)
bar2Frame:SetSize(barConfigs[2].width, barConfigs[2].height)
bar2Frame:SetPoint("TOP", bar1Frame, "BOTTOM", 0, barConfigs[2].y)
bar2Frame:SetFrameLevel(barConfigs[2].level)

-- ==============================
-- 업데이트 로직
-- ==============================
local function UpdateBar1()
    if not bar1Frame then return end

    local powerType, powerToken = UnitPowerType("player")
    local current = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)

    if max and max > 0 then
        bar1Frame:SetMinMaxValues(0, max)
        bar1Frame:SetValue(current, Enum.StatusBarInterpolation.ExponentialEaseOut)
        if bar1Frame.countPower then 
            bar1Frame.countPower:SetText(tostring(current)) 
        end
    end

    local color = PowerBarColor[powerToken] or PowerBarColor[powerType] or {r=1, g=1, b=1}
    bar1Frame:SetStatusBarColor(color.r, color.g, color.b)

    if bar2Frame and bar2Frame.Update then
        bar2Frame:Update()
    end
end

C_Timer.NewTicker(0.1, UpdateBar1)

-- ==============================
-- ResourceBar2 CDM 연동
-- ==============================
local ResourceBar2UpdaterMixin = {}

function ResourceBar2UpdaterMixin:OnLoad()
    self.bar2Frame = _G["ResourceBar2"]

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            UpdateCurrentSpecConfig()
            if bar2Frame and bar2Frame.Update then
                bar2Frame:Update()
            end
        end
    end)

    local hook = function(_, item) self:HookViewerItem(item) end
    hooksecurefunc(BuffBarCooldownViewer, 'OnAcquireItemFrame', hook)
    hooksecurefunc(BuffIconCooldownViewer, 'OnAcquireItemFrame', hook)

    for _, viewer in ipairs({BuffBarCooldownViewer, BuffIconCooldownViewer}) do
        for _, itemFrame in ipairs(viewer:GetItemFrames()) do
            if itemFrame.cooldownID then 
                self:HookViewerItem(itemFrame) 
            end
        end
    end

    UpdateCurrentSpecConfig()
end

function ResourceBar2UpdaterMixin:UpdateFromItem(item)
    if not item or not item.cooldownID then return end

    local cdInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(item.cooldownID)
    if not cdInfo or not cdInfo.spellID then return end

    local spellName = C_Spell.GetSpellName(cdInfo.spellID)

    -- ✅ 현재 특성의 모든 버프 순회
    for _, buffConfig in ipairs(currentSpecBuffs) do
        if spellName == buffConfig.spellName then
            if self.bar2Frame and self.bar2Frame.SetViewerItem then
                self.bar2Frame:SetViewerItem(item)
                -- ✅ 추가: 매칭된 버프 설정을 바에 저장
                self.bar2Frame:SetBuffConfig(buffConfig)
                self.bar2Frame:Update()
            end
            return
        end
    end
end

function ResourceBar2UpdaterMixin:HookViewerItem(item)
    if not item.__CDMBAHooked then
        hooksecurefunc(item, 'RefreshData', function() 
            self:UpdateFromItem(item) 
        end)
        item.__CDMBAHooked = true
    end
    self:UpdateFromItem(item)
end

local updater = CreateFrame("Frame", "ResourceBar2Updater", UIParent)
Mixin(updater, ResourceBar2UpdaterMixin)
updater:OnLoad()