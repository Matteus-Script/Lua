--[[
# Script Name:   Crystal Keys
# Description:   Opens crystal keys in Priff
# Author:        Matteus
# Version:       1.0
# Date:          2024.08.10
--]]
local API = require('api')

local MAX_IDLE_TIME_MINUTES = 5
local KEY_ITEM_ID = 989  
local CRYSTAL_CHEST_ID = 92627  
local BANK_ID = 114750  
local TELEPORT_SEED_ID = 39784  
local REQUIRED_KEY_COUNT = 28  

local STATE_IDLE = 1
local STATE_BANK = 2
local STATE_TELEPORT = 3
local STATE_MOVE_TO_CHEST = 4
local STATE_CLICK_CHEST = 5
local STATE_WAIT_FOR_KEYS = 6
local currentState = STATE_IDLE
local startTime, afk = os.time(), nil
local shouldContinue = true  

local chestClicks = 0  -- Counter for chest clicks

local function idleCheck()
    if afk == nil then
        afk = os.time()
        return
    end

    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function TeleportWarRetreat()
    local warTeleport = API.GetABs_name1("War's Retreat Teleport")
    if warTeleport and warTeleport.enabled then
        API.DoAction_Ability_Direct(warTeleport, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(2000, 3000, 2000)
        API.WaitUntilMovingEnds()
    end
end

local function clickSeedAndTeleport()
    -- Click the teleport seed interface
    API.DoAction_Interface(0x2e, 0x9b68, 1, 1430, 64, -1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(500, 700, 500)

    -- Define the seed interface with the correct values
    local seedInterface = {
        interfaceId = 720,  -- Interface ID from your provided details
        componentId = 18,   -- Component ID from your provided details
        option1 = -1,       -- Additional options or flags, if any
        option2 = -1,       -- Additional options or flags, if any
        item = -1           -- Item identifier or -1 if not applicable
    }

    -- Use the API function to scan for the interface
    local interfaceFound = API.ScanForInterfaceTest2Get(true, seedInterface)
    if interfaceFound then
        -- Interface found, proceed with selecting the teleport option
        API.DoAction_Interface(0xFFFFFFFF, 0xFFFFFFFF, 0, 720, 35, -1, API.OFF_ACT_GeneralInterface_Choose_option)
    else
        -- Log the error and stop the script or handle it appropriately
        print("[Error] Expected interface not found after clicking the teleport seed.")
        shouldContinue = false
    end
end

local function moveToChest()
    if currentState == STATE_MOVE_TO_CHEST then
        -- Move to the crystal chest location
        API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {CRYSTAL_CHEST_ID}, 50)
        API.RandomSleep2(1000, 1000, 1000)
        API.WaitUntilMovingEnds()
        API.RandomSleep2(100, 100, 100)
        API.DoAction_Interface(168, 27, 1, 168, 27, -1, API.OFF_ACT_GeneralInterface_route)

        -- After moving to the chest, proceed to click it
        currentState = STATE_CLICK_CHEST
    end
end

local function clickCrystalChest()
    if currentState == STATE_CLICK_CHEST then
        -- Define the chest interface with correct values
        local chestInterface = {
            interfaceId = 168,  -- Interface ID from your log
            componentId = 27,   -- Component ID from your log
            option1 = -1,       -- Additional options or flags, if any
            option2 = -1,       -- Additional options or flags, if any
            item = -1           -- Item identifier or -1 if not applicable
        }

        -- Use the API function to scan for the interface
        local interfaceFound = API.ScanForInterfaceTest2Get(true, chestInterface)
        if interfaceFound then
            -- Proceed with clicking the chest object
            API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {CRYSTAL_CHEST_ID}, 50)
            API.RandomSleep2(600, 700, 600)
            
            -- After clicking the chest, loot interface
            API.DoAction_Interface(168, 27, 1, 168, 27, -1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(500, 700, 500)
            
            chestClicks = chestClicks + 1  -- Increment chest clicks counter

            -- Transition to waiting for keys
            currentState = STATE_WAIT_FOR_KEYS
        else
            -- Log the error and stop the script or handle it appropriately
            print("[Error] Expected interface not found after clicking the chest.")
            shouldContinue = false
        end
    end
end

local function checkKeysAvailable()
    local keyCount = API.InvItemcount_1(KEY_ITEM_ID)

    return keyCount >= REQUIRED_KEY_COUNT
end

---@return number -- script runtime in seconds
function API.ScriptRuntime()
    return ScriptRuntime()
end

---@return string -- script runtime in the format [hh:mm:ss]
function API.ScriptRuntimeString()
    return ScriptRuntimeString()
end

local function handleStates()
    if currentState == STATE_IDLE then
        idleCheck()
        if API.InvItemcount_1(KEY_ITEM_ID) == 0 then
            currentState = STATE_BANK
        else
            currentState = STATE_CLICK_CHEST
        end
    elseif currentState == STATE_BANK then
        TeleportWarRetreat()
        
        API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {BANK_ID}, 50)
        API.RandomSleep2(3500, 4000, 3500)

        -- Check keys after interacting with the bank
        if not checkKeysAvailable() then
            print("Fewer than 28 crystal keys remaining after banking. Stopping script.")
            shouldContinue = false
            return false
        end

        -- Click teleport seed and wait for teleport to Priff
        currentState = STATE_TELEPORT
        clickSeedAndTeleport()
    elseif currentState == STATE_TELEPORT then
        -- After teleporting, wait before proceeding
        API.WaitUntilMovingEnds()
        API.RandomSleep2(3000, 3000, 3000) -- Wait for a reasonable time to ensure teleportation completes
        currentState = STATE_MOVE_TO_CHEST
    elseif currentState == STATE_MOVE_TO_CHEST then
        moveToChest()
    elseif currentState == STATE_CLICK_CHEST then
        clickCrystalChest()
    elseif currentState == STATE_WAIT_FOR_KEYS then
        -- Transition back to IDLE if keys are available
        currentState = STATE_IDLE
    end

    return true
end

-- Main loop
while API.Read_LoopyLoop() and shouldContinue do
    if not handleStates() then
        break
    end
    API.DoRandomEvents()
    API.RandomSleep2(200, 400, 200)
end

-- Print the total number of chest clicks and the runtime when the script stops
print("Total keys used: " .. chestClicks)
print("Script runtime: " .. API.ScriptRuntimeString())
