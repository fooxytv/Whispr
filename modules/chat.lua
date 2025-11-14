Whispr.Chat = {}

local frame, chatArea, inputBox

function Whispr.Chat:OnInit()
    -- Initialize when addon loads
end

function Whispr.Chat:GetPlayerSuggestions(partial)
    local suggestions = {}
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name then
            local name = friendInfo.name:match("^[^-]+") or friendInfo.name
            if string.lower(name):find(string.lower(partial), 1, true) then
                table.insert(suggestions, {
                    name = name,
                    fullName = friendInfo.name,
                    online = friendInfo.connected,
                    type = "friend"
                })
            end
        end
    end
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
            if name then
                local shortName = name:match("^[^-]+") or name
                if string.lower(shortName):find(string.lower(partial), 1, true) then
                    table.insert(suggestions, {
                        name = shortName,
                        fullName = name,
                        online = online,
                        type = "guild"
                    })
                end
            end
        end
    end
    if Whispr.Messages and Whispr.Messages.conversations then
        for playerName in pairs(Whispr.Messages.conversations) do
            local shortName = playerName:match("^[^-]+") or playerName
            if string.lower(shortName):find(string.lower(partial), 1, true) then
                table.insert(suggestions, {
                    name = shortName,
                    fullName = playerName,
                    online = nil,
                    type = "recent"
                })
            end
        end
    end
    local seen = {}
    local unique = {}
    for _, suggestion in ipairs(suggestions) do
        if not seen[suggestion.name] and #unique < 8 then
            seen[suggestion.name] = true
            table.insert(unique, suggestion)
        end
    end
    
    return unique
end

function Whispr.Chat:CreateDropdown(parent, nameBox)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(300, 0)
    dropdown:SetPoint("TOP", nameBox, "BOTTOM", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetFrameLevel(parent:GetFrameLevel() + 10)
    dropdown:Hide()
    dropdown.entries = {}
    function dropdown:UpdateSuggestions(suggestions)
        -- Clear existing entries
        for _, entry in ipairs(self.entries) do
            entry:Hide()
        end
        if #suggestions == 0 then
            self:Hide()
            return
        end
        for i, suggestion in ipairs(suggestions) do
            local entry = self.entries[i]
            if not entry then
                entry = CreateFrame("Button", nil, self)
                entry:SetSize(296, 24)
                entry:SetPoint("TOPLEFT", 2, -2 - (i-1) * 24)
                entry.bg = entry:CreateTexture(nil, "BACKGROUND")
                entry.bg:SetAllPoints()
                entry.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                entry.bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
                entry.highlight = entry:CreateTexture(nil, "HIGHLIGHT")
                entry.highlight:SetAllPoints()
                entry.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                entry.highlight:SetVertexColor(0.3, 0.5, 0.8, 0.6)
                entry.nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entry.nameText:SetPoint("LEFT", 8, 0)
                entry.statusIcon = entry:CreateTexture(nil, "OVERLAY")
                entry.statusIcon:SetSize(12, 12)
                entry.statusIcon:SetPoint("RIGHT", -8, 0)
                entry.typeText = entry:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                entry.typeText:SetPoint("RIGHT", entry.statusIcon, "LEFT", -4, 0)
                self.entries[i] = entry
            end
            entry.suggestion = suggestion
            entry.nameText:SetText(suggestion.name)
            if suggestion.type == "friend" then
                entry.typeText:SetText("Friend")
                entry.typeText:SetTextColor(0.5, 1, 0.5)
            elseif suggestion.type == "guild" then
                entry.typeText:SetText("Guild")
                entry.typeText:SetTextColor(1, 0.8, 0.5)
            else
                entry.typeText:SetText("Recent")
                entry.typeText:SetTextColor(0.7, 0.7, 0.7)
            end
            if suggestion.online == true then
                entry.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
            elseif suggestion.online == false then
                entry.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
            else
                entry.statusIcon:SetTexture(nil)
            end
            entry:SetScript("OnClick", function()
                nameBox:SetText(suggestion.name)
                nameBox:SetCursorPosition(string.len(suggestion.name))
                self:Hide()
                nameBox:SetFocus()
            end)
            entry:Show()
        end
        local height = #suggestions * 24 + 4
        self:SetHeight(height)
        self:Show()
    end
    return dropdown
end

function Whispr.Chat:CreateNewConversationPrompt()
    if Whispr.Chat.newConversationFrame then
        Whispr.Chat.newConversationFrame:Show()
        Whispr.Chat.newConversationFrame.nameBox:SetFocus()
        return
    end
    local parent = Whispr.Chat.frame or UIParent
    local prompt = CreateFrame("Frame", "WhisprNewConversationPrompt", parent, "BackdropTemplate")
    prompt:SetSize(280, 120)
    prompt:SetPoint("CENTER", parent, "CENTER")
    prompt:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    prompt:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    prompt:SetFrameStrata("FULLSCREEN_DIALOG")
    prompt:SetMovable(true)
    prompt:EnableMouse(true)
    prompt:RegisterForDrag("LeftButton")
    prompt:SetScript("OnDragStart", prompt.StartMoving)
    prompt:SetScript("OnDragStop", prompt.StopMovingOrSizing)
    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("New Conversation")
    local nameBox = CreateFrame("EditBox", nil, prompt, "InputBoxTemplate")
    nameBox:SetSize(200, 30)
    nameBox:SetPoint("TOP", title, "BOTTOM", 0, -10)
    nameBox:SetAutoFocus(true)
    nameBox:SetMaxLetters(50)
    nameBox:SetText("")
    nameBox:SetFocus()
    prompt.nameBox = nameBox
    local startButton = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    startButton:SetSize(80, 24)
    startButton:SetPoint("BOTTOMLEFT", 20, 15)
    startButton:SetText("Start")
    local cancelButton = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 24)
    cancelButton:SetPoint("BOTTOMRIGHT", -20, 15)
    cancelButton:SetText("Cancel")
    startButton:SetScript("OnClick", function()
        local targetName = nameBox:GetText():gsub("%s+", "")
        if targetName ~= "" then
            Whispr.Messages:AddConversation(targetName)
            Whispr.Messages:SetTarget(targetName)
            Whispr.Messages:LoadConversation(targetName)
            Whispr.Chat:HighlightSelectedContact(targetName)
            prompt:Hide()
        else
            UIErrorsFrame:AddMessage("Please enter a player name.", 1, 0.2, 0.2)
        end
    end)
    cancelButton:SetScript("OnClick", function()
        prompt:Hide()
    end)
    nameBox:SetScript("OnEnterPressed", function()
        startButton:Click()
    end)
    Whispr.Chat.newConversationFrame = prompt
end

function Whispr.Chat:CreateHeader(frame, sidebarFrame)
    local headerBar = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    headerBar:SetHeight(36)
    headerBar:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 2, 0)
    headerBar:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    headerBar.noConvoText = headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerBar.noConvoText:SetPoint("CENTER", headerBar, "CENTER", 0, 0)
    headerBar.noConvoText:SetText("No conversation selected")
    headerBar.noConvoText:SetTextColor(0.5, 0.5, 0.5, 1)
    return headerBar
end

function Whispr.Chat:Create()
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
    table.insert(UISpecialFrames, "WhisprChatWindow")
    Whispr:AddAutoTransparency(frame, {
        normalAlpha = 1.0,
        unfocusedAlpha = 0.4,
        fadeSpeed = 5,
        checkMovement = true
    })
    local sidebarFrame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    sidebarFrame:SetPoint("TOPLEFT", 4, -28)
    sidebarFrame:SetPoint("BOTTOMLEFT", 4, 4)
    sidebarFrame:SetWidth(200)
    frame.headerBar = self:CreateHeader(frame, sidebarFrame)
    local newConversationButton = CreateFrame("Button", nil, sidebarFrame, "BackdropTemplate")
    newConversationButton:SetSize(30, 30)
    newConversationButton:SetPoint("TOPLEFT", 148, -8)
    local plusTexture = "Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon"
    local bg = newConversationButton:CreateTexture(nil, "ARTWORK")
    bg:SetAllPoints()
    bg:SetTexture(plusTexture)
    newConversationButton:SetScript("OnClick", function()
        Whispr.Chat:CreateNewConversationPrompt()
    end)
    newConversationButton:SetScript("OnEnter", function(self)
        if bg then
            bg:SetVertexColor(1.3, 1.3, 1.3, 1)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Start New Conversation", 1, 1, 1)
        GameTooltip:AddLine("Click to open chat with a new player", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    newConversationButton:SetScript("OnLeave", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1)
        end
        GameTooltip:Hide()
    end)
    newConversationButton:SetScript("OnMouseDown", function(self)
        if bg then
            bg:SetVertexColor(0.7, 0.7, 0.7, 1)
        end
    end)
    newConversationButton:SetScript("OnMouseUp", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1)
        end
    end)
    local searchBox = CreateFrame("EditBox", nil, sidebarFrame, "InputBoxTemplate")
    searchBox:SetSize(160, 20)
    searchBox:SetPoint("TOPLEFT", 15, -40)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetText("Search...")
    searchBox:SetTextColor(0.5, 0.5, 0.5)
    Whispr.Chat.searchBox = searchBox
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
    Whispr.Chat.contactList = contactList
    chatArea = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    chatArea:SetPoint("TOPLEFT", frame.headerBar, "BOTTOMLEFT", 0, -2)
    chatArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    -- chatArea:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 2, 0)
    -- chatArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)
    -- chatArea.titleBar = CreateFrame("Frame", nil, chatArea)
    -- chatArea.titleBar:SetPoint("TOPLEFT", 0, 0)
    -- chatArea.titleBar:SetPoint("TOPRIGHT", 0, 0)
    -- chatArea.titleBar:SetHeight(24)
    -- chatArea.titleText = chatArea.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- chatArea.titleText:SetPoint("LEFT", 10, 0)
    -- chatArea.titleText:SetText("No conversation selected")
    chatArea.scroll = CreateFrame("ScrollingMessageFrame", nil, chatArea)
    chatArea.scroll.fontSize = Whispr.Chat.savedFontSize or 13
    chatArea.scroll.minFontSize = 8
    chatArea.scroll.maxFontSize = 24
    chatArea.scroll:SetPoint("TOPLEFT", 10, -10)
    chatArea.scroll:SetPoint("BOTTOMRIGHT", -30, 20)
    chatArea.scroll:SetFont("Fonts\\FRIZQT__.TTF", chatArea.scroll.fontSize, "")
    chatArea.scroll:SetShadowColor(0, 0, 0, 0.8)
    chatArea.scroll:SetShadowOffset(1, -1)
    chatArea.scroll:SetFading(false)
    chatArea.scroll:SetMaxLines(500)
    chatArea.scroll:SetJustifyH("LEFT")
    chatArea.scroll:SetIndentedWordWrap(true)
    chatArea.scroll:SetHyperlinksEnabled(true)
    chatArea.scroll:SetSpacing(6)
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
    chatArea.scroll:SetScript("OnMouseWheel", function(self, delta)
        if IsControlKeyDown() then
            if delta > 0 then
                self.fontSize = math.min(self.fontSize + 1, self.maxFontSize)
            else
                self.fontSize = math.max(self.fontSize - 1, self.minFontSize)
            end
            self:SetFont("Fonts\\FRIZQT__.TTF", self.fontSize, "")
            if Whispr.History then
                Whispr.History:SaveFontSize(self.fontSize)
            end
        else
            if delta > 0 then
                self:ScrollUp()
            elseif delta < 0 then
                self:ScrollDown()
            end
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
        if Whispr.Messages.target and text ~= "" then
            if Whispr.Queue and not Whispr.Queue:IsPlayerOnline(Whispr.Messages.target) then
                StaticPopupDialogs["WHISPR_QUEUE_OFFLINE"] = {
                    text = Whispr.Messages.target:match("^[^-]+") .. " is offline. Queue this message to send when they come online?",
                    button1 = "Queue",
                    button2 = "Cancel",
                    OnAccept = function()
                        Whispr.Queue:QueueMessage(Whispr.Messages.target, text)
                        if not Whispr.Messages.conversations[Whispr.Messages.target] then
                            Whispr.Messages.conversations[Whispr.Messages.target] = {}
                        end

                        table.insert(Whispr.Messages.conversations[Whispr.Messages.target], {
                            sender = UnitName("player"),
                            text = text .. "",
                            fromPlayer = true,
                            timestamp = date("%H:%M"),
                            isQueued = true
                        })

                        Whispr.Messages:SaveMessage()
                        Whispr.Messages:LoadConversation(Whispr.Messages.target)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("WHISPR_QUEUE_OFFLINE")
            else
                SendChatMessage(text, "WHISPER", nil, Whispr.Messages.target)
            end
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
        Whispr.Contacts:UpdateSidebar()
    end)
    local function SetupTabBinding()
        if not Whispr.Chat.tabBindingSet then
            CreateFrame("Button", "WhisprTabBind", frame):SetScript("OnClick", function()
                if frame:IsShown() and inputBox then
                    inputBox:SetFocus()
                end
            end)
            
            SetBindingClick("TAB", "WhisprTabBind")
            Whispr.Chat.tabBindingSet = true
        end
    end
    frame:SetScript("OnShow", function()
        SetupTabBinding()
    end)
    frame:SetScript("OnHide", function()
        if Whispr.Messages then
            Whispr.Messages.target = nil
        end
        if Whispr.Chat.tabBindingSet then
            SetBinding("TAB")
            Whispr.Chat.tabBindingSet = false
        end
    end)
    local function OnUpdate(self, elapsed)
        if self.UpdateTransparency then
            self:UpdateTransparency(elapsed)
        end
        if self:IsShown() and IsKeyDown("TAB") then
            if not self.tabPressed then
                self.tabPressed = true
                if inputBox then
                    inputBox:SetFocus()
                end
                C_Timer.After(0.1, function()
                    if frame then
                        frame.tabPressed = false
                    end
                end)
            end
        end
    end
    frame:SetScript("OnUpdate", OnUpdate)
    Whispr.Contacts:UpdateSidebar()
end

function Whispr.Chat:HighlightSelectedContact(contactName)
    if not self.contactList then return end
    for i = 1, self.contactList:GetNumChildren() do
        local child = select(i, self.contactList:GetChildren())
        if child and child.contactName then
            if child.selectedBg then
                child.selectedBg:Hide()
            end
            if child.nameText then
                child.nameText:SetTextColor(1, 1, 1)
            end
        end
    end
    for i = 1, self.contactList:GetNumChildren() do
        local child = select(i, self.contactList:GetChildren())
        if child and child.contactName == contactName then
            if not child.selectedBg then
                child.selectedBg = child:CreateTexture(nil, "BACKGROUND")
                child.selectedBg:SetAllPoints()
                child.selectedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
                child.selectedBg:SetVertexColor(0.2, 0.4, 0.8, 0.6)
            end
            child.selectedBg:Show()
            if child.nameText then
                child.nameText:SetTextColor(1, 1, 0.8)
            end
            break
        end
    end
end

function Whispr.Chat:GetFrame()
    return frame
end

function Whispr.Chat:GetChatArea()
    return chatArea
end

function Whispr.Chat:GetInputBox()
    return inputBox
end

function Whispr.Chat:GetContactList()
    return self.contactList
end

function Whispr.Chat:GetSearchBox()
    return self.searchBox
end

function Whispr.Chat:Show()
    if frame then
        frame:Show()
    end
end

function Whispr.Chat:Hide()
    if frame then
        frame:Hide()
    end
end

function Whispr.Chat:IsShown()
    return frame and frame:IsShown()
end

-- Register the module
Whispr:RegisterModule("Chat", Whispr.Chat)