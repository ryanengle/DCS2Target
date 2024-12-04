-------------------------------------------------------------------------------
--
-- fa-18c_hornet_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS F/A-18C Hornet simulation data
-- and packaging for TCP packet transmission to Thrustmaster Target
-- TMHotasLEDSync.tmc script.
--
-- Author: slughead
-- Date: 03/12/2023
--
------------------------------------------------------------------------------

-- Added by fuze (12/3/2024)
--  DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\MainPanel\lamps.lua
-- Flaps, Landing Gear and Stores Indicator Panel
--create_caution_lamp(166,	CautionLights.CPT_LTS_NOSE_GEAR)
--create_caution_lamp(165,	CautionLights.CPT_LTS_LEFT_GEAR)
--create_caution_lamp(167,	CautionLights.CPT_LTS_RIGHT_GEAR)
-- Landing Gear 
--create_caution_lamp(227, CautionLights.CPT_LTS_LDG_GEAR_HANDLE)

local P = {}
fa_18c_hornet_lamps = P

    P.CONSOLE_LIGHT_DIAL = 413
    P.LEFT_GENERATOR_CONTROL_SWITCH = 402
    P.RIGHT_GENERATOR_CONTROL_SWITCH = 403
    -- Added by fuze
    P.CPT_LTS_NOSE_GEAR = 166
    P.CPT_LTS_LEFT_GEAR = 165
    P.CPT_LTS_RIGHT_GEAR = 167
    P.CPT_LTS_LDG_GEAR_HANDLE = 227

    P.speedbrakes_value   = nil
    P.console_light_value = nil
    -- Added by fuze
    P.gear_nose_status    = nil
    P.gear_left_status    = nil
    P.gear_right_status   = nil
    P.gear_warning_status = nil


-- copied by fuze from f-16c_50_lamps.lua
local function get_lamp_status( id, status )
    local updated = false
    local value

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        value = device:get_argument_value(id) -- returns 0 (Off) 1 (On)
        if status ~= value then
            updated = true
        end
    end

    return updated, value
end
-- end of copy

local function get_console_light_value( current_value )
    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        local aircraft_lamp_utils = require("fa-18c_hornet_lamps")

        -- get engine info
        local lEngInfo = Export.LoGetEngineInfo()

        if ((lEngInfo.RPM.left  > 60 and device:get_argument_value(aircraft_lamp_utils.LEFT_GENERATOR_CONTROL_SWITCH)  == 1) or
            (lEngInfo.RPM.right > 60 and device:get_argument_value(aircraft_lamp_utils.RIGHT_GENERATOR_CONTROL_SWITCH) == 1))
        then
            value = device:get_argument_value(aircraft_lamp_utils.CONSOLE_LIGHT_DIAL)
            value = math.floor(value * 5)
        end

        if current_value ~= value then
            updated = true
        end
    end

    return updated, value
end

local function get_speedbrake_value( current_value )

    local updated = false
    local value = 0

    local lMechInfo = Export.LoGetMechInfo() -- mechanical components,  e.g. Flaps, Wheelbrakes,...
    if (lMechInfo ~= nil) then
        value = lMechInfo.speedbrakes.value

        -- ensure full range is used for aircraft that almost reach 1.0
        if (value >= 0.9) then value = 1.0 end

        value = math.floor(value * 5)

        if (current_value ~= value) then
            updated = true;
        end
    end

    return updated, value
end

function P.init( self )
    self.speedbrakes_value   = nil
    self.console_light_value = nil

    -- Added by fuze
    self.gear_nose_status   = nil
    self.gear_left_status   = nil
    self.gear_right_status   = nil
    self.gear_warning_status = nil
end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.speedbrakes_value = get_speedbrake_value( self.speedbrakes_value )
        updated = updated or status_changed

        status_changed, self.console_light_value = get_console_light_value( self.console_light_value )
        updated = updated or status_changed

        -- Added by fuze
        status_changed, self.gear_nose_status = get_lamp_status( self.CPT_LTS_NOSE_GEAR, self.gear_nose_status )
        updated = updated or status_changed

        status_changed, self.gear_left_status = get_lamp_status( self.CPT_LTS_LEFT_GEAR, self.gear_left_status )
        updated = updated or status_changed

        status_changed, self.gear_right_status = get_lamp_status( self.CPT_LTS_RIGHT_GEAR, self.gear_right_status )
        updated = updated or status_changed

        status_changed, self.gear_warning_status = get_lamp_status( self.CPT_LTS_LDG_GEAR_HANDLE, self.gear_warning_status )
        updated = updated or status_changed        

        --updated by fuze
        payload = string.format( "%d%d%d%d%d%d",
                                 self.speedbrakes_value,
                                 self.console_light_value, 
                                 self.gear_nose_status,
                                 self.gear_left_status,
                                 self.gear_right_status,
                                 self.gear_warning_status )
    else
        -- updated by fuze
        payload = "000000"
    end

    return updated, payload

end

return fa_18c_hornet_lamps