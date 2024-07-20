--[[
# Script Name:   <Fort Crafter (Ironman)>
# Description:   <Automates Crafting in Fort Forinthry for Ironman accounts>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2024.07.20>
--]]

API = require("api")

API.SetDrawTrackedSkills(true)

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()
local states = {
    Bank = 0,
    Gems = 1,
    Leather = 2,
}

local gemIds = {
    1625, 1627, 1629, 1623, 1621, 1619, 1617, 1631, 6571
}

local leatherIds = {
    1745, 2505, 2507, 2509, 24374, 56075
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
    API.logDebug("Checking state")
    local firstItem = API.ReadInvArrays33()[1].textitem
    firstItem = string.upper(firstItem)
    
    if string.find(firstItem, "LEATHER") then 
        return states.Leather
    elseif string.find(firstItem, "UNCUT") then 
        return states.Gems
    else
        return states.Bank
    end
end

local function loadLastPreset() 
    API.logDebug("Loading last preset")
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {125115}, 50)
    API.RandomSleep2(250, 350, 500) 
end

local function countItems(itemIds)
    local count = 0
    for _, itemId in ipairs(itemIds) do
        count = count + API.InvItemcount_1(itemId)
    end
    return count
end

local function initializeState()
    
    local gemCount = countItems(gemIds)
    local leatherCount = countItems(leatherIds)
    
    if gemCount >= 28 then
        state = states.Gems
    elseif leatherCount >= 28 then
        state = states.Leather
    else
        state = states.Bank
    end
end

local function openInterface()
    if state == states.Gems or state == states.Leather then 
        local itemsClicked = false
        local ids = (state == states.Gems) and gemIds or leatherIds
        
        for _, itemId in ipairs(ids) do
            
            API.logDebug("Attempting to click item with ID: ", itemId)
            if API.DoAction_Inventory1(itemId, 0, 1, API.OFF_ACT_GeneralInterface_route) then
                API.logDebug("Clicked item with ID: ", itemId)
                API.RandomSleep2(600, 200, 400) 

                
                API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
                API.logDebug("Performed interface action")
                
                itemsClicked = true
                break 
            else
                API.logDebug("Failed to click item with ID: ", itemId)
            end
        end
        
        if not itemsClicked then
            API.logDebug("No items found to interact with.")
            state = states.Bank 
        end
    end
end

initializeState() 

while API.Read_LoopyLoop() do 
    idleCheck()
    API.DoRandomEvents()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if state == states.Bank then 
            
            API.logDebug("Currently in banking state. Banking now.")
            loadLastPreset()
            initializeState()
        end

        if state == states.Gems or state == states.Leather then 
            
            local gemCount = countItems(gemIds)
            local leatherCount = countItems(leatherIds)

            if (state == states.Gems and gemCount < 28) or (state == states.Leather and leatherCount < 28) then
                API.logDebug("Not enough items for crafting. Switching to bank state.")
                state = states.Bank
                
            else
                API.logDebug("Opening interface for crafting")
                openInterface()
                
                state = states.Bank
            end
        end 
    end

    API.RandomSleep2(50, 75, 100) 
end
