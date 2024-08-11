--[[
# Script Name:   <Fort Smelter>
# Description:   <Smelts bars at the fort>
# Author:        <Matteus>
# Version:       <1.6>
# Date:          <2024.08.10>
--]]

local API = require('api')

local MAX_IDLE_TIME_MINUTES = 5
local startTime, afk = os.time(), os.time()

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
    local furnaceID = 125137

    API.logDebug("Starting smelting process")
    API.DoAction_Object1(0x3f, API.OFF_ACT_GeneralObject_route0, { furnaceID }, 50)
    API.RandomSleep2(350, 400, 450)
    API.KeyboardPress32(0x20, 0)
    API.RandomSleep2(450, 500, 550)
end

while API.Read_LoopyLoop() do
    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        idleCheck()
        smeltMaterials() 
    end
    
    API.DoRandomEvents()
    API.RandomSleep2(500, 500, 500)
end
