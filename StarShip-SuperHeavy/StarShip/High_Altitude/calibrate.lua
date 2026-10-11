-- calib_sh.lua -- Super Heavy control-axis calibration. RUN IN ZERO-G, craft free to move.
-- Fully automatic. Pulses every actuator, measures linear/angular response from the
-- sublevel API, writes a log + data file. Upload calib_sh_*.log afterwards.
-- All output is ASCII on purpose (CC terminal shows Russian as garbage).

local CONFIG = {
    pose = { UP_AXIS = "+Y", FORWARD_AXIS = "+Z", RIGHT_AXIS = "+X" },  -- same as superheavy_landing.lua
    ANGVEL_FRAME = "body",   -- raw getAngularVelocity frame ("body" or "world"), same as landing script
    run = {
        START_DELAY   = 8,     -- seconds to abort with Ctrl+T
        PRE           = 0.6,   -- baseline sampling before each pulse (s)
        TAIL          = 0.9,   -- sampling after each pulse (s)
        SKIP          = 0.25,  -- ignore this long after a command before fitting (latency/ramp)
        MIN_SAMPLES   = 3,
        WANT_SAMPLES  = 6,     -- every measured window is stretched to hold at least this many samples (adaptive to the real loop rate)
        BASELINE_TIME = 2.0,
        G_ABORT       = 1.5,   -- abort if baseline |accel| (m/s^2) is above this (= not weightless)
        ALLOW_GRAVITY = false,
        NOISE_A       = 0.05,  -- m/s^2 below this = "no response"
        NOISE_ALPHA   = 0.01,  -- rad/s^2 below this = "no response"
        RAW_DUMP      = false, -- also write every sample to a csv
        FILE_PREFIX   = "calib_sh",
    },
    tests = {
        rcs    = { levels = { 5, 15 }, dur = 0.6 },
        pairs  = { level = 10, dur = 0.6 },
        zav    = { levels = { 5, 15 }, dur = 0.6 },
        vac    = { levels = { 3, 8, 15 }, dur = 0.8 },
        vec    = { levels = { 3, 8, 15 }, dur = 0.8 },
        both   = { level = 8, dur = 0.8 },
        gimbal = { thrust = 8, levels = { 5, 10, 15 }, ref = 0.6, settle = 0.6, hold = 0.8 },
    },
    link = {
        -- RCS block, one side of the ship: top/bottom x left/right
        rcs_tl = { "computercraft:printed_page", "computercraft:printed_page" },
        rcs_tr = { "create_connected:shear_pin", "create_connected:shear_pin" },
        rcs_bl = { "computercraft:speaker",      "computercraft:speaker" },
        rcs_br = { "computercraft:printer",      "computercraft:printer" },
        -- "zaval" left (faces east) / right (faces west)
        zav_l  = { "minecraft:gold_ingot",       "minecraft:gold_ingot" },
        zav_r  = { "minecraft:nautilus_shell",   "minecraft:nautilus_shell" },
        -- engines
        vac    = { "minecraft:armadillo_scute",  "minecraft:armadillo_scute" },
        vec    = { "minecraft:bone_meal",        "minecraft:bone_meal" },
        -- nozzle vector deflection
        gim_n  = { "simulated:rope_coupling",         "simulated:rope_coupling" },
        gim_s  = { "createpropulsion:oxidizer_bucket", "createpropulsion:oxidizer_bucket" },
        gim_w  = { "createpropulsion:tempered_wing",   "createpropulsion:tempered_wing" },
        gim_e  = { "createpropulsion:solid_burner",    "createpropulsion:solid_burner" },
    },
}
local C = CONFIG
local unpackFn = table.unpack or unpack

-- ---------------------------------------------------------------- math helpers
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
local function round(v) return math.floor(v + 0.5) end
local function dot(a, b) return a[1]*b[1] + a[2]*b[2] + a[3]*b[3] end
local function cross(a, b) return { a[2]*b[3] - a[3]*b[2], a[3]*b[1] - a[1]*b[3], a[1]*b[2] - a[2]*b[1] } end
local function norm(a) return math.sqrt(dot(a, a)) end
local function sub(a, b) return { a[1]-b[1], a[2]-b[2], a[3]-b[3] } end
local function add(a, b) return { a[1]+b[1], a[2]+b[2], a[3]+b[3] } end

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
    return { x = x/l, y = y/l, z = z/l, w = w/l }
end
local function rotQ(q, a)  -- rotate vector a (array) by quaternion q (body->world)
    local x, y, z = a[1], a[2], a[3]
    local qx, qy, qz, qw = q.x, q.y, q.z, q.w
    local tx = 2*(qy*z - qz*y)
    local ty = 2*(qz*x - qx*z)
    local tz = 2*(qx*y - qy*x)
    return { x + qw*tx + (qy*tz - qz*ty),
             y + qw*ty + (qz*tx - qx*tz),
             z + qw*tz + (qx*ty - qy*tx) }
end
local function worldToBody(q, a) return rotQ({ x = -q.x, y = -q.y, z = -q.z, w = q.w }, a) end

local AXV = { ["+X"]={1,0,0}, ["-X"]={-1,0,0}, ["+Y"]={0,1,0}, ["-Y"]={0,-1,0}, ["+Z"]={0,0,1}, ["-Z"]={0,0,-1} }
local AX = { R = AXV[C.pose.RIGHT_AXIS], U = AXV[C.pose.UP_AXIS], F = AXV[C.pose.FORWARD_AXIS] }
assert(AX.R and AX.U and AX.F, "bad pose axes in CONFIG")
local function toRUF(v) return { R = dot(v, AX.R), U = dot(v, AX.U), F = dot(v, AX.F) } end

local function linfit(t, y)  -- y = c + m * t   (t relative to some reference)
    local n = #t
    if n < 2 then return nil end
    local mt, my = 0, 0
    for i = 1, n do mt = mt + t[i]; my = my + y[i] end
    mt, my = mt / n, my / n
    local sxx, sxy = 0, 0
    for i = 1, n do
        local dx = t[i] - mt
        sxx = sxx + dx*dx
        sxy = sxy + dx*(y[i] - my)
    end
    if sxx < 1e-9 then return nil end
    local m = sxy / sxx
    return m, my - m*mt
end

-- ---------------------------------------------------------------- log
local runId = tostring(os.epoch("utc"))
local logName = C.run.FILE_PREFIX .. "_" .. runId .. ".log"
local dataName = C.run.FILE_PREFIX .. "_" .. runId .. ".dat"
local logFile = fs.open(logName, "w")
local function L(s)
    print(s)
    if logFile then logFile.writeLine(s); logFile.flush() end
end
local rawFile = C.run.RAW_DUMP and fs.open(C.run.FILE_PREFIX .. "_" .. runId .. "_raw.csv", "w") or nil
if rawFile then rawFile.writeLine("t,g,vx,vy,vz,wx,wy,wz,qx,qy,qz,qw") end

local function f3(t) return ("(%+.3f,%+.3f,%+.3f)"):format(t.R, t.U, t.F) end

-- ---------------------------------------------------------------- hardware
local bridge = peripheral.find("redstone_link_bridge")
assert(bridge, "redstone_link_bridge not found")
local lastSent = {}
local function applyState(state)
    local fns = {}
    for key, pair in pairs(C.link) do
        local lv = clamp(round(state[key] or 0), 0, 15)
        if lastSent[key] ~= lv then
            lastSent[key] = lv
            fns[#fns + 1] = function() bridge.sendLinkSignal(pair[1], pair[2], lv) end
        end
    end
    if #fns == 0 then return end
    local ok, err
    if #fns == 1 then ok, err = pcall(fns[1]) else ok, err = pcall(parallel.waitForAll, unpackFn(fns)) end
    if not ok then lastSent = {}; error(err, 0) end
end
local function forceZero()
    lastSent = {}
    pcall(applyState, {})
end

local function clock() return os.epoch("utc") / 1000 end
local function gclock() return os.epoch("ingame") / 72000 end  -- ticks * 0.05 s (validated by ratio at analysis)

local S = {}
local PARALLEL_READ = true   -- chosen by a benchmark at start: 3 sublevel calls in one tick vs one after another
local function sampleOnce()
    local okp, pose, okv, v, okw, w
    if PARALLEL_READ then
        local ok = pcall(parallel.waitForAll,
            function() okp, pose = pcall(sublevel.getLogicalPose) end,
            function() okv, v = pcall(sublevel.getLinearVelocity) end,
            function() okw, w = pcall(sublevel.getAngularVelocity) end)
        if not ok then return nil end
    else
        okp, pose = pcall(sublevel.getLogicalPose)
        okv, v = pcall(sublevel.getLinearVelocity)
        okw, w = pcall(sublevel.getAngularVelocity)
    end
    if not (okp and okv and okw) or type(pose) ~= "table" or type(v) ~= "table" or type(w) ~= "table" then return nil end
    local q = extractQuaternion(pose.orientation)
    if not q then return nil end
    local s = {
        t = clock(), g = gclock(), q = q,
        v = { tonumber(v.x) or 0, tonumber(v.y) or 0, tonumber(v.z) or 0 },
        w = { tonumber(w.x) or 0, tonumber(w.y) or 0, tonumber(w.z) or 0 },
    }
    if C.ANGVEL_FRAME == "world" then s.w = worldToBody(q, s.w) end
    S[#S + 1] = s
    if rawFile then
        rawFile.writeLine(("%.3f,%.3f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f"):format(
            s.t, s.g, s.v[1], s.v[2], s.v[3], s.w[1], s.w[2], s.w[3], q.x, q.y, q.z, q.w))
    end
    return s
end

-- ---------------------------------------------------------------- test plan
local function buildSteps(hz)
    local R, T = C.run, C.tests
    local per = 1 / math.max(hz or 5, 1)
    local want = R.WANT_SAMPLES
    local function D(d) return math.max(d, R.SKIP + want * per) end
    local PRE_T  = math.max(R.PRE,  (R.MIN_SAMPLES + 2) * per)
    local TAIL_T = math.max(R.TAIL, (R.MIN_SAMPLES + 2) * per)
    local steps = {}
    local function simple(name, group, keys, level, dur, lvlKey)
        steps[#steps + 1] = {
            name = name, group = group, keys = keys, level = level, lvlKey = lvlKey,
            phases = {
                { id = "pre",  set = {}, dur = PRE_T, skip = 0 },
                { id = "on",   set = keys, dur = D(dur), skip = R.SKIP },
                { id = "tail", set = {}, dur = TAIL_T, skip = 0 },
            },
            cmp = { { id = "main", on = "on", base = "pre" } },
        }
    end
    local rcsKeys = { "rcs_tl", "rcs_tr", "rcs_bl", "rcs_br" }
    for _, k in ipairs(rcsKeys) do
        for _, lv in ipairs(T.rcs.levels) do simple(k .. " L" .. lv, "rcs", { [k] = lv }, lv, T.rcs.dur, k) end
    end
    local pairsList = { { "rcs_tl", "rcs_tr" }, { "rcs_bl", "rcs_br" }, { "rcs_tl", "rcs_bl" },
                        { "rcs_tr", "rcs_br" }, { "rcs_tl", "rcs_br" }, { "rcs_tr", "rcs_bl" } }
    for _, p in ipairs(pairsList) do
        local lv = T.pairs.level
        local st = {}; st[p[1]] = lv; st[p[2]] = lv
        simple(p[1] .. "+" .. p[2] .. " L" .. lv, "pair", st, lv, T.pairs.dur)
        steps[#steps].pairKeys = p
    end
    for _, k in ipairs({ "zav_l", "zav_r" }) do
        for _, lv in ipairs(T.zav.levels) do simple(k .. " L" .. lv, "zav", { [k] = lv }, lv, T.zav.dur, k) end
    end
    do
        local lv = T.zav.levels[#T.zav.levels]
        simple("zav_l+zav_r L" .. lv, "zavboth", { zav_l = lv, zav_r = lv }, lv, T.zav.dur)
    end
    for _, lv in ipairs(T.vac.levels) do simple("vac L" .. lv, "eng", { vac = lv }, lv, T.vac.dur, "vac") end
    for _, lv in ipairs(T.vec.levels) do simple("vec L" .. lv, "eng", { vec = lv }, lv, T.vec.dur, "vec") end
    simple("vac+vec L" .. T.both.level, "engboth", { vac = T.both.level, vec = T.both.level }, T.both.level, T.both.dur)
    for _, d in ipairs({ "gim_n", "gim_s", "gim_w", "gim_e" }) do
        for _, lv in ipairs(T.gimbal.levels) do
            local eng = { vec = T.gimbal.thrust }
            local both = { vec = T.gimbal.thrust }; both[d] = lv
            steps[#steps + 1] = {
                name = d .. " L" .. lv .. " @vec" .. T.gimbal.thrust, group = "gimbal", keys = both, level = lv, lvlKey = d,
                phases = {
                    { id = "pre",  set = {}, dur = PRE_T, skip = 0 },
                    { id = "ref",  set = eng, dur = D(T.gimbal.ref), skip = R.SKIP },
                    { id = "gim",  set = both, dur = T.gimbal.settle + math.max(T.gimbal.hold, want * per), skip = T.gimbal.settle },
                    { id = "tail", set = {}, dur = TAIL_T, skip = 0 },
                },
                cmp = { { id = "eng", on = "ref", base = "pre" }, { id = "gim", on = "gim", base = "ref" } },
            }
        end
    end
    return steps
end

local function runPhase(ph)
    sampleOnce()
    ph.t0, ph.g0 = clock(), gclock()
    applyState(ph.set or {})
    ph.sendMs = (clock() - ph.t0) * 1000
    ph.i1 = #S + 1
    while clock() - ph.t0 < ph.dur do
        local tl = clock()
        sampleOnce()
        if clock() - tl < 0.01 then os.sleep(0) end  -- the sublevel calls already yield; sleep(0) only as a guard
    end
    ph.i2 = #S
    ph.t1, ph.g1 = clock(), gclock()
end

-- ---------------------------------------------------------------- analysis
local function analyzeStep(step)
    local first, last = S[step.phases[1].i1], S[step.phases[#step.phases].i2]
    if not first or not last then return nil, "no samples" end
    local rs, gs = last.t - first.t, last.g - first.g
    local useG = gs > 0 and rs > 0 and (gs / rs) > 0.3 and (gs / rs) < 1.5
    local function T(s) return useG and s.g or s.t end
    local tRef = T(first)
    local fits = {}
    for _, ph in ipairs(step.phases) do
        local x0 = useG and ph.g0 or ph.t0
        local x1 = useG and ph.g1 or ph.t1
        local sel = {}
        for i = ph.i1, ph.i2 do
            local s = S[i]
            local tt = T(s)
            if tt >= x0 + ph.skip and tt <= x1 + 1e-6 then sel[#sel + 1] = s end
        end
        if #sel >= C.run.MIN_SAMPLES then
            local ts = {}
            local ys = { {}, {}, {}, {}, {}, {} }
            for _, s in ipairs(sel) do
                ts[#ts + 1] = T(s) - tRef
                for k = 1, 3 do ys[k][#ys[k] + 1] = s.v[k]; ys[3 + k][#ys[3 + k] + 1] = s.w[k] end
            end
            local f = { n = #sel, x0 = x0, qm = sel[math.ceil(#sel / 2)].q, mv = {}, cv = {}, mw = {}, cw = {} }
            local ok = true
            for k = 1, 3 do
                local m, c = linfit(ts, ys[k])
                local m2, c2 = linfit(ts, ys[3 + k])
                if not m or not m2 then ok = false; break end
                f.mv[k], f.cv[k], f.mw[k], f.cw[k] = m, c, m2, c2
            end
            if ok then fits[ph.id] = f end
        end
    end
    local res = { name = step.name, group = step.group, level = step.level, lvlKey = step.lvlKey,
                  clk = useG and "game" or "utc", cmp = {}, tpsRatio = (rs > 0) and (gs / rs) or 0 }
    for _, cm in ipairs(step.cmp) do
        local on, base = fits[cm.on], fits[cm.base]
        if on and base then
            local aw, alpha = {}, {}
            for k = 1, 3 do aw[k] = on.mv[k] - base.mv[k]; alpha[k] = on.mw[k] - base.mw[k] end
            local ab = worldToBody(on.qm, aw)
            local r = { a = toRUF(ab), al = toRUF(alpha), n = on.n }
            local dUp = cross(alpha, AX.U)
            r.lF, r.lR, r.yaw = dot(dUp, AX.F), dot(dUp, AX.R), dot(alpha, AX.U)
            r.aMag, r.alMag = norm(ab), norm(alpha)
            r.responded = (r.aMag > C.run.NOISE_A) or (r.alMag > C.run.NOISE_ALPHA)
            local function onset(m1, c1, m0, c0, mag, noise)
                if mag < noise then return nil end
                local best, bk = 0, 1
                for k = 1, 3 do local d = math.abs(m1[k] - m0[k]); if d > best then best, bk = d, k end end
                if best < 1e-9 then return nil end
                local tstar = (c0[bk] - c1[bk]) / (m1[bk] - m0[bk])
                local lat = tstar + tRef - on.x0 + (step.phases[1] and 0 or 0)
                return lat
            end
            -- latency measured from the phase start: on.x0 already includes skip, remove it
            local phOn
            for _, ph in ipairs(step.phases) do if ph.id == cm.on then phOn = ph end end
            local phStart = useG and phOn.g0 or phOn.t0
            local function lat(m1, c1, m0, c0, mag, noise)
                local l = onset(m1, c1, m0, c0, mag, noise)
                if not l then return nil end
                l = l + on.x0 - phStart
                if l < -0.5 or l > (phOn.dur + 0.5) then return nil end
                return l
            end
            r.latLin = lat(on.mv, on.cv, base.mv, base.cv, r.aMag, C.run.NOISE_A)
            r.latAng = lat(on.mw, on.cw, base.mw, base.cw, r.alMag, C.run.NOISE_ALPHA)
            res.cmp[cm.id] = r
        end
    end
    -- total impulse over the whole step (pre end -> tail end)
    local pre, tail = step.phases[1], step.phases[#step.phases]
    local function meanOf(i, key)
        local a, b = S[i], S[i - 1] or S[i]
        if not a then return nil end
        return { (a[key][1] + b[key][1]) / 2, (a[key][2] + b[key][2]) / 2, (a[key][3] + b[key][3]) / 2 }
    end
    local v0, v1 = meanOf(pre.i2, "v"), meanOf(tail.i2, "v")
    local w0, w1 = meanOf(pre.i2, "w"), meanOf(tail.i2, "w")
    local mainPh = fits[step.cmp[#step.cmp].on]
    if v0 and v1 and w0 and w1 and mainPh then
        res.dv = toRUF(worldToBody(mainPh.qm, sub(v1, v0)))
        res.dw = toRUF(sub(w1, w0))
    end
    return res
end

local function fmtLat(x) return x and ("%.2f"):format(x) or "n/a" end

local function logResult(idx, n, res)
    for _, id in ipairs({ "main", "eng", "gim" }) do
        local r = res.cmp[id]
        if r then
            L(("[%d/%d] %s%s | a(R,U,F)=%s m/s2 | al(R,U,F)=%s rad/s2 | dLeanF=%+.3f dLeanR=%+.3f yaw=%+.3f | lat lin=%s ang=%s s | n=%d clk=%s%s"):format(
                idx, n, res.name, (id ~= "main") and (" <" .. id .. ">") or "",
                f3(r.a), f3(r.al), r.lF, r.lR, r.yaw, fmtLat(r.latLin), fmtLat(r.latAng), r.n, res.clk,
                r.responded and "" or "  ** NO RESPONSE **"))
        end
    end
    if res.dv then
        L(("      impulse over step: dv(R,U,F)=%s m/s dw(R,U,F)=%s rad/s"):format(f3(res.dv), f3(res.dw)))
    end
    if not next(res.cmp) then L(("[%d/%d] %s -- NOT ENOUGH SAMPLES (loop too slow?)"):format(idx, n, res.name)) end
end

-- ---------------------------------------------------------------- summary
local FIELDS = { "aR", "aU", "aF", "alR", "alU", "alF", "lF", "lR", "yaw" }
local function flat(r)
    return { aR = r.a.R, aU = r.a.U, aF = r.a.F, alR = r.al.R, alU = r.al.U, alF = r.al.F, lF = r.lF, lR = r.lR, yaw = r.yaw }
end
local function dominant(m)
    local best, name, sign = 0, "-", ""
    local list = { { "R", m.aR }, { "U", m.aU }, { "F", m.aF } }
    local lin = { 0, "none" }
    for _, e in ipairs(list) do if math.abs(e[2]) > lin[1] then lin = { math.abs(e[2]), (e[2] >= 0 and "+" or "-") .. e[1] } end end
    local ang = { 0, "none" }
    for _, e in ipairs({ { "R", m.alR }, { "U", m.alU }, { "F", m.alF } }) do
        if math.abs(e[2]) > ang[1] then ang = { math.abs(e[2]), (e[2] >= 0 and "+" or "-") .. e[1] } end
    end
    return lin[2], ang[2]
end
local function gainOf(points)  -- least squares through origin: m = sum(L*x)/sum(L^2)
    local g, sll = {}, 0
    for _, p in ipairs(points) do sll = sll + p.L * p.L end
    for _, f in ipairs(FIELDS) do
        local s = 0
        for _, p in ipairs(points) do s = s + p.L * p.m[f] end
        g[f] = (sll > 0) and (s / sll) or 0
    end
    return g
end
local function gstr(g)
    return ("lin(R,U,F)=(%+.4f,%+.4f,%+.4f) ang(R,U,F)=(%+.4f,%+.4f,%+.4f) dLeanF=%+.4f dLeanR=%+.4f yaw=%+.4f"):format(
        g.aR, g.aU, g.aF, g.alR, g.alU, g.alF, g.lF, g.lR, g.yaw)
end

local function summary(results)
    L("")
    L("=============== SUMMARY (per 1 level of redstone signal) ===============")
    L("frame: R=" .. C.pose.RIGHT_AXIS .. " U=" .. C.pose.UP_AXIS .. " F=" .. C.pose.FORWARD_AXIS ..
      " (body). lin = m/s2 per level, ang = rad/s2 per level (right-hand rule about axis).")
    L("dLeanF/dLeanR = rate of change of (up vector . fwd/right) per level, same convention as landing script lean.")
    local byKey, order = {}, {}
    local singles = {}
    for _, res in ipairs(results) do
        local r = res.cmp.main
        if r and res.lvlKey and res.group ~= "gimbal" then
            if not byKey[res.lvlKey] then byKey[res.lvlKey] = {}; order[#order + 1] = res.lvlKey end
            table.insert(byKey[res.lvlKey], { L = res.level, m = flat(r), r = r })
        end
    end
    local gains = {}
    for _, key in ipairs(order) do
        local pts = byKey[key]
        local g = gainOf(pts)
        gains[key] = g
        local dl, da = dominant(g)
        local responded = false
        for _, p in ipairs(pts) do if p.r.responded then responded = true end end
        local lin = ""
        if #pts >= 2 then
            table.sort(pts, function(a, b) return a.L < b.L end)
            local lo, hi = pts[1], pts[#pts]
            local function ratio(x, y) if x < 1e-9 then return 0 end return y / x end
            lin = ("  linearity(hi/lo per-level): lin=%.2f ang=%.2f"):format(
                ratio(lo.r.aMag / lo.L, hi.r.aMag / hi.L), ratio(lo.r.alMag / lo.L, hi.r.alMag / hi.L))
        end
        L(("%-7s %s%s"):format(key, responded and ("dom lin=" .. dl .. " ang=" .. da) or "** NO RESPONSE **", lin))
        L("        " .. gstr(g))
    end
    -- pair superposition check
    local first = true
    for _, res in ipairs(results) do
        local r = res.cmp.main
        if r and res.group == "pair" then
            local pk = nil
            for _, st in ipairs(res.pairKeys or {}) do pk = pk end
        end
    end
    -- gimbal
    local gres = {}
    for _, res in ipairs(results) do
        if res.group == "gimbal" and res.cmp.eng and res.cmp.gim then
            gres[res.lvlKey] = gres[res.lvlKey] or {}
            table.insert(gres[res.lvlKey], res)
        end
    end
    local any = false
    for _, d in ipairs({ "gim_n", "gim_s", "gim_w", "gim_e" }) do
        local list = gres[d]
        if list then
            if not any then
                L("")
                L("--- nozzle vector (effect = with gimbal minus engine-only at the same vec level) ---")
                any = true
            end
            local pts = {}
            for _, res in ipairs(list) do
                local e, g = res.cmp.eng, res.cmp.gim
                local tot = { e.a.R + g.a.R, e.a.U + g.a.U, e.a.F + g.a.F }
                local ev = { e.a.R, e.a.U, e.a.F }
                local defl = 0
                if norm(ev) > 1e-6 and norm(tot) > 1e-6 then
                    defl = math.deg(math.acos(clamp(dot(ev, tot) / (norm(ev) * norm(tot)), -1, 1)))
                end
                pts[#pts + 1] = { L = res.level, m = flat(g), defl = defl }
                L(("%s L%d: engine thrust(R,U,F)=%s m/s2 | gimbal effect lin=%s ang=%s | dLeanF=%+.3f dLeanR=%+.3f yaw=%+.3f | thrust deflection=%.1f deg%s"):format(
                    d, res.level, f3(e.a), f3(g.a), f3(g.al), g.lF, g.lR, g.yaw, defl,
                    (e.responded and "" or "  ** ENGINE DID NOT FIRE **")))
            end
            L("   gain/level: " .. gstr(gainOf(pts)))
        end
    end
    L("")
    L("(run id " .. runId .. ")")
end

-- ---------------------------------------------------------------- main
local function main()
    assert(type(sublevel) == "table" and type(sublevel.getLogicalPose) == "function", "sublevel API not found")
    assert(type(sublevel.getAngularVelocity) == "function", "sublevel.getAngularVelocity not available")
    L("SUPERHEAVY CALIBRATION run=" .. runId)
    L("axes: R=" .. C.pose.RIGHT_AXIS .. " U=" .. C.pose.UP_AXIS .. " F=" .. C.pose.FORWARD_AXIS .. "  angvel frame=" .. C.ANGVEL_FRAME)
    L("Craft must be in ZERO-G and free to move. Ctrl+T to abort.")
    for i = C.run.START_DELAY, 1, -1 do
        print(("starting in %d..."):format(i))
        os.sleep(1)
    end
    forceZero()

    -- sampler benchmark: sequential reads vs parallel reads
    local function bench(par)
        PARALLEL_READ = par
        S = {}
        local t, cnt = clock(), 0
        while clock() - t < 1.5 do
            local tl = clock()
            if sampleOnce() then cnt = cnt + 1 end
            if clock() - tl < 0.01 then os.sleep(0) end
        end
        return cnt / 1.5
    end
    local hSeq, hPar = bench(false), bench(true)
    PARALLEL_READ = hPar >= hSeq
    S = {}
    L(("sampler: sequential %.1f Hz, parallel %.1f Hz -> using %s"):format(hSeq, hPar, PARALLEL_READ and "parallel" or "sequential"))

    -- baseline / weightlessness check
    local t0 = clock()
    while clock() - t0 < C.run.BASELINE_TIME do
        local tl = clock()
        sampleOnce()
        if clock() - tl < 0.01 then os.sleep(0) end
    end
    local n = #S
    if n < 4 then error("no pose/velocity samples -- is the computer on the ship?") end
    local ts, vv = {}, { {}, {}, {} }
    local tBase = S[1].t
    for i = 1, n do
        ts[i] = S[i].t - tBase
        for k = 1, 3 do vv[k][i] = S[i].v[k] end
    end
    local aw = {}
    for k = 1, 3 do aw[k] = linfit(ts, vv[k]) or 0 end
    local w = S[n].w
    L(("baseline: |a_world|=%.3f m/s2  |v|=%.2f m/s  |w|=%.3f rad/s  samples=%d (%.1f Hz)"):format(
        norm(aw), norm(S[n].v), norm(w), n, n / math.max(S[n].t - S[1].t, 1e-3)))
    if norm(aw) > C.run.G_ABORT and not C.run.ALLOW_GRAVITY then
        error(("NOT WEIGHTLESS: baseline accel %.2f m/s2 > %.2f. Run in zero-g (or set ALLOW_GRAVITY)."):format(norm(aw), C.run.G_ABORT))
    end

    local hz = n / math.max(S[n].t - S[1].t, 1e-3)
    local steps = buildSteps(hz)
    local results = {}
    for i, step in ipairs(steps) do
        print(("[%d/%d] %s"):format(i, #steps, step.name))
        for _, ph in ipairs(step.phases) do runPhase(ph) end
        applyState({})
        local res, why = analyzeStep(step)
        if res then
            results[#results + 1] = res
            res.pairKeys = step.pairKeys
            logResult(i, #steps, res)
        else
            L(("[%d/%d] %s -- analysis failed: %s"):format(i, #steps, step.name, tostring(why)))
        end
    end
    forceZero()
    summary(results)
    local df = fs.open(dataName, "w")
    if df then df.write(textutils.serialize(results)); df.close() end
    L("files: " .. logName .. "  " .. dataName)
end

local ok, err = pcall(main)
forceZero()
if not ok then L("!!! ABORTED: " .. tostring(err)) end
if logFile then logFile.close() end
if rawFile then rawFile.close() end