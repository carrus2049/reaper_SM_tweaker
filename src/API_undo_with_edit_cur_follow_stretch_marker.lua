

local function get_take_SM_idx_on_edit_cursor(take)
    if take == nil then return nil end
    local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
    -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
    if n_stretch_markers == 0 then return nil end
    local take_play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local item = reaper.GetMediaItemTake_Item(take)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    for i = 0, n_stretch_markers - 1 do
        local _, pos = reaper.GetTakeStretchMarker(take, i)
        pos = pos / take_play_rate + item_pos 
        -- reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
        -- reaper.ShowConsoleMsg("reaper.GetCursorPosition(): " .. reaper.GetCursorPosition() .. "\n")
        if math.abs(pos - reaper.GetCursorPosition()) < 0.0001 then
            return i
        end
    end
    return nil
end

local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then return end
local take = reaper.GetActiveTake(item)
if take == nil then return end
local sm_idx = get_take_SM_idx_on_edit_cursor(take)
reaper.Main_OnCommand(40029, 0)



if sm_idx ~= nil then
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local take_play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local rv, pos = reaper.GetTakeStretchMarker(take, sm_idx)
    -- reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
    pos = pos / take_play_rate
    reaper.SetEditCurPos(item_pos + pos, true, false)
end