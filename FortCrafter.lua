--[[
# Script Name:   <Fort Crafter (Ironman)>
# Description:   <Automates Crafting in Fort Forinthry for Ironman accounts, including Orbs, Urns, Superglassmake, and Porters>
# Author:        <Matteus>
# Version:       <1.27>
# Date:          <2024.08.11>
--]]

API = require("api")

API.SetDrawTrackedSkills(true)

-- Constants
local MAX_IDLE_TIME_MINUTES = 5
local REQUIRED_LEATHER = 27
local REQUIRED_GEMS = 28
local MIN_PORTER_COUNT = 27

local states = {
    Bank = 0,
    Gems = 1,
    Leather = 2,
    Orbs = 3,
    Urns = 4,
    Superglassmake = 5,
    Porters = 6
}

local itemIds = {
    gemIds = {1625, 1627, 1629, 1623, 1621, 1619, 1617, 1631, 6571},
    leatherIds = {1745, 1513, 2505, 2507, 2509, 24374, 56075, 29556},
    orbIds = {571, 573, 569, 575},
    urnIds = {39008, 40916, 20343, 40796, 20373, 20403, 40836, 40876},
    superglassmakeIds = {32847, 23194},
    porterId = 1664,
    energyId = 29324
}

local state = states.Bank
local afk = os.time()

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)
    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function countItems(itemIds)
    local count = 0
    for _, itemId in ipairs(itemIds) do
        count = count + API.InvItemcount_1(itemId)
    end
    return count
end

local function getItemCounts()
    return {
        gemCount = countItems(itemIds.gemIds),
        leatherCount = countItems(itemIds.leatherIds),
        orbCount = countItems(itemIds.orbIds),
        urnCount = countItems(itemIds.urnIds),
        superglassmakeCount = countItems(itemIds.superglassmakeIds),
        porterCount = API.InvItemcount_1(itemIds.porterId),
        energyCount = API.InvItemcount_1(itemIds.energyId)
    }
end

local function checkState()
    local counts = getItemCounts()

    if counts.leatherCount >= REQUIRED_LEATHER then 
        return states.Leather
    elseif counts.gemCount >= REQUIRED_GEMS then 
        return states.Gems
    elseif counts.orbCount > 0 then
        return states.Orbs
    elseif counts.urnCount > 0 then
        return states.Urns
    elseif counts.superglassmakeCount > 0 then
        return states.Superglassmake
    elseif counts.porterCount >= MIN_PORTER_COUNT and counts.energyCount > 0 then
        return states.Porters
    else
        return states.Bank
    end
end

local function loadLastPreset()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {125734}, 50)
    API.RandomSleep2(525, 555, 600)
end

local function checkInventoryAfterBanking()
    API.RandomSleep2(450, 500, 550)
    local counts = getItemCounts()

    if counts.gemCount >= REQUIRED_GEMS or
       counts.leatherCount >= REQUIRED_LEATHER or
       counts.orbCount > 0 or
       counts.urnCount > 0 or
       counts.superglassmakeCount > 0 or
       (counts.porterCount >= MIN_PORTER_COUNT and counts.energyCount > 0) then
        return true
    else
        print("Not enough or no Crafting materials found. Stopping script.")
        return false
    end
end

local function performCrafting(itemIds, message)
    local itemsClicked = false
    for _, itemId in ipairs(itemIds) do
        if API.DoAction_Inventory1(itemId, 0, 1, API.OFF_ACT_GeneralInterface_route) then
            API.RandomSleep2(600, 200, 400)
            API.KeyboardPress32(0x20, 0)  -- Start crafting with spacebar
            itemsClicked = true
            break
        end
    end
    if not itemsClicked then
        state = states.Bank
        print(message)
    end
end

local function openInterface()
    if state == states.Gems then
        performCrafting(itemIds.gemIds, "No gems available for crafting.")
    elseif state == states.Leather then
        if countItems(itemIds.leatherIds) < REQUIRED_LEATHER then
            state = states.Bank
            return
        end
        performCrafting(itemIds.leatherIds, "Not enough leather for crafting.")
    elseif state == states.Orbs then
        performCrafting(itemIds.orbIds, "No orbs available for crafting.")
    elseif state == states.Urns then
        performCrafting(itemIds.urnIds, "No urns available for crafting.")
    elseif state == states.Superglassmake then
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 125, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(500, 600, 700)
        state = states.Bank
    elseif state == states.Porters then
        if API.InvItemcount_1(itemIds.energyId) > 0 then
            API.DoAction_Inventory1(itemIds.energyId, 0, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(500, 600, 700)
            API.KeyboardPress32(0x20, 0)  -- Start crafting with spacebar
        else
            print("Warning: No energy items available for crafting.")
        end
        state = states.Bank
    end
end

while API.Read_LoopyLoop() do
    idleCheck()
    API.DoRandomEvents()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if state == states.Bank then
            loadLastPreset()
            if not checkInventoryAfterBanking() then
                return
            end
            state = checkState()
        else
            openInterface()
        end
    end

    API.RandomSleep2(50, 75, 100)
end
