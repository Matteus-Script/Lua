--[[
# Script Name:   Regular Ore Miner
# Description:   Mines ores at a mining location; start at the rock you want to mine
# Author:        Matteus
# Version:       1.0
# Date:          2024.08.12

-- Release Notes:
-- Version 1.0  : Repurposed for regular ore mining with updated ore IDs and types.
--]]

local API = require("api")
local GUI = require("gui")

local ORE_OPTIONS = {
    "Idle", "Copper", "Tin", "Iron", "Coal", "Mithril",
    "Adamantite", "Runite", "Luminite", "Orikalchite",
    "Drakolith", "Necrite", "Phasmatite", "Banite",
    "LightAnimica", "DarkAnimica", "Uncommon", "Common"
}

local ORE_IDS = {
    Copper = {113028, 113027, 113026},
    Tin = {113031, 113030},
    Iron = {113040, 113038, 113039},
    Coal = {113043, 113042, 113041},
    Mithril = {113050, 113051, 113052},
    Adamantite = {113055, 113053, 113054},
    Runite = {113067, 113066, 113065},
    Luminite = {113056, 113057, 113058},
    Orikalchite = {113070, 113069},
    Drakolith = {113131, 113133, 113132, 113133, 113071, 113072, 113073},
    Necrite = {113206, 113207, 113208},
    Phasmatite = {113138, 113139, 113137},
    Banite = {113140, 113141, 113142},
    LightAnimica = {113018},
    DarkAnimica = {113020, 113021, 113022},
    Uncommon = {113047, 113048, 113049},
    Common = {113035, 113036, 113037}
}

GUI.AddBackground("MainBackground", 2, 1, ImColor.new(0, 0, 0, 180))
GUI.AddLabel("Title", "Regular Ore Miner", ImColor.new(255, 255, 255))
GUI.AddComboBox("OreSelector", "Select Ore", ORE_OPTIONS)

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
        API.RandomSleep2(600, 600, 600)
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

local function FindHighlightedOre(objects, maxdistance, highlight)
    local closestOre = nil
    local closestDistance = maxdistance

    local allOres = API.GetAllObjArray1(objects, maxdistance, {0, 12})
    local allHighlights = API.GetAllObjArray1(highlight, maxdistance, {4})

    for _, obj in ipairs(allOres) do
        for _, hl in ipairs(allHighlights) do
            local distance = API.Math_DistanceF(obj.Tile_XYZ, hl.Tile_XYZ)
            if distance <= maxdistance and distance < closestDistance then
                closestOre = obj
                closestDistance = distance
            end
        end
    end

    return closestOre
end

local function getSelectedOres()
    local selectedOption = GUI.GetComponentValue("OreSelector")
    return ORE_IDS[selectedOption] or {}
end

-- Main loop
local lastClickedOre = nil
local selectedOres = {}

while API.Read_LoopyLoop() do
    GUI.Draw()

    local newSelectedOres = getSelectedOres()
    if #newSelectedOres == 0 then
        lastClickedOre = nil
    end
    selectedOres = newSelectedOres

    if #selectedOres > 0 then
        API.DoRandomEvents()
        keepGOTEcharged()
        useElvenRitualShard()
        checkAndDrinkPotion()

        local shinyOre = FindHighlightedOre(selectedOres, 50, HIGHLIGHTS)
        if shinyOre and (not lastClickedOre or API.Math_DistanceF(lastClickedOre.Tile_XYZ, shinyOre.Tile_XYZ) > 0) then
            API.RandomSleep2(500, 1000, 1500)
            API.DoAction_Object_Direct(0x3a, API.OFF_ACT_GeneralObject_route0, shinyOre)
            API.WaitUntilMovingEnds()
            API.RandomSleep2(2000, 2000, 4000)
            lastClickedOre = shinyOre
        else
            if not API.CheckAnim(25) then
                API.DoAction_Object1(0x3a, API.OFF_ACT_GeneralObject_route0, selectedOres, 50)
                API.WaitUntilMovingEnds()
                API.RandomSleep2(2000, 2000, 4000)
            end
        end

        API.RandomSleep2(1000, 1000, 2000)
    else
        API.RandomSleep2(2000, 2000, 4000)
    end
end
