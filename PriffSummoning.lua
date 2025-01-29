--[[
# Script Name:   <Priff Summoning>
# Description:   <Makes pouches in Priff, start at the bank uses loadlastpreset>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2025.01.23>
--]]

API = require("api")
UTILS = require("utils")

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10) 

local Obelisk = 94230
local Teleportseed = 39784
local Bankchest = 92692
local Shards = 12183
local Pouches = 12155
local Charms = { 12158, 12159, 12160, 12163 }
local ShouldContinue = true

local SeedInterface = { InterfaceComp5.new(720, 2, -1, 0) }
local ObeliskInterface = { InterfaceComp5.new(1371, 7, -1, 0) }

local function isSeedInterfaceOpen()
    return #API.ScanForInterfaceTest2Get(true, SeedInterface) > 0
end

local function Summoninginterfaceopen()
    return #API.ScanForInterfaceTest2Get(true, ObeliskInterface) > 0
end

local states = {
    TELEPORT_AMLODD = 1,
    CLICK_OBELISK = 2,
    TELEPORT_ITHELL = 3,
    BANK = 4
}

local currentState = states.BANK

local function TeleportAmlodd()
    API.DoAction_Inventory1(Teleportseed, 0, 1, API.OFF_ACT_GeneralInterface_route)
    UTILS.countTicks(1)
    if not isSeedInterfaceOpen() then
        print("Teleport interface did not open after using teleport seed.")
        ShouldContinue = false
        return
    end
    API.KeyboardPress32(0x33, 0)
    UTILS.randomSleep(2000 * 2)
    currentState = states.CLICK_OBELISK
end

local function Clickobelisk()
    API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, { Obelisk }, 50)
    
    local maxWaitTime = 10 
    local elapsedTime = 0
    local waitInterval = 0.5 

    while not Summoninginterfaceopen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not Summoninginterfaceopen() then
        print("Obelisk interface did not open after clicking obelisk.")
        ShouldContinue = false
        return
    end

    API.KeyboardPress32(0x20, 0)
    UTILS.randomSleep(1000 * 2)
    currentState = states.TELEPORT_ITHELL
end

local function TeleportIthell()
    API.DoAction_Inventory1(Teleportseed, 0, 1, API.OFF_ACT_GeneralInterface_route)
    UTILS.countTicks(1)
    if not isSeedInterfaceOpen() then
        print("Teleport interface did not open after using teleport seed.")
        ShouldContinue = false
        return
    end
    API.KeyboardPress32(0x38, 0)
    UTILS.randomSleep(2000 * 2)
    currentState = states.BANK
end

local function hasEnoughCharms()
    for _, charm in ipairs(Charms) do
        if API.InvStackSize(charm) >= 25 then
            return true
        end
    end
    return false
end

local function Bank()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { Bankchest }, 10)
    UTILS.randomSleep(2000 * 2)
    local shardCount = API.InvStackSize(Shards)
    local pouchCount = API.InvStackSize(Pouches)
    if not API.InvFull_() or shardCount < 1000 or pouchCount < 25 or not hasEnoughCharms() then
        print("Not enough supplies left. Stopping script.")
        ShouldContinue = false
        return
    end
    currentState = states.TELEPORT_AMLODD
end

while (API.Read_LoopyLoop()) do
    if ShouldContinue then
        if currentState == states.TELEPORT_AMLODD then
            TeleportAmlodd()
        elseif currentState == states.CLICK_OBELISK then
            Clickobelisk()
        elseif currentState == states.TELEPORT_ITHELL then
            TeleportIthell()
        elseif currentState == states.BANK then
            Bank()
        end
    else
        break
    end
end
