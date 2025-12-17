-- Title: Frames&Walls
-- Author: <Matteus>
-- Description: <Construct frames and walls using logs, planks, refined planks, and limestone. Start at bank with preset.>
-- Version: <1.4>
-- Category: Skilling/Moneymaking
-- Date : 2025.12.17

local API   = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local MAX_BANK_ATTEMPTS = 2
local bankAttempts = 0

local LOGS      = {1511, 1513, 1515, 1517, 1519, 1521, 29556, 6332, 6333, 40285}
local PLANKS    = {960, 8778, 8780, 8782, 54860, 54862, 54864, 54866, 54868, 54870}
local REFINED   = {54444, 54446, 54448, 54450, 54836, 54838, 54840, 54842, 54844, 54846}
local LIMESTONE = {3420}

local function countItems(ids)
    local total = 0
    for _, id in ipairs(ids) do
        total = total + Inventory:GetItemAmount(id)
    end
    return total
end

local function countLogs()      return countItems(LOGS) end
local function countPlanks()    return countItems(PLANKS) end
local function countRefined()   return countItems(REFINED) end
local function countLimestone() return countItems(LIMESTONE) end

local function bank()
    API.DoAction_Object2(0x33, API.OFF_ACT_GeneralObject_route3, {125115}, 50, WPOINT.new(3283,3555,0))
    API.RandomSleep2(500, 800, 50)
    local function hasItems()
        return countLogs() > 0 or countPlanks() >= 4 or countRefined() >= 3 or countLimestone() >= 3
    end
    UTILS.SleepUntil(hasItems, 5, "Waiting for bank to load items...")
end

local function bankCheck()
    bankAttempts = bankAttempts + 1
    if bankAttempts > MAX_BANK_ATTEMPTS then
        print("Exceeded max banking attempts. Exiting script.")
        API.Write_LoopyLoop(false)
        return false
    end
    bank()
    return true
end

local function isOpen()
    return API.Compare2874Status(40, false)
end

local function processStage(itemIDs, minRequired, interfaceName, actionText)
    if countItems(itemIDs) < minRequired then
        bankCheck()
        return
    end

    bankAttempts = 0
    Interact:Object(interfaceName, actionText, 50)

    UTILS.SleepUntil(isOpen, 10, "Waiting for " .. interfaceName .. " interface...")

    API.KeyboardPress32(0x20, 0)
    API.RandomSleep2(1200, 800, 50)

    UTILS.SleepUntil(function() return not API.isProcessing() end, 80, "Processing...")
end

local function handleMaterials()
    if countLimestone() >= 4 then
        processStage(LIMESTONE, 4, "Stonecutter", "Cut stone", 4)
    elseif countRefined() >= 3 then
        processStage(REFINED, 3, "Woodworking bench", "Construct frames", 3)
    elseif countPlanks() >= 4 then
        processStage(PLANKS, 4, "Sawmill", "Process planks", 4)
    elseif countLogs() >= 1 then
        processStage(LOGS, 1, "Sawmill", "Process planks", 1)
    else
        bankCheck()
    end
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do

    API.DoRandomEvents()
    handleMaterials()

    API.RandomSleep2(250, 80, 80)

end



