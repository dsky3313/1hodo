------------------------------
-- 테이블
------------------------------
local addonName, ns = ...
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true)

local dungeonName = {
    ["그림 바톨"] = "그림바톨",
    ["보랄러스 공성전"] = "보랄",
    ["죽음의 상흔"] = "죽상",
    ["티르너 사이드의 안개"] = "티르너",
    ["속죄의 전당"] = "속죄",
    ["미지의 시장 타자베쉬: 경이의 거리"] = "거리",
    ["미지의 시장 타자베쉬: 소레아의 승부수"] = "승부수",

    ["부화장"] = "부화장",
    ["새벽인도자호"] = "새인호",
    ["신성한 불꽃의 수도원"] = "수도원",
    ["작전명: 수문"] = "수문",
    ["실타래의 도시"] = "실타래",
    ["아라카라: 메아리의 도시"] = "아라카라",
    ["생태지구 알다니"] = "알다니",
    ["잿불맥주 양조장"] = "양조장",
    ["어둠불꽃 동굴"] = "어불동",
}
local lfgDifficulty = LFGListFrame.EntryCreation.ActivityDropdown
local function GetMyKeyShortName(fullName) return dungeonName[fullName] or fullName end
local function GetMyKeyInfo()
    local keyMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if keyMapID and keyLevel then
        return C_ChallengeMode.GetMapUIInfo(keyMapID), keyLevel
    end
    return nil, nil
end

------------------------------
-- 디스플레이
------------------------------
local keyDropDown = CreateFrame("DropdownButton", "KeyDropDownBtn", lfgDifficulty, "WowStyle1DropdownTemplate")
keyDropDown:SetWidth(138)
keyDropDown:SetPoint("TOP", lfgDifficulty, "BOTTOM", 0, -7)

local copyKeyFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
copyKeyFrame:SetSize(350, 100)
copyKeyFrame:SetPoint("CENTER", 0, 100)
copyKeyFrame:SetFrameStrata("DIALOG")
copyKeyFrame:EnableMouse(true) -- 외부 클릭 감지용
copyKeyFrame:Hide()

copyKeyFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

copyKeyFrame.Header = CreateFrame("Frame", nil, copyKeyFrame, "DialogHeaderTemplate")
copyKeyFrame.Header:SetPoint("TOP", 0, 12)
copyKeyFrame.Header.Text:SetText("돌 정보 복사")

copyKeyFrame.text = copyKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
copyKeyFrame.text:SetPoint("TOP", 0, -35)
copyKeyFrame.text:SetText("Ctrl+C로 복사하면 자동으로 닫힙니다")

copyKeyFrame.editBox = CreateFrame("EditBox", nil, copyKeyFrame, "InputBoxTemplate")
copyKeyFrame.editBox:SetSize(260, 30)
copyKeyFrame.editBox:SetPoint("BOTTOM", 0, 20)
copyKeyFrame.editBox:SetAutoFocus(false)

------------------------------
-- 동작
------------------------------
-- [복구] ESC 및 외부 클릭 시 닫기
copyKeyFrame.editBox:SetScript("OnEscapePressed", function() copyKeyFrame:Hide() end)
copyKeyFrame.editBox:SetScript("OnEditFocusLost", function() copyKeyFrame:Hide() end)
copyKeyFrame:SetScript("OnMouseDown", function() copyKeyFrame:Hide() end)

copyKeyFrame.editBox:SetScript("OnKeyDown", function(self, key)
    if key == "C" and IsControlKeyDown() then
        C_Timer.After(0.1, function()
            copyKeyFrame:Hide()
            local nameBox = LFGListFrame.EntryCreation.Name
            if nameBox and nameBox:IsVisible() then
                nameBox:SetFocus()
                nameBox:HighlightText()
            end
        end)
    end
end)

local function ShowCopyWindow(text)
    copyKeyFrame:Show()
    copyKeyFrame.editBox:SetText(text)
    copyKeyFrame.editBox:SetFocus()
    copyKeyFrame.editBox:HighlightText()
end

local function Refresh()
    if InCombatLockdown() or not keyDropDown:IsVisible() then return end
    local name, level = GetMyKeyInfo()
    keyDropDown:SetText(name and string.format("+%d %s", level, GetMyKeyShortName(name)) or "보유 돌 없음")
end

local function UpdateButtonVisibility()
    if not hodoDB or hodoDB.useMyKey == false or IsInInstance() then
        keyDropDown:Hide()
        return
    end
    
    local isTargetVisible = lfgDifficulty:IsVisible() and lfgDifficulty:GetHeight() > 1
    keyDropDown:SetShown(isTargetVisible)
    
    if isTargetVisible then 
        -- [복구] 내 돌 즉시 표시를 위해 딜레이 없이 실행 및 0.01초 뒤 재확인
        Refresh()
        C_Timer.After(0.01, Refresh)
    end
end

lfgDifficulty:HookScript("OnShow", UpdateButtonVisibility)
lfgDifficulty:HookScript("OnHide", UpdateButtonVisibility)
LFGListFrame.EntryCreation:HookScript("OnShow", UpdateButtonVisibility)

keyDropDown:SetupMenu(function(dropdown, rootDescription)
    if InCombatLockdown() then return end
    local myName, myLevel = GetMyKeyInfo()
    if myName then
        local myTitle = string.format("+%d %s", myLevel, GetMyKeyShortName(myName))
        rootDescription:CreateButton("|cff00ff00[내 돌]|r " .. myTitle, function() ShowCopyWindow(myTitle) end)
    end
    
    if IsInGroup() and openRaidLib then
        local allKeys = openRaidLib.GetAllKeystonesInfo()
        for name, data in pairs(allKeys) do
            if name ~= UnitName("player") then
                local pName = name:gsub("%-.+", "")
                local dName = C_ChallengeMode.GetMapUIInfo(data.challengeMapID)
                local pTitle = string.format("+%d %s", data.level, GetMyKeyShortName(dName))
                rootDescription:CreateButton(string.format("|cff00ccff[%s]|r %s", pName, pTitle), function() ShowCopyWindow(pTitle) end)
            end
        end
    end
end)

------------------------------
-- 이벤트
------------------------------
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateButtonVisibility()
    elseif hodoDB and hodoDB.useMyKey then
        if event == "GROUP_ROSTER_UPDATE" and openRaidLib then
            openRaidLib.RequestKeystoneDataFromParty()
        end
        Refresh()
    end
end)

function MykeyUpdate() UpdateButtonVisibility() end
ns.MykeyUpdate = MykeyUpdate