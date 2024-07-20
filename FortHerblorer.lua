--[[
# Script Name:   <Fort Herblore (Ironman)>
# Description:   <Automates Herblore in Fort Forinthry for Ironman accounts>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2024.07.19>
--]]

API = require("api")

API.SetDrawTrackedSkills(true)

local state = 1
local BANK_CHEST = 125115
local PotionIDs = {91, 95, 93, 97, 99, 101, 103, 105, 37973, 3004, 2483, 107, 12181, 291, 48241, 227, 21628, 32843, 48575, 48961, 48962, 48960, 48966, 48586}
local SpecialPotions = {
    {id = 12539, target = 169},      -- Extreme Ranged
    {id = 267, target = 157},        -- Extreme Strength
    {id = 9594, target = 3042},      -- Extreme Magic
    {id = 2481, target = 163},       -- Extreme Defence
    {id = 261, target = 145},        -- Extreme Attack
    {id = 55697, target = 55318},    -- Extreme Necromancy
    {id = 269, target = 15313},      -- Overload
    {id = 5972, target = 3018},      -- Adrenaline Potion
    {id = 39067, target = 15301}     -- Super Adrenaline Potion
}

local STATES = {
    {
        desc = "Banking",
        callback = function()
            local success = API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST }, 50)
            if success then
                API.RandomSleep2(350, 175, 350)  
            else
                print("Failed to interact with the bank chest.")
            end
        end,
        post = function()
            local hasPotions = false
            for _, id in ipairs(PotionIDs) do
                if API.InvItemcount_1(id) > 0 then
                    hasPotions = true
                    break
                end
            end
            local inventoryFull = API.InvFull_()
            local result = inventoryFull or hasPotions
            return result
        end
    },
    {
        desc = "Clicking potions",
        callback = function()
            print("Attempting to click potions...")
            local clicked = false
            for _, id in ipairs(PotionIDs) do
                if API.InvItemcount_1(id) > 0 then
                    API.DoAction_Inventory1(id, 0, 1, API.OFF_ACT_GeneralInterface_route)
                    print("Clicked on potion ID: " .. id)
                    clicked = true
                    API.RandomSleep2(600, 300, 600)  -- Increased delay for handling regular potions
                    break
                end
            end
            if not clicked then
                print("No potions available to click.")
            end
        end
    },
    {
        desc = "Mixing Potions",
        callback = function()
            print("Attempting to mix potions...")
            local mixed = false
            for _, potion in ipairs(SpecialPotions) do
                local potionID = potion.id
                local targetID = potion.target

                if API.InvItemcount_1(potionID) > 0 and API.InvItemcount_1(targetID) > 0 then
                    API.DoAction_Inventory1(potionID, 0, 0, API.OFF_ACT_Bladed_interface_route)
                    API.RandomSleep2(50, 30, 50)  -- Slightly increased sleep time for mixing

                    API.DoAction_Inventory1(targetID, 0, 0, API.OFF_ACT_GeneralInterface_route1)
                    API.RandomSleep2(400, 200, 250)  -- Slightly increased sleep time
                    API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
                    mixed = true
                    break
                end
            end
            if not mixed then
                print("No special potions available for mixing.")
            end
        end,
        post = function()
            API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
            local specialDone = #API.ScanForInterfaceTest2Get(true, { InterfaceComp5.new(1473, 7, -1, -1, 0) }) == 0
            print("Post Mixing Potions Check - SpecialDone: " .. tostring(specialDone))
            return specialDone
        end
    },
}

while API.Read_LoopyLoop() do
    API.DoRandomEvents()
    
    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        print("Processing State: " .. STATES[state].desc)
        STATES[state].callback()

        if STATES[state].post and not STATES[state].post() then
            print("State " .. STATES[state].desc .. " failed post-condition.")
            API.RandomSleep2(150, 100, 150)  -- Slightly increased retry wait time
        else
            state = (state % #STATES) + 1
        end
    end

    API.RandomSleep2(400, 200, 250)  -- Slightly increased sleep time
end
