local addonName, ns = ...

-- [이니셜라이저 생성 부분은 동일]
function CreateHodoInitializer(cbSetting, cbLabel, cbTooltip, dropdownSetting, dropdownOptions)
    local template = "HodoCheckboxDropdownTemplate"
    local initializer = Settings.CreateElementInitializer(template, {
        name = cbLabel,
        tooltip = cbTooltip,
        cbSetting = cbSetting,
        dropdownSetting = dropdownSetting,
        dropdownOptions = dropdownOptions,
        GetSetting = function(self) return self.cbSetting end,
    })
    initializer.data = initializer:GetData()
    initializer.frameTemplate = template
    return initializer
end

-- [수정된 메인 함수]
function CheckBoxDropDown(category, varNameCB, varNameDD, label, tooltip, options, defaultCB, defaultDD, func)
    local varID_CB = "hodo_" .. varNameCB
    local varID_DD = "hodo_" .. varNameDD

    local cbSetting = Settings.GetSetting(varID_CB) or Settings.RegisterAddOnSetting(category, varID_CB, varNameCB, hodoDB, Settings.VarType.Boolean, label, defaultCB or false)
    local fallbackValue = (options and options[1]) and options[1].value or ""
    local ddSetting = Settings.GetSetting(varID_DD) or Settings.RegisterAddOnSetting(category, varID_DD, varNameDD, hodoDB, Settings.VarType.String, label, defaultDD or fallbackValue)

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        for _, option in ipairs(options) do
            container:Add(option.value, option.label)
        end
        return container:GetData()
    end

    local initializer = CreateHodoInitializer(cbSetting, label, tooltip, ddSetting, GetOptions)

    -- 전달받은 func를 실행하도록 설정
    local function OnValueChanged()
        if func then func() end
    end

    cbSetting:SetValueChangedCallback(OnValueChanged)
    ddSetting:SetValueChangedCallback(OnValueChanged)

    local layout = SettingsPanel:GetLayout(category)
    if layout and initializer then
        layout:AddInitializer(initializer)
    end

    -- [중요] 밖에서 부모-자식 관계를 맺을 수 있도록 값들을 반환해줍니다.
    return cbSetting, initializer
end