
local function add_SM_at_start_end_of_take_item(take)
  local item = reaper.GetMediaItemTake_Item(take)
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- TODO test if srcpos is calculated correctly or needs to be sent as an argument
  -- TODO in situations like take and item start at different positions, has different len etc.
  reaper.SetTakeStretchMarker(take, -1, 0)
  reaper.SetTakeStretchMarker(take, -1, item_len)
end

local function get_stretch_marker_at_edit_cursor()
  local cursor = reaper.GetCursorPosition()
  local item = reaper.GetSelectedMediaItem(0, 0)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  if item == nil then return end
  local take = reaper.GetActiveTake(item)
  if take == nil then return end
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  if n_stretch_markers == 0 then return end

  if n_stretch_markers == 1 then
    add_SM_at_start_end_of_take_item(take)
    n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  end

  local edit_cursor_pos = reaper.GetCursorPosition()
  local sm_pos = nil
  local sm_idx = nil
  -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
  -- reaper.ShowConsoleMsg("edit_cursor_pos: " .. edit_cursor_pos .. "\n")
  for i = 0, n_stretch_markers - 1 do
    local _, pos = reaper.GetTakeStretchMarker(take, i)
    pos = item_pos + pos
    -- reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
    -- if pos == edit_cursor_pos then
    if math.abs(pos - edit_cursor_pos) < 0.0001 then
      sm_idx = i
      sm_pos = pos
      break
    end
  end
  return sm_idx, sm_pos
end

-- ! get closest instead of on edit cursor
--   local left_sm_pos = nil
--   local left_sm_idx = nil
--   local right_sm_pos = nil
--   local right_sm_idx = nil
--   -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
--   -- reaper.ShowConsoleMsg("edit_cursor_pos: " .. edit_cursor_pos .. "\n")
--   for i = 0, n_stretch_markers - 1 do
--     local _, pos = reaper.GetTakeStretchMarker(take, i)
--     pos = item_pos + pos
--     -- reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
--     if pos <= edit_cursor_pos then
--       left_sm_pos = pos
--       left_sm_idx = i
--     elseif pos > edit_cursor_pos then
--       right_sm_pos = pos
--       right_sm_idx = i
--       break
--     end
--   end
--   -- reaper.ShowConsoleMsg("left_sm_pos: " .. left_sm_pos .. "\n")
--   -- reaper.ShowConsoleMsg("right_sm_pos: " .. right_sm_pos .. "\n")
--   local closest_sm_idx = nil
--   local closest_sm_pos = nil
--   if edit_cursor_pos - left_sm_pos < right_sm_pos - edit_cursor_pos then
--     closest_sm_idx = left_sm_idx
--   else
--     closest_sm_idx = right_sm_idx
--   end
--   return closest_sm_idx, closest_sm_pos
-- end

local function get_adjacent_stretch_markers(take, sm_idx)
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  local item_len = reaper.GetMediaItemInfo_Value(reaper.GetMediaItemTake_Item(take), "D_LENGTH")

  local rv, sm_pos = reaper.GetTakeStretchMarker(take, sm_idx)
  local prev_pos = 0
  local next_pos = item_len
  for i = 0, n_stretch_markers - 1 do
    local _, pos = reaper.GetTakeStretchMarker(take, i)
    local diff = pos - sm_pos
    if diff < 0 and pos > prev_pos then
      prev_pos = pos
    end
    if diff > 0 and pos < next_pos then
      next_pos = pos
    end
  end
  return prev_pos, next_pos
end

function AdjustSM(delta_value)
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then return end
  local take = reaper.GetActiveTake(item)
  if take == nil then return end
  -- mute the track, doesnt eliminate the scrub sound, maybe uncheck the Scrub/jog when movie edit cursor in AUdio-Scrub/Jog in 7.15
  -- local track = reaper.GetMediaItemTake_Track(take)
  -- reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
  local sm_idx, sm_pos = get_stretch_marker_at_edit_cursor()
  if sm_idx == nil then
    reaper.MB("No stretch marker in first selected item at edit cursor", "Error", 0)
    return
  end

  reaper.Undo_BeginBlock()
  local _, pos = reaper.GetTakeStretchMarker(take, sm_idx)

  -- limit the movement of stretch marker to the adjacent stretch markers
  local prev_pos, next_pos = get_adjacent_stretch_markers(take, sm_idx)
  if pos + delta_value < prev_pos or pos + delta_value > next_pos then
    reaper.MB("SM move hit adjacent SM or edge of item", "Error", 0)
    return
  end
  reaper.SetTakeStretchMarker(take, sm_idx, pos + delta_value)
  -- reaper.MoveEditCursor(delta_value, false)
  reaper.SetEditCurPos(pos + delta_value, true, false)

  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Adjust stretch marker", -1)
  -- reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
end

function AdjustSMZoomDep(lambda)
  local pixel_per_second = reaper.GetHZoomLevel()
  -- reaper.ShowConsoleMsg("pixel_per_second: " .. pixel_per_second .. "\n")
  local delta_value = lambda / pixel_per_second
  -- reaper.ShowConsoleMsg("delta_value: " .. delta_value .. "\n")
  AdjustSM(delta_value)
end




