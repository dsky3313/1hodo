------------------------------
-- 테이블
------------------------------
-- local addonName, ns = ...

------------------------------
-- 디스플레이
------------------------------
--

------------------------------
-- 동작
------------------------------
-- local function FuncName()
-- local _, instanceType, difficultyID = GetInstanceInfo()
-- if difficultyID == 8 or instanceType == "raid" then return end -- 8 쐐기 / raid 레이드
-- end

-- ns.FuncName = FuncName
------------------------------
-- 이벤트
------------------------------
-- local initFuncName = CreateFrame("Frame")
-- initFuncName:RegisterEvent("PLAYER_LOGIN")
-- initFuncName:SetScript("OnEvent", function(self, event)
--     hodoDB = hodoDB or {} 260111
--     if FuncName then FuncName()
--     end
--     self:UnregisterAllEvents()
-- end)