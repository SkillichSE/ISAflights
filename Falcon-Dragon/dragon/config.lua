-- config.lua
-- coordinates and vectors for the ship and station

local config = {}

-- axis sign fixes, yaw -1 if the ship spins in circles on yaw
config.axis_calibration = {
    x = 1, y = 1, z = 1,
    pitch = 1,
    yaw = -1,
    roll = 1,
}

-- station hatch coordinates
config.target = {
    x = 1870,
    y = 13554,
    z = 20332,
}

-- unit vector the ship flies along on final approach
config.approach_vector = {
    x = 1,
    y = 0,
    z = 20332,
}

-- distance from the hatch to the hold point
config.approach_distance = 50

-- hatch is the top of the pc, main thrust direction
config.hatch_local_axis = {
    x = 1870,
    y = 1,
    z = 20332,
}

-- docking tolerance in blocks
config.tolerance = 1

config.start_altitude = 10000
config.target_altitude = 13554

-- thrust 0-15 per flight phase
config.power_ascent = 15
config.power_coarse = 10
config.power_fine = 6
config.power_final = 2

return config