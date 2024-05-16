local script_path = debug.getinfo(1).source:match(("@?(.*%s)"):format(package.config:sub(1, 1)))
dofile(script_path .. "stretch_marker_adjuster.lua")
dofile(script_path .. "configs.lua")

AdjustSM(SM_STEP_SIZE)