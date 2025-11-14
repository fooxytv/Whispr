Whispr.Queue = {}

function Whispr.Queue:OnInit()
    if not WhisprDb then
        WhisprDb = {}
    end
    if not WhisprDb.messageQueue then
        WhisprDb.messageQueue = {}
    end

    Whispr:RegisterEvent("FRIENDLIST_UPDATE")
    Whispr:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    Whispr:RegisterEvent("PLAYER_ENTERING_WORLD")

    print("Whispr Queue: Initialised with", self:GetQueueCount(), "pending messages.")
end

function Whispr.Queue:QueueMessage(playerName, message)
    if not WhisprDb.messageQueue then
        WhisprDb.messageQueue = {}
    end

    if not WhisprDb.messageQueue[playerName] then
        WhisprDb.messageQueue[playerName] = {}
    end

    table.insert(WhisprDb.messageQueue[playerName], {
        text = message,
        timestamp = time(),
        dateQueued = date("%Y-%m-%d %H:%M:%S")
    })

    print("Whispr Queue: Queued message for", playerName, "- Will send when they are online.")
    return true
end

function Whispr.Queue:GetQueueMessage(playerName)
    if not WhisprDb.messageQueue or not WhisprDb.messageQueue[playerName] then
        return {}
    end
    return WhisprDb.messageQueue[playerName]
end

function Whispr.Queue:ClearQueue(playerName)
    if WhisprDb.messageQueue and WhisprDb.messageQueue[playerName] then
        WhisprDb.messageQueue[playerName] = nil
    end
end

function Whispr.Queue:GetQueueCount()
    local count = 0
    if WhisprDb.messageQueue then
        for playerName, messages in pairs(WhisprDb.messageQueue) do
            count = count + #messages
        end
    end
    return count
end

function Whispr.Queue:IsPlayerOnline(playerName)
    local shortName = playerName:match("^[^-]+") or playerName
    if UnitExists(shortName) and UnitIsConnected(shortName) then
        return true
    end

    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name then
            local friendShortName = friendInfo.name:match("^[^-]+") or friendInfo.name
            if friendShortName == shortName then
                return friendInfo.connected
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
                    return online
                end
            end
        end
    end
    return true
end

function Whispr.Queue:ProcessQueue()
    if not WhisprDb.messageQueue then return end
    for playerName, messages in pairs(WhisprDb.messageQueue) do
        if self:IsPlayerOnline(playerName) and #messages > 0 then
            print("Whispr Queue:", playerName, "is online. Sending", #messages, "queued message(s)...")
            for _, msg in ipairs(messages) do
                SendChatMessage(msg.text, "WHISPER", nil, playerName)
                C_Timer.After(0.5, function()
                    if Whispr.Messages.conversations[playerName] then
                        table.insert(Whispr.Messages.conversations[playerName], {
                            sender = "System",
                            text = "(Sent queued message from " .. msg.dateQueued .. ")",
                            fromPlayer = false,
                            timestamp = date("%H:%M"),
                            isSystem = true
                        })

                        if Whispr.Messages.target == playerName then
                            Whispr.Messages:LoadConversation(playerName)
                        end
                    end
                end)
            end

            self:ClearQueue(playerName)

            if Whispr.Contacts then
                Whispr.Contacts:UpdateSidebar()
            end
        end
    end
end

function Whispr.Queue:OnEvent(event, ...)
    if event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            self:ProcessQueue()
        end)
    end
end

Whispr:RegisterModule("Queue", Whispr.Queue)
