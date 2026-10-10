local CONFIG = {
  TARGET = { x = -2892, y = 209.9, z = 6278 }, CATCH_DY = -31.6,
  GRAVITY = 11,
  THRUST_MULT = 5.6, ADAPT = true, ADAPT_K = 0.03, KT_MIN = 2.0, KT_MAX = 10,
  DRAG_K = 0.0004,
  KP = 0.45, KD = 1.1, RATE_SMOOTH = 0.7, MAIN_K = 1.4,
  ATT_KI = 0.10, ATT_KI_C = 0.30, ATT_IMAX = 0.08, ATT_I_ERR = 0.07,
  GIM_SHARE = 0.9, GIM_ON = true,
 
  RCS_SIGN_F = 1, RCS_SIGN_R = 1, GIM_SIGN_F = 1, GIM_SIGN_R = 1, -- signs
  
  FINE_MID = 4, MIN_FINE = 1,
  VS_KP = 2.5, TRIM_KI = 0.25, TRIM_LIM = 2,
  A_LAND_FRAC = 0.55, A_LAND_MAX = 8, LAND_MARGIN = 1.3, A_RISE = 40, BURN_LAG = 2.0,
 
  TOUCH_VS = 1.5, MAX_DESC = 200,
  HOLD_ALT = 0, HOLD_RATE = 6.0, A_FINAL = 2.5, FINAL_VS = 3.0, ML_NEAR = 0.05,
  HOLD_MAX = 60, COMMIT_ALT = 2, COMMIT_BODY = 78,
  BRAKE_FRAC = 1.3, BRAKE_LAG = 3.5,
  CATCH_XZ = 2, CATCH_VH = 1.2, EXIT_XZ = 4, SIDE_OFF = 5.5, CLAMP_ALT = 25, CLAMP_XZ = 1.5, CLAMP_T = 3.0, THRUST_RAMP = 3.5, EXIT_VH = 2.5, REST_T = 2.0, REST_VS = 0.05, REST_G = 0.95, CATCH_TILT = 3,
  CUT_ALT = 0.4, MISS_XZ = 5,
  STILL_ALT = 1.5, STILL_ALT_ARMS = 8, STILL_VS = 0.25, STILL_T = 1.0, IMPACT_ACC = 120,
  NAV_ALT_K = 0.1, EG_TMIN = 6, NAV_RAMP = 0.5,
  ML_BASE = 0.08, ML_MIN = 0.13, MAX_LEAN = 0.15, LEAN_SLEW = 0.15,
  A_TRACK = 2, PROF_TAU = 9, VS_KP_TR = 1.2, TRACK_FLOOR = 0.9, A_SLEW_TR = 6, A_SLEW_UP = 30,
  GATE_ALT = 105, GATE_XZ = 1.5, GATE_VH = 0.7, GATE_TILT = 2.5, GATE_TIME = 2.0, ML_0 = 0.02, ML_K = 0.012, ML_V = 0.04,
  CONST_ON = true, CT_MAIN = 15, CT_FINE = 15, CT_ON_MARGIN = 0, CT_OFF_MARGIN = 40, CT_HAND_VS = 12, CT_END = 45, CT_LAG = 0.35,
  MAX_CLIMB = 2, FINE_LO = 0.5, FINE_HI = 14,
  GLIDE_NEAR = 0, NEAR_R = 40, TRACK_TG = 6, ROT_ALT = 150,
  ML_NEAR2 = 0.06,
  GLIDE_SLOPE = 0, GLIDE_R0 = 3,
  TILT_SAFE = 15, TILT_THR = 15, TILT_THR_W = 20,
  GLIDE_VS = 40, GLIDE_GATE = 700, GLIDE_KP = 1.5, GLIDE_LEAN = 0.15, GLIDE_NAV_KP = 0.25, GLIDE_LAG = 1.5, GLIDE_TMIN = 2.5, GLIDE_VW_RATE = 3,
  CRUISE_A = 5, CRUISE_LEAN = 0.10, NAV_MAX = 40, NAV_KP = 1.0, NAV_PK = 0.65,
  NAV_DEAD = 0.6, ALT_BURN_EST = 600, NAV_WARN = 600,
  LOG_BUDGET = 600000, STALE_LOOPS = 15, STALE_ABORT = 80,
  FLOOR_EV0 = 1.0, FLOOR_EV_K = 0.15, FLOOR_MIN_K = 0.4, FLOOR_RELAX_ALT = 25,
  A_FLOOR = 0.6, A_FALL = 30, VS_KP_DOWN = 1.0, FLOOR_ALT = 200,
  ARMS_CLOSE = 15, ARMS_OPEN = 0,
  ROLL_ON = true, ROLL_HOLD = false,
  ENTRY_DIR = { x = 0.227, z = 0.974 }, -- from the catch point to the free side
  ARMS_DIR = { x = -0.227, z = -0.974 }, -- x east+, z south+
  LIME_AXIS = "R", LIME_SIGN = 1,
  ROLL_OFFSET = 251.5, 
  ROLL_SIGN = 1, -- -1 if roll turns the wrong way
  ROLL_KP = 0.3, ROLL_KD = 0.6, ROLL_K = 60, ROLL_MAX = 8, ROLL_DEAD = 2, ROLL_MIN = 1,
  ROLL_ALT_MAX = 1200, ROLL_ALT_MIN = 3, ROLL_TILT_MAX = 12,
  LOW_ALT = 30, ML_LOW = 0.08,
  BODY_H = 69, BODY_FADE = 150,
  CLOSE_V0 = 0.8, CLOSE_VK = 0.25, CLOSE_KB = 1.5,
  ENTRY_AWAY = true, ENTRY_OFF = 10, ENTRY_ALT = 400, ENTRY_VERT = 40,
  SLIDE_ON = false, STAND_OFF = 12, SLIDE_ALT = 3, SLIDE_V = 1.0, STAND_XZ = 2.0, STAND_VH = 1.0,
  A_CAP_G = 1.35, A_CAP_ALT = 250,
  A_PROF = 2.5, PROF_TAU_LOW = 3,
  KEEP_R = 8, KEEP_LAG = 3.0, BODY_CLEAR = 90,
  POS_ROT_ALT = 30,
  GLIDE_TAPER_T = 6.0, GLIDE_TAPER_MIN = 0.4, 
  GLIDE_FF = 1.0,
  DFF_MAX = 0.05,
  GROUND_ALT = 15, GROUND_CAP_G = 1.05, TRIM_GROUND = 0.2,
  LOG = "catch_sh.log",
}
local C = CONFIG
if fs.exists("calib.lua") then
  local ok, cal = pcall(dofile, "calib.lua")
  if ok and type(cal) == "table" then for k, v in pairs(cal) do C[k] = v end end
end
local G = {
  MAIN = 0.6407, FINE = 0.1499,
  RCS_N = 0.0060, RCS_S = 0.0060, RCS_W = 0.0050, RCS_E = 0.0050,
  GIM_N = 0.0045, GIM_S = 0.0039, GIM_W = 0.0040, GIM_E = 0.0040,
  GIM_REF = 8, GIM_SCALE = 1,
}
G.MAIN = G.FINE
local L = {
  eng_a = { "minecraft:prismarine_bricks", "minecraft:prismarine_bricks" },
  eng_b = { "minecraft:prismarine", "minecraft:prismarine" },
  gim_n = { "minecraft:short_grass", "minecraft:short_grass" },
  gim_s = { "tfmg:lithium_ore", "tfmg:lithium_ore" },
  gim_w = { "create:light_gray_postbox", "create:light_gray_postbox" },
  gim_e = { "offroad:wheel_mount", "offroad:wheel_mount" },
  rcs_n = { "minecraft:yellow_wool", "minecraft:yellow_wool" },
  rcs_s = { "minecraft:orange_wool", "minecraft:orange_wool" },
  rcs_w = { "minecraft:green_wool", "minecraft:green_wool" },
  rcs_e = { "minecraft:lime_wool", "minecraft:lime_wool" },
  roll_cw  = { "simulated:spring", "simulated:spring" }, -- clockwise
  roll_ccw = { "simulated:contraption_diagram", "dndecor:andesite_sheet_metal" }, -- counterclockwise
}

local ARMS = { "minecraft:stone", "minecraft:stone" }
local ENG_UNUSED = {
  outer  = { "minecraft:prismarine_wall", "minecraft:prismarine_wall" }, -- 22 outer engines, no gimbal: liftoff + boostback
  bricks = { "minecraft:prismarine_bricks", "minecraft:prismarine_bricks" }, -- liftoff, hotstage, boostback
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
local function out(key, v)
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

local function setArms(level)
  local ok, e = pcall(bridge.sendLinkSignal, ARMS[1], ARMS[2], level)
  if not ok then print("arms signal error: " .. tostring(e)) end
end

local log
local clampT0, clampDone = nil, false
local function startClamp()
  if not clampT0 and not clampDone then
    clampT0 = os.clock()
    setArms(CONFIG.ARMS_CLOSE)
    log(("ARMS CLOSE sent t=%.2f"):format(clampT0)); print("arms close sent")
  end
end

local function releaseArms(now)
  if clampT0 and now - clampT0 >= CONFIG.CLAMP_T then
    setArms(CONFIG.ARMS_OPEN)
    clampT0 = nil; clampDone = true
    log("ARMS RELEASED (signal cancelled)")
    print("arms signal cancelled")
  end
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
local function rot(qx, qy, qz, qw, a, b, c)
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
  return {
    px = pose.position.x, py = pose.position.y, pz = pose.position.z,
    vx = v.x, vy = v.y, vz = v.z,
    wR = w.x, wU = w.y, wF = w.z,
    ux = ux, uy = uy, uz = uz,
    fx = fx/fl, fz = fz/fl, rx = rx/rl, rz = rz/rl, fy = fy, ry = ry,
    tilt = math.deg(math.acos(clamp(uy, -1, 1))),
  }
end

local function attitude(tF, tR, aTot, kT)
  local veq = aTot / (G.FINE * kT)
  local gs = aTot / (G.FINE * G.GIM_REF) * G.GIM_SCALE
  local sh = C.GIM_ON and C.GIM_SHARE * clamp((veq - 1) / 5, 0, 1) or 0
  local rF, rR = tF * (1 - sh), tR * (1 - sh)
  local gF, gR = tF * sh, tR * sh
  local sf, sr = C.RCS_SIGN_F, C.RCS_SIGN_R
  local gsf, gsr = C.GIM_SIGN_F, C.GIM_SIGN_R
  -- rcs/gim w,e tilt F (w +, e -; gimbal e +, w -); n,s tilt R (rcs s +, n -; gimbal n +, s -)
  out("rcs_w", pos(sf * rF) / G.RCS_W); out("rcs_e", pos(-sf * rF) / G.RCS_E)
  out("rcs_s", pos(sr * rR) / G.RCS_S); out("rcs_n", pos(-sr * rR) / G.RCS_N)
  if aTot > 0 and C.GIM_ON then
    out("gim_e", pos(gsf * gF) / (G.GIM_E * gs)); out("gim_w", pos(-gsf * gF) / (G.GIM_W * gs))
    out("gim_n", pos(gsr * gR) / (G.GIM_N * gs)); out("gim_s", pos(-gsr * gR) / (G.GIM_S * gs))
  else
    out("gim_n", 0); out("gim_s", 0); out("gim_w", 0); out("gim_e", 0)
  end
end

local logf = fs.open(C.LOG, "w")
local logBytes = 0
function log(s)
  if logf and logBytes < C.LOG_BUDGET then logf.writeLine(s); logBytes = logBytes + #s + 1 end
end
print(("kT0=%.1f aMax0=%.1f"):format(C.THRUST_MULT, (G.MAIN + G.FINE) * 15 * C.THRUST_MULT))
log(("start catch_sh kT0=%.2f roll_off=%.1f lime=%s%d roll_sign=%d calib=%s"):format(C.THRUST_MULT, C.ROLL_OFFSET, C.LIME_AXIS, C.LIME_SIGN, C.ROLL_SIGN, fs.exists("calib.lua") and "yes" or "no"))
setArms(C.ARMS_OPEN)
print("Started, arms open, Ctrl+T aborts")

local function pickEngines(aDes, kT)
  if aDes <= 0.5 then return 0, 0 end
  local gm, gf = G.MAIN * kT, G.FINE * kT
  local mp = cache.eng_a or 0
  local fneed = (aDes - mp * gm) / gf
  local main
  if fneed >= C.FINE_LO and fneed <= C.FINE_HI then main = mp
  else main = clamp(math.floor((aDes - C.FINE_MID * gf) / gm), 0, 15) end
  return main, clamp((aDes - main * gm) / gf, C.MIN_FINE, 15)
end

local function rampDown(a0, kT)
  for k in pairs(L) do if k ~= "eng_a" and k ~= "eng_b" then acc[k] = 0; out(k, 0) end end
  local t0 = os.clock()
  while true do
    local now = os.clock(); local el = now - t0
    releaseArms(now)
    if el >= C.THRUST_RAMP then break end
    local m, f = pickEngines(a0 * (1 - el / C.THRUST_RAMP), kT)
    out("eng_a", m); out("eng_b", f); flush()
    sleep(0.05)
  end
  log("RAMP DONE"); print("engines off: thrust ramped down"); allZero()
end
local function endFlight(reason, d, a0, kT)
  log(("END(%s) dist=%.2f a0=%.1f"):format(reason, d, a0))
  if d <= C.MISS_XZ then
    startClamp(); print("arms closed (" .. reason .. ")")
    rampDown(a0, kT)
  else
    print("MISS, arms stay open"); allZero()
  end
end

local function run()
  local burn, trim, burnT0 = false, 0, 0
  local kT = C.THRUST_MULT
  local rF, rR, last = 0, 0, os.clock()
  local pdF, pdR, pA = 0, 0, 0
  local pvs, puy
  local n, stale, lastSig = 0, 0, nil
  local first, still, rest = true, 0, 0
  local iF, iR = 0, 0
  local aligned, holdS, holdUsed = false, C.HOLD_ALT, 0
  local pdesVS = 0
  local glide = false
  local sdx, sdz
  local gvw = 0
  local rollHead
  local standOff, sliding, staleLogged = C.STAND_OFF, false, false
  local gateT, gated = 0, false
  local ctReg = false
  while true do
    local s = read()
    if not s then allZero(); sleep(0.05)
    else
      local now = os.clock(); local dt = clamp(now - last, 0.02, 0.5); last = now
      local fd = -C.CATCH_DY
      local rx_, ry_, rz_ = fd * s.ux, fd * s.uy, fd * s.uz
      local finX, finY, finZ = s.px + rx_, s.py + ry_, s.pz + rz_
      local fvx = s.vx + (s.wU * rz_ - s.wF * ry_)
      local fvz = s.vz + (s.wR * ry_ - s.wU * rx_)
      local alt = finY - C.TARGET.y
      local rw = clamp(1 - alt / C.ROT_ALT, 0, 1)
      local altc = math.max(alt, 0)
      local cOff
      if altc < C.POS_ROT_ALT then cOff = fd - altc
      else cOff = (fd - math.min(altc, C.BODY_H)) * clamp((C.BODY_FADE - altc) / 60, 0, 1) end
      local kf = cOff / fd
      local cx, cz = s.px + cOff * s.ux, s.pz + cOff * s.uz
      local vcom = math.sqrt(s.vx * s.vx + s.vz * s.vz)
      local seeking = C.SLIDE_ON and standOff > 0
      local nvx, nvz = s.vx + (fvx - s.vx) * kf, s.vz + (fvz - s.vz) * kf
      if not sdx then
        local hx, hz = finX - C.TARGET.x, finZ - C.TARGET.z
        local hl = math.sqrt(hx*hx + hz*hz)
        if hl < 1 then sdx, sdz = 0, 0 else sdx, sdz = hx / hl, hz / hl end
        if C.ENTRY_AWAY then local al = math.sqrt(C.ENTRY_DIR.x^2 + C.ENTRY_DIR.z^2); if al > 1e-6 then sdx, sdz = C.ENTRY_DIR.x / al, C.ENTRY_DIR.z / al end end
      end
      local ofk = C.ENTRY_AWAY and clamp((alt - C.ENTRY_VERT) / (C.ENTRY_ALT - C.ENTRY_VERT), 0, 1) * C.ENTRY_OFF or clamp(alt / C.HOLD_ALT, 0, 1) * C.SIDE_OFF
      local ofkRaw = ofk
      if C.SLIDE_ON then ofk = math.max(ofk, standOff) end
      local vs = s.vy
      local eRamp = clamp((C.ENTRY_ALT - alt) / 20, 0, 1) * (alt > C.ENTRY_VERT and 1 or 0)
      local eSlope = C.ENTRY_AWAY and C.ENTRY_OFF / (C.ENTRY_ALT - C.ENTRY_VERT) * eRamp or 0
      if C.SLIDE_ON and ofkRaw <= standOff then eSlope = 0 end
      local tvx, tvz = sdx * eSlope * vs, sdz * eSlope * vs
      if C.SLIDE_ON and sliding and standOff > 0 then tvx, tvz = -sdx * C.SLIDE_V, -sdz * C.SLIDE_V end
      local g = gAt(alt)
      local dx, dz = C.TARGET.x + sdx * ofk - cx, C.TARGET.z + sdz * ofk - cz
      local dist = math.sqrt(dx*dx + dz*dz)
      local tdist = math.sqrt((C.TARGET.x - finX)^2 + (C.TARGET.z - finZ)^2)
      local vhor = math.sqrt(fvx*fvx + fvz*fvz)
      if first then
        first = false
        do local lx0, lz0; if C.LIME_AXIS == "F" then lx0, lz0 = s.fx, s.fz else lx0, lz0 = s.rx, s.rz end; rollHead = atan2(lz0 * C.LIME_SIGN, lx0 * C.LIME_SIGN) end
        log(("INIT alt=%.1f dist=%.1f pos=%.1f,%.1f,%.1f"):format(alt, dist, s.px, s.py, s.pz))
        print(("alt %.0f m, distance to catch point %.0f m"):format(alt, dist))
        if dist > C.NAV_WARN then print(("WARNING: catch point is %.0f m away"):format(dist)) end
      end
      local th = math.rad(s.tilt)
      local sn = math.sin(th)
      local kA = (sn > 1e-3) and th / sn or 0
      local leanF, leanR = -s.fy * kA, -s.ry * kA
      if sn <= 1e-3 and s.uy < 0 then leanF = th end
      rF = rF + (s.wR - rF) * C.RATE_SMOOTH
      rR = rR + (-s.wF - rR) * C.RATE_SMOOTH

      if burn and pvs and pvs < -2 and dt < 0.3 and (vs - pvs) / dt > C.IMPACT_ACC and alt < C.CLAMP_ALT + 10 and (math.abs(s.vx) + math.abs(s.vy) + math.abs(s.vz)) > 1e-3 then
        log(("CAUGHT(impact) alt=%.2f pvs=%.1f vs=%.1f tilt=%.1f dist=%.2f"):format(alt, pvs, vs, s.tilt, dist))
        return endFlight("impact", dist, pA, kT)
      end
      if burn and not seeking and math.abs(vs) < C.STILL_VS and (alt < C.STILL_ALT or (alt < C.STILL_ALT_ARMS and pdesVS < -1.5)) then still = still + dt else still = 0 end
      if still > C.STILL_T then
        log(("CAUGHT(still) alt=%.2f tilt=%.1f dist=%.2f"):format(alt, s.tilt, dist))
        return endFlight("still", dist, pA, kT)
      end

      local thrA = (G.MAIN*(cache.eng_a or 0) + G.FINE*(cache.eng_b or 0)) * kT * s.uy
      if burn and not seeking and alt < C.STILL_ALT_ARMS and math.abs(vs) < C.REST_VS and thrA < C.REST_G * g then rest = rest + dt else rest = 0 end
      if rest > C.REST_T then
        log(("CAUGHT(rest) alt=%.2f tilt=%.1f dist=%.2f thr=%.1f"):format(alt, s.tilt, dist, thrA))
        return endFlight("rest", dist, pA, kT)
      end

      if C.ADAPT and (burn or glide) and pvs and dt < 0.3 and stale == 0 and rest == 0 and math.abs(vs - pvs) > 1e-4 then
        local expected = (G.MAIN*(cache.eng_a or 0) + G.FINE*(cache.eng_b or 0)) * puy
        if expected > 1.5 then
          local meas = (vs - pvs) / dt + g + C.DRAG_K * vs * math.abs(vs)
          kT = clamp(kT + C.ADAPT_K * (clamp(meas / expected, 1, 10) - kT), C.KT_MIN, C.KT_MAX)
        end
      end
      pvs, puy = vs, s.uy
      releaseArms(now)

      local aMax = (G.MAIN + G.FINE) * 15 * kT
      local aL = clamp(C.A_LAND_FRAC * (0.97 * aMax - g), 1.5, C.A_LAND_MAX)
      local stop = 0
      if vs < 0 then
        local vL = math.max(-vs - C.TOUCH_VS, 0)
        stop = C.A_PROF > 0 and (vL * vL / (2 * C.A_PROF) + vL * C.BURN_LAG * 0.5) or vL * (C.PROF_TAU + C.BURN_LAG * 0.5)
        if C.CONST_ON then local aNet = math.max((G.MAIN * C.CT_MAIN + G.FINE * C.CT_FINE) * kT - g, 0.5); local vh = C.CT_HAND_VS > 0 and C.CT_HAND_VS or C.TOUCH_VS; stop = C.CT_END + math.max(vs * vs - vh * vh, 0) / (2 * aNet) + (-vs) * C.CT_LAG end
      end
      if not burn and alt < stop + (C.CONST_ON and 0 or C.GATE_ALT) + C.GLIDE_SLOPE * dist + C.GLIDE_NEAR * math.min(dist, C.NEAR_R) then
        burn = true; burnT0 = now; glide = false
        log(("BURN alt=%.1f vs=%.1f kT=%.2f aL=%.1f dist=%.1f"):format(alt, vs, kT, aL, dist))
        if dist > 3 or vcom > 1.5 then log(("BURN OFF-TARGET dist=%.1f vc=%.2f tilt=%.1f"):format(dist, vcom, s.tilt)) end
      end
      if burn and alt <= C.CUT_ALT then
        log(("CUTOFF alt=%.2f vs=%.2f tilt=%.1f dist=%.2f vh=%.2f%s"):format(alt, vs, s.tilt, dist, vhor, dist > C.MISS_XZ and " MISS" or ""))
        return endFlight("cutoff", dist, pA, kT)
      end

      local desF, desR, dF, dR = 0, 0, 0, 0
      local main, fine, aDes, desVS, hLog = 0, 0, 0, 0, 0
      local cr = false
      local fnl = 0
      if burn then
        if aligned then
          if alt > C.COMMIT_BODY and (dist > C.EXIT_XZ or vcom > C.EXIT_VH or s.tilt > C.CATCH_TILT * 2) then aligned = false end
          if C.SLIDE_ON and dist > C.EXIT_XZ * 1.5 then aligned = false end
        elseif dist < C.CATCH_XZ and vcom < C.CATCH_VH and s.tilt < C.CATCH_TILT then aligned = true end
        if C.SLIDE_ON then
          if sliding and not aligned then sliding = false; standOff = C.STAND_OFF; log("SLIDE ABORT") end
          if not sliding and aligned and alt < C.SLIDE_ALT + 1.5 and dist < C.STAND_XZ and vcom < C.STAND_VH and s.tilt < C.CATCH_TILT then
            sliding = true; log(("SLIDE START alt=%.1f dist=%.2f vc=%.2f tilt=%.1f"):format(alt, dist, vcom, s.tilt))
          end
          if sliding and dist < 2.5 then standOff = math.max(standOff - C.SLIDE_V * dt, 0) end
        end
        if burn and alt < C.CLAMP_ALT then startClamp() end
        local funnel = (alt < C.COMMIT_ALT or holdUsed > C.HOLD_MAX) and 0 or (C.GLIDE_SLOPE * pos(dist - C.GLIDE_R0) + C.GLIDE_NEAR * clamp(dist - C.GLIDE_R0, 0, C.NEAR_R))
        fnl = funnel
        if alt < C.HOLD_ALT + funnel + 3 and holdS > 0 then holdUsed = holdUsed + dt end
        local holdT = (aligned or alt < C.COMMIT_ALT or holdUsed > C.HOLD_MAX) and 0 or C.HOLD_ALT
        if C.SLIDE_ON then
          holdT = C.HOLD_ALT
          if aligned then holdT = (sliding and standOff <= 0) and 0 or C.SLIDE_ALT end
          if not sliding and standOff > 0 then
            if dist < C.GATE_XZ and vcom < C.GATE_VH and s.tilt < C.GATE_TILT then gateT = gateT + dt else gateT = 0 end
            if gateT > C.GATE_TIME and not gated then gated = true; log(("GATE OPEN alt=%.1f dist=%.2f vc=%.2f tilt=%.1f"):format(alt, dist, vcom, s.tilt)) end
            if gated and (dist > C.GATE_XZ * 2.5 or s.tilt > C.GATE_TILT * 2.5) then gated = false; gateT = 0; log("GATE CLOSE") end
            if not gated then holdT = math.max(holdT, C.GATE_ALT) end
          end
        end
        holdS = holdS + clamp(holdT - holdS, -C.HOLD_RATE * dt, 40 * dt)
        local h = alt - (holdS + funnel)
        hLog = h
        local vt = math.max(C.HOLD_ALT > 0 and C.TOUCH_VS * (1 - holdS / C.HOLD_ALT) or C.TOUCH_VS, 0)
        local tracking = true
        local closing = dist > 0.5 and math.max((dx * fvx + dz * fvz) / dist, 0) or 0
        local sEff = C.GLIDE_SLOPE + ((dist > C.GLIDE_R0 and dist < C.GLIDE_R0 + C.NEAR_R) and C.GLIDE_NEAR or 0)
        local vff = funnel > 0 and sEff * closing or 0
        local vProf = vt + (C.A_PROF > 0 and math.min(math.sqrt(2 * C.A_PROF * math.max(h, 0)), math.max(h, 0) / C.PROF_TAU_LOW) or math.max(h, 0) / C.PROF_TAU)
        if not tracking then vProf = math.min(vProf, C.FINAL_VS) end
        if tracking then
          if h >= 0 then desVS = -math.min(C.MAX_DESC, vProf + vff) else desVS = math.min(C.MAX_CLIMB, -0.5 * h) - vff end
        elseif h >= 0 then desVS = -math.min(C.MAX_DESC, vProf) else desVS = math.min(2, -h) end
        local ev = desVS - vs
        local floorK = 1
        if ev < -C.FLOOR_EV0 and alt > C.FLOOR_RELAX_ALT then floorK = clamp(1 + (ev + C.FLOOR_EV0) * C.FLOOR_EV_K, C.FLOOR_MIN_K, 1) end
        local aff = (not tracking and h > 0 and vProf < C.MAX_DESC) and math.min(aL, C.A_FINAL) * clamp(1 + ev, 0, 1) or 0
        if math.abs(ev) < 5 then trim = clamp(trim + C.TRIM_KI * ev * dt, -C.TRIM_LIM, C.TRIM_LIM) end
        local kp = tracking and C.VS_KP_TR or (ev < 0 and C.VS_KP_DOWN or C.VS_KP)
        aDes = clamp(math.max(g + aff + trim + kp * ev, 0) / math.max(s.uy, 0.5), 0, aMax * 0.95)
        if s.uy < 0.2 then aDes = 0 end
        if tracking and s.uy >= 0.2 then
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

        local ml = clamp(C.ML_BASE + 0.0004 * alt, C.ML_MIN, C.MAX_LEAN)
        local qd = math.sqrt((dx - nvx * C.BRAKE_LAG)^2 + (dz - nvz * C.BRAKE_LAG)^2)
        ml = math.min(ml, C.ML_0 + C.ML_K * math.max(dist, qd) + C.ML_V * vcom)
        if aligned or alt < C.COMMIT_ALT + 4 then ml = math.min(ml, C.ML_NEAR) end
        if alt < C.LOW_ALT then ml = math.min(ml, C.ML_LOW) end
        local rvx, rvz = nvx - tvx, nvz - tvz
        local pdx, pdz = dx - rvx * C.BRAKE_LAG, dz - rvz * C.BRAKE_LAG
        local pdist = math.sqrt(pdx*pdx + pdz*pdz)
        local aref = math.max(aDes, g)
        local tg = clamp(2 * math.max(h, 0.1) / (math.abs(vs) + C.TOUCH_VS), C.EG_TMIN, 120)
        if tracking then tg = math.min(tg, math.max(C.TRACK_TG, 3 + dist / 4)) end
        tg = math.min(math.max(tg, C.BRAKE_FRAC * 2 * math.sqrt(math.max(dist, pdist) / math.max(ml * aref, 0.5))), 120)
        local ramp = clamp((now - burnT0) / C.NAV_RAMP, 0, 1)
        local ax = (6 * pdx / (tg * tg) - 5.5 * rvx / tg) * ramp
        local az = (6 * pdz / (tg * tg) - 5.5 * rvz / tg) * ramp
        local cs = dist > 0.5 and (dx * rvx + dz * rvz) / dist or 0
        local over = math.max(cs - (C.CLOSE_V0 + C.CLOSE_VK * dist), 0)
        if over > 0 then ax = ax - over * C.CLOSE_KB * dx / dist; az = az - over * C.CLOSE_KB * dz / dist end
        local wx, wz = ax / aref, az / aref
        local wm = math.sqrt(wx*wx + wz*wz)
        if wm > ml then wx, wz = wx * ml / wm, wz * ml / wm end
        local tf = clamp(1 - (s.tilt - C.TILT_SAFE) / (C.TILT_SAFE * 1.5), 0, 1)
        desF = (wx * s.fx + wz * s.fz) * tf
        desR = (wx * s.rx + wz * s.rz) * tf
        local mx = C.LEAN_SLEW * dt
        desF = pdF + clamp(desF - pdF, -mx, mx)
        desR = pdR + clamp(desR - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt

        local gm, gf = G.MAIN * kT, G.FINE * kT
        local mp = cache.eng_a or 0
        local fneed = (aDes - mp * gm) / gf
        if fneed >= C.FINE_LO and fneed <= C.FINE_HI then main = mp
        else main = clamp(math.floor((aDes - C.FINE_MID * gf) / gm), 0, 15) end
        fine = clamp((aDes - main * gm) / gf, C.MIN_FINE, 15)
        if C.CONST_ON and not ctReg and C.CT_HAND_VS > 0 and (cache.eng_a or 0) > 0 and vs > -C.CT_HAND_VS then
          ctReg = true; log(("CT HANDOFF alt=%.1f vs=%.1f dist=%.1f vc=%.2f"):format(alt, vs, dist, vcom))
        end
        if C.CONST_ON and not ctReg then
          local isOn = (cache.eng_a or 0) > 0
          local thr = (isOn and C.CT_HAND_VS > 0) or (vs < 0 and alt < stop + (isOn and C.CT_OFF_MARGIN or C.CT_ON_MARGIN))
          main, fine = thr and C.CT_MAIN or 0, thr and C.CT_FINE or 0
          aDes = (G.MAIN * main + G.FINE * fine) * kT
        end
        pA = aDes
      elseif s.uy > 0.5 then
        if not glide then gvw = vhor end
        glide = true; cr = true
        local tgo = math.max((alt - C.GLIDE_GATE) / math.max(-vs, 10), C.GLIDE_TMIN)
        local tB = (alt - stop) / math.max(-vs, 10)
        local leanCap = C.GLIDE_LEAN * clamp(tB / C.GLIDE_TAPER_T, C.GLIDE_TAPER_MIN, 1)
        local vw = 0
        local brk = false
        local clos = dist > 0.5 and ((nvx - tvx) * dx + (nvz - tvz) * dz) / dist or 0
        local dEff = dist - math.max(clos, 0) * C.GLIDE_LAG
        if dEff > C.NAV_DEAD then
          vw = math.min(C.NAV_MAX, dist / tgo)
          local vb = math.sqrt(2 * leanCap * g * C.NAV_PK * (dEff - C.NAV_DEAD))
          if vb < vw then vw = vb; brk = true end
        elseif clos > 0.5 then
          -- predicted position is already inside the dead zone but we are still closing: brake at full authority instead of coasting through
          brk = true
        end
        gvw = gvw + clamp(vw - gvw, -C.GLIDE_VW_RATE * dt, C.GLIDE_VW_RATE * dt)
        vw = gvw
        local ux, uz = 0, 0
        if dist > 0.5 then ux, uz = dx / dist, dz / dist end
        local ax = C.GLIDE_NAV_KP * (ux * vw + tvx - nvx)
        local az = C.GLIDE_NAV_KP * (uz * vw + tvz - nvz)
        if brk then
          local vcl = (nvx - tvx) * ux + (nvz - tvz) * uz
          local ffk = clamp(vcl / math.max(vw, 0.5), 0, 1) * C.GLIDE_FF
          local ab = leanCap * g * C.NAV_PK * ffk
          ax = ax - ux * ab; az = az - uz * ab
        end
        local ev = -C.GLIDE_VS - vs
        aDes = clamp((g + C.GLIDE_KP * ev) / math.max(s.uy, 0.5), 0, aMax * 0.95)
        aDes = math.min(aDes, pA + C.A_RISE * dt)
        local aref = math.max(aDes, g)
        local wx, wz = ax / aref, az / aref
        local wm = math.sqrt(wx*wx + wz*wz)
        if wm > leanCap then wx, wz = wx * leanCap / wm, wz * leanCap / wm end
        local tf = clamp(1 - (s.tilt - C.TILT_SAFE) / (C.TILT_SAFE * 1.5), 0, 1)
        local mx = C.LEAN_SLEW * dt
        desF = pdF + clamp((wx * s.fx + wz * s.fz) * tf - pdF, -mx, mx)
        desR = pdR + clamp((wx * s.rx + wz * s.rz) * tf - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt
        main, fine = pickEngines(aDes, kT)
        pA = aDes
      end
      pdF, pdR = desF, desR
      pdesVS = desVS
      if not burn and not cr then pA = 0 end

      if burn or cr then
        if s.tilt < 35 and math.abs(desF - leanF) < C.ATT_I_ERR and math.abs(desR - leanR) < C.ATT_I_ERR then
          local kI = cr and C.ATT_KI_C or C.ATT_KI
          iF = clamp(iF + kI * (desF - leanF) * dt, -C.ATT_IMAX, C.ATT_IMAX)
          iR = clamp(iR + kI * (desR - leanR) * dt, -C.ATT_IMAX, C.ATT_IMAX)
        else
          iF, iR = iF * math.max(1 - 1.0 * dt, 0), iR * math.max(1 - 1.0 * dt, 0)
        end
      else iF, iR = iF * math.max(1 - 2 * dt, 0), iR * math.max(1 - 2 * dt, 0) end
      dF, dR = clamp(dF, -C.DFF_MAX, C.DFF_MAX), clamp(dR, -C.DFF_MAX, C.DFF_MAX)
      local tF = C.KP * (desF - leanF) + C.KD * (dF - rF) + iF
      local tR = C.KP * (desR - leanR) + C.KD * (dR - rR) + iR
      local aTot = (G.MAIN * main + G.FINE * fine) * kT
      local yawErr = 0
      if C.ROLL_ON and stale < C.STALE_LOOPS and alt < C.ROLL_ALT_MAX and alt > C.ROLL_ALT_MIN and s.tilt < C.ROLL_TILT_MAX then
        local lx, lz
        if C.LIME_AXIS == "F" then lx, lz = s.fx, s.fz else lx, lz = s.rx, s.rz end
        lx, lz = lx * C.LIME_SIGN, lz * C.LIME_SIGN
        local want = (C.ROLL_HOLD and rollHead) or (atan2(C.ARMS_DIR.z, C.ARMS_DIR.x) + math.rad(C.ROLL_OFFSET))
        local e = want - atan2(lz, lx)
        e = (e + math.pi) % (2 * math.pi) - math.pi
        yawErr = math.deg(e)
        if math.abs(yawErr) < C.ROLL_DEAD then e = 0 end
        -- heading (atan2(z,x)) increases clockwise from above; d(heading)/dt = -wU
        local u = C.ROLL_SIGN * (C.ROLL_KP * e + C.ROLL_KD * s.wU)
        local lc, lw = clamp(u * C.ROLL_K, 0, C.ROLL_MAX), clamp(-u * C.ROLL_K, 0, C.ROLL_MAX)
        if lc < C.ROLL_MIN then lc = 0; acc.roll_cw = 0 end
        if lw < C.ROLL_MIN then lw = 0; acc.roll_ccw = 0 end
        out("roll_cw", lc); out("roll_ccw", lw)
      else acc.roll_cw, acc.roll_ccw = 0, 0; out("roll_cw", 0); out("roll_ccw", 0) end
      local frozen = stale >= C.STALE_LOOPS or (math.abs(s.vx) < 1e-4 and math.abs(s.vy) < 1e-4 and math.abs(s.vz) < 1e-4)
      attitude(frozen and 0 or tF, frozen and 0 or tR, aTot, kT)
      if not frozen then out("eng_a", main); out("eng_b", fine) end
      flush()
      n = n + 1
      if (n % 5 == 0 or alt < 300) and logf then logf.flush() end
      local sig = s.py + s.vy + s.ux + s.wR
      local zeros = math.abs(s.vx) < 1e-4 and math.abs(s.vy) < 1e-4 and math.abs(s.vz) < 1e-4 and math.abs(s.wR) < 1e-4 and math.abs(s.wF) < 1e-4
      if (lastSig and math.abs(sig - lastSig) < 1e-4) or zeros then stale = stale + 1 else stale = 0 end
      lastSig = sig
      if stale >= C.STALE_LOOPS and not staleLogged then staleLogged = true; log(("STALE onset alt=%.1f vs=%.2f"):format(alt, vs)) end
      local c = cache
      log(("%.1f a=%.1f h=%.1f vs=%.2f/%.2f vh=%.2f dist=%.2f tilt=%.1f l=%.3f,%.3f d=%.3f,%.3f t=%.3f,%.3f aDes=%.1f kT=%.2f trim=%.2f hold=%.1f al=%d eng=%d,%d rcs=%d,%d,%d,%d gim=%d,%d,%d,%d b=%d dt=%.2f v=%.2f,%.2f tg=%.1f,%.1f yaw=%.1f rl=%d,%d p=%.1f,%.1f,%.1f vc=%.2f so=%.1f sl=%d")
        :format(now, alt, hLog, vs, desVS, vhor, dist, s.tilt, leanF, leanR, desF, desR, tF, tR,
          aDes, kT, trim, holdS + fnl, aligned and 1 or 0, c.eng_a or 0, c.eng_b or 0,
          c.rcs_n or 0, c.rcs_s or 0, c.rcs_w or 0, c.rcs_e or 0,
          c.gim_n or 0, c.gim_s or 0, c.gim_w or 0, c.gim_e or 0, burn and 1 or 0, dt, s.vx, s.vz, dx, dz, yawErr, c.roll_cw or 0, c.roll_ccw or 0, s.px, s.py, s.pz, vcom, standOff, sliding and 1 or 0))
      if stale >= C.STALE_LOOPS and burn and alt < 15 and tdist <= C.CLAMP_XZ then
        log(("CAUGHT(stale) alt=%.2f tdist=%.2f tilt=%.1f"):format(alt, tdist, s.tilt))
        return endFlight("stale", tdist, pA, kT)
      end
      if stale >= C.STALE_ABORT then log("STALE sensors -> abort"); allZero(); print("sensors frozen"); return end
    end
  end
end

local ok, err = pcall(run)
if not ok then log("ERROR: " .. tostring(err)) end
allZero()
while clampT0 and os.clock() - clampT0 < CONFIG.CLAMP_T do sleep(0.1) end
releaseArms(os.clock())
if logf then logf.close() end
if not ok then error(err, 0) end
print("done")