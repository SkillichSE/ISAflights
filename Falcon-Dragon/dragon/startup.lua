-- startup.lua
-- boot entry point ONLY. Runs main.lua (flight computer, terminal input)
-- and panel.lua (monitor dashboard) side by side on the same computer.
-- Do not put flight/panel logic in this file - it's just the launcher.

-- main is wrapped in pcall so a flight error doesn't propagate and kill
-- panel.lua too. waitForAll (not waitForAny) is deliberate: waitForAny stops
-- BOTH the moment either one finishes, which would kill the dashboard the
-- instant main.lua returns. waitForAll only stops once every function is
-- done - since panel.lua runs forever, that means main finishing just leaves
-- the dashboard running on its own, which is what we want.
parallel.waitForAll(
    function()
        pcall(shell.run, "main")
        -- main ended (error / Ctrl+T / done): never leave a thruster latched on
        pcall(function() local th = require("thrusters"); th.init(); th.all_stop() end)
    end,
    function() shell.run("panel") end
)