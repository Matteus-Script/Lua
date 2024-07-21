--[[
# Script Name:   <Material Caches>
# Description:   <Gathers Blood of Orcus or Hellfire metal for Binding contracts>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2024.07.21>
--]]

local API = require('api')

API.SetDrawTrackedSkills(true)

local IDS = {
    ELVEN_SHARD = 43358
}

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()

-- Cache configurations
local CACHE_CONFIGS = {
    [116435] = {
        {x = 3399, y = 3558, z = 0},
        {x = 3405, y = 3556, z = 0},
        {x = 3405, y = 3562, z = 0}
    },
    [116426] = {
        {x = 2904, y = 5366, z = 0},
        {x = 2906, y = 5364, z = 0},
        {x = 2901, y = 5365, z = 0}
    }
}

local cacheIDs = {116435, 116426} 
local currentCacheIDIndex = 1
local currentCacheIndex = 1
local clickAttempted = false

local function ClickingCache()
    local cacheID = cacheIDs[currentCacheIDIndex]
    local coords = CACHE_CONFIGS[cacheID][currentCacheIndex]
    API.logDebug("Clicking cache ID: " .. cacheID .. " at coordinates (" .. coords.x .. ", " .. coords.y .. ", " .. coords.z .. ")")
    clickAttempted = API.DoAction_Object2(0x2, API.OFF_ACT_GeneralObject_route0, {cacheID}, 50, WPOINT.new(coords.x, coords.y, coords.z))
    API.RandomSleep2(250, 350, 500)
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function moveToNextCache()
    local cacheID = cacheIDs[currentCacheIDIndex]
    currentCacheIndex = (currentCacheIndex % #CACHE_CONFIGS[cacheID]) + 1
    API.logDebug("Moving to next cache: ID " .. cacheID .. " at coordinates (" .. CACHE_CONFIGS[cacheID][currentCacheIndex].x .. ", " .. CACHE_CONFIGS[cacheID][currentCacheIndex].y .. ", " .. CACHE_CONFIGS[cacheID][currentCacheIndex].z .. ")")
end

local function moveToNextCacheID()
    currentCacheIDIndex = (currentCacheIDIndex % #cacheIDs) + 1
    currentCacheIndex = 1 
    API.logDebug("Switching to next cache ID: " .. cacheIDs[currentCacheIDIndex])
end

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

while API.Read_LoopyLoop() do
    idleCheck()
    API.DoRandomEvents()

    useElvenRitualShard()

    keepGOTEcharged()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if not clickAttempted then
            ClickingCache()
        else
            API.logDebug("Click attempt already made; waiting for player to complete animation.")
        end

        if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
            if clickAttempted then
                API.logDebug("Cache clicked successfully or no click attempt made. Moving to next cache.")
            end
            moveToNextCache()
            clickAttempted = false 
        end
    else
        API.logDebug("Player is animating or processing. Waiting...")
    end

    if currentCacheIndex == 1 and not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        moveToNextCacheID()
    end

    API.RandomSleep2(500, 750, 1000) 
end
