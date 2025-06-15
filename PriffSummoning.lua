-- Title: Priff Summoning
-- Author: <Matteus>
-- Description: <Makes pouches in Priff, start at the bank uses loadlastpreset>
-- Version: <1.1>
-- Category: Summoning
-- Date : 2025.01.23

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

local function getSelectedItemId()
    return API.VB_FindPSettinOrder(1170, 0).state
end

local function isOpen()
    return getSelectedItemId() ~= -1 and (API.Compare2874Status(18, false) or API.Compare2874Status(40, false))
end

local function waitCraftingInterface()
    for _ = 1, 50 do  
        if isOpen() then return true end
        API.RandomSleep2(100, 200, 300) 
    end
    return false
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

    if not waitCraftingInterface() then
        print("Obelisk interface did not open. Retrying.")

        API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, { Obelisk }, 50)

        if not waitCraftingInterface() then
            print("Obelisk interface failed to open again. Stopping script.")
            ShouldContinue = false
            return
        end
    end

    API.KeyboardPress32(0x20, 0)

    UTILS.randomSleep(3000) 

    currentState = states.TELEPORT_ITHELL
end

local function TeleportIthell()
    local item49508Count = API.InvItemcount_1(49508)
    local item49504Count = API.InvItemcount_1(49504)

    if item49508Count > 0 or item49504Count > 0 then
        UTILS.countTicks(4)
    end

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
    local charmsOk = hasEnoughCharms()

    if not API.InvFull_() then
        print("Inventory is not full. Stopping script.")
        ShouldContinue = false
        return
    end

    if shardCount < 1000 then
        print("Not enough Spirit Shards. Have: " .. shardCount)
        ShouldContinue = false
        return
    end

    if pouchCount < 25 then
        print("Not enough Summoning Pouches. Have: " .. pouchCount)
        ShouldContinue = false
        return
    end

    if not charmsOk then
        print("Not enough Charms.")
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
