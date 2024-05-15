local script_path = nil
if reaper.GetOS() ==  "Win32" or reaper.GetOS() == "Win64" then
    script_path = debug.getinfo(1).source:match("@?(.*\\)")
else
    script_path = debug.getinfo(1).source:match("@?(.*/)")
end
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
        AdjustSM(SM_STEP_SIZE)
    end
    if val < 0 then
        -- reaper.ShowConsoleMsg('val: ' .. val .. '\n')
        AdjustSM(-SM_STEP_SIZE)
    end
end