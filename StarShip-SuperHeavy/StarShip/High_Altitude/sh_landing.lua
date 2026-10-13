-- Starship landing autopilot (ground pad, no arms)
local CONFIG = {
  LAND_MODE = "pad",
  TARGET = { x = -3279, y = 69, z = 6378 },
  DECK_ALT = 24.8,
  THRUST_MULT = 9.0,
  ADAPT = true, ADAPT_K = 0.03, ADAPT_EXP_MIN = 0.5, KT_MIN = 4.0, KT_MAX = 16,
  ADAPT_VMAX = 20,
  DRAG_K = 0.0006,
  KP = 0.6, KD = 2.2, KFV = 0.6, RATE_SMOOTH = 0.7,
  ATT_KI = 0.35, ATT_KI_C = 0.30, ATT_IMAX = 0.35, ATT_I_ERR = 0.08,
  ATT_I_ERR_C = 0.06,
  ATT_I_RATE = 0.08,
  LEAN_HARD = 0.40,
  GIM_SHARE = 0.9, GIM_ON = true,

  VEC_MIN = 1,
  BURN_VEC_MIN = 9,
  TRIM_KI = 0.25, TRIM_LIM = 2,
  A_RISE = 40, BURN_LAG = 2.0,

  TOUCH_VS = 1.0, MAX_DESC = 200,
  HOLD_ALT = 0, HOLD_RATE = 6.0, ML_NEAR = 0.11,
  HOLD_MAX = 60, COMMIT_ALT = 2, COMMIT_BODY = 78,
  BRAKE_FRAC = 1.3, BRAKE_LAG = 1.5,
  BIAS_KI = 0.8, BIAS_MAX = 1.0,
  CATCH_XZ = 2, CATCH_VH = 1.2, EXIT_XZ = 4, EXIT_VH = 2.5, CATCH_TILT = 3,
  CUT_ALT = 0.5, MISS_XZ = 6.5,
  THRUST_RAMP = 2.0, REST_T = 2.0, REST_VS = 0.05, REST_G = 0.95,
  STILL_ALT = 1.5, STILL_ALT_HI = 8, STILL_VS = 0.25, STILL_T = 1.0,
  IMPACT_ACC = 120, IMPACT_ALT = 35,
  EG_TMIN = 6, NAV_RAMP = 0.5,
  ML_BASE = 0.08, ML_MIN = 0.09, MAX_LEAN = 0.15, LEAN_SLEW = 0.10,
  PROF_TAU = 9, VS_KP_TR = 1.2, TRACK_FLOOR = 0.9, A_SLEW_TR = 6, A_SLEW_UP = 30,
  GATE_ALT = 105, ML_0 = 0.02, ML_K = 0.012, ML_V = 0.025,

  CONST_ON = true, CT_VEC = 11, CT_ON_MARGIN = 0, CT_OFF_MARGIN = 40, CT_HAND_VS = 16, CT_END = 25, CT_LAG = 0.35,
  MAX_CLIMB = 2,
  GLIDE_NEAR = 0, NEAR_R = 40, TRACK_TG = 6,
  GLIDE_SLOPE = 0, GLIDE_R0 = 3,
  TILT_SAFE = 15, TILT_THR = 15, TILT_THR_W = 20,
  GLIDE_VS = 40, GLIDE_GATE = 700, GLIDE_KP = 1.5, GLIDE_LEAN = 0.16, GLIDE_NAV_KP = 0.35, GLIDE_LAG = 1.5, GLIDE_TMIN = 5, GLIDE_VW_RATE = 3,
  
  GLIDE_HOLD = false, GLIDE_HOLD_ALT = 80, GLIDE_HOLD_BAND = 40, GLIDE_HOLD_TD = 3.0, GLIDE_HOLD_V = 0.8, GLIDE_HOLD_MAX = 45,
  GLIDE_LEAD = 1.0,
  GLIDE_LOW_ALT = 150, GLIDE_LEAN_LOW = 0.07, GLIDE_LOW_R = 10, GLIDE_LOW_V = 2.5,   -- cap applies ONLY when already within GLIDE_LOW_R m of the pad
  NAV_MAX = 9, NAV_PK = 0.65, NAV_DEAD = 0.6, NAV_WARN = 600,
  LOG_BUDGET = 600000, STALE_LOOPS = 15, STALE_ABORT = 80,
  FLOOR_EV0 = 1.0, FLOOR_EV_K = 0.15, FLOOR_MIN_K = 0.4, FLOOR_RELAX_ALT = 25,
  A_FLOOR = 0.6, A_FALL = 30, FLOOR_ALT = 200,

  -- roll
  ROLL_ON = true,
  ROLL_HOLD = false,     -- true: hold the heading the ship had at start; false: turn to ARMS_DIR + ROLL_OFFSET from calib.lua (like the booster 165)
  ROLL_HDG = nil,        -- used only if there is no ARMS_DIR (no calib.lua): fixed heading in deg, atan2(z,x) of the heading axis
  ROLL_OFFSET = 0,       -- deg, overwritten from calib.lua; run calibrate_ship.lua with the ship sitting in the arms the right way round
  ROLL_TRIM = 0,         -- extra deg added on top (e.g. 180 if the heat-shield side still faces the arms)
  HDG_AXIS = "R", HDG_SIGN = 1,   -- body axis whose horizontal direction is the heading
  ROLL_SIGN = 1,         -- -1 if roll turns the wrong way
  ROLL_KP = 0.6, ROLL_KD = 0.9, ROLL_K = 90, ROLL_MAX = 10, ROLL_DEAD = 0.4, ROLL_MIN = 0.4, ROLL_KI = 0.3, ROLL_IMAX = 0.03,
  ROLL_ALT_MAX = 1200, ROLL_ALT_MIN = 0.3, ROLL_TILT_MAX = 20,
  KDY = 1.0,             -- outside the roll window: plain spin damping (as in the old 164)

  LOW_ALT = 30, ML_LOW = 0.11,
  BODY_FADE = 150, CP_LOW = 0, CP_K = 0, POS_ROT_ALT = 30,
  CLOSE_V0 = 0.8, CLOSE_VK = 0.25, CLOSE_KB = 1.5,
  A_CAP_G = 1.35, A_CAP_ALT = 250,
  A_PROF = 2.5, PROF_TAU_LOW = 3,
  GLIDE_TAPER_T = 8.0, GLIDE_TAPER_MIN = 0.25,
  GLIDE_FF = 1.0,
  GLIDE_BIAS_KI = 0.10, GLIDE_BIAS_R = 60, GLIDE_BIAS_VMAX = 1.5,
  DFF_MAX = 0.05,
  GROUND_ALT = 15, GROUND_CAP_G = 1.05, TRIM_GROUND = 0.2,

  ROLL_MAX_ARMS = 4,
  ARMS_ON = true, ARMS_CLOSE = 15, ARMS_OPEN = 0, ARMS_HOLD = false,
  CLAMP_ALT = 25, CLAMP_START_XZ = 4.5, CLAMP_START_V = 1.5, CLAMP_T = 2, CLAMP_LEAD = 0.5,
  FLAPS_ON = true, FLAPS_LEVEL = 15,
  FLAPS_ALT = 120,
  FLAPS_PULSE = true,
  FLAPS_PULSE_T = 0.4,
  -- starship legs
  LEGS_ON = true, LEGS_LEVEL = 15, LEGS_PULSE_T = 0.4,
  LEGS_ALT = 50,
  AIM_X = 2.5, AIM_Z = 0,
  PAD_NAV = true, PAD_VCAP = 15, PAD_GAIN = 0.2, PAD_LAT_DECEL = 0.5, PAD_SPEED_KP = 0.03, PAD_DEADBAND = 0.08, PAD_LEAN_GND = 0.05, PAD_SLEW = 0.06, PAD_LEAN = 0.06,
  PAD_VERT_ALT = 60, PAD_ZERO_ALT = 12,
  PAD_KI = 0.004, PAD_IMAX = 0.06, PAD_I_ALT_MIN = 3, PAD_I_EM = 6,   -- integral on velocity error: learns the constant sideways push that P alone leaves as a steady drift
  PAD_HI_ALT = 300, PAD_LEAN_HI = 0.08, PAD_TGO_K = 2.5, PAD_TGO_V = 20, PAD_TGO_MIN = 3,

  R_TQ_K = 0.0217, R_TQ_CAP = 0.24,   -- R-axis torque cap = weak side (GIM_W/ZAV_L) authority
  REC_TILT = 14, REC_EXIT = 8, REC_VEC = 9, REC_GAIN = 2,
  COAST_ON = false, GLIDE_VEC_MIN = 6, COAST_MISS_ON = 12, COAST_MISS_OFF = 4, COAST_END = 60, COAST_VFALL = 60, DIVERT_MAX = 8,
  LOG = "landing_sh.log",
}
local C = CONFIG
local function isPt(t) return type(t) == "table" and tonumber(t.x) and tonumber(t.y) and tonumber(t.z) end
local calibLoaded = false
local PADMODE = (C.LAND_MODE == "pad")
if C.LAND_MODE ~= "pad" and C.LAND_MODE ~= "chopsticks" then
  print(("unknown LAND_MODE '%s', using chopsticks"):format(tostring(C.LAND_MODE)))
end
if fs.exists("calib.lua") then
  local ok, cal = pcall(dofile, "calib.lua")
  if ok and type(cal) == "table" then
    if PADMODE then
      if isPt(cal.PAD) then
        C.TARGET = { x = cal.PAD.x, y = cal.PAD.y, z = cal.PAD.z }
        calibLoaded = true
        if tonumber(cal.PAD_HDG) then C.ROLL_HDG = cal.PAD_HDG end
      end
    elseif isPt(cal.TARGET) then
      C.TARGET = { x = cal.TARGET.x, y = cal.TARGET.y, z = cal.TARGET.z }
      calibLoaded = true
      if type(cal.ARMS_DIR) == "table" and tonumber(cal.ARMS_DIR.x) and tonumber(cal.ARMS_DIR.z) then
        C.ARMS_DIR = { x = cal.ARMS_DIR.x, z = cal.ARMS_DIR.z }
      end
      if tonumber(cal.ROLL_OFFSET) then C.ROLL_OFFSET = cal.ROLL_OFFSET end
    end
  end
end
if PADMODE then
  C.ARMS_ON = false          -- no tower arms on a ground pad
  C.AIM_X, C.AIM_Z = 0, 0    -- aim offset was tuned for the arms
  C.ARMS_DIR = nil           -- heading comes from PAD_HDG (or the start heading)
end
print(("mode %s, target %.1f %.1f %.1f (%s)"):format(PADMODE and "pad" or "chopsticks", C.TARGET.x, C.TARGET.y, C.TARGET.z, calibLoaded and "calib.lua" or "CONFIG, no calibration for this mode!"))
local G = {
  VEC = 0.1499,
  TOP_F = 0.0096, BOT_F = 0.0058, YAW_R = 0.0133, YAW_L = 0.0144,
  ZAV_L = 0.0016, ZAV_R = 0.0057,
  GIM_N = 0.0045, GIM_S = 0.0039, GIM_W = 0.0013, GIM_E = 0.0040, GIM_REF_VEC = 8,
}
local L = {
  rcs_tl = { "computercraft:printed_page", "computercraft:printed_page" },
  rcs_tr = { "create_connected:shear_pin", "create_connected:shear_pin" },
  rcs_bl = { "computercraft:speaker", "computercraft:speaker" },
  rcs_br = { "computercraft:printer", "computercraft:printer" },
  zav_l = { "minecraft:gold_ingot", "minecraft:gold_ingot" },
  zav_r = { "minecraft:nautilus_shell", "minecraft:nautilus_shell" },
  vac = { "minecraft:armadillo_scute", "minecraft:armadillo_scute" },   -- never used in landing, always held at 0
  vec = { "minecraft:bone_meal", "minecraft:bone_meal" },
  gim_n = { "simulated:rope_coupling", "simulated:rope_coupling" },
  gim_s = { "createpropulsion:oxidizer_bucket", "createpropulsion:oxidizer_bucket" },
  gim_w = { "createpropulsion:tempered_wing", "createpropulsion:tempered_wing" },
  gim_e = { "createpropulsion:solid_burner", "createpropulsion:solid_burner" },
}

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local unpackFn = table.unpack or unpack
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function pos(v) return v > 0 and v or 0 end
local GT = {{0,11},{2000,11},{2017,10.9408},{2500,9.1707},{3000,7.3363},{4000,3.6688},{5000,0.0069}}
local function gAt(alt)
  if alt <= GT[1][1] then return GT[1][2] end
  for i = 2, #GT do
    local a, b = GT[i-1], GT[i]
    if alt <= b[1] then return a[2] + (b[2]-a[2]) * (alt-a[1]) / (b[1]-a[1]) end
  end
  return 0
end

local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "redstone_link_bridge not found")
assert(type(sublevel) == "table" and sublevel.getLogicalPose, "sublevel API not found")

local cache, pending, order, acc = {}, {}, {}, {}
local function out(key, v)               -- fractional leve
  local a = (acc[key] or 0) + clamp(v, 0, 15)
  local o = clamp(math.floor(a + 0.5), 0, 15)
  acc[key] = clamp(a - o, -1, 1)
  if cache[key] ~= o then
    cache[key] = o
    if pending[key] == nil then order[#order + 1] = key end
    pending[key] = o
  end
end
local function flush()
  local n = #order
  if n == 0 then return end
  local ord, lv = order, pending
  order, pending = {}, {}
  local fns = {}
  for i = 1, n do
    local k = ord[i]
    fns[i] = function() bridge.sendLinkSignal(L[k][1], L[k][2], lv[k]) end
  end
  if n == 1 then fns[1]() else parallel.waitForAll(unpackFn(fns)) end
end
local function allZero()
  for k in pairs(L) do acc[k] = 0; out(k, 0) end
  flush()
end

local function quat(q)
  local x, y, z, w
  if type(q.v) == "table" then x, y, z, w = q.v.x, q.v.y, q.v.z, q.a else x, y, z, w = q.x, q.y, q.z, q.w end
  x, y, z, w = tonumber(x), tonumber(y), tonumber(z), tonumber(w)
  if not (x and y and z and w) then return nil end
  local l = math.sqrt(x*x + y*y + z*z + w*w)
  if l < 1e-6 then return nil end
  return x/l, y/l, z/l, w/l
end
local function rot(qx, qy, qz, qw, a, b, c)       -- body world
  local tx, ty, tz = 2*(qy*c - qz*b), 2*(qz*a - qx*c), 2*(qx*b - qy*a)
  return a + qw*tx + (qy*tz - qz*ty), b + qw*ty + (qz*tx - qx*tz), c + qw*tz + (qx*ty - qy*tx)
end
local function read()
  local okp, pose, okv, v, okw, w
  parallel.waitForAll(
    function() okp, pose = pcall(sublevel.getLogicalPose) end,
    function() okv, v = pcall(sublevel.getLinearVelocity) end,
    function() okw, w = pcall(sublevel.getAngularVelocity) end)
  if not (okp and okv and okw and type(pose) == "table" and pose.orientation and pose.position) then return nil end
  local qx, qy, qz, qw = quat(pose.orientation)
  if not qx then return nil end
  local ux, uy, uz = rot(qx, qy, qz, qw, 0, 1, 0)
  local fx, fy, fz = rot(qx, qy, qz, qw, 0, 0, 1)
  local rx, ry, rz = rot(qx, qy, qz, qw, 1, 0, 0)
  local fl, rl = math.sqrt(fx*fx + fz*fz), math.sqrt(rx*rx + rz*rz)
  if fl < 1e-3 or rl < 1e-3 then return nil end
  local wwx, wwy, wwz = rot(qx, qy, qz, qw, w.x, w.y, w.z)   -- angular velocity in world axes
  return {
    px = pose.position.x, py = pose.position.y, pz = pose.position.z,
    vx = v.x, vy = v.y, vz = v.z,
    wR = w.x, wU = w.y, wF = w.z,
    wwx = wwx, wwy = wwy, wwz = wwz,
    ux = ux, uy = uy, uz = uz,
    fx = fx/fl, fz = fz/fl, rx = rx/rl, rz = rz/rl, fy = fy, ry = ry,
    tilt = math.deg(math.acos(clamp(uy, -1, 1))),
  }
end

local function attitude(tF, tR, lc, lw, vecLevel, kT)
  local gs = vecLevel / G.GIM_REF_VEC * kT
  local sh = C.GIM_ON and C.GIM_SHARE * clamp((vecLevel - 1) / 5, 0, 1) or 0   -- gimbal authority ~ thrust
  local rF, rR = tF * (1 - sh), tR * (1 - sh)
  local gF, gR = tF * sh, tR * sh
  local top, bot = pos(-rF) / G.TOP_F, pos(rF) / G.BOT_F
  out("rcs_tl", top / 2 + lc); out("rcs_tr", top / 2 + lw)
  out("rcs_bl", bot / 2 + lc); out("rcs_br", bot / 2 + lw)
  out("zav_l", pos(rR) / G.ZAV_L); out("zav_r", pos(-rR) / G.ZAV_R)
  if vecLevel > 0 and C.GIM_ON then
    out("gim_n", pos(gF) / (G.GIM_N * gs)); out("gim_s", pos(-gF) / (G.GIM_S * gs))
    out("gim_w", pos(gR) / (G.GIM_W * gs)); out("gim_e", pos(-gR) / (G.GIM_E * gs))
  else
    out("gim_n", 0); out("gim_s", 0); out("gim_w", 0); out("gim_e", 0)
  end
end

local logf = fs.open(C.LOG, "w")
local logBytes = 0
local function log(s)
  if logf and logBytes < C.LOG_BUDGET then logf.writeLine(s); logBytes = logBytes + #s + 1 end
end
print(("kT0=%.1f aMax0=%.1f"):format(C.THRUST_MULT, G.VEC * 15 * C.THRUST_MULT))
log(("start landing_sh (165 logic) kT0=%.2f roll_hold=%s roll_sign=%d roll_off=%.1f trim=%.1f arms=%s"):format(C.THRUST_MULT, tostring(C.ROLL_HOLD), C.ROLL_SIGN, C.ROLL_OFFSET, C.ROLL_TRIM, C.ARMS_DIR and "yes" or "no"))
print("Started, Ctrl+T aborts")

-- accel
local function vecFor(aDes, kT)
  if aDes <= 0.5 then return 0 end
  return clamp(aDes / (G.VEC * kT), C.VEC_MIN, 15)
end

local ARMS = { "minecraft:stone", "minecraft:stone" }
local function setArms(level)
  if not C.ARMS_ON then return end
  local ok, e = pcall(bridge.sendLinkSignal, ARMS[1], ARMS[2], level)
  if not ok then print("arms signal error: " .. tostring(e)) end
end
local clampT0, clampEnd = nil, nil
local function startClamp()
  if C.ARMS_ON and not clampT0 then
    clampT0 = os.clock()
    setArms(C.ARMS_CLOSE)
    log(("ARMS CLOSE sent t=%.2f"):format(clampT0)); print("arms close sent")
  end
end
local function releaseArms(now)
  if clampT0 and clampEnd and not C.ARMS_HOLD and now - clampEnd >= C.CLAMP_T then
    setArms(C.ARMS_OPEN)
    clampT0 = nil
    log("ARMS RELEASED (signal cancelled)"); print("arms signal cancelled")
  end
end
setArms(C.ARMS_OPEN)

local function rampDown(a0, kT)
  for k in pairs(L) do if k ~= "vec" then acc[k] = 0; out(k, 0) end end
  local t0 = os.clock()
  while true do
    local el = os.clock() - t0
    releaseArms(os.clock())
    if el >= C.THRUST_RAMP then break end
    out("vec", vecFor(a0 * (1 - el / C.THRUST_RAMP), kT)); flush()
    sleep(0.05)
  end
  log("RAMP DONE"); print("engines off: thrust ramped down"); allZero()
end
local function endFlight(reason, d, a0, kT)
  log(("END(%s) dist=%.2f a0=%.1f%s"):format(reason, d, a0, d > C.MISS_XZ and " OFF-PAD" or ""))
  print(("landed (%s), %.1f m from the pad centre"):format(reason, d))
  clampEnd = os.clock()
  if d <= C.MISS_XZ then
    startClamp()
    if C.ARMS_ON then print("arms closed (" .. reason .. ")") end
  elseif clampT0 then
    setArms(C.ARMS_OPEN); clampT0 = nil; log("ARMS OPENED (miss)")
  end
  rampDown(a0, kT)
end

local FLAPS = { "create:shaft", "createendertransmission:energy_transmitter" }
local flapsDone, flapsOffAt = false, nil
local function closeFlaps()      -- called once, at engine ignition (just before landing)
  if flapsDone or not C.FLAPS_ON then return end
  flapsDone = true
  pcall(bridge.sendLinkSignal, FLAPS[1], FLAPS[2], C.FLAPS_LEVEL)
  if C.FLAPS_PULSE then flapsOffAt = os.clock() + C.FLAPS_PULSE_T end
  log("FLAPS closed (link level " .. C.FLAPS_LEVEL .. ")")
  print("flaps: closing")
end
local LEGS = { "minecraft:birch_button", "minecraft:birch_button" }
local legsDone, legsOffAt = false, nil
local function openLegs()        -- called once, pad mode only
  if legsDone or not C.LEGS_ON or C.LAND_MODE ~= "pad" then return end
  legsDone = true
  pcall(bridge.sendLinkSignal, LEGS[1], LEGS[2], C.LEGS_LEVEL)
  legsOffAt = os.clock() + C.LEGS_PULSE_T
  log("LEGS pulse sent")
  print("legs: opening")
end
local function flapsTick()       -- non-blocking end of the pulses
  if flapsOffAt and os.clock() >= flapsOffAt then
    flapsOffAt = nil
    pcall(bridge.sendLinkSignal, FLAPS[1], FLAPS[2], 0)
  end
  if legsOffAt and os.clock() >= legsOffAt then
    legsOffAt = nil
    pcall(bridge.sendLinkSignal, LEGS[1], LEGS[2], 0)
  end
end

local padIx, padIz = 0, 0
local function padLean(dx, dz, dist, vx, vz, alt, cap, vs, dt)
  -- seek: fades the "fly to pad" term near the ground; velocity damping stays on
  local seek = clamp((alt - C.PAD_ZERO_ALT) / (C.PAD_VERT_ALT - C.PAD_ZERO_ALT), 0, 1)
  local ux, uz, des = 0, 0, 0
  if dist > 0.3 then
    ux, uz = dx / dist, dz / dist
    des = math.min(C.PAD_VCAP, dist * C.PAD_GAIN, math.sqrt(2 * C.PAD_LAT_DECEL * dist))
    local tgo = math.max(alt / math.max(-vs, C.PAD_TGO_V), C.PAD_TGO_MIN)
    des = math.min(des, C.PAD_TGO_K * dist / tgo) * seek
  end
  if alt > C.PAD_HI_ALT then cap = math.min(cap, C.PAD_LEAN_HI) end
  if alt < C.PAD_ZERO_ALT then cap = math.min(cap, C.PAD_LEAN_GND) end
  -- velocity error vector: covers along-track and cross-track together
  local ex, ez = ux * des - vx, uz * des - vz
  local em = math.sqrt(ex * ex + ez * ez)
  if alt > C.PAD_I_ALT_MIN and em < C.PAD_I_EM then
    padIx = clamp(padIx + C.PAD_KI * ex * dt, -C.PAD_IMAX, C.PAD_IMAX)
    padIz = clamp(padIz + C.PAD_KI * ez * dt, -C.PAD_IMAX, C.PAD_IMAX)
  end
  if em < C.PAD_DEADBAND then return padIx, padIz end
  local l = math.min(C.PAD_SPEED_KP * (em - C.PAD_DEADBAND), cap)
  return ex / em * l + padIx, ez / em * l + padIz
end

local function run()
  local recov = false
  local burn, trim, burnT0 = false, 0, 0
  local kT = C.THRUST_MULT
  local rF, rR, last = 0, 0, os.clock()
  local pdF, pdR, pA = 0, 0, 0
  local pvs, puy
  local n, stale, lastSig = 0, 0, nil
  local first, still, rest = true, 0, 0
  local iF, iR = 0, 0
  local rSat = false
  local aligned, holdS, holdUsed = false, C.HOLD_ALT, 0
  local pdesVS = 0
  local glide = false
  local coast, divert, divT = false, false, 0
  local gvw = 0
  local rollHead = 0
  local staleLogged = false
  local ctReg = false
  local rollI = 0
  local biasX, biasZ = 0, 0
  local holdLatch, holdWait = false, 0
  while true do
    local s = read()
    if not s then allZero(); sleep(0.05)
    else
      local now = os.clock(); local dt = clamp(now - last, 0.02, 0.5); last = now
      flapsTick()
      -- feet point
      local fd = -C.DECK_ALT
      local rx_, ry_, rz_ = fd * s.ux, fd * s.uy, fd * s.uz
      local finX, finY, finZ = s.px + rx_, s.py + ry_, s.pz + rz_
      local fvx = s.vx + (s.wwy * rz_ - s.wwz * ry_)
      local fvz = s.vz + (s.wwx * ry_ - s.wwy * rx_)
      local alt = finY - C.TARGET.y
      local altc = math.max(alt, 0)
      if alt < C.LEGS_ALT then openLegs() end
      -- control point
      local kcp
      if altc < C.POS_ROT_ALT then kcp = C.CP_LOW - (C.CP_LOW - C.CP_K) * altc / C.POS_ROT_ALT
      else kcp = C.CP_K * clamp((C.BODY_FADE - altc) / (C.BODY_FADE - C.POS_ROT_ALT), 0, 1) end
      local cOff = fd * kcp
      local cx, cz = s.px + cOff * s.ux, s.pz + cOff * s.uz
      local vcom = math.sqrt(s.vx * s.vx + s.vz * s.vz)
      local nvx, nvz = s.vx + (fvx - s.vx) * kcp * C.KFV, s.vz + (fvz - s.vz) * kcp * C.KFV
      local vs = s.vy
      local g = gAt(alt)
      local dx, dz = C.TARGET.x + C.AIM_X - cx, C.TARGET.z + C.AIM_Z - cz
      local dist = math.sqrt(dx*dx + dz*dz)
      local tdist = math.sqrt((C.TARGET.x - finX)^2 + (C.TARGET.z - finZ)^2)
      local vhor = math.sqrt(fvx*fvx + fvz*fvz)
      if first then
        first = false
        do
          local lx0, lz0
          if C.HDG_AXIS == "F" then lx0, lz0 = s.fx, s.fz else lx0, lz0 = s.rx, s.rz end
          rollHead = atan2(lz0 * C.HDG_SIGN, lx0 * C.HDG_SIGN)
        end
        log(("INIT alt=%.1f dist=%.1f pos=%.1f,%.1f,%.1f target=%.1f,%.1f,%.1f calib=%s"):format(alt, dist, s.px, s.py, s.pz, C.TARGET.x, C.TARGET.y, C.TARGET.z, calibLoaded and "yes" or "no"))
        print(("alt %.0f m, distance to the pad %.0f m"):format(alt, dist))
        if dist > C.NAV_WARN then print(("WARNING: pad is %.0f m away"):format(dist)) end
      end

      local th = math.rad(s.tilt)
      local sn = math.sin(th)
      local kA = (sn > 1e-3) and th / sn or 0
      local leanF, leanR = -s.fy * kA, -s.ry * kA
      if sn <= 1e-3 and s.uy < 0 then leanF = th end
      rF = rF + (s.wR - rF) * C.RATE_SMOOTH
      rR = rR + (-s.wF - rR) * C.RATE_SMOOTH

      if burn and pvs and pvs < -2 and dt < 0.3 and (vs - pvs) / dt > C.IMPACT_ACC and alt < C.IMPACT_ALT and (math.abs(s.vx) + math.abs(s.vy) + math.abs(s.vz)) > 1e-3 then
        log(("LANDED(impact) alt=%.2f pvs=%.1f vs=%.1f tilt=%.1f dist=%.2f"):format(alt, pvs, vs, s.tilt, tdist))
        return endFlight("impact", tdist, pA, kT)
      end
      if burn and math.abs(vs) < C.STILL_VS and (alt < C.STILL_ALT or (alt < C.STILL_ALT_HI and pdesVS < -1.5)) then still = still + dt else still = 0 end
      if still > C.STILL_T then
        log(("LANDED(still) alt=%.2f tilt=%.1f dist=%.2f"):format(alt, s.tilt, tdist))
        return endFlight("still", tdist, pA, kT)
      end

      local thrA = G.VEC * (cache.vec or 0) * kT * s.uy
      if burn and alt < C.STILL_ALT_HI and math.abs(vs) < C.REST_VS and thrA < C.REST_G * g then rest = rest + dt else rest = 0 end
      if rest > C.REST_T then
        log(("LANDED(rest) alt=%.2f tilt=%.1f dist=%.2f thr=%.1f"):format(alt, s.tilt, tdist, thrA))
        return endFlight("rest", tdist, pA, kT)
      end

      if C.ADAPT and (burn or glide) and math.abs(vs) < C.ADAPT_VMAX and pvs and dt < 0.3 and stale == 0 and rest == 0 and math.abs(vs - pvs) > 1e-4 then
        local expected = G.VEC * (cache.vec or 0) * puy
        if expected > C.ADAPT_EXP_MIN then
          local meas = (vs - pvs) / dt + g + C.DRAG_K * vs * math.abs(vs)
          kT = clamp(kT + C.ADAPT_K * (clamp(meas / expected, 1, 20) - kT), C.KT_MIN, C.KT_MAX)
        end
      end
      pvs, puy = vs, s.uy

      coast = false
      local aMax = G.VEC * 15 * kT
      local stop = 0
      if vs < 0 then
        local vL = math.max(-vs - C.TOUCH_VS, 0)
        stop = C.A_PROF > 0 and (vL * vL / (2 * C.A_PROF) + vL * C.BURN_LAG * 0.5) or vL * (C.PROF_TAU + C.BURN_LAG * 0.5)
        if C.CONST_ON then
          local aNet = math.max(G.VEC * C.CT_VEC * kT - g, 0.5)
          local vh = C.CT_HAND_VS > 0 and C.CT_HAND_VS or C.TOUCH_VS
          stop = C.CT_END + math.max(vs * vs - vh * vh, 0) / (2 * aNet) + (-vs) * C.CT_LAG
        end
      end
      if not burn and alt < stop + (C.CONST_ON and 0 or C.GATE_ALT) + C.GLIDE_SLOPE * dist + C.GLIDE_NEAR * math.min(dist, C.NEAR_R) then
        burn = true; burnT0 = now; glide = false
        openLegs()
        pdF, pdR = pdF * 0.45, pdR * 0.45
        log(("BURN alt=%.1f vs=%.1f kT=%.2f dist=%.1f"):format(alt, vs, kT, dist))
        if dist > 3 or vcom > 1.5 then log(("BURN OFF-TARGET dist=%.1f vc=%.2f tilt=%.1f"):format(dist, vcom, s.tilt)) end
      end
      if burn and alt + math.min(vs, 0) * C.CLAMP_LEAD < C.CLAMP_ALT and ((dist < C.CLAMP_START_XZ and vcom < C.CLAMP_START_V and s.tilt < C.CATCH_TILT * 2) or (alt < 4 and dist < C.MISS_XZ and s.tilt < 10)) then startClamp() end
      if burn and alt <= C.CUT_ALT then
        log(("CUTOFF alt=%.2f vs=%.2f tilt=%.1f dist=%.2f vh=%.2f%s"):format(alt, vs, s.tilt, tdist, vhor, tdist > C.MISS_XZ and " OFF-PAD" or ""))
        return endFlight("cutoff", tdist, pA, kT)
      end

      local desF, desR, dF, dR = 0, 0, 0, 0
      local vec, aDes, desVS, hLog = 0, 0, 0, 0
      local cr = false
      local fnl = 0
      if burn then
        if aligned then
          if alt > C.COMMIT_BODY and (dist > C.EXIT_XZ or vcom > C.EXIT_VH or s.tilt > C.CATCH_TILT * 2) then aligned = false end
        elseif dist < C.CATCH_XZ and vcom < C.CATCH_VH and s.tilt < C.CATCH_TILT then aligned = true end
        local funnel = (alt < C.COMMIT_ALT or holdUsed > C.HOLD_MAX) and 0 or (C.GLIDE_SLOPE * pos(dist - C.GLIDE_R0) + C.GLIDE_NEAR * clamp(dist - C.GLIDE_R0, 0, C.NEAR_R))
        fnl = funnel
        if alt < C.HOLD_ALT + funnel + 3 and holdS > 0 then holdUsed = holdUsed + dt end
        local holdT = (aligned or alt < C.COMMIT_ALT or holdUsed > C.HOLD_MAX) and 0 or C.HOLD_ALT
        holdS = holdS + clamp(holdT - holdS, -C.HOLD_RATE * dt, 40 * dt)
        local h = alt - (holdS + funnel)
        hLog = h
        local vt = math.max(C.HOLD_ALT > 0 and C.TOUCH_VS * (1 - holdS / C.HOLD_ALT) or C.TOUCH_VS, 0)
        local closing = dist > 0.5 and math.max((dx * fvx + dz * fvz) / dist, 0) or 0
        local sEff = C.GLIDE_SLOPE + ((dist > C.GLIDE_R0 and dist < C.GLIDE_R0 + C.NEAR_R) and C.GLIDE_NEAR or 0)
        local vff = funnel > 0 and sEff * closing or 0
        local vProf = vt + (C.A_PROF > 0 and math.min(math.sqrt(2 * C.A_PROF * math.max(h, 0)), math.max(h, 0) / C.PROF_TAU_LOW) or math.max(h, 0) / C.PROF_TAU)
        if h >= 0 then desVS = -math.min(C.MAX_DESC, vProf + vff) else desVS = math.min(C.MAX_CLIMB, -0.5 * h) - vff end
        local ev = desVS - vs
        local floorK = 1
        if ev < -C.FLOOR_EV0 and alt > C.FLOOR_RELAX_ALT then floorK = clamp(1 + (ev + C.FLOOR_EV0) * C.FLOOR_EV_K, C.FLOOR_MIN_K, 1) end
        if math.abs(ev) < 5 then trim = clamp(trim + C.TRIM_KI * ev * dt, -C.TRIM_LIM, C.TRIM_LIM) end
        aDes = clamp(math.max(g + trim + C.VS_KP_TR * ev, 0) / math.max(s.uy, 0.5), 0, aMax * 0.95)
        if s.uy < 0.2 then aDes = 0 end
        if s.uy >= 0.2 then
          aDes = math.max(aDes, C.TRACK_FLOOR * floorK * g / math.max(s.uy, 0.5))
          if pA > 0 then aDes = clamp(aDes, pA - C.A_SLEW_TR * dt, pA + C.A_SLEW_UP * dt) end
          aDes = math.min(aDes, aMax * 0.95)
        end
        if s.tilt > C.TILT_THR and alt > 200 then aDes = aDes * clamp(1 - (s.tilt - C.TILT_THR) / C.TILT_THR_W, 0.15, 1) end
        if alt <= C.FLOOR_ALT and s.uy >= 0.2 then
          aDes = math.max(aDes, C.A_FLOOR * floorK * g / math.max(s.uy, 0.5), pA - C.A_FALL * dt)
          aDes = math.min(aDes, aMax * 0.95)
        end
        aDes = math.min(aDes, pA + C.A_RISE * dt)
        if alt < C.A_CAP_ALT and ev < 1 and s.uy >= 0.2 then aDes = math.min(aDes, C.A_CAP_G * g / math.max(s.uy, 0.5)) end
        if alt < C.GROUND_ALT then
          trim = math.min(trim, C.TRIM_GROUND)
          if ev < 0.5 and s.uy >= 0.2 then aDes = math.min(aDes, C.GROUND_CAP_G * g / math.max(s.uy, 0.5)) end
        end

        if C.BURN_VEC_MIN > 0 and alt > C.GROUND_ALT and s.uy >= 0.2 then
          aDes = math.max(aDes, G.VEC * C.BURN_VEC_MIN * kT)
        end

        local ml = clamp(C.ML_BASE + 0.0004 * alt, C.ML_MIN, C.MAX_LEAN)
        local qd = math.sqrt((dx - nvx * C.BRAKE_LAG)^2 + (dz - nvz * C.BRAKE_LAG)^2)
        ml = math.min(ml, C.ML_0 + C.ML_K * math.max(dist, qd) + C.ML_V * vcom)
        if aligned or alt < C.COMMIT_ALT + 4 then ml = math.min(ml, C.ML_NEAR) end
        if alt < C.LOW_ALT then ml = math.min(ml, C.ML_LOW) end
        local pdx, pdz = dx - nvx * C.BRAKE_LAG, dz - nvz * C.BRAKE_LAG
        local pdist = math.sqrt(pdx*pdx + pdz*pdz)
        local aref = math.max(aDes, g)
        local tg = clamp(2 * math.max(h, 0.1) / (math.abs(vs) + C.TOUCH_VS), C.EG_TMIN, 120)
        tg = math.min(tg, math.max(C.TRACK_TG, 3 + dist / 4))
        tg = math.min(math.max(tg, C.BRAKE_FRAC * 2 * math.sqrt(math.max(dist, pdist) / math.max(ml * aref, 0.5))), 120)
        local ramp = clamp((now - burnT0) / C.NAV_RAMP, 0, 1)
        local ax = (6 * pdx / (tg * tg) - 5.5 * nvx / tg) * ramp
        local az = (6 * pdz / (tg * tg) - 5.5 * nvz / tg) * ramp

        biasX = clamp(biasX + C.BIAS_KI * ax * dt, -C.BIAS_MAX, C.BIAS_MAX)
        biasZ = clamp(biasZ + C.BIAS_KI * az * dt, -C.BIAS_MAX, C.BIAS_MAX)
        ax, az = ax + biasX, az + biasZ
        local cs = dist > 0.5 and (dx * nvx + dz * nvz) / dist or 0
        local over = math.max(cs - (C.CLOSE_V0 + C.CLOSE_VK * dist), 0)
        if over > 0 then ax = ax - over * C.CLOSE_KB * dx / dist; az = az - over * C.CLOSE_KB * dz / dist end
        local wx, wz = ax / aref, az / aref
        local wm = math.sqrt(wx*wx + wz*wz)
        if wm > ml then wx, wz = wx * ml / wm, wz * ml / wm end
        if PADMODE and C.PAD_NAV then wx, wz = padLean(dx, dz, dist, nvx, nvz, alt, math.min(ml, C.PAD_LEAN), vs, dt) end
        local tf = clamp(1 - (s.tilt - C.TILT_SAFE) / (C.TILT_SAFE * 1.5), 0, 1)
        desF = (wx * s.fx + wz * s.fz) * tf
        desR = (wx * s.rx + wz * s.rz) * tf
        local mx = (PADMODE and C.PAD_NAV and C.PAD_SLEW or C.LEAN_SLEW) * dt
        desF = pdF + clamp(desF - pdF, -mx, mx)
        desR = pdR + clamp(desR - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt

        vec = vecFor(aDes, kT)
        if C.CONST_ON and not ctReg and C.CT_HAND_VS > 0 and (cache.vec or 0) > 0 and vs > -C.CT_HAND_VS then
          ctReg = true; log(("CT HANDOFF alt=%.1f vs=%.1f dist=%.1f vc=%.2f"):format(alt, vs, dist, vcom))
        end
        if C.CONST_ON and not ctReg then
          local isOn = (cache.vec or 0) > 0
          local thr = (isOn and C.CT_HAND_VS > 0) or (vs < 0 and alt < stop + (isOn and C.CT_OFF_MARGIN or C.CT_ON_MARGIN))
          vec = thr and C.CT_VEC or 0
          aDes = G.VEC * vec * kT
        end
        pA = aDes
      elseif s.uy > 0.5 then
        if not glide then gvw = vhor end
        glide = true; cr = true
        local aT = G.VEC * (cache.vec or 0) * kT
        local nvx, nvz = nvx + C.GLIDE_LEAD * aT * s.ux, nvz + C.GLIDE_LEAD * aT * s.uz
        local tgo = math.max((alt - C.GLIDE_GATE) / math.max(-vs, 10), C.GLIDE_TMIN)
        local tB = (alt - stop) / math.max(-vs, 10)
        local clos = dist > 0.5 and (nvx * dx + nvz * dz) / dist or 0
        do 
          local tf_ = math.max((alt - stop) / math.max(-vs, C.COAST_VFALL), 0.5)
          local mx_, mz_ = dx - nvx * tf_, dz - nvz * tf_
          local miss = math.sqrt(mx_ * mx_ + mz_ * mz_)
          if divert then divT = divT + dt end
          if divT < C.DIVERT_MAX and alt > stop + C.COAST_END and miss > C.COAST_MISS_ON then
            if not divert then log(("DIVERT on alt=%.0f miss=%.1f"):format(alt, miss)) end
            divert = true
          elseif miss < C.COAST_MISS_OFF or divT >= C.DIVERT_MAX or alt <= stop + C.COAST_END then
            if divert then log(("DIVERT off alt=%.0f miss=%.1f"):format(alt, miss)) end
            divert = false
          end
          coast = C.COAST_ON and not divert
        end
        local errK = clamp((dist - 0.8) / 3 + (math.abs(clos) - 0.2) / 1.0, 0, 1) 
        local leanCap = C.GLIDE_LEAN * clamp(tB / C.GLIDE_TAPER_T, math.max(C.GLIDE_TAPER_MIN, errK), 1)
        if alt < C.GLIDE_LOW_ALT and dist < C.GLIDE_LOW_R and nvx * nvx + nvz * nvz < C.GLIDE_LOW_V ^ 2 then leanCap = math.min(leanCap, C.GLIDE_LEAN_LOW) end
        local vw = 0
        local brk = false
        local dEff = dist - math.max(clos, 0) * C.GLIDE_LAG
        if dEff > C.NAV_DEAD then
          vw = math.min(C.NAV_MAX, dist / tgo)
          local vb = math.sqrt(2 * leanCap * g * C.NAV_PK * (dEff - C.NAV_DEAD))
          if vb < vw then vw = vb; brk = true end
        elseif clos > 0.5 then
          brk = true 
        end
        gvw = gvw + clamp(vw - gvw, -C.GLIDE_VW_RATE * dt, C.GLIDE_VW_RATE * dt)
        vw = gvw
        local ux, uz = 0, 0
        if dist > 0.5 then ux, uz = dx / dist, dz / dist end
        local ax = C.GLIDE_NAV_KP * (ux * vw - nvx)
        local az = C.GLIDE_NAV_KP * (uz * vw - nvz)
        if brk then
          local vcl = nvx * ux + nvz * uz
          local ffk = clamp(vcl / math.max(vw, 0.5), 0, 1) * C.GLIDE_FF
          local ab = leanCap * g * C.NAV_PK * ffk
          ax = ax - ux * ab; az = az - uz * ab
        end
        if dist < C.GLIDE_BIAS_R then
          if nvx * nvx + nvz * nvz < C.GLIDE_BIAS_VMAX ^ 2 then
            biasX = clamp(biasX + C.GLIDE_BIAS_KI * ax * dt, -C.BIAS_MAX, C.BIAS_MAX)
            biasZ = clamp(biasZ + C.GLIDE_BIAS_KI * az * dt, -C.BIAS_MAX, C.BIAS_MAX)
          end
        else
          biasX, biasZ = biasX * math.max(1 - dt, 0), biasZ * math.max(1 - dt, 0)
        end
        ax, az = ax + biasX, az + biasZ
        local vTgt = C.COAST_ON and math.max(-vs, C.GLIDE_VS) or C.GLIDE_VS
        if C.GLIDE_HOLD and not holdLatch and alt < C.GLIDE_HOLD_ALT + C.GLIDE_HOLD_BAND then
          if (tdist < C.GLIDE_HOLD_TD and vcom < C.GLIDE_HOLD_V) or holdWait > C.GLIDE_HOLD_MAX then
            holdLatch = true
            log(("HOLD RELEASE alt=%.1f td=%.2f vc=%.2f tilt=%.1f waited=%.1fs%s"):format(alt, tdist, vcom, s.tilt, holdWait, holdWait > C.GLIDE_HOLD_MAX and " TIMEOUT" or ""))
          else
            vTgt = C.GLIDE_VS * clamp((alt - C.GLIDE_HOLD_ALT) / C.GLIDE_HOLD_BAND, 0, 1)
            if alt < C.GLIDE_HOLD_ALT + 5 then holdWait = holdWait + dt end
          end
        end
        local ev = -vTgt - vs
        aDes = clamp((g + C.GLIDE_KP * ev) / math.max(s.uy, 0.5), G.VEC * C.GLIDE_VEC_MIN * kT, aMax * 0.95)
        aDes = math.min(aDes, pA + C.A_RISE * dt)
        local aref = math.max(aDes, g)
        local wx, wz = ax / aref, az / aref
        local wm = math.sqrt(wx*wx + wz*wz)
        if wm > leanCap then wx, wz = wx * leanCap / wm, wz * leanCap / wm end
        if PADMODE and C.PAD_NAV then wx, wz = padLean(dx, dz, dist, nvx, nvz, alt, math.min(leanCap, C.PAD_LEAN), vs, dt) end
        local tf = clamp(1 - (s.tilt - C.TILT_SAFE) / (C.TILT_SAFE * 1.5), 0, 1)
        local mx = (PADMODE and C.PAD_NAV and C.PAD_SLEW or C.LEAN_SLEW) * dt
        desF = pdF + clamp((wx * s.fx + wz * s.fz) * tf - pdF, -mx, mx)
        desR = pdR + clamp((wx * s.rx + wz * s.rz) * tf - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt
        vec = vecFor(aDes, kT)
        pA = aDes
        if coast then aDes = 0; vec = 0; pA = 0; desF, desR, dF, dR = 0, 0, 0, 0 end
      end
      if PADMODE and C.REC_TILT > 0 then
        if not recov and s.tilt > C.REC_TILT and s.uy > 0.2 then recov = true; log(("RECOVERY on tilt=%.1f alt=%.1f"):format(s.tilt, alt))
        elseif recov and (s.tilt < C.REC_EXIT or s.uy <= 0.2) then recov = false; log(("RECOVERY off tilt=%.1f alt=%.1f"):format(s.tilt, alt)) end
      end
      if recov and (burn or cr) then
        desF, desR, dF, dR = 0, 0, 0, 0
        if not coast and not (burn and alt < 40) then
          local ar = G.VEC * C.REC_VEC * kT / math.max(s.uy, 0.5)
          if aDes < ar then aDes = ar; vec = vecFor(aDes, kT); pA = aDes end
        end
      end
      pdF, pdR = desF, desR
      pdesVS = desVS
      if not burn and not cr then pA = 0 end

      if burn or cr then
        local ie = cr and C.ATT_I_ERR_C or C.ATT_I_ERR
        local lm = math.sqrt(leanF * leanF + leanR * leanR)
        if lm > C.LEAN_HARD then
          iF, iR = 0, 0
        elseif s.tilt < 35 and math.abs(desF - leanF) < ie and math.abs(desR - leanR) < ie then
          if math.abs(rF) < C.ATT_I_RATE and math.abs(rR) < C.ATT_I_RATE then
            local kI = cr and C.ATT_KI_C or C.ATT_KI
            iF = clamp(iF + kI * (desF - leanF) * dt, -C.ATT_IMAX, C.ATT_IMAX)
            if not rSat then iR = clamp(iR + kI * (desR - leanR) * dt, -C.ATT_IMAX, C.ATT_IMAX) end
          end
        else
          local bl = cr and 3.0 or 1.0
          iF, iR = iF * math.max(1 - bl * dt, 0), iR * math.max(1 - bl * dt, 0)
        end
      else iF, iR = iF * math.max(1 - 2 * dt, 0), iR * math.max(1 - 2 * dt, 0) end
      dF, dR = clamp(dF, -C.DFF_MAX, C.DFF_MAX), clamp(dR, -C.DFF_MAX, C.DFF_MAX)
      local kk = recov and C.REC_GAIN or 1
      local tF = kk * (C.KP * (desF - leanF) + C.KD * (dF - rF)) + iF
      local tR = kk * (C.KP * (desR - leanR) + C.KD * (dR - rR)) + iR
      rSat = false
      if vec >= 6 then   -- symmetric R cap: strong side (E/zav_r) must not exceed what weak side (W/zav_l) can brake
        local trMax = math.min(C.R_TQ_CAP, C.R_TQ_K * vec / G.GIM_REF_VEC * kT)
        if math.abs(tR) > trMax then rSat = true; tR = clamp(tR, -trMax, trMax) end
      end

      local lc, lw = 0, 0
      local yawErr = 0
      if C.ROLL_ON and stale < C.STALE_LOOPS and alt < C.ROLL_ALT_MAX and alt > C.ROLL_ALT_MIN and s.tilt < C.ROLL_TILT_MAX then
        local lx, lz
        if C.HDG_AXIS == "F" then lx, lz = s.fx, s.fz else lx, lz = s.rx, s.rz end
        lx, lz = lx * C.HDG_SIGN, lz * C.HDG_SIGN
        local want = rollHead
        if not C.ROLL_HOLD then
          if C.ARMS_DIR then want = atan2(C.ARMS_DIR.z, C.ARMS_DIR.x) + math.rad(C.ROLL_OFFSET + C.ROLL_TRIM)
          elseif C.ROLL_HDG then want = math.rad(C.ROLL_HDG) end
        end
        local e = want - atan2(lz, lx)
        e = (e + math.pi) % (2 * math.pi) - math.pi
        yawErr = math.deg(e)
        if math.abs(yawErr) < C.ROLL_DEAD then e = 0 end
        if math.abs(yawErr) < 12 and math.abs(s.wU) < 0.03 then rollI = clamp(rollI + C.ROLL_KI * e * dt, -C.ROLL_IMAX, C.ROLL_IMAX) else rollI = rollI * math.max(1 - 2 * dt, 0) end
        if e * rollI < 0 then rollI = rollI * math.max(1 - 4 * dt, 0) end
        local u = C.ROLL_SIGN * (C.ROLL_KP * e + rollI + C.ROLL_KD * s.wU)
        local rmax = clampT0 and C.ROLL_MAX_ARMS or C.ROLL_MAX
        lc, lw = clamp(u * C.ROLL_K, 0, rmax), clamp(-u * C.ROLL_K, 0, rmax)
        if lc < C.ROLL_MIN then lc = 0 end
        if lw < C.ROLL_MIN then lw = 0 end
      else
        rollI = 0
        local ty = -C.KDY * s.wU 
        lc, lw = pos(-ty) / G.YAW_L, pos(ty) / G.YAW_R
      end

      local frozen = stale >= C.STALE_LOOPS or (math.abs(s.vx) < 1e-4 and math.abs(s.vy) < 1e-4 and math.abs(s.vz) < 1e-4)
      attitude(frozen and 0 or tF, frozen and 0 or tR, frozen and 0 or lc, frozen and 0 or lw, frozen and (cache.vec or 0) or vec, kT)
      out("vac", 0)
      if not frozen then out("vec", vec) end
      flush()
      n = n + 1
      if (n % 5 == 0 or alt < 300) and logf then logf.flush() end
      local sig = s.py + s.vy + s.ux + s.wR
      local zeros = math.abs(s.vx) < 1e-4 and math.abs(s.vy) < 1e-4 and math.abs(s.vz) < 1e-4 and math.abs(s.wR) < 1e-4 and math.abs(s.wF) < 1e-4
      if (lastSig and math.abs(sig - lastSig) < 1e-4) or zeros then stale = stale + 1 else stale = 0 end
      lastSig = sig
      if stale >= C.STALE_LOOPS and not staleLogged then staleLogged = true; log(("STALE onset alt=%.1f vs=%.2f"):format(alt, vs)) end
      local c = cache
      log(("%.1f a=%.1f h=%.1f vs=%.2f/%.2f vh=%.2f dist=%.2f tilt=%.1f l=%.3f,%.3f d=%.3f,%.3f t=%.3f,%.3f aDes=%.1f kT=%.2f trim=%.2f hold=%.1f al=%d vec=%d rcs=%d,%d,%d,%d zav=%d,%d gim=%d,%d,%d,%d b=%d dt=%.2f v=%.2f,%.2f dd=%.2f,%.2f yaw=%.1f roll=%.1f,%.1f p=%.1f,%.1f,%.1f vc=%.2f wu=%.3f ri=%.3f td=%.2f iF=%.3f iR=%.3f pi=%.3f,%.3f")
        :format(now, alt, hLog, vs, desVS, vhor, dist, s.tilt, leanF, leanR, desF, desR, tF, tR,
          aDes, kT, trim, holdS + fnl, aligned and 1 or 0, c.vec or 0,
          c.rcs_tl or 0, c.rcs_tr or 0, c.rcs_bl or 0, c.rcs_br or 0, c.zav_l or 0, c.zav_r or 0,
          c.gim_n or 0, c.gim_s or 0, c.gim_w or 0, c.gim_e or 0, burn and 1 or 0, dt, s.vx, s.vz, dx, dz, yawErr,
          lc, lw, s.px, s.py, s.pz, vcom, s.wU, rollI, tdist, iF, iR, padIx, padIz))
      if stale >= C.STALE_LOOPS and burn and alt < 15 then
        log(("LANDED(stale) alt=%.2f tdist=%.2f tilt=%.1f"):format(alt, tdist, s.tilt))
        return endFlight("stale", tdist, pA, kT)
      end
      if stale >= C.STALE_ABORT then log("STALE sensors -> abort"); allZero(); print("sensors frozen"); return end
    end
  end
end

closeFlaps()   -- flaps: one press at the start of the landing script
local ok, err = pcall(run)
if not ok then log("ERROR: " .. tostring(err)) end
allZero()
if clampT0 and not clampEnd then clampEnd = os.clock() end
while clampT0 and clampEnd and not C.ARMS_HOLD and os.clock() - clampEnd < C.CLAMP_T do sleep(0.1) end
releaseArms(os.clock())
if logf then logf.close() end
if not ok then error(err, 0) end
print("done")