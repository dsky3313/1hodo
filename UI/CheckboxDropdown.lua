------------------------------
-- 테이블 및 네임스페이스
------------------------------
local addonName, ns = ...

------------------------------
-- [메인] 체크박스 + 드롭다운 복합 함수
------------------------------
function CheckBoxDropDown(category, varNameCB, varNameDD, label, tooltip, options, defaultCB, defaultDD, func)
    local varID_CB = "hodo_" .. varNameCB
    local varID_DD = "hodo_" .. varNameDD

    local cbSetting = Settings.GetSetting(varID_CB) or Settings.RegisterAddOnSetting(category, varID_CB, varNameCB, hodoDB, Settings.VarType.Boolean, label, defaultCB or false)
    
    local fallbackValue = (options and options[1]) and options[1].value or ""
    local ddSetting = Settings.GetSetting(varID_DD) or Settings.RegisterAddOnSetting(category, varID_DD, varNameDD, hodoDB, Settings.VarType.String, label, defaultDD or fallbackValue)

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        if options then
            for _, option in ipairs(options) do
                container:Add(option.value, option.label)
            end
        end
        return container:GetData()
    end

    -- 블리자드 표준 데이터 구조
    local data = {
        name = label,
        tooltip = tooltip,
        cbSetting = cbSetting,
        dropDownSetting = ddSetting, -- 블리자드 내부 키값 확인 필요 (보통 dropDownSetting)
        options = GetOptions,
    }

    local initializer = Settings.CreateSettingInitializer("hodoCheckboxDropdownTemplate", data)

    local function OnValueChanged()
        if func then func() end
    end
    cbSetting:SetValueChangedCallback(OnValueChanged)
    ddSetting:SetValueChangedCallback(OnValueChanged)

    local layout = SettingsPanel:GetLayout(category)
    if layout then
        layout:AddInitializer(initializer)
    end
end