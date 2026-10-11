return {

    nav = {
        TARGET = { x = -2589, y = 63, z = 9965 },  -- rev65: same droneship as landing.lua (was z=13367)
        GRAVITY_TABLE = { {0,11}, {2000,11}, {2017,10.9408}, {2500,9.1707}, {3000,7.3363}, {4000,3.6688}, {5000,0.0069} },
    },

    pose = { UP_AXIS = "+Y", FORWARD_AXIS = "+Z", RIGHT_AXIS = "+X" },

    sign = {
        STEER_RIGHT = 1,
        STEER_FWD = -1,
        AXIS_SWAP_GIMBAL = true,
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
        TORQUE_REF_LEVEL = 1.9,
        TORQUE_IDLE_LEVEL = 2,
        TORQUE_SCALE_MIN = 0.3,
        TORQUE_SCALE_MAX = 1.15,
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
        I_MIN_LEVEL = 1.5,
    },

    thrust = {
        LIFTOFF_LEVEL = 3,
        ASCENT_LEVEL = 3,
        TAPER_MIN_LEVEL = 2,
    },

    ascent = {
        DELUGE_LEAD_TIME = 0,
        IGNITION_RAMP_TIME = 0.5,
        CLAMP_RELEASE_FRAC = 0.60,
        CLEAR_TOWER_ALT = 20,
        VERT_CLIMB_ALT = 300,   -- rev65: back to the rev63 profile (rev64 gave vH=115 m/s at separation, landing brakes only 2.5 m/s2)
        TURN_RAMP_ALT = 2500,   -- rev65: tilt ramps over 3 km (rev63 value, gave vH ~55 m/s at separation)
        TURN_TILT_MAX_DEG = 25,   -- rev65: rev63 value. Droneship is only ~1.5 km from the pad now, no need for a big lean
        OPEN_LOOP_TURN = true,        -- rev63: false = old zero-effort-miss guidance on the droneship
        TURN_MIN_REMAINING = 100,
        SEP_ALT = 4550,
        SEP_ALT_MAX = 5000,
        SEP_RADIUS_WARN = 150,
        TAPER_ALT = 600,
        MECO_RAMP_TIME = 1.0,
        COAST_SEP_VS = 3.0,
        COAST_MAX_TIME = 60,
        STAGE_SEP_PULSE_TIME = 0.5,
        SEP_SETTLE_TIME = 2.0,        -- s between releasing stage_sep and starting landing.lua (neutral controls)
        STAGE2_IGNITE_DELAY = 1.0,    -- s after release before IGNITE is sent to stage 2 (repeats every 0.3 s until SEP_SETTLE_TIME)
        TILT_ABORT_DEG = 45,
        TILT_RECOVER_MARGIN = 5,
        HARD_ABORT_TILT_DEG = 60,
        HARD_ABORT_YAW_RATE_DPS = 45,
        VS_TARGET = 60,
        VS_START = 25,
        VS_SLOPE = 0.12,
        VS_TAPER_FRAC = 0.4,
        BASE_LEVEL = 3,
        VS_KP = 0.12,
        VS_KI = 0.05,
        VS_I_MIN = -1,
        VS_I_MAX = 5,
        LEVEL_MIN = 0.6,  -- hover at 4000 m is ~0.7
        LEVEL_MAX = 8,
        LEVEL_HYST = 0.7,
        LEVEL_SLEW = 3.0,
        T_PER_LEVEL = 5.6,  -- accel per level, all 9 engines
        NAV_VH_MAX = 35,
        NAV_KV = 0.02,
        NAV_TGO_MIN = 8,
        NAV_TGO_VS_MIN = 20,
        NAV_LEAN_SLEW = 0.06,
        NAV_VF_END = 0,              -- was 10: arrive OVER the droneship with ~0 sideways speed at separation
        NAV_TB_MIN = 15,
        NAV_G_MIN = 3,
        PROGRADE_BLEND = 0,          -- was 0.85: nose-along-velocity fed back into itself and kept accelerating sideways
        PROGRADE_MIN_SPEED = 25,
        NAV_AIM_BIAS = 0,
    },

    rcs = {
        ENABLE = true,
        KP = 6.0,
        KD = 18.0,
        LIMIT = 15,
        DEADZONE = 0.12,
        SLEW_RATE = 15,
    },

    flight = {
        LOOP_PERIOD = 0.05,
        DRY_RUN = false,
        GRAVITY = 11,
    },

    -- wireless link to the stage 2 computer (needs a wireless/ender modem on BOTH computers)
    stage2 = {
        PROTOCOL = "f9_stage2",
        COMPUTER_ID = nil,   -- set to the stage 2 computer id to address it directly; nil = broadcast
    },

    log = { FILE = "launch.log" },

    telemetry = {
        ENABLE = false,
        RELAY_HOST = "127.0.0.1:8124",
        RELAY_PATH = "/stage1",
        SEND_INTERVAL = 0.2,
        RECONNECT_INTERVAL = 5.0,
        LIT_THRESHOLD = 0.05,
    },

    link = {
        gas_centre    = { "copycats:copycat_slope",              "tfmg:aluminum_frame"        },
        gas_north     = { "minecraft:candle",                    "minecraft:white_candle"     },
        gas_south     = { "create:mechanical_bearing",           "tfmg:electromagnetic_coil"  },
        gas_west      = { "minecraft:heavy_weighted_pressure_plate", "minecraft:redstone_ore" },
        gas_east      = { "minecraft:loom",                      "minecraft:white_bed"        },
        gas_southwest = { "minecraft:kelp",                      "minecraft:spruce_trapdoor"  },
        gas_southeast = { "minecraft:sea_lantern",               "minecraft:composter"        },
        gas_northwest = { "minecraft:comparator",                "minecraft:decorated_pot"    },
        gas_northeast = { "minecraft:sand",                      "minecraft:pointed_dripstone"},

        ENGINES = { "centre", "north", "south", "west", "east", "northeast", "southeast", "southwest", "northwest" },

        rcs_to_north = { "create:stockpile_switch", "create:golden_sheet" },
        rcs_to_south = { "create:stockpile_switch", "create:andesite_table_cloth" },
        rcs_to_west  = { "create:stockpile_switch", "create:cart_assembler" },
        rcs_to_east  = { "create:stockpile_switch", "create:crushed_raw_platinum" },

        gimbal_to_north = { "minecraft:flower_pot",       "minecraft:cauldron"  },
        gimbal_to_south = { "minecraft:armor_stand",      "minecraft:chicken"   },
        gimbal_to_west  = { "minecraft:totem_of_undying", "minecraft:bone_meal" },
        gimbal_to_east  = { "minecraft:breeze_rod",       "minecraft:brush"     },

        clamp          = { "minecraft:white_concrete",        "create:cardboard_leggings" },
        stage_sep      = { "create:mechanical_press",         "minecraft:stick"           },
        launch_trigger = { "minecraft:redstone_torch",        "minecraft:lever"           },
        deluge         = { "minecraft:stripped_dark_oak_wood","create:tree_fertilizer"    },
        liftoff_effect = { "minecraft:name_tag",              "minecraft:deepslate_copper_ore" },
        gyro           = { "minecraft:stone",                 "minecraft:trapped_chest"   },
    },
}