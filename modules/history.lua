Whispr.History = {}

function Whispr.History:OnInit()

    if not WhisprDb then
        WhisprDb = {
            conversations = {},
            settings = {},
            groups = {
                ["Favorites"] = { contacts = {}, color = {1, 0.84, 0}, expand = true, pinned = true },
            },
            contactGroups = {}
        }
    else
        if not WhisprDb.groups then
            WhisprDb.groups = {
                ["Favorites"] = { contacts = {}, color = {1, 0.84, 0}, expand = true, pinned = true },
            }
        end
        if not WhisprDb.contactGroups then
            WhisprDb.contactGroups = {}
        end
    end

    if WhisprDb.conversations then
        Whispr.Messages.conversations = WhisprDb.conversations

        for name, message in pairs(WhisprDb.conversations) do
            print(" - Loaded conversation with", name, ":", #message, "messages") -- Debug output
        end
    end
    if WhisprDb.settings and WhisprDb.settings.fontSize then
        Whispr.Chat.savedFontSize = WhisprDb.settings.fontSize
    else
        Whispr.Chat.savedFontSize = 13
    end
end

function Whispr.History:SaveFontSize(fontSize)
    if not WhisprDb.settings then
        WhisprDb.settings = {}
    end
    WhisprDb.settings.fontSize = fontSize
end

function Whispr.History:CreateGroup(groupName, color)
    if not WhisprDb.groups then
        WhisprDb.groups = {}
    end

    if not WhisprDb.groups[groupName] then
        WhisprDb.groups[groupName] = {
            contacts = {},
            color = color or {0.7, 0.7, 0.7},
            expanded = true,
            pinned = false
        }
        return true
    end
    return false
end

function Whispr.History:RenameGroup(oldName, newName)
    if oldName == "Favorites" then
        return false -- Cannot rename the Favorites group
    end

    if not WhisprDb.groups or not WhisprDb.groups[oldName] then
        return false
    end

    if WhisprDb.groups[newName] then
        return false -- New group name already exists
    end

    WhisprDb.groups[newName] = WhisprDb.groups[oldName]
    WhisprDb.groups[oldName] = nil

    if WhisprDb.contactGroups then
        for playerName, groupName in pairs(WhisprDb.contactGroups) do
            if groupName == oldName then
                WhisprDb.contactGroups[playerName] = newName
            end
        end
    end

    return true
end

function Whispr.History:DeleteGroup(groupName)
    if groupName == "Favorites" then
        return false -- Cannot delete the Favorites group
    end

    if WhisprDb.groups and WhisprDb.groups[groupName] then
        for playerName, group in pairs(WhisprDb.contactGroups) do
            if group == groupName then
                WhisprDb.contactGroups[playerName] = nil
            end
        end

        WhisprDb.groups[groupName] = nil
        return true
    end
    return false
end

function Whispr.History:AddContactToGroup(playerName, groupName)
    if not WhisprDb.contactGroups then
        WhisprDb.contactGroups = {}
    end

    if not WhisprDb.groups or not WhisprDb.groups[groupName] then
        return false
    end

    WhisprDb.contactGroups[playerName] = groupName
    return true
end

function Whispr.History:RemoveContactFromGroup(playerName)
    if WhisprDb.contactGroups then
        WhisprDb.contactGroups[playerName] = nil
        return true
    end
    return false
end

function Whispr.History:GetContactGroup(playerName)
    if WhisprDb.contactGroups then
        return WhisprDb.contactGroups[playerName]
    end
    return nil
end

function Whispr.History:GetAllGroups()
    return WhisprDb.groups or {}
end

function Whispr.History:ToggleGroupExpanded(groupName)
    if WhisprDb.groups and WhisprDb.groups[groupName] then
        WhisprDb.groups[groupName].expanded = not WhisprDb.groups[groupName].expanded
    end
end

function Whispr.History:ToggleFavorite(playerName)
    local currentGroup = self:GetContactGroup(playerName)
    if currentGroup == "Favorites" then
        self:RemoveContactFromGroup(playerName)
    else
        self:AddContactToGroup(playerName, "Favorites")
    end

    if Whispr.Contacts then
        Whispr.Contacts:UpdateSidebar()
    end
end

function Whispr.History:SaveConversations()
    if not WhisprDb then
        WhisprDb = {}
    end

    WhisprDb.conversations = Whispr.Messages.conversations
end

function Whispr.History:ClearConversation(playerName)
    if WhisprDb.conversations and WhisprDb.conversations[playerName] then
        WhisprDb.conversations[playerName] = nil
        Whispr.Messages.conversations[playerName] = nil
        self:SaveConversations()
        if Whispr.Contacts then
            Whispr.Contacts:UpdateSidebar()
        end
    end
end

function Whispr.History:ClearAllConversations()
    WhisprDb.conversations = {}
    Whispr.Messages.conversations = {}
    Whispr.Contacts:UpdateSidebar()
end

function Whispr.History:GetConversations()
    local count = 0
    if WhisprDb.conversations then
        for _ in pairs(WhisprDb.conversations) do
            count = count + 1
        end
    end
    return count
end

function Whispr.History:GetTotalMessageCount()
    local count = 0
    if WhisprDb.conversations then
        for _, messages in pairs(WhisprDb.conversations) do
            count = count + #messages
        end
    end
    return count
end

Whispr:RegisterModule("History", Whispr.History)