------------------------------
-- 테이블
------------------------------
local addonName, ns = ...

local function isIns() -- 인스확인
    local _, instanceType, difficultyID = GetInstanceInfo()
    return (difficultyID == 8 or instanceType == "raid") -- 1 일반 / 8 쐐기
end

local BobberTable = {
    { label = "재활용 가능한 심하게 큰 낚시찌", value = 202207 },
}

------------------------------
-- 디스플레이
------------------------------
local BobberButton = CreateFrame("Button", "BobberButton", UIParent, "ActionButtonTemplate, SecureActionButtonTemplate")
BobberButton:SetSize(40, 40)
BobberButton:Hide()

local function updateBobberButton()
    local itemID = BobberTable[1].value
    local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemID)

    local ActionButtonObject = {
        BobberButton.icon, -- 아이콘
        BobberButton.NormalTexture, -- 기본 액션바 버튼 테두리
        BobberButton.Name, -- 기본 액션바 버튼 테두리
        BobberButton.Border, -- 사효템?
        BobberButton.HighlightTexture, -- 마우스오버 하이라이트
        BobberButton.PushedTexture, -- 버튼클릭
        BobberButton.CheckedTexture, -- 토글스킬 켜져있을 때
        BobberButton.Flash, -- 반짝?
        BobberButton.IconMask, -- 아이콘이 둥근 사각형이나 원형으로 보이게?
        BobberButton.cooldown, -- 쿨타임
    }

    for _, obj in ipairs(ActionButtonObject) do
        if obj then
            obj:ClearAllPoints()

            if obj == BobberButton.icon then
                obj:SetTexture(itemTexture or 134400)
                obj:SetPoint("TOPLEFT", BobberButton, "TOPLEFT", 2, -2)
                obj:SetPoint("BOTTOMRIGHT", BobberButton, "BOTTOMRIGHT", -2, 2)
                -- BobberButton.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

            elseif obj == BobberButton.NormalTexture or obj == BobberButton.PushedTexture then
                local atlas = (obj == BobberButton.NormalTexture) and "UI-HUD-ActionBar-IconFrame" or "UI-HUD-ActionBar-IconFrame-Down"
                obj:SetAtlas(atlas, false)
                obj:ClearAllPoints()
                obj:SetPoint("TOPLEFT", BobberButton, "TOPLEFT", 0, 0)
                obj:SetPoint("BOTTOMRIGHT", BobberButton, "BOTTOMRIGHT", 0, 0)
                if not obj.isFixed then
                    obj:SetSize(40, 40)
                    obj.SetSize = function() end
                    obj.SetWidth = function() end
                    obj.SetHeight = function() end
                    obj.isFixed = true
                end

            elseif obj == BobberButton.Name then
                obj:SetPoint("BOTTOM", BobberButton, "TOP", 0, 5)
                obj:SetWidth(200)
                obj:SetText(itemName or "아이템 이름")

            elseif obj == BobberButton.cooldown then
                obj:SetPoint("TOPLEFT", BobberButton, "TOPLEFT", 2, -2)
                obj:SetPoint("BOTTOMRIGHT", BobberButton, "BOTTOMRIGHT", -2, 2)
                obj:SetFrameLevel(BobberButton:GetFrameLevel() + 5)

                local start, duration, enable = C_Container.GetItemCooldown(itemID)
                if enable == 1 and start > 0 and duration > 0 then
                    obj:SetCooldown(start, duration)
                else
                    obj:Clear()
                end

            else
                obj:SetPoint("TOPLEFT", BobberButton, "TOPLEFT", 0, 0)
                obj:SetPoint("BOTTOMRIGHT", BobberButton, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
end








------------------------------
-- 동작
------------------------------
BobberButton:RegisterForClicks("AnyUp", "AnyDown")
BobberButton:SetAttribute("type", "item")
BobberButton:SetAttribute("item", "item:" ..BobberTable[1].value)

BobberButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(BobberTable[1].value)
    GameTooltip:Show()
end)
BobberButton:SetScript("OnLeave", GameTooltip_Hide)

function QuickBobber()
    if isIns() then
        BobberButton:Hide()
        return
    end

    local isEnabled = hodoDB.useQuickBobber ~= false -- 기본값 true
    local useQuickBobber = not (hodoDB and hodoDB.useQuickBobber == false)
    local professionsBookFrameShown = ProfessionsBookFrame and ProfessionsBookFrame:IsShown()

    if isEnabled and professionsBookFrameShown then
        if SecondaryProfession2SpellButtonLeft then
            BobberButton:SetParent(ProfessionsBookFrame)
            BobberButton:ClearAllPoints()
            BobberButton:SetPoint("LEFT", SecondaryProfession2SpellButtonLeft, "RIGHT", 50, 0)
            BobberButton:SetFrameLevel(ProfessionsBookFrame:GetFrameLevel() + 10)
            updateBobberButton() -- 아이콘 및 개수 최신화
            BobberButton:Show()
        end
    else
        BobberButton:Hide()
    end
end

------------------------------
-- 이벤트
------------------------------
local initBobberButton = CreateFrame("Frame")
initBobberButton:RegisterEvent("ADDON_LOADED")
initBobberButton:RegisterEvent("PLAYER_ENTERING_WORLD")

initBobberButton:SetScript("OnEvent", function (self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            if isIns() then
                BobberButton:Hide()
            else
                QuickBobber()
            end
        end)
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_ProfessionsBook" then
        if ProfessionsBookFrame then
            ProfessionsBookFrame:HookScript("OnShow", QuickBobber)
            ProfessionsBookFrame:HookScript("OnHide", QuickBobber)
        end
    end
end)

ns.QuickBobber = QuickBobber