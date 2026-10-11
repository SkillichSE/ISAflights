-- guidance.lua  (stage 2)
-- Pure math, no peripherals. stage2.lua calls this every tick.
--
-- Stage 2 steering by gimbal. Above ~5000 blocks gravity is ~0 but the stage is slowed by drag
-- (v' = -K_DRAG*v, measured). After cutoff it flies a straight line and stops v/K_DRAG blocks later.
-- So: reach v = K_DRAG*(range - STOP_SHORT) exactly along the line to the hold point, kill sideways
-- speed, cut off. Thrust direction is the body up axis, the gimbal leans the stage, stage2.lua's
-- attitude loop follows the commanded lean (same convention as launch.lua).
--   a_thrust = KV*(v_desired - v) + g + K_DRAG*v

local G = {}

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end
local function len3(x, y, z) return math.sqrt(x * x + y * y + z * z) end

function G.gravityAt(tbl, alt)
    if alt <= tbl[1][1] then return tbl[1][2] end
    for i = 2, #tbl do
        local a, b = tbl[i - 1], tbl[i]
        if alt <= b[1] then return a[2] + (b[2] - a[2]) * (alt - a[1]) / (b[1] - a[1]) end
    end
    return 0
end

-- one guidance solution, no state
-- Real flight data (stage2.log): above ~5000 blocks the stage is NOT in vacuum, speed decays like
-- v' = -K_DRAG * v (K_DRAG ~ 0.0103 1/s, same at 6000 and at 15000). Gravity there is ~0.
-- So after cutoff the stage coasts in a straight line and stops after  v / K_DRAG  blocks.
-- To stop STOP_SHORT before the hold point we need   v_desired = K_DRAG * (range - STOP_SHORT) * u.
function G.steer(pos, vel, hold, N, g, tPerLevel)
    local dx, dy, dz = hold.x - pos.x, hold.y - pos.y, hold.z - pos.z
    local range = math.max(len3(dx, dy, dz), 1)
    local ux, uy, uz = dx / range, dy / range, dz / range
    local dStop = math.max(range - N.STOP_SHORT, 50)
    local vReq = N.K_DRAG * dStop
    local va = vel.x * ux + vel.y * uy + vel.z * uz
    local lx0, ly0, lz0 = vel.x - va * ux, vel.y - va * uy, vel.z - va * uz
    local lat = len3(lx0, ly0, lz0)
    -- the engine can only push: never ask for braking, if we are already too fast only fix the sideways part
    local vd = math.max(vReq, va)
    local ex = ux * vd - vel.x
    local ey = uy * vd - vel.y
    local ez = uz * vd - vel.z
    local cx, cy, cz = N.KV * ex, N.KV * ey, N.KV * ez
    local cm = len3(cx, cy, cz)
    if cm > N.A_MAX then
        local k = N.A_MAX / cm
        cx, cy, cz = cx * k, cy * k, cz * k
    end
    -- feed-forward after the cap: gravity and drag must not starve the correction
    local fd = (va < vReq) and N.K_DRAG or 0   -- already too fast: do not hold the speed up against drag
    local tx, ty, tz = cx + fd * vel.x, cy + g + fd * vel.y, cz + fd * vel.z
    local tm = len3(tx, ty, tz)
    local dirx, diry, dirz = 0, 1, 0
    if tm > 1e-6 then dirx, diry, dirz = tx / tm, ty / tm, tz / tm end
    local lx, lz = dirx, dirz
    -- below the gravity zone keep the stage mostly upright, above it it can lean harder
    local tilt = (g > 0.5) and N.TILT_MAX_DEG or N.TILT_MAX_DEG_HIGH
    local maxLean = math.sin(math.rad(tilt))
    local lm = math.sqrt(lx * lx + lz * lz)
    if lm > maxLean then lx, lz = lx * maxLean / lm, lz * maxLean / lm end
    -- magnitude as wanted. If the lean is capped the direction is only approximate, but thrust must
    -- not grow to compensate: the stage cannot push down, extra thrust would only add speed along the line.
    local level = tm / tPerLevel
    return {
        lx = lx, lz = lz,
        level = clamp(level, N.LEVEL_MIN, N.LEVEL_MAX),
        accel = tm, range = range,
        va = va, lat = lat, vReq = vReq,
        eAlong = math.max(vReq - va, 0), over = math.max(va - vReq, 0),
        dv = len3(lat, math.max(vReq - va, 0), 0),
        ux = ux, uy = uy, uz = uz,
    }
end

-- burn state: lean slew, thrust-per-level estimator, cutoff timer
function G.newBurn(N, hold)
    local b = {
        N = N, hold = hold,
        tEst = N.T_PER_LEVEL, estN = 0,
        navLx = 0, navLz = 0,
        holdT = 0, lastLevel = 0, minMiss = nil, missN = 0,
        win = nil,
    }

    function b:step(pos, vel, up, rdt)
        local alt = pos.y - self.N.PAD_Y
        local g = G.gravityAt(self.N.GRAVITY_TABLE, alt)

        -- measure real acceleration per level over ~1 s windows (the velocity api is coarse)
        local w = self.win
        if not w then
            w = { t = 0, lvl = 0, vx = vel.x, vy = vel.y, vz = vel.z }
            self.win = w
        end
        w.t = w.t + rdt
        w.lvl = w.lvl + self.lastLevel * rdt
        if w.t >= self.N.EST_WINDOW then
            local lvlAvg = w.lvl / w.t
            if lvlAvg >= 1.0 then
                local kd = self.N.K_DRAG
                local ax = (vel.x - w.vx) / w.t + kd * (vel.x + w.vx) * 0.5
                local ay = (vel.y - w.vy) / w.t + g + kd * (vel.y + w.vy) * 0.5
                local az = (vel.z - w.vz) / w.t + kd * (vel.z + w.vz) * 0.5
                local along = ax * up.x + ay * up.y + az * up.z
                local est = clamp(along / lvlAvg, 0.2 * self.N.T_PER_LEVEL, 6 * self.N.T_PER_LEVEL)
                self.tEst = self.tEst + (est - self.tEst) * 0.6
                self.estN = self.estN + 1
            end
            self.win = nil
        end

        local s = G.steer(pos, vel, self.hold, self.N, g, self.tEst)

        local dlx, dlz = s.lx - self.navLx, s.lz - self.navLz
        local dm = math.sqrt(dlx * dlx + dlz * dlz)
        local step = self.N.LEAN_SLEW * rdt
        if dm > step and dm > 1e-9 then dlx, dlz = dlx * step / dm, dlz * step / dm end
        self.navLx, self.navLz = self.navLx + dlx, self.navLz + dlz

        -- ready: speed along the line is enough AND sideways speed is gone (miss = lat / K_DRAG blocks).
        -- too fast already (over) cannot be braked, so then only the sideways part is worth fixing.
        local ready = s.eAlong <= self.N.ALONG_TOL and s.lat <= self.N.LAT_TOL
        -- too fast: more thrust only makes it worse, BUT only cut off if the sideways speed is already small.
        -- (rev65: before, this bypass ignored lat and cut off with 80 m/s sideways -> stage 2 stopped ~5 km off the hold point)
        if s.over > self.N.OVER_TOL and s.lat <= (self.N.LAT_OVER_TOL or self.N.LAT_TOL * 5) then ready = true end
        -- ballistic cutoff: after cutoff the stage coasts in a straight line and stops at pos + vel/K_DRAG.
        -- Cut when that stop point is close to the hold point, or when it has passed its best and is moving away
        -- (the engine cannot push back, so burning longer only makes the miss bigger).
        local K = self.N.K_DRAG
        -- the guidance aims to stop STOP_SHORT before the hold point (on the line from the stage), so measure the miss against that point
        local hx, hy, hz = self.hold.x - pos.x, self.hold.y - pos.y, self.hold.z - pos.z
        local hl = math.max(len3(hx, hy, hz), 1)
        local sh = math.min(self.N.STOP_SHORT or 0, hl)
        local tx, ty, tz = self.hold.x - hx / hl * sh, self.hold.y - hy / hl * sh, self.hold.z - hz / hl * sh
        local mx, my, mz = tx - (pos.x + vel.x / K), ty - (pos.y + vel.y / K), tz - (pos.z + vel.z / K)
        local miss = len3(mx, my, mz)
        if not self.minMiss or miss < self.minMiss then self.minMiss = miss end
        if alt >= self.N.MIN_CUTOFF_ALT and (vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0) then
            if miss <= (self.N.MISS_OK or 150) or miss > self.minMiss + (self.N.MISS_GROW or 150) then
                self.missN = (self.missN or 0) + 1
            else
                self.missN = 0
            end
            if self.missN >= 3 then ready = true end
        end
        if ready and alt >= self.N.MIN_CUTOFF_ALT then
            self.holdT = self.holdT + rdt
        else
            self.holdT = 0
        end

        -- until thrust per level has been measured once, do not trust the first-guess value with a big level
        local level = s.level
        if self.estN == 0 and level > self.N.LEVEL_FIRST then level = self.N.LEVEL_FIRST end
        self.lastLevel = level
        return {
            lx = self.navLx, lz = self.navLz, level = level,
            cutoff = (self.missN >= 3) or self.holdT >= self.N.DV_HOLD_TIME, miss = miss,
            dv = s.dv, lat = s.lat, va = s.va, vReq = s.vReq, range = s.range, alt = alt, g = g, tEst = self.tEst,
            over = s.over,
            ux = s.ux, uy = s.uy, uz = s.uz,
        }
    end

    return b
end

-- how far from the hold point the craft must be cut loose so it can still flip, brake and self-check
function G.sepRange(speed, S)
    local r = speed * (S.FLIP_T + S.SELFCHECK_T) + speed * speed / (2 * S.A_BRAKE) + S.MARGIN
    return clamp(r, S.MIN_RANGE, S.MAX_RANGE)
end

return G