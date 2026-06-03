--[[
# Script Name:   <Priff Summoning>
# Description:   <Makes pouches in Priff, start at the bank uses loadlastpreset>
# Author:        <Matteus>
# Version:       <2.0>
# Date:          <2025.01.23>
--]]

API = require("api")
UTILS = require("utils")

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10) 

local Charms = { 12158, 12159, 12160, 12163 }

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false) or API.Compare2874Status(13, false)
end

local states = {
    TELEPORT_AMLODD = 1,
    CLICK_OBELISK = 2,
    TELEPORT_ITHELL = 3,
    BANK = 4
}

local currentState = states.BANK

local function TeleportAmlodd()
    API.DoAction_Inventory1(39784, 0, 1, API.OFF_ACT_GeneralInterface_route)
    if not UTILS.SleepUntil(isOpen, 5, "Seed Teleport Interface") then
        print("Teleport interface did not open after using teleport seed.")
        API.Write_LoopyLoop(false)
        return
    end
    API.KeyboardPress32(0x33, 0)
    UTILS.SleepUntil(function() return API.PInArea(2155, 5, 3383, 5, 1) end, 10, "Arrived at Amlodd")
    currentState = states.CLICK_OBELISK
end

local function ClickObelisk()
    Interact:Object("Obelisk", "Infuse-pouch", WPOINT.new(2139, 3374,0))

    if not UTILS.SleepUntil(isOpen, 10, "Obelisk Interface to open") then
        print("Obelisk interface did not open. Retrying.")

        Interact:Object("Obelisk", "Infuse-pouch", WPOINT.new(2139, 3374,0))

        if not UTILS.SleepUntil(isOpen, 10, "Obelisk Interface to open on retry") then
            print("Obelisk interface failed to open again. Stopping script.")
            API.Write_LoopyLoop(false)
            return
        end
    end

    API.KeyboardPress32(0x20, 0)
    API.RandomSleep2(600, 900, 75)

    UTILS.SleepUntil(function() 
        local processing = API.isProcessing()
        return not processing 
    end, 80, "Processing...")
    

    currentState = states.TELEPORT_ITHELL
end

local function TeleportIthell()
    API.DoAction_Inventory1(39784, 0, 1, API.OFF_ACT_GeneralInterface_route)

    
    if not UTILS.SleepUntil(isOpen, 5, "Seed Teleport Interface") then
        print("Teleport interface did not open after using teleport seed.")
        API.Write_LoopyLoop(false)
        return
    end

    API.KeyboardPress32(0x38, 0)
    UTILS.SleepUntil(function() return API.PInArea(2155, 5, 3339, 5, 1) end, 10, "Arrived at Ithell")
    currentState = states.BANK
end

local function hasEnoughCharms()
    for _, charm in ipairs(Charms) do
    if Inventory:InvStackSize(charm) >= 25 then
            return true
        end
    end
    return false
end

local function validateRequirement(condition, itemName)
    if not condition then
        print("Not enough " .. itemName .. ".")
        API.Write_LoopyLoop(false)
        return false
    end
    return true
end

local function Bank()
    Interact:Object("Bank chest", "Load Last Preset from", WPOINT.new(2153, 3341,0))
    UTILS.SleepUntil(function() return Inventory:IsFull() end, 30, "Inventory full")

    local shardCount = Inventory:InvStackSize(12183)
    local pouchCount = Inventory:InvStackSize(12155)
    local charmsOk = hasEnoughCharms()

    if not validateRequirement(shardCount >= 1000, "Spirit Shards. Have: " .. shardCount) then return end
    if not validateRequirement(pouchCount >= 25, "Summoning Pouches. Have: " .. pouchCount) then return end
    if not validateRequirement(charmsOk, "Charms") then return end

    currentState = states.TELEPORT_AMLODD
end


API.Write_LoopyLoop(true)

while (API.Read_LoopyLoop()) do
    if currentState == states.TELEPORT_AMLODD then
        TeleportAmlodd()
    elseif currentState == states.CLICK_OBELISK then
        ClickObelisk()
    elseif currentState == states.TELEPORT_ITHELL then
        TeleportIthell()
    elseif currentState == states.BANK then
        Bank()
    end
end
