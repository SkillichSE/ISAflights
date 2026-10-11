local CONFIG = {
    nav = {
        TARGET = { x = -2589, y = 64, z = 9965 },  -- pad (droneship deck)
        DECK_ALT = 24.8,  -- pose origin is the rocket centre, not the feet; tune if ENGINES OFF fires early/late
    },
    pose = { UP_AXIS = "+Y", FORWARD_AXIS = "+Z", RIGHT_AXIS = "+X" },
    sign = {
        STEER_RIGHT =  1,
        STEER_FWD   = -1,
        -- measured: gimbal is rotated 90deg vs RCS, so its axes are swapped
        AXIS_SWAP_GIMBAL = true,
    },
    attitude = {
        -- loop really runs ~3-5 Hz, gains are tuned for that
        TILT_KP = 4.0,
        TILT_KD = 12.0,
        TILT_KI = 0.8,
        I_LIMIT = 1.0,
        RATE_SMOOTH = 0.55,
        ANGVEL_FRAME = "body",  -- raw angular velocity is in body frame
        OUTPUT_LIMIT = 15,
        EMERGENCY_TILT = 12,
        EMERGENCY_EXIT_TILT = 9,
        TILT_SAFE_START = 4,
        HIGH_THRUST_LEAN_CUT = 0.35,
        MIN_LEAN = 2,
        TORQUE_SCALE_MIN = 0.45,
        TORQUE_SCALE_MAX = 1.15,
        EFFORT_SLEW_RATE = 10,
        EMERGENCY_SLEW_RATE = 30,
        EMERGENCY_ENTRY_SLEW_RATE = 4,
        EMERGENCY_ENTRY_RAMP_TIME = 0.35,
        EMERGENCY_GAIN_MULT = 4.2,
        MAX_RATE_RAW = 6.0,
        EMERGENCY_RATE = 1.0,
        EMERGENCY_YAW_RATE = 35.0,
        YAW_SAFE_START = 12.0,
        EMERGENCY_TIMEOUT = 7.0,
        STUCK_CUSHION_THRUST = 9,
        CUSHION_RESTORE_TILT_CEILING = 20,
        CUSHION_RESTORE_RATE_CEILING = 0.6,
        CUSHION_RESTORE_RATE_TAPER_START = 0.25,
        CUSHION_RESTORE_TAPER_START = 12,
        POST_EMERGENCY_RAMP = 3.0,
        CUSHION_RECOVER_TILT = 6,
        CUSHION_RECOVER_YAW = 5,
        CUSHION_RECOVER_RATE = 0.3,
        CUSHION_RECOVER_HOLD = 1.5,
        YAW_KD = 8.0,
        -- yaw RCS ring pushes one way only. -1 = positive feedback and a tumble, don't flip
        YAW_SIGN = 1,
        ENG_YAW_LIMIT = 0,
        ENG_YAW_FLIP = true,  -- which tangential pair fires
    },
    rcs = {
        KP = 6.0,
        KD = 18.0,
        LIMIT = 15,
        SLEW_RATE = 15,
        DEADZONE = 0.12,
    },
    guidance = {
        GRAVITY = 11,
        STABILIZE_ALT = 600,
        LANDING_BURN_ALT = 120,
        LANDING_BURN_MAX_DECEL = 3.0,
        LANDING_BURN_MARGIN = 1.3,
        LANDING_DECEL = 1.5,
        TOUCH_VS = 1.2,
        TOUCH_CUT_ALT = 3.0,
        NAV_TERMINAL_MAX_SPEED = 6,
        MAX_SPEED = 28,
        APPROACH_GAIN = 0.12,
        VEL_KP = 0.4,
        MAX_LEAN = 12,
        MAX_SAFE_VH = 12,
        DRAG = 0.09,
        SPEED_KP = 2.0,
        NAV_IN_TERMINAL = true,
        NAV_MIN_ALT = 6,
        NAV_MAX_TILT = 8,
        NAV_DEADZONE_DIST = 4,
        LANDING_DIST = 150,
        TOUCHDOWN_ALT = 8,
        MAX_DESCENT_VS = 25,
        LEAN_RAMP_TIME = 5.0,
        LEAN_SLEW_RATE = 0.10,
    },
    thrust = {
        HOVER = 8,  -- centre engine alone; real hover level drops with altitude (hoverTrim)
        HOVER_TRIM_KI  = 0.25,
        HOVER_TRIM_MIN = -8,
        HOVER_TRIM_MAX = 4,
        VS_KP = 0.7,
        ALT_KP  = 0.08,
        DESC_VS = 15,
        CEILING = 6000,
        MIN = 0, MAX = 15,
        SMOOTH = 0.2,
        FLOOR_ABOVE_GROUND = 3,
        TOUCHDOWN_CUTOFF = 0.6,
        CRUISE_IDLE = 5,
        COAST = 1.5,
        COAST_TILT_BUMP = 2.5,
        -- unused
        CENTRE_ENGINE_PN = 6000,
        OUTER_ENGINE_PN  = 3000,
    },
    legs = {
        LEGS_ALT = 100,
        LEGS_VS  = -3,
        HYSTERESIS = 30,
        FORCE_LANDING = 80,
    },
    touchdown_safety = {
        MAX_TILT = 20,
        MAX_VH   = 4,
    },
    flight = {
        LOOP_PERIOD = 0.05,
        DRY_RUN = false,
        PERF_LOG = true,
        DEBUG_START_PHASE = nil,
        PARALLEL_LINKS = true,
    },
    link = {
        gas_centre    = { "copycats:copycat_slope",              "tfmg:aluminum_frame"             },
        gimbal_to_north = { "minecraft:flower_pot",       "minecraft:cauldron"          },
        gimbal_to_south = { "minecraft:armor_stand",      "minecraft:chicken"           },
        gimbal_to_west  = { "minecraft:totem_of_undying", "minecraft:bone_meal"         },
        gimbal_to_east  = { "minecraft:breeze_rod",       "minecraft:brush"             },
        rcs_to_north    = { "create:stockpile_switch",    "create:golden_sheet"          },
        rcs_to_south    = { "create:stockpile_switch",    "create:andesite_table_cloth"  },
        rcs_to_west     = { "create:stockpile_switch",    "create:cart_assembler"        },
        rcs_to_east     = { "create:stockpile_switch",    "create:crushed_raw_platinum"  },
        rcs_yaw_north   = { "minecraft:white_concrete",   "create:mechanical_mixer"      },
        rcs_yaw_east    = { "minecraft:white_concrete",   "create:wooden_bracket"        },
        rcs_yaw_south   = { "minecraft:white_concrete",   "create:fluid_pipe"            },
        rcs_yaw_west    = { "minecraft:white_concrete",   "create:metal_bracket"         },
        legs            = { "minecraft:terracotta",       "minecraft:yellow_terracotta" },

        gas_north = { "minecraft:candle",                       "minecraft:white_candle"     },
        gas_south = { "create:mechanical_bearing",               "tfmg:electromagnetic_coil"  },
        gas_west  = { "minecraft:heavy_weighted_pressure_plate", "minecraft:redstone_ore"     },
        gas_east  = { "minecraft:loom",                          "minecraft:white_bed"        },
        gas_southwest = { "minecraft:kelp",    "minecraft:spruce_trapdoor"      },
        gas_southeast = { "minecraft:sea_lantern", "minecraft:composter"     },
        gas_northwest = { "minecraft:comparator", "minecraft:decorated_pot" },
        gas_northeast = { "minecraft:sand",    "minecraft:pointed_dripstone" },

        eng_north_to_west  = { "minecraft:nether_sprouts",      "simulated:docking_connector" },
        eng_north_to_east  = { "minecraft:sculk_vein",          "simulated:docking_connector" },
        eng_north_to_north = { "minecraft:sniffer_egg",         "simulated:docking_connector" },
        eng_north_to_south = { "minecraft:seagrass",            "simulated:docking_connector" },

        eng_south_to_west  = { "minecraft:blackstone",          "simulated:docking_connector" },
        eng_south_to_east  = { "minecraft:magma_block",         "simulated:docking_connector" },
        eng_south_to_north = { "minecraft:crying_obsidian",     "simulated:docking_connector" },
        eng_south_to_south = { "minecraft:bone_block",          "simulated:docking_connector" },

        eng_west_to_west   = { "minecraft:cherry_leaves",       "simulated:docking_connector" },
        eng_west_to_east   = { "minecraft:enchanting_table",    "simulated:docking_connector" },
        eng_west_to_north  = { "minecraft:bamboo_hanging_sign", "simulated:docking_connector" },
        eng_west_to_south  = { "minecraft:decorated_pot",       "simulated:docking_connector" },

        eng_east_to_west   = { "minecraft:loom",                "simulated:docking_connector" },
        eng_east_to_east   = { "minecraft:armor_stand",         "simulated:docking_connector" },
        eng_east_to_north  = { "minecraft:ladder",              "simulated:docking_connector" },
        eng_east_to_south  = { "minecraft:birch_log",           "simulated:docking_connector" },

        OUTER_ENGINES = { "north", "south", "west", "east" },
    },
    log = { EVERY = 6, FILE = "falcon9.log", VERBOSE_TILT = 2.0, RING = 8, BYTE_BUDGET = 700000 },
    telemetry = {
        ENABLE = true,
        RELAY_HOST = "127.0.0.1:8124",
        RELAY_PATH = "/stage1",
        SEND_INTERVAL = 0.2,
        RECONNECT_INTERVAL = 5.0,
        LIT_THRESHOLD = 0.05,
    },
    debug = {
        AXIS_TEST = "both",
    },
}
local C = CONFIG
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
local function round(v) return math.floor(v + 0.5) end
local function len2(x, z) return math.sqrt(x*x + z*z) end
local function angleDiff(a, b) return ((a - b + 180) % 360) - 180 end
local function dirOf(deg) local r = math.rad(deg) return math.sin(r), math.cos(r) end
local function extractQuaternion(q)
    if type(q) ~= "table" then return nil end
    local x, y, z, w
    if type(q.v) == "table" then
        x, y, z, w = tonumber(q.v.x), tonumber(q.v.y), tonumber(q.v.z), tonumber(q.a)
    else
        x, y, z, w = tonumber(q.x), tonumber(q.y), tonumber(q.z), tonumber(q.w)
    end
    if not (x and y and z and w) then return nil end
    local l = math.sqrt(x*x + y*y + z*z + w*w)
    if l < 1e-6 then return nil end
    return { x=x/l, y=y/l, z=z/l, w=w/l }
end
local function rotateBodyToWorld(qq, x, y, z)
    local qx, qy, qz, qw = qq.x, qq.y, qq.z, qq.w
    local tx = 2*(qy*z - qz*y)
    local ty = 2*(qz*x - qx*z)
    local tz = 2*(qx*y - qy*x)
    return x + qw*tx + (qy*tz - qz*ty),
           y + qw*ty + (qz*tx - qx*tz),
           z + qw*tz + (qx*ty - qy*tx)
end
local function axisVec(name)
    local t = { ["+X"]={1,0,0}, ["-X"]={-1,0,0}, ["+Y"]={0,1,0},
                ["-Y"]={0,-1,0}, ["+Z"]={0,0,1}, ["-Z"]={0,0,-1} }
    return t[name]
end
local function worldAxis(qq, name)
    local v = axisVec(name); if not v then return nil end
    return rotateBodyToWorld(qq, v[1], v[2], v[3])
end
local function horizUnit(x, z)
    local l = len2(x, z); if l < 1e-9 then return nil end
    return x/l, z/l, l
end
local function effectiveMaxLean(baseLean, thrustLevel)
    local frac = clamp((thrustLevel - C.thrust.HOVER) / math.max(C.thrust.MAX - C.thrust.HOVER, 1e-6), 0, 1)
    local lean = baseLean * (1 - frac * C.attitude.HIGH_THRUST_LEAN_CUT)
    return math.max(lean, C.attitude.MIN_LEAN)
end
local GH = {
    ground = C.thrust.HOVER,
    cur = nil,
    tab = {{0,11},{2000,11},{2017,10.9408},{2500,9.1707},{3000,7.3363},{4000,3.6688},{5000,0.0069}},  -- g by altitude
}
function GH.g(alt)
    alt = alt or 0
    local T = GH.tab
    if alt <= T[1][1] then return T[1][2] end
    for i = 2, #T do
        local a, b = T[i-1], T[i]
        if alt <= b[1] then return a[2] + (b[2]-a[2]) * (alt-a[1]) / (b[1]-a[1]) end
    end
    return 0
end
function GH.hover(alt) return math.max(GH.ground * GH.g(alt) / 11, 0.5) end
C.GH = GH
C.altitude = { LAT_DECEL = 2.5 }

local function torqueScale(thrustLevel)
    local t = math.max(thrustLevel, C.thrust.CRUISE_IDLE * 0.5)
    local s = clamp((GH.cur or C.thrust.HOVER) / t, C.attitude.TORQUE_SCALE_MIN, C.attitude.TORQUE_SCALE_MAX)
    return s
end
local function kpActiveFrac(angRateNow, start, ceiling)
    start = start or C.attitude.CUSHION_RESTORE_RATE_TAPER_START
    ceiling = ceiling or C.attitude.CUSHION_RESTORE_RATE_CEILING
    return 1 - clamp((angRateNow - start) / math.max(ceiling - start, 1e-6), 0, 1)
end
local prevAttitudeMode = nil
local prevRcsMode = nil
local prevEffortRight, prevEffortFwd = 0, 0
local function slewEffort(effortRight, effortFwd, rdtNow, rateOverride, mode)
    if mode and mode ~= prevAttitudeMode then
        local enteringEmergency = (mode == "emergency")
        prevAttitudeMode = mode
        if not enteringEmergency then
            prevEffortRight, prevEffortFwd = effortRight, effortFwd
            return effortRight, effortFwd
        end
    end
    if mode then prevAttitudeMode = mode end
    local rate = rateOverride or C.attitude.EFFORT_SLEW_RATE
    local maxStep = rate * rdtNow
    local dER, dEF = effortRight - prevEffortRight, effortFwd - prevEffortFwd
    effortRight = prevEffortRight + clamp(dER, -maxStep, maxStep)
    effortFwd   = prevEffortFwd   + clamp(dEF, -maxStep, maxStep)
    prevEffortRight, prevEffortFwd = effortRight, effortFwd
    return effortRight, effortFwd
end
local prevRcsRight, prevRcsFwd = 0, 0
local function slewRCS(effortRight, effortFwd, rdtNow, mode)
    if mode and mode ~= prevRcsMode then
        local enteringEmergency = (mode == "emergency")
        prevRcsMode = mode
        if not enteringEmergency then
            prevRcsRight, prevRcsFwd = effortRight, effortFwd
            return effortRight, effortFwd
        end
    end
    if mode then prevRcsMode = mode end
    local maxStep = C.rcs.SLEW_RATE * rdtNow
    local dER, dEF = effortRight - prevRcsRight, effortFwd - prevRcsFwd
    effortRight = prevRcsRight + clamp(dER, -maxStep, maxStep)
    effortFwd   = prevRcsFwd   + clamp(dEF, -maxStep, maxStep)
    prevRcsRight, prevRcsFwd = effortRight, effortFwd
    return effortRight, effortFwd
end
local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "redstone_link_bridge not found")
local sendCache = {}
local pendingLinks, pendingOrder = {}, {}
local function sendLink(pair, level)
    if C.flight.DRY_RUN then return end
    level = clamp(round(level), 0, 15)
    if sendCache[pair] == level then return end
    sendCache[pair] = level
    if C.flight.PARALLEL_LINKS then
        if pendingLinks[pair] == nil then pendingOrder[#pendingOrder + 1] = pair end
        pendingLinks[pair] = level
    else
        bridge.sendLinkSignal(pair[1], pair[2], level)
    end
end
local unpackFn = table.unpack or unpack
local function flushLinks()
    local n = #pendingOrder
    if n == 0 then return end
    local order, levels = pendingOrder, pendingLinks
    pendingOrder, pendingLinks = {}, {}
    if n == 1 then
        local pr = order[1]
        bridge.sendLinkSignal(pr[1], pr[2], levels[pr])
        return
    end
    local fns = {}
    for i = 1, n do
        local pr, lv = order[i], levels[order[i]]
        fns[i] = function() bridge.sendLinkSignal(pr[1], pr[2], lv) end
    end
    local ok, err = pcall(parallel.waitForAll, unpackFn(fns))
    if not ok then
        for i = 1, n do sendCache[order[i]] = nil end
        error(err, 0)
    end
end
local dbg = {}
local function setThrottle(level)
    local sendLevel = clamp(round(level), 0, 15)
    -- centre engine only, any outer signal adds uncommanded lift
    sendLink(C.link.gas_centre, sendLevel)
    for _, eng in ipairs(C.link.OUTER_ENGINES) do
        sendLink(C.link["gas_"..eng], 0)
    end
end
local ditherAcc = {}
local function dither(key, v)
    local acc = (ditherAcc[key] or 0) + v
    local out = math.floor(acc + 0.5)
    ditherAcc[key] = clamp(acc - out, -1, 1)
    return out
end
local function remapGimbalAxes(effortRight, effortFwd)
    if C.sign.AXIS_SWAP_GIMBAL then return effortFwd, -effortRight end
    return effortRight, effortFwd
end
local function setGimbal(effortRight, effortFwd)
    effortRight, effortFwd = remapGimbalAxes(effortRight, effortFwd)
    if C.debug.AXIS_TEST == "right_only" then effortFwd = 0 end
    if C.debug.AXIS_TEST == "fwd_only" then effortRight = 0 end
    local lim = C.attitude.OUTPUT_LIMIT
    local r = clamp(effortRight * C.sign.STEER_RIGHT, -lim, lim)
    local f = clamp(effortFwd   * C.sign.STEER_FWD,   -lim, lim)
    r = dither("gim_r", r)
    f = dither("gim_f", f)
    local east  = (r < 0) and math.abs(r) or 0
    local west  = (r > 0) and r or 0
    local north = (f < 0) and math.abs(f) or 0
    local south = (f > 0) and f or 0
    sendLink(C.link.gimbal_to_east,  east)
    sendLink(C.link.gimbal_to_west,  west)
    sendLink(C.link.gimbal_to_north, north)
    sendLink(C.link.gimbal_to_south, south)
end
local prevYawRcsEffort = 0
local function slewYawRCS(effort, rdtNow)
    local maxStep = C.rcs.SLEW_RATE * rdtNow
    local d = effort - prevYawRcsEffort
    effort = prevYawRcsEffort + clamp(d, -maxStep, maxStep)
    prevYawRcsEffort = effort
    return effort
end
local function setYawRCS(effort)
    local lim = C.rcs.LIMIT
    local e = clamp(effort * C.attitude.YAW_SIGN, -lim, lim)
    if math.abs(e) < C.rcs.DEADZONE then e = 0 end
    local mag = (e > 0) and e or 0  -- ring fires one way only
    mag = dither("yaw_rcs", mag)
    sendLink(C.link.rcs_yaw_north, mag)
    sendLink(C.link.rcs_yaw_east,  mag)
    sendLink(C.link.rcs_yaw_south, mag)
    sendLink(C.link.rcs_yaw_west,  mag)
end
local function neutralYawRCS()
    prevYawRcsEffort = 0
    sendLink(C.link.rcs_yaw_north, 0)
    sendLink(C.link.rcs_yaw_east,  0)
    sendLink(C.link.rcs_yaw_south, 0)
    sendLink(C.link.rcs_yaw_west,  0)
end
local function setEngineYaw(effort)
    local e = clamp(effort * C.attitude.YAW_SIGN, -C.attitude.ENG_YAW_LIMIT, C.attitude.ENG_YAW_LIMIT)
    if math.abs(e) < C.rcs.DEADZONE then e = 0 end
    local mag = (e < 0) and math.abs(e) or 0
    mag = dither("eng_yaw", mag)
    dbg.engYawMag = -mag
    local flip = C.attitude.ENG_YAW_FLIP
    sendLink(C.link.eng_north_to_west, flip and 0 or mag)
    sendLink(C.link.eng_east_to_north, flip and 0 or mag)
    sendLink(C.link.eng_south_to_east, flip and 0 or mag)
    sendLink(C.link.eng_west_to_south, flip and 0 or mag)
    sendLink(C.link.eng_north_to_east, flip and mag or 0)
    sendLink(C.link.eng_east_to_south, flip and mag or 0)
    sendLink(C.link.eng_south_to_west, flip and mag or 0)
    sendLink(C.link.eng_west_to_north, flip and mag or 0)
end
local function neutralEngineYaw()
    sendLink(C.link.eng_north_to_west, 0)
    sendLink(C.link.eng_east_to_north, 0)
    sendLink(C.link.eng_south_to_east, 0)
    sendLink(C.link.eng_west_to_south, 0)
    sendLink(C.link.eng_north_to_east, 0)
    sendLink(C.link.eng_east_to_south, 0)
    sendLink(C.link.eng_south_to_west, 0)
    sendLink(C.link.eng_west_to_north, 0)
end

local function neutralGimbal()
    sendLink(C.link.gimbal_to_north, 0)
    sendLink(C.link.gimbal_to_south, 0)
    sendLink(C.link.gimbal_to_west,  0)
    sendLink(C.link.gimbal_to_east,  0)
end
local function setRCS(effortRight, effortFwd)
    if math.abs(effortRight) < C.rcs.DEADZONE then effortRight = 0 end
    if math.abs(effortFwd)   < C.rcs.DEADZONE then effortFwd   = 0 end
    local lim = C.rcs.LIMIT
    local r = clamp(effortRight * C.sign.STEER_RIGHT, -lim, lim)
    local f = clamp(effortFwd   * C.sign.STEER_FWD,   -lim, lim)
    r = dither("rcs_r", r)
    f = dither("rcs_f", f)
    sendLink(C.link.rcs_to_east,  (r < 0) and math.abs(r) or 0)
    sendLink(C.link.rcs_to_west,  (r > 0) and r or 0)
    sendLink(C.link.rcs_to_north, (f < 0) and math.abs(f) or 0)
    sendLink(C.link.rcs_to_south, (f > 0) and f or 0)
end
local function neutralRCS()
    sendLink(C.link.rcs_to_north, 0)
    sendLink(C.link.rcs_to_south, 0)
    sendLink(C.link.rcs_to_west,  0)
    sendLink(C.link.rcs_to_east,  0)
end
C.flight.shutdownAll = function()
    setThrottle(0)
    neutralGimbal()
    neutralRCS()
    neutralYawRCS()
    neutralEngineYaw()
end
local legsDeployed = false
local function setLegs(deploy)
    if deploy == legsDeployed then return end
    legsDeployed = deploy
    sendLink(C.link.legs, deploy and 15 or 0)
end
local function hasSable()
    return type(sublevel) == "table" and type(sublevel.getLogicalPose) == "function"
end
local function readAttitude()
    if not hasSable() then return nil end
    local ok, pose = pcall(sublevel.getLogicalPose)
    if not ok or type(pose) ~= "table" or not pose.orientation then return nil end
    local qq = extractQuaternion(pose.orientation)
    if not qq then return nil end
    local ux, uy, uz = worldAxis(qq, C.pose.UP_AXIS)
    local fx, _, fz  = worldAxis(qq, C.pose.FORWARD_AXIS)
    local rx, _, rz  = worldAxis(qq, C.pose.RIGHT_AXIS)
    local fhx, fhz = horizUnit(fx, fz)
    local rhx, rhz = horizUnit(rx, rz)
    if not fhx or not rhx then return nil end
    local px, py, pz
    if type(pose.position) == "table" then
        px = tonumber(pose.position.x)
        py = tonumber(pose.position.y)
        pz = tonumber(pose.position.z)
    end
    return {
        qq      = qq,
        up      = { x=ux, y=uy, z=uz },
        fwd     = { x=fhx, z=fhz },
        right   = { x=rhx, z=rhz },
        heading = math.deg(math.atan2(fhx, fhz)),
        tiltDeg = math.deg(math.acos(clamp(uy, -1, 1))),
        pos     = { x=px, y=py, z=pz },
        posY    = py,
    }
end
local function readVelocity()
    if type(sublevel) ~= "table" or type(sublevel.getLinearVelocity) ~= "function" then return nil end
    local ok, v = pcall(sublevel.getLinearVelocity)
    if ok and type(v) == "table" then
        return { x=tonumber(v.x) or 0, y=tonumber(v.y) or 0, z=tonumber(v.z) or 0 }
    end
    return nil
end
local hasAngVelFn = type(sublevel) == "table" and type(sublevel.getAngularVelocity) == "function"
local function readAngularVelocity()
    if not hasAngVelFn then return nil end
    local ok, w = pcall(sublevel.getAngularVelocity)
    if ok and type(w) == "table" then
        return { x=tonumber(w.x) or 0, y=tonumber(w.y) or 0, z=tonumber(w.z) or 0 }
    end
    return nil
end
local function crossProduct(ax, ay, az, bx, by, bz)
    return ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx
end
local dt = C.flight.LOOP_PERIOD
local rdt = dt
local lastTickMs = nil
local phase = C.flight.DEBUG_START_PHASE or "DESCENT"
local poseSettled = false
local poseSettleTimer = 0
local prevWLX, prevWLZ = nil, nil
local wRateX, wRateZ = 0, 0
local iFwd, iRight = 0, 0
local prevLx, prevLz = 0, 0
local prevHeading  = nil
local yawRate      = 0
local smoothedThrust = 0
local lastTiltDeg = 0
local prevTiltDeg = 0
local hoverTrim = 0
local function landingDesVS(alt)
    local g = C.guidance
    local h = math.max((alt or 0) - g.TOUCH_CUT_ALT, 0)
    local v = math.sqrt(2 * g.LANDING_DECEL * h)
    return -clamp(v, g.TOUCH_VS, C.thrust.DESC_VS)
end
local prevAngRateNow = 0
local forceCeilingCut = false
local emergencyTimer = 0
local prevEmergencyTilt = nil
local emergencyEntryTimer = nil
local phaseTimer = 0
local touchdownTimer = 0
local enginesOff = false
local cushionMode = false
local cushionRecoverTimer = 0
local postEmergencyTimer = 0
local stall = {
    EPS_ALT = 0.05, EPS_POS = 0.05, TIMEOUT = 6.0,
    timer = 0, lastAlt = nil, lastPosX = nil, lastPosZ = nil, warned = false, emergLatched = false,
}
local logFile = require("runlog").open(C.log.FILE)
local logCount = 0
local function logLine(s)
    print(s)
    if logFile then logFile.writeLine(s); logFile.flush() end
end
logLine(("START falcon9 v9-landing  sable=%s dry=%s perflog=%s")
    :format(tostring(hasSable()), tostring(C.flight.DRY_RUN), tostring(C.flight.PERF_LOG)))
if C.debug.AXIS_TEST ~= "both" then
    logLine(("!!! WARNING: AXIS_TEST=%q -- one gimbal axis is DISABLED (diagnostic mode). Flight WILL be unstable. Set to \"both\" for real flight."):format(C.debug.AXIS_TEST))
end
local function doYaw(scale)
    setYawRCS(0)
    slewYawRCS(0, rdt)
    setEngineYaw(0)
    dbg.engYawMag = 0
    dbg.yawEffort = yawEffort
end
local function emergencyRecovery(leanRight, leanFwd, rateRight, rateFwd, att, altNow, vsNow)
    if prevAttitudeMode ~= "emergency" then
        emergencyEntryTimer = 0
    elseif emergencyEntryTimer then
        emergencyEntryTimer = emergencyEntryTimer + rdt
    end
    local entryRamp = emergencyEntryTimer and clamp(emergencyEntryTimer / C.attitude.EMERGENCY_ENTRY_RAMP_TIME, 0, 1) or 1
    local slewRate = C.attitude.EMERGENCY_ENTRY_SLEW_RATE
        + entryRamp * (C.attitude.EMERGENCY_SLEW_RATE - C.attitude.EMERGENCY_ENTRY_SLEW_RATE)
    local tilt = att.tiltDeg or 0
    local emergencyThrust = C.thrust.HOVER
    local emergencyBraking = false
    if altNow then
        local speed = math.max(-(vsNow or 0), 0)
        local brakeAlt = (speed * speed) / (2 * C.guidance.LANDING_BURN_MAX_DECEL) * C.guidance.LANDING_BURN_MARGIN
        if altNow <= math.max(C.guidance.LANDING_BURN_ALT, brakeAlt) or altNow < 100 then
            local desVS = clamp(-altNow * C.thrust.ALT_KP * 2, -C.thrust.DESC_VS, -0.3)
            local verr = desVS - (vsNow or 0)
            emergencyThrust = clamp((C.thrust.HOVER + hoverTrim) + C.thrust.VS_KP * verr, C.thrust.MIN, C.thrust.MAX)
            emergencyBraking = emergencyThrust > C.thrust.HOVER
        end
    end
    if tilt > 25 and (altNow or 0) > 30 then
        emergencyThrust = math.min(emergencyThrust, C.thrust.HOVER * 0.8)
    end
    if (vsNow or 0) > 0.5 then
        emergencyThrust = C.thrust.MIN
        emergencyBraking = false
    end
    local lim = C.attitude.OUTPUT_LIMIT * 0.6
    local scale = torqueScale(emergencyThrust)
    local leanMag = math.sqrt(leanRight*leanRight + leanFwd*leanFwd)
    local divergeRate = 0
    if leanMag > 1e-6 then
        divergeRate = math.max(0, (rateRight*leanRight + rateFwd*leanFwd) / leanMag)
    end
    local frameSpinRate = divergeRate
    local kpActive = kpActiveFrac(frameSpinRate, 0.25, 0.7)
    local iAuthority = emergencyThrust >= C.thrust.COAST_TILT_BUMP
    if iAuthority then
        local kiScale = (emergencyThrust >= C.thrust.HOVER * 0.8) and 1.0 or 0.45
        iRight = clamp(iRight + kiScale * (0 - leanRight)*rdt, -C.attitude.I_LIMIT, C.attitude.I_LIMIT)
        iFwd   = clamp(iFwd   + kiScale * (0 - leanFwd  )*rdt, -C.attitude.I_LIMIT, C.attitude.I_LIMIT)
    end
    scale = math.max(scale, 0.7)
    local emergP = C.attitude.TILT_KP * C.attitude.EMERGENCY_GAIN_MULT * kpActive
    local emergD = C.attitude.TILT_KD
    if att.tiltDeg < 25 then
        emergD = emergD * 1.8
        emergP = emergP * 0.7
    end
    local rawEffortRight = clamp(scale * (-emergP*leanRight - emergD*rateRight + C.attitude.TILT_KI*iRight), -lim, lim)
    local rawEffortFwd   = clamp(scale * (-emergP*leanFwd   - emergD*rateFwd   + C.attitude.TILT_KI*iFwd),   -lim, lim)
    if att.tiltDeg > 20 then
        local boost = clamp((att.tiltDeg - 20) / 25, 0, 1) * lim * 0.55
        local leanMag = math.sqrt(leanRight*leanRight + leanFwd*leanFwd)
        if leanMag > 1e-4 then
            rawEffortRight = clamp(rawEffortRight - boost * (leanRight / leanMag), -lim, lim)
            rawEffortFwd   = clamp(rawEffortFwd   - boost * (leanFwd   / leanMag), -lim, lim)
        end
    end
    local effortRight, effortFwd = slewEffort(rawEffortRight, rawEffortFwd, rdt, slewRate, "emergency")
    setGimbal(effortRight, effortFwd)
    local savedYawKd = C.attitude.YAW_KD
    C.attitude.YAW_KD = C.attitude.YAW_KD * 1.4
    doYaw(scale)
    C.attitude.YAW_KD = savedYawKd
    local rawRcsRight = clamp(-C.rcs.KP*C.attitude.EMERGENCY_GAIN_MULT*kpActive*leanRight - C.rcs.KD*rateRight, -C.rcs.LIMIT, C.rcs.LIMIT)
    local rawRcsFwd   = clamp(-C.rcs.KP*C.attitude.EMERGENCY_GAIN_MULT*kpActive*leanFwd   - C.rcs.KD*rateFwd,   -C.rcs.LIMIT, C.rcs.LIMIT)
    if att.tiltDeg > 20 then
        local boost = clamp((att.tiltDeg - 20) / 25, 0, 1) * C.rcs.LIMIT * 0.55
        local leanMag = math.sqrt(leanRight*leanRight + leanFwd*leanFwd)
        if leanMag > 1e-4 then
            rawRcsRight = clamp(rawRcsRight - boost * (leanRight / leanMag), -C.rcs.LIMIT, C.rcs.LIMIT)
            rawRcsFwd   = clamp(rawRcsFwd   - boost * (leanFwd   / leanMag), -C.rcs.LIMIT, C.rcs.LIMIT)
        end
    end
    local rcsRight, rcsFwd = slewRCS(rawRcsRight, rawRcsFwd, rdt, "emergency")
    setRCS(rcsRight, rcsFwd)
    setThrottle(emergencyThrust)
    dbg.note = "EMERGENCY"
    dbg.slewMode = "emergency"
    dbg.torqueScale = scale
    dbg.effortRawFwd, dbg.effortRawRight = rawEffortFwd, rawEffortRight
    dbg.effortFwd, dbg.effortRight = effortFwd, effortRight
    dbg.rcsRawFwd, dbg.rcsRawRight = rawRcsFwd, rawRcsRight
    dbg.rcsFwd, dbg.rcsRight = rcsFwd, rcsRight
    dbg.desFwd, dbg.desRight = 0, 0
    dbg.thrustOut = emergencyThrust
    dbg.thrustReason = emergencyBraking and "EMERGENCY-brake-floor" or "EMERGENCY-hover"
    dbg.tiltSafeFrac = 0
    dbg.iFwd, dbg.iRight = iFwd, iRight
    if not (prevEmergencyTilt and att.tiltDeg < prevEmergencyTilt - 0.05) then
        emergencyTimer = emergencyTimer + rdt
    end
    prevEmergencyTilt = att.tiltDeg
end
local function controlThrust(vs, tiltCos, alt, tiltDeg, cmdLeanDeg, yawRateAbs, postEmergTimer)
    if enginesOff then
        setThrottle(0)
        dbg.thrustOut = 0
        dbg.thrustReason = "engines-off"
        return
    end
    local tNow = tiltDeg or 0
    local tiltRising = (tNow > prevTiltDeg + 0.15)
    prevTiltDeg = lastTiltDeg
    lastTiltDeg = tNow
    local level
    local reason
    if phase == "DESCENT" then
        if (vs or 0) < -C.guidance.MAX_DESCENT_VS then
            local overspeed = -(vs or 0) - C.guidance.MAX_DESCENT_VS
            level = clamp(C.thrust.HOVER + C.thrust.VS_KP * overspeed, C.thrust.HOVER, C.thrust.MAX)
            reason = ("descent-speed-brake(over=%.1f)"):format(overspeed)
        elseif (tiltDeg or 0) > C.attitude.TILT_SAFE_START then
            level = C.thrust.COAST_TILT_BUMP * (C.GH.g(alt) / 11) * ((vs or 0) > 0 and 0.2 or 1)
            reason = ("descent-tilt-safety(tilt=%.1f>%.1f)"):format(tiltDeg or 0, C.attitude.TILT_SAFE_START)
        else
            level = C.thrust.COAST * (C.GH.g(alt) / 11) * ((vs or 0) > 0 and 0.2 or 1)
            reason = "descent-freefall"
        end
    elseif phase == "APPROACH" or phase == "LANDING" or phase == "TOUCHDOWN" then
        local altN = math.max(alt or 0, 0)
        local vsN = vs or 0
        local speed = math.max(-vsN, 0)
        local maxDecel = C.guidance.LANDING_BURN_MAX_DECEL
        local suicideAlt = (speed * speed) / (2 * math.max(maxDecel, 1)) * C.guidance.LANDING_BURN_MARGIN
        local mustBrake = altN <= suicideAlt

        local desVS = clamp(-altN * C.thrust.ALT_KP * 2, -C.guidance.MAX_DESCENT_VS, -0.3)
        if mustBrake or phase ~= "APPROACH" then
            desVS = landingDesVS(altN)
            local verr = desVS - vsN
            local hovFF = GH.hover(altN)
            GH.res = clamp((GH.res or 0) + C.thrust.HOVER_TRIM_KI * verr * rdt, -3, 3)
            local hovReal = math.max(hovFF + GH.res, 0.5)
            hoverTrim = clamp(hovReal - C.thrust.HOVER, C.thrust.HOVER_TRIM_MIN, C.thrust.HOVER_TRIM_MAX)
            local base = hovReal / math.max(tiltCos or 1, 0.5)
            level = clamp(base + C.thrust.VS_KP * verr, C.thrust.MIN, C.thrust.MAX)
            reason = ("suicide desVS=%.1f must=%s hov=%.1f"):format(
                desVS, tostring(mustBrake), C.thrust.HOVER + hoverTrim)
        elseif speed > (-desVS) + 1.5 then
            local overspeed = speed - (-desVS)
            level = clamp(C.thrust.HOVER + C.thrust.VS_KP * overspeed, C.thrust.HOVER, C.thrust.MAX)
            reason = ("profile-brake over=%.1f desVS=%.1f"):format(overspeed, desVS)
        elseif (tiltDeg or 0) > 2.0 then
            level = C.thrust.COAST_TILT_BUMP
            reason = ("tilt-auth tilt=%.1f"):format(tiltDeg or 0)
        else
            level = C.thrust.COAST
            reason = ("freefall desVS=%.1f"):format(desVS)
        end
        local tdeg = tiltDeg or 0
        local climbing = (yawRateAbs or 0)
        local mustSlow = tdeg < 20 and speed > math.sqrt(2 * 2.5 * math.max(altN, 1))
        if false and tdeg > 2.5 and tiltRising and level > C.thrust.HOVER and not mustSlow then
            level = C.thrust.HOVER
            reason = reason .. "+hold-for-att"
        end
        if tdeg > 15 and not mustSlow and altN > 30 then
            local cap = C.thrust.HOVER * 0.85
            if level > cap then
                level = cap
                reason = reason .. "+tumble-soft"
            end
        end
    else
        local base = (C.thrust.HOVER + hoverTrim) / math.max(tiltCos or 1, 0.5)
        level = base
        reason = "fallback-hover"
    end
    if (phase == "DESCENT" or phase == "APPROACH") and (tiltDeg or 0) > C.attitude.TILT_SAFE_START then
        local braking = reason:find("brake") or reason:find("suicide") or reason:find("profile")
        if not braking then
            local ceiling = C.thrust.HOVER
            if ceiling < level then reason = reason .. ("+tilt-ceiling(%.1f)"):format(ceiling) end
            level = math.min(level, ceiling)
        end
        local yaw = yawRateAbs or 0
        if yaw > C.attitude.YAW_SAFE_START then
            local yawFrac = clamp(
                (yaw - C.attitude.YAW_SAFE_START) / (C.attitude.EMERGENCY_YAW_RATE - C.attitude.YAW_SAFE_START),
                0, 1
            )
            local ceiling = C.thrust.HOVER + (C.thrust.MAX - C.thrust.HOVER) * (1 - yawFrac)
            ceiling = math.max(ceiling, C.thrust.HOVER)
            if ceiling < level then reason = reason .. ("+yaw-ceiling(%.1f,yaw=%.1f)"):format(ceiling, yaw) end
            level = math.min(level, ceiling)
        end
        if (postEmergTimer or 0) > 0 then
            local rampFrac = 1 - clamp((postEmergTimer or 0) / C.attitude.POST_EMERGENCY_RAMP, 0, 1)
            local ceiling = C.thrust.HOVER + (C.thrust.MAX - C.thrust.HOVER) * rampFrac
            if ceiling < level then reason = reason .. ("+post-emerg-ramp(%.1f)"):format(ceiling) end
            level = math.min(level, ceiling)
        end
    end
    if forceCeilingCut then
        level = C.thrust.MIN
        reason = reason .. "+ceiling-cut"
    end
    dbg.thrustReason = reason
    smoothedThrust = clamp(smoothedThrust + (level - smoothedThrust) * C.thrust.SMOOTH, C.thrust.MIN, C.thrust.MAX)
    local minThrust = C.thrust.MIN
    if phase == "LANDING" or phase == "TOUCHDOWN" then
        if (alt or 0) > C.guidance.LANDING_BURN_ALT then
            minThrust = C.thrust.MIN
        elseif (alt or 0) > 10 then
            minThrust = C.thrust.FLOOR_ABOVE_GROUND
        elseif (alt or 0) > 0 then
            minThrust = C.thrust.FLOOR_ABOVE_GROUND * 0.5
        end
    end
    if forceCeilingCut then minThrust = C.thrust.MIN end
    local clamped = clamp(smoothedThrust, minThrust, C.thrust.MAX)
    if lastTiltDeg and lastTiltDeg > 20 and (alt or 0) > 30 then
        if clamped > C.thrust.HOVER * 0.8 then
            clamped = C.thrust.HOVER * 0.8
        end
    end
    setThrottle(clamped)
    dbg.thrustOut = clamped
end
local perfT0 = nil
local function perfMark(dbgTable, key)
    if not C.flight.PERF_LOG then return end
    local now = os.epoch("utc")
    if perfT0 then dbgTable[key] = now - perfT0 end
    perfT0 = now
end
local telemetryWs = nil
local telemetryLastAttempt = 0
local telemetryTimer = 0
local prevVelX, prevVelY, prevVelZ = nil, nil, nil
local smoothG = 0
local function connectTelemetry()
    if not C.telemetry.ENABLE then return end
    local now = os.epoch("utc") / 1000
    if now - telemetryLastAttempt < C.telemetry.RECONNECT_INTERVAL then return end
    telemetryLastAttempt = now
    local ok, handle, err = pcall(http.websocket, "ws://" .. C.telemetry.RELAY_HOST .. C.telemetry.RELAY_PATH)
    if ok and handle and handle ~= false then
        telemetryWs = handle
        logLine("telemetry: connected to " .. C.telemetry.RELAY_HOST .. C.telemetry.RELAY_PATH)
    else
        telemetryWs = nil
        local reason = (not ok and handle) or err or "unknown error"
        logLine("telemetry: connect failed to " .. C.telemetry.RELAY_HOST .. C.telemetry.RELAY_PATH .. " -- " .. tostring(reason))
    end
end
local function computeGForce(vel, rdtNow)
    if not vel then return smoothG end
    if not prevVelX then
        prevVelX, prevVelY, prevVelZ = vel.x, vel.y, vel.z
        return smoothG
    end
    local ax = (vel.x - prevVelX) / rdtNow
    local ay = (vel.y - prevVelY) / rdtNow + C.guidance.GRAVITY
    local az = (vel.z - prevVelZ) / rdtNow
    prevVelX, prevVelY, prevVelZ = vel.x, vel.y, vel.z
    local mag = math.sqrt(ax*ax + ay*ay + az*az)
    local g = mag / C.guidance.GRAVITY
    smoothG = smoothG + (g - smoothG) * 0.3
    return smoothG
end
local DIAGONAL_LINKS = {
    northeast = C.link.gas_northeast,
    southeast = C.link.gas_southeast,
    southwest = C.link.gas_southwest,
    northwest = C.link.gas_northwest,
}
local function readDiagonalLit(name)
    local pair = DIAGONAL_LINKS[name]
    if not pair then return false end
    local ok, signal = pcall(bridge.getLinkSignal, pair[1], pair[2])
    return ok and signal ~= nil and signal >= 1
end
local telemetryDebugCount = 0
local lastAltM, lastSpeedMs = 0, 0
local function sendTelemetry(rdtNow)
    if not C.telemetry.ENABLE then return end
    if not telemetryWs then
        connectTelemetry()
        if not telemetryWs then return end
    end
    telemetryTimer = telemetryTimer + rdtNow
    if telemetryTimer < C.telemetry.SEND_INTERVAL then return end
    telemetryTimer = 0
    local lit = (not enginesOff) and smoothedThrust > C.telemetry.LIT_THRESHOLD
    local payload = textutils.serializeJSON({
        engines = {
            lit,
            lit,
            readDiagonalLit("northeast"),
            lit,
            readDiagonalLit("southeast"),
            lit,
            readDiagonalLit("southwest"),
            lit,
            readDiagonalLit("northwest"),
        },
        gforce = smoothG,
        altitude = lastAltM,
        speed = lastSpeedMs,
    })
    local ok = telemetryWs and pcall(telemetryWs.send, payload)
    if not ok then
        pcall(telemetryWs.close)
        logLine("telemetry: send failed, will reconnect")
        telemetryWs = nil
    else
        telemetryDebugCount = telemetryDebugCount + 1
        if telemetryDebugCount % 20 == 1 then
            logLine("telemetry: sent " .. payload)
        end
    end
end
local function update()
    perfT0 = os.epoch("utc")
    local att = readAttitude()
    perfMark(dbg, "t_pose")
    local vel = readVelocity()
    perfMark(dbg, "t_vel")
    if not att then
        neutralGimbal()
        neutralRCS()
        smoothedThrust = smoothedThrust + (C.thrust.HOVER - smoothedThrust) * C.thrust.SMOOTH
        setThrottle(clamp(smoothedThrust, C.thrust.FLOOR_ABOVE_GROUND, C.thrust.MAX))
        dbg.note = "no-pose"
        return
    end
    dbg.note = nil
    local nowMs = os.epoch("utc")
    if lastTickMs then
        rdt = clamp((nowMs - lastTickMs) / 1000, 0.01, 1.0)
    end
    lastTickMs = nowMs
    computeGForce(vel, rdt)
    if not poseSettled and att.posY then
        poseSettleTimer = poseSettleTimer + rdt
        if poseSettleTimer >= 0.5 then
            poseSettled = true
            logLine(("computer online  alt=%.1f  (settled after %.2fs)"):format(att.posY - C.nav.TARGET.y - C.nav.DECK_ALT, poseSettleTimer))
        else
            neutralGimbal(); neutralRCS(); setThrottle(C.thrust.HOVER); dbg.note = "waiting-pose"; return
        end
    end
    if not poseSettled then
        neutralGimbal(); neutralRCS(); setThrottle(C.thrust.HOVER); dbg.note = "waiting-pose"; return
    end
    local alt = att.posY - C.nav.TARGET.y - C.nav.DECK_ALT
    C.GH.cur = C.GH.hover(alt)
    local vs  = vel and vel.y or 0
    local vHoriz = vel and len2(vel.x, vel.z) or 0
    lastAltM = alt
    lastSpeedMs = vel and math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z) or vHoriz
    if not enginesOff and (phase == "LANDING" or phase == "TOUCHDOWN")
       and alt <= 1.2 and vs > -3 then
        C.flight.restTimer = (C.flight.restTimer or 0) + rdt
        if C.flight.restTimer >= 0.05 then
            enginesOff = true
            C.flight.shutdownAll()
            logLine(("ENGINES OFF -- resting on deck  alt=%.1f  tilt=%.1f  pos=(%.1f,%.1f)  dist=%.1f"):format(
                alt, att.tiltDeg or 0, att.pos and att.pos.x or 0, att.pos and att.pos.z or 0,
                att.pos and len2(C.nav.TARGET.x - att.pos.x, C.nav.TARGET.z - att.pos.z) or -1))
            return
        end
    else
        C.flight.restTimer = 0
    end
    if alt > C.thrust.CEILING then
        forceCeilingCut = true
        dbg.note = "ceiling-breach"
        logLine(("!!! CEILING BREACH alt=%.0f > %.0f -- forcing thrust to floor, stabilization stays live"):format(alt, C.thrust.CEILING))
    else
        forceCeilingCut = false
    end
    if stall.lastAlt == nil then
        stall.lastAlt, stall.lastPosX, stall.lastPosZ = alt, att.pos and att.pos.x, att.pos and att.pos.z
    end
    local posKnown = att.pos and att.pos.x and att.pos.z and stall.lastPosX and stall.lastPosZ
    local moved = math.abs(alt - stall.lastAlt) > stall.EPS_ALT
        or (posKnown and (math.abs(att.pos.x - stall.lastPosX) > stall.EPS_POS
                        or math.abs(att.pos.z - stall.lastPosZ) > stall.EPS_POS))
    if moved then
        stall.timer = 0
        stall.warned = false
        stall.lastAlt = alt
        if posKnown then stall.lastPosX, stall.lastPosZ = att.pos.x, att.pos.z end
    elseif not enginesOff and phase ~= "TOUCHDOWN" then
        stall.timer = stall.timer + rdt
        if stall.timer > stall.TIMEOUT and not stall.warned then
            stall.warned = true
            iFwd, iRight = 0, 0
            logLine(("!!! STALL: alt/pos unchanged for >%.1fs while engines commanded on (ph=%s cushion=%s) -- craft is not physically responding to control input. Reset iTerm; check for physics-sleep / world collision."):format(
                stall.TIMEOUT, phase, tostring(cushionMode)))
        elseif stall.warned and stall.timer % 10 < rdt then
            logLine(("    ...still stalled, %.0fs and counting"):format(stall.timer))
        end
    end
    local angVel = readAngularVelocity()
    local angFrame = C.attitude.ANGVEL_FRAME or "body"
    if angVel and angFrame == "diff" then
        angVel = nil
    elseif angVel and angFrame == "body" and att.qq then
        local wx, wy, wz = rotateBodyToWorld(att.qq, angVel.x, angVel.y, angVel.z)
        angVel = { x=wx, y=wy, z=wz }
    end
    if angVel then
        yawRate = math.deg(angVel.y)
    elseif prevHeading then
        yawRate = angleDiff(att.heading, prevHeading) / rdt
    end
    prevHeading = att.heading
    local wlx, wlz = att.up.x, att.up.z
    if prevWLX == nil then prevWLX, prevWLZ = wlx, wlz end
    if angVel then
        local dux, _, duz = crossProduct(angVel.x, angVel.y, angVel.z, att.up.x, att.up.y, att.up.z)
        wRateX = wRateX + (dux - wRateX) * C.attitude.RATE_SMOOTH
        wRateZ = wRateZ + (duz - wRateZ) * C.attitude.RATE_SMOOTH
        dbg.rateSource = "ang"
    else
        local rawRX = clamp((wlx - prevWLX) / rdt, -C.attitude.MAX_RATE_RAW, C.attitude.MAX_RATE_RAW)
        local rawRZ = clamp((wlz - prevWLZ) / rdt, -C.attitude.MAX_RATE_RAW, C.attitude.MAX_RATE_RAW)
        wRateX = wRateX + (rawRX - wRateX) * C.attitude.RATE_SMOOTH
        wRateZ = wRateZ + (rawRZ - wRateZ) * C.attitude.RATE_SMOOTH
        dbg.rateSource = "diff"
    end
    do
        local ddx, ddz = (wlx - prevWLX) / rdt, (wlz - prevWLZ) / rdt
        dbg.dLeanFwd   = ddx*att.fwd.x   + ddz*att.fwd.z
        dbg.dLeanRight = ddx*att.right.x + ddz*att.right.z
    end
    prevWLX, prevWLZ = wlx, wlz
    local leanFwd   = wlx*att.fwd.x   + wlz*att.fwd.z
    local leanRight = wlx*att.right.x + wlz*att.right.z
    local rateFwd   = wRateX*att.fwd.x   + wRateZ*att.fwd.z
    local rateRight = wRateX*att.right.x + wRateZ*att.right.z
    local angRateNow = len2(rateRight, rateFwd)
    dbg.angAccel = (angRateNow - prevAngRateNow) / math.max(rdt, 1e-6)
    prevAngRateNow = angRateNow
    dbg.yawRateFromW = angVel and math.deg(angVel.y) or nil
    dbg.rateSrcForYawDiag = angVel and "ang" or "unavailable"
    if cushionMode then
        if att.tiltDeg < C.attitude.CUSHION_RECOVER_TILT
           and math.abs(yawRate) < C.attitude.CUSHION_RECOVER_YAW
           and angRateNow < C.attitude.CUSHION_RECOVER_RATE then
            cushionRecoverTimer = cushionRecoverTimer + rdt
        else
            cushionRecoverTimer = 0
        end
        if cushionRecoverTimer > C.attitude.CUSHION_RECOVER_HOLD then
            cushionMode = false
            cushionRecoverTimer = 0
            emergencyTimer = 0
            postEmergencyTimer = C.attitude.POST_EMERGENCY_RAMP
            iFwd, iRight = 0, 0
            logLine(("CUSHION -> RECOVERED tilt=%.1f, resuming attitude control"):format(att.tiltDeg))
        else
            local scale = torqueScale(smoothedThrust)
            local frameSpinRate = angRateNow
            local kpActive = kpActiveFrac(frameSpinRate)
            local rawEffortRight = clamp(scale * (-C.attitude.TILT_KP*kpActive*leanRight - C.attitude.TILT_KD*rateRight), -C.attitude.OUTPUT_LIMIT, C.attitude.OUTPUT_LIMIT)
            local rawEffortFwd   = clamp(scale * (-C.attitude.TILT_KP*kpActive*leanFwd   - C.attitude.TILT_KD*rateFwd),   -C.attitude.OUTPUT_LIMIT, C.attitude.OUTPUT_LIMIT)
            local effortRight, effortFwd = slewEffort(rawEffortRight, rawEffortFwd, rdt, C.attitude.EMERGENCY_SLEW_RATE, "cushion")
            setGimbal(effortRight, effortFwd)
            doYaw(scale)
            local rawRcsRight = clamp(-C.rcs.KP*kpActive*leanRight - C.rcs.KD*rateRight, -C.rcs.LIMIT, C.rcs.LIMIT)
            local rawRcsFwd   = clamp(-C.rcs.KP*kpActive*leanFwd   - C.rcs.KD*rateFwd,   -C.rcs.LIMIT, C.rcs.LIMIT)
            local rcsRight, rcsFwd = slewRCS(rawRcsRight, rawRcsFwd, rdt, "cushion")
            setRCS(rcsRight, rcsFwd)
            dbg.torqueScale = scale
            local usefulFrac = clamp(att.up.y, 0, 1)
            local target
            if vs > 0 then
                target = C.thrust.MIN
            elseif (alt or 0) > 40 then
                local speed = math.max(-vs, 0)
                local desVS = clamp(-(alt or 0) * C.thrust.ALT_KP * 2, -C.thrust.DESC_VS, -0.3)
                local verr = desVS - vs
                target = clamp(C.thrust.HOVER + C.thrust.VS_KP * verr, C.thrust.HOVER, C.thrust.MAX)
            else
                target = C.attitude.STUCK_CUSHION_THRUST * usefulFrac
            end
            if vHoriz > 8 then
                target = math.min(target, C.thrust.MIN + 1)
            elseif vHoriz > 5 then
                target = math.min(target, C.thrust.COAST_TILT_BUMP)
            end
            smoothedThrust = clamp(smoothedThrust + (target - smoothedThrust) * C.thrust.SMOOTH, C.thrust.MIN, C.thrust.MAX)
            setThrottle(smoothedThrust)
            dbg.note = "cushion"
            dbg.alt, dbg.vs = alt, vs
            dbg.tiltDeg = att.tiltDeg
            dbg.heading = att.heading
            dbg.vHoriz = vHoriz
            dbg.posX, dbg.posZ = att.pos and att.pos.x or 0, att.pos and att.pos.z or 0
            dbg.tgtDist = (att.pos and att.pos.x and att.pos.z)
                and len2(C.nav.TARGET.x - att.pos.x, C.nav.TARGET.z - att.pos.z) or dbg.tgtDist
            dbg.leanFwd, dbg.leanRight = leanFwd, leanRight
            dbg.rateFwd, dbg.rateRight = rateFwd, rateRight
            dbg.angRate = angRateNow
            dbg.yawRate = yawRate
            dbg.effortRawFwd, dbg.effortRawRight = rawEffortFwd, rawEffortRight
            dbg.effortFwd, dbg.effortRight = effortFwd, effortRight
            dbg.rcsRawFwd, dbg.rcsRawRight = rawRcsFwd, rawRcsRight
            dbg.rcsFwd, dbg.rcsRight = rcsFwd, rcsRight
            dbg.slewMode = "cushion-active-recover"
            dbg.thrustOut = smoothedThrust
            dbg.thrustReason = (vs > 0) and "cushion-still-climbing-cut-thrust" or "cushion-soften-fall"
            dbg.emergReason = ("tilt %.1f>%.1f"):format(att.tiltDeg, C.attitude.EMERGENCY_TILT)
            perfMark(dbg, "t_gimbal")
            perfMark(dbg, "t_thrust")
            if (alt <= 3 and vHoriz < 5 and math.abs(vs) < 5)
               or (vHoriz < 1 and math.abs(vs) < 1 and alt < 10) then
                enginesOff = true
                C.flight.shutdownAll()
                logLine(("ENGINES OFF -- cushion landed, alt=%.1f  pos=(%.1f,%.1f)  dist=%.1f"):format(
                    alt, att.pos and att.pos.x or 0, att.pos and att.pos.z or 0, dbg.tgtDist or -1))
            end
            return
        end
    end
    local legsWanted = (alt < C.legs.LEGS_ALT) and (vs < C.legs.LEGS_VS)
    if legsDeployed and alt < C.legs.LEGS_ALT + C.legs.HYSTERESIS then
        legsWanted = true
    end
    if (phase == "LANDING" or phase == "TOUCHDOWN") and alt < C.legs.FORCE_LANDING then
        legsWanted = true
    end
    setLegs(legsWanted)
    local tgtBear, tgtDist
    if att.pos and att.pos.x and att.pos.z then
        local dx = C.nav.TARGET.x - att.pos.x
        local dz = C.nav.TARGET.z - att.pos.z
        tgtBear = math.deg(math.atan2(dx, dz))
        tgtDist = len2(dx, dz)
    end
    local angRate = angRateNow
    local emergTiltLimit = stall.emergLatched and C.attitude.EMERGENCY_EXIT_TILT or C.attitude.EMERGENCY_TILT
    local emergTilt = att.tiltDeg > emergTiltLimit
    local emergRate = angRate > C.attitude.EMERGENCY_RATE
    local emergYaw
    if yawRate < 0 then
        emergYaw = (-yawRate) > C.attitude.EMERGENCY_YAW_RATE
    else
        emergYaw = yawRate > (C.attitude.EMERGENCY_YAW_RATE * 2.5)
    end
    local emergencyNow = false
    stall.emergLatched = emergencyNow and not enginesOff
    if emergencyNow and not enginesOff then
        postEmergencyTimer = C.attitude.POST_EMERGENCY_RAMP
        local reasons = {}
        if emergTilt then reasons[#reasons+1] = ("tilt %.1f>%.1f"):format(att.tiltDeg, C.attitude.EMERGENCY_TILT) end
        if emergRate then reasons[#reasons+1] = ("rate %.2f>%.2f"):format(angRate, C.attitude.EMERGENCY_RATE) end
        if emergYaw  then reasons[#reasons+1] = ("yaw %.1f>%.1f"):format(yawRate, C.attitude.EMERGENCY_YAW_RATE) end
        dbg.emergReason = table.concat(reasons, " & ")
        if emergencyTimer > C.attitude.EMERGENCY_TIMEOUT and (alt or 0) < 80 then
            cushionMode = true
            neutralGimbal()
            neutralRCS()
            setThrottle(C.attitude.STUCK_CUSHION_THRUST)
            logLine(("ENGINES CUSHION -- timeout %.1fs alt=%.0f"):format(emergencyTimer, alt or 0))
        elseif emergencyTimer > C.attitude.EMERGENCY_TIMEOUT then
            emergencyTimer = C.attitude.EMERGENCY_TIMEOUT * 0.4
            logLine(("EMERGENCY persist alt=%.0f — keep recovery"):format(alt or 0))
        else
            emergencyRecovery(leanRight, leanFwd, rateRight, rateFwd, att, alt, vs)
        end
        dbg.alt, dbg.vs     = alt, vs
        dbg.tiltDeg         = att.tiltDeg
        dbg.heading         = att.heading
        dbg.yawRate         = yawRate
        dbg.tgtBear         = tgtBear or 0
        dbg.tgtDist         = tgtDist or -1
        dbg.posX, dbg.posZ  = att.pos and att.pos.x or 0, att.pos and att.pos.z or 0
        dbg.leanFwd         = leanFwd
        dbg.leanRight       = leanRight
        dbg.rateFwd         = rateFwd
        dbg.rateRight       = rateRight
        dbg.angRate         = angRate
        dbg.legs            = legsDeployed
        dbg.phaseTimer      = phaseTimer
        dbg.vHoriz          = vHoriz
        if phase == "APPROACH" then
            local speed = math.max(-(vs or 0), 0)
            local brakeAlt = (speed * speed) / (2 * C.guidance.LANDING_BURN_MAX_DECEL) * C.guidance.LANDING_BURN_MARGIN
            local trigger = math.max(C.guidance.LANDING_BURN_ALT, brakeAlt)
            if alt <= trigger then
                phase = "LANDING"
                phaseTimer = 0
                logLine(("PHASE: LANDING (during EMERG) dist=%.0f vH=%.1f alt=%.1f vs=%.1f"):format(
                    tgtDist or -1, vHoriz, alt, vs or 0))
            end
        end
        return
    else
        emergencyTimer = math.max(0, emergencyTimer - rdt)
        prevEmergencyTilt = nil
        postEmergencyTimer = math.max(0, postEmergencyTimer - rdt)
        dbg.emergReason = nil
    end
    phaseTimer = phaseTimer + rdt
    if phase == "DESCENT" and alt <= math.max(C.guidance.STABILIZE_ALT, vHoriz * vHoriz / (2 * C.altitude.LAT_DECEL) * 1.3) then
        phase = "APPROACH"
        phaseTimer = 0
        logLine(("PHASE: APPROACH  dist=%.0f  alt=%.0f  vs=%.1f"):format(tgtDist or -1, alt, vs or 0))
    end
    if phase == "APPROACH" then
        local speed = math.max(-(vs or 0), 0)
        local brakeAlt = (speed * speed) / (2 * C.guidance.LANDING_BURN_MAX_DECEL) * C.guidance.LANDING_BURN_MARGIN
        local trigger = math.max(C.guidance.LANDING_BURN_ALT, brakeAlt)
        if alt <= trigger then
            phase = "LANDING"
            phaseTimer = 0
            logLine(("PHASE: LANDING  dist=%.0f  vH=%.1f  alt=%.1f  vs=%.1f  trigger=%.0f(brakeAlt=%.0f)"):format(
                tgtDist or -1, vHoriz, alt, vs or 0, trigger, brakeAlt))
        end
    end
    if phase == "LANDING" then
        if alt <= C.guidance.TOUCHDOWN_ALT and tgtDist and tgtDist < C.guidance.LANDING_DIST * 0.4 then
            phase = "TOUCHDOWN"
            phaseTimer = 0
            touchdownTimer = 0
            logLine(("PHASE: TOUCHDOWN  alt=%.1f  dist=%.0f"):format(alt, tgtDist))
        end
    end
    if phase == "TOUCHDOWN" and not enginesOff then
        local safe = att.tiltDeg <= C.touchdown_safety.MAX_TILT
                 and vHoriz <= C.touchdown_safety.MAX_VH
        local touching = alt <= C.guidance.TOUCH_CUT_ALT
            or (alt <= C.guidance.TOUCH_CUT_ALT + 2 and math.abs(vs or 0) < 0.3)
        safe = safe and touching
        if safe then
            touchdownTimer = touchdownTimer + rdt
        else
            touchdownTimer = 0
        end
        if touchdownTimer >= C.thrust.TOUCHDOWN_CUTOFF then
            enginesOff = true
            C.flight.shutdownAll()
            logLine(("ENGINES OFF -- landed  pos=(%.1f,%.1f)  dist=%.1f  target=(%.0f,%.0f)"):format(
                att.pos and att.pos.x or 0, att.pos and att.pos.z or 0, tgtDist or -1,
                C.nav.TARGET.x, C.nav.TARGET.z))
        end
    end
    local lx, lz = 0, 0
    local navPhase = (phase == "DESCENT")
        or ((phase == "APPROACH" or phase == "LANDING") and C.guidance.NAV_IN_TERMINAL and alt > C.guidance.NAV_MIN_ALT)
    if navPhase and tgtBear and tgtDist and tgtDist > C.guidance.NAV_DEADZONE_DIST then
        local g = C.guidance
        local dx, dz = dirOf(tgtBear)
        local vCap = (phase == "DESCENT") and g.MAX_SPEED or g.NAV_TERMINAL_MAX_SPEED
        local desSpeed = math.min(vCap, tgtDist * g.APPROACH_GAIN, math.sqrt(2 * C.altitude.LAT_DECEL * tgtDist))
        local vx = (vel and vel.x or 0)
        local vz = (vel and vel.z or 0)
        local vAlong = vx*dx + vz*dz
        local maxLeanDeg = effectiveMaxLean(g.MAX_LEAN, smoothedThrust)
        local speedErr = desSpeed - vAlong
        if math.abs(speedErr) < 0.3 then speedErr = 0 end
        local leanCmd = clamp(g.SPEED_KP * speedErr, -maxLeanDeg, maxLeanDeg)
        local mag = math.sin(math.rad(math.abs(leanCmd))) * (leanCmd >= 0 and 1 or -1)
        lx, lz = dx*mag, dz*mag
        local px, pz = -dz, dx
        local vCross = vx*px + vz*pz
        local cmag = clamp(-g.VEL_KP * vCross / g.GRAVITY, -0.3, 0.3)
        lx, lz = lx + px*cmag, lz + pz*cmag
        local lmag = len2(lx, lz)
        local maxLean = math.sin(math.rad(maxLeanDeg))
        if lmag > maxLean and lmag > 1e-9 then lx, lz = lx*maxLean/lmag, lz*maxLean/lmag end
    elseif phase == "APPROACH" or phase == "LANDING" or phase == "TOUCHDOWN" then
        lx, lz = 0, 0
    end
    if phase == "DESCENT" or phase == "APPROACH" or phase == "LANDING" then
        local rampFrac = clamp(phaseTimer / C.guidance.LEAN_RAMP_TIME, 0, 1)
        lx, lz = lx * rampFrac, lz * rampFrac
        if vHoriz > C.guidance.MAX_SAFE_VH then
            local overFrac = clamp((vHoriz - C.guidance.MAX_SAFE_VH) / C.guidance.MAX_SAFE_VH, 0, 1)
            local vx0 = vel and vel.x or 0
            local vz0 = vel and vel.z or 0
            local vDirX, vDirZ = horizUnit(vx0, vz0)
            if vDirX then
                local along = lx*vDirX + lz*vDirZ
                if along > 0 then
                    local damp = along * overFrac
                    lx, lz = lx - vDirX*damp, lz - vDirZ*damp
                end
            end
        end
    end
    do
        local dlx, dlz = lx - prevLx, lz - prevLz
        local dmag = len2(dlx, dlz)
        local maxStep = C.guidance.LEAN_SLEW_RATE * rdt
        if dmag > maxStep and dmag > 1e-9 then
            dlx, dlz = dlx * maxStep / dmag, dlz * maxStep / dmag
        end
        lx, lz = prevLx + dlx, prevLz + dlz
    end
    prevLx, prevLz = lx, lz
    local nearPad = (tgtDist or 0) > 0 and (tgtDist or 0) < C.guidance.NAV_DEADZONE_DIST
    local highThr = (smoothedThrust or 0) >= C.thrust.HOVER * 0.9
    local landingPh = (phase == "LANDING" or phase == "TOUCHDOWN")
    local legacyLock = (not C.guidance.NAV_IN_TERMINAL) and (highThr or landingPh)
    if nearPad or legacyLock or phase == "TOUCHDOWN" or (att.tiltDeg or 0) > C.guidance.NAV_MAX_TILT then
        lx, lz = 0, 0
    end
    local desFwd   = lx*att.fwd.x   + lz*att.fwd.z
    local desRight = lx*att.right.x + lz*att.right.z
    local cmdLeanDeg = math.deg(math.asin(clamp(len2(lx, lz), 0, 1)))
    local tiltSafeFrac = 1
    if att.tiltDeg > C.attitude.TILT_SAFE_START then
        tiltSafeFrac = clamp(
            1 - (att.tiltDeg - C.attitude.TILT_SAFE_START) / (C.attitude.EMERGENCY_TILT - C.attitude.TILT_SAFE_START),
            0, 1
        )
    end
    desFwd   = desFwd   * tiltSafeFrac
    desRight = desRight * tiltSafeFrac
    if not enginesOff then
        local leanErr = math.abs((desRight or 0) - (leanRight or 0)) + math.abs((desFwd or 0) - (leanFwd or 0))
        local leak = 1 - clamp(rdt / 15, 0, 0.5)
        iRight = iRight * leak
        iFwd   = iFwd   * leak
        local quasi = math.abs(leanRight) < 0.12 and math.abs(leanFwd) < 0.12 and angRateNow < 0.12
        if quasi and math.abs(yawRate) < 8.0 and smoothedThrust >= C.thrust.COAST_TILT_BUMP then
            iRight = clamp(iRight + (desRight - leanRight)*rdt, -C.attitude.I_LIMIT, C.attitude.I_LIMIT)
            iFwd   = clamp(iFwd   + (desFwd   - leanFwd  )*rdt, -C.attitude.I_LIMIT, C.attitude.I_LIMIT)
        end
        local scale = torqueScale(smoothedThrust)
        local gainFrac = clamp((att.tiltDeg - 3) / (C.attitude.EMERGENCY_TILT - 3), 0, 1)
        local gainMult = 1 + 0.4 * gainFrac
        local kd = C.attitude.TILT_KD
        if phase == "LANDING" or phase == "TOUCHDOWN" then
            kd = kd * 1.0
        end
        if (smoothedThrust or 0) > C.thrust.HOVER * 0.9 then
            kd = kd * 1.0
            gainMult = gainMult * 1.0
        end
        local thrI = 1.0
        local spinLock = math.abs(yawRate) > 15
        local pR = spinLock and 0 or (desRight - leanRight - rateRight * rdt * 0.7)
        local pF = spinLock and 0 or (desFwd - leanFwd - rateFwd * rdt * 0.7)
        local iR = spinLock and 0 or iRight
        local iF = spinLock and 0 or iFwd
        local kdSpin = spinLock and (kd * 2.5) or kd
        local rawEffortRight = scale * (C.attitude.TILT_KP*gainMult*pR - kdSpin*gainMult*rateRight + C.attitude.TILT_KI*thrI*iR)
        local rawEffortFwd   = scale * (C.attitude.TILT_KP*gainMult*pF - kdSpin*gainMult*rateFwd   + C.attitude.TILT_KI*thrI*iF)
        local lim = C.attitude.OUTPUT_LIMIT
        if false and leanRight * rateRight > 0.0004 and math.abs(leanRight) > 0.02 then
            rawEffortRight = rawEffortRight - (leanRight > 0 and 1 or -1) * clamp(math.abs(rateRight)*25, 0, 2.5)
        end
        if false and leanFwd * rateFwd > 0.0004 and math.abs(leanFwd) > 0.02 then
            rawEffortFwd = rawEffortFwd - (leanFwd > 0 and 1 or -1) * clamp(math.abs(rateFwd)*25, 0, 2.5)
        end
        rawEffortRight = clamp(rawEffortRight, -lim, lim)
        rawEffortFwd   = clamp(rawEffortFwd,   -lim, lim)
        local effortRight, effortFwd = slewEffort(rawEffortRight, rawEffortFwd, rdt, nil, "nominal")
        setGimbal(effortRight, effortFwd)
        doYaw(scale)
        local rcsBoost = 1.0
        if (phase == "LANDING" or phase == "TOUCHDOWN") and att.tiltDeg > C.attitude.TILT_SAFE_START then
            rcsBoost = 1.0 + 0.8 * clamp((att.tiltDeg - C.attitude.TILT_SAFE_START) / (C.attitude.EMERGENCY_TILT - C.attitude.TILT_SAFE_START), 0, 1)
        end
        local rcsThrScale = clamp(smoothedThrust / math.max(C.GH.cur or C.thrust.HOVER, 0.1), 0.55, 1.0)
        local rawRcsRight = clamp(C.rcs.KP*gainMult*rcsBoost*rcsThrScale*(desRight - leanRight) - C.rcs.KD*gainMult*rcsBoost*rcsThrScale*rateRight, -C.rcs.LIMIT, C.rcs.LIMIT)
        local rawRcsFwd   = clamp(C.rcs.KP*gainMult*rcsBoost*rcsThrScale*(desFwd   - leanFwd  ) - C.rcs.KD*gainMult*rcsBoost*rcsThrScale*rateFwd,   -C.rcs.LIMIT, C.rcs.LIMIT)
        local rcsRight, rcsFwd = slewRCS(rawRcsRight, rawRcsFwd, rdt, "nominal")
        setRCS(rcsRight, rcsFwd)
        dbg.rcsRawFwd, dbg.rcsRawRight = rawRcsFwd, rawRcsRight
        dbg.rcsFwd, dbg.rcsRight = rcsFwd, rcsRight
        perfMark(dbg, "t_gimbal")
        dbg.slewMode = "nominal"
        dbg.torqueScale = scale
        dbg.effortRawFwd, dbg.effortRawRight = rawEffortFwd, rawEffortRight
        dbg.effortFwd, dbg.effortRight = effortFwd, effortRight
        dbg.desFwd, dbg.desRight = desFwd, desRight
        dbg.iFwd, dbg.iRight = iFwd, iRight
        dbg.tiltSafeFrac = tiltSafeFrac
    end
    controlThrust(vs, att.up.y, alt, att.tiltDeg, cmdLeanDeg, math.abs(yawRate), postEmergencyTimer)
    perfMark(dbg, "t_thrust")
    dbg.alt, dbg.vs     = alt, vs
    dbg.tiltDeg         = att.tiltDeg
    dbg.cmdTilt         = cmdLeanDeg
    dbg.heading         = att.heading
    dbg.yawRate         = yawRate
    dbg.tgtBear         = tgtBear or 0
    dbg.tgtDist         = tgtDist or -1
    dbg.posX, dbg.posZ  = att.pos and att.pos.x or 0, att.pos and att.pos.z or 0
    dbg.leanFwd         = leanFwd
    dbg.leanRight       = leanRight
    dbg.rateFwd         = rateFwd
    dbg.rateRight       = rateRight
    dbg.angRate         = len2(rateRight, rateFwd)
    dbg.legs            = legsDeployed
    dbg.phaseTimer      = phaseTimer
    dbg.vHoriz          = vHoriz
end
local logRing = { blocks = {}, bytes = 0, verbose = false }
local function logState()
    logCount = logCount + 1
    local hot = (dbg.tiltDeg or 0) > C.log.VERBOSE_TILT
             or emergencyTimer > 0 or dbg.emergReason ~= nil
    local scheduled = logCount % C.log.EVERY == 0
    local blk = {}
    local function logLine(s) blk[#blk + 1] = s end
    do
    logLine(("t=%d ph=%s alt=%.1f vs=%.1f vH=%.1f tilt=%.1f pos=(%.1f,%.1f) dist=%.0f legs=%s rdt=%.3f"):format(
        logCount, phase, dbg.alt or 0, dbg.vs or 0,
        dbg.vHoriz or 0, dbg.tiltDeg or 0, dbg.posX or 0, dbg.posZ or 0, dbg.tgtDist or -1, tostring(dbg.legs), rdt))
    logLine(("   brg=%.1f hdg=%.1f yawRate=%.1f engYaw=%+.2f des=(%+.2f,%+.2f) act=(%+.2f,%+.2f) thr=%.1f%s"):format(
        dbg.tgtBear or 0, dbg.heading or 0, dbg.yawRate or 0, dbg.engYawMag or 0,
        dbg.desFwd or 0, dbg.desRight or 0,
        dbg.leanFwd or 0, dbg.leanRight or 0,
        dbg.thrustOut or smoothedThrust,
        dbg.note and (" ["..dbg.note.."]") or ""))
    logLine(("   rate=(%+.2f,%+.2f) angRate=%.2f (emerg@%.2f) tiltSafeFrac=%.2f iTerm=(%+.3f,%+.3f)"):format(
        dbg.rateFwd or 0, dbg.rateRight or 0, dbg.angRate or 0, C.attitude.EMERGENCY_RATE,
        dbg.tiltSafeFrac or 0, dbg.iFwd or 0, dbg.iRight or 0))
    logLine(("   diag: dLean/dt=(%+.2f,%+.2f) angAccel=%+.3f yawRate_fromW=%s (src=%s)"):format(
        dbg.dLeanFwd or 0, dbg.dLeanRight or 0,
        dbg.angAccel or 0,
        dbg.yawRateFromW and (("%+.1f"):format(dbg.yawRateFromW)) or "n/a",
        dbg.rateSrcForYawDiag or "?"))
    logLine(("   effRaw=(%+.2f,%+.2f) eff=(%+.2f,%+.2f) slew=%s torque=%.2fx sat=%s"):format(
        dbg.effortRawFwd or 0, dbg.effortRawRight or 0,
        dbg.effortFwd or 0, dbg.effortRight or 0,
        dbg.slewMode or "?", dbg.torqueScale or 0,
        tostring(math.abs(dbg.effortFwd or 0) >= C.attitude.OUTPUT_LIMIT * 0.99
              or math.abs(dbg.effortRight or 0) >= C.attitude.OUTPUT_LIMIT * 0.99)))
    logLine(("   rcsRaw=(%+.2f,%+.2f) rcs=(%+.2f,%+.2f) sat=%s"):format(
        dbg.rcsRawFwd or 0, dbg.rcsRawRight or 0,
        dbg.rcsFwd or 0, dbg.rcsRight or 0,
        tostring(math.abs(dbg.rcsFwd or 0) >= C.rcs.LIMIT * 0.99
              or math.abs(dbg.rcsRight or 0) >= C.rcs.LIMIT * 0.99)))
    logLine(("   thrustReason=%s%s"):format(
        dbg.thrustReason or "?",
        dbg.emergReason and (("  EMERG_TRIGGER=[%s]"):format(dbg.emergReason)) or ""))
    if C.flight.PERF_LOG then
        logLine(("   perf: pose=%dms vel=%dms gimbal=%dms thrust=%dms flush=%dms rateSrc=%s"):format(
            dbg.t_pose or -1, dbg.t_vel or -1, dbg.t_gimbal or -1, dbg.t_thrust or -1, dbg.t_flush or -1,
            dbg.rateSource or "?"))
    end
    end
    local function flush(list, echo)
        for _, b in ipairs(list) do
            for _, line in ipairs(b) do
                if echo then print(line) end
                if logFile then logFile.writeLine(line); logRing.bytes = logRing.bytes + #line + 1 end
            end
        end
        if logFile then logFile.flush() end
    end
    local overBudget = logRing.bytes > C.log.BYTE_BUDGET
    if (hot and not overBudget) then
        if not logRing.verbose then
            logRing.verbose = true
            if logFile then logFile.writeLine("---- VERBOSE LOG ON (tilt/emergency) -- preceding buffered ticks follow ----") end
            flush(logRing.blocks, false)
            logRing.blocks = {}
        end
        flush({ blk }, scheduled)
    else
        logRing.verbose = false
        if scheduled then
            flush({ blk }, true)
            logRing.blocks = {}
        else
            logRing.blocks[#logRing.blocks + 1] = blk
            if #logRing.blocks > C.log.RING then table.remove(logRing.blocks, 1) end
        end
    end
end
logLine(("target %.0f,%.0f,%.0f"):format(C.nav.TARGET.x, C.nav.TARGET.y, C.nav.TARGET.z))
neutralGimbal()
neutralRCS()
setThrottle(0)
setLegs(false)
flushLinks()
logLine(("BOOSTER COMPUTER ONLINE -- post-separation, starting in %s  rev=rev40-no-emergency%s"):format(
    phase, C.flight.DEBUG_START_PHASE and "  [[DEBUG_START_PHASE ACTIVE -- NOT A REAL BOOT]]" or ""))
while true do
    if enginesOff then
        C.flight.shutdownAll()
        pcall(flushLinks)
        local vel = readVelocity()
        computeGForce(vel, 1.0)
        if vel then
            lastSpeedMs = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)
        end
        pcall(sendTelemetry, 1.0)
        os.sleep(1)
    else
        local ok, err = pcall(function() update(); flushLinks(); perfMark(dbg, "t_flush"); logState() end)
        if not ok then
            local line = "[F9] ERROR: " .. tostring(err)
            print(line); logLine(line)
            neutralGimbal()
            neutralRCS()
            smoothedThrust = C.thrust.HOVER
            setThrottle(smoothedThrust)
            pcall(flushLinks)
            os.sleep(0.5)
        else
            os.sleep(dt)
        end
        pcall(sendTelemetry, rdt)
    end
end
