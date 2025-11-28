function Whispr:CreateDraggableFrame(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", f.StartMoving)
    frame:SetScript("OnDragStop", f.StopMovingOrSizing)
    return frame
end

function Whispr:AddAutoTransparency(frame, options)
    options = options or {}    
    frame.transparencyEnabled = true
    frame.isFocused = false
    frame.normalAlpha = options.normalAlpha or 1.0
    frame.unfocusedAlpha = options.unfocusedAlpha or 0.4
    frame.fadeSpeed = options.fadeSpeed or 5
    frame.currentAlpha = frame.normalAlpha
    frame.targetAlpha = frame.normalAlpha
    frame.checkMovement = options.checkMovement ~= false
    frame.UpdateTransparency = function(self, elapsed)
        if not self.transparencyEnabled then return end
        local shouldFade = false
        if self.checkMovement then
            local isMoving = GetUnitSpeed("player") > 0
            shouldFade = isMoving and not self.isFocused
        else
            shouldFade = not self.isFocused
        end
        self.targetAlpha = shouldFade and self.unfocusedAlpha or self.normalAlpha
        if self.currentAlpha ~= self.targetAlpha then
            local diff = self.targetAlpha - self.currentAlpha
            local change = diff * self.fadeSpeed * elapsed
            if math.abs(diff) < 0.01 then
                self.currentAlpha = self.targetAlpha
            else
                self.currentAlpha = self.currentAlpha + change
            end
            self:SetAlpha(self.currentAlpha)
        end
    end
    frame:HookScript("OnEnter", function(self)
        self.isFocused = true
    end)
    frame:HookScript("OnLeave", function(self)
        self.isFocused = false
    end)
    frame:HookScript("OnMouseDown", function(self)
        self.isFocused = true
    end)
end