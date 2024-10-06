local API = require('api')

local MAX_IDLE_TIME_MINUTES = 5
local furnaceID = 125137
local BANK_CHEST = 125115
local GEM_ID = 4155 --1615 change this to whatever gem

local SMITHING_IFACE = InterfaceComp5:new(37, 17, -1, -1, 0)

local afk = os.time()

API.SetDrawTrackedSkills(true)

local function handleRandomEventsAndIdle()
    API.DoRandomEvents()

    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)
    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function isSmithingInterfacePresent()
    local success, result = pcall(function()
        return API.ScanForInterfaceTest2Get(true, { SMITHING_IFACE })
    end)
    
    if success then
        return #result > 0
    else
        return false
    end
end

local function smeltMaterials()
    API.DoAction_Object1(0x3f, API.OFF_ACT_GeneralObject_route0, { furnaceID }, 50)
    API.RandomSleep2(2000, 2500, 3500)

    if isSmithingInterfacePresent() then
        API.KeyboardPress32(0x20, 0)  -- Press spacebar
    end

    API.RandomSleep2(450, 500, 550)
end

local function bankGems()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST }, 50)
    API.RandomSleep2(350, 400, 450)
end

local function hasGemsInInventory()
    return API.InvItemcount_1(GEM_ID) > 0
end

local function waitForInventoryUpdate()
    local maxWaitTime = 3000  -- Maximum wait time in milliseconds (3 seconds)
    local checkInterval = 500  -- Interval between checks in milliseconds
    local elapsedTime = 0

    while elapsedTime < maxWaitTime do
        API.RandomSleep2(checkInterval, checkInterval, checkInterval)
        if hasGemsInInventory() then
            return true
        end
        elapsedTime = elapsedTime + checkInterval
    end

    return false
end

while API.Read_LoopyLoop() do
    handleRandomEventsAndIdle()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if hasGemsInInventory() then
            smeltMaterials()

            while hasGemsInInventory() do
                handleRandomEventsAndIdle()
                API.RandomSleep2(500, 600, 700)
            end
        end

        bankGems()

        --if not waitForInventoryUpdate() then
        --    print("No more gems in inventory, stopping the script.")
        --    break
        --end
    end

    API.RandomSleep2(500, 500, 500)
end
