-- thrusters.lua
-- thruster control via Redstone Link Bridge (CC: Tweaked)
-- the bridge sends/reads a signal over a pair of item frequencies (bridge.sendLinkSignal / getLinkSignal)
-- frequencies are set by the Redstone Link blocks placed on the ship itself

local thrusters = {}

-- frequency pairs, one per direction used by main.lua
local FREQ = {
    main        = {"minecraft:bone_meal", "minecraft:crying_obsidian"},

    pitch_up    = {"minecraft:pointed_dripstone", "minecraft:sculk_sensor"},
    pitch_down  = {"minecraft:bread", "create:cogwheel"},
    yaw_left    = {"minecraft:rabbit", "minecraft:tnt_minecart"},
    yaw_right   = {"minecraft:mossy_stone_bricks", "minecraft:sculk_shrieker"},
    roll_cw     = {"minecraft:tropical_fish", "minecraft:dried_kelp"},
    roll_ccw    = {"minecraft:heavy_core", "minecraft:glistering_melon_slice"},

    dash_left   = {"simulated:velocity_sensor", "simulated:gyroscopic_mechanism"},
    dash_right  = {"create_connected:cross_connector", "simulated:engine_assembly"},
    dash_up     = {"rocketnautics:copper_nozzle", "aeronautics:end_stone_powder"},
    dash_down   = {"create:industrial_iron_block", "rocketnautics:titanium_ingot"},

    dock        = {"minecraft:dispenser", "minecraft:sea_lantern"}, -- same pair as the DOCK button on the panel

    -- vectoring thrusters mounted on the main engine, not currently used by main.lua
    main_yaw_left   = {"minecraft:bamboo_mosaic_slab", "minecraft:grindstone"},
    main_yaw_right  = {"minecraft:suspicious_gravel", "minecraft:torchflower_seeds"},
    main_pitch_up   = {"simulated:spring", "createpropulsion:platinum_ingot"},
    main_pitch_down = {"tfmg:resistor", "railways:maroon_hinged_locometal_door"},
}

thrusters.FREQ = FREQ

local bridge
local cache = {}

function thrusters.init()
    bridge = peripheral.find("redstone_link_bridge")
    assert(bridge, "redstone_link_bridge not found, check the bridge is connected to the computer")
    return true
end

-- set thrust on a direction (0-15), holds until you reset it back to 0 yourself
function thrusters.set(direction, strength)
    local pair = FREQ[direction]
    if not pair then
        error("no frequency pair for direction '" .. tostring(direction) .. "', check FREQ")
    end
    bridge.sendLinkSignal(pair[1], pair[2], strength or 0)
end

-- read the current signal on a direction, for debugging
function thrusters.get(direction)
    local pair = FREQ[direction]
    if not pair then
        error("no frequency pair for direction '" .. tostring(direction) .. "'")
    end
    return bridge.getLinkSignal(pair[1], pair[2])
end

-- short thrust pulse for a given duration
function thrusters.burn(direction, strength, duration)
    thrusters.set(direction, strength or 15)
    sleep(duration or 0.2)
    thrusters.set(direction, 0)
end

-- sets every control at once from a {name = level} table (missing = 0).
-- only changed levels are sent, in parallel. dock latch is never touched here.
function thrusters.setMany(want)
    local fns = {}
    for name, pair in pairs(FREQ) do
        if name ~= "dock" then
            local lvl = math.max(0, math.min(15, want[name] or 0))
            if cache[name] ~= lvl then
                cache[name] = lvl
                fns[#fns + 1] = function() bridge.sendLinkSignal(pair[1], pair[2], lvl) end
            end
        end
    end
    if #fns == 0 then return end
    local ok, err = pcall(parallel.waitForAll, table.unpack(fns))
    if not ok then
        cache = {}
        error(err, 0)
    end
end

-- emergency stop, kills every thruster (not the dock latch)
function thrusters.all_stop()
    for direction, pair in pairs(FREQ) do
        if direction ~= "dock" then
            pcall(bridge.sendLinkSignal, pair[1], pair[2], 0)
        end
    end
    cache = {}
end
thrusters.stopAll = thrusters.all_stop

return thrusters