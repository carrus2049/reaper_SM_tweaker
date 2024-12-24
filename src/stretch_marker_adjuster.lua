---@diagnostic disable: param-type-mismatch


local function take_have_sm_in_certain_srcpos(take, srcpos)
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
  for i = 0, n_stretch_markers - 1 do
    local rv, pos, src_pos = reaper.GetTakeStretchMarker(take, i)
    if src_pos == srcpos then
      return true
    end
  end
  return false
end

local function get_stretch_marker_at_take_source_end_pos(take)
  local src = reaper.GetMediaItemTake_Source(take)
  local src_len = reaper.GetMediaSourceLength(src)
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  for i = 0, n_stretch_markers - 1 do
    local rv, pos, src_pos = reaper.GetTakeStretchMarker(take, i)
    -- reaper.ShowConsoleMsg("src_pos: " .. src_pos .. " src_len" .. src_len .. "\n")
    -- reaper.ShowConsoleMsg('offset' .. src_pos - src_len .. "\n")
    if math.abs(src_pos - src_len) < 0.0001 then
      -- reaper.ShowConsoleMsg("got pos: " .. pos .. "\n")
      return i, pos
    end
  end
  return nil
end

local function add_SM_at_start_end_of_take_item(take)
  local item = reaper.GetMediaItemTake_Item(take)
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

  -- TODO test if srcpos is calculated correctly or needs to be sent as an argument
  -- TODO in situations like take and item start at different positions, has different len etc.
  local added_start = 0
  local added_end = 0
  local src = reaper.GetMediaItemTake_Source(take)
  -- local src_len = reaper.GetMediaSourceLength(src)
  local item_end_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + item_len
  local src_len = item_end_pos

  if not take_have_sm_in_certain_srcpos(take, 0) then
    reaper.SetTakeStretchMarker(take, -1, 0)
    added_start = 1
  end
  if not take_have_sm_in_certain_srcpos(take, src_len) then
    reaper.SetTakeStretchMarker(take, -1, src_len)
    added_end = 1
  end
  return added_start, added_end
  -- reaper.SetTakeStretchMarker(take, -1, 0)
  -- reaper.SetTakeStretchMarker(take, -1, item_len)
end





local function get_stretch_marker_at_edit_cursor()
  local cursor = reaper.GetCursorPosition()
  local item = reaper.GetSelectedMediaItem(0, 0)
  -- ! test
  -- local track0 = reaper.GetTrack(0, 0)
  -- local item = reaper.GetTrackMediaItem(track0, 0)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  if item == nil then return end
  local take = reaper.GetActiveTake(item)
  if take == nil then return end
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  if n_stretch_markers == 0 then return end

  -- if n_stretch_markers == 1 then
  --   add_SM_at_start_end_of_take_item(take)
  --   n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  -- end

  local edit_cursor_pos = reaper.GetCursorPosition()
  local take_play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  local sm_pos = nil
  local sm_idx = nil
  -- reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")
  -- reaper.ShowConsoleMsg("edit_cursor_pos: " .. edit_cursor_pos .. "\n")
  for i = 0, n_stretch_markers - 1 do
    local _, pos = reaper.GetTakeStretchMarker(take, i)
    pos = pos / take_play_rate
    -- reaper.ShowConsoleMsg("pos: " .. pos .. "\n")
    -- reaper.ShowConsoleMsg("item_pos: " .. item_pos .. "\n")
    pos = item_pos + pos
    -- reaper.ShowConsoleMsg("pos: " .. pos .. "edit curpos: " .. edit_cursor_pos .. "\n")
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
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local take_play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  reaper.SetEditCurPos(item_pos + (pos + delta_value)/take_play_rate, true, false)

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


local function take_next_stretch_marker_follow_rate(take, sm_idx, rate)
  local rv, pos, srcpos = reaper.GetTakeStretchMarker(take, sm_idx)
  local rv, next_pos, next_srcpos = reaper.GetTakeStretchMarker(take, sm_idx + 1)
  -- reaper.ShowConsoleMsg("next_pos: " .. next_pos .. "\n")
  if rv == -1 then return end
  local src_offset = next_srcpos - srcpos
  local target_time_offset = src_offset / rate
  -- reaper.ShowConsoleMsg("src_offset: " .. src_offset .. "\n")
  -- reaper.ShowConsoleMsg("target_time_offset: " .. target_time_offset .. "\n")

  -- reaper.ShowConsoleMsg("target_time_offset: " .. target_time_offset .. "\n")
  -- reaper.SetTakeStretchMarker(take, sm_idx + 1, pos + target_time_offset)
end

local function take_next_stretch_marker_follow_slope(take, sm_idx, rate)
  local rv, pos, srcpos = reaper.GetTakeStretchMarker(take, sm_idx)
  local rv, next_pos, next_srcpos = reaper.GetTakeStretchMarker(take, sm_idx + 1)
  -- reaper.ShowConsoleMsg("next_pos: " .. next_pos .. "\n")
  if rv == -1 then return end
  
  local src_offset = next_srcpos - srcpos
  local prev_stretch_rate = src_offset / (pos - next_pos)
  reaper.ShowConsoleMsg("prev_stretch_rate: " .. prev_stretch_rate .. "\n")
  local target_time_offset = src_offset / rate
  -- reaper.ShowConsoleMsg("src_offset: " .. src_offset .. "\n")
  reaper.ShowConsoleMsg("target_time_offset: " .. target_time_offset .. "\n")

  -- reaper.ShowConsoleMsg("target_time_offset: " .. target_time_offset .. "\n")
  
  reaper.SetTakeStretchMarker(take, sm_idx + 1, pos + target_time_offset)
  reaper.SetTakeStretchMarkerSlope(take, sm_idx, 0)
  -- reaper.SetTakeStretchMarkerSlope(take, sm_idx + 1, slope)
  


end

-- the function of GetSMData and ApplySMData and slope calculation method from https://github.com/ReaTeam/Doc/blob/master/X-Raym_Working%20with%20Stretch%20Markers%20ReaScript%20API.md
function GetSMData( take, i )
    local slope = reaper.GetTakeStretchMarkerSlope( take, i )
    local retval, pos_a, srcpos_a = reaper.GetTakeStretchMarker( take, i )
    local retval, pos_b, srcpos_b = reaper.GetTakeStretchMarker( take, i+1 )
    local len_init = srcpos_b - srcpos_a
    local len_after = pos_b - pos_a
    local rate_right = (len_init / len_after) * (1+slope)
    local rate_left = (len_init / len_after) * (1-slope)
    -- reaper.ShowConsoleMsg("i: " .. i .. " rate_right: " .. rate_right .. " rate_left: " .. rate_left .. "\n")
    local sm = {
      pos = pos_a,
      srcpos = srcpos_a,
      len_init = len_init,
      len_after = len_after,
      rate_right = rate_right,
      rate_left = rate_left,
      slope = slope
    }
    return sm
end

function ApplySMData(take, SMs)
  local count =  reaper.GetTakeNumStretchMarkers( take )
  reaper.DeleteTakeStretchMarkers( take, 0,  reaper.GetTakeNumStretchMarkers( take ) ) -- Remove existing SM
  for i, sm in ipairs(SMs) do
    if sm.new_pos == nil then
      sm.new_pos = sm.pos
      sm.new_slope = sm.slope
    end
    local id = reaper.SetTakeStretchMarker( take, -1, sm.new_pos, sm.srcpos ) -- .new_pos value
    if id >= 1 then -- If there is a previous SM, then we can add a slope to the previous marker
      reaper.SetTakeStretchMarkerSlope( take, id-1, SMs[i-1].new_slope ) -- .new_slope value.
    end
  end
  reaper.Undo_OnStateChange("Apply SM")
end

function AdjustPrevSMSlope(delta_value)
  reaper.ShowConsoleMsg('adjusting slope at rating: ' .. delta_value .. "\n")
  local item = reaper.GetSelectedMediaItem(0, 0)
  local take = reaper.GetActiveTake(item)
  add_SM_at_start_end_of_take_item(take)
  reaper.ShowConsoleMsg('n_stretch_markers: ' .. reaper.GetTakeNumStretchMarkers(take) .. "\n")
  local sm_idx, sm_pos = get_stretch_marker_at_edit_cursor()

  local sm_head_prev = GetSMData(take, sm_idx - 1)
  local sm_body_prev = GetSMData(take, sm_idx)
  local sm_tail_prev = GetSMData(take, sm_idx + 1)

  AdjustSM(delta_value)
  local sm_head_post = GetSMData(take, sm_idx - 1)
  local sm_body_post = GetSMData(take, sm_idx)
  local sm_tail_post = GetSMData(take, sm_idx + 1)

  local head_left_rate = sm_head_prev.rate_left
  -- local head_new_slope = 1 - sm_head_post.len_after / sm_head_prev.len_after + sm_head_prev.slope
  local head_new_slope = 1 - head_left_rate / (sm_head_post.len_init/sm_head_post.len_after)
  reaper.SetTakeStretchMarkerSlope(take, sm_idx-1, head_new_slope)
  local sm_head_ppost = GetSMData(take, sm_idx - 1)
  -- reaper.ShowConsoleMsg("head_rate_left: " .. sm_head_ppost.rate_left .. "head_rate_right: " .. sm_head_ppost.rate_right .. "\n")

  local body_rate_left = sm_head_ppost.rate_right
  local body_slope = head_new_slope
  local body_new_len_after = sm_body_post.len_init/(body_rate_left / (1-body_slope))
  local body_pos_b = sm_body_post.pos + body_new_len_after
  reaper.SetTakeStretchMarker(take, sm_idx+1, body_pos_b)
  reaper.SetTakeStretchMarkerSlope(take, sm_idx, body_slope)
  local sm_tail_ppost = GetSMData(take, sm_idx + 1)

  local offset_head2body = sm_body_post.pos - sm_body_prev.pos
  local offset_body2tail = sm_tail_ppost.pos - sm_tail_post.pos
  local offset_head2tail = offset_head2body + offset_body2tail
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  reaper.SetMediaItemLength(item, item_length + offset_head2tail, false)
  local n_take_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  for i = sm_idx+2, n_take_stretch_markers-1 do
    local rv, pos, srcpos = reaper.GetTakeStretchMarker(take, i)
    -- reaper.ShowConsoleMsg("adding offset: " .. offset_head2tail .. "to pos: " .. pos .. "\n")
    if i == sm_idx + 2 then
      reaper.SetTakeStretchMarker(take, i, pos + offset_body2tail)
    else
      reaper.SetTakeStretchMarker(take, i, pos + offset_body2tail)
    end
  end




end

function AdjustPrevSMSlope_bak(delta_value)
  reaper.ShowConsoleMsg('adjusting slope at rating: ' .. delta_value .. "\n")
  local item = reaper.GetSelectedMediaItem(0, 0)
  local take = reaper.GetActiveTake(item)
  add_SM_at_start_end_of_take_item(take)
  reaper.ShowConsoleMsg('n_stretch_markers: ' .. reaper.GetTakeNumStretchMarkers(take) .. "\n")
  local sm_idx, sm_pos = get_stretch_marker_at_edit_cursor()
  local rv, init_pos, init_src_pos = reaper.GetTakeStretchMarker(take, sm_idx)
  AdjustSM(delta_value)
  local rv,  prev_pos, prev_srcpos = reaper.GetTakeStretchMarker(take, sm_idx - 1)
  local rv,  pos, srcpos = reaper.GetTakeStretchMarker(take, sm_idx)
  local time_offset = pos - prev_pos
  local init_offset = init_pos - prev_pos


  local prev_init_slope = reaper.GetTakeStretchMarkerSlope(take, sm_idx-1)
  local slope = 1 - time_offset / init_offset + prev_init_slope
  -- local new_slope = 

  -- item len follow last stretch marker
  local i, take_sm_pos_end = get_stretch_marker_at_take_source_end_pos(take)
  if i == nil then
    reaper.MB("No stretch marker at take source end", "Error", 0)
    return
  end

  reaper.ShowConsoleMsg("prev_init_slope: " .. prev_init_slope .. "\n")
  reaper.ShowConsoleMsg("slope: " .. slope .. "\n")
  reaper.SetTakeStretchMarkerSlope(take, sm_idx-1, slope)

  -- local right_rate = init_offset / time_offset * (1+ slope)
  local prev_src_offset = init_src_pos - prev_srcpos
  local prev_stretch_rate = prev_src_offset / time_offset + slope
  -- reaper.ShowConsoleMsg("prev_stretch_rate: " .. prev_stretch_rate .. "\n")
  local right_rate = init_offset / time_offset
  -- reaper.ShowConsoleMsg("right_rate: " .. right_rate .. "\n")
  -- take_next_stretch_marker_follow_rate(take, sm_idx, prev_stretch_rate)
  local n_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  reaper.ShowConsoleMsg("n_stretch_markers: " .. n_stretch_markers .. "\n")

  local rv,  prev_pos_postadj, prev_srcpos_postadj = reaper.GetTakeStretchMarker(take, sm_idx - 1)
  local rv,  pos_postadj, srcpos_postadj = reaper.GetTakeStretchMarker(take, sm_idx)
  local time_offset_postadj = (pos_postadj - prev_pos_postadj) - (init_pos - prev_pos)
  reaper.ShowConsoleMsg("time_offset_postadj: " .. time_offset_postadj .. "\n")
  -- reaper.ShowConsoleMsg('take_sm_pos_end: ' .. take_sm_pos_end .. "\n")
  local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  -- reaper.ShowConsoleMsg("take_sm_pos_end: " .. take_sm_pos_end .. "\n")
  reaper.SetMediaItemLength(item, item_length + time_offset_postadj, false)
  local n_take_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
  for i = sm_idx+1, n_take_stretch_markers - 1 do
    local rv, pos, srcpos = reaper.GetTakeStretchMarker(take, i)
    reaper.SetTakeStretchMarker(take, i, pos + time_offset_postadj)
  end
  -- reaper.SetEditCurPos(reaper.GetCursorPosition() + time_offset_postadj, true, false)
  -- for i = sm_idx, n_stretch_markers - 2 do
  -- for i = sm_idx, sm_idx + 1 do
  --   reaper.ShowConsoleMsg("i: " .. i .. "\n")
  --   -- take_next_stretch_marker_follow_rate(take, i, prev_stretch_rate)
  --   take_next_stretch_marker_follow_slope(take, i, prev_stretch_rate, slope)

  -- end
end

function AdjustSMPrevSMSlopeZoomDep(lambda)
  local pixel_per_second = reaper.GetHZoomLevel()
  -- reaper.ShowConsoleMsg("pixel_per_second: " .. pixel_per_second .. "\n")
  local delta_value = lambda / pixel_per_second
  -- reaper.ShowConsoleMsg("delta_value: " .. delta_value .. "\n")
  AdjustPrevSMSlope(delta_value)
end