Whispr.Contacts = {}

function Whispr.Contacts:OnInit()
    self.sectionStates = {
        conversations = true
    }

    Whispr:RegisterEvent("BN_FRIEND_INFO_CHANGED")
    Whispr:RegisterEvent("FRIENDLIST_UPDATE")
    Whispr:RegisterEvent("GUILD_ROSTER_UPDATE")
end

function Whispr.Contacts:OnEvent(event, ...)
    if event == "BN_FRIEND_INFO_CHANGED" or
       event == "FRIENDLIST_UPDATE" or
       event == "GUILD_ROSTER_UPDATE" then
        if Whispr.Chat:IsShown() then
            self:UpdateSidebar()
        end
    end
end

function Whispr.Contacts:GetRacePortrait(playerName)
    -- You can expand this to detect actual race if you have that data
    -- For now, we'll use a variety of portraits based on name hash
    local portraits = {
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Human",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Human", 
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-NightElf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-NightElf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Dwarf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Dwarf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Orc",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Orc",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Troll",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Troll",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Undead",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Undead"
    }
    
    -- Simple hash to assign consistent portraits
    local hash = 0
    for i = 1, string.len(playerName) do
        hash = hash + string.byte(playerName, i)
    end
    
    return portraits[(hash % #portraits) + 1]
end

function Whispr.Contacts:GetPlayerClassInfo(playerName)
    local shortName = playerName:match("^[^-]+") or playerName
    if WhisprDb.PlayerClasses and WhisprDb.playerClasses[playerName] then
        return WhisprDb.playerClasses[playerName], nil
    end
    if UnitExists(shortName) then
        local _, class = UnitClass(shortName)
        if class then
            if not WhisprDb.playerClasses then
                WhisprDb.playerClasses = {}
            end
            WhisprDb.playerClasses[playerName] = class
            return class, nil
        end
    end
    local numBNetFriends = BNGetNumFriends()
    for i = 1, numBNetFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local gameAccountInfo = accountInfo.gameAccountInfo
            if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                local characterName = gameAccountInfo.characterName
                if characterName then
                    local bnetShortName = characterName:match("^[^-]+") or characterName
                    if bnetShortName == shortName then
                        local class = gameAccountInfo.className
                        if class then
                            if not WhisprDb.playerClasses then
                                WhisprDb.playerClasses = {}
                            end
                            WhisprDb.playerClasses[playerName] = class
                            return class, nil
                        end
                    end
                end
            end
        end
    end
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, class = GetGuildRosterInfo(i)
            if name then
                local guildShortName = name:match("^[^-]+") or name
                if guildShortName == shortName then
                    if not WhisprDb.playerClasses then
                        WhisprDb.playerClasses = {}
                    end
                    WhisprDb.playerClasses[playerName] = class
                    return class, nil
                end
            end
        end
    end
    return nil, nil
end

function Whispr.Contacts:GetClassColor(className)
    if not className then
        return 1, 1, 1
    end
    local classColors = {
        ["WARRIOR"] = {0.78, 0.61, 0.43},
        ["PALADIN"] = {0.96, 0.55, 0.73},
        ["HUNTER"] = {0.67, 0.83, 0.45},
        ["ROGUE"] = {1.00, 0.96, 0.41},
        ["PRIEST"] = {1.00, 1.00, 1.00},
        ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
        ["SHAMAN"] = {0.00, 0.44, 0.87},
        ["MAGE"] = {0.25, 0.78, 0.92},
        ["WARLOCK"] = {0.53, 0.53, 0.93},
        ["MONK"] = {0.00, 1.00, 0.59},
        ["DRUID"] = {1.00, 0.49, 0.04},
        ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
        ["EVOKER"] = {0.20, 0.58, 0.50},
    }
    return unpack(classColors[className:upper()] or {1, 1, 1})
end


function Whispr.Contacts:GetPlayerOnlineStatus(playerName)
    local shortName = playerName:match("^[^-]+") or playerName    
    local numBNetFriends = BNGetNumFriends()
    for i = 1, numBNetFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local gameAccountInfo = accountInfo.gameAccountInfo
            if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
                local characterName = gameAccountInfo.characterName
                if characterName then
                    local bnetShortName = characterName:match("^[^-]+") or characterName
                    if bnetShortName == shortName then
                        if not gameAccountInfo.isOnline then
                            return "offline"
                        elseif accountInfo.isDND then
                            return "dnd"
                        elseif accountInfo.isAFK then
                            return "away"
                        else
                            return "online"
                        end
                    end
                end
            end
        end
    end
    
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name then
            local friendShortName = friendInfo.name:match("^[^-]+") or friendInfo.name
            if friendShortName == shortName then
                if friendInfo.connected then
                    if friendInfo.dnd then
                        return "dnd"
                    elseif friendInfo.afk then
                        return "away"
                    else
                        return "online"
                    end
                else
                    return "offline"
                end
            end
        end
    end
    
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
            if name then
                local guildShortName = name:match("^[^-]+") or name
                if guildShortName == shortName then
                    if online then
                        return "online"
                    else
                        return "offline"
                    end
                end
            end
        end
    end
    return nil
end

function Whispr.Contacts:CreateSectionHeader(parent, title, yOffset, sectionKey)
    local header = CreateFrame("Button", nil, parent)
    header:SetSize(180, 20)
    header:SetPoint("TOPLEFT", 0, yOffset)
    header:EnableMouse(true)
    header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    header.highlight = header:CreateTexture(nil, "HIGHLIGHT")
    header.highlight:SetAllPoints()
    header.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    header.highlight:SetBlendMode("ADD")
    header.leftFade = header:CreateTexture(nil, "HIGHLIGHT")
    header.leftFade:SetSize(20, 20)
    header.leftFade:SetPoint("LEFT")
    header.leftFade:SetColorTexture(0, 0, 0)
    header.leftFade:SetGradient("HORIZONTAL", 
        CreateColor(0, 0, 0, 1),
        CreateColor(0, 0, 0, 0)
    )
    header.leftFade:SetBlendMode("BLEND")
    header.rightFade = header:CreateTexture(nil, "HIGHLIGHT")
    header.rightFade:SetSize(20, 20)
    header.rightFade:SetPoint("RIGHT")
    header.rightFade:SetColorTexture(0, 0, 0)
    header.rightFade:SetGradient("HORIZONTAL",
        CreateColor(0, 0, 0, 0),
        CreateColor(0, 0, 0, 1)
    )
    header.rightFade:SetBlendMode("BLEND")
    header:SetHighlightTexture(header.highlight)
    header.arrow = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.arrow:SetPoint("LEFT", 6, 0)
    header.arrow:SetTextColor(0.8, 0.8, 0.8, 1) 
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.text:SetPoint("LEFT", header.arrow, "RIGHT", 4, 0)
    header.text:SetText(title)
    header.text:SetTextColor(1, 0.82, 0, 1) 
    local function UpdateArrow()
        if self.sectionStates[sectionKey] then
            header.arrow:SetText("-")
        else
            header.arrow:SetText("+")
        end
    end
    UpdateArrow()
    header:SetScript("OnClick", function(clickedSelf, button)
        if button == "LeftButton" then
            Whispr.Contacts.sectionStates[sectionKey] = not Whispr.Contacts.sectionStates[sectionKey]
            UpdateArrow()
            Whispr.Contacts:UpdateSidebar()
        elseif button == "RightButton" then
            if sectionKey:match("^group_") then
                local groupName = sectionKey:gsub("^group_", "")
                Whispr.Contacts:ShowGroupContextMenu(groupName)
            end
        end
    end)
    return header
end

function Whispr.Contacts:CreateContactEntry(parent, contactData, yOffset)
    local contact = CreateFrame("Button", nil, parent)
    contact:SetSize(180, 28)
    contact:SetPoint("TOPLEFT", 0, yOffset)
    contact.contactName = contactData.name
    contact:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    contact.selectedHighlight = contact:CreateTexture(nil, "BACKGROUND")
    contact.selectedHighlight:SetAllPoints()
    contact.selectedHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    contact.selectedHighlight:SetBlendMode("ADD")
    contact.selectedHighlight:SetAlpha(0.5)
    contact.selectedHighlight:Hide()
    contact.portrait = contact:CreateTexture(nil, "ARTWORK")
    contact.portrait:SetSize(16, 16)
    contact.portrait:SetPoint("LEFT", 4, 0)
    contact.portrait:SetTexture(self:GetRacePortrait(contactData.name))
    contact.portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    contact.statusIcon = contact:CreateTexture(nil, "OVERLAY")
    contact.statusIcon:SetSize(12, 12)
    contact.statusIcon:SetPoint("BOTTOMRIGHT", contact.portrait, "BOTTOMRIGHT", 5, -4)
    local status = self:GetPlayerOnlineStatus(contactData.name)
    if status == "online" then
        contact.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
    elseif status == "away" then
        contact.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Away")
    elseif status == "dnd" then
        contact.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-DnD")
    elseif status == "offline" then
        contact.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
    else
        contact.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
    end
    contact.nameText = contact:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    contact.nameText:SetPoint("LEFT", contact.portrait, "RIGHT", 6, 0)
    contact.nameText:SetPoint("RIGHT", -30, 0)
    contact.nameText:SetJustifyH("LEFT")
    contact.nameText:SetText(contactData.shortName or contactData.name)
    contact.nameText:SetTextColor(1, 1, 1, 1)
    if contactData.unreadCount and contactData.unreadCount > 0 then
        contact.unreadGlow = contact:CreateTexture(nil, "BACKGROUND")
        contact.unreadGlow:SetAllPoints()
        contact.unreadGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        contact.unreadGlow:SetVertexColor(0.7, 0.3, 0.9, 0.3)
        contact.unreadGlowLeftFade = contact:CreateTexture(nil, "BACKGROUND", nil, 1)
        contact.unreadGlowLeftFade:SetSize(30, 28)
        contact.unreadGlowLeftFade:SetPoint("LEFT", 0, 0)
        contact.unreadGlowLeftFade:SetTexture("Interface\\Buttons\\WHITE8x8")
        contact.unreadGlowLeftFade:SetGradient("HORIZONTAL",
            CreateColor(0.7, 0.3, 0.9, 0.3),
            CreateColor(0.7, 0.3, 0.9, 0)
        )
        contact.unreadGlowRightFade = contact:CreateTexture(nil, "BACKGROUND", nil, 1)
        contact.unreadGlowRightFade:SetSize(30, 28)
        contact.unreadGlowRightFade:SetPoint("RIGHT", 0, 0)
        contact.unreadGlowRightFade:SetTexture("Interface\\Buttons\\WHITE8x8")
        contact.unreadGlowRightFade:SetGradient("HORIZONTAL",
            CreateColor(0.7, 0.3, 0.9, 0),
            CreateColor(0.7, 0.3, 0.9, 0.3)
        )
        contact.unreadIndicator = contact:CreateTexture(nil, "OVERLAY")
        contact.unreadIndicator:SetSize(12, 12)
        contact.unreadIndicator:SetPoint("RIGHT", -13, 0)
        contact.unreadIndicator:SetTexture("Interface\\Minimap\\ObjectIcons")
        contact.unreadIndicator:SetTexCoord(0.125, 0.25, 0.125, 0.25)
        if contactData.unreadCount and contactData.unreadCount > 0 then
            -- contact.unreadBadge = contact:CreateTexture(nil, "OVERLAY")
            -- contact.unreadBadge:SetSize(12, 12)
            -- contact.unreadBadge:SetPoint("TOPLEFT", contact.portrait, "TOPLEFT", 4, 4)
            -- contact.unreadBadge:SetTexture("Interface\\Store\\minimap-delivery-highlight")
            -- contact.unreadBadge:SetVertexColor(1, 0.3, 0.9, 1)
            contact.unreadText = contact:CreateFontString(nil, "OVERLAY")
            contact.unreadText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            contact.unreadText:SetPoint("CENTER", contact.unreadBadge, "CENTER", -5, 0)
            contact.unreadText:SetText(tostring(contactData.unreadCount))
            contact.unreadText:SetTextColor(1, 1, 1, 1)
        end
        contact.pulseTime = 0
        contact:SetScript("OnUpdate", function(self, elapsed)
            self.pulseTime = self.pulseTime + elapsed
            local alpha = 0.15 + (math.sin(self.pulseTime * 3) * 0.15)
            self.unreadGlow:SetAlpha(alpha)
        end)
    else
        contact:SetScript("OnUpdate", nil)
    end
    contact:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    contact:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            Whispr.Messages:SetTarget(contactData.name)
            Whispr.Contacts:UpdateSidebar()
        elseif button == "RightButton" then
            Whispr.Contacts:ShowContextMenu(self, contactData)
        end
    end)
    contact:SetScript("OnEnter", function(self)
        if contactData.lastMessage and contactData.lastMessage ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(contactData.name, 1, 1, 1)
            GameTooltip:AddLine("Last: " .. contactData.lastMessage, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    contact:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    return contact
end

function Whispr.Contacts:UpdateSidebar()
    local contactList = Whispr.Chat:GetContactList()
    if not contactList then return end
    for _, child in ipairs({ contactList:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    local searchBox = Whispr.Chat:GetSearchBox()
    local query = ""
    if searchBox then
        query = string.lower(searchBox:GetText() or "")
        if query == "search..." then query = "" end
    end
    local offsetY = -8
    local currentTarget = Whispr.Messages and Whispr.Messages.target
    local conversations = Whispr.Messages:GetConversations()
    local hasConversations = false
    for _ in pairs(conversations) do
        hasConversations = true
        break
    end
    if not hasConversations then
        local emptyMessage = contactList:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        emptyMessage:SetPoint("TOPLEFT", 20, offsetY - 10)
        emptyMessage:SetText("No conversations yet") -- // This is retaining it must be removed
        emptyMessage:SetTextColor(0.5, 0.5, 0.5, 1)
        contactList:SetHeight(50)
        return
    end
    local groups = Whispr.History:GetAllGroups()
    local groupedContacts = {}
    local ungroupedContacts = {}
    for groupName in pairs(groups) do
        groupedContacts[groupName] = {}
    end
    for name, messages in pairs(conversations) do
        local shortName = name:match("^[^-]+") or name
        if query == "" or shortName:lower():find(query, 1, true) then
            local lastMessage = ""
            local timestamp = ""
            local messageDate = ""
            local unreadCount = 0
            if messages and #messages > 0 then
                local lastMsg = messages[#messages]
                lastMessage = lastMsg.text or ""
                timestamp = lastMsg.timestamp or ""
                messageDate = lastMsg.date or ""
                
                -- Count unread messages
                for _, msg in ipairs(messages) do
                    if msg.unread then
                        unreadCount = unreadCount + 1
                    end
                end
            end
            
            -- Truncate long messages
            if string.len(lastMessage) > 30 then
                lastMessage = string.sub(lastMessage, 1, 27) .. "..."
            end
            
            local contactData = {
                name = name,
                shortName = shortName,
                lastMessage = lastMessage,
                timestamp = timestamp,
                date = messageDate,
                unreadCount = unreadCount
            }
            local groupName = Whispr.History:GetContactGroup(name)
            if groupName and groupedContacts[groupName] then
                table.insert(groupedContacts[groupName], contactData)
            else
                table.insert(ungroupedContacts, contactData)
            end
        end
    end
    local function sortByTimestamp(a, b)
        if a.unreadCount > 0 and b.unreadCount > 0 then
            local aDateTime = (a.date or "") .. " " .. (a.timestamp or "")
            local bDateTime = (b.date or "") .. " " .. (b.timestamp or "")
            return aDateTime > bDateTime
        end
        if a.unreadCount > 0 and b.unreadCount == 0 then
            return true
        end
        if a.unreadCount == 0 and b.unreadCount > 0 then
            return false
        end
        local aDateTime = (a.date or "") .. " " .. (a.timestamp or "")
        local bDateTime = (b.date or "") .. " " .. (b.timestamp or "")
        if aDateTime == " " and bDateTime ~= " " then
            return false
        elseif aDateTime ~= " " and bDateTime == " " then
            return true
        end
        return aDateTime > bDateTime
    end
    local groupOrder = {}
    for groupName, groupData in pairs(groups) do
        if groupData.pinned then
            table.insert(groupOrder, groupName)
        end
    end
    for groupName, groupData in pairs(groups) do
        if not groupData.pinned then
            table.insert(groupOrder, groupName)
        end
    end
    for _, groupName in ipairs(groupOrder) do
        local groupData = groups[groupName]
        local contacts = groupedContacts[groupName]
        if #contacts > 0 then
            local hasUnread = false
            for _, contactData in ipairs(contacts) do
                if contactData.unreadCount > 0 then
                    hasUnread = true
                    break
                end
            end
            if hasUnread and self.sectionStates["group_" .. groupName] == false then
                self.sectionStates["group_" .. groupName] = true
            end
            if self.sectionStates["group_" .. groupName] == nil then
                self.sectionStates["group_" .. groupName] = true
            end
            local header = self:CreateSectionHeader(contactList, groupName .. " (" .. #contacts .. ")", offsetY, "group_" .. groupName)
            if groupData.color then
                header.text:SetTextColor(groupData.color[1], groupData.color[2], groupData.color[3], 1)
            end
            offsetY = offsetY - 24
            if self.sectionStates["group_" .. groupName] then
                table.sort(contacts, sortByTimestamp)
                for _, contactData in ipairs(contacts) do
                    local contact = self:CreateContactEntry(contactList, contactData, offsetY)
                    if contactData.name == currentTarget then
                        contact.selectedHighlight:Show()
                    end
                    offsetY = offsetY - 30
                end
            end
        end
    end
    if #ungroupedContacts > 0 then
        local header = self:CreateSectionHeader(contactList, "Recent Conversations", offsetY, "conversations")
        offsetY = offsetY - 24
        if self.sectionStates.conversations then
            table.sort(ungroupedContacts, sortByTimestamp)
            for _, contactData in ipairs(ungroupedContacts) do
                local contact = self:CreateContactEntry(contactList, contactData, offsetY)
                if contactData.name == currentTarget then
                    contact.selectedHighlight:Show()
                end
                offsetY = offsetY - 30
            end
        end
    end
    if query ~= "" and offsetY == -8 then
        local emptyMessage = contactList:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        emptyMessage:SetPoint("TOPLEFT", 20, offsetY - 10)
        emptyMessage:SetText("No matches found")
        emptyMessage:SetTextColor(0.5, 0.5, 0.5, 1)
        offsetY = offsetY - 25
    end    
    offsetY = offsetY - 10    
    contactList:SetHeight(math.abs(offsetY))
end

function Whispr.Contacts:ShowGroupContextMenu(groupName)
    if groupName == "Favorites" then
        return
    end
    if not _G["WhisprGroupContextMenuFrame"] then
        CreateFrame("Frame", "WhisprGroupContextMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    local menu = _G["WhisprGroupContextMenuFrame"]
    local function InitializeMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        if level == 1 then
            info.text = groupName
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            info = UIDropDownMenu_CreateInfo()
            info.text = "Delete Group"
            info.notCheckable = true
            info.func = function()
                StaticPopupDialogs["WHISPR_CONFIRM_DELETE_GROUP"] = {
                    text= "Delete group '" .. groupName .. "'? Contacts will be moved to Recent Conversations.",
                    button1 = "Delete",
                    button2 = "Cancel",
                    OnAccept = function()
                        if Whispr.History then
                            Whispr.History:DeleteGroup(groupName)
                        end
                        Whispr.Contacts:UpdateSidebar()
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("WHISPR_CONFIRM_DELETE_GROUP")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
            info = UIDropDownMenu_CreateInfo()
            info.text = "Rename Group"
            info.notCheckable = true
            info.func = function()
                StaticPopupDialogs["WHISPR_RENAME_GROUP"] = {
                    text = "Enter new name for '" .. groupName .. "':",
                    button1 = "Rename",
                    button2 = "Cancel",
                    hasEditBox = true,
                    OnShow = function(self)
                        self.EditBox:SetText(groupName)
                        self.EditBox:SetFocus()
                        self.EditBox:HighlightText()
                    end,
                    OnAccept = function(self)
                        local newName = self.EditBox:GetText()
                        if newName and newName ~= "" and newName ~= groupName then
                            if Whispr.History then
                                Whispr.History:RenameGroup(groupName, newName)
                            end
                            Whispr.Contacts:UpdateSidebar()
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("WHISPR_RENAME_GROUP")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
            info = UIDropDownMenu_CreateInfo()
            info.text = "Cancel"
            info.notCheckable = true
            info.func = function()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(menu, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
end


function Whispr.Contacts:ShowContextMenu(contact, contactData)
    if not _G["WhisprContextMenuFrame"] then
        CreateFrame("Frame", "WhisprContextMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    local menu = _G["WhisprContextMenuFrame"]
    local currentGroup = Whispr.History:GetContactGroup(contactData.name)
    local function InitializeMenu(self, level)
        local info = UIDropDownMenu_CreateInfo()
        if level == 1 then
            info.text = contactData.shortName or contactData.name
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)            
            info = UIDropDownMenu_CreateInfo()
            info.text = (currentGroup == "Favorites") and "Remove from Favorites" or "Add to Favorites"
            info.notCheckable = true
            info.func = function()
                Whispr.History:ToggleFavorite(contactData.name)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)            
            if currentGroup and currentGroup ~= "Favorites" then
                info = UIDropDownMenu_CreateInfo()
                info.text = "Remove from " .. currentGroup
                info.notCheckable = true
                info.func = function()
                    Whispr.History:RemoveContactFromGroup(contactData.name)
                    Whispr.Contacts:UpdateSidebar()
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(info, level)
            end            
            if not currentGroup or currentGroup == "Favorites" then
                info = UIDropDownMenu_CreateInfo()
                info.text = "Add to Group"
                info.hasArrow = true
                info.notCheckable = true
                info.value = "GROUPS"
                UIDropDownMenu_AddButton(info, level)
            else
                info = UIDropDownMenu_CreateInfo()
                info.text = "Move to Group"
                info.hasArrow = true
                info.notCheckable = true
                info.value = "GROUPS"
                UIDropDownMenu_AddButton(info, level)
            end
            info = UIDropDownMenu_CreateInfo()
            info.text = "Clear Chat History"
            info.notCheckable = true
            info.func = function()
                StaticPopupDialogs["WHISPR_CONFIRM_CLEAR"] = {
                    text = "Clear chat history with " .. (contactData.shortName or contactData.name) .. "?",
                    button1 = "Clear",
                    button2 = "Cancel",
                    OnAccept = function()
                        if Whispr.History then
                            Whispr.History:ClearConversation(contactData.name)
                        end
                        if Whispr.Messages.target == contactData.name then
                            Whispr.Messages.target = nil
                            local chatArea = Whispr.Chat:GetChatArea()
                            if chatArea then
                                chatArea.titleText:SetText("No conversation selected")
                                chatArea.scroll:Clear()
                            end
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("WHISPR_CONFIRM_CLEAR")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
            info = UIDropDownMenu_CreateInfo()
            info.text = "Cancel"
            info.notCheckable = true
            info.func = function()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        elseif level == 2 and UIDROPDOWNMENU_MENU_VALUE == "GROUPS" then
            local groups = Whispr.History:GetAllGroups()
            for groupName, groupData in pairs(groups) do
                if groupName ~= "Favorites" and groupName ~= currentGroup then -- Don't show current group or Favorites
                    info = UIDropDownMenu_CreateInfo()
                    info.text = groupName
                    info.notCheckable = true
                    info.func = function()
                        Whispr.History:AddContactToGroup(contactData.name, groupName)
                        Whispr.Contacts:UpdateSidebar()
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
            info = UIDropDownMenu_CreateInfo()
            info.text = "Create New Group..."
            info.notCheckable = true
            info.func = function()
                Whispr.Contacts:ShowCreateGroupDialog(contactData.name)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(menu, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
end

function Whispr.Contacts:ShowCreateGroupDialog(playerName)
    StaticPopupDialogs["WHISPR_CREATE_GROUP"] = {
        text = "Enter group name:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local groupName = self.EditBox:GetText()
            if groupName and groupName ~= "" then
                Whispr.History:CreateGroup(groupName)
                if playerName then
                    Whispr.History:AddContactToGroup(playerName, groupName)
                end
                Whispr.Contacts:UpdateSidebar()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("WHISPR_CREATE_GROUP")
end

function Whispr.Contacts:SetSelectedContact(contactName)
    self:UpdateSidebar()
end

Whispr:RegisterModule("Contacts", Whispr.Contacts)