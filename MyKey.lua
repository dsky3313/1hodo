------------------------------
-- 1. 테이블 및 변수 선언 (순서 중요)
------------------------------
local addonName, ns = ...
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true)

-- 이벤트 프레임을 미리 생성하여 아래 함수들이 참조할 수 있게 함
local EventFrame = CreateFrame("Frame")

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
-- 2. 디스플레이
------------------------------
-- 드롭다운
local keyDropDown = CreateFrame("DropdownButton", "KeyDropDownBtn", lfgDifficulty, "WowStyle1DropdownTemplate")
keyDropDown:SetWidth(138)
keyDropDown:SetPoint("TOP", lfgDifficulty, "BOTTOM", 0, -7)

-- 복사창 (템플릿 변경 및 버튼 제거)
local copyKeyFrame = CreateFrame("Frame", "HodoCopyDialog", UIParent, "BackdropTemplate")
copyKeyFrame:SetSize(350, 100) -- 확인 버튼이 없어지므로 높이를 줄임
copyKeyFrame:SetPoint("CENTER", "UIParent", "CENTER", 0, 100)
copyKeyFrame:SetFrameStrata("DIALOG")
copyKeyFrame:Hide()

-- 배경 설정 (와우 기본 스타일)
copyKeyFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- 헤더 (기존 스타일 유지)
copyKeyFrame.Header = CreateFrame("Frame", nil, copyKeyFrame, "DialogHeaderTemplate")
copyKeyFrame.Header:SetPoint("TOP", 0, 12)
copyKeyFrame.Header.Text:SetText("돌 정보 복사")

-- 안내 텍스트
copyKeyFrame.text = copyKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
copyKeyFrame.text:SetPoint("CENTER", 0, 4)
copyKeyFrame.text:SetText("Ctrl+C로 복사하면 자동으로 닫힙니다")

-- 에디트박스
copyKeyFrame.editBox = CreateFrame("EditBox", nil, copyKeyFrame, "InputBoxTemplate")
copyKeyFrame.editBox:SetSize(260, 30)
copyKeyFrame.editBox:SetPoint("BOTTOM", 0, 15)
copyKeyFrame.editBox:SetAutoFocus(false)

------------------------------
-- 3. 동작
------------------------------
copyKeyFrame.editBox:SetScript("OnKeyDown", function(self, key)
    if key == "C" and IsControlKeyDown() then
        C_Timer.After(0.1, function()
            copyKeyFrame:Hide()
            -- 복사 후 파티 이름 입력창으로 포커스 이동 (기존 로직 유지)
            local nameBox = LFGListFrame.EntryCreation.Name
            if nameBox and nameBox:IsVisible() then
                nameBox:SetFocus()
                nameBox:HighlightText()
            end
        end)
    end
end)

-- ESC나 포커스 해제 시 닫기
copyKeyFrame.editBox:SetScript("OnEscapePressed", function() copyKeyFrame:Hide() end)
copyKeyFrame.editBox:SetScript("OnEditFocusLost", function() copyKeyFrame:Hide() end)

-- 마우스 클릭 시 창 닫기 (빈 공간 클릭 대응)
copyKeyFrame:SetScript("OnMouseDown", function() copyKeyFrame:Hide() end)

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

-- [수정] EventFrame을 직접 참조하도록 고정
local function ManageEvents(enable)
    if enable and hodoDB and hodoDB.useMyKey then
        EventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
        EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        EventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    else
        EventFrame:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
        EventFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
        EventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        EventFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
    end
end

local function UpdateButtonVisibility()
    -- 1. 설정이 꺼졌거나 2. 인스턴스 안이라면 기능을 숨기고 이벤트 해제
    if not hodoDB or hodoDB.useMyKey == false or IsInInstance() then
        keyDropDown:Hide()
        ManageEvents(false)
        return
    end
    
    -- LFG 창의 활동 선택 드롭다운이 보일 때만 쐐기돌 드롭다운 표시
    local isTargetVisible = lfgDifficulty:IsVisible() and lfgDifficulty:GetHeight() > 1
    keyDropDown:SetShown(isTargetVisible)
    
    if isTargetVisible then 
        ManageEvents(true)
        Refresh() 
    else
        ManageEvents(false)
    end
end

-- 후킹 및 외부 연동
lfgDifficulty:HookScript("OnShow", UpdateButtonVisibility)
lfgDifficulty:HookScript("OnHide", UpdateButtonVisibility)
lfgDifficulty:HookScript("OnSizeChanged", function() UpdateButtonVisibility() end)

LFGListFrame.EntryCreation:HookScript("OnShow", function()
    UpdateButtonVisibility()
end)

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
-- 4. 이벤트 핸들러
------------------------------
-- PLAYER_ENTERING_WORLD는 지역 이동(인스 출입) 감지를 위해 상시 등록
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

EventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateButtonVisibility()
    elseif hodoDB and hodoDB.useMyKey then
        if event == "PLAYER_REGEN_ENABLED" then 
            Refresh() 
        elseif event == "GROUP_ROSTER_UPDATE" then
            if openRaidLib then openRaidLib.RequestKeystoneDataFromParty() end
            Refresh()
        else
            Refresh()
        end
    end
end)

-- 외부 호출용 업데이트 함수 (1Option.lua 연동용)
function MykeyUpdate()
    UpdateButtonVisibility()
end
ns.MykeyUpdate = MykeyUpdate