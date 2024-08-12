--[[
# Script Name:   Primal Ore Miner
# Description:   Mines ores at Daemonheim; start at the rock you want to mine
# Author:        Matteus
# Version:       1.2
# Date:          2024.08.12

-- Release Notes:
-- Version 1.1  : Cleaned code, enhanced logging, and optimized checks.
-- Version 1.2  : Fixed Gote and perfect plus
--]]

local API = require("api")
local GUI = require("gui")


local ROCK_OPTIONS = {
    "Idle", "Novite", "Bathus", "Marmaros", "Kratonium",
    "Fractite", "Zephyrium", "Argonite", "Katagon", 
    "Gorgonite", "Promethium"
}

local ROCK_IDS = {
    Novite = {130797, 130799, 130798},
    Bathus = {130801, 130800, 130802},
    Marmaros = {130803, 130805, 130804},
    Kratonium = {130778, 130776, 130777},
    Fractite = {130780, 130779, 130781},
    Zephyrium = {130812, 130814, 130813},
    Argonite = {130786, 130785, 130787},
    Katagon = {130818, 130819, 130820},
    Gorgonite = {130791, 130793, 130792},
    Promethium = {130824, 130825, 130826}
}


GUI.AddBackground("MainBackground", 2, 1, ImColor.new(0, 0, 0, 180))
GUI.AddLabel("Title", "Primal Ore Miner", ImColor.new(255, 255, 255))
GUI.AddComboBox("RockSelector", "Select Rock", ROCK_OPTIONS)


local MAX_IDLE_TIME_MINUTES = 10
local HIGHLIGHTS = {7164, 7165}
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(MAX_IDLE_TIME_MINUTES)

local IDS = {
    ELVEN_SHARD = 43358,
    POTION_BUFF = 33234
}

local POTION_IDS = {33234, 33232, 33230, 33228, 33226, 33224}

local function hasElvenRitualShard()
    return API.InvItemcount_1(IDS.ELVEN_SHARD) > 0
end

local function useElvenRitualShard()
    if not hasElvenRitualShard() then return end
    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(IDS.ELVEN_SHARD, false)

    if prayer < 50 and not elvenCD.found then
        API.logDebug("Using Elven Shard")
        API.DoAction_Inventory1(IDS.ELVEN_SHARD, IDS.ELVEN_SHARD, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(300, 500, 700)
        local shinyRock = FindHighlightedRock(selectedRocks, 50, HIGHLIGHTS)
        if shinyRock and (not clickedRock or API.Math_DistanceF(clickedRock.Tile_XYZ, shinyRock.Tile_XYZ) > 0) then
            API.RandomSleep2(500, 1000, 1500)
            API.DoAction_Object_Direct(0x3a, API.OFF_ACT_GeneralObject_route0, shinyRock)
            clickedRock = shinyRock
        else
            API.DoAction_Object1(0x3a, API.OFF_ACT_GeneralObject_route0, selectedRocks, 50)
        end
    end
end

local function keepGOTEcharged()
    
    local buffStatus = API.Buffbar_GetIDstatus(51490, false)
    local stacks = tonumber(buffStatus.text) or 0

    local function findPorters()
        local portersIds = {51490, 29285, 29283, 29281, 29279, 29277, 29275}
        local porters = API.CheckInvStuff3(portersIds)
        for i, value in ipairs(porters) do
            if tostring(value) == '1' then
                return portersIds[i]
            end
        end
        return nil
    end

    if stacks <= 50 then
        local porterId = findPorters()
        if porterId then
            API.logDebug("Recharging GOTE - Found porter item in inventory.")
            
            local success = API.DoAction_Ability("Grace of the elves", 5, API.OFF_ACT_GeneralInterface_route)
            if not success then
                API.logDebug("Failed to activate Grace of the Elves ability.")
            end
            API.RandomSleep2(600, 600, 600)
        else
            API.logDebug("Recharging GOTE - No porter item found in inventory.")
        end
    end
end

local function checkAndDrinkPotion()
    
    local buffStatus = API.Buffbar_GetIDstatus(IDS.POTION_BUFF, false)

    if not buffStatus.found then
        for _, potionId in ipairs(POTION_IDS) do
            local potionCount = API.InvItemcount_1(potionId)
            if potionCount > 0 then
                API.logDebug("Drinking potion with ID: " .. potionId)
                API.DoAction_Inventory1(potionId, potionId, 1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(500, 1000, 1500)
                return
            end
        end
        API.logDebug("No potion found in inventory.")
    end
end

local function FindHighlightedRock(objects, maxdistance, highlight)
    local closestRock = nil
    local closestDistance = maxdistance

    local allRocks = API.GetAllObjArray1(objects, maxdistance, {0, 12})
    local allHighlights = API.GetAllObjArray1(highlight, maxdistance, {4})

    for _, obj in ipairs(allRocks) do
        for _, hl in ipairs(allHighlights) do
            local distance = API.Math_DistanceF(obj.Tile_XYZ, hl.Tile_XYZ)
            if distance <= maxdistance and distance < closestDistance then
                closestRock = obj
                closestDistance = distance
            end
        end
    end

    return closestRock
end

local function getSelectedRocks()
    local selectedOption = GUI.GetComponentValue("RockSelector")
    return ROCK_IDS[selectedOption] or {}
end

-- Main loop
local clickedRock = nil
local selectedRocks = {}

while API.Read_LoopyLoop() do
    GUI.Draw()

    local newSelectedRocks = getSelectedRocks()
    if #newSelectedRocks == 0 then
        clickedRock = nil
    end
    selectedRocks = newSelectedRocks

    if #selectedRocks > 0 then
        API.DoRandomEvents()
        keepGOTEcharged()
        useElvenRitualShard()
        checkAndDrinkPotion()

        local shinyRock = FindHighlightedRock(selectedRocks, 50, HIGHLIGHTS)
        if shinyRock and (not clickedRock or API.Math_DistanceF(clickedRock.Tile_XYZ, shinyRock.Tile_XYZ) > 0) then
            API.RandomSleep2(500, 1000, 1500)
            API.DoAction_Object_Direct(0x3a, API.OFF_ACT_GeneralObject_route0, shinyRock)
            clickedRock = shinyRock
        else
            if not API.CheckAnim(25) then
                API.DoAction_Object1(0x3a, API.OFF_ACT_GeneralObject_route0, selectedRocks, 50)
            end
        end

        API.RandomSleep2(1000, 1000, 2000)
    else
        API.RandomSleep2(2000, 2000, 4000)
    end
end
