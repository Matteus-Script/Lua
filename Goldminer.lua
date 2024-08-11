--[[
# Script Name:   <LRC Gold Miner>
# Description:   <Mines gold in lrc>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2024.08.10>
--]]

local API = require('api')

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()

API.SetDrawTrackedSkills(true)

local IDS = {
    ELVEN_SHARD = 43358
}

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
        API.logDebug("Recharging GOTE")
        API.DoAction_Interface(0xffffffff, 0xae06, 6, 1464, 15, 2, API.OFF_ACT_GeneralInterface_route2)
        API.RandomSleep2(600, 600, 600)
    end
end

local function performMining()
    API.logDebug("Checking if Mining Action can be performed")
    
    
    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        API.logDebug("Performing Mining Action")
        
        
        local ids = {113010}
        
        API.DoAction_Object1(0x3a, API.OFF_ACT_GeneralObject_route0, ids, 50)
        
        API.RandomSleep2(1000, 1500, 1000)
    else
        API.logDebug("Mining action skipped due to ongoing activity")
    end
end

while API.Read_LoopyLoop() do
    idleCheck()

    useElvenRitualShard()

    keepGOTEcharged()
    
    performMining()
    
    API.DoRandomEvents()
    API.RandomSleep2(500, 500, 500)
end
