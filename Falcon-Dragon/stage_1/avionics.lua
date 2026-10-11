local M = {}

function M.clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
function M.round(v) return math.floor(v + 0.5) end
function M.len2(x, z) return math.sqrt(x*x + z*z) end
function M.angleDiff(a, b) return ((a - b + 180) % 360) - 180 end

M.pose = { UP_AXIS = "+Y", FORWARD_AXIS = "+Z", RIGHT_AXIS = "+X" }
function M.setPose(p) M.pose = p end

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
    return { x=x/l, y=y/l, z=z/l, w=w/l }
end

local function rotateBodyToWorld(qq, x, y, z)
    local qx, qy, qz, qw = qq.x, qq.y, qq.z, qq.w
    local tx = 2*(qy*z - qz*y)
    local ty = 2*(qz*x - qx*z)
    local tz = 2*(qx*y - qy*x)
    return x + qw*tx + (qy*tz - qz*ty),
           y + qw*ty + (qz*tx - qx*tz),
           z + qw*tz + (qx*ty - qy*tx)
end

local AXIS_VEC = { ["+X"]={1,0,0}, ["-X"]={-1,0,0}, ["+Y"]={0,1,0},
                   ["-Y"]={0,-1,0}, ["+Z"]={0,0,1}, ["-Z"]={0,0,-1} }
local function worldAxis(qq, name)
    local v = AXIS_VEC[name]
    if not v then return nil end
    return rotateBodyToWorld(qq, v[1], v[2], v[3])
end

local function horizUnit(x, z)
    local l = M.len2(x, z)
    if l < 1e-9 then return nil end
    return x/l, z/l, l
end

function M.hasSable()
    return type(sublevel) == "table" and type(sublevel.getLogicalPose) == "function"
end

function M.readAttitude()
    if not M.hasSable() then return nil end
    local ok, pose = pcall(sublevel.getLogicalPose)
    if not ok or type(pose) ~= "table" or not pose.orientation then return nil end
    local qq = extractQuaternion(pose.orientation)
    if not qq then return nil end
    local ux, uy, uz = worldAxis(qq, M.pose.UP_AXIS)
    local fx, _, fz  = worldAxis(qq, M.pose.FORWARD_AXIS)
    local rx, _, rz  = worldAxis(qq, M.pose.RIGHT_AXIS)
    local fhx, fhz = horizUnit(fx, fz)
    local rhx, rhz = horizUnit(rx, rz)
    if not fhx or not rhx then return nil end
    local px, py, pz
    if type(pose.position) == "table" then
        px = tonumber(pose.position.x)
        py = tonumber(pose.position.y)
        pz = tonumber(pose.position.z)
    end
    return {
        qq      = qq,
        up      = { x=ux, y=uy, z=uz },
        fwd     = { x=fhx, z=fhz },
        right   = { x=rhx, z=rhz },
        heading = math.deg(math.atan2(fhx, fhz)),
        tiltDeg = math.deg(math.acos(M.clamp(uy, -1, 1))),
        pos     = { x=px, y=py, z=pz },
        posY    = py,
    }
end

function M.readVelocity()
    if type(sublevel) ~= "table" or type(sublevel.getLinearVelocity) ~= "function" then return nil end
    local ok, v = pcall(sublevel.getLinearVelocity)
    if ok and type(v) == "table" then
        return { x=tonumber(v.x) or 0, y=tonumber(v.y) or 0, z=tonumber(v.z) or 0 }
    end
    return nil
end

function M.readAngularVelocity()
    if type(sublevel) ~= "table" or type(sublevel.getAngularVelocity) ~= "function" then return nil end
    local ok, w = pcall(sublevel.getAngularVelocity)
    if ok and type(w) == "table" then
        return { x=tonumber(w.x) or 0, y=tonumber(w.y) or 0, z=tonumber(w.z) or 0 }
    end
    return nil
end

function M.readAngularVelocityWorld(att)
    local w = M.readAngularVelocity()
    if not w or not att or not att.qq then return nil end
    local x, y, z = rotateBodyToWorld(att.qq, w.x, w.y, w.z)
    return { x=x, y=y, z=z }
end

function M.yawRate(att, angVel)
    if not angVel or not att or not att.up then return 0 end
    return angVel.x*att.up.x + angVel.y*att.up.y + angVel.z*att.up.z
end

function M.upRate(att, angVel)
    return angVel.y*att.up.z - angVel.z*att.up.y,
           angVel.x*att.up.y - angVel.y*att.up.x
end

local bridge

function M.initBridge(timeout, interval)
    timeout = timeout or 5.0
    interval = interval or 0.25
    local waited = 0
    while not bridge and waited < timeout do
        bridge = peripheral.find("redstone_link_bridge")
        if not bridge then
            os.sleep(interval)
            waited = waited + interval
        end
    end
    if not bridge then
        return false, "redstone_link_bridge not found after " .. timeout .. "s"
    end
    M.bridge = bridge
    return true
end

local dryRun = false
function M.setDryRun(v) dryRun = v end

local sendCache = {}
local pending, order = {}, {}

function M.sendLink(pair, level)
    if dryRun then return end
    level = M.clamp(M.round(level), 0, 15)
    if sendCache[pair] == level then return end
    sendCache[pair] = level
    if pending[pair] == nil then order[#order + 1] = pair end
    pending[pair] = level
end

local unpackFn = table.unpack or unpack

function M.flush()
    local n = #order
    if n == 0 then return end
    local ord, lv = order, pending
    order, pending = {}, {}
    if n == 1 then
        local pr = ord[1]
        local ok, err = pcall(bridge.sendLinkSignal, pr[1], pr[2], lv[pr])
        if not ok then
            sendCache[pr] = nil
            error(err, 0)
        end
        return
    end
    local fns = {}
    for i = 1, n do
        local pr, l = ord[i], lv[ord[i]]
        fns[i] = function() bridge.sendLinkSignal(pr[1], pr[2], l) end
    end
    local ok, err = pcall(parallel.waitForAll, unpackFn(fns))
    if not ok then
        for i = 1, n do sendCache[ord[i]] = nil end
        error(err, 0)
    end
end

function M.getLink(pair)
    local ok, signal = pcall(bridge.getLinkSignal, pair[1], pair[2])
    if not ok or signal == nil then return 0 end
    return signal
end

function M.newTelemetry(cfg)
    local t = { cfg = cfg, ws = nil, lastAttempt = 0, sendTimer = 0, sentCount = 0 }

    local function connect(logFn)
        local now = os.epoch("utc") / 1000
        if now - t.lastAttempt < t.cfg.RECONNECT_INTERVAL then return end
        t.lastAttempt = now
        local url = "ws://" .. t.cfg.RELAY_HOST .. t.cfg.RELAY_PATH
        local ok, handle, err = pcall(http.websocket, url)
        if ok and handle and handle ~= false then
            t.ws = handle
            if logFn then logFn("telemetry: connected to " .. url) end
        else
            t.ws = nil
            local reason = (not ok and handle) or err or "unknown error"
            if logFn then logFn("telemetry: connect failed to " .. url .. " -- " .. tostring(reason)) end
        end
    end

    function t:send(rdtNow, payloadFn, logFn)
        if not self.cfg.ENABLE then return end
        if not self.ws then
            connect(logFn)
            if not self.ws then return end
        end
        self.sendTimer = self.sendTimer + rdtNow
        if self.sendTimer < self.cfg.SEND_INTERVAL then return end
        self.sendTimer = 0
        local payload = textutils.serializeJSON(payloadFn())
        local ok = pcall(self.ws.send, payload)
        if not ok then
            pcall(self.ws.close)
            if logFn then logFn("telemetry: send failed, will reconnect") end
            self.ws = nil
        else
            self.sentCount = self.sentCount + 1
        end
    end

    return t
end

function M.newGForceTracker(gravity)
    local g = { gravity = gravity, smoothed = 0, prevX = nil, prevY = nil, prevZ = nil }
    function g:update(vel, rdtNow)
        if not vel then return self.smoothed end
        if not self.prevX then
            self.prevX, self.prevY, self.prevZ = vel.x, vel.y, vel.z
            return self.smoothed
        end
        local ax = (vel.x - self.prevX) / rdtNow
        local ay = (vel.y - self.prevY) / rdtNow + self.gravity
        local az = (vel.z - self.prevZ) / rdtNow
        self.prevX, self.prevY, self.prevZ = vel.x, vel.y, vel.z
        local mag = math.sqrt(ax*ax + ay*ay + az*az)
        self.smoothed = self.smoothed + (mag / self.gravity - self.smoothed) * 0.3
        return self.smoothed
    end
    return g
end

return M
