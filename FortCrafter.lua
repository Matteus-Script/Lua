--[[
# Script Name:   <Fort Crafter (Ironman)>
# Description:   <Automates Crafting in Fort Forinthry for Ironman accounts, including Orbs, Urns, and Superglassmake>
# Author:        <Matteus>
# Version:       <1.24>
# Date:          <2024.08.02>
--]]

API = require("api")

API.SetDrawTrackedSkills(true)

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()
local states = {
    Bank = 0,
    Gems = 1,
    Leather = 2,
    Orbs = 3,
    Urns = 4,
    Superglassmake = 5
}

local gemIds = {
    1625, 1627, 1629, 1623, 1621, 1619, 1617, 1631, 6571
}

local leatherIds = {
    1745, 1513, 2505, 2507, 2509, 24374, 56075, 29556
}

local orbIds = {
    571, 573, 569, 575
}

local urnIds = {
    39008, 40916, 20343, 40796, 20373, 20403, 40836, 40876
}

local superglassmakeIds = {
    32847, 23194
}

local state = states.Bank

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function checkState()
    local firstItem = API.ReadInvArrays33()[1].textitem
    firstItem = string.upper(firstItem)
    
    if string.find(firstItem, "LEATHER") then 
        return states.Leather
    elseif string.find(firstItem, "UNCUT") then 
        return states.Gems
    elseif string.find(firstItem, "ORB") then
        return states.Orbs
    elseif API.InvItemcount_1(urnIds[1]) > 0 then
        return states.Urns
    elseif API.InvItemcount_1(superglassmakeIds[1]) > 0 or API.InvItemcount_1(superglassmakeIds[2]) > 0 then
        return states.Superglassmake
    else
        return states.Bank
    end
end

local function loadLastPreset()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {125734}, 50)
    API.RandomSleep2(525, 555, 600)
end

local function countItems(itemIds)
    local count = 0
    for _, itemId in ipairs(itemIds) do
        count = count + API.InvItemcount_1(itemId)
    end
    return count
end

local function checkInventoryAfterBanking()
    API.RandomSleep2(450, 500, 550)  -- Slight delay to ensure inventory updates properly

    local gemCount = countItems(gemIds)
    local leatherCount = countItems(leatherIds)
    local orbCount = countItems(orbIds)
    local urnCount = 0
    local superglassmakeCount = 0

    for _, urnId in ipairs(urnIds) do
        urnCount = urnCount + API.InvItemcount_1(urnId)
    end

    for _, id in ipairs(superglassmakeIds) do
        superglassmakeCount = superglassmakeCount + API.InvItemcount_1(id)
    end

    if gemCount >= 28 or leatherCount >= 27 or orbCount > 0 or urnCount > 0 or superglassmakeCount > 0 then
        return true
    else
        print("Not enough or no Crafting materials found stopping script.")
        return false
    end
end

local function initializeState()
    local gemCount = countItems(gemIds)
    local leatherCount = countItems(leatherIds)
    local orbCount = countItems(orbIds)
    local urnCount = 0
    local superglassmakeCount = 0

    for _, urnId in ipairs(urnIds) do
        urnCount = urnCount + API.InvItemcount_1(urnId)
    end

    for _, id in ipairs(superglassmakeIds) do
        superglassmakeCount = superglassmakeCount + API.InvItemcount_1(id)
    end

    if gemCount >= 28 then
        state = states.Gems
    elseif leatherCount >= 27 then  -- Check for at least 27 pieces of leather
        state = states.Leather
    elseif orbCount > 0 then
        state = states.Orbs
    elseif urnCount > 0 then
        state = states.Urns
    elseif superglassmakeCount > 0 then
        state = states.Superglassmake
    else
        state = states.Bank
    end
end

local function openInterface()
    if state == states.Gems or state == states.Leather or state == states.Orbs then
        if state == states.Leather and countItems(leatherIds) < 27 then
            state = states.Bank  -- Go to bank if less than 27 pieces of leather
            return
        end
        
        local itemsClicked = false
        local ids = (state == states.Gems) and gemIds or (state == states.Leather) and leatherIds or orbIds
        
        for _, itemId in ipairs(ids) do
            if API.DoAction_Inventory1(itemId, 0, 1, API.OFF_ACT_GeneralInterface_route) then
                API.RandomSleep2(600, 200, 400)
                API.KeyboardPress32(0x20, 0)  -- Start crafting with urn using the spacebar --API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
                itemsClicked = true
                break
            end
        end
        
        if not itemsClicked then
            state = states.Bank
        end
    elseif state == states.Urns then
        local urnCrafted = false
        for _, urnId in ipairs(urnIds) do
            if API.InvItemcount_1(urnId) > 0 then
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 209, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(500, 600, 700)
                API.KeyboardPress32(0x20, 0)  -- Start crafting with urn using the spacebar
                urnCrafted = true
                break
            end
        end
        
        if not urnCrafted then
            print("Warning: No urns available for crafting.")
        end
        state = states.Bank
    elseif state == states.Superglassmake then
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 125, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(500, 600, 700)
        state = states.Bank
    end
end

initializeState()

while API.Read_LoopyLoop() do
    idleCheck()
    API.DoRandomEvents()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if state == states.Bank then
            loadLastPreset()
            if not checkInventoryAfterBanking() then
                -- Continue execution; no stopping
                return
            end
            initializeState()
        elseif state == states.Gems or state == states.Leather or state == states.Orbs or state == states.Urns or state == states.Superglassmake then
            openInterface()
        end
    end

    API.RandomSleep2(50, 75, 100)
end
