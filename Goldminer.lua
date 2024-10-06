--[[
# Script Name:   LRC Gold Miner Enhanced
# Description:   Automates gold mining in LRC
# Author:        Matteus
# Version:       1.2
# Date:          2024.09.01
--]]

local API = require('api')

-- Configurable Parameters
local MAX_IDLE_TIME_MINUTES = 5
local ELVEN_SHARD_PRAYER_THRESHOLD = 50 
local GOTE_RECHARGE_THRESHOLD = 500      
local MIN_RECLICK_TIME = 25  
local MAX_RECLICK_TIME = 35  

local startTime, afk = os.time(), os.time()
local nextMiningTime = nil  

API.SetDrawTrackedSkills(true)

-- Item IDs
local IDS = {
    ELVEN_SHARD = 43358,
    POTION_BUFF = 33234,
    GOTE = 51490,
}

local POTION_IDS = {33234, 33232, 33230, 33228, 33226, 33224}

local function checkAndDrinkPotion()
    local buffStatus = API.Buffbar_GetIDstatus(IDS.POTION_BUFF, false)

    if not buffStatus.found then
        for _, potionId in ipairs(POTION_IDS) do
            local potionCount = API.InvItemcount_1(potionId)
            if potionCount > 0 then
                API.DoAction_Inventory1(potionId, potionId, 1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(500, 1000, 1500)
                return true
            end
        end
    end
    return false
end

local function hasElvenRitualShard()
    return API.InvItemcount_1(IDS.ELVEN_SHARD) > 0
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function useElvenRitualShard()
    if not hasElvenRitualShard() then 
        return 
    end

    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(IDS.ELVEN_SHARD, false)

    if prayer < ELVEN_SHARD_PRAYER_THRESHOLD and not elvenCD.found then
        API.DoAction_Inventory1(IDS.ELVEN_SHARD, IDS.ELVEN_SHARD, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600, 600, 600)
    end
end

local function keepGOTEcharged()
    local buffStatus = API.Buffbar_GetIDstatus(IDS.GOTE, false)
    local stacks = tonumber(buffStatus.text)

    local function findPorters()
        local portersIds = {IDS.GOTE, 29285, 29283, 29281, 29279, 29277, 29275}
        local porters = API.CheckInvStuff3(portersIds)
        for i, value in ipairs(porters) do
            if tostring(value) == '1' then
                return portersIds[i]
            end
        end
        return nil
    end
    
    if stacks and stacks <= GOTE_RECHARGE_THRESHOLD then
        local porterId = findPorters()
        if porterId then
            API.DoAction_Ability("Grace of the elves", 5, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 600, 600)
        end
    end
end

local function performMining()
    local currentTime = os.time()
    local isPlayerIdle = not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing())  

    if isPlayerIdle or (nextMiningTime == nil or currentTime >= nextMiningTime) then
        local ids = {113010}
        API.DoAction_Object1(0x3a, API.OFF_ACT_GeneralObject_route0, ids, 50) 
        API.RandomSleep2(1000, 1500, 1000) 

        nextMiningTime = currentTime + math.random(MIN_RECLICK_TIME, MAX_RECLICK_TIME)
    end
end

-- Main loop
while API.Read_LoopyLoop() do
    idleCheck()
    useElvenRitualShard()
    checkAndDrinkPotion()
    keepGOTEcharged()
    performMining()  
    API.DoRandomEvents()
    API.RandomSleep2(500, 500, 500)
end
