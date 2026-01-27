------------------------------
-- 테이블
------------------------------
local addonName, ns = ...

------------------------------
-- 체크박스
------------------------------
function Checkbox(category, varName, label, tooltip, default)
    local varID = "dodo_" .. varName

    local setting = Settings.GetSetting(varID)
    if not setting then
        setting = Settings.RegisterAddOnSetting(category, varID, varName, dodoDB, Settings.VarType.Boolean, label, default)
    end

    local initializer = Settings.CreateControlInitializer("dodoCheckboxTemplate", setting, nil, tooltip)
    setting:SetValueChangedCallback(function()

        if ns.browseGroupsButton then ns.browseGroupsButton() end
        if ns.expFilter then ns.expFilter() end
        if ns.DeleteNow then ns.DeleteNow() end
        if ns.Mykey then ns.Mykey() end
        if ns.PartyClass then ns.PartyClass() end

    end)

    -- 레이아웃에 추가
    local layout = SettingsPanel:GetLayout(category)
    if layout then
        layout:AddInitializer(initializer)
    end

    return setting, initializer
end