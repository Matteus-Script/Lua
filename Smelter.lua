--[[
# Script Name:   Smelter
# Description:   Smelts bars and deposits them in the furnace
# Author:        Matteus
# Version:       1.0
# Date:          2025.12.17
--]]

local API = require('api')
local UTILS = require('utils')

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local function isOpen()
    return API.Compare2874Status(85, false)
end

local trackedSkill = "SMITHING"
local startXp = API.GetSkillXP(trackedSkill)
local lastXpTime = os.time()
local maxIdleTime = 40

local function checkXpIncrease()
    local currentXp = API.GetSkillXP(trackedSkill)
    if currentXp > startXp then
        startXp = currentXp
        lastXpTime = os.time()
        return
    end

    if os.difftime(os.time(), lastXpTime) >= maxIdleTime then
        print("No XP increase detected in " .. trackedSkill .. " for " .. maxIdleTime .. " seconds. Stopping script.")
        API.Write_LoopyLoop(false)
    end
end

local BAR_SELECTION = {
    Bronze = {action = function() API.DoAction_Interface(0xffffffff, 0x92d, 1, 37, 103, 1, API.OFF_ACT_GeneralInterface_route) end},
    Iron = {action = function() API.DoAction_Interface(0xffffffff, 0x92f, 1, 37, 103, 3, API.OFF_ACT_GeneralInterface_route) end},
    Steel = {action = function() API.DoAction_Interface(0xffffffff, 0x931, 1, 37, 103, 5, API.OFF_ACT_GeneralInterface_route) end},
    Mithril = {action = function() API.DoAction_Interface(0xffffffff, 0x937, 1, 37, 103, 7, API.OFF_ACT_GeneralInterface_route) end},
    Adamant = {action = function() API.DoAction_Interface(0xffffffff, 0x939, 1, 37, 103, 9, API.OFF_ACT_GeneralInterface_route) end},
    Rune = {action = function() API.DoAction_Interface(0xffffffff, 0x93b, 1, 37, 103, 11, API.OFF_ACT_GeneralInterface_route) end},
    Orikalkum = {action = function() API.DoAction_Interface(0xffffffff, 0xaf26, 1, 37, 103, 13, API.OFF_ACT_GeneralInterface_route) end},
    Necronium = {action = function() API.DoAction_Interface(0xffffffff, 0xaf28, 1, 37, 103, 15, API.OFF_ACT_GeneralInterface_route) end},
    Bane = {action = function() API.DoAction_Interface(0xffffffff, 0xaf2a, 1, 37, 103, 17, API.OFF_ACT_GeneralInterface_route) end},
    ElderRune = {action = function() API.DoAction_Interface(0xffffffff, 0xaf2c, 1, 37, 103, 19, API.OFF_ACT_GeneralInterface_route) end},
    Primal = {action = function() API.DoAction_Interface(0xffffffff, 0xe05b, 1, 37, 103, 21, API.OFF_ACT_GeneralInterface_route) end},
    Silver = {action = function() API.DoAction_Interface(0xffffffff, 0x1ba, 1, 37, 52, 51, API.OFF_ACT_GeneralInterface_route) end},
    Gold = {action = function() API.DoAction_Interface(0xffffffff, 0x1bc, 1, 37, 52, 53, API.OFF_ACT_GeneralInterface_route) end},
    Cannonball = {action = function()
        if not isOpen() then
            API.DoAction_Interface(0xffffffff, 0x2, 1, 37, 62, 17, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(500, 700, 100) 
            API.DoAction_Interface(0xffffffff, 0xe9fe, 1, 37, 103, 5, API.OFF_ACT_GeneralInterface_route)
        end
    end}
}

local selectedBar = nil 

local function getOptionSelection(option_string, tbl)
    local options = {}
    for _, bar in ipairs({"Bronze", "Iron", "Steel", "Mithril", "Adamant", "Rune", "Orikalkum", "Necronium", "Bane", "ElderRune", "Primal", "Silver", "Gold", "Cannonball"}) do
        if tbl[bar] then
            table.insert(options, bar)
        end
    end

    local selection = API.ScriptDialogWindow2(option_string, options, "Start", "Close").Name
    return selection
end

selectedBar = getOptionSelection("Select Bar Type", BAR_SELECTION)
if not BAR_SELECTION[selectedBar] then
    print("Invalid bar selection. Exiting script.")
    return
end

print("Selected Bar: " .. selectedBar)

local firstRun = true

local function performInterfaceAction(action, ...)
    action(...)
    API.RandomSleep2(500, 700, 100)
end

local function hasElvenRitualShard()
    return Inventory:InvItemcount(43358) > 0
end

local function hasRequiredItem()
    return hasElvenRitualShard() or API.GetEquipSlot(5).itemid1 == 50806
end

local function isChronicleAttractionOnBar()
    local chronicle = API.GetABs_name("Chronicle Attraction", true)
    return chronicle ~= nil
end

local function isSuperheatFormOnBar()
    local superheat = API.GetABs_name("Superheat Form", true)
    return superheat ~= nil
end

local function checkBuffs()
    local hasShard = hasElvenRitualShard()
    local hasFurnaceCore = API.GetEquipSlot(5).itemid1 == 50806

    if not (hasShard and hasFurnaceCore) then
        return
    end

    local buffsToCheck = {
        --[[ {id = 26053, name = "Chronicle Attraction", action = function()
            if isChronicleAttractionOnBar() then
                print("Activating Chronicle Attraction from ability bar.")
                local success = API.DoAction_Ability("Chronicle Attraction", 1, API.OFF_ACT_GeneralInterface_route)
                if not success then
                    print("Chronicle Attraction activation failed on ability bar. Falling back to interface.")
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 30, API.OFF_ACT_GeneralInterface_route)
                end
            else
                print("Chronicle Attraction not found on ability bar. Falling back to interface.")
                performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 30, API.OFF_ACT_GeneralInterface_route)
            end
        end}, ]]
        {id = 26055, name = "Superheat Form", action = function()
            if isSuperheatFormOnBar() then
                print("Activating Superheat Form from ability bar.")
                local success = API.DoAction_Ability("Superheat Form", 1, API.OFF_ACT_GeneralInterface_route)
                if not success then
                    print("Superheat Form activation failed on ability bar. Falling back to interface.")
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 34, API.OFF_ACT_GeneralInterface_route)
                end
            else
                print("Superheat Form not found on ability bar. Falling back to interface.")
                performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 34, API.OFF_ACT_GeneralInterface_route)
            end
        end}
    }

    for _, buff in ipairs(buffsToCheck) do
        local buffStatus = API.Buffbar_GetIDstatus(buff.id)
        if not buffStatus.found then
            print("Activating missing buff: " .. buff.name)
            buff.action()
        end
    end
end

local ORE_REQUIREMENTS = {
    Bronze = { [436] = 1, [438] = 1 }, -- Copper Ore, Tin Ore
    Iron = { [440] = 2 }, -- Iron Ore
    Steel = { [440] = 1, [453] = 1 }, -- Iron Ore, Coal
    Silver = { [442] = 1 }, -- Silver Ore
    Gold = { [444] = 1 }, -- Gold Ore
    Mithril = { [447] = 1, [453] = 1 }, -- Mithril Ore, Coal
    Adamant = { [449] = 1, [44820] = 1 }, -- Adamantite Ore, Luminite Ore
    Rune = { [451] = 1, [44820] = 1 }, -- Runite Ore, Luminite Ore
    Orikalkum = { [44824] = 1, [44822] = 1 }, -- Drakolith, Orichalcite
    Necronium = { [44826] = 1, [44828] = 1 }, -- Necrite, Phasmatite
    Bane = { [21778] = 2 }, -- Banite Ore
    ElderRune = { [44830] = 1, [44832] = 1, [2363] = 1 }, -- Light Animica, Dark Animica, Runite Bar
    Primal = { [57175] = 1, [57177] = 1, [57179] = 1, [57181] = 1, [57183] = 1, [57185] = 1, [57187] = 1, [57189] = 1, [57191] = 1, [57193] = 1 }, -- Various ores
    Cannonball = { [2353] = 2 } -- Steel Bar
}

local ORE_NAMES = {
    [436] = "Copper Ore",
    [438] = "Tin Ore",
    [440] = "Iron Ore",
    [442] = "Silver Ore",
    [444] = "Gold Ore",
    [447] = "Mithril Ore",
    [453] = "Coal",
    [449] = "Adamantite Ore",
    [44820] = "Luminite Ore",
    [451] = "Runite Ore",
    [44824] = "Drakolith",
    [44822] = "Orichalcite",
    [44826] = "Necrite",
    [44828] = "Phasmatite",
    [21778] = "Banite Ore",
    [44830] = "Light Animica",
    [44832] = "Dark Animica",
    [2363] = "Runite Bar",
    [57175] = "Novite ore",
    [57177] = "Bathus ore",
    [57179] = "Marmaros ore",
    [57181] = "Kratonium ore",
    [57183] = "Fractite ore",
    [57185] = "Zephyrium ore",
    [57187] = "Argonite ore",
    [57189] = "Katagon ore",
    [57191] = "Gorgonite ore",
    [57193] = "Promethium ore",
    [2353] = "Steel Bar" 
}

local function hasSufficientOres(barType)
    local required = ORE_REQUIREMENTS[barType]
    if not required then
        print("No ore requirements defined for bar type: " .. barType)
        return false
    end

    if not isOpen() then
        print("Furnace interface is not open. Cannot check contents.")
        return false
    end

    local furnaceContainerId = 858
    local items = API.Container_Get_all(furnaceContainerId)
    if not items or #items == 0 then
        print("The furnace container is empty or not accessible.")
        return false
    end

    local itemCounts = {}
    for _, item in ipairs(items) do
        itemCounts[item.item_id] = (itemCounts[item.item_id] or 0) + item.item_stack
    end

    for itemId, quantity in pairs(required) do
        local available = itemCounts[itemId] or 0
        local oreName = ORE_NAMES[itemId] or "Unknown Ore"
        if available < quantity then
            print(string.format("Missing ore: %s (Item ID %d). Required: %d, Available: %d", oreName, itemId, quantity, available))
            return false, oreName
        else
            print(string.format("Sufficient ore: %s (Item ID %d). Required: %d, Available: %d", oreName, itemId, quantity, available))
        end
    end

    return true, nil
end

local function checkFurnaceContents(barType)
    if not barType then
        print("Error: Bar type is nil. Cannot check furnace contents.")
        return false
    end

    local required = ORE_REQUIREMENTS[barType]
    if not required then
        print("No ore requirements defined for bar type: " .. barType)
        return false
    end

    if not isOpen() then
        print("Furnace interface is not open. Cannot check contents.")
        return false
    end

    local furnaceContainerId = 858
    local items = API.Container_Get_all(furnaceContainerId)
    if not items or #items == 0 then
        print("The furnace container is empty or not accessible.")
        return false
    end

    local itemCounts = {}
    for _, item in ipairs(items) do
        itemCounts[item.item_id] = (itemCounts[item.item_id] or 0) + item.item_stack
    end

    for itemId, quantity in pairs(required) do
        local available = itemCounts[itemId] or 0
        print(string.format("Checking %s in furnace: Required %d, Available %d", itemId, quantity, available))
        if available < quantity then
            print(string.format("Insufficient item ID %d in furnace: Required %d, Available %d", itemId, quantity, available))
            return false
        end
    end

    return true
end

local function smeltMaterials()
    local maxRetries = 3
    local retries = 0
    while retries < maxRetries do
        Interact:Object("Furnace", "Smelt", 20)
        API.RandomSleep2(1200, 1000, 500)

        if isOpen() then
            break
        end

        retries = retries + 1
        print("Furnace interface failed to open. Retrying... (Attempt " .. retries .. "/" .. maxRetries .. ")")
    end

    if not isOpen() then
        print("Furnace interface failed to open after " .. maxRetries .. " attempts. Stopping script.")
        API.Write_LoopyLoop(false)
        return
    end

    if not hasSufficientOres(selectedBar) then
        print("Not enough ores in furnace to smelt " .. (selectedBar or "Unknown") .. ". Stopping script.")
        API.Write_LoopyLoop(false)
        return
    end

    if UTILS.SleepUntil(isOpen, 10, "Waiting for smithing interface to open") then
        if firstRun then
            local barConfig = BAR_SELECTION[selectedBar]
            if barConfig then
                print("Selecting bar: " .. selectedBar)
                if selectedBar == "Bronze" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x1b4, 1, 37, 52, 1, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Iron" or selectedBar == "Steel" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x1b8, 1, 37, 52, 5, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Mithril" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x1c5, 1, 37, 52, 7, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Adamant" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x1c1, 1, 37, 52, 11, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Rune" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x1c3, 1, 37, 52, 15, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Orikalkum" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xaf16, 1, 37, 52, 17, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Necronium" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xaf1a, 1, 37, 52, 21, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Bane" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x5512, 1, 37, 52, 25, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "ElderRune" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xaf1e, 1, 37, 52, 27, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Primal" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xdf59, 1, 37, 52, 33, API.OFF_ACT_GeneralInterface_route)
                elseif selectedBar == "Cannonball" then
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0x2, 1, 37, 62, 17, API.OFF_ACT_GeneralInterface_route)
                    API.RandomSleep2(500, 700, 100) 
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xe9fe, 1, 37, 103, 5, API.OFF_ACT_GeneralInterface_route)
                    
                end

                API.RandomSleep2(1000, 1200, 100) 
                barConfig.action()
            else
                print("Invalid bar selection: " .. tostring(selectedBar))
            end
            firstRun = false
        end
        API.KeyboardPress32(0x20)
    else
        print("Failed to open smithing interface.")
    end

    API.RandomSleep2(500, 700, 100)
end

local function isElvenRitualShardOnBar()
    local shard = API.GetABs_name("Ancient elven ritual shard", true)
    return shard ~= nil
end

local function useElvenRitualShard()
    if not hasElvenRitualShard() then 
        return 
    end

    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(43358, false)

    if prayer < 70 and not elvenCD.found then
        if isElvenRitualShardOnBar() then
            print("Activating Ancient Elven Ritual Shard from ability bar.")
            local success = API.DoAction_Ability("Ancient elven ritual shard", 1, API.OFF_ACT_GeneralInterface_route)
            if not success then
                print("Ancient Elven Ritual Shard activation failed on ability bar. Falling back to inventory.")
                API.DoAction_Inventory1(43358, 43358, 1, API.OFF_ACT_GeneralInterface_route)
            end
        else
            print("Activating Ancient Elven Ritual Shard from inventory.")
            API.DoAction_Inventory1(43358, 43358, 1, API.OFF_ACT_GeneralInterface_route)
        end
        API.RandomSleep2(600, 700, 100)
    end
end

while API.Read_LoopyLoop() do
    if not (API.isProcessing()) then
        smeltMaterials() 
    end
    if Inventory:IsFull() then
        Interact:Object("Furnace", "Deposit-all (into metal bank)")
        print("Depositing bars into furnace.")
        API.RandomSleep2(600, 500, 100)   
    end
    checkXpIncrease()
    useElvenRitualShard()
    checkBuffs() 
    API.DoRandomEvents()
    API.RandomSleep2(600, 700, 100)
end

checkFurnaceContents()
