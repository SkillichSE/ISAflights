return {
    PROTOCOL = "f9_stage2",      -- stage 1 -> stage 2 (same as stage2.PROTOCOL in launch_config.lua)
    STAGE1_ID = nil,             -- stage 1 computer id; nil = accept any
    PAYLOAD_PROTOCOL = "f9_payload",  -- stage 2 -> docking craft (same as config.launch_protocol in 123/config.lua)

    -- redstone_link pairs that light stage 2 engines (fill in from your build)
    ENGINES = {
        { "create:brown_toolbox", "simulated:white_nameplate" },
    },
    -- gimbal, same naming as stage 1
    GIMBAL = {
        south = { "simulated:white_nameplate", "create:hand_crank" },
        north = { "create:hand_crank", "simulated:white_nameplate" },
        west  = { "create:hand_crank", "create:hand_crank" },
        east  = { "simulated:white_nameplate", "simulated:white_nameplate" },
    },
    IGNITE_LEVEL = 15,           -- only used as a fallback now, the level comes from guidance
    LOG = "stage2.log",

    LOOP_PERIOD = 0.05,
    DRY_RUN = false,
    LOG_INTERVAL = 1.0,

    pose = { UP_AXIS = "+Y", FORWARD_AXIS = "+Z", RIGHT_AXIS = "+X" },

    sign = {
        STEER_RIGHT = 1,
        STEER_FWD = -1,
        AXIS_SWAP_GIMBAL = true,
    },

    -- where the station is. Same numbers as 123/target.txt. They are sent to the craft in START,
    -- so this is the single place to change them.
    station = { x = -856, y = 13781, z = 9776, ax = 0, ay = 0, az = 1 },
    APPROACH_DISTANCE = 50,      -- same as config.approach_distance on the craft; stage 2 aims at the hold point

    nav = {
        PAD_Y = 63,              -- same zero as launch_config nav.TARGET.y
        GRAVITY_TABLE = { {0,11}, {2000,11}, {2017,10.9408}, {2500,9.1707}, {3000,7.3363}, {4000,3.6688}, {5000,0.0069} },

        V_CRUISE = 25,           -- m/s toward the hold point. The craft has to brake from this, keep it modest
        KV = 0.5,                -- 1/s, thrust accel per m/s of velocity error
        A_MAX = 4,               -- m/s2 cap on the velocity-error part (keeps burns long enough to steer)
        T_PER_LEVEL = 2.0,       -- m/s2 per redstone level, FIRST GUESS. Measured live after ~1 s, check "tEst" in stage2.log
        EST_WINDOW = 0.8,        -- s per thrust measurement
        LEVEL_FIRST = 3,         -- level cap until the first thrust measurement is in
        LEVEL_MIN = 0.5,         -- fractional levels are dithered between integers
        LEVEL_MAX = 15,
        TILT_MAX_DEG = 30,       -- never lean the stage more than this to steer
        LEAN_SLEW = 0.12,        -- lean change per second (sin units, ~7 deg/s)

        LAT_TOL = 0.6,           -- m/s sideways speed allowed at cutoff (velocity api is coarse, ~0.7 steps)
        ALONG_TOL = 1.5,         -- m/s below V_CRUISE still counts as reached
        DV_HOLD_TIME = 1.0,      -- both must hold this long
        V_ABS_MAX = 45,          -- m/s along the line: cut off here even if sideways speed is not fixed yet
        MIN_CUTOFF_ALT = 5100,   -- never cut off inside the gravity zone, the coast would curve
        BURN_MAX_TIME = 120,     -- s, cut off anyway (if above MIN_CUTOFF_ALT)
        BURN_HARD_TIME = 300,    -- s, give up
        NOATT_CUT_TIME = 2.0,    -- s without attitude/velocity while burning, then engine off

        HARD_ABORT_TILT_DEG = 60,
        HARD_ABORT_YAW_RATE_DPS = 45,
    },

    separation = {
        -- redstone_link pair that releases the craft from stage 2. FILL THIS IN. nil = no physical release,
        -- only START is sent (the log says so loudly).
        PAYLOAD_SEP = { "rocketnautics:rcs_thruster", "minecraft:white_concrete" },  -- Dragon release
        MODE = "pulse",          -- "release": held at 15 from start, set to 0 to separate (like stage_sep on stage 1)
                                 -- "pulse":   0 normally, 15 for PULSE_TIME to separate
        PULSE_TIME = 0.5,
        SETTLE_TIME = 1.5,       -- s between release and START (stages need to part)
        PAYLOAD_ID = nil,        -- craft computer id; nil = broadcast

        -- how far from the hold point the craft is released (see guidance.sepRange)
        A_BRAKE = 2.0,           -- m/s2, craft soft braking (BRAKE_LVL 5 * 0.47)
        FLIP_T = 9,              -- s, craft flip time (P.FLIP_T)
        SELFCHECK_T = 12,        -- s, craft selfCheck() before it starts flying
        MARGIN = 150,
        MIN_RANGE = 300,
        MAX_RANGE = 2500,
        COAST_MAX_TIME = 1200,   -- s, release anyway

        START_PERIOD = 0.5,
        START_TIMEOUT = 20,      -- s waiting for the craft ACK
        ABORT_RELEASE = true,    -- stage 2 aborted: still release the craft so it can try on its own
        ABORT_RELEASE_DELAY = 3,
    },

    attitude = {
        TILT_KP = 4.0,
        TILT_KD = 12.0,
        TILT_KI = 0.8,
        I_LIMIT = 1.0,
        RATE_SMOOTH = 0.55,
        MAX_RATE_RAW = 6.0,
        OUTPUT_LIMIT = 15,
        EFFORT_SLEW_RATE = 10,
        TORQUE_SCALE = 1.0,
        TORQUE_REF_LEVEL = 6,    -- gimbal torque follows thrust: gains are scaled by REF/level
        TORQUE_IDLE_LEVEL = 2,
        TORQUE_SCALE_MIN = 0.5,
        TORQUE_SCALE_MAX = 1.5,
        GAIN_TILT_START = 3,
        GAIN_TILT_FULL = 12,
        GAIN_MULT_EXTRA = 0.4,
        RATE_LEAD = 0.7,
        SPIN_LOCK_DPS = 15,
        SPIN_KD_MULT = 2.5,
        I_LEAK_TAU = 15,
        I_QUASI_LEAN = 0.12,
        I_QUASI_RATE = 0.12,
        I_QUASI_YAW_DPS = 8,
    },
}