local CATCH_DY = -31.6
local TOWER = { x = -2899, z = 6248 }
local LIME_AXIS, LIME_SIGN = "R", 1
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local function rot(qx,qy,qz,qw,a,b,c)
  local tx,ty,tz=2*(qy*c-qz*b),2*(qz*a-qx*c),2*(qx*b-qy*a)
  return a+qw*tx+(qy*tz-qz*ty), b+qw*ty+(qz*tx-qx*tz), c+qw*tz+(qx*ty-qy*tx)
end

local timer = os.startTimer(0.4)
local msg = "Enter = save calib.lua"
while true do
  local p=sublevel.getLogicalPose(); local o=p.orientation
  local qx,qy,qz,qw
  if type(o.v)=="table" then qx,qy,qz,qw=o.v.x,o.v.y,o.v.z,o.a else qx,qy,qz,qw=o.x,o.y,o.z,o.w end
  local ux,uy,uz=rot(qx,qy,qz,qw,0,1,0)
  local rx,_,rz=rot(qx,qy,qz,qw,1,0,0)
  local fx,_,fz=rot(qx,qy,qz,qw,0,0,1)
  local fd=-CATCH_DY
  local px,py,pz=p.position.x+fd*ux, p.position.y+fd*uy, p.position.z+fd*uz
  local dx,dz=TOWER.x-px, TOWER.z-pz
  local l=math.sqrt(dx*dx+dz*dz); if l<1e-6 then l=1 end
  local ax,az=dx/l,dz/l
  local lx,lz
  if LIME_AXIS=="F" then lx,lz=fx,fz else lx,lz=rx,rz end
  lx,lz=lx*LIME_SIGN,lz*LIME_SIGN
  local off=math.deg(atan2(lz,lx)-atan2(az,ax))
  off=((off+180)%360)-180
  local out=("return {\n  TARGET = { x = %.1f, y = %.1f, z = %.1f },\n  ENTRY_DIR = { x = %.3f, z = %.3f },\n  ARMS_DIR = { x = %.3f, z = %.3f },\n  ROLL_OFFSET = %.1f,\n}\n"):format(px,py,pz,-ax,-az,ax,az,off)
  term.clear(); term.setCursorPos(1,1)
  print(("pos %.1f %.1f %.1f  tower %.1f m"):format(px,py,pz,l))
  print(("entry %.3f %.3f  roll %.1f  up %.3f"):format(-ax,-az,off,uy))
  if uy<0.99 then print("booster not upright!") end
  print(msg)
  local e,k=os.pullEvent()
  if e=="timer" then timer=os.startTimer(0.4)
  elseif e=="key" and k==keys.enter then
    local f=fs.open("calib.lua","w"); f.write(out); f.close()
    msg="saved calib.lua"
  end
end