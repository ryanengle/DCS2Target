-------------------------------------------------------------------------------
--
-- a-10c_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS A-10C simulation data and packaging
-- for TCP packet transmission to Thrustmaster Target TMHotasLEDSync.tmc
-- script.
--
-- Author: slughead
-- Date: 03/12/2023
--
------------------------------------------------------------------------------

-- Added by fuze (10/12/2024)
-- DCS World OpenBeta\Mods\aircraft\A-10C_2\Cockpit\Scripts\mainpanel_init.lua
-- Caution Light Panel 
-- caution_lamp(659,SystemsSignals.flag_LANDING_GEAR_N_SAFE)
-- caution_lamp(660,SystemsSignals.flag_LANDING_GEAR_L_SAFE)
-- caution_lamp(661,SystemsSignals.flag_LANDING_GEAR_R_SAFE)

-- caution_lamp(737,SystemsSignals.flag_HANDLE_GEAR_WARNING)


local P = {}
a_10c_lamps = P

    P.APU_RPM_GUAGE            = 13
    P.APU_GEN_PWR_SWITCH       = 241
    P.LEFT_AC_GENERATOR_POWER  = 244
    P.RIGHT_AC_GENERATOR_POWER = 245
    P.CONSOLE_LIGHT_DIAL       = 297
    -- Added by fuze 
    P.flag_LANDING_GEAR_N_SAFE = 659
    P.flag_LANDING_GEAR_L_SAFE = 660
    P.flag_LANDING_GEAR_R_SAFE = 661
    P.flag_HANDLE_GEAR_WARNING = 737

    P.speedbrakes_value   = nil
    P.console_light_value = nil
    -- Added by fuze
    P.gear_nose_status     = nil
    P.gear_left_status     = nil
    P.gear_right_status    = nil
    P.gear_warning_status  = nil


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
        local aircraft_lamp_utils = require("a-10c_lamps")

        -- get apu rpm
        local apu_rpm = device:get_argument_value(aircraft_lamp_utils.APU_RPM_GUAGE)
        local apu_gen_pwr_switch = device:get_argument_value(aircraft_lamp_utils.APU_GEN_PWR_SWITCH)

        -- get engine info
        local lEngInfo = Export.LoGetEngineInfo()

        if ((apu_rpm > 0.8 and apu_gen_pwr_switch == 1) or
            (lEngInfo.RPM.left  > 50 and device:get_argument_value(aircraft_lamp_utils.LEFT_AC_GENERATOR_POWER)  == 1) or
            (lEngInfo.RPM.right > 50 and device:get_argument_value(aircraft_lamp_utils.RIGHT_AC_GENERATOR_POWER) == 1) )
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

        -- A_10C fudge factor
        value = value * 1.3

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
    self.gear_warning_status   = nil    

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
        status_changed, self.gear_nose_status = get_lamp_status( self.flag_LANDING_GEAR_N_SAFE, self.gear_nose_status )
        updated = updated or status_changed

        status_changed, self.gear_left_status = get_lamp_status( self.flag_LANDING_GEAR_L_SAFE, self.gear_left_status )
        updated = updated or status_changed

        status_changed, self.gear_right_status = get_lamp_status( self.flag_LANDING_GEAR_R_SAFE, self.gear_right_status )
        updated = updated or status_changed

        status_changed, self.gear_warning_status = get_lamp_status( self.flag_HANDLE_GEAR_WARNING, self.gear_warning_status )
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

return a_10c_lamps