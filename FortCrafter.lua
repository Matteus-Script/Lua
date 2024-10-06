--[[
# Script Name:   <Fort Crafter (Ironman)>
# Description:   <Automates Crafting in Fort Forinthry for Ironman accounts>
# Author:        <Matteus>
# Version:       <1.30>
# Date:          <2024.09.14>
--]]

API = require("api")

API.SetDrawTrackedSkills(true)

local MAX_IDLE_TIME_MINUTES = 5
local REQUIRED_ITEMS = {
    leather = 27,
    gems = 28,
    porters = 27,
    arrowshafts = 1,
    feathers = 1,
    headlessArrows = 1,
    necroplasm = 1,  
    ash = 1,
    vialOfWater = 1,
    flax = 25  
}

local states = {
    Bank = 0,
    Gems = 1,
    Leather = 2,
    Orbs = 3,
    Urns = 4,
    Superglassmake = 5,
    Porters = 6,
    Arrows = 7,
    FullArrows = 8,
    Inks = 9,
    Flax = 10  
}

local itemIds = {
    gems = {1625, 1627, 1629, 1623, 1621, 1619, 1617, 1631, 6571, 1519, 32845, 23193, 1517, 1515},
    leather = {1745, 1513, 2505, 2507, 2509, 24374, 56075, 29556},
    orbs = {571, 573, 569, 575, 48961, 68, 64 },
    urns = {39008, 40916, 20343, 40796, 20373, 20403, 40836, 40876},
    superglassmake = {32847, 23194},
    porter = 1664,
    energy = 29324,
    arrowshaft = 52,
    feather = 314,
    headlessArrow = 53,
    necroplasm = {55599, 55600, 55601},
    ash = 592,
    vialOfWater = 227,
    flax = 1779  
}

local bankChestIds = {125734, 125115}

local state = states.Bank
local afk = os.time()

local function countItems(ids)
    local count = 0
    for _, id in ipairs(ids) do
        count = count + API.InvItemcount_1(id)
    end
    return count
end

local function idleCheck()
    if os.difftime(os.time(), afk) > math.random(MAX_IDLE_TIME_MINUTES * 36, MAX_IDLE_TIME_MINUTES * 54) then
        API.PIdle2()
        afk = os.time()
    end
end

local function getSelectedItemId()
    return API.VB_FindPSettinOrder(1170, 0).state
end

local function isOpen()
    return getSelectedItemId() ~= -1 and (API.Compare2874Status(18, false) or API.Compare2874Status(40, false))
end

local function waitCraftingInterface()
    for _ = 1, 50 do  
        if isOpen() then return true end
        API.RandomSleep2(100, 200, 300) 
    end
    return false
end

local function performCraftingAction(itemIds)
    for _, id in ipairs(itemIds) do
        if API.DoAction_Inventory1(id, 0, 1, API.OFF_ACT_GeneralInterface_route) then
            if waitCraftingInterface() then
                API.KeyboardPress32(0x20, 0)  
                return
            else
                state = states.Bank
                return
            end
        end
    end
    state = states.Bank
end

local function getItemCounts()
    return {
        gems = countItems(itemIds.gems),
        leather = countItems(itemIds.leather),
        orbs = countItems(itemIds.orbs),
        urns = countItems(itemIds.urns),
        superglassmake = countItems(itemIds.superglassmake),
        porters = API.InvItemcount_1(itemIds.porter),
        energy = API.InvItemcount_1(itemIds.energy),
        arrowshafts = API.InvItemcount_1(itemIds.arrowshaft),
        feathers = API.InvItemcount_1(itemIds.feather),
        headlessArrows = API.InvItemcount_1(itemIds.headlessArrow),
        necroplasm = countItems(itemIds.necroplasm),
        ash = API.InvItemcount_1(itemIds.ash),
        vialOfWater = API.InvItemcount_1(itemIds.vialOfWater),
        flax = API.InvItemcount_1(itemIds.flax)  
    }
end

local function checkState()
    local counts = getItemCounts()

    if counts.leather >= REQUIRED_ITEMS.leather then
        return states.Leather
    elseif counts.gems >= REQUIRED_ITEMS.gems then
        return states.Gems
    elseif counts.orbs > 0 then
        return states.Orbs
    elseif counts.urns > 0 then
        return states.Urns
    elseif counts.superglassmake > 0 then
        return states.Superglassmake
    elseif counts.porters >= REQUIRED_ITEMS.porters and counts.energy > 0 then
        return states.Porters
    elseif counts.arrowshafts >= REQUIRED_ITEMS.arrowshafts and counts.feathers >= REQUIRED_ITEMS.feathers then
        return states.Arrows
    elseif counts.headlessArrows >= REQUIRED_ITEMS.headlessArrows then
        return states.FullArrows
    elseif counts.necroplasm >= REQUIRED_ITEMS.necroplasm and counts.ash >= REQUIRED_ITEMS.ash and counts.vialOfWater >= REQUIRED_ITEMS.vialOfWater then
        return states.Inks
    elseif counts.flax >= REQUIRED_ITEMS.flax then  
        return states.Flax  
    else
        return states.Bank
    end
end

local function loadLastPreset()
    for _, chestId in ipairs(bankChestIds) do
        if API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {chestId}, 15) then
            API.RandomSleep2(600, 650, 700)
            return
        end
    end
end

local function checkInventoryAfterBanking()
    API.RandomSleep2(600, 650, 700)
    local counts = getItemCounts()
    if not (counts.gems >= REQUIRED_ITEMS.gems or
           counts.leather >= REQUIRED_ITEMS.leather or
           counts.orbs > 0 or
           counts.urns > 0 or
           counts.superglassmake > 0 or
           (counts.porters >= REQUIRED_ITEMS.porters and counts.energy > 0) or
           (counts.arrowshafts >= REQUIRED_ITEMS.arrowshafts and counts.feathers >= REQUIRED_ITEMS.feathers) or
           (counts.headlessArrows >= REQUIRED_ITEMS.headlessArrows) or
           (counts.necroplasm >= REQUIRED_ITEMS.necroplasm and counts.ash >= REQUIRED_ITEMS.ash and counts.vialOfWater >= REQUIRED_ITEMS.vialOfWater) or
           counts.flax >= REQUIRED_ITEMS.flax) then  
        print("Not enough or no Crafting materials found. Stopping script.")
        return false
    end
    return true
end

local function handleState()
    local stateHandlers = {
        [states.Gems] = function() performCraftingAction(itemIds.gems)
            state = states.Bank
        end,
        [states.Leather] = function()
            performCraftingAction(itemIds.leather)
            state = states.Bank 
        end,
        [states.Orbs] = function() performCraftingAction(itemIds.orbs) 
            state = states.Bank
        end,
        [states.Urns] = function()
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 209, API.OFF_ACT_GeneralInterface_route)
            if waitCraftingInterface() then
                API.KeyboardPress32(0x20, 0)
                API.RandomSleep2(500, 600, 700)
                state = states.Bank
            end
        end,
        [states.Superglassmake] = function()
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 125, API.OFF_ACT_GeneralInterface_route)
            state = states.Bank
        end,
        [states.Porters] = function()
            if API.InvItemcount_1(itemIds.energy) > 0 then
                performCraftingAction({itemIds.energy})
            else
                state = states.Bank
            end
        end,
        [states.Arrows] = function() performCraftingAction({itemIds.arrowshaft}) end,
        [states.FullArrows] = function() performCraftingAction({itemIds.headlessArrow}) end,
        [states.Inks] = function() performCraftingAction(itemIds.necroplasm) end,
        [states.Flax] = function()  
            API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,194,API.OFF_ACT_GeneralInterface_route)
            state = states.Bank
        end
    }

    (stateHandlers[state] or function() print("Unknown state.") end)()
end

-- Main loop
while API.Read_LoopyLoop() do
    idleCheck()
    API.DoRandomEvents()

    if not (API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing()) then
        if state == states.Bank then
            loadLastPreset()
            if not checkInventoryAfterBanking() then return end
            state = checkState()
        else
            handleState()
        end
    end

    API.RandomSleep2(50, 75, 100)
end
