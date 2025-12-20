local addonName, ns = ...
local ClassyMap = LibStub("AceAddon-3.0"):NewAddon("ClassyMap", "AceConsole-3.0", "AceEvent-3.0")
local GUI = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
ns.ClassyMap = ClassyMap

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

-- =============================================================================
-- Default Configuration
-- =============================================================================
local defaults = {
    profile = {
        enabled = true,
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        borderSize = 1,
        
        hideZoomButtons = false,
        hideExpansionButton = false,
        expansionIcon = "Interface\\AddOns\\ClassyMap\\Assets\\icon-expansion.tga",
        hideClock = false,
        
        -- Fonts
        font = "Fira Sans Condensed Black",
        zoneFontSize = 11,
        overrideZoneColor = false,
        zoneTextColor = { r = 1, g = 1, b = 1, a = 1 },
        clockFontSize = 11,
        clockTextColor = { r = 1, g = 0.82, b = 0, a = 1 }, -- WoW Gold/Yellow

        -- Toggles
        hideCalendar = false,
        hideAddonBtn = false,
        hideTracking = false,
        hideInstance = false,
        hideZoneText = false,
    }
}

-- =============================================================================
-- Combat Logic
-- =============================================================================
local combatQueue = {}

function ClassyMap:RunSafe(func, ...)
    if InCombatLockdown() then
        -- Serialize args cleanly if possible, or just closure it
        -- For simplicity in Lua, wrapping in a closure is easiest but arguments need care
        -- We will store the function and args table
        table.insert(combatQueue, {func = func, args = {...}})
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        func(self, ...)
    end
end

function ClassyMap:ProcessCombatQueue()
    for _, item in ipairs(combatQueue) do
        local success, err = pcall(item.func, self, unpack(item.args))
        if not success then
            geterrorhandler()(err)
        end
    end
    table.wipe(combatQueue)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- =============================================================================
-- Initialization
-- =============================================================================
function ClassyMap:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ClassyMapDB", defaults, true)
    
    self:RegisterChatCommand("classymap", "SlashHandler")
    self:RegisterChatCommand("cm", "SlashHandler")
    
    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        AddonCompartmentFrame:RegisterAddon({
            text = "ClassyMap",
            icon = "Interface\\Icons\\INV_Misc_Map02",
            notCheckable = true,
            func = function() ns.Settings:OpenOptions() end,
        })
    end
    
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "ProcessCombatQueue")
    
    self:Print("Loaded. Type /classymap or /cm for options.")
end

function ClassyMap:OnEnable()
    if IsLoggedIn() then
        self:RunSafe(self.ApplyMinimapChanges)
    else
        self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
            self:RunSafe(self.ApplyMinimapChanges)
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end)
    end
    
    -- Enforce Zone Text Colors on Zone Change
    self:RegisterEvent("ZONE_CHANGED", "ApplyFontStyles")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "ApplyFontStyles")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ApplyFontStyles")
end

function ClassyMap:SlashHandler(msg)
    local cmd = msg:trim():lower()
    if cmd == "toggle" then
        self.db.profile.enabled = not self.db.profile.enabled
        self:RunSafe(self.ApplyMinimapChanges)
        self:Print(self.db.profile.enabled and "Enabled" or "Disabled")
    else
        ns.Settings:OpenOptions()
    end
end

-- =============================================================================
-- Core Minimap Modifications
-- =============================================================================
function ClassyMap:SatStyles(f)
    if not f then return end
    f:SetParent(Minimap)
    f:SetFrameStrata("DIALOG") 
    f:Show()
end

    function ClassyMap:FixLayout()
    local db = self.db.profile
    local MARGIN = 4
    local STACK_GAP = 2
    local ICON_SIZE = 24 -- Size for standardized placement if needed
    
    -- Cluster & Map
    if MinimapCluster then
         MinimapCluster:SetWidth(Minimap:GetWidth())
         MinimapCluster:SetHeight(Minimap:GetHeight())
         MinimapCluster:SetClampedToScreen(false)
    end
    if Minimap then
         Minimap:ClearAllPoints()
         Minimap:SetPoint("CENTER", MinimapCluster, "CENTER", 0, 0)
    end

    -- Zone Text (Top Center)
    if MinimapCluster.ZoneTextButton then
        if not db.hideZoneText then
            self:SatStyles(MinimapCluster.ZoneTextButton)
            MinimapCluster.ZoneTextButton:ClearAllPoints()
            -- Header Row Alignment (User Tweak: Down 2px from +2 -> 0)
            MinimapCluster.ZoneTextButton:SetPoint("TOP", Minimap, "TOP", 0, 0)
            MinimapCluster.ZoneTextButton:SetHeight(ICON_SIZE) -- Match Icon Height (24)
            MinimapCluster.ZoneTextButton:SetAlpha(1)
            
            -- Centering Text
            if MinimapZoneText then 
                MinimapZoneText:ClearAllPoints()
                MinimapZoneText:SetAllPoints(MinimapCluster.ZoneTextButton)
                MinimapZoneText:SetJustifyH("CENTER") 
                MinimapZoneText:SetJustifyV("MIDDLE")
                MinimapZoneText:SetWordWrap(false)
            end
        else
            MinimapCluster.ZoneTextButton:Hide()
        end
    end

    -- Clock (Below Zone Text)
    if TimeManagerClockButton then
        if not db.hideClock then
            self:SatStyles(TimeManagerClockButton)
            TimeManagerClockButton:ClearAllPoints()
            if MinimapCluster.ZoneTextButton then
                TimeManagerClockButton:SetPoint("TOP", MinimapCluster.ZoneTextButton, "BOTTOM", 0, 0)
            else
                TimeManagerClockButton:SetPoint("TOP", Minimap, "TOP", 0, -MARGIN)
            end
        else
            TimeManagerClockButton:Hide()
        end
    end

    -- Tracking (TOP LEFT)
    -- Native Tracking frame is quirky, but let's try standard anchor
    if MinimapCluster.Tracking then
        if not db.hideTracking then
            self:SatStyles(MinimapCluster.Tracking)
            MinimapCluster.Tracking:ClearAllPoints()
            MinimapCluster.Tracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", MARGIN, -MARGIN)
        else
            MinimapCluster.Tracking:Hide()
        end
    end

    -- Stack Logic (TOP RIGHT)
    local lastFrame = nil
    
    -- Calendar
    if GameTimeFrame then
        if not db.hideCalendar then
            self:SatStyles(GameTimeFrame)
            GameTimeFrame:ClearAllPoints()
            GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
            GameTimeFrame:SetScale(1.0)
            lastFrame = GameTimeFrame
        else
            GameTimeFrame:Hide()
        end
    end

    -- Addon Drawer
    if AddonCompartmentFrame then
        if not db.hideAddonBtn then
            self:SatStyles(AddonCompartmentFrame)
            AddonCompartmentFrame:ClearAllPoints()
            if lastFrame then
                -- Center align with manual tweak (User requested revert to previous -> -2)
                AddonCompartmentFrame:SetPoint("TOP", lastFrame, "BOTTOM", -2, -STACK_GAP)
            else
                AddonCompartmentFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
            end
            AddonCompartmentFrame:SetScale(1.0)
            if not lastFrame then lastFrame = AddonCompartmentFrame end
        else
            AddonCompartmentFrame:Hide()
        end
    end
    
    -- Instance Difficulty (Left of Top Item)
    local diffFrame = MinimapCluster.InstanceDifficulty
    if diffFrame then
        if not db.hideInstance then
            self:SatStyles(diffFrame)
            diffFrame:ClearAllPoints()
            local topFrame = nil
            if GameTimeFrame and GameTimeFrame:IsShown() then topFrame = GameTimeFrame
            elseif AddonCompartmentFrame and AddonCompartmentFrame:IsShown() then topFrame = AddonCompartmentFrame end
            
            if topFrame then
                diffFrame:SetPoint("RIGHT", topFrame, "LEFT", -STACK_GAP, 0)
            else
                diffFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -MARGIN, -MARGIN)
            end
            diffFrame:SetScale(1.0)
        else
            diffFrame:Hide()
        end
    end
    
    -- Expansion Button (BOTTOM LEFT)
    local expBtn = _G["ClassyMapExpansionBtn"]
    if expBtn then
        if not db.hideExpansionButton then
            self:SatStyles(expBtn)
            expBtn:ClearAllPoints()
            expBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", MARGIN, MARGIN)
            expBtn:SetScale(1.0)
        else
            expBtn:Hide()
        end
    end
end

function ClassyMap:ApplyMinimapChanges()
    if not self.db.profile.enabled then
        self:ResetMinimap()
        return
    end
    
    -- 1. Apply Square Mask
    Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
    
    -- 2. Hybrid Minimap
    if HybridMinimap then
        HybridMinimap.MapCanvas:SetUseMaskTexture(false)
        HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        HybridMinimap.MapCanvas:SetUseMaskTexture(true)
    end
    
    -- 3. Border
    self:CreateBorder()
    
    -- 4. Hide Clutter
    self:HideMinimapClutter()
    
    -- 5. Blobs (disable ring effects that don't work well with square minimap)
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetArchBlobRingAlpha(0)
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetQuestBlobRingAlpha(0)
    Minimap:SetTaskBlobRingScalar(0)
    Minimap:SetTaskBlobRingAlpha(0)
    
    -- 6. Shape
    GetMinimapShape = function() return "SQUARE" end

    -- 7. Clamping
    if MinimapCluster then
        MinimapCluster:SetClampedToScreen(true)
        MinimapCluster:SetClampRectInsets(0, -60, 0, -60)
    end
    if Minimap then
        Minimap:SetClampedToScreen(false) 
    end
    
    -- 8. Fonts
    self:ApplyFontStyles()
    
    -- 9. Layout
    self:FixLayout()
    
    if not self.hookedLayout then
        hooksecurefunc(MinimapCluster, "SetWidth", function() 
            if not self.resizing then 
                self.resizing = true
                -- We only want to run this if enabled (could check self.db)
                -- Also, running FixLayout repeatedly is costly.
                -- Blizzard often animates SetWidth.
                -- Basic throttle or check:
                if self.db.profile.enabled then
                    self:FixLayout() 
                end
                self.resizing = false
            end 
        end)
        self.hookedLayout = true
    end
end

function ClassyMap:CreateBorder()
    if self.borders then
        self:UpdateBorderStyle()
        return
    end
    
    -- "The Background Container" Strategy failed via Frame.
    -- New Strategy: 4 Textures DIRECTLY on the Minimap object.
    -- Layer: BACKGROUND, SubLevel: -5 (Lowest possible).
    -- This guarantees they are "painted" onto the map canvas before anything else.
    
    self.borders = {}
    local function CreateLine()
        -- Create texture on Minimap.
        -- ARTWORK layer ensures it is visible above the map terrain (BACKGROUND),
        -- But as a texture on the Frame, it is strictly below any Child Frames (Buttons).
        local t = Minimap:CreateTexture(nil, "ARTWORK")
        t:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        return t
    end
    
    self.borders.top = CreateLine()
    self.borders.bottom = CreateLine()
    self.borders.left = CreateLine()
    self.borders.right = CreateLine()
    
    -- Remove old frame if it exists from previous load
    if self.borderFrame then 
        self.borderFrame:Hide() 
        self.borderFrame = nil 
    end
    
    self:UpdateBorderStyle()
end

function ClassyMap:UpdateBorderStyle()
    if not self.borders then return end
    
    local size = self.db.profile.borderSize
    local c = self.db.profile.borderColor
    
    -- If size is 0, hide all
    if size <= 0 then
        for _, tex in pairs(self.borders) do tex:Hide() end
        return
    end
    
    -- Setup textures
    for _, tex in pairs(self.borders) do
        tex:SetVertexColor(c.r, c.g, c.b, c.a)
        tex:Show()
        tex:ClearAllPoints()
    end
    
    -- Top (Spans full width)
    self.borders.top:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    self.borders.top:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
    self.borders.top:SetHeight(size)
    
    -- Bottom (Spans full width)
    self.borders.bottom:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    self.borders.bottom:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    self.borders.bottom:SetHeight(size)
    
    -- Left (Spans top to bottom)
    self.borders.left:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    self.borders.left:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    self.borders.left:SetWidth(size)
    
    -- Right (Spans top to bottom)
    self.borders.right:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
    self.borders.right:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    self.borders.right:SetWidth(size)
end

function ClassyMap:HideMinimapClutter()
    local db = self.db.profile
    
    -- Force Hide Compass
    if MinimapCompassTexture then
        MinimapCompassTexture:Hide()
        MinimapCompassTexture:SetAlpha(0)
    end
    
    -- Zoom Buttons
    if db.hideZoomButtons then
        if not self.zoomParentIn then self.zoomParentIn = Minimap.ZoomIn:GetParent() end
        if not self.zoomParentOut then self.zoomParentOut = Minimap.ZoomOut:GetParent() end
        Minimap.ZoomIn:SetParent(hiddenFrame)
        Minimap.ZoomOut:SetParent(hiddenFrame)
    else
        if self.zoomParentIn then Minimap.ZoomIn:SetParent(self.zoomParentIn) end
        if self.zoomParentOut then Minimap.ZoomOut:SetParent(self.zoomParentOut) end
    end
    
    -- Expansion Landing Page (Always Replace Native)
    if ExpansionLandingPageMinimapButton then
         ExpansionLandingPageMinimapButton:Hide()
         ExpansionLandingPageMinimapButton:SetAlpha(0)
         if not self.expHooked then
             hooksecurefunc(ExpansionLandingPageMinimapButton, "Show", function(self)
                 self:Hide()
             end)
             self.expHooked = true
         end
    end
    
    self:CreateExpansionReplacement()
    
    -- Custom Button Visibility
    if self.expansionReplacementBtn then
        if db.hideExpansionButton then
            self.expansionReplacementBtn:Hide()
        else
            self.expansionReplacementBtn:Show()
        end
    end
    
    -- Tracking
    if MinimapCluster.Tracking then
        if db.hideTracking then
            MinimapCluster.Tracking:Hide()
        else
            MinimapCluster.Tracking:Show()
        end
    end

    -- BorderTop
    if MinimapCluster.BorderTop then
        MinimapCluster.BorderTop:Hide()
        MinimapCluster.BorderTop:SetAlpha(0)
    end
end

function ClassyMap:CreateExpansionReplacement()
    if not self.db.profile.enabled then return end
    
    if self.expansionReplacementBtn then
        -- Update Icon
        local iconPath = self.db.profile.expansionIcon
        if not iconPath or iconPath == "" then iconPath = "Interface\\Icons\\Inv_misc_book_17" end
        self.expansionReplacementBtn.icon:SetTexture(iconPath)
        return
    end
    
    local btn = CreateFrame("Button", "ClassyMapExpansionBtn", MinimapCluster)
    btn:SetSize(24, 24) -- Resized to match standard small buttons
    btn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
    btn:SetFrameStrata("DIALOG") 
    btn:SetFrameLevel(100)
    
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    
    local iconPath = self.db.profile.expansionIcon
    if not iconPath or iconPath == "" then iconPath = "Interface\\Icons\\Inv_misc_book_17" end
    btn.icon:SetTexture(iconPath) 
    
    btn.icon:SetTexCoord(0, 1, 0, 1) -- No crop
    
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    btn:SetScript("OnClick", function()
        if ExpansionLandingPageMinimapButton then
            ExpansionLandingPageMinimapButton:Click()
        end
    end)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Khaz Algar Summary")
        GameTooltip:AddLine("Click to open expansion summary", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    self.expansionReplacementBtn = btn
end

function ClassyMap:ApplyFontStyles()
    local db = self.db.profile
    local fontPath = LSM:Fetch("font", db.font) or "Fonts\\FRIZQT__.TTF"
    
    if MinimapZoneText then
        MinimapZoneText:SetFont(fontPath, db.zoneFontSize, "OUTLINE")
        
        -- Only override color if enabled. Otherwise let Blizzard handle it (Sanctuary/Contested colors).
        if db.overrideZoneColor then
            local c = db.zoneTextColor
            MinimapZoneText:SetTextColor(c.r, c.g, c.b, c.a)
        else
            -- If we are not overriding, we let Blizzard's native code handle it.
        end
    end
    
    if TimeManagerClockButton then
        local region = TimeManagerClockButton:GetRegions() -- Usually the first region is the text
        if region then
             region:SetFont(fontPath, db.clockFontSize, "OUTLINE")
             local c = db.clockTextColor
             region:SetTextColor(c.r, c.g, c.b, c.a)
        end
    end
end

function ClassyMap:ResetMinimap()
    Minimap:SetMaskTexture("Textures\\MinimapMask")
    
    if self.borders then 
        for _, tex in pairs(self.borders) do tex:Hide() end
    end
    if self.borderFrame then self.borderFrame:Hide() end
    
    -- Restore Zoom
    if self.zoomParentIn then Minimap.ZoomIn:SetParent(self.zoomParentIn) end
    if self.zoomParentOut then Minimap.ZoomOut:SetParent(self.zoomParentOut) end
    
    -- Restore Expansion
    if ExpansionLandingPageMinimapButton then 
        ExpansionLandingPageMinimapButton:Show()
        ExpansionLandingPageMinimapButton:SetAlpha(1)
    end
    if self.expansionReplacementBtn then self.expansionReplacementBtn:Hide() end
    
    if MinimapCompassTexture then 
        MinimapCompassTexture:Show()
        MinimapCompassTexture:SetAlpha(1)
    end
    if MinimapCluster.BorderTop then MinimapCluster.BorderTop:SetAlpha(1) end
    if TimeManagerClockButton then TimeManagerClockButton:Show() end
    if MinimapCluster.Tracking then MinimapCluster.Tracking:Show() end
    
    Minimap:SetArchBlobRingScalar(1)
    Minimap:SetQuestBlobRingScalar(1)
    Minimap:SetTaskBlobRingScalar(1)
    
    GetMinimapShape = function() return "ROUND" end
end

local function OnHybridMinimapLoaded()
    if HybridMinimap and ClassyMap.db.profile.enabled then
        HybridMinimap.MapCanvas:SetUseMaskTexture(false)
        HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        HybridMinimap.MapCanvas:SetUseMaskTexture(true)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_HybridMinimap" then
        OnHybridMinimapLoaded()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
