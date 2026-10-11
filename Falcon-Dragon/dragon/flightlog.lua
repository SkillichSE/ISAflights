-- flightlog.lua
-- writes a plain CSV log to disk during flight, since report() only sends
-- telemetry over the radio and nothing was ever saved to a file. flush()
-- after every line so if the ship gets tumbled/killed mid-flight, whatever
-- was logged up to that point is still on disk to look at afterwards.

local flightlog = {}
local LOG_FILE = "flight_log.csv"
local handle

-- starts a fresh log for this flight (old one is not appended to - rename/copy
-- it first with `cp flight_log.csv flight_log_old.csv` in the shell if you
-- want to keep a previous run before starting a new one)
function flightlog.init()
    handle = fs.open(LOG_FILE, "w")
    if handle then
        handle.writeLine("t,phase,x,y,z,vx,vy,vz,pitch,yaw,roll,dist,dx,dy,dz,note")
        handle.flush()
    end
end

-- one CSV row. note is optional (e.g. "ERROR: ..."), pass "" if nothing to add
function flightlog.log(phase, pos, vel, pitch, yaw, roll, dist, delta, note)
    if not handle then return end
    local ok = pcall(function()
        handle.writeLine(string.format(
            "%.2f,%s,%.1f,%.1f,%.1f,%.2f,%.2f,%.2f,%.3f,%.3f,%.3f,%.1f,%.2f,%.2f,%.2f,%s",
            os.clock(), phase,
            pos.x, pos.y, pos.z,
            vel.x, vel.y, vel.z,
            pitch, yaw, roll,
            dist or -1,
            delta and delta.x or 0, delta and delta.y or 0, delta and delta.z or 0,
            note or ""
        ))
        handle.flush()
    end)
    if not ok then
        -- logging must never be the thing that kills the flight
        pcall(function() handle = nil end)
    end
end

-- freeform line for things that don't fit the pose row (e.g. a raw error message)
function flightlog.note(text)
    if not handle then return end
    pcall(function()
        handle.writeLine(string.format("%.2f,NOTE,,,,,,,,,,,,,,%s", os.clock(), text))
        handle.flush()
    end)
end

function flightlog.close()
    if handle then
        pcall(function() handle.close() end)
        handle = nil
    end
end

return flightlog