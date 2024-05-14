local script_path = debug.getinfo(1).source:match("@?(.*/)")
dofile(script_path .. "stretch_marker_adjuster.lua")

AdjustSMZoomDep(50)
