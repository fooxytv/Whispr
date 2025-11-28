local Whispers = {}

local frame, chatArea, inputBox
Whispers.conversations = {}
Whispers.target = nil

function Whispers:OnInit()
    Whispr:RegisterEvent("CHAT_MSG_WHISPER")
end

function Whispers:LoadConversation(playerName)
    if not chatArea or not chatArea.scroll then return end
    chatArea.scroll:Clear()
    local messages = self.conversations[playerName] or {}
    for _, msg in ipairs(messages) do
        local sender = msg.fromPlayer and "|cff00ccffYou|r" or ("|cffffcc00" .. msg.sender .. "|r")
        local timestamp = msg.timestamp or "--:--"
        local line = string.format("[%s] %s: %s", timestamp, sender, msg.text)
        chatArea.scroll:AddMessage(line)
    end
    chatArea.scroll:ScrollToBottom()
end

function Whispers:OnEvent(event, msg, sender)
    if not self.conversations[sender] then
        self.conversations[sender] = {}
    end
    table.insert(self.conversations[sender], {
        sender = sender,
        text = msg,
        fromPlayer = false,
        timestamp = date("%H:%M")
    })
    if not frame then self:Create() end
    self:UpdateSidebar()

    if not frame:IsShown() or (frame:IsShown() and self.target ~= sender) then
        Whispr.modules.Notifications:ShowNotification(sender, msg)
    end

    if frame:IsShown() and self.target == sender then
        Whispers:LoadConversation(sender)
    end
end

function Whispers:SetTarget(playerName)
    self.target = playerName
    if not frame then self:Create() end
    if chatArea and chatArea.titleText then
        chatArea.titleText:SetText(("Talking to: |cff00ccff%s|r"):format(playerName))
    end
    Whispers:LoadConversation(playerName)
    frame:Show()
end

function Whispers:Create()
            function Whispers:CreateNewConversationPrompt()
        if Whispers.newConversationFrame then
            Whispers.newConversationFrame:Show()
            return
        end
        local prompt = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        prompt:SetSize(300, 100)
        prompt:SetPoint("CENTER", frame, "CENTER")
        prompt:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
        prompt:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        prompt:SetFrameStrata("DIALOG")
        local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Start New Conversation")
        local nameBox = CreateFrame("EditBox", nil, prompt, "InputBoxTemplate")
        nameBox:SetSize(200, 20)
        nameBox:SetPoint("TOP", title, "BOTTOM", 0, -10)
        nameBox:SetAutoFocus(true)
        nameBox:SetMaxLetters(50)
        local confirm = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
        confirm:SetSize(80, 22)
        confirm:SetPoint("BOTTOMRIGHT", -10, 10)
        confirm:SetText("Start")
        local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
        cancel:SetSize(80, 22)
        cancel:SetPoint("BOTTOMLEFT", 10, 10)
        cancel:SetText("Cancel")
        confirm:SetScript("OnClick", function()
            local name = nameBox:GetText()
            if name and name ~= "" then
                if not Whispers.conversations[name] then
                    Whispers.conversations[name] = {}
                end
                Whispers:SetTarget(name)
                Whispers:UpdateSidebar()
            end
            prompt:Hide()
        end)
        cancel:SetScript("OnClick", function()
            prompt:Hide()
        end)
        Whispers.newConversationFrame = prompt
    end
    frame = CreateFrame("Frame", "WhisprChatWindow", UIParent, "PortraitFrameTemplate")
    frame:SetSize(800, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetTitle("Whispr Chat")
    local sidebarFrame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    sidebarFrame:SetPoint("TOPLEFT", 4, -28)
    sidebarFrame:SetPoint("BOTTOMLEFT", 4, 4)
    sidebarFrame:SetWidth(200)
    local newButton = CreateFrame("Button", nil, sidebarFrame, "UIPanelButtonTemplate")
    newButton:SetSize(160, 20)
    newButton:SetPoint("TOPLEFT", 15, -10)
    newButton:SetText("New Conversation")
    newButton:SetScript("OnClick", function()
        Whispers:CreateNewConversationPrompt()
    end)
    local searchBox = CreateFrame("EditBox", nil, sidebarFrame, "InputBoxTemplate")
    searchBox:SetSize(160, 20)
    searchBox:SetPoint("TOPLEFT", 15, -40)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetText("Search...")
    searchBox:SetTextColor(0.5, 0.5, 0.5)
    Whispers.searchBox = searchBox
    local contactScroll = CreateFrame("ScrollFrame", nil, sidebarFrame)
    contactScroll:SetPoint("TOPLEFT", 4, -90)
    contactScroll:SetPoint("BOTTOMRIGHT", -28, 4)
    contactScroll.scrollBarTemplate = "MinimalScrollBar"
    contactScroll.scrollBarX = 12
    contactScroll.scrollBarTopY = 0
    contactScroll.scrollBarBottomY = 0
    ScrollFrame_OnLoad(contactScroll)
    local contactList = CreateFrame("Frame", nil, contactScroll)
    contactList:SetSize(1, 1)
    contactScroll:SetScrollChild(contactList)
    Whispers.contactList = contactList
    chatArea = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    chatArea:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 2, 0)
    chatArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    chatArea.titleBar = CreateFrame("Frame", nil, chatArea)
    chatArea.titleBar:SetPoint("TOPLEFT", 0, 0)
    chatArea.titleBar:SetPoint("TOPRIGHT", 0, 0)
    chatArea.titleBar:SetHeight(24)
    chatArea.titleText = chatArea.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatArea.titleText:SetPoint("LEFT", 10, 0)
    chatArea.titleText:SetText("No conversation selected")
    chatArea.scroll = CreateFrame("ScrollingMessageFrame", nil, chatArea)
    chatArea.scroll:SetPoint("TOPLEFT", 10, -30)
    chatArea.scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    chatArea.scroll:SetFontObject(GameFontHighlightSmall)
    chatArea.scroll:SetFading(false)
    chatArea.scroll:SetMaxLines(500)
    chatArea.scroll:SetJustifyH("LEFT")
    chatArea.scroll:SetIndentedWordWrap(true)
    chatArea.scroll:SetHyperlinksEnabled(true)
    chatArea.scroll:SetScript("OnHyperlinkEnter", function(_, link)
        GameTooltip:SetOwner(chatArea.scroll, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    chatArea.scroll:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
    chatArea.scroll:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
    chatArea.scroll.scrollBarTemplate = "MinimalScrollBar"
    chatArea.scroll.scrollBarX = 12
    chatArea.scroll.scrollBarTopY = 0
    chatArea.scroll.scrollBarBottomY = 0
    chatArea.scroll:EnableMouseWheel(true)
    chatArea.scroll:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        elseif delta < 0 then
            self:ScrollDown()
        end
    end)
    inputBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    inputBox:SetAutoFocus(false)
    inputBox:SetSize(460, 24)
    inputBox:SetMaxLetters(255)
    inputBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 220, 10)
    local charCount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charCount:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
    charCount:SetText("0/255")
    inputBox:SetScript("OnTextChanged", function(self)
        local len = self:GetNumLetters()
        charCount:SetText(len .. "/255")
    end)
    inputBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if Whispers.target and text ~= "" then
            C_ChatInfo.SendChatMessage(text, "WHISPER", nil, Whispers.target)
            table.insert(Whispers.conversations[Whispers.target], {
                sender = UnitName("player"),
                text = text,
                fromPlayer = true,
                timestamp = date("%H:%M")
            })
            Whispers:LoadConversation(Whispers.target)
        end
        self:SetText("")
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end)
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Search...")
            self:SetTextColor(0.5, 0.5, 0.5)
        end
    end)

    searchBox:SetScript("OnTextChanged", function()
        Whispers:UpdateSidebar()
    end)
    self:UpdateSidebar()
end

function Whispers:UpdateSidebar()
    if not Whispers.contactList then return end
    for _, child in ipairs({ Whispers.contactList:GetChildren() }) do
        if child ~= Whispers.contactList.searchBox and child ~= Whispers.contactList.newButton then
            child:Hide()
            child:SetParent(nil)
        end
    end
    if not Whispers.contactList.searchBox then
        Whispers.contactList.searchBox = CreateFrame("EditBox", nil, Whispers.contactList, "InputBoxTemplate")
        Whispers.contactList.searchBox:SetSize(160, 20)
        Whispers.contactList.searchBox:ClearAllPoints()
        Whispers.contactList.searchBox:SetAutoFocus(false)
        Whispers.contactList.searchBox:SetFontObject("GameFontHighlightSmall")
        Whispers.contactList.searchBox:SetTextInsets(6, 6, 0, 0)
        Whispers.contactList.searchBox:SetText("Search...")
        Whispers.contactList.searchBox:SetTextColor(0.5, 0.5, 0.5)
        Whispers.contactList.searchBox:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == "Search..." then
                self:SetText("")
                self:SetTextColor(1, 1, 1)
            end
        end)
        Whispers.contactList.searchBox:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                self:SetText("Search...")
                self:SetTextColor(0.5, 0.5, 0.5)
            end
        end)
        Whispers.contactList.searchBox:SetScript("OnTextChanged", function()
            Whispers:UpdateSidebar()
        end)
    end
    local query = string.lower(Whispers.contactList.searchBox:GetText() or "")
    if query == "search..." then query = "" end
    local offsetY = -10
    local category = "Conversations"
    local expanded = true
    local toggles = {}
    toggles[category] = {}
    local header = CreateFrame("Button", nil, Whispers.contactList)
    header:SetSize(180, 20)
    header:SetPoint("TOPLEFT", 10, offsetY)
    header:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
    header:GetHighlightTexture():SetBlendMode("ADD")
    header.icon = header:CreateTexture(nil, "OVERLAY")
    header.icon:SetSize(14, 14)
    header.icon:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    header.icon:SetPoint("LEFT", 4, 0)
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("LEFT", header.icon, "RIGHT", 4, 0)
    header.text:SetText(category)
    local function UpdateIconState()
        if expanded then
            header.icon:SetRotation(-math.pi / 2) -- ►
        else
            header.icon:SetRotation(0) -- ▼
        end
    end
    UpdateIconState()
    header:SetScript("OnClick", function()
        expanded = not expanded
        UpdateIconState()
        for _, entry in ipairs(toggles[category]) do
            if expanded then entry:Show() else entry:Hide() end
        end
    end)
    offsetY = offsetY - 28
    local sorted = {}
    for name, messages in pairs(self.conversations) do
        local time = ""
        if messages[#messages] then
            time = messages[#messages].timestamp or ""
    end
    table.insert(sorted, { name = name, time = time })
    end
    table.sort(sorted, function(a, b) return a.time > b.time end)
    for _, convo in ipairs(sorted) do
        local name = convo.name
        local shortName = name:match("^[^-]+")
        local lastMessage = ""
        local messages = self.conversations[name] or {}
        if messages and #messages > 0 then
            lastMessage = messages[#messages].text or ""
        end

        if query == "" or shortName:lower():find(query, 1, true) then
            local contact = CreateFrame("Button", nil, Whispers.contactList)
            contact:SetSize(180, 48)
            contact:SetPoint("TOPLEFT", 10, offsetY)
            local highlight = contact:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetColorTexture(0.25, 0.45, 1, 0.1)
            highlight:SetAllPoints(contact)
            contact:SetHighlightTexture(highlight)
            local portrait = contact:CreateTexture(nil, "ARTWORK")
            portrait:SetTexture("Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-NightElf")
            portrait:SetSize(32, 32)
            portrait:SetPoint("TOPLEFT", 6, -8)
            portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            local nameLabel = contact:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 6, -2)
            nameLabel:SetText(shortName)
            local snippetLabel = contact:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            snippetLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
            snippetLabel:SetWidth(120)
            snippetLabel:SetJustifyH("LEFT")
            snippetLabel:SetText(lastMessage:sub(1, 30))
            contact:SetScript("OnClick", function()
                Whispers:SetTarget(name)
            end)
            table.insert(toggles[category], contact)
            if not expanded then contact:Hide() end
            offsetY = offsetY - 54
        end
    end
    Whispers.contactList:SetHeight(-offsetY + 10)
end

Whispr:RegisterModule("Whispers", Whispers)
