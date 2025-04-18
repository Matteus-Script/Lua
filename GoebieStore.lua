--[[
# Script Name:   <GoebieStore>
# Description:   <Makes potions and buys supplies from the Goebie store>
# Author:        <Matteus>
# Version:       <1.1>
# Date:          <2025.03.24>
--]]

--[[v1.10 - 31-03-2025
    - Added Fletching methods ( Logs>Unstrung>Bows) (logs>shafts>Headless>Arrows). -- note if crafting unstrung or shafts from logs make sure you make 1 first yourself so it remembers last made item 
]]--

local API = require("api")
local UTILS = require("utils")
local ShouldContinue = true
local maxIdleTime = 20

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local states = {
    Banking = 1,
    Crafting = 2,
    BuyingPotions = 3,
}

local currentState = states.Banking
local lastPotionTime = 0
local lastCycleTime = os.time()
local bankingStateCalls = 0
local firstLoop = true
local trackedSkill = {"HERBLORE", "CRAFTING", "FLETCHING", "MAGIC"}
local startXp = {}
local lastXpTime = os.time()

for _, skill in ipairs(trackedSkill) do
    startXp[skill] = API.GetSkillXP(skill) or 0
end

local function checkXpIncrease()
    local xpGained = false

    for _, skill in ipairs(trackedSkill) do
        local currentXp = API.GetSkillXP(skill) or 0 

        if currentXp > (startXp[skill] or 0) then
            startXp[skill] = currentXp
            lastXpTime = os.time()
            xpGained = true
        end
    end

    if not xpGained then
        local idleTime = os.difftime(os.time(), lastXpTime)
        if idleTime >= maxIdleTime then
            print("No XP increase detected in tracked skills for " .. maxIdleTime .. " seconds. Stopping script.")
            API.Write_LoopyLoop(false) 
        end
    end
end

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false)
end

local function waitCraftingInterface()
    for _ = 1, 50 do
        if isOpen() then return true end
        API.RandomSleep2(100, 200, 300)
    end
    return false
end

local function shouldBank()
    local inventoryItems = API.ReadInvArrays33()
    if not inventoryItems then return true end  -- If inventory can't be read, assume banking is needed.

    for _, item in ipairs(inventoryItems) do
        if item.textitem and (string.find(item.textitem, "(shaft)") or string.find(item.textitem, "(Headless)")) then
            print("Found " .. item.textitem .. ", skipping bank reload.")
            return false
        end
    end

    return true  -- If neither is found, banking is needed.
end

local function banking()
    if not shouldBank() then return end

    API.DoAction_NPC(0x5, API.OFF_ACT_InteractNPC_route, { 21393 }, 50)
    UTILS.countTicks(1)
    if API.BankOpen2 then
        API.KeyboardPress("1", 0, 50)
    end
    UTILS.countTicks(2)

    local inventoryItems = API.ReadInvArrays33()
    local uniqueItems = {}

    if inventoryItems then
        for _, item in ipairs(inventoryItems) do
            if item.itemid1 and item.itemid1 > 0 then
                uniqueItems[item.itemid1] = true
            end
        end
    end

    local uniqueItemCount = 0
    for _ in pairs(uniqueItems) do
        uniqueItemCount = uniqueItemCount + 1
    end

    if uniqueItemCount < 1 then
        print("Error: Less than two different items found after banking. Stopping script.")
        ShouldContinue = false
    end
end



local function banking2()
    API.DoAction_NPC(0x5, API.OFF_ACT_InteractNPC_route, { 21393 }, 50)
    UTILS.countTicks(1)
    if API.BankOpen2 then
        API.KeyboardPress("3", 0, 50)
    end
end

local function Buypotions()
    local currentTime = os.time()
    if currentTime - lastPotionTime < 100 then return end
    lastPotionTime = currentTime

    banking2()

    print("Opening the shop to buy potions...")
    while API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing() do
        UTILS.randomSleep(1000)
    end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, { 21393 }, 50)
    UTILS.randomSleep(1000)

    local maxWaitTime = 10
    local elapsedTime = 0
    local waitInterval = 0.5

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not isOpen() then return end

    local potions = { 1, 3, 4, 5, 6, 7, 8 }
    for _, potion in ipairs(potions) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 2, 1265, 20, potion, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    print("Potion buying completed.")
end

local function handleCrafting(item1, item2, actionRoute1, actionRoute2, errorMessage)
    if item1 and item2 then
        API.DoAction_Inventory1(item1, 0, 0, actionRoute1)
        API.RandomSleep2(50, 30, 50)
        API.DoAction_Inventory1(item2, 0, 0, actionRoute2)
        API.RandomSleep2(400, 200, 250)

        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
            while API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing() do
                UTILS.randomSleep(1000)
                API.DoRandomEvents()
            end
            return true
        else
            print(errorMessage)
        end
    end
    return false
end

local function useCleanOnSuper()
    local inventoryItems = API.ReadInvArrays33()
    if not inventoryItems then
        print("Error: Inventory is empty or could not be read.")
        return false
    end

    local unfItem, berryItem, cleanItem, superItem
    local foundItems = {}
    local itemCounts = {} 
    local itemIDs = {}    

    for _, item in ipairs(inventoryItems) do
        if item.textitem == "Weapon poison++ (unf)" then
            unfItem = item.itemid1
            table.insert(foundItems, "Unf poison: " .. item.textitem)
        elseif item.textitem == "Poison ivy berries" then
            berryItem = item.itemid1
            table.insert(foundItems, "Berries: " .. item.textitem)
        elseif item.textitem and (string.find(item.textitem, "Clean") or 
                                  string.find(item.textitem, "Ground") or 
                                  string.find(item.textitem, "Grenwall") or 
                                  string.find(item.textitem, "Phoenix") or 
                                  string.find(item.textitem, "Papaya") or
                                  string.find(item.textitem, "++")) then
            cleanItem = item.itemid1
            itemCounts[item.textitem] = (itemCounts[item.textitem] or 0) + 1
            itemIDs[item.textitem] = item.itemid1
        elseif item.textitem and (string.find(item.textitem, "(3)") or string.find(item.textitem, "berries")) then
            superItem = item.itemid1
            table.insert(foundItems, "Super item: " .. item.textitem)
        end
    end

    for itemText, count in pairs(itemCounts) do
        table.insert(foundItems, itemText .. " (x" .. count .. ") - Item ID: " .. itemIDs[itemText])
    end

    if #foundItems > 0 then
        print("Found items: " .. table.concat(foundItems, ", "))
    end

    if handleCrafting(unfItem, berryItem, API.OFF_ACT_Bladed_interface_route, API.OFF_ACT_GeneralInterface_route1, "Herblore interface not detected for Weapon poison++ (unf).") then
        return true
    end

    if handleCrafting(cleanItem, superItem, API.OFF_ACT_Bladed_interface_route, API.OFF_ACT_GeneralInterface_route1, "Herblore interface not detected.") then
        return true
    end

    return false
end

local function checkForVialOrUnfItems()
    local inventoryItems = API.ReadInvArrays33()

    if not inventoryItems then
        print("Error: Inventory is empty or could not be read.")
    end

    local added = {}

    for i = 1, #inventoryItems do
        local item = inventoryItems[i]

        if item.textitem and (
            string.find(item.textitem, "Grimy") or 
            string.find(item.textitem, "Vial") or
            string.find(item.textitem, "(unf)") or 
            string.find(item.textitem, "flask") or
            string.find(item.textitem, "shaft") or
            string.find(item.textitem, "Headless") or
            string.find(item.textitem, "Primal") or
            string.find(item.textitem, "Uncut") or
            string.find(item.textitem, "logs") or
            string.find(item.textitem, "(unstrung)") or
            string.find(item.textitem, "leather") or
            string.find(item.textitem, "glass") or
            string.find(item.textitem, "decorated") or
            string.find(item.textitem, "sandstone") or
            string.find(item.textitem, "Unicorn") or
            string.find(item.textitem, "Mud rune") or
            string.find(item.textitem, "Miasma rune") or
            string.find(item.textitem, "nest") or
            string.find(item.textitem, "scale") or
            string.find(item.textitem, "milk")
        ) then
            local cleanedName = string.gsub(item.textitem, "<.->", "") -- remove tags
            print("Found item: " .. cleanedName .. " (" .. item.itemid1 .. ")")

            if not added[item.itemid1] and item.itemid1 > 0 then
                added[item.itemid1] = true
                return item.itemid1, cleanedName
            end
        end
    end
end


local function performCraftingAction()
    local unfItem, itemName = checkForVialOrUnfItems()
    if not unfItem or not itemName then
        return
    end

    itemName = itemName:lower()

    if itemName:find("sandstone") then
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 125, API.OFF_ACT_GeneralInterface_route)
        return
    end

    if itemName:find("decorated") then
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 209, API.OFF_ACT_GeneralInterface_route)
        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
        else
            ShouldContinue = false
        end
        return
    end

    if itemName:find("miasma rune") or
       itemName:find("mud rune") or
       itemName:find("unicorn horn") or
       itemName:find("scale") or
       itemName:find("bird's nest") then
        API.DoAction_Interface(0x9e,0xffffffff,0,1461,1,211,API.OFF_ACT_Bladed_interface_route)
        API.RandomSleep2(300, 300, 100)
        API.DoAction_Inventory1(unfItem,0,0,API.OFF_ACT_GeneralInterface_route1)
        return
    end

    print("Normal crafting with item: " .. itemName)
    if API.DoAction_Inventory1(unfItem, 0, 1, API.OFF_ACT_GeneralInterface_route) then
        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
        else
            ShouldContinue = false
        end
    end
end

while API.Read_LoopyLoop(true) and ShouldContinue do
    checkXpIncrease()

    if bankingStateCalls >= 2 then
        ShouldContinue = false
        break
    end

    if currentState == states.Banking then
        bankingStateCalls = bankingStateCalls + 1
        banking()
        currentState = states.Crafting

    elseif currentState == states.Crafting then
        bankingStateCalls = 0

        if useCleanOnSuper() then
            currentState = states.BuyingPotions
        else
            performCraftingAction()
            API.DoRandomEvents()

            while API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing() do
                UTILS.randomSleep(1000)
                API.DoRandomEvents()
            end

            currentState = states.BuyingPotions
        end

    elseif currentState == states.BuyingPotions then
        bankingStateCalls = 0

        if firstLoop then
            print("First loop, buying potions.")
            Buypotions()
            lastPotionTime = os.time()
            firstLoop = false
        else
            local currentTime = os.time()
            local timeDiff = currentTime - lastPotionTime

            if timeDiff >= 100 then
                Buypotions()
                lastPotionTime = currentTime
            else
                print("Not enough time has passed, skipping potion buying.")
            end
        end
        currentState = states.Banking
    end

    UTILS.randomSleep(1000)
end
