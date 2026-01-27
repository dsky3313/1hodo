------------------------------
-- 테이블
------------------------------
local addonName, ns = ...

local function isIns() -- 인스확인
    local _, instanceType, difficultyID = GetInstanceInfo()
    return (difficultyID == 8 or instanceType == "raid") -- 1 일반 / 8 쐐기 / raid 레이드
end

local LFGListFrame = _G.LFGListFrame

------------------------------
-- 디스플레이
------------------------------
local browseGroupsBtn = CreateFrame("Button", "browseGroupsBtn", LFGListFrame, "UIPanelButtonTemplate")
browseGroupsBtn:SetSize(144, 22)
browseGroupsBtn:SetText("파티 탐색하기")
browseGroupsBtn:ClearAllPoints()
browseGroupsBtn:SetPoint("TOP", LFGListFrame, "BOTTOM", -100, 26)
browseGroupsBtn:Hide()

local returnGroupsBtn = CreateFrame("Button", "returnGroupsBtn", LFGListFrame, "UIPanelButtonTemplate")
returnGroupsBtn:SetSize(144, 22)
returnGroupsBtn:SetText("파티로 돌아가기")
returnGroupsBtn:ClearAllPoints()
returnGroupsBtn:SetPoint("TOP", LFGListFrame, "BOTTOM", -100, 26)

------------------------------
-- 동작
------------------------------
local function creatBtn()
    if not LFGListFrame then return end

    local joinedGroup = C_LFGList.GetActiveEntryInfo() ~= nil
    local isLeader = UnitIsGroupLeader("player") == true
    local shownApp = LFGListFrame.ApplicationViewer and LFGListFrame.ApplicationViewer:IsShown()
    local shownSearch = LFGListFrame.SearchPanel and LFGListFrame.SearchPanel:IsShown()

    if browseGroupsBtn then
        if shownApp and (not isLeader) and joinedGroup then -- 탐색하기 (파티 창 + 내가 파티장이 아닐 때)
            browseGroupsBtn:Show()
        else
            browseGroupsBtn:Hide()
        end
    end

    if returnGroupsBtn then -- 돌아가기 (파티목록 + 등록된 파티가 있을 때)
        if shownSearch and joinedGroup then
            returnGroupsBtn:Show()
        else
            returnGroupsBtn:Hide()
        end
    end
end

local function clickBtn()
    if not LFGListFrame or initialized then return end

    browseGroupsBtn:SetScript("OnClick", function() -- 파티 탐색하기
        if LFGListFrame.ApplicationViewer then
            local bgb = LFGListFrame.ApplicationViewer.BrowseGroupsButton
            if bgb and bgb:IsEnabled() then bgb:Click() end
        end
    end)

    local backBtn = LFGListFrame.SearchPanel and LFGListFrame.SearchPanel.BackButton -- 파티로 돌아가기
    if backBtn then
        returnGroupsBtn:SetFrameStrata(backBtn:GetFrameStrata())
        returnGroupsBtn:SetFrameLevel(backBtn:GetFrameLevel() + 10)
    end
    returnGroupsBtn:Hide()
    returnGroupsBtn:SetScript("OnClick", function()
        if not C_LFGList.GetActiveEntryInfo() then return end
        if LFGListFrame.ApplicationViewer then
            C_Timer.After(0, function() 
                LFGListFrame_SetActivePanel(LFGListFrame, LFGListFrame.ApplicationViewer)
            end)
        end
    end)

    -- 스크립트 훅 설정
    LFGListFrame.ApplicationViewer:HookScript("OnShow", creatBtn)
    LFGListFrame.SearchPanel:HookScript("OnShow", creatBtn)
    LFGListFrame:HookScript("OnHide", function()
        if browseGroupsBtn then browseGroupsBtn:Hide() end
        if returnGroupsBtn  then returnGroupsBtn:Hide()  end
    end)

    initialized = true
    creatBtn()
end

------------------------------
-- 이벤트
------------------------------
local browseGroup = CreateFrame("Frame")
browseGroup:RegisterEvent("ADDON_LOADED")
browseGroup:RegisterEvent("GROUP_ROSTER_UPDATE")
browseGroup:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")

browseGroup:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_GroupFinder" then
        clickBtn()
    elseif event == "GROUP_ROSTER_UPDATE" or event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        creatBtn()
    end
end)

if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_GroupFinder") then
    clickBtn()
end