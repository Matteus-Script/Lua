--[[
# Script Name:   Primal Ore Miner
# Description:   Mines all the ores at Daemonheim; start at the rock you want to mine
# Author:        Matteus
# Version:       1.0
# Date:          2024.07.19

--]]

-- Release Notes:
-- Version 1.00  : Initial release.


local API = require("api")
local GUI = require("gui")


local ROCK_OPTIONS = {
    "Idle",  
    "Novite",
    "Bathus",
    "Marmaros",
    "Kratonium",
    "Fractite",
    "Zephyrium",
    "Argonite",
    "Katagon",
    "Gorgonite",
    "Promethium"
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
GUI.AddLabel("Title", "Spade Miner", ImColor.new(255, 255, 255))
GUI.AddComboBox("RockSelector", "Select Rock", ROCK_OPTIONS)

local MAX_IDLE_TIME_MINUTES = 10
local POTIONS = {33234, 33232, 33230, 33228, 33226, 33224}
local HIGHLIGHTS = {7164, 7165}
API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(MAX_IDLE_TIME_MINUTES) 

local function keepGOTEcharged()
    local buffStatus = API.Buffbar_GetIDstatus(51490, false)
    local stacks = tonumber(buffStatus.text)

    local function findPorters()
        local portersIds = {51490, 29285, 29283, 29281, 29279, 29277, 29275}
        local porters = API.CheckInvStuff3(portersIds)
        local foundIdx = -1
        for i, value in ipairs(porters) do
            if tostring(value) == '1' then
                foundIdx = i
                break
            end
        end
        if foundIdx ~= -1 then
            local foundId = portersIds[foundIdx]
            if foundId <= 51490 then
                return foundId
            else
                return nil
            end
        else
            return nil
        end
    end
    
    if stacks and stacks <= 50 and findPorters() then
        print("Recharging GOTE")
        API.DoAction_Interface(0xffffffff, 0xae06, 5, 1430, 77, -1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 600, 600)
    end
end

local function takeMiningPot()
    if API.Buffbar_GetIDstatus(33234).conv_text <= 1 then
        for _, pot in ipairs(POTIONS) do
            if API.InvItemcount_1(pot) > 0 then
                print("Drinking potion!")
                API.DoAction_Inventory1(pot, 0, 1, API.OFF_ACT_GeneralInterface_route)
                break
            end
        end
    end
end

local function FindHl(objects, maxdistance, highlight)
    for _, obj in ipairs(API.GetAllObjArray1(objects, maxdistance, {0, 12})) do
        for _, hl in ipairs(API.GetAllObjArray1(highlight, maxdistance, {4})) do
            if math.abs(obj.Tile_XYZ.x - hl.Tile_XYZ.x) <= 1 and math.abs(obj.Tile_XYZ.y - hl.Tile_XYZ.y) <= 1 then
                return obj
            end
        end
    end
    return nil
end

local function PerfectPlus()
    if not API.Buffbar_GetIDstatus(33234, false).found and inventoryContains("Perfect") then
        API.DoAction_Inventory3("Perfect", 0, 1, 3808)
    end
end

local function getSelectedRocks()
    local selectedOption = GUI.GetComponentValue("RockSelector")
    if selectedOption and ROCK_IDS[selectedOption] then
        return ROCK_IDS[selectedOption]
    else
        return {} 
    end
end

-- Main loop
local clickedRock = nil
local selectedRocks = {} 

while API.Read_LoopyLoop() do
    GUI.Draw()

    local newSelectedRocks = getSelectedRocks()
    if #newSelectedRocks > 0 then
        selectedRocks = newSelectedRocks
    end

    if #selectedRocks > 0 then
        API.DoRandomEvents()
        PerfectPlus()
        keepGOTEcharged()

        local shinyRock = FindHl(selectedRocks, 50, HIGHLIGHTS)
        if shinyRock then        
            if not clickedRock or API.Math_DistanceF(clickedRock.Tile_XYZ, shinyRock.Tile_XYZ) ~= 0 then
                API.RandomSleep2(500, 1000, 1500)
                API.DoAction_Object_Direct(0x3a, API.OFF_ACT_GeneralObject_route0, shinyRock)
                clickedRock = shinyRock
            end
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
