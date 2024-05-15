local script_path = nil
if reaper.GetOS() ==  "Win32" or reaper.GetOS() == "Win64" then
    script_path = debug.getinfo(1).source:match("@?(.*\\)")
else
    script_path = debug.getinfo(1).source:match("@?(.*/)")
end
dofile(script_path .. "stretch_marker_adjuster.lua")
dofile(script_path .. "configs.lua")

AdjustSM(SM_STEP_SIZE)