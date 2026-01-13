------------------------------
-- 테이블
------------------------------
local addonName, ns = ...
hodoDB = hodoDB or {}

local function isIns() -- 인스확인
    local _, instanceType, difficultyID = GetInstanceInfo()
    return (difficultyID == 1 or instanceType == "raid") -- 1 일반 / 8 쐐기
end

------------------------------
-- 디스플레이
------------------------------
local abc = CreateFrame("Frame")

------------------------------
-- 동작
------------------------------
local function FuncName()
    if isIns() then return end
end

ns.FuncName = FuncName
------------------------------
-- 이벤트
------------------------------
local initFuncName = CreateFrame("Frame")
initFuncName:RegisterEvent("PLAYER_LOGIN")
initFuncName:SetScript("OnEvent", function(self, event)
    if FuncName then FuncName()
    end
    self:UnregisterAllEvents()
end)