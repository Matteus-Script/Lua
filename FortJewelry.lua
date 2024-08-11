--[[
# Script Name:   <Fort Smelter>
# Description:   <Smelts bars and banks gems at the fort>
# Author:        <Matteus>
# Version:       <2.1>
# Date:          <2024.08.11>
--]]

local API = require('api')

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()

local furnaceID = 125137
local BANK_CHEST = 125115
local GEM_ID = 1615

API.SetDrawTrackedSkills(true)

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function smeltMaterials()
    API.logDebug("Starting smelting process")
    API.DoAction_Object1(0x3f, API.OFF_ACT_GeneralObject_route0, { furnaceID }, 50)
    API.RandomSleep2(2000, 2500, 3500)
    API.KeyboardPress32(0x20, 0)
    API.RandomSleep2(450, 500, 550)
end

local function bankGems()
    API.logDebug("Banking gems")
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST }, 50)
    API.RandomSleep2(350, 400, 450)
end

local function checkInventoryForGems()
    return API.InvItemcount_1(GEM_ID) > 0
end

while API.Read_LoopyLoop() do
    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        idleCheck()

        -- Only smelt once if gems are present
        if checkInventoryForGems() then
            smeltMaterials()
        end

        -- Wait until all gems are smelted
        while checkInventoryForGems() and API.Read_LoopyLoop() do
            API.RandomSleep2(500, 600, 700)  -- Delay to periodically check inventory
        end

        -- Bank only after all gems are smelted and the loop is still running
        if API.Read_LoopyLoop() then
            bankGems()
        end
    end
    
    API.DoRandomEvents()
    API.RandomSleep2(500, 500, 500)
end
