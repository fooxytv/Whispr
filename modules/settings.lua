Whispr.Settings = {}

-- Settings panel reference
Whispr.Settings.panel = nil
Whispr.Settings.expanded = false

-- Default settings configuration
Whispr.Settings.settings = {
    borderColor = {r = 0.2, g = 0.4, b = 0.8, a = 0.6},
    fontSize = 12,
    fontFace = "GameFontNormal",
    backgroundColor = {r = 0.08, g = 0.08, b = 0.12, a = 0.95},
    yourMessageColor = {r = 0.7, g = 0.9, b = 1.0},
    showTimestamps = true,
    fadeMessages = false,
    enableNotifications = true,
    notificationSound = true,
    theme = "dark" -- dark, light, auto
}

function Whispr.Settings:OnInit()
    -- Initialize settings when addon loads
    -- TODO: Load saved settings from SavedVariables
end

function Whispr.Settings:CreateSettingsPanel()
    local frame = Whispr.Chat:GetFrame()
    if not frame then return end

    -- Create the settings panel with InsetFrameTemplate3 styling to match the sidebar
    local settingsPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    settingsPanel:SetPoint("TOPLEFT", Whispr.Chat:GetChatArea(), "TOPRIGHT", 2, 0)
    settingsPanel:SetPoint("BOTTOMLEFT", Whispr.Chat:GetChatArea(), "BOTTOMRIGHT", 2, 0)
    settingsPanel:SetWidth(300)
    settingsPanel:Hide() -- Start hidden

    self.panel = settingsPanel

    -- Settings header
    local header = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", 0, -15)
    header:SetText("Chat Settings")
    header:SetTextColor(1, 1, 1)

    -- Create a scroll frame for settings content
    local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(260, 600) -- Increased height for more settings
    scrollFrame:SetScrollChild(content)

    local yOffset = -10

    -- Appearance Section
    yOffset = self:CreateSectionHeader(content, "Appearance", yOffset)

    -- Theme Selection
    yOffset = self:CreateThemeSelector(content, yOffset)

    -- Border Color Setting
    yOffset = self:CreateColorSetting(content, "Border Color:", "borderColor", yOffset)

    -- Background Color Setting
    yOffset = self:CreateColorSetting(content, "Background Color:", "backgroundColor", yOffset)

    -- Your Message Color Setting
    yOffset = self:CreateColorSetting(content, "Your Message Color:", "yourMessageColor", yOffset)

    -- Font Size Setting
    yOffset = self:CreateFontSizeSlider(content, yOffset)

    -- Messages Section
    yOffset = self:CreateSectionHeader(content, "Messages", yOffset)

    -- Show Timestamps Checkbox
    yOffset = self:CreateCheckbox(content, "Show Timestamps", "showTimestamps", yOffset)

    -- Fade Messages Checkbox
    yOffset = self:CreateCheckbox(content, "Fade Old Messages", "fadeMessages", yOffset)

    -- Notifications Section
    yOffset = self:CreateSectionHeader(content, "Notifications", yOffset)

    -- Enable Notifications Checkbox
    yOffset = self:CreateCheckbox(content, "Enable Notifications", "enableNotifications", yOffset)

    -- Notification Sound Checkbox
    yOffset = self:CreateCheckbox(content, "Notification Sound", "notificationSound", yOffset)

    -- Actions Section
    yOffset = self:CreateSectionHeader(content, "Actions", yOffset)

    -- Reset to Defaults Button
    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetSize(140, 25)
    resetButton:SetPoint("TOP", 0, yOffset)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        self:ResetSettings()
    end)
    yOffset = yOffset - 35

    -- Export Settings Button
    local exportButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportButton:SetSize(140, 25)
    exportButton:SetPoint("TOP", 0, yOffset)
    exportButton:SetText("Export Settings")
    exportButton:SetScript("OnClick", function()
        self:ExportSettings()
    end)
end

function Whispr.Settings:CreateSectionHeader(parent, title, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 10, yOffset)
    header:SetText("|cff00ccff" .. title .. "|r") -- Cyan colored section headers

    -- Add a subtle line under the header
    local line = parent:CreateTexture(nil, "BACKGROUND")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    line:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
    line:SetColorTexture(0.3, 0.6, 1, 0.3)

    return yOffset - 30
end

function Whispr.Settings:CreateColorSetting(parent, label, settingKey, yOffset)
    local colorLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", 10, yOffset)
    colorLabel:SetText(label)

    local colorButton = CreateFrame("Button", nil, parent)
    colorButton:SetSize(40, 20)
    colorButton:SetPoint("TOPRIGHT", -10, yOffset)

    -- Create border for the color button
    local border = colorButton:CreateTexture(nil, "BORDER")
    border:SetAllPoints()
    border:SetColorTexture(0.3, 0.3, 0.3, 1)

    local bg = colorButton:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", border, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
    bg:SetColorTexture(
        self.settings[settingKey].r,
        self.settings[settingKey].g,
        self.settings[settingKey].b,
        1
    )

    colorButton:SetScript("OnClick", function()
        self:ShowColorPicker(settingKey, bg)
    end)

    -- Hover effect
    colorButton:SetScript("OnEnter", function(self)
        border:SetColorTexture(0.8, 0.8, 0.8, 1)
    end)

    colorButton:SetScript("OnLeave", function(self)
        border:SetColorTexture(0.3, 0.3, 0.3, 1)
    end)

    return yOffset - 35
end

function Whispr.Settings:CreateFontSizeSlider(parent, yOffset)
    local fontLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", 10, yOffset)
    fontLabel:SetText("Font Size:")

    local fontSizeSlider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    fontSizeSlider:SetPoint("TOPRIGHT", -40, yOffset - 5)
    fontSizeSlider:SetSize(120, 20)
    fontSizeSlider:SetMinMaxValues(8, 20)
    fontSizeSlider:SetValue(self.settings.fontSize)
    fontSizeSlider:SetValueStep(1)
    fontSizeSlider:SetObeyStepOnDrag(true)

    local fontSizeText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontSizeText:SetPoint("RIGHT", fontSizeSlider, "LEFT", -10, 0)
    fontSizeText:SetText(self.settings.fontSize)

    fontSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        fontSizeText:SetText(value)
        Whispr.Settings.settings.fontSize = value
        Whispr.Settings:ApplySettings()
    end)

    return yOffset - 45
end

function Whispr.Settings:CreateCheckbox(parent, label, settingKey, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 10, yOffset)
    checkbox:SetChecked(self.settings[settingKey])

    local checkboxLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText(label)

    checkbox:SetScript("OnClick", function(self)
        Whispr.Settings.settings[settingKey] = self:GetChecked()
        Whispr.Settings:ApplySettings()
    end)

    return yOffset - 35
end

function Whispr.Settings:CreateThemeSelector(parent, yOffset)
    local themeLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    themeLabel:SetPoint("TOPLEFT", 10, yOffset)
    themeLabel:SetText("Theme:")

    -- Create theme buttons
    local themes = {
        {key = "dark", name = "Dark", color = {0.1, 0.1, 0.1}},
        {key = "light", name = "Light", color = {0.9, 0.9, 0.9}},
        {key = "auto", name = "Auto", color = {0.5, 0.5, 0.8}}
    }

    local buttonWidth = 60
    local spacing = 5
    local totalWidth = (#themes * buttonWidth) + ((#themes - 1) * spacing)
    local startX = 260 - totalWidth

    for i, theme in ipairs(themes) do
        local themeButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        themeButton:SetSize(buttonWidth, 20)
        themeButton:SetPoint("TOPLEFT", startX + ((i - 1) * (buttonWidth + spacing)), yOffset)
        themeButton:SetText(theme.name)

        -- Store theme data on button for reference
        themeButton.themeKey = theme.key

        -- Create selection indicator using button text color
        local function UpdateButtonAppearance()
            if self.settings.theme == theme.key then
                -- Selected theme - use blue text
                themeButton:GetFontString():SetTextColor(0.3, 0.6, 1, 1)
                themeButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            else
                -- Normal theme - use default text
                themeButton:GetFontString():SetTextColor(1, 1, 1, 1)
                themeButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            end
        end

        -- Initial appearance
        UpdateButtonAppearance()

        themeButton:SetScript("OnClick", function()
            self.settings.theme = theme.key
            self:ApplyTheme(theme.key)

            -- Update all theme buttons in this group
            local parentFrame = themeButton:GetParent()
            for _, child in ipairs({parentFrame:GetChildren()}) do
                if child.themeKey then
                    if child.themeKey == theme.key then
                        child:GetFontString():SetTextColor(0.3, 0.6, 1, 1)
                        child:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                    else
                        child:GetFontString():SetTextColor(1, 1, 1, 1)
                        child:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                    end
                end
            end
        end)

        -- Hover effects
        themeButton:SetScript("OnEnter", function(self)
            if self.themeKey ~= Whispr.Settings.settings.theme then
                self:GetFontString():SetTextColor(0.8, 0.8, 1, 1)
            end
        end)

        themeButton:SetScript("OnLeave", function(self)
            if self.themeKey ~= Whispr.Settings.settings.theme then
                self:GetFontString():SetTextColor(1, 1, 1, 1)
            end
        end)
    end

    return yOffset - 35
end

-- Remove the RefreshThemeButtons function since it's no longer needed
-- The theme button updates are now handled inline

function Whispr.Settings:ToggleSettings()
    if self.expanded then
        self:CollapseSettings()
    else
        self:ExpandSettings()
    end
end

function Whispr.Settings:ExpandSettings()
    local frame = Whispr.Chat:GetFrame()
    if not frame then return end

    if not self.panel then
        self:CreateSettingsPanel()
    end

    self.expanded = true

    -- Animate the main frame expanding to accommodate the settings panel
    local startWidth = frame:GetWidth()
    local targetWidth = startWidth + 300

    frame:SetScript("OnUpdate", function(self, elapsed)
        local currentWidth = self:GetWidth()
        local speed = 1000 * elapsed -- pixels per second

        if currentWidth < targetWidth then
            local newWidth = math.min(targetWidth, currentWidth + speed)
            self:SetWidth(newWidth)

            -- Calculate animation progress (0 to 1)
            local animationProgress = (newWidth - startWidth) / 300

            -- Show settings panel when animation is about 85% complete
            if animationProgress >= 0.85 and not Whispr.Settings.panel:IsShown() then
                Whispr.Settings.panel:Show()
            end
        else
            -- Animation complete - ensure settings panel is visible
            Whispr.Settings.panel:Show()
            self:SetScript("OnUpdate", nil) -- Stop the animation
        end
    end)
end

function Whispr.Settings:CollapseSettings()
    local frame = Whispr.Chat:GetFrame()
    if not frame then return end

    self.expanded = false

    -- Hide settings panel immediately when starting collapse
    if self.panel then
        self.panel:Hide()
    end

    -- Animate the main frame collapsing back to original size
    local targetWidth = 800 -- Original frame width

    frame:SetScript("OnUpdate", function(self, elapsed)
        local currentWidth = self:GetWidth()
        local speed = 1000 * elapsed -- pixels per second

        if currentWidth > targetWidth then
            local newWidth = math.max(targetWidth, currentWidth - speed)
            self:SetWidth(newWidth)
        else
            -- Animation complete
            self:SetScript("OnUpdate", nil) -- Stop the animation
        end
    end)
end

function Whispr.Settings:ShowColorPicker(settingKey, textureToUpdate)
    local r, g, b = self.settings[settingKey].r, self.settings[settingKey].g, self.settings[settingKey].b

    local function OnColorChanged()
        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
        if newR and newG and newB then
            self.settings[settingKey].r = newR
            self.settings[settingKey].g = newG
            self.settings[settingKey].b = newB
            textureToUpdate:SetColorTexture(newR, newG, newB, 1)
            self:ApplySettings()
        end
    end

    local function OnCancel()
        self.settings[settingKey].r = r
        self.settings[settingKey].g = g
        self.settings[settingKey].b = b
        textureToUpdate:SetColorTexture(r, g, b, 1)
        self:ApplySettings()
    end

    local colorInfo = {
        r = r,
        g = g,
        b = b,
        opacity = 1.0,
        hasOpacity = false,
        swatchFunc = OnColorChanged,
        opacityFunc = OnColorChanged,
        cancelFunc = OnCancel,
    }

    -- Try the modern API first, fallback to legacy if needed
    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow(colorInfo)
    elseif ColorPickerFrame then
        -- Legacy API fallback
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.func = OnColorChanged
        ColorPickerFrame.cancelFunc = OnCancel
        ColorPickerFrame:Show()
    else
        print("Color picker not available")
    end
end

function Whispr.Settings:ApplySettings()
    local chatArea = Whispr.Chat:GetChatArea()
    if not chatArea then return end

    -- Apply border color
    if chatArea.border then
        chatArea.border:SetBackdropBorderColor(
            self.settings.borderColor.r,
            self.settings.borderColor.g,
            self.settings.borderColor.b,
            self.settings.borderColor.a
        )
    end

    -- Apply background color
    if chatArea.bg then
        chatArea.bg:SetColorTexture(
            self.settings.backgroundColor.r,
            self.settings.backgroundColor.g,
            self.settings.backgroundColor.b,
            self.settings.backgroundColor.a
        )
    end

    -- Apply font settings to Messages module
    if Whispr.Messages and Whispr.Messages.ApplyFontSettings then
        Whispr.Messages:ApplyFontSettings()
    end

    -- Apply theme changes
    self:ApplyTheme(self.settings.theme)
end

function Whispr.Settings:ApplyTheme(themeName)
    if themeName == "light" then
        -- Light theme adjustments
        self.settings.backgroundColor = {r = 0.95, g = 0.95, b = 0.98, a = 0.95}
        self.settings.borderColor = {r = 0.6, g = 0.6, b = 0.8, a = 0.8}
    elseif themeName == "dark" then
        -- Dark theme (default)
        self.settings.backgroundColor = {r = 0.08, g = 0.08, b = 0.12, a = 0.95}
        self.settings.borderColor = {r = 0.2, g = 0.4, b = 0.8, a = 0.6}
    elseif themeName == "auto" then
        -- Auto theme could detect system preferences or time of day
        local hour = tonumber(date("%H"))
        if hour >= 6 and hour < 18 then
            self:ApplyTheme("light")
        else
            self:ApplyTheme("dark")
        end
        return -- Don't apply twice
    end

    self:ApplySettings()
end

function Whispr.Settings:ResetSettings()
    self.settings = {
        borderColor = {r = 0.2, g = 0.4, b = 0.8, a = 0.6},
        fontSize = 12,
        fontFace = "GameFontNormal",
        backgroundColor = {r = 0.08, g = 0.08, b = 0.12, a = 0.95},
        yourMessageColor = {r = 0.7, g = 0.9, b = 1.0},
        showTimestamps = true,
        fadeMessages = false,
        enableNotifications = true,
        notificationSound = true,
        theme = "dark"
    }

    -- Recreate settings panel to reflect reset values
    if self.panel and self.panel:IsShown() then
        self:CollapseSettings()
        C_Timer.After(0.5, function()
            self:CreateSettingsPanel()
            self:ExpandSettings()
        end)
    end

    self:ApplySettings()
end

function Whispr.Settings:ExportSettings()
    -- Create a simple export dialog showing the settings as text
    local exportFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    exportFrame:SetSize(400, 300)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    exportFrame:SetBackdropColor(0.1, 0.1, 0.15, 0.95)
    exportFrame:SetFrameStrata("FULLSCREEN_DIALOG")

    local title = exportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Export Settings")

    local scrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(350)
    editBox:SetText(self:SerializeSettings())
    scrollFrame:SetScrollChild(editBox)

    local closeButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOM", 0, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        exportFrame:Hide()
    end)
end

function Whispr.Settings:SerializeSettings()
    local lines = {}
    table.insert(lines, "-- Whispr Chat Settings Export")
    table.insert(lines, "-- Copy this text to share your settings")
    table.insert(lines, "")

    for key, value in pairs(self.settings) do
        if type(value) == "table" then
            table.insert(lines, key .. " = {")
            for subKey, subValue in pairs(value) do
                table.insert(lines, "  " .. subKey .. " = " .. tostring(subValue) .. ",")
            end
            table.insert(lines, "}")
        else
            table.insert(lines, key .. " = " .. tostring(value))
        end
    end

    return table.concat(lines, "\n")
end

function Whispr.Settings:GetSettings()
    return self.settings
end

function Whispr.Settings:GetSetting(key)
    return self.settings[key]
end

function Whispr.Settings:SetSetting(key, value)
    self.settings[key] = value
    self:ApplySettings()
end

-- Register the module
Whispr:RegisterModule("Settings", Whispr.Settings)