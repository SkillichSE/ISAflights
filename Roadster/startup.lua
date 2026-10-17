local C = {
  mode = "casual", -- casual | acro
  inFreq = {"minecraft:cyan_wool", "minecraft:cyan_wool"},
  rollR = {"minecraft:dirt", "minecraft:dirt"},
  rollL = {"minecraft:sand", "minecraft:sand"},
  pitchF = {"minecraft:blue_wool", "minecraft:blue_wool"},
  pitchB = {"minecraft:green_wool", "minecraft:green_wool"},
  rcs = {
    {f = {"minecraft:white_wool", "minecraft:white_wool"},                   sx = -1, sz = -1},
    {f = {"minecraft:white_concrete", "minecraft:white_concrete"},           sx = -1, sz =  1},
    {f = {"minecraft:red_carpet", "minecraft:red_carpet"},                   sx =  1, sz = -1},
    {f = {"minecraft:brown_stained_glass", "minecraft:brown_stained_glass"}, sx =  1, sz =  1},
  },

  flipRate = 2.2,
  flipSlew = 0.35,
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
  flipBoost = 0.6,
  kHd = 0.04, hdMax = 0.06, dampTime = 6,
  flipBoostMin = 0.35,
  kHdFlip = 0.05,
  holdTime = 5.0,
  holdS = 5,
  idleDamp = true,
  idleVh = 0.6, idleHdMax = 0.08,
  flipCx = 0.15,
  flipExit = 0.35,
  flipExitW = 0.6,
  flipMax = 3.5,
  flipCommit = 0.3,
  rescue = true,
  idleStab = true,
  idleMax = 0.12, idleMinUy = 0.3,
  idleVy = 1.5,
  idleHold = 0.5,
  idleOn = 0.25,
  idleOff = 0.08,
  landBrake = true,
  landAlt = 60,
  gEff = 9.8,
  landUse = 0.6,
  landEff = 0.8,
  idleMaxBrake = 0.3,
  brakeGain = 2.0,
  groundOff = 0.3,
  landDone = 0.4,
  flipMinAlt = 1.5,
  flipVy = 12,
  flipPreTilt = 0.08,
  flipPreThrust = 0.7, flipPreMax = 2.0,
  stuckTime = 1.0,
  stuckBand = 0.4,
  brakeMinAlt = 3,
  landTiltVy = 3,
  landTiltMin = 0.25,
  landLag = 0.3,
  landGroundCap = 1.1,
  landCapAlt = 1.5,
  kBoost = 0.15, boostMax = 0.8,
  landV = 1.5,
  groundY = nil,
  sDropFlip = 4.0,
  sDebounce = 0.2,
  aRec = 20.0,
  vStep = 1.0,
  vStepDown = 0.4,
  kP = 0.10, kI = 0.05,
  aMax = 5.0,
  hover = 0.285,
  kTx = 0.45, kDx = 0.25,
  kTz = 0.12, kDz = 0.14, kDzRec = 1.5, kItz = 0.1, itMaxZ = 0.08,
  kIt = 0.3, itMax = 0.1,
  dither = true,
  debug = true,
  pitchFlipHold = 1.0,
  pitchFlip = {
    rate = 2.0, authD = 14.8, authB = 12.4, c = 0.45, kW = 0.6, slew = 0.7,
  },
  flipHold = 0.7,
  bankMax  = 0.35,
  bankRamp = 0.6,
  bankGain = 3.0,
  bankKp   = 3,
  pitchV    = 10,
  pitchMax  = 0.3,
  pitchRamp = 1.0,
  pitchGain = 1.5,
  pitchKv   = 0.06,
  pitchSign = 1,
  autoBrake = true,
  brakeDb   = 0.5,
  idleKv    = 0.05,
  idleVyT   = -6,
  autoDescent = true,
  autoMinAlt = 3,
  autoVy = 15,
  idleMaxAir = 0.25,
}

local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "no redstone_link_bridge")
local function sig(f) return bridge.getLinkSignal(f[1], f[2]) end
local function put(f, v) bridge.sendLinkSignal(f[1], f[2], v) end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end

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

local function horizVel(q, v)
  local qx, qy, qz, qw = q.v.x, q.v.y, q.v.z, q.a
  return v.x * (1 - 2*(qy*qy + qz*qz)) + v.z * 2*(qx*qz - qw*qy),
         v.x * 2*(qx*qz + qw*qy) + v.z * (1 - 2*(qx*qx + qy*qy))
end

local K = {pphi = 0, omega = 0, pphiX = 0, omegaX = 0, keyT = 0, keyDir = 0, stuckT = 0, stuckY = 0, vrx = 0, vrz = 0, pitchT = 0, pitchDir = 0, preT = 0, restT = 0}
local integ, plx, plz = C.hover, 0, 0
local dlx, dlz = 0, 0
local itx, itz = 0, 0
local acc = {0, 0, 0, 0}
local tv = 0
local was = false

local flip = nil
local recover = 0
local settle, zeroT, lastS = 0, 99, 0
local idleT, idleOn, idleD = 0, false, false
local py, groundY = 0, C.groundY
local damp = 0
local holdT = 0
local holdAuto = false
local landOn = false
local hist = {}

local function uIn(tin)
  local u = 0
  for _, h in ipairs(hist) do
    if h.t <= tin - C.flipD then u = h.u else break end
  end
  return u
end

local AX = {
  z = {rate = C.flipRate, authD = C.flipAuthD, authB = C.flipAuthB, c = C.flipC, kW = C.kW, slew = C.flipSlew},
  x = C.pitchFlip,
}

local function stopMargin(now, rem, w, ue, uf, fa)
  local sgn = w >= 0 and 1 or -1
  local h, tt = 0.05, 0
  local a = 1 - math.exp(-h / C.flipTau)
  while tt < 2.5 do
    local ui = (tt >= C.flipD) and uf or uIn(now + tt)
    ue = ue + (ui - ue) * a
    w = w + ((ue * w >= 0) and fa.authD or fa.authB) * ue * h
    rem = rem - w * h
    tt = tt + h
    if sgn * w <= 0 then break end
  end
  return sgn * rem, sgn
end

local function wAhead(now, w, ue, fa)
  local h, tt = 0.05, 0
  local a = 1 - math.exp(-h / C.flipTau)
  local T = C.flipD + 2 * C.flipTau
  while tt < T do
    local ui = (tt >= C.flipD) and 0 or uIn(now + tt)
    ue = ue + (ui - ue) * a
    w = w + ((ue * w >= 0) and fa.authD or fa.authB) * ue * h
    tt = tt + h
  end
  return w
end

function C.landNeed(h, vy, uy, dt)
  local v = -vy
  local hp = h + C.groundOff - v * (C.landLag + dt)
  local aNeed = math.max(v * v - C.landV * C.landV, 0) / (2 * math.max(hp, 0.05))
  local aMax = C.gEff * (1 / C.hover - 1) * C.landEff * math.max(uy, 0.5)
  return aNeed, aMax
end

local s, pose, vel = 0, nil, nil
local rR, rL = 0, 0
local pF, pB = 0, 0
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
  if f then f.writeLine("tick s lx lz uy vy integ itx itz out1 out2 out3 out4 dt tv flip w rem u mrg vlx vlz hgt vwx vwz"); f.close() end
end

local function zeroAll()
  for _, r in ipairs(C.rcs) do put(r.f, 0) end
end

local function io()
  local fns = {
    function() s = sig(C.inFreq) end,
    function() rR = sig(C.rollR) end,
    function() rL = sig(C.rollL) end,
    function() pF = sig(C.pitchF) end,
    function() pB = sig(C.pitchB) end,
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
    local sRaw = s

    local now = os.clock()
    local dt = clamp(now - tprev, 0.05, 0.5)
    tprev = now

    if s > 0 then zeroT = 0 elseif was then zeroT = zeroT + dt else zeroT = 99 end
    if s == 0 and was and zeroT < (flip and C.sDropFlip or C.sDebounce) then s = lastS end
    if s > 0 then lastS = s end

    if s > 0 then
      holdT = 0
      holdAuto = false
    elseif was and holdT > 0 then
      holdT = holdT - dt
      s = holdAuto and 1 or C.holdS
    end

    local hgt = nil
    if pose and vel then
      local pp = pose.position
      if type(pp) == "table" and type(pp.y) == "number" then py = pp.y else py = py + vel.y * dt end
      if sRaw == 0 and math.abs(vel.y) < 0.2 then K.restT = K.restT + dt else K.restT = 0 end
      if K.restT > 1.0 and not C.groundY then groundY = py end
      if groundY then hgt = math.max(py - groundY, 0) end
    end

    if C.autoDescent and s == 0 and was and holdT <= 0 and hgt and hgt > C.autoMinAlt and pose and vel then
      holdT, holdAuto, s = 1e9, true, 1
    end

    if holdT > 0 and vel and tv < -0.8 and math.abs(py - K.stuckY) < C.stuckBand then
      K.stuckT = K.stuckT + dt
    else
      K.stuckT = 0
      K.stuckY = py
    end
    if holdT > 0 and K.stuckT >= C.stuckTime then
      holdT, holdAuto, s = 0, false, 0
      K.stuckT = 0
      itx, itz, landOn = 0, 0, false
      if not C.groundY and pose then groundY = py end
      hgt = 0
    end

    if holdT > 0 and hgt and vel and hgt < C.landDone and math.abs(vel.y) < 0.4 then
      holdT, holdAuto, s = 0, false, 0
      itx, itz, landOn = 0, 0, false
    end

    local lx, uy, lz, vy = 0, 1, 0, 0
    local vlx, vlz = 0, 0
    local dW, dRem, dU, dWP = 0, 0, 0, 0
    out = {0, 0, 0, 0}

    if s > 0 and pose and vel then
      lx, uy, lz = localUp(pose.orientation)
      vy = vel.y
      if not was then
        K.vrx, K.vrz = 0, 0
        if hgt and hgt < 1.0 and math.abs(vel.y) < 0.5 then K.vrx, K.vrz = vel.x, vel.z end
      end
      vlx, vlz = horizVel(pose.orientation, {x = vel.x - K.vrx, y = vel.y, z = vel.z - K.vrz})

      local phi = atan2(lz, uy)
      local phiX = atan2(lx, uy)

      if not was then
        integ = C.hover
        if not groundY and math.abs(vel.y) < 0.3 then groundY = py end
        plx, plz = lx, lz
        dlx, dlz = 0, 0
        itx, itz = 0, 0
        acc = {0, 0, 0, 0}
        tv = vy
        damp = 0
        K.pphi, K.omega = phi, 0
        K.pphiX, K.omegaX = phiX, 0
        flip = nil
        settle = 3
      end
      if settle > 0 then settle = settle - 1 end

      local dphi = wrap(phi - K.pphi)
      K.pphi = phi
      K.omega = 0.5 * K.omega + 0.5 * dphi / dt
      local dphiX = wrap(phiX - K.pphiX)
      K.pphiX = phiX
      K.omegaX = 0.5 * K.omegaX + 0.5 * dphiX / dt

      dlx = 0.3 * dlx + 0.7 * (lx - plx) / dt
      dlz = 0.3 * dlz + 0.7 * (lz - plz) / dt
      plx, plz = lx, lz

      local fReq = (rR > 0 and rL == 0 and 1) or (rL > 0 and rR == 0 and -1) or 0

      if fReq ~= 0 then
        if fReq ~= K.keyDir then K.keyT = 0 end
        K.keyDir = fReq
        K.keyT = K.keyT + dt
      else
        K.keyT = 0; K.keyDir = 0
      end

      local pReq = (pF > 0 and pB == 0 and 1) or (pB > 0 and pF == 0 and -1) or 0
      if pReq ~= 0 then
        if pReq ~= K.pitchDir then K.pitchT = 0 end
        K.pitchDir = pReq
        K.pitchT = K.pitchT + dt
      else
        K.pitchT = 0; K.pitchDir = 0
      end

      local wantAxis, wantDir = nil, 0
      if C.mode == "acro" then
        if fReq ~= 0 and K.keyT >= C.flipHold then wantAxis, wantDir = "z", fReq
        elseif fReq == 0 and pReq ~= 0 and K.pitchT >= C.pitchFlipHold then wantAxis, wantDir = "x", C.pitchSign * pReq end
      end
      local wantOm = (wantAxis == "x") and K.omegaX or K.omega

      if not flip and wantAxis and settle == 0 and uy > 0.8 and math.abs(wantOm) < 1.5 and (not hgt or hgt > C.flipMinAlt) and vy >= C.flipVy then
        K.preT = 0
        flip = {axis = wantAxis, dir = wantDir, ang = (wantAxis == "x") and phiX or phi, t = 0, ue = 0, up = 0}
        hist = {}
      end

      if C.rescue and not flip and settle == 0 and uy <= 0.3 and (not hgt or hgt > 1.5) then
        flip = {axis = "z", dir = (phi > 0) and -1 or 1, ang = phi, t = 0, ue = 0, up = 0, target = 0}
        hist = {}
      end

      local rem
      if flip then
        local tau = 2 * math.pi
        local fa = AX[flip.axis]
        local om = (flip.axis == "x") and K.omegaX or K.omega
        flip.ang = flip.ang + ((flip.axis == "x") and dphiX or dphi)
        local held = (flip.axis == "x") and (fReq == 0 and C.pitchSign * pReq or 0) or fReq
        if held == flip.dir then
          flip.target = nil
          flip.t = 0
        else
          flip.t = flip.t + dt
          if not flip.target then
            local w0 = flip.dir * om
            local sg0 = w0 >= 0 and 1 or -1
            local m0 = stopMargin(now, 0, w0, flip.ue, -sg0 * fa.c * C.flipBrake, fa)
            local pred = flip.ang - flip.dir * sg0 * m0
            local prog = flip.dir * pred
            flip.target = flip.dir * math.floor(prog / tau + 1 - C.flipCommit) * tau
          end
        end
        if flip.target then
          rem = flip.dir * (flip.target - flip.ang)
          if (math.abs(rem) < C.flipExit and math.abs(om) < C.flipExitW) or flip.t > C.flipMax then
            flip = nil
            itx, itz = 0, 0
            tv = vy
            recover = C.recTime
            damp = C.dampTime
            hist = {}
            if zeroT >= C.sDebounce and not holdAuto then holdT = C.holdTime end
          end
        end
      end

      if flip or uy > 0.3 then
        local base, cx, cz
        local grounded = false

        if flip then
          local fa = AX[flip.axis]
          local om = (flip.axis == "x") and K.omegaX or K.omega
          local w = flip.dir * om
          while #hist >= 2 and hist[2].t <= now - C.flipD do table.remove(hist, 1) end
          flip.ue = flip.ue + (uIn(now) - flip.ue) * (1 - math.exp(-dt / C.flipTau))
          local wp = wAhead(now, w, flip.ue, fa)
          local uV = clamp(fa.kW * (fa.rate - wp), -fa.c, fa.c)
          local u, mrg = uV, 0
          if not rem then
            if uV > 0 then u = math.min(uV, flip.up + fa.slew * dt) end
            if w > 0.5 then
              local prog = flip.dir * flip.ang
              local dN = 2 * math.pi * (math.floor(prog / (2 * math.pi)) + 1) - prog
              local mN = stopMargin(now, dN, w, flip.ue, -fa.c * C.flipBrake, fa)
              mrg = mN
              if mN < 0 then u = math.min(u, clamp(C.flipKm * mN, -fa.c, fa.c)) end
            end
          end
          if rem then
            local sg = w >= 0 and 1 or -1
            mrg = stopMargin(now, rem, w, flip.ue, -sg * fa.c * C.flipBrake, fa)
            local uM = sg * clamp(C.flipKm * mrg, -fa.c, fa.c)
            u = math.min(uM, uV)
          end
          if rem then flip.up = math.max(u, 0) elseif u > 0 then flip.up = u end
          hist[#hist + 1] = {t = now, u = u}
          dW, dRem, dU, dWP = w, rem or 0, u, mrg
          local sg = clamp(uy * 3, -1, 1)
          local tq = -flip.dir * u
          if flip.axis == "x" then
            local lzT = clamp(C.kHdFlip * vlz, -C.hdMax, C.hdMax)
            cz = clamp(sg * (C.kTz * (lz - lzT) + C.kDz * dlz), -C.flipCx, C.flipCx)
            cx = tq
          else
            local lxT = clamp(C.kHdFlip * vlx, -C.hdMax, C.hdMax)
            cx = clamp(sg * (C.kTx * (lx - lxT) + C.kDx * dlx), -C.flipCx, C.flipCx)
            cz = tq
          end
          local k = clamp((uy - 0.6) / 0.3, 0, 1)
          local wk = clamp(w / fa.rate, C.flipBoostMin, 1)
          base = math.max(math.abs(tq), k * C.flipBoost * wk)
        else
          local tgt = (s - 8) * ((s < 8) and C.vStepDown or C.vStep)
          if holdAuto and holdT > 0 then tgt = -C.autoVy end
          if C.landBrake and hgt and hgt < C.landAlt then
            local aProf = C.gEff * (1 / C.hover - 1) * C.landEff * C.landUse * math.max(uy, 0.5)
            local hp = math.max(hgt + C.groundOff - math.max(-vy, 0) * (C.landLag + dt), 0)
            tgt = math.max(tgt, -math.sqrt(C.landV * C.landV + 2 * aProf * hp))
          end
          local am = (recover > 0 or holdAuto) and C.aRec or C.aMax
          local boost = recover > 0 and vy < C.recVy and uy > 0.5
          local preBurn = wantAxis ~= nil and settle == 0 and uy > 0.8 and vy < C.flipVy and K.preT < C.flipPreMax and (not hgt or hgt > C.flipMinAlt) and math.abs(lx) < C.flipPreTilt and math.abs(lz) < C.flipPreTilt
          if preBurn then K.preT = K.preT + dt elseif fReq == 0 then K.preT = 0 end
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
          if boost then
            base = clamp(C.hover + C.kBoost * (C.recVy - vy), 0, C.boostMax) / uyc
          else
            base = (integ + C.kP * err) / uyc
          end
          if preBurn then
            base = C.flipPreThrust / uyc
            tv = vy
          end

          if C.landBrake and hgt and not preBurn and not boost and vy < -0.3 then
            local aNeed, aMax = C.landNeed(hgt, vy, uy, dt)
            if not landOn and aNeed >= C.landUse * aMax then landOn = true end
            if landOn then
              local floor = math.min(C.hover * (1 + aNeed / C.gEff) / uyc, 1)
              if hgt < C.landCapAlt and vy > -(C.landV + 0.5) then
                floor = math.min(floor, C.landGroundCap * C.hover / uyc)
              end
              base = math.max(base, floor)
            end
          elseif vy >= -0.3 then
            landOn = false
          end

          if hgt and hgt < C.landDone and math.abs(vy) < 0.4 and tgt < 0 and not preBurn and not boost then
            grounded = true
            integ = C.hover
            itx, itz = 0, 0
            tv = vy
          end

          local pMax = C.pitchMax
          if hgt and hgt < C.landAlt and vy < -C.landTiltVy then
            pMax = C.pitchMax * clamp(hgt / C.landAlt, C.landTiltMin, 1)
          end

          local lxT, lzT = 0, 0
          if damp > 0 then
            damp = damp - dt
            lxT = clamp(C.kHd * vlx, -C.hdMax, C.hdMax)
            lzT = clamp(C.kHd * vlz, -C.hdMax, C.hdMax)
          end
          local gx = 1
          local brakeOk = not (hgt and hgt < C.brakeMinAlt and vy > 0.3)
          local usePitch = K.pitchDir ~= 0 and fReq == 0 and wantAxis ~= "x"
          if C.autoBrake and (usePitch or (damp <= 0 and brakeOk)) then
            local vT = 0
            if usePitch then vT = -C.pitchSign * K.pitchDir * C.pitchV * clamp(K.pitchT / C.pitchRamp, 0, 1) end
            local e = vlx - vT
            e = e - clamp(e, -C.brakeDb, C.brakeDb)
            if e ~= 0 or usePitch then
              lxT = clamp(C.pitchKv * e, -pMax, pMax)
              gx = C.pitchGain
            end
          end
          local gz, gzp = 1, 1
          if fReq ~= 0 and (K.keyT < C.flipHold or C.mode ~= "acro") then
            lzT = fReq * math.sin(C.bankMax * clamp(K.keyT / C.bankRamp, 0, 1))
            gz, gzp = C.bankGain, C.bankKp
          elseif C.autoBrake and fReq == 0 and damp <= 0 and brakeOk then
            local e = vlz
            e = e - clamp(e, -C.brakeDb, C.brakeDb)
            if e ~= 0 then
              lzT = clamp(C.pitchKv * e, -pMax, pMax)
              gz, gzp = C.pitchGain, C.pitchGain
            end
          end
          local ez = lz - lzT
          local ex = lx - lxT

          if not grounded then
            itx = clamp(itx + ex * dt * C.kIt, -C.itMax, C.itMax)
            itz = clamp(itz + ez * dt * C.kItz, -C.itMaxZ, C.itMaxZ)
          end

          cx = gx * (C.kTx * ex + C.kDx * dlx) + itx
          cz = gzp * C.kTz * ez + gz * C.kDz * (recover > 0 and C.kDzRec or 1) * dlz + itz
        end

        if grounded then
          acc = {0, 0, 0, 0}
        else
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
      end
    elseif C.idleStab and pose and vel then
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
      local vLim = 0
      if C.landBrake and hgt and vy < -0.3 then
        local aNeed, aMax = C.landNeed(hgt, vy, uy, dt)
        if not landOn and aNeed >= C.landUse * aMax then landOn = true end
        if landOn then
          base = math.min(C.hover * (1 + aNeed / C.gEff) / math.max(uy, 0.5), 1)
          brake = true
        end
        vLim = aNeed
      else
        landOn = false
      end
      vlx, vlz = horizVel(pose.orientation, {x = vel.x - K.vrx, y = vel.y, z = vel.z - K.vrz})
      local vh = math.sqrt(vlx * vlx + vlz * vlz)
      if not C.idleDamp or vy >= -C.idleVy or uy < 0.8 or (hgt and hgt < 2) then idleD = false
      elseif vh > C.idleVh then idleD = true
      elseif vh < 0.5 * C.idleVh then idleD = false end
      local lxT, lzT = 0, 0
      if idleD then
        local hov = math.max(integ, C.hover)
        local thr = hov + C.idleKv * math.max(C.idleVyT - vy, 0)
        base = math.max(base, math.min(thr / math.max(uy, 0.5), 1))
        lxT = clamp(C.kHd * vlx, -C.idleHdMax, C.idleHdMax)
        lzT = clamp(C.kHd * vlz, -C.idleHdMax, C.idleHdMax)
      end
      if hgt and hgt < C.landCapAlt and vy > -(C.landV + 0.5) and (brake or idleD) then
        base = math.min(base, C.landGroundCap * C.hover / math.max(uy, 0.5))
      end
      local onGround = hgt and hgt < 1.0
      if ((idleOn and not onGround) or brake or idleD) and uy > C.idleMinUy then
        local gB = brake and C.brakeGain or 1
        local air = hgt and hgt > 4
        local imax = brake and C.idleMaxBrake or (air and C.idleMaxAir or C.idleMax)
        local cx = clamp(gB * (C.kTx * (lx - lxT) + C.kDx * dlx), -imax, imax)
        local cz = clamp(gB * (C.kTz * (lz - lzT) + C.kDz * dlz), -imax, imax)
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
      if C.debug and (brake or idleD or idleOn) and logged < 2500 then
        logged = logged + 1
        buf[#buf + 1] = ("IDLE hgt=%.2f vy=%.2f aNeed=%.2f base=%.2f brake=%s idleD=%s out=%d,%d,%d,%d lx=%.2f lz=%.2f uy=%.2f"):format(
          hgt or -1, vy, vLim, base, tostring(brake), tostring(idleD), out[1], out[2], out[3], out[4], lx, lz, uy)
        if logged % 5 == 0 then flush() end
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
      if (tick % 5 == 0 or flip) and logged < 2500 then
        logged = logged + 1
        buf[#buf + 1] = ("%d %d %.3f %.3f %.3f %.3f %.2f %.3f %.3f %d %d %d %d %.2f %.2f %.2f %.2f %.3f %.2f %.2f %.2f %.2f %.2f %.2f %.2f"):format(
          tick, s, lx, lz, uy, vy, integ, itx, itz, out[1], out[2], out[3], out[4], dt, tv,
          flip and flip.ang or 0, dW, dRem, dU, dWP, vlx, vlz, hgt or -1, vel and vel.x or 0, vel and vel.z or 0)
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