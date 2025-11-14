Whispr.Messages = {}

Whispr.Messages.conversations = {}
Whispr.Messages.target = nil

function Whispr.Messages:OnInit()
    Whispr:RegisterEvent("CHAT_MSG_WHISPER")
    Whispr:RegisterEvent("CHAT_MSG_WHISPER_INFORM") -- For sent messages
end

-- Helper function to get full name with server
local function GetFullName(name)
    if name:find("-") then
        return name -- Already has server
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
    
    -- Ensure we use full name with server
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
            local senderFull = playerName -- Default to the conversation target
            
            if msg.sender then
                senderName = msg.sender:match("^[^-]+") or msg.sender
                senderFull = msg.sender:find("-") and msg.sender or GetFullName(msg.sender)
            end
            
            line = string.format("|cff666666%s|r |cffffcc00|Hplayer:%s|h%s|h|r|cffffffff: %s|r", 
                timestamp, 
                senderFull, 
                senderName, 
                text)
        end
        
        -- Add queued indicator if needed
        if msg.isQueued then
            line = line .. " |cffff9900(Queued)|r"
        end
        
        chatArea.scroll:AddMessage(line, 1, 1, 1)
    end

    -- Scroll to bottom
    chatArea.scroll:ScrollToBottom()
end

function Whispr.Messages:SaveMessage()
    if Whispr.History then
        Whispr.History:SaveConversations()
    end
end

function Whispr.Messages:OnEvent(event, msg, sender)
    -- Handle incoming whispers
    if event == "CHAT_MSG_WHISPER" then
        sender = GetFullName(sender)
        
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

        -- Update sidebar to show new message
        Whispr.Contacts:UpdateSidebar()

        if not frame:IsShown() or (frame:IsShown() and self.target ~= sender) then
            if Whispr.Notifications then
                Whispr.Notifications:ShowNotification(sender, msg)
            end
        end

        if frame:IsShown() and self.target == sender then
            self:LoadConversation(sender)
        end
    
    -- Handle sent whispers
    elseif event == "CHAT_MSG_WHISPER_INFORM" then
        local recipient = GetFullName(sender) -- sender is actually the recipient for INFORM events
        
        if not self.conversations[recipient] then
            self.conversations[recipient] = {}
        end

        table.insert(self.conversations[recipient], {
            sender = UnitName("player"),
            text = msg,
            fromPlayer = true,
            timestamp = date("%H:%M"),
            date = date("%Y-%m-%d"),
            unread = false -- Our own messages are never unread
        })

        self:SaveMessage()

        -- Update sidebar after sending
        Whispr.Contacts:UpdateSidebar()

        -- Refresh conversation if we're viewing it
        if self.target == recipient then
            self:LoadConversation(recipient)
        end
    end
end

function Whispr.Messages:SetTarget(playerName)
    playerName = GetFullName(playerName)
    self.target = playerName
    if Whispr.Chat:GetChatArea() then
        Whispr.Chat:GetChatArea().titleText:SetText("Chat with " .. (playerName:match("^[^-]+") or playerName))
    end
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