local CONFIG = {
  TARGET = { x = -3279, y = 69, z = 6378 }, DECK_ALT = 24.8,   -- alt = pose.y - TARGET.y - DECK_ALT
  GRAVITY = 11,
  THRUST_MULT = 4.5,   -- start value of kT (logs: converges to 4.6-5.2) (engine power now / during calib)
  ADAPT = true,        -- refine kT online from measured accel
  RCS_MULT = 1,
  VEC_MIN = 1, VEC_FRAC = 0.45, GIM_SHARE = 0.9,   -- rev4: more gimbal authority
  KP = 0.25, KD = 0.9, KDY = 1.0, RATE_SMOOTH = 0.7,   -- rev4: softer (rev3 limit-cycled with saturated actuators)
  BRAKE_FRAC = 0.7,    -- share of real (thrust-g) margin used by burn trigger / profile
  BRAKE_CAP = 30,      -- m/s2
  BURN_MARGIN = 2.0,
  TOUCH_VS = 1.0, TOUCH_ALT = 3.0, CUT_ALT = 1.5, MAX_DESC = 200, IMPACT_ACC = 120,
  VS_KP = 2.5, TRIM_KI = 0.25, TRIM_LIM = 6,
  NAV_MAX = 40, NAV_DECEL = 2.4, NAV_KP = 1.0, VH_LB = 0.15, VH_CAPK = 0.4, BRAKE_LEAN = 0.22, NAV_RAMP = 2.0, ALT_BURN_EST = 600, BURN_T = 10, NAV_MIN_ALT = 0.5, NAV_DEAD = 6, NAV_REACH = 150, NAV_WARN = 600,
  MAX_LEAN = 0.30, LEAN_SLEW = 0.20, TILT_SAFE = 15,
  NAV_PK = 0.7,      -- rev11: share of NAV_DECEL used by the speed-vs-distance profile (margin for lean slew lag / overspeed)
  VCAP_DROP = 0.6,   -- rev11: sink-rate cap may fall by at most VCAP_DROP*aProf per second (no slam)
  NAV_AH = 1.8,      -- rev6: conservative horizontal accel (m/s2) used to estimate time needed to reach the pad
  TNEED_K = 1.0, TNEED_ADD = 3,   -- safety factor / constant settle time (s)
  NAV_END_ALT = 60,  -- lateral flight should be finished by this altitude
  -- rev13 ----------------------------------------------------------------
  NAV_ALT_K = 0.1,   -- burn starts at alt < stop-alt + NAV_ALT_K*dist (altitude reserve for lateral flight); replaces "dist > NAV_REACH -> burn at once" (burned from 2264 m)
  ML_BASE = 0.08, ML_MIN = 0.14,   -- lean limit = clamp(ML_BASE + 0.0004*alt, ML_MIN, MAX_LEAN); old 0.03/0.05 saturated near the pad and the craft drifted away 2 -> 21 m
  VCAP_MIN = 10,      -- floor of the sink-rate cap while lateral flight is unfinished (old 4 m/s = 17 s hover, ~22% of fuel)
  VCAP_RISE = 4,     -- m/s2: max rise rate of the cap after NAV_END_ALT (old: jumped to 200 -> engines off 2.5 s, then a slam)
  ADAPT_K = 0.03, KT_MIN = 4.0, KT_MAX = 8.0,   -- kT estimator: slower and bounded (old 0.06 wandered 4.5..6.6 and pumped thrust)
  STILL_VS = 0.8,    -- |vs| below this for 1.5 s low down = landed (old 0.3 never fired: craft crept at 0.4-0.6 m/s)
  -- rev14 ----------------------------------------------------------------
  VAC_ALT = 300,     -- vacuum engines allowed ONLY above this altitude (latched off below: they break in landing); below: vec only
  LAND_K = 0.07,     -- below VAC_ALT sink-rate profile = TOUCH_VS + LAND_K*height (gentle, vec-only can follow)
  NAV_KI = 0.15, NAV_IMAX = 1.0,   -- integral of horizontal velocity error (m/s2): cancels steady drift away from the pad
  DRAG_K = 0.00156,   -- 11/84^2, terminal speed in logs
  CRUISE_A = 5,   -- low vec thrust while falling, only to steer to the pad
  -- rev19 ----------------------------------------------------------------
  ATT_KI = 0.10, ATT_IMAX = 0.2,   -- integral of lean error (lean/s2): at low vec the P-D loop sat at a constant offset (want -0.14, had -0.02) -> drift 15 -> 61 m
  -- rev20 ----------------------------------------------------------------
  CRUISE_LEAN = 0.15,  -- max lean while free-falling (rev19: 0.39 lean = 25 deg at burn start -> vac engines pushed it sideways 4 -> 14 m/s)
  NAV_KP_B = 0.4,      -- horizontal velocity gain during burn (1.0 + sqrt profile + slow attitude loop = 6 s orbit around the pad, r up to 13 m)
  NAV_VLIN = 0.25,     -- vh <= NAV_VLIN*(dist-NAV_DEAD): linear (finite-slope) approach to the pad
  A_RISE = 40,         -- m/s2 per s: max rise of commanded accel (was a 0 -> 40 step in one loop at 370 m)
  TILT_THR = 15, TILT_THR_W = 20,   -- above TILT_THR deg thrust is scaled down (was 35 deg, never active at the 25 deg we had)
  STILL_ALT = 8,       -- 'landed by standstill' only below this altitude (rev19: cut engines at 13 m while creeping at 0.5 m/s)
  -- rev21 ----------------------------------------------------------------
  FAST_DIST = 15,     -- once within this distance of the pad (below FAST_ALT) lateral flight is over: stop crawling, land on a constant-decel profile
  FAST_ALT = 150,
  A_LAND_FRAC = 0.55, A_LAND_MAX = 8,   -- share of the vec-only net margin (thrust - g) used as landing decel, m/s2
  DAMP_ALT = 15,      -- below this: no more chasing the pad, only null the horizontal velocity (log: touched down at 2 m/s sideways -> tipped over)
  -- rev22: single late vec-only hoverslam, ZEM/ZEV lateral guidance; VS_KP 0.8 -> 2.5 (faster tracking of the landing profile)
  VAC_USE = false,
  VEC_ACC_MIN = 22,
  LAND_MARGIN = 1.3,
  EG_TMIN = 2.5,
  ATT_KI_C = 0.30,
  LOG_BUDGET = 600000, STALE_LOOPS = 15,
  LOG = "landing_sh.log",
  SPLASHDOWN = false,   -- true: water, faster touchdown; false: flat ground, gentle
}
local C = CONFIG
if C.SPLASHDOWN then C.TOUCH_VS, C.TOUCH_ALT, C.CUT_ALT = 6, 8, 3 end
local G = {
  VAC = 0.6407, VEC = 0.1499,
  TOP_F = 0.0096, BOT_F = 0.0058, YAW_R = 0.0133, YAW_L = 0.0144,
  ZAV_L = 0.0048, ZAV_R = 0.0057,
  GIM_N = 0.0045, GIM_S = 0.0039, GIM_W = 0.0040, GIM_E = 0.0040, GIM_REF_VEC = 8,
}
G.TOP_F, G.BOT_F, G.YAW_R, G.YAW_L = G.TOP_F*C.RCS_MULT, G.BOT_F*C.RCS_MULT, G.YAW_R*C.RCS_MULT, G.YAW_L*C.RCS_MULT
G.ZAV_L, G.ZAV_R = G.ZAV_L*C.RCS_MULT, G.ZAV_R*C.RCS_MULT
local L = {
  rcs_tl = { "computercraft:printed_page", "computercraft:printed_page" },
  rcs_tr = { "create_connected:shear_pin", "create_connected:shear_pin" },
  rcs_bl = { "computercraft:speaker", "computercraft:speaker" },
  rcs_br = { "computercraft:printer", "computercraft:printer" },
  zav_l = { "minecraft:gold_ingot", "minecraft:gold_ingot" },
  zav_r = { "minecraft:nautilus_shell", "minecraft:nautilus_shell" },
  vac = { "minecraft:armadillo_scute", "minecraft:armadillo_scute" },
  vec = { "minecraft:bone_meal", "minecraft:bone_meal" },
  gim_n = { "simulated:rope_coupling", "simulated:rope_coupling" },
  gim_s = { "createpropulsion:oxidizer_bucket", "createpropulsion:oxidizer_bucket" },
  gim_w = { "createpropulsion:tempered_wing", "createpropulsion:tempered_wing" },
  gim_e = { "createpropulsion:solid_burner", "createpropulsion:solid_burner" },
}
local unpackFn = table.unpack or unpack
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function pos(v) return v > 0 and v or 0 end
-- Falcon gravity table (g falls above 2000)
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

-- ---------------------------------------------------------------- outputs
local cache, pending, order, acc = {}, {}, {}, {}
local function out(key, v)               -- fractional level -> integer with error carry (dither)
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

-- ---------------------------------------------------------------- sensors
local function quat(q)
  local x, y, z, w
  if type(q.v) == "table" then x, y, z, w = q.v.x, q.v.y, q.v.z, q.a else x, y, z, w = q.x, q.y, q.z, q.w end
  x, y, z, w = tonumber(x), tonumber(y), tonumber(z), tonumber(w)
  if not (x and y and z and w) then return nil end
  local l = math.sqrt(x*x + y*y + z*z + w*w)
  if l < 1e-6 then return nil end
  return x/l, y/l, z/l, w/l
end
local function rot(qx, qy, qz, qw, a, b, c)       -- body -> world
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

-- ---------------------------------------------------------------- attitude: torque demand -> actuators
-- tF/tR in lean/s2, tY in rad/s2. kT = engine power multiplier (gimbal torque scales with it).
local function attitude(tF, tR, tY, vecLevel, kT)
  local gs = vecLevel / G.GIM_REF_VEC * kT
  local sh = C.GIM_SHARE * clamp((vecLevel - 1) / 5, 0, 1)   -- rev10: gimbal authority ~ vecLevel; at low thrust RCS must do the work
  local rF, rR = tF * (1 - sh), tR * (1 - sh)
  local gF, gR = tF * sh, tR * sh
  local top, bot = pos(-rF) / G.TOP_F, pos(rF) / G.BOT_F
  local yr, yl = pos(tY) / G.YAW_R, pos(-tY) / G.YAW_L
  out("rcs_tl", top / 2 + yl); out("rcs_tr", top / 2 + yr)
  out("rcs_bl", bot / 2 + yl); out("rcs_br", bot / 2 + yr)
  out("zav_l", pos(rR) / G.ZAV_L); out("zav_r", pos(-rR) / G.ZAV_R)
  if vecLevel > 0 then
    out("gim_n", pos(gF) / (G.GIM_N * gs)); out("gim_s", pos(-gF) / (G.GIM_S * gs))
    out("gim_w", pos(gR) / (G.GIM_W * gs)); out("gim_e", pos(-gR) / (G.GIM_E * gs))
  else
    out("gim_n", 0); out("gim_s", 0); out("gim_w", 0); out("gim_e", 0)
  end
end

-- ---------------------------------------------------------------- main
local logf = fs.open(C.LOG, "w")
local logBytes = 0
local function log(s)
  if logf and logBytes < C.LOG_BUDGET then logf.writeLine(s); logBytes = logBytes + #s + 1 end
end
print(("kT0=%.1f aMax0=%.1f"):format(C.THRUST_MULT, (G.VAC + G.VEC) * 15 * C.THRUST_MULT))
log(("start rev22 kT0=%.2f"):format(C.THRUST_MULT))
print("Started, Ctrl+T aborts")

local function run()
  local burn, trim = false, 0
  local burnT0 = 0
  local kT = C.THRUST_MULT
  local rF, rR, last = 0, 0, os.clock()
  local pdF, pdR = 0, 0
  local pvs, puy
  local n, stale, lastSig, distNow = 0, 0, nil, 0
  local first = true
  local still = 0
  local vCapS = nil
  local kC, pcr = 1, false   -- vec-only thrust scale (differs from kT), learned while steering
  local vacOff, bx, bz = false, 0, 0
  local fast = false
  local iF, iR, pDes, pA = 0, 0, 0, 0
  while true do
    local s = read()
    if not s then allZero(); sleep(0.05)
    else
      local now = os.clock(); local dt = clamp(now - last, 0.02, 0.5); last = now
      local alt = s.py - C.TARGET.y - C.DECK_ALT
      local vs = s.vy
      local g = gAt(alt)
      local dx, dz = C.TARGET.x - s.px, C.TARGET.z - s.pz
      local dist = math.sqrt(dx*dx + dz*dz)
      distNow = dist
      if first then
        first = false
        log(("INIT alt=%.1f dist=%.1f pos=%.1f,%.1f,%.1f"):format(alt, dist, s.px, s.py, s.pz))
        print(("alt %.0f m, distance to target %.0f m"):format(alt, dist))
        if dist > C.NAV_WARN then
          print(("WARNING: target is %.0f m away, may be too far to reach"):format(dist))
        end
      end
      -- rev12: attitude error valid at ANY tilt. Old lean = horizontal projection of "up": it is ~0 both upright and
      -- upside down (and meaningless on its side), so a craft starting past 90 deg was driven to 180 deg (log: 91 -> 176 deg).
      -- Now: rotation vector that takes body-up to world-up, in body axes (fy/ry = vertical components of forward/right).
      -- Same sign convention and ~same value as the old lean for small tilt.
      local th = math.rad(s.tilt)
      local sn = math.sin(th)
      local kA = (sn > 1e-3) and th / sn or 0
      local leanF, leanR = -s.fy * kA, -s.ry * kA
      if sn <= 1e-3 and s.uy < 0 then leanF = th end      -- exactly upside down: pitch over, any direction will do
      rF = rF + (s.wR - rF) * C.RATE_SMOOTH
      rR = rR + (-s.wF - rR) * C.RATE_SMOOTH

      -- impact: huge sudden decel (engines max ~ 56 m/s2) = we hit something -> stop fighting
      if burn and pvs and pvs < -5 and dt < 0.3 and (vs - pvs) / dt > C.IMPACT_ACC then
        log(("IMPACT alt=%.2f pvs=%.1f vs=%.1f tilt=%.1f dist=%.1f"):format(alt, pvs, vs, s.tilt, dist))
        allZero(); return
      end

      -- standing on something (vs ~ 0 low down) -> engines off
      if burn and ((alt < C.STILL_ALT and math.abs(vs) < C.STILL_VS) or (pDes < -3 and math.abs(vs) < 0.15)) then still = still + dt else still = 0 end   -- rev20: no standstill-landing in mid air   -- rev19: also stuck on something high up (log: vs=0.00 at 127 m for 4 s)
      if still > 1.5 then log(("LANDED alt=%.2f tilt=%.1f dist=%.1f"):format(alt, s.tilt, dist)); allZero(); return end

      -- online thrust-multiplier estimate (vertical accel vs commanded vac/vec of previous loop)
      if C.ADAPT and burn and pvs and dt < 0.3 then
        local expected = (G.VAC*(cache.vac or 0) + G.VEC*(cache.vec or 0)) * puy
        if expected > 1.8 then
          local meas = (vs - pvs) / dt + g + C.DRAG_K * vs * math.abs(vs)   -- rev20: drag compensation (was inflating kT 4.5 -> 7.65)
          kT = clamp(kT + C.ADAPT_K * (clamp(meas / expected, 1, 10) - kT), C.KT_MIN, C.KT_MAX)
        end
      end
      if (pcr or (burn and vacOff)) and pvs and dt < 0.3 and (cache.vac or 0) == 0 and (cache.vec or 0) >= 1 and math.abs(vs) < 60 then   -- rev20: also learn vec-only thrust during landing
        local meas = (vs - pvs) / dt + g + C.DRAG_K * vs * math.abs(vs)
        local ex = G.VEC * kT * cache.vec * puy
        kC = clamp(kC + 0.08 * (clamp(meas / ex, 0.3, 5) - kC), 0.3, 5)
      end
      pvs, puy = vs, s.uy

      local aMax = (G.VAC + G.VEC) * 15 * kT
      local aBrake = clamp(C.BRAKE_FRAC * (aMax - g), 1, C.BRAKE_CAP)
      local aProf = 0.8 * aBrake                        -- decel the descent profile really asks for
      local aVecMax = math.max(15 * G.VEC * kT * kC * 0.97, C.VEC_ACC_MIN)
      local aL = clamp(C.A_LAND_FRAC * (aVecMax - g), 1.5, C.A_LAND_MAX)
      local vEnd = C.TOUCH_VS + C.LAND_K * (C.VAC_ALT - C.TOUCH_ALT)
      local av, stop = -vs, 0
      if vs < 0 then
        if C.VAC_USE and av > vEnd then stop = C.VAC_ALT - C.TOUCH_ALT + C.BURN_MARGIN * (av*av - vEnd*vEnd) / (2*aProf)
        else local vL = math.max(av - C.TOUCH_VS, 0); stop = C.LAND_MARGIN * vL * vL / (2*aL) end
      end
      if alt <= C.VAC_ALT or not C.VAC_USE then vacOff = true end
      -- rev21: lateral flight finished -> leave the slow exponential profile (36 s of hover thrust, 20 m/s of fuel wasted per 2 s while orbiting)
      if vacOff and not fast then fast = true; log(("FAST alt=%.1f dist=%.1f vs=%.1f aL=%.2f"):format(alt, dist, vs, aL)) end
      if not burn and (alt < stop + C.TOUCH_ALT + C.NAV_ALT_K * dist) then
        burn = true; burnT0 = now; log(("BURN alt=%.1f vs=%.1f kT=%.2f aBrake=%.1f dist=%.1f"):format(alt, vs, kT, aBrake, dist))
      end
      if burn and alt <= C.CUT_ALT then
        log(("CUTOFF alt=%.2f vs=%.2f tilt=%.1f dist=%.1f"):format(alt, vs, s.tilt, dist)); allZero(); return
      end

      -- horizontal guidance -> desired lean (only during burn, pure vertical near the pad / the ground)
      local desF, desR = 0, 0
      local dF, dR = 0, 0
      local vac, vecL, aDes, desVS = 0, 0, 0, 0
      local vCapLog = 0
      local cr = false
      if burn then
        local vProf = C.TOUCH_VS + C.LAND_K * math.max(alt - C.TOUCH_ALT, 0)
        local aFF = C.LAND_K * vProf
        if not vacOff then
          vProf = math.sqrt(2*aProf*math.max(alt - C.VAC_ALT, 0)) + vEnd
          aFF = aProf
        end
        if fast then   -- rev21: constant-decel profile v = vt + sqrt(2*aL*h)
          vProf = C.TOUCH_VS + math.sqrt(2 * aL * math.max(alt - C.TOUCH_ALT, 0))
          aFF = aL
        end
        local vCap = C.MAX_DESC   -- no slow-descent cap: free fall, then hard late burn
        vCapLog = vCap
        desVS = -math.min(vCap, vProf)
        local ev = desVS - vs
        local aff = (alt > C.TOUCH_ALT and vProf < vCap) and aFF * clamp(1 + ev, 0, 1) or 0   -- no ff when far above profile speed (it cancelled VS_KP -> hover)
        if alt <= C.TOUCH_ALT + 3 then trim = trim * math.max(1 - 2*dt, 0) elseif math.abs(ev) < 5 then trim = clamp(trim + C.TRIM_KI*ev*dt, -C.TRIM_LIM, C.TRIM_LIM) end
        aDes = clamp(math.max(g + aff + trim + C.VS_KP*ev, 0) / math.max(s.uy, 0.5), 0, aMax * 0.95)
        if s.uy < 0.2 then aDes = 0 end   -- rev12: more than ~78 deg off vertical: thrust is useless/harmful, only righting (RCS)
        if s.tilt > C.TILT_THR and alt > 200 then aDes = aDes * clamp(1 - (s.tilt - C.TILT_THR) / C.TILT_THR_W, 0.15, 1) end
        aDes = math.min(aDes, pA + C.A_RISE * dt)   -- rev20: thrust ramp, no 0 -> 40 step   -- rev10: badly tilted -> don't push sideways, rotate first
        if alt > C.NAV_MIN_ALT then
          local ml = clamp(C.ML_BASE + 0.0004 * alt, C.ML_MIN, C.MAX_LEAN)
          local aref = math.max(aDes, g)
          local tg = clamp(2 * math.max(alt - C.TOUCH_ALT, 0.1) / (math.abs(vs) + C.TOUCH_VS), C.EG_TMIN, 120)
          local ramp = clamp((now - burnT0) / C.NAV_RAMP, 0, 1)
          local ax, az
          if alt < C.DAMP_ALT then ax, az = -C.NAV_KP_B * s.vx * ramp, -C.NAV_KP_B * s.vz * ramp
          else ax, az = (6*dx/(tg*tg) - 4*s.vx/tg) * ramp, (6*dz/(tg*tg) - 4*s.vz/tg) * ramp end
          bx, bz = 0, 0
          local wx, wz = ax / aref, az / aref
          local lim = ml
          local wm = math.sqrt(wx*wx + wz*wz)
          if wm > lim then wx, wz = wx * lim / wm, wz * lim / wm end
          local tf = clamp(1 - (s.tilt - C.TILT_SAFE) / (C.TILT_SAFE * 1.5), 0, 1)
          desF = (wx*s.fx + wz*s.fz) * tf
          desR = (wx*s.rx + wz*s.rz) * tf
        end
        -- slew limit
        local mx = C.LEAN_SLEW * dt
        desF = pdF + clamp(desF - pdF, -mx, mx)
        desR = pdR + clamp(desR - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt        -- desired lean rate (feed-forward)
        local gv, gc = G.VEC * kT * (vacOff and kC or 1), G.VAC * kT   -- rev20: vec-only uses learned kC
        if vacOff then aDes = math.min(aDes, 15 * gv * 0.97) end
        local vecT = clamp(C.VEC_FRAC * aDes / gv, C.VEC_MIN, 15)       -- wanted vec share (gimbal authority)
        vac = clamp(math.floor((aDes - vecT*gv) / gc + 0.5), 0, 15)      -- integer vac
        if vac > 0 and (aDes - vac*gc) / gv < C.VEC_MIN then vac = vac - 1 end
        vecL = clamp((aDes - vac*gc) / gv, C.VEC_MIN, 15)                -- vec takes the fine remainder
        if vacOff then vac = 0; vecL = clamp(aDes / gv, C.VEC_MIN, 15) end   -- rev14: never vacuum engines in landing
        pA = aDes
      elseif alt > 200 and dist > C.NAV_DEAD and s.tilt < C.TILT_SAFE then
        -- steer while falling: lean thrust toward the pad, vertical speed is not held
        local tgo = math.max(alt - C.ALT_BURN_EST, 1) / math.max(-vs, 40)
        local vh = math.min(C.NAV_MAX, 1.3 * dist / tgo)
        -- rev19: below ~600 m tgo = 1/v gave a 40 m/s demand = full lean (19 deg) at burn start -> x8 thrust kicked it sideways 5 -> 10 m/s, past the pad
        local mlc = clamp(C.ML_BASE + 0.0004 * alt, C.ML_MIN, C.MAX_LEAN)
        vh = math.min(vh, math.sqrt(2 * C.CRUISE_LEAN * C.CRUISE_A * C.NAV_PK * math.max(dist - C.NAV_DEAD, 0)))
        local ax = C.NAV_KP * (dx/dist*vh - s.vx)
        local az = C.NAV_KP * (dz/dist*vh - s.vz)
        local wx, wz = ax / C.CRUISE_A, az / C.CRUISE_A
        local wm = math.sqrt(wx*wx + wz*wz)
        if wm > C.CRUISE_LEAN then wx, wz = wx * C.CRUISE_LEAN / wm, wz * C.CRUISE_LEAN / wm end
        local mx = C.LEAN_SLEW * dt
        desF = pdF + clamp(wx*s.fx + wz*s.fz - pdF, -mx, mx)
        desR = pdR + clamp(wx*s.rx + wz*s.rz - pdR, -mx, mx)
        dF, dR = (desF - pdF) / dt, (desR - pdR) / dt
        -- thrust only while really falling (never lifts the craft), scaled by learned vec thrust
        local f = clamp((-vs - 5) / 10, 0, 1)
        aDes = C.CRUISE_A * f
        if f > 0 then vecL = clamp(aDes / (G.VEC * kT * kC), C.VEC_MIN, 15); cr = true end
      end
      pdF, pdR = desF, desR
      if not burn then pA = 0 end
      pDes = burn and desVS or 0
      pcr = cr

      if (burn and alt > C.TOUCH_ALT + 3) or cr then
        if s.tilt < 35 then
          local kI = cr and C.ATT_KI_C or C.ATT_KI
          iF = clamp(iF + kI * (desF - leanF) * dt, -C.ATT_IMAX, C.ATT_IMAX)
          iR = clamp(iR + kI * (desR - leanR) * dt, -C.ATT_IMAX, C.ATT_IMAX)
        end
      else iF, iR = iF * math.max(1 - 2*dt, 0), iR * math.max(1 - 2*dt, 0) end
      local tF = C.KP*(desF - leanF) + C.KD*(dF - rF) + iF
      local tR = C.KP*(desR - leanR) + C.KD*(dR - rR) + iR
      local tY = -C.KDY * s.wU
      attitude(tF, tR, tY, vecL, kT * ((vacOff or cr) and kC or 1))   -- rev21: gimbal torque scales with REAL vec thrust (kC was ignored: loop gain x1.7 -> 6 s lean oscillation)
      out("vac", vac); out("vec", vecL)
      flush()
      n = n + 1
      if n % 20 == 0 and logf then logf.flush() end
      local sig = s.py + s.vy + s.ux + s.wR
      if sig == lastSig then stale = stale + 1 else stale = 0 end
      lastSig = sig
      local c = cache
      log(("%.1f a=%.1f vs=%.2f/%.2f vh=%.1f dist=%.0f tilt=%.1f l=%.3f,%.3f d=%.3f,%.3f r=%.3f,%.3f t=%.3f,%.3f aDes=%.1f kT=%.2f trim=%.2f vc=%.0f vac=%.1f vec=%.1f rcs=%d,%d,%d,%d zav=%d,%d gim=%d,%d,%d,%d b=%s dt=%.2f wU=%.3f kC=%.2f")
        :format(now, alt, vs, desVS, math.sqrt(s.vx*s.vx+s.vz*s.vz), distNow, s.tilt, leanF, leanR, desF, desR, rF, rR, tF, tR,
          aDes, kT, trim, vCapLog, vac, vecL, c.rcs_tl or 0, c.rcs_tr or 0, c.rcs_bl or 0, c.rcs_br or 0, c.zav_l or 0, c.zav_r or 0,
          c.gim_n or 0, c.gim_s or 0, c.gim_w or 0, c.gim_e or 0, burn and 1 or 0, dt, s.wU, kC))
      if stale >= C.STALE_LOOPS then log("STALE sensors -> abort"); allZero(); print("sensors frozen"); return end
    end
  end
end

local ok, err = pcall(run)
allZero()
if logf then logf.close() end
if not ok then error(err, 0) end
print("done")