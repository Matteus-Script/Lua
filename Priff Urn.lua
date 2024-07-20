--[[
# Script Name:   Prifddinas Urn maker
# Description:   Makes urns in Prifddinas.
# Author:        Matteus
# Version:       1.2
# Date:          2024.07.19
--]]

-- Release Notes:
-- Version 1.00  : Initial release.
-- Version 1.10  : Changed wait times, Added invcheck for softclay so it doesnt always have to bank first
-- Version 1.20  : Will now do random events whilst making urns

API = require("api")

API.SetDrawTrackedSkills(true)

state = 1

local MAX_IDLE_TIME_MINUTES = 5
local BANK_CHEST = 92692
local POTTERSWHEEL = 94062
local PotterInterface = { InterfaceComp5.new(1371, 7, -1, -1, 0) }
local SOFT_CLAY_ID = 1761
local MIN_SOFT_CLAY_COUNT = 2

local STATES = {
    {
        desc = "Banking",
        callback = function() API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST }, 50) end,
        post = function() return API.InvFull_() end
    },
    {
        desc = "Opening Potterswheel",
        callback = function() API.DoAction_Object1(0x3e, API.OFF_ACT_GeneralObject_route0, { POTTERSWHEEL }, 50) end,
        post = nil
    },
    {
        desc = "Making urns",
        callback = function()
            API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
        end,
        post = function() return #API.ScanForInterfaceTest2Get(true, PotterInterface) <= 0 end
    }
}

local function validatePosition()
    if #API.GetAllObjArray1({ BANK_CHEST, POTTERSWHEEL }, 50, { 0, 12 }) <= 0 then
        print("Please start near the Pottery wheel or bank in Prifddinas!")
        return false
    end
    return true
end

local function hasEnoughSoftClay()
    return (API.InvItemcount_1(SOFT_CLAY_ID) or 0) >= MIN_SOFT_CLAY_COUNT
end

-- Main loop.
while API.Read_LoopyLoop() and validatePosition() do
    API.DoRandomEvents()
    API.SetMaxIdleTime(MAX_IDLE_TIME_MINUTES)

  STATES[state].callback()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if state == 1 and hasEnoughSoftClay() then
            -- Skip banking if there are at least 2 soft clay.
            state = 2
        elseif state == 2 and not hasEnoughSoftClay() then
            -- If we don't have enough soft clay, switch to banking.
            state = 1
        end
    
        STATES[state].callback()
    
        if STATES[state].post and not STATES[state].post() then
            print(STATES[state].desc .. " failed!")
            break
        end
    
        state = (state % #STATES) + 1
    end
    API.RandomSleep2(200, 300, 400)
end
