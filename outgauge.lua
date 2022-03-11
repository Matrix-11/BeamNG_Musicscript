-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this file serves two purposes:
-- A) generic outgauge implementation: used to use for example custom made dashboard hardware and alike
-- B) update the user interface for the remote control app directly via the sendPackage function
-- please note that use case A and B exclude each other for now.

local M = {}

local ip = "127.0.0.1"
local port = 4444

local udpSocket = nil

local ffi = require("ffi")

local function declareOutgaugeStruct()
  -- the documentation can be found at LFS/docs/InSim.txt
  ffi.cdef [[
  typedef struct outgauge_t  {
      unsigned       time;            // time in milliseconds (to check order)
      char           car[4];          // Car name
      unsigned short flags;           // Info (see OG_x below)
      char           gear;            // Reverse:0, Neutral:1, First:2...
      char           plid;            // Unique ID of viewed player (0 = none)
      float          speed;           // M/S
      float          speedAir;         // M/S Airspeed
      float          rpm;             // RPM
      float          turbo;           // BAR
      float          engTemp;         // C
      float          fuel;            // 0 to 1
      float          oilPressure;     // BAR
      float          oilTemp;         // C
      float          RLslip;          //Wheelslip of rear left wheel
      float          RRslip;          //Wheelslip of rear left wheel
      unsigned       dashLights;      // Dash lights available (see DL_x below)
      unsigned       showLights;      // Dash lights currently switched on
      float          throttle;        // 0 to 1
      float          brake;           // 0 to 1
      float          clutch;          // 0 to 1
      char           display1[16];    // Usually Fuel
      char           display2[16];    // Usually Settings
      int            id;              // optional - only if OutGauge ID is specified
  } outgauge_t;
  ]]
end
pcall(declareOutgaugeStruct)

--[[
CONSTANTS
// OG_x - bits for OutGaugePack Flags
#define OG_SHIFT      1        // key
#define OG_CTRL       2        // key
#define OG_TURBO      8192     // show turbo gauge
#define OG_KM         16384    // if not set - user prefers MILES
#define OG_BAR        32768    // if not set - user prefers PSI

// DL_x - bits for OutGaugePack DashLights and ShowLights
DL_SHIFT,           // bit 0    - shift light
DL_FULLBEAM,        // bit 1    - full beam
DL_HANDBRAKE,       // bit 2    - handbrake
DL_PITSPEED,        // bit 3    - pit speed limiter
DL_TC,              // bit 4    - TC active or switched off
DL_SIGNAL_L,        // bit 5    - left turn signal
DL_SIGNAL_R,        // bit 6    - right turn signal
DL_SIGNAL_ANY,      // bit 7    - shared turn signal
DL_OILWARN,         // bit 8    - oil pressure warning
DL_BATTERY,         // bit 9    - battery warning
DL_ABS,             // bit 10   - ABS active or switched off
DL_SPARE,           // bit 11
]]
local OG_KM = 16384
local OG_BAR = 32768
local OG_TURBO = 8192

local DL_SHIFT = 2 ^ 0
local DL_FULLBEAM = 2 ^ 1
local DL_HANDBRAKE = 2 ^ 2
local DL_TC = 2 ^ 4
local DL_SIGNAL_L = 2 ^ 5
local DL_SIGNAL_R = 2 ^ 6
local DL_OILWARN = 2 ^ 8
local DL_BATTERY = 2 ^ 9
local DL_ABS = 2 ^ 10

local hasESC = false
local hasShiftLights = false

local function sendPackage(ip, port, id)
  --log('D', 'outgauge', 'sendPackage: '..tostring(ip) .. ':' .. tostring(port))

  if not electrics.values.watertemp then
    -- vehicle not completly initialized, skip sending package
    return
  end

  local o = ffi.new("outgauge_t")
  -- set the values
  o.time = 0 -- not used atm
  o.car = "beam"
  o.flags = OG_KM + OG_BAR + (electrics.values.turboBoost and OG_TURBO or 0)
  o.gear = electrics.values.gearIndex + 1 -- reverse = 0 here
  o.plid = 0
  o.speed = electrics.values.wheelspeed
  o.speedAir = electrics.values.airspeed
  o.rpm = electrics.values.rpm or 0
  o.turbo = (electrics.values.turboBoost or 0) / 14.504
  o.engTemp = electrics.values.watertemp or 0
  o.fuel = electrics.values.fuel or 0
  o.oilPressure = 0 -- TODO
  o.oilTemp = electrics.values.oiltemp or 0
  o.RLslip = wheels.wheelRotators[2].lastSlip --Slip of Rear left wheel (wheelRotators returns Wheelid (0 = FR, 1 = RR, 2 = RL, 3 = FR) for names use .name)
  o.RRslip = wheels.wheelRotators[1].lastSlip --Slip of Rear right wheel

  -- the lights
  o.dashLights = bit.bor(o.dashLights, DL_FULLBEAM)
  if electrics.values.highbeam ~= 0 then
    o.showLights = bit.bor(o.showLights, DL_FULLBEAM)
  end

  o.dashLights = bit.bor(o.dashLights, DL_HANDBRAKE)
  if electrics.values.parkingbrake ~= 0 then
    o.showLights = bit.bor(o.showLights, DL_HANDBRAKE)
  end

  o.dashLights = bit.bor(o.dashLights, DL_SIGNAL_L)
  if electrics.values.signal_L ~= 0 then
    o.showLights = bit.bor(o.showLights, DL_SIGNAL_L)
  end

  o.dashLights = bit.bor(o.dashLights, DL_SIGNAL_R)
  if electrics.values.signal_R ~= 0 then
    o.showLights = bit.bor(o.showLights, DL_SIGNAL_R)
  end

  local hasABS = electrics.values.hasABS or false
  if hasABS then
    o.dashLights = bit.bor(o.dashLights, DL_ABS)
    if electrics.values.abs ~= 0 then
      o.showLights = bit.bor(o.showLights, DL_ABS)
    end
  end

  o.dashLights = bit.bor(o.dashLights, DL_OILWARN)
  if electrics.values.oil ~= 0 then
    o.showLights = bit.bor(o.showLights, DL_OILWARN)
  end

  o.dashLights = bit.bor(o.dashLights, DL_BATTERY)
  if electrics.values.engineRunning == 0 then
    o.showLights = bit.bor(o.showLights, DL_BATTERY)
  end

  hasESC = electrics.values.hasESC
  if hasESC then
    o.dashLights = bit.bor(o.dashLights, DL_TC)
    if electrics.values.esc ~= 0 or electrics.values.tcs ~= 0 then
      o.showLights = bit.bor(o.showLights, DL_TC)
    end
  end

  if hasShiftLights then
    o.dashLights = bit.bor(o.dashLights, DL_SHIFT)
    if electrics.values.shouldShift then
      o.showLights = bit.bor(o.showLights, DL_SHIFT)
    end
  end

  o.throttle = electrics.values.throttle
  o.brake = electrics.values.brake
  o.clutch = electrics.values.clutch
  o.display1 = "" -- TODO
  o.display2 = "" -- TODO
  o.id = id

  local packet = ffi.string(o, ffi.sizeof(o)) --convert the struct into a string
  udpSocket:sendto(packet, ip, port)
  --log("I", "", "SendPackage for ID '"..dumps(id).."': "..dumps(electrics.values.rpm))
end

local function updateGFX(dt)
  if not playerInfo.firstPlayerSeated then
    return
  end
  sendPackage(ip, port, 0)
end

local function onExtensionLoaded()
  if not ffi then
    log("E", "outgauge", "Unable to load outgauge module: Lua FFI required")
    return false
  end

  if not udpSocket then
    udpSocket = socket.udp()
  end

  ip = settings.getValue("outgaugeIP")
  port = tonumber(settings.getValue("outgaugePort"))

  log("I", "", "Outgauge initialized for: " .. tostring(ip) .. ":" .. tostring(port))

  local shiftLightControllers = controller.getControllersByType("shiftLights")
  hasShiftLights = shiftLightControllers and #shiftLightControllers > 0
  return true
end

local function onExtensionUnloaded()
  if udpSocket then
    udpSocket:close()
  end
  udpSocket = nil
end

-- public interface
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.updateGFX = updateGFX

M.sendPackage = sendPackage

return M
