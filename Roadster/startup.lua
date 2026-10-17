local C = {
  inFreq = {"minecraft:cyan_wool", "minecraft:cyan_wool"}, -- throttle: 0 off, 8 hover
  rollR = {"minecraft:dirt", "minecraft:dirt"}, -- hold: rotate right, release: level
  rollL = {"minecraft:sand", "minecraft:sand"}, -- hold: rotate left, release: level
  rcs = {
    {f = {"minecraft:white_wool", "minecraft:white_wool"},                   sx = -1, sz = -1}, -- front right
    {f = {"minecraft:white_concrete", "minecraft:white_concrete"},           sx = -1, sz =  1}, -- front left
    {f = {"minecraft:red_carpet", "minecraft:red_carpet"},                   sx =  1, sz = -1}, -- rear right
    {f = {"minecraft:brown_stained_glass", "minecraft:brown_stained_glass"}, sx =  1, sz =  1}, -- rear left
  },

  flipRate = 3.0,
  flipSlew = 0.6,  -- torque ramp while held
  flipD = 0.25,
  flipTau = 0.25,
  flipAuthD = 29.6,
  flipAuthB = 24.8,
  flipBrake = 1.0,
  flipKm = 1.6,
  kW = 0.3,
  recVy = -1.0,
  recTime = 2.0,
  flipC = 0.28,
  flipBoost = 0.6, -- thrust share while upright in a flip (same at start and end -> no sideways drift)
  kHd = 0.05, hdMax = 0.15, dampTime = 6, -- brake horizontal speed after a flip
  flipCx = 0.075,
  flipExit = 0.35,
  flipExitW = 0.6,
  flipMax = 3.5,
  flipCommit = 0.3, -- released after this share of a turn (0.3 = ~108 deg) -> finish the flip forward, before it -> go back to level (0.5 = old nearest-way)
  rescue = true,    -- throttle on, body tilted past ~72 deg and no flip: auto-righting flip, so a dropout in the air doesn't leave it tumbling
  idleStab = true, -- throttle 0 and no roll: still keep the body level with RCS
  idleMax = 0.12, idleMinUy = 0.3, -- idleMax kept low: leveling thrust must stay below hover or it lifts the ship off after a touchdown
  idleVy = 1.5,   -- only when |vy| is above this (airborne), not while driving
  idleHold = 0.5, -- keep active this long after vy drops
  idleOn = 0.25,  -- dead zone: start leveling above this tilt (~14 deg)
  idleOff = 0.08, -- stop leveling below this tilt
  landBrake = true, -- brake the fall just above the ground
  landAlt = 12,     -- m above the ground where braking starts
  landV = 1.5,      -- allowed descent speed at touchdown, m/s
  landK = 0.6,      -- allowed descent speed grows by this per meter of height, 1/s
  groundY = nil,    -- optional fixed ground Y; otherwise learned where the ship rests
  sDropFlip = 4.0, -- during a flip a throttle dropout is ignored this long (s), so the flip is not cut off half way
  sDebounce = 0.2, -- throttle must read 0 this long (s) before engines are really cut
  aRec = 12.0,
  vStep = 1.0,      -- climb speed per throttle level above 8, m/s
  vStepDown = 0.4,  -- descent speed per throttle level below 8, m/s (s=5 -> -1.2, s=1 -> -2.8)
  kP = 0.10, kI = 0.05,
  aMax = 5.0,
  hover = 0.285,
  kTx = 0.45, kDx = 0.25,
  kTz = 0.08, kDz = 0.10, kDzRec = 1.5, kItz = 0.005, itMaxZ = 0.03,
  kIt = 0.3, itMax = 0.1,
  dither = true,
  debug = true,
}

local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "no redstone_link_bridge")
local function sig(f) return bridge.getLinkSignal(f[1], f[2]) end
local function put(f, v) bridge.sendLinkSignal(f[1], f[2], v) end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local TWO_PI = 2 * math.pi

local atan2 = math.atan2 or math.atan

local function wrap(a)
  while a > math.pi do a = a - 2 * math.pi end
  while a < -math.pi do a = a + 2 * math.pi end
  return a
end

local function localUp(q)
  local x, y, z, w = q.v.x, q.v.y, q.v.z, q.a
  return 2*w*z + 2*x*y, 1 - 2*(x*x + z*z), -2*w*x + 2*y*z
end

local integ, plx, plz = C.hover, 0, 0
local dlx, dlz = 0, 0
local itx, itz = 0, 0
local acc = {0, 0, 0, 0}
local tv = 0
local was = false

local pphi, omega = 0, 0
local pomega, alpha = 0, 0
local flip = nil
local recover = 0
local settle, zeroT, lastS = 0, 99, 0
local idleT, idleOn = 0, false
local py, restT, groundY = 0, 0, C.groundY
local damp = 0
local hist = {}

local function uIn(tin)
  local u = 0
  for _, h in ipairs(hist) do
    if h.t <= tin - C.flipD then u = h.u else break end
  end
  return u
end

local function stopMargin(now, rem, w, ue, uf)
  local sgn = w >= 0 and 1 or -1
  local h, tt = 0.05, 0
  local a = 1 - math.exp(-h / C.flipTau)
  while tt < 2.5 do
    local ui = (tt >= C.flipD) and uf or uIn(now + tt)
    ue = ue + (ui - ue) * a
    w = w + ((ue * w >= 0) and C.flipAuthD or C.flipAuthB) * ue * h
    rem = rem - w * h
    tt = tt + h
    if sgn * w <= 0 then break end
  end
  return sgn * rem, sgn
end

-- w the body would reach if no further torque were commanded (accounts for delay + lag of what is already in flight)
local function wAhead(now, w, ue)
  local h, tt = 0.05, 0
  local a = 1 - math.exp(-h / C.flipTau)
  local T = C.flipD + 2 * C.flipTau
  while tt < T do
    local ui = (tt >= C.flipD) and 0 or uIn(now + tt)
    ue = ue + (ui - ue) * a
    w = w + ((ue * w >= 0) and C.flipAuthD or C.flipAuthB) * ue * h
    tt = tt + h
  end
  return w
end

local s, pose, vel = 0, nil, nil
local rR, rL = 0, 0
local out = {0, 0, 0, 0}
local last = {-1, -1, -1, -1}
local tprev = os.clock()

local buf, logged, tick = {}, 0, 0
local function flush()
  if #buf == 0 then return end
  local f = fs.open("flight_log.txt", "a")
  if f then
    for _, l in ipairs(buf) do f.writeLine(l) end
    f.close()
  end
  buf = {}
end
if C.debug then
  local f = fs.open("flight_log.txt", "w")
  if f then f.writeLine("tick s lx lz uy vy integ itx itz out1 out2 out3 out4 dt tv flip w rem u mrg vlx vlz"); f.close() end
end

local function zeroAll()
  for _, r in ipairs(C.rcs) do put(r.f, 0) end
end

local function io()
  local fns = {
    function() s = sig(C.inFreq) end,
    function() rR = sig(C.rollR) end,
    function() rL = sig(C.rollL) end,
    function() pose = sublevel.getLogicalPose() end,
    function() vel = sublevel.getVelocity() end,
  }
  for i, r in ipairs(C.rcs) do
    if out[i] ~= last[i] then
      last[i] = out[i]
      local v = out[i]
      fns[#fns + 1] = function() put(r.f, v) end
    end
  end
  parallel.waitForAll(table.unpack(fns))
end

local function loop()
  while true do
    io()

    local now = os.clock()
    local dt = clamp(now - tprev, 0.05, 0.5)
    tprev = now

    -- ignore a short throttle dropout (it wipes the controller state mid-flight)
    if s > 0 then zeroT = 0 elseif was then zeroT = zeroT + dt else zeroT = 99 end
    if s == 0 and was and zeroT < (flip and C.sDropFlip or C.sDebounce) then s = lastS end
    if s > 0 then lastS = s end

    -- height above the spot where the ship last rested (throttle 0, not moving)
    local hgt = nil
    if pose and vel then
      local pp = pose.position
      if type(pp) == "table" and type(pp.y) == "number" then py = pp.y else py = py + vel.y * dt end
      if s == 0 and math.abs(vel.y) < 0.2 then restT = restT + dt else restT = 0 end
      if restT > 1.0 and not C.groundY then groundY = py end
      if groundY then hgt = math.max(py - groundY, 0) end
    end

    local lx, uy, lz, vy = 0, 1, 0, 0
    local vlx, vlz = 0, 0
    local dW, dRem, dU, dWP = 0, 0, 0, 0
    out = {0, 0, 0, 0}

    if s > 0 and pose and vel then
      lx, uy, lz = localUp(pose.orientation)
      vy = vel.y
      do
        local q = pose.orientation
        local qx, qy, qz, qw = q.v.x, q.v.y, q.v.z, q.a
        vlx = vel.x * (1 - 2*(qy*qy + qz*qz)) + vel.z * 2*(qx*qz - qw*qy)
        vlz = vel.x * 2*(qx*qz + qw*qy) + vel.z * (1 - 2*(qx*qx + qy*qy))
      end

      local phi = atan2(lz, uy)

      if not was then
        integ = C.hover
        plx, plz = lx, lz
        dlx, dlz = 0, 0
        itx, itz = 0, 0
        acc = {0, 0, 0, 0}
        tv = vy
        damp = 0
        pphi, omega = phi, 0
        pomega, alpha = 0, 0
        flip = nil
        settle = 3
      end
      if settle > 0 then settle = settle - 1 end

      local dphi = wrap(phi - pphi)
      pphi = phi
      omega = 0.5 * omega + 0.5 * dphi / dt
      alpha = clamp(0.6 * alpha + 0.4 * (omega - pomega) / dt, -12, 12)
      pomega = omega

      dlx = 0.3 * dlx + 0.7 * (lx - plx) / dt
      dlz = 0.3 * dlz + 0.7 * (lz - plz) / dt
      plx, plz = lx, lz

      -- hold = rotate that way, release = level out the nearest way
      local fReq = (rR > 0 and rL == 0 and 1) or (rL > 0 and rR == 0 and -1) or 0

      if not flip and fReq ~= 0 and settle == 0 and uy > 0.8 and math.abs(omega) < 1.5 then
        flip = {dir = fReq, ang = phi, t = 0, ue = 0, up = 0}  -- ang is absolute: target = true level, not the tilt at start
        hist = {}
      end

      if C.rescue and not flip and settle == 0 and uy <= 0.3 and (not hgt or hgt > 1.5) then
        flip = {dir = (phi > 0) and -1 or 1, ang = phi, t = 0, ue = 0, up = 0, target = 0}
        hist = {}
      end

      local rem
      if flip then
        local tau = 2 * math.pi
        flip.ang = flip.ang + dphi
        if fReq == flip.dir then
          flip.target = nil
          flip.t = 0
        else
          flip.t = flip.t + dt
          if not flip.target then
            local w0 = flip.dir * omega
            local sg0 = w0 >= 0 and 1 or -1
            local m0 = stopMargin(now, 0, w0, flip.ue, -sg0 * C.flipC * C.flipBrake)
            local pred = flip.ang - flip.dir * sg0 * m0
            local prog = flip.dir * pred  -- predicted stop angle, counted in the flip direction
            flip.target = flip.dir * math.floor(prog / tau + 1 - C.flipCommit) * tau
          end
        end
        if flip.target then
          rem = flip.dir * (flip.target - flip.ang)
          if (math.abs(rem) < C.flipExit and math.abs(omega) < C.flipExitW) or flip.t > C.flipMax then
            flip = nil
            itx, itz = 0, 0
            tv = vy
            recover = C.recTime
            damp = C.dampTime
            hist = {}
          end
        end
      end

      if flip or uy > 0.3 then
        local base, cx, cz

        if flip then
          local w = flip.dir * omega
          while #hist >= 2 and hist[2].t <= now - C.flipD do table.remove(hist, 1) end
          flip.ue = flip.ue + (uIn(now) - flip.ue) * (1 - math.exp(-dt / C.flipTau))
          local wp = wAhead(now, w, flip.ue)
          local uV = clamp(C.kW * (C.flipRate - wp), -C.flipC, C.flipC)
          local u, mrg = uV, 0
          if not rem then
            -- ramp only the accelerating torque; braking (uV < 0) applies immediately even while held
            if uV > 0 then u = math.min(uV, flip.up + C.flipSlew * dt) end
            -- held past the point where it could still stop at the next level pass: start braking early
            if w > 0.5 then
              local prog = flip.dir * flip.ang
              local dN = TWO_PI * (math.floor(prog / TWO_PI) + 1) - prog
              local mN = stopMargin(now, dN, w, flip.ue, -C.flipC * C.flipBrake)
              mrg = mN
              if mN < 0 then u = math.min(u, clamp(C.flipKm * mN, -C.flipC, C.flipC)) end
            end
          end
          if rem then
            local sg = w >= 0 and 1 or -1
            mrg = stopMargin(now, rem, w, flip.ue, -sg * C.flipC * C.flipBrake)
            local uM = sg * clamp(C.flipKm * mrg, -C.flipC, C.flipC)
            u = math.min(uM, uV)
          end
          if rem then flip.up = math.max(u, 0) elseif u > 0 then flip.up = u end
          hist[#hist + 1] = {t = now, u = u}
          dW, dRem, dU, dWP = w, rem or 0, u, mrg
          local sg = clamp(uy * 3, -1, 1)
          cx = clamp(sg * (C.kTx * lx + C.kDx * dlx), -C.flipCx, C.flipCx)
          cz = -flip.dir * u
          local k = clamp((uy - 0.6) / 0.3, 0, 1)
          base = math.max(math.abs(cz), k * C.flipBoost)
        else
          local tgt = (s - 8) * ((s < 8) and C.vStepDown or C.vStep)
          if C.landBrake and hgt and hgt < C.landAlt then tgt = math.max(tgt, -(C.landV + C.landK * hgt)) end
          local am = recover > 0 and C.aRec or C.aMax
          local boost = recover > 0 and vy < C.recVy and uy > 0.5
          recover = math.max(recover - dt, 0)
          if boost then
            tv = vy
          else
            tv = tv + clamp(tgt - tv, -am * dt, am * dt)
          end
          local err = tv - vy
          local uyc = math.max(uy, 0.5)
          local pre = (integ + C.kP * err) / uyc
          if not boost and not ((pre >= 1 and err > 0) or (pre <= 0 and err < 0)) then
            integ = clamp(integ + err * dt * C.kI, 0, 1)
          end
          base = boost and 1 or (integ + C.kP * err) / uyc

          local lxT, lzT = 0, 0
          if damp > 0 then
            damp = damp - dt
            lxT = clamp(C.kHd * vlx, -C.hdMax, C.hdMax)
            lzT = clamp(C.kHd * vlz, -C.hdMax, C.hdMax)
          end
          local ez = lz - lzT
          local ex = lx - lxT

          itx = clamp(itx + ex * dt * C.kIt, -C.itMax, C.itMax)
          itz = clamp(itz + ez * dt * C.kItz, -C.itMaxZ, C.itMaxZ)

          cx = C.kTx * ex + C.kDx * dlx + itx
          cz = C.kTz * ez + C.kDz * (recover > 0 and C.kDzRec or 1) * dlz + itz
        end

        local pr, pmax, pmin = {}, -1e9, 1e9
        for i, r in ipairs(C.rcs) do
          pr[i] = base - r.sx * cx - r.sz * cz
          pmax = math.max(pmax, pr[i])
          pmin = math.min(pmin, pr[i])
        end
        local shift = 0
        if pmax > 1 then shift = 1 - pmax end
        if pmin + shift < 0 then shift = -pmin end

        for i, r in ipairs(C.rcs) do
          local v = clamp(pr[i] + shift, 0, 1) * 15
          if C.dither then v = v + acc[i] end
          local lvl = clamp(math.floor(v + 0.5), 0, 15)
          acc[i] = C.dither and clamp(v - lvl, -0.5, 0.5) or 0
          out[i] = lvl
        end
      end
    elseif C.idleStab and pose and vel then
      -- no throttle: minimal RCS leveling, no collective thrust
      flip = nil
      lx, uy, lz = localUp(pose.orientation)
      vy = vel.y
      dlx = 0.3 * dlx + 0.7 * (lx - plx) / dt
      dlz = 0.3 * dlz + 0.7 * (lz - plz) / dt
      plx, plz = lx, lz
      idleT = math.max(idleT - dt, 0)
      if math.abs(vy) > C.idleVy then idleT = C.idleHold end
      local tilt = math.sqrt(lx * lx + lz * lz)
      if idleT <= 0 then idleOn = false
      elseif tilt > C.idleOn then idleOn = true
      elseif tilt < C.idleOff then idleOn = false end
      local base, brake = 0, false
      if C.landBrake and hgt and hgt < C.landAlt then
        local vLim = -(C.landV + C.landK * hgt)
        if vy < vLim then
          base = math.min(clamp(C.hover + C.kP * (vLim - vy), 0, 1) / math.max(uy, 0.5), 1)
          brake = true
        end
      end
      local onGround = hgt and hgt < 1.0
      if ((idleOn and not onGround) or brake) and uy > C.idleMinUy then
        local cx = clamp(C.kTx * lx + C.kDx * dlx, -C.idleMax, C.idleMax)
        local cz = clamp(C.kTz * lz + C.kDz * dlz, -C.idleMax, C.idleMax)
        local pr, pmax, pmin = {}, -1e9, 1e9
        for i, r in ipairs(C.rcs) do
          pr[i] = base - r.sx * cx - r.sz * cz
          pmax = math.max(pmax, pr[i])
          pmin = math.min(pmin, pr[i])
        end
        local shift = 0
        if pmax > 1 then shift = 1 - pmax end
        if pmin + shift < 0 then shift = -pmin end
        for i, r in ipairs(C.rcs) do
          local v = clamp(pr[i] + shift, 0, 1) * 15
          if C.dither then v = v + acc[i] end
          local lvl = clamp(math.floor(v + 0.5), 0, 15)
          acc[i] = C.dither and clamp(v - lvl, -0.5, 0.5) or 0
          out[i] = lvl
        end
      end
    else
      flip = nil
    end
    if C.debug and was and s == 0 then
      buf[#buf + 1] = ("DROP tick=%d zeroT=%.2f flip=%s uy=%.2f vy=%.2f pose=%s vel=%s"):format(
        tick, zeroT, tostring(flip ~= nil), uy, vy, tostring(pose ~= nil), tostring(vel ~= nil))
      flush()
    end
    if C.debug and s > 0 and not (pose and vel) then
      buf[#buf + 1] = ("NOPOSE tick=%d"):format(tick)
      flush()
    end
    was = s > 0

    if C.debug and s > 0 then
      tick = tick + 1
      if (tick % 5 == 0 or flip) and logged < 900 then
        logged = logged + 1
        buf[#buf + 1] = ("%d %d %.3f %.3f %.3f %.3f %.2f %.3f %.3f %d %d %d %d %.2f %.2f %.2f %.2f %.3f %.2f %.2f %.2f %.2f"):format(
          tick, s, lx, lz, uy, vy, integ, itx, itz, out[1], out[2], out[3], out[4], dt, tv,
          flip and flip.ang or 0, dW, dRem, dU, dWP, vlx, vlz)
      end
      if tick % 10 == 0 then flush() end
    end
  end
end

local ok, err = pcall(loop)
zeroAll()
flush()
if not ok then
  print(err)
  local f = fs.open("flight_log.txt", "a")
  if f then f.writeLine("ERR " .. tostring(err)); f.close() end
end