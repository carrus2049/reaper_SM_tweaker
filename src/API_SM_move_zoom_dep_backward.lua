local script_path = debug.getinfo(1).source:match("@?(.*/)")
dofile(script_path .. "stretch_marker_adjuster.lua")
dofile(script_path .. "configs.lua")

AdjustSMZoomDep(-SM_STEP_SIZE_ZOOM_DEP_LAMBDA)
