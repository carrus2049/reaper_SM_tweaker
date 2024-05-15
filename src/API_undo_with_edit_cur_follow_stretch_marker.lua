

local function get_take_SM_idx_on_edit_cursor(take)
    if take == nil then return nil end
    local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
    if n_stretch_markers == 0 then return nil end
    for i = 0, n_stretch_markers - 1 do
        local _, pos = reaper.GetTakeStretchMarker(take, i)
        if math.abs(pos - reaper.GetCursorPosition()) < 0.0001 then
            return i
        end
    end
    return nil
end

reaper.Main_OnCommand(40029, 0)

local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then return end
local take = reaper.GetActiveTake(item)
if take == nil then return end
local sm_idx = get_take_SM_idx_on_edit_cursor(take)

if sm_idx ~= nil then
    local rv, pos = reaper.GetTakeStretchMarker(take, sm_idx)
    reaper.SetEditCurPos(pos, true, false)
end