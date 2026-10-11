local function crashRecord(msg)
    local f = fs.open("launch_crash.log", "w")
    if f then
        f.writeLine(msg)
        f.close()
    end
end

local ok, A = pcall(require, "avionics")
if not ok then
    crashRecord("require avionics failed: " .. tostring(A))
    error(A, 0)
end

local bridgeOk, bridgeErr
for attempt = 1, 3 do
    bridgeOk, bridgeErr = A.initBridge()
    if bridgeOk then break end
    print(("bridge init attempt %d/3 failed: %s"):format(attempt, tostring(bridgeErr)))
end
if not bridgeOk then
    crashRecord("bridge init failed: " .. tostring(bridgeErr))
    error(bridgeErr, 0)
end

local C = require("launch_config")
A.setDryRun(C.flight.DRY_RUN)
A.setPose(C.pose)

local ATT, SIGN, TH, AS, NAV = C.attitude, C.sign, C.thrust, C.ascent, C.nav
local RC = C.rcs

local LOG_PATH = "/" .. C.log.FILE:gsub("^/", "")
local logFile = require("runlog").open(LOG_PATH)
local logDiskOk = (logFile ~= nil)
local logLineCount = 0

local function logLine(s, forceFlush)
    print(s)
    if not logDiskOk then return end
    local okW, err = pcall(function()
        logFile.writeLine(s)
        logLineCount = logLineCount + 1
        if forceFlush or logLineCount % 5 == 0 then logFile.flush() end
    end)
    if not okW then
        logDiskOk = false
        pcall(function() logFile.close() end)
        print("log write failed: " .. tostring(err))
    end
end

local telemetry = A.newTelemetry(C.telemetry)
local gforceTracker = A.newGForceTracker(C.flight.GRAVITY)

-- stage 2 is a separate computer: it is lit by a wireless (rednet) message, not a redstone link
local S2 = C.stage2
local s2Modem = nil
do
    local okM, m = pcall(peripheral.find, "modem", function(_, p) return p.isWireless and p.isWireless() end)
    if okM and m then
        s2Modem = peripheral.getName(m)
        rednet.open(s2Modem)
    else
        logLine("WARNING: no wireless modem on stage 1 -- stage 2 will NOT be ignited", true)
    end
end

local function sendStage2(cmd)
    if not s2Modem then return false end
    local msg = { cmd = cmd, t = os.epoch("utc") }
    return pcall(function()
        if S2.COMPUTER_ID then rednet.send(S2.COMPUTER_ID, msg, S2.PROTOCOL)
        else rednet.broadcast(msg, S2.PROTOCOL) end
    end)
end

local ST = {
    state = "LOCKED_WAIT",
    stateTimer = 0,
    rdt = C.flight.LOOP_PERIOD,
    lastAlt = 0,
    lastSpeedKmh = 0,
    poseSettled = false,
    poseSettleTimer = 0,
    clampReleased = false,
    tiltGateLatched = false,
    triggerPollTimer = 0,
    launchUx = 0,
    launchUz = 0,
    lastDesFwd = 0,
    lastDesRight = 0,
    lastLeanFwd = 0,
    lastLeanRight = 0,
    lastTb = 0,
    navLx = 0,
    navLz = 0,
    mecoLevel = 0,
    currentLevel = 0,
    coastFrozen = 0,
    coastBadLogged = false,
    s2Sent = 0,
    s2LastSend = -1,
    s2Acked = false,
    separated = false,
    usedLevelSec = 0,
    thrEst = 0,
    prevEffR = 0,
    prevEffF = 0,
}

local ENGINES = C.link.ENGINES
local engineLevel = {}
for _, name in ipairs(ENGINES) do engineLevel[name] = 0 end

local EXTRA_PAIRS = {
    { "north", "south" }, { "east", "west" },
    { "northeast", "southwest" }, { "northwest", "southeast" },
}
-- fractional level: the extra +1 goes to the centre / opposite pairs, so thrust stays symmetric
local function setThrottleAll(level)
    level = A.clamp(level, 0, 15)
    local base = math.floor(level)
    local extra = A.round((level - base) * 9)
    if extra >= 9 then base = base + 1; extra = 0 end
    local plus = {}
    if extra % 2 == 1 then plus.centre = true end
    for i = 1, math.floor(extra / 2) do
        plus[EXTRA_PAIRS[i][1]] = true
        plus[EXTRA_PAIRS[i][2]] = true
    end
    ST.currentLevel = level
    for _, name in ipairs(ENGINES) do
        local s = A.clamp(base + (plus[name] and 1 or 0), 0, 15)
        engineLevel[name] = s
        A.sendLink(C.link["gas_" .. name], s)
    end
end

local ditherAcc = {}
local function dither(key, v)
    local acc = (ditherAcc[key] or 0) + v
    local out = math.floor(acc + 0.5)
    ditherAcc[key] = A.clamp(acc - out, -1, 1)
    return out
end

local function setGimbal(effortRight, effortFwd)
    if SIGN.AXIS_SWAP_GIMBAL then effortRight, effortFwd = effortFwd, -effortRight end
    local lim = ATT.OUTPUT_LIMIT
    local r = dither("r", A.clamp(effortRight * SIGN.STEER_RIGHT, -lim, lim))
    local f = dither("f", A.clamp(effortFwd * SIGN.STEER_FWD, -lim, lim))
    A.sendLink(C.link.gimbal_to_east,  (r < 0) and -r or 0)
    A.sendLink(C.link.gimbal_to_west,  (r > 0) and r or 0)
    A.sendLink(C.link.gimbal_to_north, (f < 0) and -f or 0)
    A.sendLink(C.link.gimbal_to_south, (f > 0) and f or 0)
end

local prevRcsR, prevRcsF = 0, 0

local function setRCS(effortRight, effortFwd)
    if not RC.ENABLE then return end
    if math.abs(effortRight) < RC.DEADZONE then effortRight = 0 end
    if math.abs(effortFwd) < RC.DEADZONE then effortFwd = 0 end
    local lim = RC.LIMIT
    local r = dither("rcs_r", A.clamp(effortRight * SIGN.STEER_RIGHT, -lim, lim))
    local f = dither("rcs_f", A.clamp(effortFwd * SIGN.STEER_FWD, -lim, lim))
    A.sendLink(C.link.rcs_to_east,  (r < 0) and -r or 0)
    A.sendLink(C.link.rcs_to_west,  (r > 0) and r or 0)
    A.sendLink(C.link.rcs_to_north, (f < 0) and -f or 0)
    A.sendLink(C.link.rcs_to_south, (f > 0) and f or 0)
end

local function neutralRCS()
    prevRcsR, prevRcsF = 0, 0
    setRCS(0, 0)
end

local function neutralGimbal()
    setGimbal(0, 0)
    neutralRCS()
end

local function engageClamp() A.sendLink(C.link.clamp, 15) end
local function releaseClamp() A.sendLink(C.link.clamp, 0) end
-- stage_sep is held (15) from start, released to separate
local function holdStageSep() A.sendLink(C.link.stage_sep, 15) end
local function releaseStageSep() A.sendLink(C.link.stage_sep, 0) end
local function setDeluge(on) A.sendLink(C.link.deluge, on and 15 or 0) end
local function setGyro(on) A.sendLink(C.link.gyro, on and 15 or 0) end

local function pulseLink(pair)
    A.sendLink(pair, 15)
    A.flush()
    os.sleep(AS.STAGE_SEP_PULSE_TIME)
    A.sendLink(pair, 0)
    A.flush()
end

local function gravityAt(alt)
    local T = NAV.GRAVITY_TABLE
    if alt <= T[1][1] then return T[1][2] end
    for i = 2, #T do
        local a, b = T[i-1], T[i]
        if alt <= b[1] then return a[2] + (b[2] - a[2]) * (alt - a[1]) / (b[1] - a[1]) end
    end
    return 0
end

local function predictApogee(alt, vs)
    if vs <= 0 then return alt end
    local h, v, step = alt, vs, 0.5
    for _ = 1, 600 do
        v = v - gravityAt(h) * step
        if v <= 0 then return h end
        h = h + v * step
    end
    return h + 1e6
end

local function burnPlan(alt, vs)
    local v = math.max(vs, AS.NAV_TGO_VS_MIN)
    local h = alt
    for _ = 1, 120 do
        if predictApogee(h, v) >= AS.SEP_ALT then break end
        h = h + 50
    end
    return math.max((h - alt) / v, AS.NAV_TB_MIN), h, v
end

local function coastTime(h, v)
    local t = 0
    for _ = 1, 240 do
        v = v - gravityAt(h) * 0.5
        if v <= AS.COAST_SEP_VS then break end
        h = h + v * 0.5
        t = t + 0.5
        if h >= AS.SEP_ALT_MAX then break end
    end
    return math.min(t, AS.COAST_MAX_TIME)
end

local dt = C.flight.LOOP_PERIOD

local wRateX, wRateZ = 0, 0
local prevWLX, prevWLZ = nil, nil
local iFwd, iRight = 0, 0
local vsI = 0
local heldAscent = C.thrust.LIFTOFF_LEVEL

local function resetAttitudeState()
    iFwd, iRight = 0, 0
    ST.prevEffR, ST.prevEffF = 0, 0
    prevRcsR, prevRcsF = 0, 0
    wRateX, wRateZ = 0, 0
    prevWLX, prevWLZ = nil, nil
    vsI = 0
    heldAscent = TH.LIFTOFF_LEVEL
    ST.navLx, ST.navLz = 0, 0
end

local function torqueScale(level)
    local t = math.max(level, ATT.TORQUE_IDLE_LEVEL * 0.5)
    return A.clamp(ATT.TORQUE_REF_LEVEL / t, ATT.TORQUE_SCALE_MIN, ATT.TORQUE_SCALE_MAX)
end

local function ascentLevel(vs, upY, alt, climbed)
    local taper = A.clamp((AS.SEP_ALT - alt) / AS.TAPER_ALT, 0, 1)
    local target = AS.VS_TARGET * (AS.VS_TAPER_FRAC + (1 - AS.VS_TAPER_FRAC) * taper)
    target = math.min(target, AS.VS_START + AS.VS_SLOPE * climbed)
    local err = target - vs
    vsI = A.clamp(vsI + AS.VS_KI * err * ST.rdt, AS.VS_I_MIN, AS.VS_I_MAX)
    local base = gravityAt(alt) / AS.T_PER_LEVEL  -- feed-forward: level that cancels gravity
    local level = (base + AS.VS_KP * err + vsI) / A.clamp(upY, 0.5, 1)
    level = A.clamp(level, AS.LEVEL_MIN, AS.LEVEL_MAX)
    local step = AS.LEVEL_SLEW * ST.rdt
    heldAscent = heldAscent + A.clamp(level - heldAscent, -step, step)
    return heldAscent
end

local function holdAttitude(att, angVel, desFwd, desRight, level, yawRateDps)
    local wlx, wlz = att.up.x, att.up.z
    if prevWLX == nil then prevWLX, prevWLZ = wlx, wlz end
    if angVel then
        local dux, duz = A.upRate(att, angVel)
        wRateX = wRateX + (dux - wRateX) * ATT.RATE_SMOOTH
        wRateZ = wRateZ + (duz - wRateZ) * ATT.RATE_SMOOTH
    else
        local rx = A.clamp((wlx - prevWLX) / ST.rdt, -ATT.MAX_RATE_RAW, ATT.MAX_RATE_RAW)
        local rz = A.clamp((wlz - prevWLZ) / ST.rdt, -ATT.MAX_RATE_RAW, ATT.MAX_RATE_RAW)
        wRateX = wRateX + (rx - wRateX) * ATT.RATE_SMOOTH
        wRateZ = wRateZ + (rz - wRateZ) * ATT.RATE_SMOOTH
    end
    prevWLX, prevWLZ = wlx, wlz

    local leanFwd   = wlx * att.fwd.x   + wlz * att.fwd.z
    local leanRight = wlx * att.right.x + wlz * att.right.z
    local rateFwd   = wRateX * att.fwd.x   + wRateZ * att.fwd.z
    local rateRight = wRateX * att.right.x + wRateZ * att.right.z
    local angRate = A.len2(rateRight, rateFwd)
    ST.lastLeanFwd, ST.lastLeanRight = leanFwd, leanRight

    local leak = 1 - A.clamp(ST.rdt / ATT.I_LEAK_TAU, 0, 0.5)
    iRight = iRight * leak
    iFwd = iFwd * leak
    local quasi = math.abs(leanRight) < ATT.I_QUASI_LEAN and math.abs(leanFwd) < ATT.I_QUASI_LEAN
        and angRate < ATT.I_QUASI_RATE
    if quasi and math.abs(yawRateDps) < ATT.I_QUASI_YAW_DPS and level >= ATT.I_MIN_LEVEL then
        iRight = A.clamp(iRight + (desRight - leanRight) * ST.rdt, -ATT.I_LIMIT, ATT.I_LIMIT)
        iFwd   = A.clamp(iFwd   + (desFwd   - leanFwd)   * ST.rdt, -ATT.I_LIMIT, ATT.I_LIMIT)
    end

    local scale = torqueScale(level)
    local gainFrac = A.clamp((att.tiltDeg - ATT.GAIN_TILT_START) / (ATT.GAIN_TILT_FULL - ATT.GAIN_TILT_START), 0, 1)
    local gainMult = 1 + ATT.GAIN_MULT_EXTRA * gainFrac
    local spinLock = math.abs(yawRateDps) > ATT.SPIN_LOCK_DPS
    local kd = spinLock and ATT.TILT_KD * ATT.SPIN_KD_MULT or ATT.TILT_KD
    local pR = spinLock and 0 or (desRight - leanRight - rateRight * ST.rdt * ATT.RATE_LEAD)
    local pF = spinLock and 0 or (desFwd - leanFwd - rateFwd * ST.rdt * ATT.RATE_LEAD)
    local iR = spinLock and 0 or iRight
    local iF = spinLock and 0 or iFwd

    local lim = ATT.OUTPUT_LIMIT
    local rawR = A.clamp(scale * (ATT.TILT_KP * gainMult * pR - kd * gainMult * rateRight + ATT.TILT_KI * iR), -lim, lim)
    local rawF = A.clamp(scale * (ATT.TILT_KP * gainMult * pF - kd * gainMult * rateFwd   + ATT.TILT_KI * iF), -lim, lim)

    local maxStep = ATT.EFFORT_SLEW_RATE * ST.rdt
    ST.prevEffR = ST.prevEffR + A.clamp(rawR - ST.prevEffR, -maxStep, maxStep)
    ST.prevEffF = ST.prevEffF + A.clamp(rawF - ST.prevEffF, -maxStep, maxStep)
    setGimbal(ST.prevEffR, ST.prevEffF)

    if RC.ENABLE then
        local rlim = RC.LIMIT
        local qR = spinLock and 0 or (desRight - leanRight)
        local qF = spinLock and 0 or (desFwd - leanFwd)
        local rkd = RC.KD * (spinLock and ATT.SPIN_KD_MULT or 1)
        local rawRcsR = A.clamp(RC.KP * gainMult * qR - rkd * gainMult * rateRight, -rlim, rlim)
        local rawRcsF = A.clamp(RC.KP * gainMult * qF - rkd * gainMult * rateFwd, -rlim, rlim)
        local rStep = RC.SLEW_RATE * ST.rdt
        prevRcsR = prevRcsR + A.clamp(rawRcsR - prevRcsR, -rStep, rStep)
        prevRcsF = prevRcsF + A.clamp(rawRcsF - prevRcsF, -rStep, rStep)
        setRCS(prevRcsR, prevRcsF)
    end

    setThrottleAll(level)
end

local function telemetryPayload()
    local lit = C.telemetry.LIT_THRESHOLD
    local e = {}
    for i, name in ipairs(ENGINES) do e[i] = engineLevel[name] > lit end
    return { engines = e, gforce = gforceTracker.smoothed, altitude = ST.lastAlt, speed = ST.lastSpeedKmh }
end

local function abort(reason)
    setThrottleAll(0)
    neutralGimbal()
    setDeluge(false)
    setGyro(false)
    pcall(A.flush)
    logLine("HARD ABORT -- " .. reason, true)
    ST.state = "DONE"
end

engageClamp()
holdStageSep()
neutralGimbal()
setThrottleAll(0)
setGyro(false)
pcall(A.flush)

logLine(("START falcon9-launch rev=rev64-early-turn dry=%s"):format(tostring(C.flight.DRY_RUN)))

local function tick()
    local att = A.readAttitude()
    if not att or not att.posY then
        neutralGimbal()
        setThrottleAll(0)
        os.sleep(0.2)
        return
    end

    local nowMs = os.epoch("utc")
    if ST.lastTickMs then ST.rdt = A.clamp((nowMs - ST.lastTickMs) / 1000, 0.01, 1.0) end
    ST.lastTickMs = nowMs

    local vel = A.readVelocity()
    gforceTracker:update(vel, ST.rdt)
    local alt = att.posY - NAV.TARGET.y
    ST.lastAlt = alt
    ST.lastSpeedKmh = vel and (math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z) * 3.6) or 0
    local vs = vel and vel.y or 0
    local velOk = vel ~= nil

    if not ST.poseSettled then
        ST.poseSettleTimer = ST.poseSettleTimer + ST.rdt
        if ST.poseSettleTimer < 0.5 then
            neutralGimbal()
            setThrottleAll(0)
            return
        end
        ST.poseSettled = true
        logLine(("pose settled y=%.1f alt=%.1f"):format(att.posY, alt))
    end

    local angVel = A.readAngularVelocityWorld(att)
    local yawRateDps = math.deg(A.yawRate(att, angVel))
    local live = ST.state ~= "DONE" and ST.state ~= "LOCKED_WAIT" and ST.state ~= "COAST" and ST.state ~= "SEPARATING"

    if live and att.tiltDeg > AS.HARD_ABORT_TILT_DEG then
        abort(("tilt=%.1f > %.1f"):format(att.tiltDeg, AS.HARD_ABORT_TILT_DEG))
        return
    end
    if live and math.abs(yawRateDps) > AS.HARD_ABORT_YAW_RATE_DPS then
        abort(("yawRate=%.1f > %.1f"):format(yawRateDps, AS.HARD_ABORT_YAW_RATE_DPS))
        return
    end

    setGyro(ST.state == "IGNITION" or ST.state == "VERTICAL_ASCENT")
    ST.stateTimer = ST.stateTimer + ST.rdt

    local dx = NAV.TARGET.x - (att.pos.x or NAV.TARGET.x)
    local dz = NAV.TARGET.z - (att.pos.z or NAV.TARGET.z)
    local dist = A.len2(dx, dz)

    if ST.state == "LOCKED_WAIT" then
        engageClamp()
        neutralGimbal()
        setThrottleAll(0)
        ST.triggerPollTimer = ST.triggerPollTimer + ST.rdt
        if A.getLink(C.link.launch_trigger) >= 1 then
            logLine("LAUNCH TRIGGER RECEIVED")
            setDeluge(true)
            ST.state = "DELUGE_LEAD"
            ST.stateTimer = 0
        elseif ST.triggerPollTimer >= 5.0 then
            ST.triggerPollTimer = 0
            logLine("waiting for launch trigger...")
        end

    elseif ST.state == "DELUGE_LEAD" then
        engageClamp()
        neutralGimbal()
        setThrottleAll(0)
        if ST.stateTimer >= AS.DELUGE_LEAD_TIME then
            pulseLink(C.link.liftoff_effect)
            ST.lastTickMs = os.epoch("utc")
            logLine("DELUGE_LEAD -> IGNITION")
            ST.state = "IGNITION"
            ST.stateTimer = 0
            ST.clampReleased = false
            ST.tiltGateLatched = false
            resetAttitudeState()
        end

    elseif ST.state == "IGNITION" then
        local frac = A.clamp(ST.stateTimer / AS.IGNITION_RAMP_TIME, 0, 1)
        if not ST.clampReleased then engageClamp() end
        holdAttitude(att, angVel, 0, 0, TH.LIFTOFF_LEVEL * frac, yawRateDps)
        if not ST.clampReleased and frac >= AS.CLAMP_RELEASE_FRAC then
            releaseClamp()
            ST.clampReleased = true
            logLine(("CLAMP RELEASED frac=%.2f y=%.1f tilt=%.1f"):format(frac, att.posY, att.tiltDeg))
        end
        if ST.stateTimer >= AS.IGNITION_RAMP_TIME then
            if not ST.clampReleased then
                releaseClamp()
                ST.clampReleased = true
            end
            ST.liftoffY = att.posY
            do
                local ldx = NAV.TARGET.x - (att.pos.x or NAV.TARGET.x)
                local ldz = NAV.TARGET.z - (att.pos.z or NAV.TARGET.z)
                local ll = A.len2(ldx, ldz)
                if ll > 1 then ST.launchUx, ST.launchUz = ldx / ll, ldz / ll end
            end
            logLine(("LIFTOFF y=%.1f alt=%.1f tilt=%.1f"):format(att.posY, alt, att.tiltDeg))
            ST.state = "VERTICAL_ASCENT"
            ST.stateTimer = 0
        end

    elseif ST.state == "VERTICAL_ASCENT" then
        local climbed = att.posY - (ST.liftoffY or att.posY)
        local nearPad = climbed < AS.CLEAR_TOWER_ALT
        if att.tiltDeg >= AS.TILT_ABORT_DEG then
            ST.tiltGateLatched = true
        elseif att.tiltDeg < AS.TILT_ABORT_DEG - AS.TILT_RECOVER_MARGIN then
            ST.tiltGateLatched = false
        end
        local level = (nearPad or ST.tiltGateLatched) and TH.LIFTOFF_LEVEL or ascentLevel(vs, att.up.y, alt, climbed)
        setDeluge(nearPad)
        holdAttitude(att, angVel, 0, 0, level, yawRateDps)
        ST.lastDesFwd, ST.lastDesRight = 0, 0
        if climbed >= AS.VERT_CLIMB_ALT then
            logLine(("VERTICAL_ASCENT -> GRAVITY_TURN climbed=%.1f alt=%.1f"):format(climbed, alt))
            ST.state = "GRAVITY_TURN"
            ST.stateTimer = 0
        end

    elseif ST.state == "GRAVITY_TURN" then
        local climbed = att.posY - (ST.liftoffY or att.posY)
        local desFwd, desRight = 0, 0
        local recovering = att.tiltDeg >= AS.TILT_ABORT_DEG
        local lx, lz = 0, 0
        if not recovering and dist > 1 then
            local vx = vel and vel.x or 0
            local vz = vel and vel.z or 0
            local ux, uz = dx / dist, dz / dist
            local Tb, hMeco, vPlan = burnPlan(alt, vs)
            local Tc = coastTime(hMeco, vPlan)
            ST.lastTb = Tb
            local ddx = dx + ux * AS.NAV_AIM_BIAS
            local ddz = dz + uz * AS.NAV_AIM_BIAS
            local vfx, vfz = ux * AS.NAV_VF_END, uz * AS.NAV_VF_END
            -- zero-effort-miss guidance, replanned every tick
            local function accelCmd(d, v, vf)
                local jerk = 12 * ((v + vf) * Tb / 2 - d + vf * Tc) / (Tb * Tb * Tb)
                return (vf - v) / Tb - jerk * Tb / 2
            end
            local ax = accelCmd(ddx, vx, vfx)
            local az = accelCmd(ddz, vz, vfz)
            local geff = math.max(gravityAt(alt), AS.NAV_G_MIN)
            -- rev62: sideways accel = thrust accel * lean, so divide by the REAL thrust accel, not by g.
            -- Dividing by g made the lean 1.5-2x too big low down (thrust ~17-25 m/s2 there, g = 11).
            local teff = math.max(ST.currentLevel * AS.T_PER_LEVEL, geff)
            local ramp = A.clamp((climbed - AS.VERT_CLIMB_ALT) / AS.TURN_RAMP_ALT, 0, 1)
            local maxLean = math.sin(math.rad(AS.TURN_TILT_MAX_DEG))
            lx, lz = ax / teff * ramp, az / teff * ramp
            local m = A.len2(lx, lz)
            if m > maxLean then lx, lz = lx * maxLean / m, lz * maxLean / m end
            -- nose along velocity, otherwise it flies crabbed
            local pb = AS.PROGRADE_BLEND or 0
            if pb > 0 and vel then
                local sp = math.sqrt(vx*vx + (vel.y or 0)^2 + vz*vz)
                if sp > (AS.PROGRADE_MIN_SPEED or 25) and (vel.y or 0) > 0 then
                    local plx, plz = vx / sp, vz / sp
                    local pm = A.len2(plx, plz)
                    if pm > maxLean then plx, plz = plx * maxLean / pm, plz * maxLean / pm end
                    local w = pb * ramp
                    lx = lx + (plx - lx) * w
                    lz = lz + (plz - lz) * w
                end
            end
        end
        -- rev63: open-loop Falcon-style pitch program. No guidance on the droneship during ascent:
        -- fixed azimuth (pad -> droneship bearing), tilt grows smoothly (smoothstep), never reverses.
        -- Landing script flips, aims and lands by itself after separation.
        if AS.OPEN_LOOP_TURN and not recovering and ST.launchUx then
            local f = A.clamp((climbed - AS.VERT_CLIMB_ALT) / AS.TURN_RAMP_ALT, 0, 1)
            f = f * f * (3 - 2 * f)
            local sn = math.sin(math.rad(AS.TURN_TILT_MAX_DEG * f))
            lx, lz = ST.launchUx * sn, ST.launchUz * sn
        end
        local dlx, dlz = lx - ST.navLx, lz - ST.navLz
        local dm = A.len2(dlx, dlz)
        local nStep = AS.NAV_LEAN_SLEW * ST.rdt
        if dm > nStep and dm > 1e-9 then dlx, dlz = dlx * nStep / dm, dlz * nStep / dm end
        ST.navLx, ST.navLz = ST.navLx + dlx, ST.navLz + dlz
        desFwd   = ST.navLx * att.fwd.x   + ST.navLz * att.fwd.z
        desRight = ST.navLx * att.right.x + ST.navLz * att.right.z
        local level = ascentLevel(vs, att.up.y, alt, climbed)
        holdAttitude(att, angVel, desFwd, desRight, level, yawRateDps)
        ST.lastDesFwd, ST.lastDesRight = desFwd, desRight
        local apogee = predictApogee(alt, vs)
        if alt >= AS.SEP_ALT or apogee >= AS.SEP_ALT then
            logLine(("GRAVITY_TURN -> MECO alt=%.1f vs=%.1f apogee=%.0f dist=%.0f"):format(alt, vs, apogee, dist))
            ST.mecoLevel = ST.currentLevel
            ST.state = "MECO"
            ST.stateTimer = 0
        end

    elseif ST.state == "MECO" then
        local frac = A.clamp(1 - ST.stateTimer / AS.MECO_RAMP_TIME, 0, 1)
        holdAttitude(att, angVel, 0, 0, ST.mecoLevel * frac, yawRateDps)
        ST.lastDesFwd, ST.lastDesRight = 0, 0
        if ST.stateTimer >= AS.MECO_RAMP_TIME then
            setThrottleAll(0)
            neutralGimbal()
            setGyro(false)
            logLine(("MECO DONE alt=%.1f vs=%.1f dist=%.0f"):format(alt, vs, dist))
            ST.state = "COAST"
            ST.stateTimer = 0
        end

    elseif ST.state == "COAST" then
        -- separate right after MECO, no attitude hold
        neutralGimbal()
        neutralRCS()
        setGyro(false)
        ST.lastDesFwd, ST.lastDesRight = 0, 0
        -- sensors dead (vel nil, or pose not moving while it should be climbing) = never separate on that data
        if ST.coastLastY and math.abs(att.posY - ST.coastLastY) < 0.01 then ST.coastFrozen = ST.coastFrozen + ST.rdt else ST.coastFrozen = 0 end
        ST.coastLastY = att.posY
        local sensorBad = (not velOk) or ST.coastFrozen > 0.7
        if sensorBad then
            if not ST.coastBadLogged then logLine(("COAST: sensors dead (velOk=%s frozen=%.1fs) y=%.1f -- holding separation"):format(tostring(velOk), ST.coastFrozen, att.posY), true); ST.coastBadLogged = true end
        else
            A.flush()
            releaseStageSep()
            A.flush()
            local warn = dist > AS.SEP_RADIUS_WARN and "  WARNING: far from pad" or ""
            -- + = flew past the pad, - = short
            local along = ((att.pos.x or 0) - NAV.TARGET.x) * ST.launchUx + ((att.pos.z or 0) - NAV.TARGET.z) * ST.launchUz
            local cross = -((att.pos.x or 0) - NAV.TARGET.x) * ST.launchUz + ((att.pos.z or 0) - NAV.TARGET.z) * ST.launchUx
            logLine(("STAGE SEPARATION alt=%.1f vs=%.1f dist=%.0f pos=(%.1f,%.1f) miss_along=%+.0f miss_cross=%+.0f%s"):format(
                alt, vs, dist, att.pos.x or 0, att.pos.z or 0, along, cross, warn), true)
            -- do NOT hand off yet: the press needs time to push the stages apart
            ST.stateTimer = 0
            ST.sepY0 = att.posY
            ST.state = "SEPARATING"
        end

    elseif ST.state == "SEPARATING" then
        -- stages are still touching for a moment: no gimbal, no RCS, no thrust, nothing that pushes the stack
        neutralGimbal()
        neutralRCS()
        setGyro(false)
        local sepT = AS.SEP_SETTLE_TIME or 1.5
        local igT  = AS.STAGE2_IGNITE_DELAY or 1.0
        -- stage 2 is told to ignite only after the stages have had time to part; repeat the message (rednet is lossy)
        if s2Modem and not ST.s2Acked then
            local okR, id, msg = pcall(rednet.receive, S2.PROTOCOL, 0)
            if okR and type(msg) == "table" and msg.cmd == "ACK" then
                ST.s2Acked = true
                logLine(("STAGE2 ACK from #%s t=%.2f"):format(tostring(id), ST.stateTimer), true)
            end
        end
        if not ST.s2Acked and ST.stateTimer >= igT and (ST.s2Sent == 0 or ST.stateTimer - ST.s2LastSend >= 0.3) then
            if sendStage2("IGNITE") then
                if ST.s2Sent == 0 then logLine(("STAGE2 IGNITE sent t=%.2f alt=%.1f"):format(ST.stateTimer, alt), true) end
                ST.s2Sent = ST.s2Sent + 1
            end
            ST.s2LastSend = ST.stateTimer
        end
        -- pose must still be updating (booster moves after the press lets go); frozen = not really separated
        local alive = velOk and (math.abs(att.posY - ST.sepY0) > 0.3 or math.abs(vs) > 0.5)
        if ST.stateTimer >= sepT + 3 and not alive then
            logLine(("SEPARATION FAILED: pose/vel frozen t=%.2f y=%.1f -- NOT handing off to landing"):format(ST.stateTimer, att.posY), true)
            ST.state = "DONE"
        elseif ST.stateTimer >= sepT and alive then
            logLine(("SEPARATION CONFIRMED (timed) t=%.2f alt=%.1f tilt=%.1f ignite_msgs=%d acked=%s"):format(ST.stateTimer, alt, att.tiltDeg, ST.s2Sent, tostring(ST.s2Acked)), true)
            ST.separated = true
            ST.state = "DONE"
        end
    end

    if ST.state ~= "LOCKED_WAIT" then
        if ST.state ~= "DONE" then ST.usedLevelSec = ST.usedLevelSec + ST.currentLevel * ST.rdt end
        if ST.prevVsLog and ST.currentLevel >= 1 then
            local acc = (vs - ST.prevVsLog) / ST.rdt
            local est = (acc + gravityAt(alt)) / math.max(att.up.y, 0.3) / ST.currentLevel
            ST.thrEst = ST.thrEst + (est - ST.thrEst) * 0.3
        end
        ST.prevVsLog = vs
        local vH = vel and A.len2(vel.x, vel.z) or 0
        local climbed = ST.liftoffY and (att.posY - ST.liftoffY) or 0
        logLine(("t=%.1f %s alt=%.0f up=%.0f dist=%.0f vs=%.1f vH=%.1f tilt=%.1f yaw=%.1f lean=(%.2f,%.2f) des=(%.2f,%.2f) eff=(%.1f,%.1f) thr=%.2f dt=%.3f y=%.0f used=%.1f TperL=%.2f Tb=%.0f"):format(
            ST.stateTimer, ST.state, alt, climbed, dist, vs, vH, att.tiltDeg, yawRateDps,
            ST.lastLeanFwd, ST.lastLeanRight, ST.lastDesFwd, ST.lastDesRight, ST.prevEffF, ST.prevEffR, ST.currentLevel, ST.rdt, att.posY, ST.usedLevelSec, ST.thrEst, ST.lastTb))
    end
end

while ST.state ~= "DONE" do
    local okT, err = pcall(tick)
    if not okT then
        local line = "[LAUNCH] ERROR: " .. tostring(err)
        logLine(line, true)
        pcall(neutralGimbal)
    end
    local okF, ferr = pcall(A.flush)
    if not okF then logLine("[LAUNCH] FLUSH ERROR: " .. tostring(ferr), true) end
    pcall(function() telemetry:send(ST.rdt, telemetryPayload, logLine) end)
    os.sleep(dt)
end

if ST.separated then
    logLine("launch.lua done -- handing off to landing.lua on this computer.", true)
    shell.run("landing.lua")
else
    logLine("launch.lua done -- no separation (abort), landing.lua NOT started.", true)
end