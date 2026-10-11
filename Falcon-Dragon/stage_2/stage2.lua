-- stage 2 flight computer
-- WAIT -> BURN (steer to the station with the gimbal) -> COAST -> RELEASE (craft) -> HANDOFF (START to craft) -> DONE
local C = require("stage2_config")
local A = require("avionics")
local G = require("guidance")
local ATT, SIGN, NAV, SEP = C.attitude, C.sign, C.nav, C.separation

local function log(m)
    local f = fs.open(C.LOG, "a")
    if f then f.writeLine(("[%.1f] %s"):format(os.epoch("utc") / 1000, m)); f.close() end
    print(m)
end

local modem = peripheral.find("modem", function(_, p) return p.isWireless and p.isWireless() end)
if not modem then log("ERROR: no wireless modem"); return end
rednet.open(peripheral.getName(modem))

local okB, errB = A.initBridge()
if not okB then log("ERROR: " .. tostring(errB)); return end
A.setDryRun(C.DRY_RUN)
A.setPose(C.pose)

if not A.hasSable() then log("WARNING: sublevel API not available -- no attitude, gimbal stays neutral") end
if not SEP.PAYLOAD_SEP then log("WARNING: separation.PAYLOAD_SEP is not set -- the craft will NOT be physically released") end

-- point the stage aims at: the craft's hold point in front of the docking port
local HOLD
do
    local s = C.station
    local ax, ay, az = s.ax or 0, s.ay or 0, s.az or 1
    local l = math.sqrt(ax * ax + ay * ay + az * az)
    if l < 1e-6 then ax, ay, az, l = 0, 0, 1, 1 end
    HOLD = { x = s.x - ax / l * C.APPROACH_DISTANCE, y = s.y - ay / l * C.APPROACH_DISTANCE, z = s.z - az / l * C.APPROACH_DISTANCE }
end

local ST = {
    state = "WAIT", timer = 0,
    igniteReq = false, cutReq = false,
    payloadAcked = false,
    aborted = false,
    noAttT = 0,
    startSent = 0, startLast = -1,
    lastLog = 0,
    released = false,
}
local burn = nil
local lastVel = nil

local function setState(s, why)
    log(("STATE %s -> %s%s"):format(ST.state, s, why and (" (" .. why .. ")") or ""))
    ST.state = s
    ST.timer = 0
end

local ditherAcc = {}
local function dither(key, v)
    local acc = (ditherAcc[key] or 0) + v
    local out = math.floor(acc + 0.5)
    ditherAcc[key] = A.clamp(acc - out, -1, 1)
    return out
end

local function setEngines(level)
    for _, pair in ipairs(C.ENGINES) do A.sendLink(pair, level) end
end

-- fractional level: dithered between neighbouring integers so the average thrust is right
local function setThrust(level)
    if level <= 0 then
        ditherAcc.eng = 0
        setEngines(0)
    else
        setEngines(A.clamp(dither("eng", level), 0, 15))
    end
end

local function setGimbal(effortRight, effortFwd)
    if SIGN.AXIS_SWAP_GIMBAL then effortRight, effortFwd = effortFwd, -effortRight end
    local lim = ATT.OUTPUT_LIMIT
    local r = dither("r", A.clamp(effortRight * SIGN.STEER_RIGHT, -lim, lim))
    local f = dither("f", A.clamp(effortFwd * SIGN.STEER_FWD, -lim, lim))
    A.sendLink(C.GIMBAL.east,  (r < 0) and -r or 0)
    A.sendLink(C.GIMBAL.west,  (r > 0) and r or 0)
    A.sendLink(C.GIMBAL.north, (f < 0) and -f or 0)
    A.sendLink(C.GIMBAL.south, (f > 0) and f or 0)
end

local wRateX, wRateZ = 0, 0
local prevWLX, prevWLZ = nil, nil
local iFwd, iRight = 0, 0
local prevEffR, prevEffF = 0, 0
local lastLeanR, lastLeanF = 0, 0
local lastDesR, lastDesF = 0, 0

local function resetAttitudeState()
    wRateX, wRateZ = 0, 0
    prevWLX, prevWLZ = nil, nil
    iFwd, iRight = 0, 0
    prevEffR, prevEffF = 0, 0
    ditherAcc = {}
end

local function neutralGimbal()
    prevEffR, prevEffF = 0, 0
    setGimbal(0, 0)
end

-- same loop as before, now with a wanted lean (desFwd/desRight) instead of always 0
local function holdAttitude(att, angVel, desFwd, desRight, level, yawRateDps, rdt)
    local wlx, wlz = att.up.x, att.up.z
    if prevWLX == nil then prevWLX, prevWLZ = wlx, wlz end
    if angVel then
        local dux, duz = A.upRate(att, angVel)
        wRateX = wRateX + (dux - wRateX) * ATT.RATE_SMOOTH
        wRateZ = wRateZ + (duz - wRateZ) * ATT.RATE_SMOOTH
    else
        local rx = A.clamp((wlx - prevWLX) / rdt, -ATT.MAX_RATE_RAW, ATT.MAX_RATE_RAW)
        local rz = A.clamp((wlz - prevWLZ) / rdt, -ATT.MAX_RATE_RAW, ATT.MAX_RATE_RAW)
        wRateX = wRateX + (rx - wRateX) * ATT.RATE_SMOOTH
        wRateZ = wRateZ + (rz - wRateZ) * ATT.RATE_SMOOTH
    end
    prevWLX, prevWLZ = wlx, wlz

    local leanFwd   = wlx * att.fwd.x   + wlz * att.fwd.z
    local leanRight = wlx * att.right.x + wlz * att.right.z
    local rateFwd   = wRateX * att.fwd.x   + wRateZ * att.fwd.z
    local rateRight = wRateX * att.right.x + wRateZ * att.right.z
    local angRate = A.len2(rateRight, rateFwd)
    lastLeanR, lastLeanF = leanRight, leanFwd
    lastDesR, lastDesF = desRight, desFwd

    local leak = 1 - A.clamp(rdt / ATT.I_LEAK_TAU, 0, 0.5)
    iRight = iRight * leak
    iFwd = iFwd * leak
    local quasi = math.abs(leanRight - desRight) < ATT.I_QUASI_LEAN and math.abs(leanFwd - desFwd) < ATT.I_QUASI_LEAN
        and angRate < ATT.I_QUASI_RATE
    if quasi and math.abs(yawRateDps) < ATT.I_QUASI_YAW_DPS then
        iRight = A.clamp(iRight + (desRight - leanRight) * rdt, -ATT.I_LIMIT, ATT.I_LIMIT)
        iFwd   = A.clamp(iFwd   + (desFwd   - leanFwd)   * rdt, -ATT.I_LIMIT, ATT.I_LIMIT)
    end

    local scale = ATT.TORQUE_SCALE * A.clamp(ATT.TORQUE_REF_LEVEL / math.max(level, ATT.TORQUE_IDLE_LEVEL),
        ATT.TORQUE_SCALE_MIN, ATT.TORQUE_SCALE_MAX)
    local gainFrac = A.clamp((att.tiltDeg - ATT.GAIN_TILT_START) / (ATT.GAIN_TILT_FULL - ATT.GAIN_TILT_START), 0, 1)
    local gainMult = 1 + ATT.GAIN_MULT_EXTRA * gainFrac
    local spinLock = math.abs(yawRateDps) > ATT.SPIN_LOCK_DPS
    local kd = spinLock and ATT.TILT_KD * ATT.SPIN_KD_MULT or ATT.TILT_KD
    local pR = spinLock and 0 or (desRight - leanRight - rateRight * rdt * ATT.RATE_LEAD)
    local pF = spinLock and 0 or (desFwd   - leanFwd   - rateFwd   * rdt * ATT.RATE_LEAD)
    local iR = spinLock and 0 or iRight
    local iF = spinLock and 0 or iFwd

    local lim = ATT.OUTPUT_LIMIT
    local rawR = A.clamp(scale * (ATT.TILT_KP * gainMult * pR - kd * gainMult * rateRight + ATT.TILT_KI * iR), -lim, lim)
    local rawF = A.clamp(scale * (ATT.TILT_KP * gainMult * pF - kd * gainMult * rateFwd   + ATT.TILT_KI * iF), -lim, lim)

    local maxStep = ATT.EFFORT_SLEW_RATE * rdt
    prevEffR = prevEffR + A.clamp(rawR - prevEffR, -maxStep, maxStep)
    prevEffF = prevEffF + A.clamp(rawF - prevEffF, -maxStep, maxStep)
    setGimbal(prevEffR, prevEffF)
end

-- payload release
local function holdPayload()
    if not SEP.PAYLOAD_SEP then return end
    -- release: held at 15 until separation. pulse: kept at 0 (explicitly, so a stale 15 can never separate it early)
    A.sendLink(SEP.PAYLOAD_SEP, SEP.MODE == "release" and 15 or 0)
end
local function releasePayload()
    if ST.released then return end
    ST.released = true
    if not SEP.PAYLOAD_SEP then return end
    if SEP.MODE == "pulse" then
        A.sendLink(SEP.PAYLOAD_SEP, 15); pcall(A.flush)
        os.sleep(SEP.PULSE_TIME)
        A.sendLink(SEP.PAYLOAD_SEP, 0)
    else
        A.sendLink(SEP.PAYLOAD_SEP, 0)
    end
    pcall(A.flush)
end

local function sendStart()
    local msg = { cmd = "START", t = os.epoch("utc"), target = C.station, aborted = ST.aborted }
    return pcall(function()
        if SEP.PAYLOAD_ID then rednet.send(SEP.PAYLOAD_ID, msg, C.PAYLOAD_PROTOCOL)
        else rednet.broadcast(msg, C.PAYLOAD_PROTOCOL) end
    end)
end

local function abort(reason)
    setThrust(0)
    neutralGimbal()
    ST.aborted = true
    log("HARD ABORT -- " .. reason)
    if SEP.ABORT_RELEASE then
        setState("ABORT", reason)
    else
        setState("DONE", "abort, no release")
    end
end

local function commsLoop()
    while true do
        local id, msg, proto = rednet.receive()
        if type(msg) == "table" then
            if proto == C.PROTOCOL and (not C.STAGE1_ID or id == C.STAGE1_ID) then
                if msg.cmd == "IGNITE" then
                    if ST.state == "WAIT" and not ST.igniteReq then
                        ST.igniteReq = true
                        log("IGNITE from #" .. id)
                    end
                    rednet.send(id, { cmd = "ACK", t = os.epoch("utc") }, C.PROTOCOL)
                elseif msg.cmd == "CUTOFF" then
                    ST.cutReq = true
                    rednet.send(id, { cmd = "ACK", t = os.epoch("utc") }, C.PROTOCOL)
                end
            elseif proto == C.PAYLOAD_PROTOCOL and msg.cmd == "ACK" then
                ST.payloadAcked = true
            end
        end
    end
end

local function tick(rdt)
    ST.timer = ST.timer + rdt
    local att = A.readAttitude()
    local vel = A.readVelocity()
    if vel then lastVel = vel end
    local nowS = os.epoch("utc") / 1000
    local doLog = nowS - ST.lastLog >= C.LOG_INTERVAL
    if doLog then ST.lastLog = nowS end

    if ST.state == "WAIT" then
        setThrust(0); neutralGimbal()
        if ST.igniteReq then
            resetAttitudeState()
            burn = G.newBurn(NAV, HOLD)
            setState("BURN", ("hold=(%.0f,%.0f,%.0f)"):format(HOLD.x, HOLD.y, HOLD.z))
        end

    elseif ST.state == "BURN" then
        if ST.cutReq then
            setThrust(0); neutralGimbal()
            setState("DONE", "CUTOFF from stage 1")
            return
        end
        if not (att and att.pos and att.pos.y and vel) then
            neutralGimbal()
            ST.noAttT = ST.noAttT + rdt
            if ST.noAttT >= NAV.NOATT_CUT_TIME then
                setThrust(0)
                setState("COAST", "no attitude/velocity data, engine off")
            end
            return
        end
        ST.noAttT = 0

        if att.tiltDeg > NAV.HARD_ABORT_TILT_DEG then abort(("tilt=%.1f"):format(att.tiltDeg)); return end
        local angVel = A.readAngularVelocityWorld(att)
        local yawRateDps = math.deg(A.yawRate(att, angVel))
        if math.abs(yawRateDps) > NAV.HARD_ABORT_YAW_RATE_DPS then abort(("yawRate=%.1f"):format(yawRateDps)); return end

        local cmd = burn:step(att.pos, vel, att.up, rdt)
        local desFwd   = cmd.lx * att.fwd.x   + cmd.lz * att.fwd.z
        local desRight = cmd.lx * att.right.x + cmd.lz * att.right.z
        holdAttitude(att, angVel, desFwd, desRight, cmd.level, yawRateDps, rdt)
        setThrust(cmd.level)

        if doLog then
            log(("burn t=%.0f alt=%.0f range=%.0f va=%.1f lat=%.1f v=(%.1f,%.1f,%.1f) tilt=%.1f lean=(%+.2f,%+.2f) des=(%+.2f,%+.2f) eff=(%+.1f,%+.1f) lvl=%.1f tEst=%.2f yaw=%.1f"):format(
                ST.timer, cmd.alt, cmd.range, cmd.va, cmd.lat, vel.x, vel.y, vel.z, att.tiltDeg,
                lastLeanR, lastLeanF, lastDesR, lastDesF, prevEffR, prevEffF, cmd.level, cmd.tEst, yawRateDps))
        end

        if cmd.cutoff then
            setThrust(0); neutralGimbal()
            local sp = math.sqrt(vel.x ^ 2 + vel.y ^ 2 + vel.z ^ 2)
            local cosA = (vel.x * cmd.ux + vel.y * cmd.uy + vel.z * cmd.uz) / math.max(sp, 1e-6)
            setState("COAST", ("CUTOFF alt=%.0f speed=%.1f dir_err=%.1fdeg range=%.0f tEst=%.2f"):format(
                cmd.alt, sp, math.deg(math.acos(A.clamp(cosA, -1, 1))), cmd.range, cmd.tEst))
        elseif ST.timer >= NAV.BURN_HARD_TIME then
            abort("burn time > BURN_HARD_TIME")
        elseif ST.timer >= NAV.BURN_MAX_TIME and cmd.alt >= NAV.MIN_CUTOFF_ALT then
            setThrust(0); neutralGimbal()
            setState("COAST", ("BURN_MAX_TIME alt=%.0f va=%.1f lat=%.1f range=%.0f"):format(cmd.alt, cmd.va, cmd.lat, cmd.range))
        end

    elseif ST.state == "COAST" then
        setThrust(0); neutralGimbal()
        if ST.cutReq then setState("DONE", "CUTOFF from stage 1"); return end
        local pos = att and att.pos
        if not (pos and pos.y and lastVel) then
            if ST.timer >= SEP.COAST_MAX_TIME then setState("RELEASE", "coast timeout, no data") end
            return
        end
        local dx, dy, dz = HOLD.x - pos.x, HOLD.y - pos.y, HOLD.z - pos.z
        local range = math.max(math.sqrt(dx * dx + dy * dy + dz * dz), 1)
        local speed = math.sqrt(lastVel.x ^ 2 + lastVel.y ^ 2 + lastVel.z ^ 2)
        local radial = (lastVel.x * dx + lastVel.y * dy + lastVel.z * dz) / range
        local rSep = G.sepRange(speed, SEP)
        if doLog then
            log(("coast t=%.0f alt=%.0f range=%.0f sep_at=%.0f speed=%.1f closing=%.1f"):format(
                ST.timer, pos.y - NAV.PAD_Y, range, rSep, speed, radial))
        end
        if range <= rSep then
            setState("RELEASE", ("range %.0f <= %.0f"):format(range, rSep))
        elseif radial <= 0.5 and ST.timer > 5 then
            setState("RELEASE", ("not closing (%.1f m/s), range %.0f"):format(radial, range))
        elseif ST.timer >= SEP.COAST_MAX_TIME then
            setState("RELEASE", "coast timeout")
        end

    elseif ST.state == "ABORT" then
        setThrust(0); neutralGimbal()
        if ST.timer >= SEP.ABORT_RELEASE_DELAY then setState("RELEASE", "abort release") end

    elseif ST.state == "RELEASE" then
        setThrust(0); neutralGimbal()
        if not ST.released then
            releasePayload()
            log("PAYLOAD RELEASED" .. (SEP.PAYLOAD_SEP and "" or " (no PAYLOAD_SEP configured, nothing physical happened)"))
            ST.timer = 0
        end
        if ST.timer >= SEP.SETTLE_TIME then setState("HANDOFF") end

    elseif ST.state == "HANDOFF" then
        setThrust(0); neutralGimbal()
        if ST.payloadAcked then
            log(("CRAFT ACK after %d START msgs -- stage 2 done"):format(ST.startSent))
            setState("DONE", "handed off")
        elseif ST.timer >= SEP.START_TIMEOUT then
            log("WARNING: no ACK from craft, giving up (is its computer on, wireless modem, f9_payload?)")
            setState("DONE", "no ack")
        elseif ST.startSent == 0 or ST.timer - ST.startLast >= SEP.START_PERIOD then
            sendStart()
            ST.startSent = ST.startSent + 1
            ST.startLast = ST.timer
        end

    else -- DONE
        setThrust(0); neutralGimbal()
    end
end

local function controlLoop()
    local lastMs = os.epoch("utc")
    while true do
        local nowMs = os.epoch("utc")
        local rdt = A.clamp((nowMs - lastMs) / 1000, 0.01, 1.0)
        lastMs = nowMs

        local ok, err = pcall(tick, rdt)
        if not ok then log("ERROR: " .. tostring(err)) end

        local okF, errF = pcall(A.flush)
        if not okF then log("FLUSH ERROR: " .. tostring(errF)) end

        os.sleep(C.LOOP_PERIOD)
    end
end

setEngines(0)
neutralGimbal()
holdPayload()
pcall(A.flush)
log(("stage 2 online, waiting for IGNITE (dry=%s) station=(%.0f,%.0f,%.0f) hold=(%.0f,%.0f,%.0f)"):format(
    tostring(C.DRY_RUN), C.station.x, C.station.y, C.station.z, HOLD.x, HOLD.y, HOLD.z))

parallel.waitForAny(commsLoop, controlLoop)