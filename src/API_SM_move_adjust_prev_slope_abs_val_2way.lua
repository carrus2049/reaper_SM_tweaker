local script_path = debug.getinfo(1).source:match(("@?(.*%s)"):format(package.config:sub(1, 1)))
dofile(script_path .. "stretch_marker_adjuster.lua")
dofile(script_path .. "configs.lua")

local nv, _, _, _, _, _, val = reaper.get_action_context()

REVERT = false
if REVERT then
    val = -val
end
if nv then
    if val > 0 then
        -- reaper.ShowConsoleMsg('val: ' .. val .. '\n')
        AdjustPrevSMSlope(SM_SLOPE_STEP_SIZE)
    end
    if val < 0 then
        -- reaper.ShowConsoleMsg('val: ' .. val .. '\n')
        AdjustPrevSMSlope(-SM_SLOPE_STEP_SIZE)
    end
end