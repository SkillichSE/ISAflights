-- docking autopilot
-- ship axes: x right, y up (main engine pushes this way), z nose

local config = require("config")
local thrusters = require("thrusters")
local flightlog = require("flightlog")

local AUTOPILOT_CHANNEL = 52
local AUTOPILOT_REPLY_CHANNEL = 53
local PANEL_CHANNEL = 51
local modem = peripheral.find("modem")
local report_tick = 0
local autopilot_paused = false
local prompt_target

if modem then pcall(modem.open, PANEL_CHANNEL) end

-- measured actuators
-- torque in deg/s2 about right/up/nose per power level, force in m/s2 along right/up/nose
local ACT = {
    torque = {
        { pos = "pitch_down", gp = 1.4, neg = "pitch_up",  gn = 1.6 },
        { pos = "roll_ccw",   gp = 7.5, neg = "roll_cw",   gn = 7.8 },
        { pos = "yaw_right",  gp = 1.3, neg = "yaw_left",  gn = 1.6 },
    },
    force = {
        { pos = "dash_left", gp = 0.15, neg = "dash_right", gn = 0.10 },
        { pos = "main",      gp = 0.47 },
        { pos = "dash_down", gp = 0.18, neg = "dash_up",    gn = 0.14 },
    },
    mainTorque = { 0.1, 0.0, 0.3 },
}

local P = {
    VMAX = 12, ABRAKE = 2.0, KV = 0.5, AMAX = 7.0, FLIP_T = 9,
    K_ATT = 0.8, KW = 1.8, WMAX = 25, SPIN_ABORT = 60, W_ALPHA = 0.8,
    ATT_ACC = { 10, 30, 10 },
    FIRE_ANGLE = 15, FIRE_RATE = 12,
    HOLD_R = 20, HOLD_V = 0.8,
    VFLOOR = 1.2,
    VLEG_DIV = 20, VLEG_MIN = 5,
    DIR_MIN = 0.5, DIR_FLIP = 0.8,
    BRAKE_LVL = 5,
    TOL_LAT = 1.0,
    LOOP = 0.02,
}

-- panel protocol
local function broadcast_apstate()
    if not modem then return end
    pcall(modem.transmit, AUTOPILOT_CHANNEL, AUTOPILOT_REPLY_CHANNEL,
        "APSTATE|" .. (autopilot_paused and "OFF" or "ON"))
end

local function waitTick(dt)
    local timer = os.startTimer(dt)
    while true do
        local event, p1, p2, p3, p4 = os.pullEvent()
        if event == "timer" and p1 == timer then
            return
        elseif event == "modem_message" then
            local channel, message = p2, p4
            if channel == PANEL_CHANNEL and message == "ABORT" then
                error("ABORT: stopped from the panel")
            elseif channel == PANEL_CHANNEL and message == "AP" then
                autopilot_paused = not autopilot_paused
                print(autopilot_paused and "[AP] PAUSED" or "[AP] RESUMED")
                broadcast_apstate()
            end
        elseif event == "key" and p1 == keys.k then
            pcall(thrusters.all_stop)
            print("--- K: update target ---")
            pcall(prompt_target, true)
            return
        end
    end
end

local function report(phase, distance)
    if not modem then return end
    report_tick = report_tick + 1
    if report_tick % 3 ~= 0 and phase ~= "ERROR" then return end
    local msg = phase
    if distance then msg = msg .. "|" .. string.format("%.1f", distance) end
    pcall(modem.transmit, AUTOPILOT_CHANNEL, AUTOPILOT_REPLY_CHANNEL, msg)
end

local function broadcast_target(target)
    if not modem then return end
    pcall(modem.transmit, AUTOPILOT_CHANNEL, AUTOPILOT_REPLY_CHANNEL,
        string.format("TARGET|%.1f|%.1f|%.1f", target.x, target.y, target.z))
end

local TARGET_FILE = "target.txt"
local function load_saved_target()
    if not fs.exists(TARGET_FILE) then return nil end
    local f = fs.open(TARGET_FILE, "r")
    local target = textutils.unserialize(f.readAll())
    f.close()
    return target
end
local function save_target(target)
    local f = fs.open(TARGET_FILE, "w")
    f.write(textutils.serialize(target))
    f.close()
end

-- math
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function vsub(a, b) return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z } end
local function vadd(a, b) return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z } end
local function vscale(a, k) return { x = a.x * k, y = a.y * k, z = a.z * k } end
local function vdot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function vlen(a) return math.sqrt(vdot(a, a)) end
local function vcross(a, b)
    return { x = a.y * b.z - a.z * b.y, y = a.z * b.x - a.x * b.z, z = a.x * b.y - a.y * b.x }
end
local function vnorm(a)
    local l = vlen(a)
    if l < 1e-9 then return { x = 0, y = 1, z = 0 } end
    return vscale(a, 1 / l)
end
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function extractQuaternion(q)
    if type(q) ~= "table" and type(q) ~= "userdata" then return nil end
    local x, y, z, w
    if type(q.v) == "table" then
        x, y, z, w = tonumber(q.v.x), tonumber(q.v.y), tonumber(q.v.z), tonumber(q.a)
    else
        x, y, z, w = tonumber(q.x), tonumber(q.y), tonumber(q.z), tonumber(q.w)
    end
    if not (x and y and z and w) then return nil end
    local l = math.sqrt(x * x + y * y + z * z + w * w)
    if l < 1e-6 then return nil end
    return { x = x / l, y = y / l, z = z / l, w = w / l }
end
local function rotate(qq, x, y, z)
    local qx, qy, qz, qw = qq.x, qq.y, qq.z, qq.w
    local tx = 2 * (qy * z - qz * y)
    local ty = 2 * (qz * x - qx * z)
    local tz = 2 * (qx * y - qy * x)
    return { x = x + qw * tx + (qy * tz - qz * ty),
             y = y + qw * ty + (qz * tx - qx * tz),
             z = z + qw * tz + (qx * ty - qy * tx) }
end
local function quatMul(a, b)
    return { w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
             x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
             y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
             z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w }
end
-- rotation from qa to qb as a vector in rad in the body frame of qa
local function rotVecBody(qa, qb)
    local r = quatMul({ x = -qa.x, y = -qa.y, z = -qa.z, w = qa.w }, qb)
    if r.w < 0 then r = { x = -r.x, y = -r.y, z = -r.z, w = -r.w } end
    local sn = math.sqrt(r.x * r.x + r.y * r.y + r.z * r.z)
    if sn < 1e-9 then return 0, 0, 0 end
    local k = 2 * atan2(sn, r.w) / sn
    return r.x * k, r.y * k, r.z * k
end

-- state
local prevS
local frameShift
local bodyOff

local function readState()
    local pose = sublevel.getLogicalPose()
    local q = extractQuaternion(pose.orientation)
    assert(q, "cannot read orientation")
    local vel = sublevel.getLinearVelocity()
    local s = {
        t = os.epoch("utc") / 1000, q = q,
        pos = { x = pose.position.x + (frameShift and frameShift.x or 0),
                y = pose.position.y + (frameShift and frameShift.y or 0),
                z = pose.position.z + (frameShift and frameShift.z or 0) },
        vel = { x = vel.x, y = vel.y, z = vel.z },
        right = rotate(q, 1, 0, 0), up = rotate(q, 0, 1, 0), fwd = rotate(q, 0, 0, 1),
    }
    local w = { 0, 0, 0 }
    if prevS and s.t > prevS.t + 1e-3 then
        local dt = s.t - prevS.t
        local rx, ry, rz = rotVecBody(prevS.q, q)
        local raw = { math.deg(rx) / dt, math.deg(ry) / dt, math.deg(rz) / dt }
        for i = 1, 3 do w[i] = P.W_ALPHA * raw[i] + (1 - P.W_ALPHA) * prevS.w[i] end
    end
    s.w = w
    prevS = s
    return s
end

-- computer position in the same frame as the target
local function posC(st)
    if not bodyOff then return st.pos end
    return vadd(st.pos, vadd(vscale(st.right, bodyOff.x),
        vadd(vscale(st.up, bodyOff.y), vscale(st.fwd, bodyOff.z))))
end
local function toBody(st, v) return { vdot(v, st.right), vdot(v, st.up), vdot(v, st.fwd) } end
local function bodyVecToWorld(st, b)
    return vadd(vscale(st.right, b.x), vadd(vscale(st.up, b.y), vscale(st.fwd, b.z)))
end

-- taught target uses ship origin, typed target uses gps
local function refPos(st)
    if config.target.taught then return st.pos end
    return posC(st)
end

local function applyTarget(t)
    config.target = t
    if t.ax then config.approach_vector = { x = t.ax, y = t.ay, z = t.az } end
end

local PORT_DIRS = {
    w = { x = 1, y = 0, z = 0 }, e = { x = -1, y = 0, z = 0 },
    n = { x = 0, y = 0, z = 1 }, s = { x = 0, y = 0, z = -1 },
    u = { x = 0, y = -1, z = 0 }, d = { x = 0, y = 1, z = 0 },
}
local function portDir(letter)
    return PORT_DIRS[string.lower(letter or "")]
end
local function portLetter(ax, ay, az)
    for k, v in pairs(PORT_DIRS) do
        if math.abs(v.x - ax) < 0.05 and math.abs(v.y - ay) < 0.05 and math.abs(v.z - az) < 0.05 then
            return string.upper(k)
        end
    end
    return string.format("%.2f %.2f %.2f", ax, ay, az)
end

-- enter keeps saved, t teaches from current pose, m types coordinates
prompt_target = function(allowTeach)
    local default = load_saved_target() or config.target
    local target = default
    if allowTeach then
        print("enter = auto (direction from the ship pose) | t = teach exact pose | m = type coordinates + port side | d = change port side only")
        local ans = read()
        if ans == "t" then
            io.write("gap from the ship hatch to the final docked position, blocks (0 = docked now): ")
            local gap = tonumber(read()) or 0
            local st = readState()
            local h = bodyVecToWorld(st, config.hatch_local_axis)
            target = { x = st.pos.x + h.x * gap, y = st.pos.y + h.y * gap, z = st.pos.z + h.z * gap,
                       ax = h.x, ay = h.y, az = h.z, taught = true }
            print(string.format("taught: target %.1f %.1f %.1f, approach %.2f %.2f %.2f", target.x, target.y, target.z, h.x, h.y, h.z))
        elseif ans == "m" or ans == "d" then
            local x, y, z = default.x, default.y, default.z
            if ans == "m" then
                io.write("x [" .. default.x .. "]: "); x = tonumber(read()) or x
                io.write("y [" .. default.y .. "]: "); y = tonumber(read()) or y
                io.write("z [" .. default.z .. "]: "); z = tonumber(read()) or z
            end
            target = { x = x, y = y, z = z, taught = (ans == "d") and default.taught or nil }
            if default.ax then target.ax, target.ay, target.az = default.ax, default.ay, default.az end
            local cur = default.ax and portLetter(default.ax, default.ay, default.az) or "auto"
            io.write("ports face W/E/N/S/U/D [" .. cur .. "], enter = keep: ")
            local dir = portDir(read())
            if dir then
                target.ax, target.ay, target.az = dir.x, dir.y, dir.z
                print(string.format("ports face %s, approach %.0f %.0f %.0f", portLetter(dir.x, dir.y, dir.z), dir.x, dir.y, dir.z))
            end
        end
    end
    local toSave = target
    -- no stored direction, take the line from the ship to the target
    if allowTeach and not target.ax then
        local okS, st = pcall(readState)
        if okS and st then
            local h = bodyVecToWorld(st, config.hatch_local_axis)
            local d = vsub(target, st.pos)
            local dist = vlen(d)
            if dist > 1 then
                local dir = vscale(d, 1 / dist)
                local c = clamp(vdot(h, dir), -1, 1)
                local av = dir
                target = { x = target.x, y = target.y, z = target.z, ax = av.x, ay = av.y, az = av.z, taught = target.taught }
                print(("auto approach %.2f %.2f %.2f from %s (hatch is %.0f deg off the target line)")
                    :format(av.x, av.y, av.z, "ship->target line", math.deg(math.acos(c))))
            end
        end
    end
    applyTarget(target)
    save_target(toSave)
    broadcast_target(target)
    print(string.format("target: %.1f %.1f %.1f%s", target.x, target.y, target.z, target.taught and " (taught)" or ""))
    return target
end

-- rotation vector in deg that turns world vector cur onto want, in body axes
local function pointErr(st, cur, want)
    local c = vcross(cur, want)
    local s = vlen(c)
    local d = vdot(cur, want)
    local theta = atan2(s, d)
    local axis
    if s < 1e-4 then
        if d > 0 then return { 0, 0, 0 }, 0 end
        local other = (math.abs(cur.x) < 0.9) and { x = 1, y = 0, z = 0 } or { x = 0, y = 1, z = 0 }
        axis = vnorm(vcross(cur, other))
    else
        axis = vscale(c, 1 / s)
    end
    local e = vscale(axis, theta)
    local b = toBody(st, e)
    return { math.deg(b[1]), math.deg(b[2]), math.deg(b[3]) }, math.deg(theta)
end

-- actuation
local want = {}
local function put(name, lvl)
    lvl = clamp(math.floor(lvl + 0.5), 0, 15)
    if lvl > (want[name] or 0) then want[name] = lvl end
end
local function torque(i, a, cap)
    local t = ACT.torque[i]
    local lvl = (a > 0) and (a / t.gp) or (-a / t.gn)
    if cap and lvl > cap then lvl = cap end
    put(a > 0 and t.pos or t.neg, lvl)
end
-- dash gives nothing below 3 so it pulses 3 and 0
local resid = {}
local function putDither(name, lvl)
    lvl = clamp(lvl, 0, 15)
    local q = (name:sub(1, 5) == "dash_") and 3 or 1
    local n = math.floor(lvl / q) * q
    resid[name] = (resid[name] or 0) + (lvl - n)
    if resid[name] >= q then n = n + q; resid[name] = resid[name] - q end
    if n > (want[name] or 0) then want[name] = n end
end
local function force(i, a)
    local f = ACT.force[i]
    if a > 0 then if f.pos then putDither(f.pos, a / f.gp) end
    elseif f.neg then putDither(f.neg, -a / f.gn) end
end

-- cascade from angle error to wanted rate to torque
local function attitudeControl(err, w, mainLvl, dampOnly, cap, wmax)
    for i = 1, 3 do
        local wd = 0
        if not dampOnly then
            wd = clamp(P.K_ATT * err[i], -(wmax or P.WMAX), (wmax or P.WMAX))
            local lim = math.sqrt(P.ATT_ACC[i] * math.abs(err[i]))
            wd = clamp(wd, -lim, lim)
        end
        local a = P.KW * (wd - w[i]) - ACT.mainTorque[i] * (mainLvl or 0)
        torque(i, a, cap)
    end
end

-- attitude thrusters push the ship along minus up, main cancels it
local RCS_FORCE_U = { pitch_up = -0.13, pitch_down = -0.23, yaw_left = -0.14, yaw_right = -0.13 }
local curAng = nil
local noComp = false -- DIRECT: the hatch axis can only be pushed forward, never braked
local compAlways = false
local function apply()
    local net = 0
    for k, v in pairs(want) do net = net + (RCS_FORCE_U[k] or 0) * v end
    -- no compensation while up points away from the wanted direction
    if net < 0 and not noComp and ((compAlways and curAng ~= 180) or not (curAng and curAng > 60)) then
        local m = (want.main or 0) + (-net / ACT.force[2].gp)
        want.main = clamp(math.floor(m + 0.5), 0, 15)
    end
    thrusters.setMany(want)
end

-- one control tick
local function tick(phase, dist, ctl)
    want = {}
    curAng = nil
    local st = readState()
    local info = ""
    if autopilot_paused then
        info = "paused"
        thrusters.setMany({})
    else
        local maxw = math.max(math.abs(st.w[1]), math.abs(st.w[2]), math.abs(st.w[3]))
        if maxw > P.SPIN_ABORT then
            curAng = 180
            attitudeControl({ 0, 0, 0 }, st.w, 0, true, 6)
            info = "SPIN GUARD"
        else
            info = ctl(st) or ""
        end
        apply()
        local wl = {}
        for k, v in pairs(want) do if v > 0 then wl[#wl + 1] = k .. "=" .. v end end
        table.sort(wl)
        info = info .. " W:" .. table.concat(wl, ";")
    end
    flightlog.log(phase, st.pos, st.vel, st.w[1] * 0.0175, st.w[2] * 0.0175, st.w[3] * 0.0175,
        dist, nil, info)
    report(phase, dist)
    waitTick(P.LOOP)
    return st
end

-- self check
local function selfCheck()
    print("[check] torque signs ...")
    local tests = {
        { "roll_ccw", "roll_cw", 2, 2, 0.4 },
        { "pitch_down", "pitch_up", 1, 6, 0.5 },
        { "yaw_right", "yaw_left", 3, 6, 0.5 },
    }
    local names = { "R(pitch)", "U(roll)", "F(yaw)" }
    for _, t in ipairs(tests) do
        thrusters.setMany({})
        sleep(0.5)
        -- measure leftover drift from the previous test over a quiet window
        prevS = nil
        local sa = readState()
        sleep(0.6)
        local s0 = readState()
        local ra, rb2, rc = rotVecBody(sa.q, s0.q)
        local dtb = math.max(s0.t - sa.t, 0.1)
        local drift = { math.deg(ra) / dtb, math.deg(rb2) / dtb, math.deg(rc) / dtb }
        thrusters.setMany({ [t[1]] = t[4] }); sleep(t[5])
        thrusters.setMany({}); sleep(0.3)
        local s1 = readState()
        local rx, ry, rz = rotVecBody(s0.q, s1.q)
        local dtt = s1.t - s0.t
        -- remove the drift that would have happened anyway
        local d = { math.deg(rx) - drift[1] * dtt, math.deg(ry) - drift[2] * dtt, math.deg(rz) - drift[3] * dtt }
        local k, m = 1, 0
        for i = 1, 3 do if math.abs(d[i]) > m then k, m = i, math.abs(d[i]) end end
        print((" %s lvl%d: turned %+.1f %+.1f %+.1f deg (drift %+.1f %+.1f %+.1f /s)"):format(
            t[1], t[4], d[1], d[2], d[3], drift[1], drift[2], drift[3]))
        -- cancel the turn
        thrusters.setMany({ [t[2]] = t[4] }); sleep(t[5] * 1.1)
        thrusters.setMany({}); sleep(0.5)
        if math.abs(d[t[3]]) < 0.3 and m < 0.3 then
            error(("selfcheck: %s did not turn the ship (check link/thruster)"):format(t[1]), 0)
        end
        if d[t[3]] < 0 and k == t[3] then
            error(("selfcheck: %s turned the wrong way (%s%+.1f), axis/sign table is wrong"):format(
                t[1], names[t[3]], d[t[3]]), 0)
        end
        if k ~= t[3] and math.abs(d[t[3]]) < 0.5 * m then
            print(("[check] warn: %s mostly turned %s (%+.1f), expected %s"):format(t[1], names[k], d[k], names[t[3]]))
            if d[t[3]] < 0 then
                error(("selfcheck: %s turned the wrong way on its axis (%+.1f)"):format(t[1], d[t[3]]), 0)
            end
        end
    end
    prevS = nil
    print("[check] ok")
end

-- haul to a point
local function haul(goal, stopR, timeout, phase)
    noComp = false
    compAlways = false
    local t0 = os.clock()
    local lastDir
    local vcap
    local done = false
    while not done do
        if os.clock() - t0 > timeout then error(phase .. ": timeout", 0) end
        local d0
        tick(phase, nil, function(st)
            local pos = refPos(st)
            local d = vsub(goal, pos)
            local dist = vlen(d)
            d0 = dist
            local speed = vlen(st.vel)
            if dist < P.HOLD_R and speed < P.HOLD_V then done = true; return "arrived" end
            -- short legs get a lower top speed so the flip costs less distance
            vcap = vcap or clamp(dist / P.VLEG_DIV, P.VLEG_MIN, P.VMAX)
            local dirT = vscale(d, 1 / math.max(dist, 1e-6))
            local rem = math.max(dist - stopR, 0)
            local aT = P.ABRAKE * P.FLIP_T
            local vmag = math.min(vcap, -aT + math.sqrt(aT * aT + 2 * P.ABRAKE * rem))
            -- velocity noise dominates at low speed so keep a floor
            if rem > 5 then vmag = math.max(vmag, P.VFLOOR) end
            local a = vscale(vsub(vscale(dirT, vmag), st.vel), P.KV)
            local am = vlen(a)
            if am > P.AMAX then a = vscale(a, P.AMAX / am); am = P.AMAX end
            -- direction hysteresis, a turn over 90 deg needs a real correction
            local cand = vscale(a, 1 / math.max(am, 1e-6))
            if not lastDir then
                lastDir = (am > 1e-6) and cand or st.up
            elseif am > P.DIR_MIN then
                local behind = vdot(st.up, cand) < 0
                if not behind or am > P.DIR_FLIP then lastDir = cand end
            end
            local err, ang = pointErr(st, st.up, lastDir)
            local mainLvl = 0
            local maxw = math.max(math.abs(st.w[1]), math.abs(st.w[2]), math.abs(st.w[3]))
            if am > P.DIR_MIN and ang < P.FIRE_ANGLE and maxw < P.FIRE_RATE then
                mainLvl = am * math.cos(math.rad(ang)) / ACT.force[2].gp
                -- soft braking
                if vdot(lastDir, st.vel) < 0 and mainLvl > P.BRAKE_LVL then mainLvl = P.BRAKE_LVL end
                put("main", mainLvl)
            end
            -- roll about the thrust axis is free
            err[2] = 0
            curAng = ang
            attitudeControl(err, st.w, want.main or 0, false, 8, 12)
            return string.format("v=%.1f vd=%.1f ang=%.0f m=%d", speed, vmag, ang, want.main or 0)
        end)
        if d0 then
            report(phase, d0)
        end
    end
    thrusters.setMany({})
end

-- direct approach
local D = { VAPP = 0.6, DEC = 0.15, KV = 0.8, AMAX = 0.35, VLATMAX = 0.4, RCS_CAP = 4, WMAX = 6 }

-- the ship stalls against the port at along 3.7 so latch from further out
local DOCK_ALONG = 6

-- roll about the hatch axis, the right or left side of the computer must face world up
local WORLD_UP = { x = 0, y = 1, z = 0 }
local rollSide = nil
local function wrap180(a) return a - 360 * math.floor((a + 180) / 360) end
local function sideRoll(st, hatchW, av, hl)
    local upRef = vsub(WORLD_UP, vscale(av, vdot(WORLD_UP, av)))
    if vlen(upRef) < 0.3 then return nil end
    upRef = vsub(upRef, vscale(hatchW, vdot(upRef, hatchW)))
    if vlen(upRef) < 0.2 then return nil end
    upRef = vnorm(upRef)
    local side = (math.abs(hl.x) > 0.5) and st.up or st.right
    local sp = vsub(side, vscale(hatchW, vdot(side, hatchW)))
    if vlen(sp) < 1e-3 then return nil end
    sp = vnorm(sp)
    local phiA = math.deg(atan2(vdot(vcross(sp, upRef), hatchW), vdot(sp, upRef)))
    local phiB = wrap180(phiA + 180)
    -- keep the chosen side with 20 deg hysteresis
    if rollSide == nil then
        rollSide = (math.abs(phiA) <= math.abs(phiB)) and 1 or -1
    else
        local cur, other = (rollSide == 1) and phiA or phiB, (rollSide == 1) and phiB or phiA
        if math.abs(other) + 20 < math.abs(cur) then rollSide = -rollSide end
    end
    return (rollSide == 1) and phiA or phiB
end

-- coast on low speed, turn the hatch to the approach vector and roll, no thrust
local function align(timeout)
    print("[align] hatch to approach vector + roll")
    noComp = false
    compAlways = true
    local av = vnorm(config.approach_vector)
    local hl = config.hatch_local_axis
    local t0 = os.clock()
    local done = false
    while not done do
        if os.clock() - t0 > timeout then error("ALIGN: timeout", 0) end
        tick("ALIGN", nil, function(st)
            local hatchW = bodyVecToWorld(st, hl)
            -- too close to the port, let direct deal with it
            local along = vdot(vsub(config.target, refPos(st)), av)
            if along < 10 then done = true; return "too close" end
            local err, ang = pointErr(st, hatchW, av)
            local phi = nil
            if ang < 40 then phi = sideRoll(st, hatchW, av, hl) end
            if phi then
                local rb = toBody(st, vscale(hatchW, math.rad(phi)))
                for i = 1, 3 do err[i] = err[i] + math.deg(rb[i]) end
            end
            local maxw = math.max(math.abs(st.w[1]), math.abs(st.w[2]), math.abs(st.w[3]))
            local vertical = math.abs(av.y) > 0.9
            if ang < 8 and maxw < 2 and (vertical or (phi and math.abs(phi) < 8)) then
                done = true
                return "aligned"
            end
            curAng = ang
            attitudeControl(err, st.w, 0, false, 8, 12)
            return string.format("ang=%.0f phi=%s al=%.1f", ang, phi and string.format("%.0f", phi) or "-", along)
        end)
    end
    thrusters.setMany({})
end

-- returns true when docked, false when it left the corridor
local function direct(timeout)
    print("[direct] hatch toward the dock, main forward, dash sideways")
    noComp = false  -- attitude thrusters push the ship along -U even at low levels, main must cancel it
    compAlways = false
    local stuckPos, stuckT0
    local tooFast = 0
    local av = vnorm(config.approach_vector)
    local hl = config.hatch_local_axis
    local t0 = os.clock()
    local done, failed, latched = false, false, false
    local a0, l0
    local still = 0
    while not done and not failed do
        if os.clock() - t0 > timeout then error("DIRECT: timeout", 0) end
        tick("DIRECT", nil, function(st)
            local hatchW = bodyVecToWorld(st, hl)
            local pos = st.pos
            if bodyOff and not config.target.taught then
                pos = vadd(pos, vscale(hatchW, bodyOff.x * hl.x + bodyOff.y * hl.y + bodyOff.z * hl.z))
            end
            local d = vsub(config.target, pos)
            local along = vdot(d, av)
            local lat = vsub(d, vscale(av, along))
            local latm = vlen(lat)
            local vAlong = vdot(st.vel, av)
            local vLat = vsub(st.vel, vscale(av, vAlong))
            local speed = vlen(st.vel)
            a0 = a0 or along; l0 = l0 or latm
            local err, ang = pointErr(st, hatchW, av)
            local phi = nil
            if ang < 30 then phi = sideRoll(st, hatchW, av, hl) end
            -- roll is done within 8 deg or undefined for a vertical approach
            local vertical = math.abs(av.y) > 0.9
            local rollOk = vertical or (phi ~= nil and math.abs(phi) < 8)
            if phi then
                local rb = toBody(st, vscale(hatchW, math.rad(phi)))
                for i = 1, 3 do err[i] = err[i] + math.deg(rb[i]) end
            end
            if not latched and along < DOCK_ALONG and latm < 1.5 and rollOk then
                thrusters.set("dock", 15); latched = true
            end
            still = (along < DOCK_ALONG and speed < 0.05) and still + 1 or 0
            if ((math.abs(along) < config.tolerance and latm < P.TOL_LAT and speed < 1.0) or still > 40) and rollOk then
                done = true
                return "in tolerance"
            end
            if along > a0 + 25 or latm > l0 + 20 then
                failed = true
                return "off corridor"
            end
            -- main only pushes toward the dock, there is no way to brake along the hatch axis
            if along < -3 then failed = true; return "overshoot" end
            -- the velocity api reads in 0.7 m/s steps, a single spike (1.6 at 0.7 real) must not abort
            tooFast = (vAlong > 1.8 and along > 3) and (tooFast + 1) or 0
            if tooFast > 12 then failed = true; return "too fast, cannot brake" end
            -- blocked / collided: no movement for 30 s
            if not stuckPos or vlen(vsub(st.pos, stuckPos)) > 0.3 then
                stuckPos, stuckT0 = st.pos, os.clock()
            elseif os.clock() - stuckT0 > 30 and along > 1 then
                error("DIRECT: ship has not moved for 30 s (blocked or collided?)", 0)
            end
            local vda = math.min(D.VAPP, math.sqrt(2 * D.DEC * math.max(math.abs(along) - 0.3, 0)))
            if along < 0 then vda = -vda end
            vda = vda * clamp(1.2 - latm / 4, 0, 1)
            -- near the port wait for the roll
            if phi and along < 15 then vda = vda * clamp(1.5 - math.abs(phi) / 20, 0, 1) end
            local vl = vscale(lat, 0.3)
            local vlm = vlen(vl)
            if vlm > D.VLATMAX then vl = vscale(vl, D.VLATMAX / vlm) end
            local aAlong = clamp(D.KV * (vda - vAlong), 0, D.AMAX)
            local aLat = vscale(vsub(vl, vLat), D.KV)
            local alm = vlen(aLat)
            if alm > D.AMAX then aLat = vscale(aLat, D.AMAX / alm) end
            local a = vadd(vscale(av, aAlong), aLat)
            local ab = toBody(st, a)
            local maxw = math.max(math.abs(st.w[1]), math.abs(st.w[2]), math.abs(st.w[3]))
            if maxw < D.WMAX and ang < 12 then
                force(1, ab[1]); force(3, ab[3])
                if ab[2] > 0 and ang < 30 then force(2, ab[2]) end
            end
            attitudeControl(err, st.w, want.main or 0, false, D.RCS_CAP, D.WMAX)
            return string.format("al=%.1f lat=%.1f v=%.2f ang=%.0f phi=%s", along, latm, speed, ang, phi and string.format("%.0f", phi) or "-")
        end)
    end
    thrusters.setMany({})
    if failed and latched then thrusters.set("dock", 0) end
    return done
end

-- entry
report("INIT")

-- wait for START from stage 2 (f9_payload). Any key = skip and type the target by hand like before.
local function waitStart()
    local wm = peripheral.find("modem", function(_, p) return p.isWireless and p.isWireless() end)
    if not wm then print("[start] no wireless modem, manual mode"); return nil end
    pcall(rednet.open, peripheral.getName(wm))
    print("[start] waiting for START from stage 2 (any key = manual)")
    -- while attached: after stage 2 cuts off (DAMP messages) stop the stack's rotation with the RCS (damp only)
    local damping, dampLast, inited = false, 0, false
    local tmr = os.startTimer(0.2)
    while true do
        local ev, a, b, c = os.pullEvent()
        if ev == "rednet_message" and c == "f9_payload" and type(b) == "table" and b.cmd == "START" then
            pcall(rednet.send, a, { cmd = "ACK", t = os.epoch("utc") }, "f9_payload")
            if damping then pcall(thrusters.setMany, {}) end
            return b
        elseif ev == "rednet_message" and c == "f9_payload" and type(b) == "table" and b.cmd == "DAMP" then
            damping, dampLast = true, os.clock()
        elseif ev == "timer" and a == tmr then
            tmr = os.startTimer(0.2)
            if damping and os.clock() - dampLast < 5 then
                pcall(function()
                    if not inited then thrusters.init(); inited = true end
                    want = {}; curAng = nil
                    local st = readState()
                    attitudeControl({ 0, 0, 0 }, st.w, 0, true, 6)
                    apply()
                end)
            elseif damping then
                damping = false
                pcall(thrusters.setMany, {})
            end
        elseif ev == "key" then
            return nil
        end
    end
end

local startMsg = waitStart()
if startMsg and type(startMsg.target) == "table" then
    local t = startMsg.target
    local tgt = { x = t.x, y = t.y, z = t.z, ax = t.ax, ay = t.ay, az = t.az }
    applyTarget(tgt); save_target(tgt); broadcast_target(tgt)
    print(string.format("[start] target from stage 2: %.0f %.0f %.0f", tgt.x, tgt.y, tgt.z))
else
    prompt_target(true)
end
broadcast_apstate()
flightlog.init()

local ok, err = pcall(function()
    thrusters.init()
    assert(sublevel, "no sublevel api")
    -- computer position inside the ship
    local s = readState()
    local okg, gx, gy, gz = pcall(gps.locate, 2)
    if okg and gx then
        local dv = { x = gx - s.pos.x, y = gy - s.pos.y, z = gz - s.pos.z }
        local off = { x = vdot(dv, s.right), y = vdot(dv, s.up), z = vdot(dv, s.fwd) }
        if config.target.taught then
            print("taught pose: positions stay in the sublevel frame, gps not used")
        elseif vlen(off) < 60 then
            bodyOff = off
            print(("gps offset body R/U/F %.1f %.1f %.1f"):format(off.x, off.y, off.z))
        else
            -- sublevel frame is not gps, shift it
            frameShift = dv
            s = readState()
            print(("sublevel is %.0f m from gps, shifting positions by %.1f %.1f %.1f"):format(vlen(dv), dv.x, dv.y, dv.z))
        end
    end
    report("CHECK")
    -- selfCheck() removed: after release the craft is not moving yet and the movement test banged into stage 2
    local av = vnorm(config.approach_vector)
    local hold = vsub(config.target, vscale(av, config.approach_distance))
    print(("[haul] to hold point %.0f %.0f %.0f"):format(hold.x, hold.y, hold.z))
    -- wide corridor, direct cancels lateral error with dash
    local function inCorridor()
        local s2 = readState()
        local dd = vsub(config.target, refPos(s2))
        local al = vdot(dd, av)
        return al > 3 and al < 150 and vlen(vsub(dd, vscale(av, al))) < 12 + 0.5 * al
    end
    local docked = false
    local reHaul = false
    for try = 1, 3 do
        if reHaul or not inCorridor() then
            haul(hold, 2, 1500, "COARSE")
            print("[haul] hold point reached")
            align(60)
        end
        docked = direct(500)
        if docked then break end
        print("[direct] failed, back to the hold point and retry")
        reHaul = true
    end
    assert(docked, "dock failed after 3 tries")
    print("[dock] in tolerance, latch")
    report("DOCKING")
    thrusters.setMany({})
    -- hold the latch on, release it from the panel
    thrusters.set("dock", 15)
    report("DOCKED")
    print("docked.")
end)

if not ok then
    flightlog.note("ERROR: " .. tostring(err))
    print("ERROR: " .. tostring(err))
    pcall(thrusters.all_stop)
    if modem then
        pcall(modem.transmit, AUTOPILOT_CHANNEL, AUTOPILOT_REPLY_CHANNEL, "ERROR|" .. tostring(err))
    end
end
pcall(thrusters.all_stop)