--[[
# Script Name:   Crystal Keys
# Description:   Opens crystal keys in Priff
# Author:        Matteus
# Version:       1.1
# Date:          2024.08.10
--]]

local API = require('api')

local CONFIG = {
    MAX_IDLE_TIME_MINUTES = 5,
    KEY_ITEM_ID = 989,
    CRYSTAL_CHEST_ID = 92627,
    BANK_ID = 114750,
    TELEPORT_SEED_ID = 39784,
    REQUIRED_KEY_COUNT = 28,
    TELEPORT_WAIT_TIME = 3000,
    CHEST_WAIT_TIME = 600,
    BANK_WAIT_TIME = 3500
}

local STATE_IDLE = 1
local STATE_BANK = 2
local STATE_TELEPORT = 3
local STATE_MOVE_TO_CHEST = 4
local STATE_CLICK_CHEST = 5
local STATE_WAIT_FOR_KEYS = 6

local currentState = STATE_IDLE
local startTime, afk = os.time(), nil
local shouldContinue = true
local chestClicks = 0

local function randomSleep(minMs, maxMs)
    API.RandomSleep2(minMs, maxMs, minMs)
end

local function idleCheck()
    if not afk then
        afk = os.time()
        return
    end

    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((CONFIG.MAX_IDLE_TIME_MINUTES * 60) * 0.6, (CONFIG.MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function teleportWarRetreat()
    local warTeleport = API.GetABs_name1("War's Retreat Teleport")
    if warTeleport and warTeleport.enabled then
        API.DoAction_Ability_Direct(warTeleport, 1, API.OFF_ACT_GeneralInterface_route)
        randomSleep(2000, 3000)
        API.WaitUntilMovingEnds()
    else
        print("[Error] War's Retreat Teleport ability not available.")
        shouldContinue = false
    end
end

local function clickSeedAndTeleport()
    API.DoAction_Ability("Attuned crystal teleport seed", 1, API.OFF_ACT_GeneralInterface_route)
    randomSleep(500, 700)
    API.DoAction_Interface(0xFFFFFFFF, 0xFFFFFFFF, 0, 720, 35, -1, API.OFF_ACT_GeneralInterface_Choose_option)
end

local function moveToChest()
    if currentState == STATE_MOVE_TO_CHEST then
        API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {CONFIG.CRYSTAL_CHEST_ID}, 50)
        randomSleep(1000, 1000)
        API.WaitUntilMovingEnds()
        randomSleep(100, 100)
        API.DoAction_Interface(168, 27, 1, 168, 27, -1, API.OFF_ACT_GeneralInterface_route)
        currentState = STATE_CLICK_CHEST
    end
end

local function clickCrystalChest()
    if currentState == STATE_CLICK_CHEST then
        API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {CONFIG.CRYSTAL_CHEST_ID}, 50)
        randomSleep(CONFIG.CHEST_WAIT_TIME, CONFIG.CHEST_WAIT_TIME + 100)
        API.DoAction_Interface(168, 27, 1, 168, 27, -1, API.OFF_ACT_GeneralInterface_route)
        randomSleep(500, 700)
        chestClicks = chestClicks + 1
        currentState = STATE_WAIT_FOR_KEYS
    end
end

local function checkKeysAvailable()
    return API.InvItemcount_1(CONFIG.KEY_ITEM_ID) >= CONFIG.REQUIRED_KEY_COUNT
end

function API.ScriptRuntime()
    return os.difftime(os.time(), startTime)
end

function API.ScriptRuntimeString()
    local seconds = API.ScriptRuntime()
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function handleStates()
    if currentState == STATE_IDLE then
        idleCheck()
        if API.InvItemcount_1(CONFIG.KEY_ITEM_ID) == 0 then
            currentState = STATE_BANK
        else
            currentState = STATE_CLICK_CHEST
        end
    elseif currentState == STATE_BANK then
        teleportWarRetreat()
        API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {CONFIG.BANK_ID}, 50)
        randomSleep(CONFIG.BANK_WAIT_TIME, CONFIG.BANK_WAIT_TIME + 500)

        if not checkKeysAvailable() then
            print("Fewer than 28 crystal keys remaining after banking. Stopping script.")
            shouldContinue = false
            return false
        end

        currentState = STATE_TELEPORT
        clickSeedAndTeleport()
    elseif currentState == STATE_TELEPORT then
        API.WaitUntilMovingEnds()
        randomSleep(CONFIG.TELEPORT_WAIT_TIME, CONFIG.TELEPORT_WAIT_TIME + 500)
        currentState = STATE_MOVE_TO_CHEST
    elseif currentState == STATE_MOVE_TO_CHEST then
        moveToChest()
    elseif currentState == STATE_CLICK_CHEST then
        clickCrystalChest()
    elseif currentState == STATE_WAIT_FOR_KEYS then
        currentState = STATE_IDLE
    end

    return true
end

while API.Read_LoopyLoop() and shouldContinue do
    if not handleStates() then
        break
    end
    API.DoRandomEvents()
    randomSleep(200, 400)
end

print("Total keys used: " .. chestClicks)
print("Script runtime: " .. API.ScriptRuntimeString())
