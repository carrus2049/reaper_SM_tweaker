
local function get_stretch_marker_near_edit_cursor()
  local cursor = reaper.GetCursorPosition()
  local item = reaper.GetSelectedMediaItem(0, 0)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  if item == nil then return end
  local take = reaper.GetActiveTake(item)
  if take == nil then return end
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  if n_stretch_markers == 0 then return end
  local edit_cursor_pos = reaper.GetCursorPosition()
  local left_sm_pos = nil
  local left_sm_idx = nil
  local right_sm_pos = nil
  local right_sm_idx = nil
  -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
  reaper.ShowConsoleMsg("edit_cursor_pos: " .. edit_cursor_pos .. "\n")
  for i = 0, n_stretch_markers - 1 do
    local _, pos = reaper.GetTakeStretchMarker(take, i)
    pos = item_pos + pos
    reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
    if pos <= edit_cursor_pos then
      left_sm_pos = pos
      left_sm_idx = i
    elseif pos > edit_cursor_pos then
      right_sm_pos = pos
      right_sm_idx = i
      break
    end
  end
  -- reaper.ShowConsoleMsg("left_sm_pos: " .. left_sm_pos .. "\n")
  -- reaper.ShowConsoleMsg("right_sm_pos: " .. right_sm_pos .. "\n")
  local closest_sm_idx = nil
  local closest_sm_pos = nil
  if edit_cursor_pos - left_sm_pos < right_sm_pos - edit_cursor_pos then
    closest_sm_idx = left_sm_idx
  else
    closest_sm_idx = right_sm_idx
  end
  return closest_sm_idx, closest_sm_pos
end

function AdjustSM(delta_value)
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then return end
  local take = reaper.GetActiveTake(item)
  if take == nil then return end
  local closest_sm_idx, closest_sm_pos = get_stretch_marker_near_edit_cursor()
  if closest_sm_idx == nil then return end
  local _, pos = reaper.GetTakeStretchMarker(take, closest_sm_idx)
  reaper.SetTakeStretchMarker(take, closest_sm_idx, pos + delta_value)
  reaper.MoveEditCursor(delta_value, false)
  reaper.UpdateArrange()
end

function AdjustSMZoomDep(lambda)
  local pixel_per_second = reaper.GetHZoomLevel()
  reaper.ShowConsoleMsg("pixel_per_second: " .. pixel_per_second .. "\n")
  local delta_value = lambda / pixel_per_second
  reaper.ShowConsoleMsg("delta_value: " .. delta_value .. "\n")
  adjust_stretch_marker(delta_value)
end




