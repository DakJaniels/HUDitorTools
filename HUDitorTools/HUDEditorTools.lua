-- -----------------------------------------------------------------------------
-- HUDitorTools
-- Grid overlay + snap-to-grid for the ZOS HUD Editor (settings in info box)
-- and other features
-- -----------------------------------------------------------------------------

HUDitorTools = {}
local HT    = HUDitorTools
HT.name     = "HUDitor Tools"
HT.Defaults =
{
    enabled = false,
    showGrid = false,
    gridSize = 15,
}

------------------------------------------------------------------------------------------------------------------------
--- HUD Grid Snap
------------------------------------------------------------------------------------------------------------------------
local editorShowing = false

function HT.IsEditorShowing()
    return editorShowing
end

local function SnapControlTopLeft(control)
    local sv = HT.SV
    if not sv.enabled then
        return
    end
    local left, top = zo_round(control:GetLeft()), zo_round(control:GetTop())
    left, top = HT.ApplySnap(left, top, sv.gridSize)
    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

local function InstallEditorHooks()
    ZO_PreHook(ZO_HUDEditorElement_Keyboard, "ApplyChanges", function (self)
        if not HT.SV.enabled then
            return false
        end
        SnapControlTopLeft(self.control)
        return false
    end)

    ZO_PreHook(ZO_HUDEditorElement_Keyboard, "SetPositionFromTopLeft", function (self, offsetX, offsetY)
        if not HT.SV.enabled then
            return false
        end
        offsetX, offsetY = HT.ApplySnap(tonumber(offsetX), tonumber(offsetY), HT.SV.gridSize)
        self.control:ClearAnchors()
        self.control:SetAnchor(TOPLEFT, nil, nil, offsetX, offsetY)
        self:ApplyChanges()
        HUD_EDITOR_KEYBOARD.infoBoxXCoordsEditBox:SetText(tostring(offsetX))
        HUD_EDITOR_KEYBOARD.infoBoxYCoordsEditBox:SetText(tostring(offsetY))
        return true
    end)
end

local function OnEditorSceneStateChange(oldState, newState)
    if newState == SCENE_SHOWING or newState == SCENE_SHOWN then
        editorShowing = true
        HT.RefreshGridOverlay()
    elseif newState == SCENE_HIDING or newState == SCENE_HIDDEN then
        editorShowing = false
        HT.HideGridOverlay()
    end
end


------------------------------------------------------------------------------------------------------------------------
--- AddOn loading
------------------------------------------------------------------------------------------------------------------------
local function OnAddOnLoaded(_, addonName)
    if addonName ~= HT.name then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(HT.name, EVENT_ADD_ON_LOADED)

    HT.SV = ZO_SavedVars:NewAccountWide("HUDitorToolsSV", 1, nil, HT.Defaults)

    SCENE_MANAGER:GetScene("hud_editor_keyboard"):RegisterCallback("StateChange", OnEditorSceneStateChange)
    InstallEditorHooks()
    HT.InstallInfoBoxControls()
end
EVENT_MANAGER:RegisterForEvent(HT.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)