-- STARSHIP HIGH-ALTITUDE TEST (SN8-style)
-- Ascent -> coast at apogee -> hand off to sh_landing.lua
-- Climb profile scaled from the real SN8 flight, ~3x faster
local C = {
  APO = 2200,            -- apogee above deck, m
  VCRUISE = 30,          -- cruise climb rate, m/s
  V0 = 5.3, A_UP = 1.24, -- start: vs = V0 + A_UP*t
  A_DEC = 0.88,          -- decel near apogee, m/s2
  KVZ = 1.0, KIV = 0.04, LVL_MAX = 12,   -- LVL_MAX: thrust headroom
  A_LVL = 1.65,          -- m/s2 per vec level (from logs)
  ASC_MAX_T = 330,
  -- horizontal: hold point drifts toward the pad during ascent
  PAD = { x = -3278, z = 6378 }, STANDOFF = 0, SAME_SPOT = false,  -- SAME_SPOT=true: stay above launch point
  -- STANDOFF: apogee point distance from the pad, m
  HOLD_KP = 0.05, HOLD_VMAX = 10, HOLD_KV = 0.10, HOLD_LEAN = 0.10, HOLD_KI = 0.004,
  KI_ASC = 0.15, BIAS_MAX = 0.5, BIAS_REF = 10,
  BIAS0_F = -0.048, BIAS0_R = -0.001,   -- constant thrust bias, from logs
  HDG = false, HDG_KP = 0.5, HDG_KD = 1.5, HDG_RATE = 0.3,  -- heading hold relative to pad line
  COUNTDOWN = 3,
  -- tilt before handoff
  FLIP = false, BELLY_TILT = 35, BELLY_RATE = 0.4, HANDOFF_VS = -15,   -- BELLY_TILT: deg at handoff
  TARGET_Y = 70, DECK_ALT = 24.8,
  RCS_MULT = 1, GIM_SHARE = 0.97, RCS_DB = 0.006, YAW_DB = 0.02, GIM_GAIN = 1.5, KT = 4.5,
  KP = 0.4, KD = 1.5, RATE_MAX = 0.4, FLIP_RATE = 0.8, KDY = 1.5, YAW_MAX = 0.10, RATE_SMOOTH = 0.7,
  LANDING = "sh_landing.lua", LOG = "hitest.log",
}
local G = {
  VEC = 0.367,
  TOP_F = 0.0096, BOT_F = 0.0058, YAW_R = 0.0133, YAW_L = 0.0144,
  ZAV_L = 0.0016, ZAV_R = 0.0057,   -- ZAV_L, GIM_W synced with sh_landing.lua
  GIM_N = 0.0045, GIM_S = 0.0039, GIM_W = 0.0013, GIM_E = 0.0040, GIM_REF_VEC = 8,
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

-- dithered output: fractional levels act as time-averaged thrust
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
  local bx, _, bz = rot(-qx, -qy, -qz, qw, 0, 1, 0)
  local fx, _, fz = rot(qx, qy, qz, qw, 0, 0, 1)
  local rx, _, rz = rot(qx, qy, qz, qw, 1, 0, 0)
  local fl, rl = math.sqrt(fx*fx + fz*fz), math.sqrt(rx*rx + rz*rz)
  if fl < 1e-3 or rl < 1e-3 then return nil end
  return {
    px = pose.position.x, py = pose.position.y, pz = pose.position.z,
    vx = v.x, vy = v.y, vz = v.z,
    wR = w.x, wU = w.y, wF = w.z,
    ux = ux, uy = uy, uz = uz, bx = bx, bz = bz,
    fx = fx/fl, fz = fz/fl, rx = rx/rl, rz = rz/rl,
    tilt = math.deg(math.acos(clamp(uy, -1, 1))),
  }
end

local function db(v, d) if v > -d and v < d then return 0 end return v end
local function attitude(tF, tR, tY, vecLevel, kT)
  tY = db(tY, C.YAW_DB)
  local gs = math.max(vecLevel, 1) / G.GIM_REF_VEC * kT * C.GIM_GAIN
  local sh = C.GIM_SHARE * clamp((vecLevel - 1) / 5, 0, 1)
  local rF, rR = db(tF * (1 - sh), C.RCS_DB), db(tR * (1 - sh), C.RCS_DB)
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

local logf = fs.open(C.LOG, "w")
local function log(x) if logf then logf.writeLine(x) end end
local function pd(err, dRate, rate, rmax)
  return C.KD * (clamp(C.KP * err / C.KD, -rmax, rmax) + dRate - rate)
end

local function run()
  local phase, t0, last = "ascent", os.clock(), os.clock()
  local rF, rR, flipF, pdF, pdR, n = 0, 0, 0, 0, 0, 0
  local bF, bR = C.BIAS0_F, C.BIAS0_R
  local homeX, homeZ, aimX, aimZ
  local coastT = 0
  local ipx, ipz = 0, 0
  local stale, lastSig, first, iV, lastPrint = 0, nil, true, 0, 0
  while true do
    local s = read()
    if not s then allZero(); sleep(0.05)
    else
      local now = os.clock(); local dt = clamp(now - last, 0.02, 0.5); last = now
      if not homeX then
        homeX, homeZ = s.px, s.pz
        aimX, aimZ = homeX, homeZ
        if C.PAD then
          local dx, dz = C.PAD.x - homeX, C.PAD.z - homeZ
          local d = math.sqrt(dx*dx + dz*dz)
          if d > 1 and not C.SAME_SPOT then   -- STANDOFF > d: apogee farther from pad than launch
           aimX, aimZ = C.PAD.x - dx/d*C.STANDOFF, C.PAD.z - dz/d*C.STANDOFF end
          log(("PAD dist from launch %.1f m, aim point offset %.1f m"):format(d, math.sqrt((aimX-homeX)^2 + (aimZ-homeZ)^2)))
        end
        log(("HOME %.1f,%.1f,%.1f"):format(s.px, s.py, s.pz))
      end
      local alt = s.py - C.TARGET_Y - C.DECK_ALT
      local g = gAt(alt)
      local tt = now - t0
      local leanF = s.ux*s.fx + s.uz*s.fz
      local leanR = s.ux*s.rx + s.uz*s.rz
      if s.tilt > 20 then
        local k = math.rad(s.tilt)
        local sn = math.sqrt(s.bx*s.bx + s.bz*s.bz)
        if sn > 1e-3 then leanF, leanR = -k*s.bz/sn, -k*s.bx/sn else leanF, leanR = k, 0 end
      end
      rF = rF + (s.wR - rF) * C.RATE_SMOOTH
      rR = rR + (-s.wF - rR) * C.RATE_SMOOTH
      local drift = math.sqrt((s.px-homeX)^2 + (s.pz-homeZ)^2)
      local padD = C.PAD and math.sqrt((C.PAD.x-s.px)^2 + (C.PAD.z-s.pz)^2) or 0
      local hc, he = 0, 0
      local hdgOn = C.HDG and C.PAD and not C.SAME_SPOT and alt > C.APO * 0.5 and padD > 20
      if hdgOn then
        local tx, tz = -(C.PAD.z - s.pz), C.PAD.x - s.px
        local tl = math.sqrt(tx*tx + tz*tz); tx, tz = tx/tl, tz/tl
        he = (math.atan2 or math.atan)(s.rz*tx - s.rx*tz, s.rx*tx + s.rz*tz)
        local psid = s.wR*s.bx + s.wU*s.uy + s.wF*s.bz
        hc = clamp(C.HDG_KD * (clamp(C.HDG_KP*he/C.HDG_KD, -C.HDG_RATE, C.HDG_RATE) - psid), -C.YAW_MAX, C.YAW_MAX)
      end
      local desF, desR, vecL, vsT = 0, 0, 0, 0
      if phase == "ascent" then
        -- vertical profile: accelerate, cruise, decelerate to zero at apogee
        local vcr = math.min(C.VCRUISE, C.V0 + C.A_UP * tt)
        local vdec = math.sqrt(2 * C.A_DEC * math.max(C.APO - alt, 0)) + 0.4
        local aFF = 0
        vsT = vcr
        if vdec < vcr then vsT, aFF = vdec, -C.A_DEC elseif vcr < C.VCRUISE then aFF = C.A_UP end
        iV = clamp(iV + C.KIV * (vsT - s.vy) * dt, -2, 2)
        local aCmd = aFF + C.KVZ * (vsT - s.vy)
        vecL = clamp((g + aCmd) / C.A_LVL / math.max(s.uy, 0.8) + iV, 0, C.LVL_MAX)
        -- hold point eases (smoothstep) toward the apogee point
        local p = clamp(alt / C.APO, 0, 1)
        local sp = p*p*(3 - 2*p)
        local dsp = 6*p*(1 - p) * s.vy / C.APO
        local tx = homeX + (aimX - homeX) * sp
        local tz = homeZ + (aimZ - homeZ) * sp
        ipx = clamp(ipx + C.HOLD_KI*(tx - s.px)*dt, -2, 2); ipz = clamp(ipz + C.HOLD_KI*(tz - s.pz)*dt, -2, 2)
        local vmx = clamp(ipx + C.HOLD_KP*(tx - s.px) + (aimX - homeX)*dsp, -C.HOLD_VMAX, C.HOLD_VMAX)
        local vmz = clamp(ipz + C.HOLD_KP*(tz - s.pz) + (aimZ - homeZ)*dsp, -C.HOLD_VMAX, C.HOLD_VMAX)
        local aT = math.max(G.VEC * vecL * C.KT, 5)
        local ax, az = C.HOLD_KV * (vmx - s.vx), C.HOLD_KV * (vmz - s.vz)
        desF = clamp((ax*s.fx + az*s.fz) / aT, -C.HOLD_LEAN, C.HOLD_LEAN)
        desR = clamp((ax*s.rx + az*s.rz) / aT, -C.HOLD_LEAN, C.HOLD_LEAN)
        if alt >= C.APO - 3 or (alt > C.APO * 0.9 and s.vy < 0.8) or tt > C.ASC_MAX_T then
          phase = "coast"; vecL = 0; coastT = tt
          log(("MECO alt=%.1f vs=%.1f t=%.0f pad=%.1f vh=%.1f"):format(alt, s.vy, tt, padD, math.sqrt(s.vx^2 + s.vz^2)))
        end
      else
        if C.FLIP and s.vy < 0 and (not hdgOn or math.abs(he) < 0.25 or tt - coastT > 12) then flipF = math.min(flipF + C.BELLY_RATE*dt, math.rad(C.BELLY_TILT)) end
        desF = -flipF
        if s.vy < C.HANDOFF_VS and (not C.FLIP or s.tilt >= C.BELLY_TILT - 5) then
          log(("HANDOFF alt=%.1f vs=%.1f tilt=%.1f pad=%.1f vh=%.1f t=%.0f"):format(alt, s.vy, s.tilt, padD, math.sqrt(s.vx^2 + s.vz^2), tt))
          return true
        end
      end
      if phase == "ascent" and alt > 0.5 and s.tilt < 25 then   -- trim starts right at liftoff
        bF = clamp(bF + C.KI_ASC * clamp(desF - leanF, -0.3, 0.3) * dt, -C.BIAS_MAX, C.BIAS_MAX)
        bR = clamp(bR + C.KI_ASC * clamp(desR - leanR, -0.3, 0.3) * dt, -C.BIAS_MAX, C.BIAS_MAX)
      elseif phase ~= "ascent" then bF, bR = 0, 0 end
      local bs = vecL / C.BIAS_REF
      local dF, dR = (desF - pdF) / dt, (desR - pdR) / dt
      if first then dF, dR, first = 0, 0, false end
      pdF, pdR = desF, desR
      local rmax = C.RATE_MAX + (C.FLIP_RATE - C.RATE_MAX) * clamp((s.tilt - 30) / 30, 0, 1)
      local tF, tR = pd(desF - leanF, dF, rF, rmax) + bF*bs, pd(desR - leanR, dR, rR, rmax) + bR*bs
      local tY = clamp(-C.KDY * s.wU, -C.YAW_MAX, C.YAW_MAX)
      if hdgOn then tF = tF + hc*s.bx; tR = tR - hc*s.bz; tY = clamp(hc*s.uy, -C.YAW_MAX, C.YAW_MAX) end
      attitude(tF, tR, tY, vecL, C.KT)
      out("vac", 0); out("vec", vecL); flush()
      local sig = s.py + s.vy + s.ux + s.wR
      if sig == lastSig and alt > 3 then stale = stale + 1 else stale = 0 end
      lastSig = sig
      if stale >= 30 then
        log(("STALE sensors alt=%.1f -> abort"):format(alt)); logf.flush()
        return false
      end
      n = n + 1
      if n % 5 == 0 then
        log(("%.1f %s a=%.1f vs=%.1f/%.1f vh=%.1f pad=%.0f tilt=%.1f vec=%.1f l=%.3f,%.3f d=%.3f,%.3f b=%.3f,%.3f iV=%.2f"):format(
          now, phase, alt, s.vy, vsT, math.sqrt(s.vx^2+s.vz^2), padD, s.tilt, vecL, leanF, leanR, desF, desR, bF, bR, iV))
        logf.flush()
      end
      if now - lastPrint >= 1 then
        lastPrint = now
        print(("T+%3d %-6s alt %5.0f vs %6.1f pad %4.0f tilt %3.0f"):format(tt, phase, alt, s.vy, padD, s.tilt))
      end
    end
  end
end

for i = C.COUNTDOWN, 1, -1 do print("T-" .. i); sleep(1) end
print("LIFTOFF")
local ok, res = pcall(run)
allZero()
if logf then logf.close() end
if not ok then error(res, 0) end
if res then dofile(C.LANDING) end