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
        AdjustSMZoomDep(SM_STEP_SIZE_ZOOM_DEP_LAMBDA)
    end
    if val < 0 then
        AdjustSMZoomDep(-SM_STEP_SIZE_ZOOM_DEP_LAMBDA)
    end
end