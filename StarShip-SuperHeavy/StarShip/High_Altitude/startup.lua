-- High-altitude test launcher: ascent (hitest.lua) -> landing (sh_landing.lua)
-- hitest.lua hands off to sh_landing.lua on its own
-- Needs: hitest.lua, sh_landing.lua, calib.lua (from calibrate.lua)
for _, f in ipairs({ "hitest.lua", "sh_landing.lua" }) do
  if not fs.exists(f) then error("missing " .. f, 0) end
end
if not fs.exists("calib.lua") then
  print("WARNING: no calib.lua, landing uses CONFIG.TARGET")
end
print("HIGH-ALTITUDE TEST: ascent -> landing")
dofile("hitest.lua")
print("done, logs: hitest.log, landing_sh.log")
