-- keep LAND_MODE and PAD_DY in sync with startup.lua
local LAND_MODE = "pad"          -- "chopsticks" | "pad"
local PAD_DY = 24.8                 -- pad mode: foot below pose origin, m (same as CONFIG.PAD_DY)
local CATCH_DY = -31.6           -- chopsticks mode: grid fins above pose origin (same as CONFIG.CATCH_DY)
local TOWER = { x = -2899, z = 6248 }
local LIME_AXIS, LIME_SIGN = "R", 1
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local PADMODE = LAND_MODE == "pad"

local function rot(qx,qy,qz,qw,a,b,c)
  local tx,ty,tz=2*(qy*c-qz*b),2*(qz*a-qx*c),2*(qx*b-qy*a)
  return a+qw*tx+(qy*tz-qz*ty), b+qw*ty+(qz*tx-qx*tz), c+qw*tz+(qx*ty-qy*tx)
end

-- calib.lua keeps both modes' data: the mode being calibrated overwrites its own keys, the rest is preserved
local function loadOld()
  if fs.exists("calib.lua") then
    local ok, t = pcall(dofile, "calib.lua")
    if ok and type(t) == "table" then return t end
  end
  return {}
end

local function serialize(c)
  local l = { "return {" }
  if c.TARGET then l[#l+1] = ("  TARGET = { x = %.1f, y = %.1f, z = %.1f },"):format(c.TARGET.x, c.TARGET.y, c.TARGET.z) end
  if c.ENTRY_DIR then l[#l+1] = ("  ENTRY_DIR = { x = %.3f, z = %.3f },"):format(c.ENTRY_DIR.x, c.ENTRY_DIR.z) end
  if c.ARMS_DIR then l[#l+1] = ("  ARMS_DIR = { x = %.3f, z = %.3f },"):format(c.ARMS_DIR.x, c.ARMS_DIR.z) end
  if c.ROLL_OFFSET then l[#l+1] = ("  ROLL_OFFSET = %.1f,"):format(c.ROLL_OFFSET) end
  if c.PAD then l[#l+1] = ("  PAD = { x = %.1f, y = %.1f, z = %.1f },"):format(c.PAD.x, c.PAD.y, c.PAD.z) end
  l[#l+1] = "}"
  return table.concat(l, "\n") .. "\n"
end

local timer = os.startTimer(0.4)
local msg = "Enter = save calib.lua (" .. LAND_MODE .. ")"
while true do
  local p=sublevel.getLogicalPose(); local o=p.orientation
  local qx,qy,qz,qw
  if type(o.v)=="table" then qx,qy,qz,qw=o.v.x,o.v.y,o.v.z,o.a else qx,qy,qz,qw=o.x,o.y,o.z,o.w end
  local ux,uy,uz=rot(qx,qy,qz,qw,0,1,0)
  local rx,_,rz=rot(qx,qy,qz,qw,1,0,0)
  local fx,_,fz=rot(qx,qy,qz,qw,0,0,1)
  local fd = PADMODE and -PAD_DY or -CATCH_DY
  local px,py,pz=p.position.x+fd*ux, p.position.y+fd*uy, p.position.z+fd*uz
  local new = loadOld()
  term.clear(); term.setCursorPos(1,1)
  if PADMODE then
    new.PAD = { x = px, y = py, z = pz }
    print(("PAD mode  pos %.1f %.1f %.1f  up %.3f"):format(px,py,pz,uy))
    print("Put the booster on the pad, upright, as landed")
  else
    local dx,dz=TOWER.x-px, TOWER.z-pz
    local l=math.sqrt(dx*dx+dz*dz); if l<1e-6 then l=1 end
    local ax,az=dx/l,dz/l
    local lx,lz
    if LIME_AXIS=="F" then lx,lz=fx,fz else lx,lz=rx,rz end
    lx,lz=lx*LIME_SIGN,lz*LIME_SIGN
    local off=math.deg(atan2(lz,lx)-atan2(az,ax))
    off=((off+180)%360)-180
    new.TARGET = { x = px, y = py, z = pz }
    new.ENTRY_DIR = { x = -ax, z = -az }
    new.ARMS_DIR = { x = ax, z = az }
    new.ROLL_OFFSET = off
    print(("pos %.1f %.1f %.1f  tower %.1f m"):format(px,py,pz,l))
    print(("entry %.3f %.3f  roll %.1f  up %.3f"):format(-ax,-az,off,uy))
  end
  if uy<0.99 then print("booster not upright!") end
  print(msg)
  local e,k=os.pullEvent()
  if e=="timer" then timer=os.startTimer(0.4)
  elseif e=="key" and k==keys.enter then
    local f=fs.open("calib.lua","w"); f.write(serialize(new)); f.close()
    msg="saved calib.lua"
  end
end