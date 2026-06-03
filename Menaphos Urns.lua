--[[
# Script Name:   <Urn Crafter (Ironman)>
# Description:   <Makes Urns in Menaphos select your urn then start>
# Author:        <Matteus>
# Version:       <1.1>
# Date:          <2025.12.18>
--]]

local API = require("api")
local UTILS = require("utils")
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local function countItems(itemID)
    return Inventory:InvItemcount(itemID) or 0
end

local function bank()
    Interact:Object("Bank chest", "Load Last Preset from", 15)
    API.RandomSleep2(500, 800, 50)
    local success = UTILS.SleepUntil(function() return countItems(1761) >= 2 end, 10, "Waiting for bank to load items...")
    if not success then
        print("Banking timed out. Not enough soft clay. Exiting script.")
        API.Write_LoopyLoop(false)
    end
end

local function hasEnoughSoftClay()
    if countItems(1761) < 2 then
        print("Not enough soft clay. Attempting to bank.")
        bank()
        if countItems(1761) < 2 then
            print("Still not enough soft clay after banking. Exiting script.")
            API.Write_LoopyLoop(false)
            return false
        end
    end
    return true
end

local function isOpen()
    return API.Compare2874Status(18, false) or API.Compare2874Status(40, false)
end

local function processStage()
    if not hasEnoughSoftClay() then
        bank()
        return
    end

    API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route0, { 107724 }, 50, WPOINT.new(3164, 2791, 0))

    UTILS.SleepUntil(isOpen, 10, "Waiting for pottery interface...")

    API.KeyboardPress32(0x20, 0)
    API.RandomSleep2(1200, 800, 50)

    UTILS.SleepUntil(function() return not API.isProcessing() end, 80, "Processing...")
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    API.DoRandomEvents()

    if API.isProcessing() then
        API.RandomSleep2(200, 300, 400)
    else
        processStage()
    end

    API.RandomSleep2(250, 80, 80)
end
