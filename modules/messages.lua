Whispr.Messages = {}

Whispr.Messages.conversations = {}
Whispr.Messages.target = nil

function Whispr.Messages:OnInit()
    if not Whispr.eventFrame then
        Whispr.eventFrame = CreateFrame("Frame")
    end

    Whispr.eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    Whispr.eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    Whispr.eventFrame:SetScript("OnEvent", function(_, event, ...)
        self:OnEvent(event, ...)
    end)
end

local function GetFullName(name)
    if name:find("-") then
        return name
    else
        local _, realm = UnitFullName("player")
        return name .. "-" .. (realm or GetRealmName())
    end
end

function Whispr.Messages:GetConversations()
    return self.conversations
end

function Whispr.Messages:AddConversation(playerName)
    if not playerName or playerName == "" then
        return
    end
    playerName = GetFullName(playerName)

    if not self.conversations[playerName] then
        self.conversations[playerName] = {}
    end
    Whispr.Contacts:UpdateSidebar()
end

function Whispr.Messages:LoadConversation(playerName)
    local chatArea = Whispr.Chat:GetChatArea()
    if not chatArea or not chatArea.scroll then return end
    chatArea.scroll:Clear()
    local messages = self.conversations[playerName] or {}
    local class = Whispr.Contacts:GetPlayerClassInfo(playerName)
    local r, g, b = Whispr.Contacts:GetClassColor(class)
    local classColorHex = string.format("%02x%02x%02x", r*255, g*255, b*255)
    for _, msg in ipairs(messages) do
        if msg.date and msg.date ~= lastDate then
            chatArea.scroll:AddMessage(" ")
            chatArea.scroll:AddMessage("|cff666666" .. date("%B %d, %Y", time{year=msg.date:sub(1,4), month=msg.date:sub(6,7), day=msg.date:sub(9,10)}) .. "|r", 0.6, 0.6, 0.6)
            chatArea.scroll:AddMessage(" ")
            lastDate = msg.date
        end
        local timestamp = msg.timestamp or "--:--"
        local text = msg.text or ""
        local line
        if msg.isSystem then
            line = string.format("|cff666666%s %s|r", timestamp, text)
        elseif msg.fromPlayer then
            line = string.format("|cff666666%s|r |cff00ccff|Hplayer:player|hYou|h|r|cffffffff: %s|r", timestamp, text)
        else
            local senderName = "Unknown"
            local senderFull = playerName
            if msg.sender then
                senderName = msg.sender:match("^[^-]+") or msg.sender
                senderFull = msg.sender:find("-") and msg.sender or GetFullName(msg.sender)
            end
            line = string.format("|cff666666%s|r |cff%s|Hplayer:%s|h%s|h|r|cffffffff: %s|r",
                timestamp,
                classColorHex,
                senderFull,
                senderName,
                text)
        end
        if msg.isQueued then
            line = line .. " |cffff9900(Queued)|r"
        end
        chatArea.scroll:AddMessage(line, 1, 1, 1)
    end
    chatArea.scroll:ScrollToBottom()
end

function Whispr.Messages:SaveMessage()
    if Whispr.History then
        Whispr.History:SaveConversations()
    end
end

function Whispr.Messages:OnEvent(event, ...)
    if event == "CHAT_MSG_WHISPER" then
        local msg, sender, _, _, _, _, _, _, _, _, _, guid = ...
        sender = GetFullName(sender)
        if guid then
            local _, class, _, race, bodyType = GetPlayerInfoByGUID(guid)
            if class then
                if not WhisprDb.playerClasses then
                    WhisprDb.playerClasses = {}
                end
                WhisprDb.playerClasses[sender] = class
            end
            if race then
                if not WhisprDb.playerRaces then
                    WhisprDb.playerRaces = {}
                end
                WhisprDb.playerRaces[sender] = race
            end
            if bodyType then
                if not WhisprDb.playerBodyTypes then
                    WhisprDb.playerBodyTypes = {}
                end
                WhisprDb.playerBodyTypes[sender] = bodyType
            end
        end
        if not self.conversations[sender] then
            self.conversations[sender] = {}
        end
        local isCurrentTarget = (sender == self.target)
        table.insert(self.conversations[sender], {
            sender = sender,
            text = msg,
            fromPlayer = false,
            timestamp = date("%H:%M"),
            date = date("%Y-%m-%d"),
            unread = not isCurrentTarget
        })
        self:SaveMessage()
        local frame = Whispr.Chat:GetFrame()
        if not frame then
            Whispr.Chat:Create()
            frame = Whispr.Chat:GetFrame()
        end
        Whispr.Contacts:UpdateSidebar()
        if not frame:IsShown() or (frame:IsShown() and self.target ~= sender) then
            if Whispr.Notifications then
                Whispr.Notifications:ShowNotification(sender, msg)
            end
        end
        if frame:IsShown() and self.target == sender then
            self:LoadConversation(sender)
        end
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local msg, sender, _, _, _, _, _, _, _, _, _, guid = ...
        local recipient = GetFullName(sender)
        if guid then
            local _, class, _, race, bodyType = GetPlayerInfoByGUID(guid)
            if class then
                if not WhisprDb.playerClasses then
                    WhisprDb.playerClasses = {}
                end
                WhisprDb.playerClasses[recipient] = class
            end
            if race then
                if not WhisprDb.playerRaces then
                    WhisprDb.playerRaces = {}
                end
                WhisprDb.playerRaces[recipient] = race
            end
            if bodyType then
                if not WhisprDb.playerBodyTypes then
                    WhisprDb.playerBodyTypes = {}
                end
                WhisprDb.playerBodyTypes[recipient] = bodyType
            end
        end
        if not self.conversations[recipient] then
            self.conversations[recipient] = {}
        end
        table.insert(self.conversations[recipient], {
            sender = UnitName("player"),
            text = msg,
            fromPlayer = true,
            timestamp = date("%H:%M"),
            date = date("%Y-%m-%d"),
            unread = false
        })
        self:SaveMessage()
        Whispr.Contacts:UpdateSidebar()
        if self.target == recipient then
            self:LoadConversation(recipient)
        end
    end
end

function Whispr.Messages:SetTarget(playerName)
    playerName = GetFullName(playerName)
    self.target = playerName
    local frame = Whispr.Chat:GetFrame()
    if frame and frame.headerBar then
        local shortName = playerName:match("^[^-]+") or playerName
        local class = Whispr.Contacts:GetPlayerClassInfo(playerName)
        local r, g, b = Whispr.Contacts:GetClassColor(class)
        -- if WhisprDb.playerClasses then
        --     print("Stored class:", WhisprDb.playerClasses[playerName])
        -- end
        frame.headerBar.noConvoText:SetText("Chat with " .. shortName)
        frame.headerBar.noConvoText:SetTextColor(r, g, b, 1)
        frame.headerBar.noConvoText:Show()
    end
    -- if Whispr.Chat:GetChatArea() then
    --     Whispr.Chat:GetChatArea().titleText:SetText("Chat with " .. (playerName:match("^[^-]+") or playerName))
    -- end
    if self.conversations[playerName] then
        for _, message in ipairs(self.conversations[playerName]) do
            message.unread = false
        end
    end
    if Whispr.Contacts then
        Whispr.Contacts:UpdateSidebar()
    end
    self:LoadConversation(playerName)
end

function Whispr.Messages:GetTarget()
    return self.target
end

function Whispr.Messages:GetConversation(playerName)
    playerName = GetFullName(playerName)
    return self.conversations[playerName] or {}
end

function Whispr.Messages:HasConversation(playerName)
    playerName = GetFullName(playerName)
    return self.conversations[playerName] ~= nil
end

function Whispr.Messages:GetLastMessage(playerName)
    playerName = GetFullName(playerName)
    local conversation = self.conversations[playerName]
    if conversation and #conversation > 0 then
        return conversation[#conversation]
    end
    return nil
end

-- Register the module
Whispr:RegisterModule("Messages", Whispr.Messages)