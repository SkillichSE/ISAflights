-- runlog.lua: opens a NEW log file per run (name_<epochsec>.ext) so a restart
-- never overwrites earlier logs. Keeps the newest `keep` files per prefix.
local M = {}

function M.open(path, keep)
    keep = keep or 5
    path = path:gsub("^/", "")
    local base, ext = path:match("^(.-)(%.[^./]+)$")
    if not base then base, ext = path, ".log" end
    local dir = fs.getDir(path)
    local prefix = fs.getName(base) .. "_"
    local stamp = os.epoch and math.floor(os.epoch("utc") / 1000) or math.floor(os.clock())
    stamp = string.format("%012d", stamp) -- fixed width so name sort == time sort

    local list = {}
    for _, f in ipairs(fs.list(dir)) do
        if f:sub(1, #prefix) == prefix and f:sub(-#ext) == ext then list[#list + 1] = f end
    end
    table.sort(list)
    for i = 1, #list - (keep - 1) do pcall(fs.delete, fs.combine(dir, list[i])) end

    local name = fs.combine(dir, prefix .. stamp .. ext)
    local f = fs.open(name, "a") -- append: even a same-second restart can't wipe it
    if f then f.writeLine("=== RUN START " .. name .. " ===") end
    return f
end

return M
