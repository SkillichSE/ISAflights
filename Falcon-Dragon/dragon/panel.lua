local oldX, oldY, oldZ = nil, nil, nil
local oldVel = 0
local shipName = "CrewDemo-1"
local flash = nil
local needsClear = true -- full clear only on the first frame and after a failure, not every second

-- os.time() is game time, it jumps around; the T+ timer runs on os.clock() and ticks evenly
local startClock = os.clock()
local function metString()
    local elapsed = math.floor(os.clock() - startClock)
    local hh = math.floor(elapsed / 3600)
    local mm = math.floor((elapsed % 3600) / 60)
    local ss = elapsed % 60
    return string.format("T+%02d:%02d:%02d", hh, mm, ss)
end

-- only buttons that actually do something for the autopilot:
-- ABORT is caught by main.lua's waitTick() and kills the flight;
-- DOCK toggles the same frequency pair thrusters.lua uses for "dock"
local buttons = {
    { label = "ABORT", color = colors.red,   cmd = "ABORT", col = 1 },
    { label = "AP",    color = colors.cyan,  cmd = "AP",    col = 2 }, -- pauses/resumes main.lua's autopilot, state comes back as APSTATE on channel 52
    { label = "DOCK",  color = colors.lime,  cmd = "DOCK",  col = 3, link = { "minecraft:dispenser", "minecraft:sea_lantern" } },
}

-- 51 - panel sends ABORT to main.lua, 52 - main.lua sends status/target/errors here
local PANEL_CHANNEL = 51
local AUTOPILOT_CHANNEL = 52
local lastPhase, lastDistance, lastAutopilotTime = nil, nil, 0
local lastError, lastErrorTime = nil, 0
local dockingTarget = nil
local apActive = false -- true once main.lua confirms the autopilot is actively flying (not paused)
pcall(function()
    local modem = peripheral.find("modem") or error("no modem")
    modem.open(AUTOPILOT_CHANNEL)
end)

-- check the actual signal state on the bridge instead of guessing from a local flag
local function isLinkActive(freqA, freqB)
    local ok, result = pcall(function()
        local bridge = peripheral.find("redstone_link_bridge") or error("no redstone_link_bridge peripheral found")
        return (bridge.getLinkSignal(freqA, freqB) or 0) > 0
    end)
    if ok then return result end
    return false
end

-- sends a command and toggles the signal on this frequency pair, used by buttons with a link field
local function toggleLink(freqA, freqB)
    local currentlyActive = isLinkActive(freqA, freqB)
    local newState = not currentlyActive
    local ok, err = pcall(function()
        local bridge = peripheral.find("redstone_link_bridge") or error("no redstone_link_bridge peripheral found")
        bridge.sendLinkSignal(freqA, freqB, newState and 15 or 0)
    end)
    if not ok then
        print("[link error] " .. tostring(err))
    end
    return newState
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- PWR/FUEL are real peripherals (energy_storage/fluid_storage)

local function readPower()
    local ok, pct = pcall(function()
        local cell = peripheral.find("energy_storage") or error("no energy_storage")
        local cap = cell.getEnergyCapacity()
        if not cap or cap <= 0 then return 0 end
        return cell.getEnergy() / cap * 100
    end)
    if ok then return clamp(pct, 0, 100) end
    return nil
end

local function readFuel()
    local ok, pct = pcall(function()
        local tank = peripheral.find("fluid_storage") or error("no fluid_storage")
        local tanks = tank.tanks()
        local amount, capacity = 0, 0
        for _, t in pairs(tanks) do
            amount = amount + (t.amount or 0)
            capacity = capacity + (t.capacity or 0)
        end
        if capacity <= 0 then return 0 end
        return amount / capacity * 100
    end)
    if ok then return clamp(pct, 0, 100) end
    return nil
end

-- writes text padded with spaces to the column width, no leftover residue from old text
local function writeClipped(monitor, x, y, w, text, color)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(color)
    local padded = text .. string.rep(" ", math.max(0, w - #text))
    monitor.write(string.sub(padded, 1, w))
end

-- gauge bar: label, filled portion in fillColor, remainder in gray, number at the end
local function drawGauge(monitor, x, y, w, label, pct, fillColor)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.write(label)

    local barX = x + #label + 1
    local barWidth = w - #label - 6 -- room for " 100%"
    if barWidth < 1 then barWidth = 1 end
    local filled = math.floor(barWidth * clamp(pct or 0, 0, 100) / 100 + 0.5)

    monitor.setCursorPos(barX, y)
    monitor.setBackgroundColor(fillColor)
    monitor.write(string.rep(" ", filled))
    monitor.setBackgroundColor(colors.gray)
    monitor.write(string.rep(" ", barWidth - filled))
    monitor.setBackgroundColor(colors.black)

    local text = pct and string.format(" %3.0f%%", pct) or "  N/A"
    monitor.setCursorPos(barX + barWidth, y)
    monitor.setTextColor(pct and colors.white or colors.gray)
    monitor.write(text)
end

local function getAttitude()
    local ok, pose = pcall(function() return sublevel.getLogicalPose() end)
    if not ok or not pose then return nil end
    -- toEuler() returns three loose numbers (pitch, yaw, roll) on this build,
    -- not a {x,y,z} table - grab all three instead of just the first.
    local ok2, a, b, c = pcall(function() return pose.orientation:toEuler() end)
    if not ok2 then return nil end
    if type(a) == "table" then
        return a
    end
    return { x = a, y = b, z = c }
end

-- one button per column stretches to full height, several share it evenly
local function drawColumnButtons(monitor, colButtons, x, w, btnStartY, areaRows)
    local n = #colButtons
    if n == 0 then return end
    local rowsEach = math.max(1, math.floor(areaRows / n))
    for i, b in ipairs(colButtons) do
        local by = btnStartY + (i - 1) * rowsEach
        local isActive = (b.link and isLinkActive(b.link[1], b.link[2])) or (b.cmd == "AP" and apActive)
        local bg
        if flash == b then
            bg = colors.white
        elseif isActive then
            bg = colors.white
        else
            bg = b.color
        end
        local fg = isActive and b.color or colors.black
        for r = 0, rowsEach - 1 do
            monitor.setCursorPos(x, by + r)
            monitor.setBackgroundColor(bg)
            monitor.write(string.rep(" ", w))
        end
        local label = b.label .. (isActive and "*" or "")
        monitor.setCursorPos(x + math.max(0, math.floor((w - #label) / 2)), by + math.floor(rowsEach / 2))
        monitor.setTextColor(fg)
        monitor.write(label)
    end
    monitor.setBackgroundColor(colors.black)
end

local function draw()
    local ok, err = pcall(function()
        local monitor = peripheral.find("monitor") or error("no monitor")
        local modem = peripheral.find("modem") or error("no modem")
        monitor.setTextScale(0.5) -- as small as it can go, so 3 full zones fit on a 3-block monitor
        local w, h = monitor.getSize()
        monitor.setBackgroundColor(colors.black)
        if needsClear then
            monitor.clear()
            needsClear = false
        end

        -- 3 equal columns, the last one takes the remainder of the division
        local colW = math.floor(w / 3)
        local colX = { 1, colW + 1, 2 * colW + 1 }
        local colWidth = { colW, colW, w - 2 * colW }

        -- reserve height at the bottom for the column with the most buttons (currently DOCKING with three)
        local maxButtons = 1
        for _, b in ipairs(buttons) do
            local n = 0
            for _, b2 in ipairs(buttons) do if b2.col == b.col then n = n + 1 end end
            if n > maxButtons then maxButtons = n end
        end
        local btnRowH = math.max(1, math.floor(h * 0.09))
        local btnAreaRows = btnRowH * maxButtons
        local btnStartY = h - btnAreaRows + 1

        local x, y, z = gps.locate(5)
        local velocity, dv = 0, 0
        if x and oldX then
            velocity = math.sqrt((x - oldX) ^ 2 + (y - oldY) ^ 2 + (z - oldZ) ^ 2)
            dv = velocity - oldVel
        end
        local euler = getAttitude()
        local status, statusColor = "NOMINAL", colors.lime
        if velocity > 40 then
            status, statusColor = "HIGH VELOCITY", colors.red
        elseif math.abs(dv) > 10 then
            status, statusColor = "UNSTABLE DV", colors.orange
        end
        if x then
            pcall(modem.transmit, 60, 50, string.format("%s|%.0f %.0f %.0f|%.1f|%.1f", shipName, x, y, z, velocity, dv))
        end
        oldX, oldY, oldZ, oldVel = x, y, z, velocity

        -- column 1: pilot/nav data (no header, straight into the readout)
        local c1 = colX[1]
        writeClipped(monitor, c1, 1, colWidth[1], shipName .. " " .. metString(), colors.white)
        if x then
            writeClipped(monitor, c1, 2, colWidth[1], string.format("X%.0f Y%.0f Z%.0f", x, y, z), colors.white)
            writeClipped(monitor, c1, 3, colWidth[1], string.format("VEL %.1f DV %.1f", velocity, dv), colors.orange)
        else
            writeClipped(monitor, c1, 2, colWidth[1], "NO GPS SIGNAL", colors.red)
        end
        if euler then
            writeClipped(monitor, c1, 4, colWidth[1], string.format("P%.0f Y%.0f R%.0f", euler.x, euler.y, euler.z), colors.lightBlue)
        end
        writeClipped(monitor, c1, 5, colWidth[1], status, statusColor)

        -- column 2: power/fuel gauges (only real peripheral data, no header)
        local c2 = colX[2]
        drawGauge(monitor, c2, 1, colWidth[2], "PWR",  readPower(), colors.blue)
        drawGauge(monitor, c2, 2, colWidth[2], "FUEL", readFuel(), colors.orange)
        if lastError and (os.clock() - lastErrorTime) < 30 then
            writeClipped(monitor, c2, 3, colWidth[2], "ERR: " .. lastError, colors.red)
        else
            writeClipped(monitor, c2, 3, colWidth[2], "no errors", colors.gray)
        end

        -- column 3: docking status (no header)
        local c3 = colX[3]
        if dockingTarget then
            writeClipped(monitor, c3, 1, colWidth[3], string.format("TGT %.0f/%.0f/%.0f", dockingTarget.x, dockingTarget.y, dockingTarget.z), colors.white)
        else
            writeClipped(monitor, c3, 1, colWidth[3], "TGT: unknown", colors.gray)
        end
        if lastPhase and (os.clock() - lastAutopilotTime) < 5 then
            writeClipped(monitor, c3, 2, colWidth[3], "PHASE " .. lastPhase, colors.magenta)
            if lastDistance then
                writeClipped(monitor, c3, 3, colWidth[3], string.format("DIST %.1f m", lastDistance), colors.magenta)
            end
        else
            writeClipped(monitor, c3, 2, colWidth[3], "AUTOPILOT OFFLINE", colors.gray)
        end

        for i = 1, 3 do
            drawColumnButtons(monitor, (function()
                local list = {}
                for _, b in ipairs(buttons) do if b.col == i then table.insert(list, b) end end
                return list
            end)(), colX[i], colWidth[i], btnStartY, btnAreaRows)
        end
    end)
    if not ok then
        needsClear = true -- the next successful frame must clear "RECONNECTING..." entirely
        pcall(function()
            local monitor = peripheral.find("monitor")
            if monitor then
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                monitor.setCursorPos(1, 1)
                monitor.setTextColor(colors.red)
                monitor.write("RECONNECTING...")
            end
        end)
    end
end

draw()
local timer = os.startTimer(1)
while true do
    local event, p1, p2, p3, p4 = os.pullEvent()
    if event == "timer" and p1 == timer then
        draw()
        timer = os.startTimer(1)
    elseif event == "modem_message" then
        local channel, message = p2, p4
        if channel == AUTOPILOT_CHANNEL and type(message) == "string" then
            local parts = {}
            for part in string.gmatch(message, "[^|]+") do table.insert(parts, part) end
            if parts[1] == "TARGET" then
                dockingTarget = { x = tonumber(parts[2]), y = tonumber(parts[3]), z = tonumber(parts[4]) }
            elseif parts[1] == "ERROR" then
                lastError = parts[2] or message
                lastErrorTime = os.clock()
            elseif parts[1] == "APSTATE" then
                apActive = (parts[2] == "ON")
            else
                lastPhase = parts[1]
                lastDistance = tonumber(parts[2])
                lastAutopilotTime = os.clock()
            end
        end
    elseif event == "monitor_touch" then
        local ok = pcall(function()
            local monitor = peripheral.find("monitor") or error("no monitor")
            local modem = peripheral.find("modem") or error("no modem")
            local w, h = monitor.getSize()
            local colW = math.floor(w / 3)
            local touchX, touchY = p2, p3

            local col = 1
            if touchX > 2 * colW then col = 3
            elseif touchX > colW then col = 2 end

            local maxButtons = 1
            for _, b in ipairs(buttons) do
                local n = 0
                for _, b2 in ipairs(buttons) do if b2.col == b.col then n = n + 1 end end
                if n > maxButtons then maxButtons = n end
            end
            local btnRowH = math.max(1, math.floor(h * 0.09))
            local btnAreaRows = btnRowH * maxButtons
            local btnStartY = h - btnAreaRows + 1

            if touchY >= btnStartY then
                local colButtons = {}
                for _, b in ipairs(buttons) do if b.col == col then table.insert(colButtons, b) end end
                local rowsEach = math.max(1, math.floor(btnAreaRows / math.max(1, #colButtons)))
                local index = math.min(#colButtons, math.floor((touchY - btnStartY) / rowsEach) + 1)
                local b = colButtons[index]
                if b then
                    flash = b
                    draw()
                    pcall(modem.transmit, PANEL_CHANNEL, 50, b.cmd)
                    local held = false
                    if b.link then
                        held = toggleLink(b.link[1], b.link[2])
                    end
                    sleep(0.15)
                    flash = held and b or nil
                    draw()
                end
            end
        end)
    end
end