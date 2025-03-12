-- seconds on how much the SM is moved for every time the script is executed
SM_STEP_SIZE = 0.01
-- SM_STEP_SIZE_ZOOM_DEP_LAMBDA / zoom level(pixel per seconds) = seconds on how much the SM is moved for every time the script is executed
-- refer to https://www.extremraym.com/cloud/reascript-doc/#GetHZoomLevel for zoom level calculation
SM_STEP_SIZE_ZOOM_DEP_LAMBDA = 5

-- slope value on how much the SM is moved for every time the script is executed, 
-- the calculation is kinda complex, plz do some test to get desired value
SM_SLOPE_STEP_SIZE = 0.05
SM_SLOPE_STEP_SIZE_ZOOM_DEP_LAMBDA = 5