# Whispr Addon - Current State Analysis

**Generated:** 2025-11-03
**Version:** 0.1.0-alpha.0
**Interface:** 110107 (Retail WoW, The War Within)

---

## Executive Summary

Whispr is a partially-implemented instant messaging addon for World of Warcraft that aims to modernize in-game whisper conversations with a Discord/Teams-like interface. The codebase has been successfully modularized, with most core UI functionality working. However, critical features like data persistence, settings integration, and some module connections remain incomplete.

**Overall Status:** ~60% Complete - Core UI functional, but missing persistence and polish

---

## Table of Contents

1. [File Structure](#file-structure)
2. [Module-by-Module Analysis](#module-by-module-analysis)
3. [What's Working](#whats-working)
4. [What's Not Working](#whats-not-working)
5. [Technical Debt](#technical-debt)
6. [Critical Issues](#critical-issues)
7. [Development Roadmap](#development-roadmap)
8. [Next Steps (Prioritized)](#next-steps-prioritized)

---

## File Structure

```
Whispr/
├── core/
│   ├── init.lua          ✅ Complete - Module registration system
│   ├── events.lua        ✅ Complete - Event distribution
│   └── ui.lua            ✅ Complete - Helper for draggable frames
├── modules/
│   ├── chat.lua          ✅ 90% - Main UI implementation (has issues)
│   ├── contacts.lua      ✅ 95% - Sidebar contact list
│   ├── messages.lua      ⚠️  85% - Message handling (incomplete)
│   ├── commands.lua      ✅ 95% - Slash command system
│   ├── notifications.lua ✅ 100% - Toast notifications
│   ├── settings.lua      ⚠️  60% - Settings UI (not integrated)
│   ├── whispers.lua      ❌ DEPRECATED - Old version, commented out in TOC
│   └── history.lua       ❌ EMPTY - Only 1 line, not implemented
├── chat.lua              ❌ DEPRECATED - Duplicate of modules/chat.lua
├── Whispr.toc            ✅ Complete - Load order configured
└── .env                  ✅ Present - WoW addon paths configured
```

### TOC Load Order Analysis

```lua
core/init.lua           # 1. Creates Whispr namespace & module system
core/events.lua         # 2. Sets up event routing to modules
core/ui.lua             # 3. UI helper functions

#modules/whispers.lua   # COMMENTED OUT - old implementation

modules/chat.lua        # 4. Main chat window UI
modules/contacts.lua    # 5. Contact list sidebar
modules/messages.lua    # 6. Message storage & events
modules/commands.lua    # 7. Slash commands
modules/notifications.lua # 8. Toast notifications
```

**Note:** `modules/settings.lua` is NOT loaded in the TOC file, meaning the settings panel is completely non-functional despite being implemented.

---

## Module-by-Module Analysis

### ✅ core/init.lua - **COMPLETE**

**Status:** Fully functional
**Purpose:** Establishes the Whispr namespace and module registration system

**Implementation:**
- Global `Whispr` table created
- `Whispr:RegisterModule(name, module)` - Stores modules
- `Whispr:Init()` - Calls `OnInit()` on all registered modules
- Listens for `ADDON_LOADED` event to trigger initialization

**Issues:** None

---

### ✅ core/events.lua - **COMPLETE**

**Status:** Fully functional
**Purpose:** Central event distribution system

**Implementation:**
- Creates `Whispr.EventFrame` for event registration
- `Whispr:RegisterEvent(event)` - Registers WoW events
- Routes all events to every module's `OnEvent()` method

**Issues:** None

**Note:** This is a broadcast system - every module receives every event. Consider adding event filtering if performance becomes an issue.

---

### ✅ core/ui.lua - **COMPLETE**

**Status:** Fully functional
**Purpose:** UI helper functions

**Implementation:**
- `Whispr:CreateDraggableFrame(name, width, height)` - Creates movable frames with backdrop

**Issues:** None

**Recommendation:** Could be expanded with more UI utilities (color helpers, font management, etc.)

---

### ⚠️ modules/chat.lua - **90% COMPLETE**

**Status:** Mostly functional with some issues
**Purpose:** Main chat window UI

**What Works:**
- Main frame creation using `PortraitFrameTemplate`
- Three-panel layout: sidebar, chat area, input
- Draggable, ESC-closable window
- Contact list with scroll frame
- Chat message area with `ScrollingMessageFrame`
- Character counter for input (0/255)
- Search box in sidebar
- New conversation button with improved icon
- Hyperlink support in chat (items, spells, etc.)
- Mouse wheel scrolling
- TAB key to focus input box
- Auto-complete dropdown for player names (sophisticated implementation)

**What's Incomplete:**
1. **Duplicate function:** `CreateNewConversationPrompt()` implemented TWICE (lines 186-265 and not shown in modules version)
2. **Settings integration:** References `Whispr.Settings` but settings module isn't loaded
3. **Contact highlighting:** `HighlightSelectedContact()` function exists (lines 509-545) but may have issues with the new contact list design
4. **Input box focus:** TAB binding attempts are overly complex with multiple methods

**Code Issues:**
- Lines 186-265: `CreateNewConversationPrompt()` creates a sophisticated dropdown with friend/guild/recent player suggestions
- The function properly handles:
  - Friend list via `C_FriendList.GetNumFriends()` and `C_FriendList.GetFriendInfoByIndex()`
  - Guild members via `GetNumGuildMembers()` and `GetGuildRosterInfo()`
  - Recent conversations from `Whispr.Messages.conversations`
  - Duplicate removal and limiting to 8 suggestions
- Dropdown implementation (lines 76-183) is well-designed with proper click handlers and visual states

**Dependencies:**
- Requires: `Whispr.Messages` (message storage)
- Requires: `Whispr.Contacts` (sidebar updates)
- Optional: `Whispr.Settings` (not loaded)

---

### ✅ modules/contacts.lua - **95% COMPLETE**

**Status:** Nearly complete, excellent implementation
**Purpose:** Contact list sidebar with conversation entries

**What Works:**
- Collapsible section headers using WoW profession frame style (atlases)
- Contact entry creation with:
  - Race portraits (hash-based assignment from player name)
  - Player name display (short name without realm)
  - Unread message indicators with count badges
  - Hover tooltips showing last message
  - Selection highlighting (gold bars + dark background)
- Search filtering
- Sorting by timestamp (most recent first)
- Click handlers to open conversations
- Dynamic height adjustment

**Implementation Highlights:**
- `CreateSectionHeader()` (lines 37-106): Uses WoW atlases for native look
  - `Professions-recipe-header-left/middle/right`
  - Animated arrow rotation for expand/collapse
- `CreateContactEntry()` (lines 108-203): Rich contact display
  - Portrait with `SetTexCoord` for clean cropping
  - Selection state with dual highlight (top/bottom bars + background)
  - Unread indicators using minimap object icons
- `GetRacePortrait()` (lines 10-35): Consistent portrait assignment via name hash

**What's Incomplete:**
- Portrait assignment is random (hash-based) rather than actual race detection
- No way to fetch actual player race/class from name alone (WoW API limitation)

**Dependencies:**
- Requires: `Whispr.Chat:GetContactList()` and `Whispr.Chat:GetSearchBox()`
- Requires: `Whispr.Messages.conversations` and `Whispr.Messages.target`

**Quality:** This is one of the best-implemented modules. The UI is polished and follows WoW conventions.

---

### ⚠️ modules/messages.lua - **85% COMPLETE**

**Status:** Core functionality works, but has critical gaps
**Purpose:** Message storage and whisper event handling

**What Works:**
- `CHAT_MSG_WHISPER` event registration
- Conversation storage in `Whispr.Messages.conversations` table
- `LoadConversation(playerName)` - Displays messages in chat area
- `SetTarget(playerName)` - Switches active conversation
- Unread message tracking (`unread` flag on messages)
- Auto-creates chat window on first whisper
- Shows notifications for background messages
- Timestamp generation using `date("%H:%M")`
- Message formatting with colored sender names

**What's Incomplete:**
1. **No data persistence:** All conversations stored in RAM-only table
   - TOC declares `SavedVariables: Whispr_Account` but nothing uses it
   - All messages lost on logout/reload
2. **Duplicate event handler:** `OnWhisperReceived()` function (lines 88-112) is defined but NEVER CALLED
   - The actual handler is `OnEvent()` (lines 28-57)
   - This creates confusion about which code path is active
3. **No outgoing message tracking:** Sent messages are added to conversation but not to SavedVariables
4. **No conversation metadata:** No way to store player notes, favorite status, blocked list, etc.

**Critical Bug:**
- Line 48-52: Shows notification if message arrives while window is hidden OR while viewing different conversation
- But notification system may fire even when user is actively chatting (minor UX issue)

**Data Structure:**
```lua
Whispr.Messages.conversations = {
    ["PlayerName-RealmName"] = {
        { sender = "PlayerName-RealmName", text = "Hello", fromPlayer = false, timestamp = "14:30", unread = false },
        { sender = "YourName", text = "Hi there", fromPlayer = true, timestamp = "14:31" }
    }
}
```

**Dependencies:**
- Requires: `Whispr.Chat` (UI to display messages)
- Requires: `Whispr.Contacts` (sidebar updates)
- Optional: `Whispr.Notifications` (toast alerts)

---

### ✅ modules/commands.lua - **95% COMPLETE**

**Status:** Excellent implementation, nearly complete
**Purpose:** Slash command interface

**Registered Commands:**
- `/whispr`, `/wp`, `/whisper`

**Implemented Commands:**
| Command | Status | Functionality |
|---------|--------|---------------|
| `/whispr` or `/whispr show` | ✅ | Opens chat window |
| `/whispr hide` | ✅ | Closes chat window |
| `/whispr toggle` | ✅ | Toggles window visibility |
| `/whispr tell <name>` | ✅ | Opens conversation with player |
| `/whispr settings` | ⚠️ | Tries to open settings (module not loaded) |
| `/whispr clear notifications` | ✅ | Clears toast notifications |
| `/whispr status` | ✅ | Shows addon status (conversations, notifications, etc.) |
| `/whispr help` | ✅ | Displays command help |

**What Works:**
- Comprehensive command parsing
- Player name capitalization normalization
- Clear, colored output messages
- Auto-creates chat window if needed
- Excellent help text with examples
- Status command shows: window state, settings panel, conversation count, current target, notifications, theme

**What's Incomplete:**
1. `/whispr settings` attempts to call `Whispr.Settings:ExpandSettings()` but settings module isn't loaded
2. `ValidatePlayerName()` function (lines 222-239) exists but is never used
3. `GetPlayerSuggestions()` function (lines 242-259) exists but is never used (autocomplete could use this)

**Quality:** Excellent module with good error handling and user feedback.

---

### ✅ modules/notifications.lua - **100% COMPLETE**

**Status:** Fully functional
**Purpose:** Toast notification system for incoming whispers

**What Works:**
- Slide-in animation from left side
- Pink/magenta themed notifications (matches modern chat apps)
- Portrait icon (currently static, could be dynamic)
- Sender name and message snippet (60 char limit)
- Click handlers:
  - Left-click: Open conversation
  - Right-click: Dismiss notification
- Auto-dismiss after 6 seconds
- Sound effect (plays sound file 2113870)
- Stacking management (multiple notifications stack vertically)
- Active notification tracking
- `ClearAll()` and `GetActiveCount()` utilities

**Implementation Quality:**
- Clean fade-in animation using `UIFrameFadeIn`
- Proper frame strata (`DIALOG`) for visibility
- Good color scheme (dark background, pink border/glow)
- Responsive re-stacking when notifications are dismissed

**Potential Improvements:**
- Portrait is currently static (`Achievement_Character_Dwarf_Male`)
- Could integrate with character race/class data
- Could add more interaction options (reply inline, etc.)

**Dependencies:**
- Requires: `Whispr.Messages:SetTarget()` for opening conversations

---

### ⚠️ modules/settings.lua - **60% COMPLETE** (NOT LOADED)

**Status:** Fully implemented but NOT INCLUDED IN TOC
**Purpose:** Settings panel UI

**CRITICAL ISSUE:** This file is NOT loaded in Whispr.toc, meaning ALL this code is inactive!

**What's Implemented (but not loaded):**
- Expandable settings panel (slides out from right side)
- Animated expand/collapse (300px width addition)
- Scrollable settings content
- Three main sections:
  1. **Appearance:**
     - Theme selector (Dark, Light, Auto)
     - Border color picker
     - Background color picker
     - Message color picker
     - Font size slider (8-20)
  2. **Messages:**
     - Show timestamps checkbox
     - Fade old messages checkbox
  3. **Notifications:**
     - Enable notifications checkbox
     - Notification sound checkbox
- Action buttons:
  - Reset to defaults
  - Export settings (shows serialized settings text)

**Settings Data Structure:**
```lua
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
```

**What's Missing:**
1. **Not loaded in TOC** - Entire module is non-functional
2. **No SavedVariables integration** - Settings not persisted
3. **No settings application** - `ApplySettings()` exists but doesn't actually modify the UI
4. **No gear button** - No way to open settings panel from UI (relies on `/whispr settings` command)
5. **Color picker API version detection** - Has fallback for legacy API but may need testing
6. **Auto theme** - Uses time-of-day but doesn't respond to system theme

**Integration Points Needed:**
- Chat area needs border/background references that settings can modify
- Messages module needs font settings application
- Needs TOC entry: `modules/settings.lua`
- Needs UI button to toggle settings panel

---

### ❌ modules/whispers.lua - **DEPRECATED**

**Status:** Old implementation, commented out in TOC (line 16: `#modules/whispers.lua`)
**Purpose:** Legacy module, replaced by chat.lua + messages.lua

**What This Was:**
- Combined chat UI and message handling (monolithic design)
- Contains many of the same functions as current modules
- Has commented-out experimental code (lines 52-81)

**Action Required:** DELETE THIS FILE - It's confusing and serves no purpose

---

### ❌ modules/history.lua - **EMPTY**

**Status:** Not implemented
**Purpose:** Unknown (likely intended for conversation history management)

**Current Content:** Only 1 line (probably empty or just a comment)

**Speculation:** This might have been intended for:
- Conversation search/filtering
- Message history export
- Conversation archiving
- Deleted message recovery

**Action Required:** Either implement or delete this file

---

### ❌ chat.lua (root) - **DUPLICATE FILE**

**Status:** Duplicate of modules/chat.lua
**Purpose:** None (leftover from refactoring)

**Action Required:** DELETE THIS FILE - It's a duplicate of `modules/chat.lua`

---

## What's Working

### Core Functionality ✅
- [x] Addon loads without errors
- [x] Module registration system works
- [x] Event distribution to modules works
- [x] Main chat window creation
- [x] Whisper event capture (`CHAT_MSG_WHISPER`)

### UI Features ✅
- [x] Main window (800x500, draggable, ESC-closable)
- [x] Three-panel layout (sidebar, chat, input)
- [x] Contact list sidebar with:
  - [x] Collapsible sections
  - [x] Contact entries with portraits
  - [x] Unread indicators
  - [x] Selection highlighting
  - [x] Search filtering
  - [x] Timestamp sorting
- [x] Chat area with:
  - [x] Scrolling message display
  - [x] Hyperlink support (items/spells/etc.)
  - [x] Mouse wheel scrolling
  - [x] Colored sender names
  - [x] Timestamp display
- [x] Input box with:
  - [x] 255 character limit
  - [x] Character counter
  - [x] Enter to send
  - [x] TAB to focus
- [x] New conversation dialog with auto-complete dropdown

### Message System ✅
- [x] Incoming whisper capture
- [x] Message storage (RAM only)
- [x] Conversation switching
- [x] Unread message tracking
- [x] Message sending via `SendChatMessage()`
- [x] Timestamp generation

### Notifications ✅
- [x] Toast notifications for new messages
- [x] Slide-in animation
- [x] Click to open conversation
- [x] Right-click to dismiss
- [x] Auto-dismiss after 6 seconds
- [x] Notification stacking
- [x] Sound effects

### Commands ✅
- [x] `/whispr` - Open chat
- [x] `/wp` - Short alias
- [x] `/whispr toggle` - Toggle visibility
- [x] `/whispr tell <player>` - Start conversation
- [x] `/whispr status` - Show addon info
- [x] `/whispr help` - Command help
- [x] `/whispr clear notifications` - Clear toasts

---

## What's Not Working

### Critical Issues ❌

1. **NO DATA PERSISTENCE**
   - SavedVariables declared but never used
   - All conversations lost on logout/reload
   - Settings not saved
   - Unread counts not persisted

2. **Settings Module Not Loaded**
   - `modules/settings.lua` missing from TOC
   - Settings panel completely non-functional
   - `/whispr settings` command fails
   - No way to customize appearance

3. **Duplicate/Dead Files**
   - `modules/whispers.lua` - Commented out, should be deleted
   - `chat.lua` (root) - Duplicate of modules/chat.lua
   - `modules/history.lua` - Empty file

### Missing Features ⚠️

4. **No Settings UI Access**
   - No gear icon or settings button in main window
   - Only accessible via `/whispr settings` (which doesn't work)

5. **No Message History Features**
   - Can't search old messages
   - Can't export conversations
   - Can't delete conversations
   - No conversation archiving

6. **No Contact Management**
   - Can't favorite contacts
   - Can't block players
   - Can't add notes to contacts
   - Can't organize contacts into groups

7. **No Rich Text Features**
   - Can't format messages (bold, italic, etc.)
   - No emoji support
   - No custom colors per user

8. **No Session Management**
   - Window position not saved
   - Window size not saved
   - Last conversation not remembered
   - Search query not remembered

### API/Technical Issues ⚠️

9. **Event Handler Confusion**
   - `messages.lua` has two different message receive functions
   - `OnEvent()` is used, but `OnWhisperReceived()` is also defined (dead code)

10. **No Cross-Character Data**
    - TOC declares `SavedVariablesPerCharacter: Whispr_Lockout` but nothing uses it
    - No account-wide settings option

11. **No Error Handling**
    - No protection against nil references
    - No handling of invalid player names
    - No handling of offline players

12. **Performance Concerns**
    - Every module receives every event (no filtering)
    - Contact list rebuilds entire UI on every update
    - No throttling on search box text changes

---

## Technical Debt

### Code Quality Issues

1. **Inconsistent Module Patterns**
   - Some modules use local variables (chat.lua: `local frame, chatArea, inputBox`)
   - Others use module properties (notifications.lua: `Whispr.Notifications.active`)
   - No clear pattern for module state management

2. **Function Duplication**
   - `CreateNewConversationPrompt()` has sophisticated autocomplete in chat.lua
   - But similar logic in commands.lua (`GetPlayerSuggestions()`) is unused

3. **Magic Numbers**
   - Hard-coded sizes: 800x500, 200px sidebar, 300px settings panel
   - Should be constants or configurable

4. **String Formatting Inconsistency**
   - Some messages use `string.format()`
   - Others use string concatenation `.. " " ..`
   - Color codes scattered throughout

5. **No Localization**
   - All strings are English hard-coded
   - No localization framework

### Architecture Issues

6. **No Data Layer**
   - Messages stored directly in module table
   - No abstraction for data access
   - No data validation

7. **Tight Coupling**
   - Modules directly access each other's internals
   - Example: `Whispr.Messages.conversations` accessed from multiple modules
   - Hard to test or replace modules

8. **No Logging/Debugging**
   - No debug mode
   - No verbose logging
   - Hard to diagnose issues

9. **No Version Migration**
   - No way to upgrade SavedVariables schema
   - Will break if data structure changes

### WoW API Issues

10. **Deprecated API Usage Potential**
    - Code written for Interface 110107 (current as of analysis)
    - Need to verify compatibility with Midnight expansion API changes
    - Color picker code has fallback but may need updates

11. **No API Safety Checks**
    - No checks if `C_FriendList` exists before calling
    - No checks for Classic vs Retail API differences
    - Could break in different WoW versions

---

## Critical Issues

### Priority 1: Data Loss ⚠️🔴

**Issue:** All conversation data is lost on logout/reload
**Impact:** Users cannot build conversation history
**Cause:** SavedVariables declared but never implemented

**Example:**
```lua
-- In Whispr.toc:
## SavedVariables: Whispr_Account
## SavedVariablesPerCharacter: Whispr_Lockout

-- But in messages.lua:
Whispr.Messages.conversations = {}  -- RAM only, not persisted
```

**Fix Required:**
1. Create data persistence layer in messages.lua
2. Save conversations to `Whispr_Account.conversations`
3. Load saved data in `OnInit()`
4. Implement data migration for version updates

**Estimated Effort:** 2-4 hours

---

### Priority 2: Settings Module Not Loaded ⚠️🔴

**Issue:** Settings module fully implemented but not included in TOC
**Impact:** No way to customize addon, settings command broken
**Cause:** Forgotten in TOC file

**Fix Required:**
1. Add `modules/settings.lua` to TOC (after notifications.lua)
2. Add settings gear icon to chat window title bar
3. Connect settings to actual UI elements
4. Implement SavedVariables for settings persistence

**Estimated Effort:** 1-2 hours

---

### Priority 3: Dead Code Cleanup 🟡

**Issue:** Multiple deprecated/duplicate files confusing the codebase
**Impact:** Confusing for development, wasted space

**Files to Delete:**
- `modules/whispers.lua` - Old implementation
- `chat.lua` (root) - Duplicate
- `modules/history.lua` - Empty (or implement it)

**Estimated Effort:** 10 minutes

---

### Priority 4: Function Duplication in Messages Module 🟡

**Issue:** Two message receive functions, one never called
**Impact:** Confusing code, potential bugs if wrong one is edited

**In messages.lua:**
- `OnEvent()` (lines 28-57) - ACTIVE handler
- `OnWhisperReceived()` (lines 88-112) - DEFINED but NEVER CALLED

**Fix Required:** Delete `OnWhisperReceived()` or refactor to use it

**Estimated Effort:** 15 minutes

---

## Development Roadmap

### Phase 1: Critical Fixes (2-3 days)
**Goal:** Make addon usable for daily conversations

- [ ] Implement SavedVariables for messages
- [ ] Load settings.lua in TOC
- [ ] Add settings button to UI
- [ ] Connect settings to chat UI elements
- [ ] Implement window position saving
- [ ] Delete dead code files
- [ ] Fix message handler duplication
- [ ] Add nil safety checks

### Phase 2: Core Features (1 week)
**Goal:** Complete the "minimum viable product"

- [ ] Conversation search functionality
- [ ] Delete conversation feature
- [ ] Archive conversation feature
- [ ] Better timestamp display (relative times: "5m ago", "Yesterday")
- [ ] Player online/offline status indicators
- [ ] Character count enforcement (prevent sending >255 chars)
- [ ] Error handling for offline players
- [ ] Settings persistence to SavedVariables

### Phase 3: Polish & UX (1-2 weeks)
**Goal:** Make addon feel polished and professional

- [ ] Keyboard shortcuts (Ctrl+W to close, etc.)
- [ ] Context menus (right-click contact for options)
- [ ] Contact notes/favorites
- [ ] Contact grouping (Friends, Guild, Recent, etc.)
- [ ] Sound settings (choose notification sound)
- [ ] Color customization UI
- [ ] Font size/style selection
- [ ] Theme preview before apply
- [ ] Animation settings (enable/disable, speed)
- [ ] Compact mode (smaller window)

### Phase 4: Advanced Features (2-4 weeks)
**Goal:** Differentiate from other chat addons

- [ ] Battle.net friend integration
- [ ] Guild chat support (not just whispers)
- [ ] Party/Raid chat integration
- [ ] Multi-recipient messages (group whisper)
- [ ] Message templates/macros
- [ ] Auto-responses (away message)
- [ ] Conversation encryption (if technically possible)
- [ ] Cross-character conversation history
- [ ] Message export (text file, HTML)
- [ ] Rich text formatting (if possible within WoW API limits)

### Phase 5: Optimization & Release (1 week)
**Goal:** Prepare for public release

- [ ] Performance profiling
- [ ] Memory leak testing
- [ ] Event handling optimization (filter events per module)
- [ ] Contact list rendering optimization (virtual scrolling?)
- [ ] Localization framework
- [ ] English strings extracted
- [ ] Release notes
- [ ] User documentation
- [ ] CurseForge/Wago submission

---

## Next Steps (Prioritized)

### Immediate Actions (Do First) 🔴

1. **Fix SavedVariables Integration (Critical)**
   - **File:** `modules/messages.lua`
   - **Action:**
     ```lua
     function Whispr.Messages:OnInit()
         -- Initialize SavedVariables
         if not Whispr_Account then
             Whispr_Account = {}
         end
         if not Whispr_Account.conversations then
             Whispr_Account.conversations = {}
         end

         -- Use SavedVariables instead of local table
         self.conversations = Whispr_Account.conversations

         Whispr:RegisterEvent("CHAT_MSG_WHISPER")
         Whispr:RegisterEvent("PLAYER_LOGOUT") -- Save on logout
     end
     ```
   - **Why:** Prevents all data loss on reload
   - **Time:** 30 minutes

2. **Load Settings Module**
   - **File:** `Whispr.toc`
   - **Action:** Add line after `modules/notifications.lua`:
     ```
     modules/settings.lua
     ```
   - **Why:** Enables settings functionality
   - **Time:** 1 minute

3. **Delete Dead Files**
   - **Files to Delete:**
     - `modules/whispers.lua`
     - `chat.lua` (root level)
   - **File to Decide:** `modules/history.lua` (delete or implement)
   - **Why:** Reduces confusion
   - **Time:** 2 minutes

4. **Add Settings Button to UI**
   - **File:** `modules/chat.lua`
   - **Action:** Add gear icon to title bar (after line 278)
     ```lua
     -- Settings button in chat title bar
     local settingsButton = CreateFrame("Button", nil, chatArea.titleBar)
     settingsButton:SetSize(20, 20)
     settingsButton:SetPoint("RIGHT", chatArea.titleBar, "RIGHT", -10, 0)

     local settingsIcon = settingsButton:CreateTexture(nil, "ARTWORK")
     settingsIcon:SetAllPoints()
     settingsIcon:SetAtlas("mechagon-projects") -- Gear icon

     settingsButton:SetScript("OnClick", function()
         if Whispr.Settings then
             Whispr.Settings:ToggleSettings()
         end
     end)

     settingsButton:SetScript("OnEnter", function(self)
         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
         GameTooltip:SetText("Settings", 1, 1, 1)
         GameTooltip:Show()
     end)

     settingsButton:SetScript("OnLeave", function()
         GameTooltip:Hide()
     end)
     ```
   - **Why:** Provides UI access to settings
   - **Time:** 15 minutes

5. **Connect Settings to Chat UI**
   - **File:** `modules/settings.lua`
   - **Action:** Update `ApplySettings()` to actually modify the chat window
   - **Why:** Make settings actually work
   - **Time:** 1 hour

### Short-Term Goals (This Week) 🟡

6. **Implement Window Position Saving**
   - Save frame position to SavedVariables
   - Restore on addon load
   - **Time:** 30 minutes

7. **Add Conversation Deletion**
   - Right-click contact → Delete conversation
   - Confirmation dialog
   - **Time:** 1 hour

8. **Improve Timestamp Display**
   - Show relative time ("5m ago") instead of just "14:30"
   - Tooltip shows full timestamp
   - **Time:** 1 hour

9. **Add Nil Safety Checks**
   - Protect against missing modules
   - Handle offline players gracefully
   - **Time:** 1 hour

10. **Test All Commands**
    - Verify every `/whispr` command works
    - Fix `/whispr settings` now that module is loaded
    - **Time:** 30 minutes

### Medium-Term Goals (This Month) 🟢

11. **Conversation Search**
    - Search messages within current conversation
    - Highlight matching text
    - **Time:** 4 hours

12. **Contact Management**
    - Favorite contacts (pin to top)
    - Block list
    - Contact notes
    - **Time:** 6 hours

13. **Better Settings UI**
    - Live preview of color changes
    - Font preview
    - Reset individual settings (not just all)
    - **Time:** 4 hours

14. **Performance Optimization**
    - Event filtering per module
    - Throttle search box updates
    - Virtual scrolling for large contact lists
    - **Time:** 8 hours

15. **Error Handling**
    - Try/catch equivalent for Lua (pcall)
    - User-friendly error messages
    - Debug mode toggle
    - **Time:** 4 hours

---

## Technical Recommendations

### Data Architecture

**Current State:**
```lua
-- Scattered across modules
Whispr.Messages.conversations = {}
Whispr.Settings.settings = {}
```

**Recommended:**
```lua
-- Centralized data layer
Whispr.Data = {
    conversations = {},
    settings = {},
    contacts = {},
    blockedPlayers = {}
}

-- In OnInit:
if not Whispr_Account then
    Whispr_Account = {
        version = "0.1.0-alpha.0",
        conversations = {},
        settings = {},
        contacts = {},
        blockedPlayers = {}
    }
end

Whispr.Data = Whispr_Account
```

### Event Optimization

**Current State:**
```lua
-- Every module gets every event
Whispr.EventFrame:SetScript("OnEvent", function(_, event, ...)
    for _, module in pairs(Whispr.modules) do
        if module.OnEvent then
            module:OnEvent(event, ...)
        end
    end
end)
```

**Recommended:**
```lua
-- Event routing with registration
Whispr.EventHandlers = {}

function Whispr:RegisterEventHandler(event, module)
    if not self.EventHandlers[event] then
        self.EventHandlers[event] = {}
        self.EventFrame:RegisterEvent(event)
    end
    table.insert(self.EventHandlers[event], module)
end

Whispr.EventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = Whispr.EventHandlers[event] or {}
    for _, module in ipairs(handlers) do
        if module.OnEvent then
            module:OnEvent(event, ...)
        end
    end
end)
```

### Module Pattern Standardization

**Recommended Pattern:**
```lua
-- Every module should follow this pattern:
local ModuleName = {}

-- Module state (prefer local variables for frame refs)
local frame, panel, buttons

-- Module data (prefer module properties)
ModuleName.data = {}

-- Required lifecycle method
function ModuleName:OnInit()
    -- Initialize module
end

-- Optional lifecycle methods
function ModuleName:OnEvent(event, ...)
    -- Handle events
end

function ModuleName:OnEnable()
    -- Called when addon enables
end

function ModuleName:OnDisable()
    -- Called when addon disables
end

-- Public API methods
function ModuleName:PublicMethod()
    -- External interface
end

-- Private helper methods
local function privateHelper()
    -- Internal use only
end

-- Registration
Whispr:RegisterModule("ModuleName", ModuleName)
```

---

## Code Quality Checklist

### Before Next Session
- [ ] Delete deprecated files
- [ ] Fix SavedVariables integration
- [ ] Load settings.lua in TOC
- [ ] Test basic functionality (send/receive whisper)

### Before Public Release
- [ ] All modules follow consistent pattern
- [ ] No hard-coded strings (localization ready)
- [ ] All magic numbers extracted to constants
- [ ] Error handling on all external API calls
- [ ] Performance profiling completed
- [ ] Memory leak testing completed
- [ ] Cross-version testing (Retail/PTR)
- [ ] User documentation written
- [ ] Code comments added to complex sections
- [ ] TOC file metadata complete (Author, Version, Notes, etc.)

---

## API Compatibility Notes

### Current Interface Version
- **TOC Interface:** 110107 (The War Within - Retail)
- **Lua Version:** 5.1 (WoW uses Lua 5.1, not 5.4)

### WoW API Functions Used

**Friend List:**
- `C_FriendList.GetNumFriends()` - Retail API
- `C_FriendList.GetFriendInfoByIndex(i)` - Retail API

**Guild:**
- `IsInGuild()` - Universal
- `GetNumGuildMembers()` - Universal
- `GetGuildRosterInfo(i)` - Universal

**Chat:**
- `SendChatMessage(text, "WHISPER", nil, playerName)` - Universal
- Event: `CHAT_MSG_WHISPER` - Universal

**UI:**
- `CreateFrame()` - Universal
- Templates: `PortraitFrameTemplate`, `BackdropTemplate`, `InputBoxTemplate` - Retail
- `UISpecialFrames` table - Universal (ESC key handling)

**Color Picker:**
- Modern: `ColorPickerFrame:SetupColorPickerAndShow(info)` - Retail 10.0+
- Legacy: `ColorPickerFrame:SetColorRGB(r,g,b)` - Older versions
- Code has fallback for both

### Midnight Expansion Considerations

**Potential Breaking Changes:**
- Color picker API may change
- Friend list API may be updated
- Template names may change
- Atlas names may be deprecated

**Recommended Action:**
- Monitor Midnight beta API changes
- Update TOC Interface version when Midnight releases
- Test on PTR before Midnight launch
- Add version detection for API calls that change

---

## Conclusion

Whispr is a **well-architected addon with solid foundations** but **lacks critical data persistence and settings integration**. The modularization effort was successful, and the UI implementation is polished. However, without fixing the SavedVariables integration and loading the settings module, the addon is not ready for real use.

### Quick Summary

**Strengths:**
- Clean module system
- Polished contact list UI
- Working notifications
- Comprehensive slash commands
- Good WoW API usage

**Weaknesses:**
- No data persistence (everything lost on reload)
- Settings module not loaded
- Dead code needs cleanup
- Missing error handling
- No keyboard shortcuts

**Time to Usable:** ~2-3 hours (fix SavedVariables, load settings, add settings button)
**Time to Feature-Complete:** ~2-3 weeks (add all planned features)
**Time to Release-Ready:** ~4-6 weeks (polish, testing, documentation)

---

## File Locations Reference

All file paths below are absolute for easy access:

### Core Files
- `C:\Users\simon\workspaces\home-projects\Whispr\Whispr.toc`
- `C:\Users\simon\workspaces\home-projects\Whispr\core\init.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\core\events.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\core\ui.lua`

### Active Modules
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\chat.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\contacts.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\messages.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\commands.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\notifications.lua`
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\settings.lua` (NOT LOADED)

### Files to Delete
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\whispers.lua` (deprecated)
- `C:\Users\simon\workspaces\home-projects\Whispr\chat.lua` (duplicate)
- `C:\Users\simon\workspaces\home-projects\Whispr\modules\history.lua` (empty)

### Configuration
- `C:\Users\simon\workspaces\home-projects\Whispr\.env` (WoW addon paths)

---

**Document Version:** 1.0
**Last Updated:** 2025-11-03
**Next Review:** After implementing immediate actions
