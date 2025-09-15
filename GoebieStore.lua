-- Title: GoebieStore
-- Author: <Matteus>
-- Description: <Skills and buys supplies from the Goebie store>
-- Version: <1.11>
-- Category: Skilling
-- Date : 2025.03.24

local API = require("api")
local UTILS = require("utils")
local maxIdleTime = 20

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
local trackedSkill = {"HERBLORE", "CRAFTING", "FLETCHING", "MAGIC", "DIVINATION", "PRAYER", "FIREMAKING", "COOKING", "NECROMANCY", "INVENTION",  }
local startXp = {}
local lastXpTime = os.time()

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

for _, skill in ipairs(trackedSkill) do
    startXp[skill] = API.GetSkillXP(skill) or 0
end

local function clickRandomTile(baseX, baseY, range)
    local offsetX = math.random(-range, range)
    local offsetY = math.random(-range, range)
    local randomTile = WPOINT.new(baseX + offsetX, baseY + offsetY, 0)
    API.DoAction_Tile(randomTile)
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

local function isBankopen()
    return API.Compare2874Status(24, false)
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
    if not inventoryItems then return true end 

    local hasArrowshafts = false
    local hasFeathers = false

    for _, item in ipairs(inventoryItems) do
        if item.textitem then
            if string.find(item.textitem, "(shaft)") then
                hasArrowshafts = true
            elseif string.find(item.textitem, "Feather") then
                hasFeathers = true
            end
        end
    end

    if hasArrowshafts and hasFeathers then
        print("Found arrowshafts and feathers, skipping bank reload.")
        return false
    end

    return true
end

local function canDive()
    local dive = API.GetABs_name("Dive")
    if dive.cooldown_timer < 1 and dive.enabled == true then return true
    else return false end
end

local function getEscapeTile(player, soul, distance)
    local dx = player.x - soul.Tile_XYZ.x
    local dy = player.y - soul.Tile_XYZ.y
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag == 0 then return nil end 
    dx = dx / mag * distance
    dy = dy / mag * distance
    return WPOINT.new(math.floor(player.x + dx), math.floor(player.y + dy), player.z)
end

local function DO_ElidinisSouls()
    while true do
        local foundSomething = false

        -- Lost Soul
        if #API.ReadAllObjectsArray({1}, {17720}, {}) > 0 then
            foundSomething = true
            print("Found Lost Soul, interacting")
            API.RandomSleep2(600, 550, 650)
            API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {17720}, 50, true, 0)
            API.RandomSleep2(1500, 550, 650)
            while #API.ReadAllObjectsArray({1}, {17720}, {}) > 0 do
                API.RandomSleep2(200, 50, 50)
            end
        end

        -- Unstable Soul
        if #API.ReadAllObjectsArray({1}, {17739}, {}) > 0 then
            foundSomething = true
            print("Found Unstable Soul, interacting")
            API.RandomSleep2(600, 550, 650)
            API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {17739}, 50, true, 0)
            API.RandomSleep2(1500, 550, 650)
            while #API.ReadAllObjectsArray({1}, {17739}, {}) > 0 do
                API.RandomSleep2(200, 50, 50)
            end
        end

        -- Mimicking Soul
        local mimicSoul = API.ReadAllObjectsArray({1}, {18222}, {})[1]
        if mimicSoul then
        foundSomething = true
        print("Found Mimicking Soul, diving or walking to its tile once...")
        local triedDive = false
        if canDive() then
            print("Dive is ready — executing dive.")
            local tile = mimicSoul.Tile_XYZ
            API.DoAction_Dive_Tile(WPOINT.new(tile.x, tile.y, tile.z))
            API.RandomSleep2(3200, 550, 650)
            triedDive = true
        end
        while API.ReadAllObjectsArray({1}, {18222}, {})[1] do
            local updatedSoul = API.ReadAllObjectsArray({1}, {18222}, {})[1]
            local tile = updatedSoul.Tile_XYZ
            local player = API.PlayerCoord()
            local dx, dy = tile.x - player.x, tile.y - player.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if (not triedDive) or (distance > 1.5) then
                 print("Walking to Mimicking.")
                 API.DoAction_WalkerF(FFPOINT.new(tile.x, tile.y, tile.z))
                 API.RandomSleep2(600, 400, 200)
                end

                API.RandomSleep2(200, 50, 50)
            end
        end

    -- Vengeful Soul
    local soul = API.ReadAllObjectsArray({1}, {17802}, {})[1]

    while soul do
        foundSomething = true
        local player = API.PlayerCoord()
        local dx, dy = soul.Tile_XYZ.x - player.x, soul.Tile_XYZ.y - player.y
        local currentDist = math.sqrt(dx * dx + dy * dy)

        if currentDist <= 7 then
            print("Vengeful Soul is close, dodging...")
            local escapeTile = getEscapeTile(player, soul, 6)
            if escapeTile then
                API.DoAction_Tile(escapeTile)
            else
                local fallbackTile = WPOINT.new(player.x + math.random(-20, 20), player.y + math.random(-20, 20), player.z)
                API.DoAction_Tile(fallbackTile)
            end
            API.RandomSleep2(1200, 100, 100)
        else
            API.RandomSleep2(300, 100, 100)
        end

        soul = API.ReadAllObjectsArray({1}, {17802}, {})[1]
    end

    if not foundSomething then return end
    end
end


local function banking()
    if not shouldBank() then return end

    API.DoAction_NPC(0x5, API.OFF_ACT_InteractNPC_route, { 21393 }, 50)
    UTILS.SleepUntil(isBankopen, 10, "Bank open")

    if isBankopen() then 
        API.RandomSleep2(100, 50, 50)
        API.KeyboardPress("1", 0, 50)
    end

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

    --[[ if uniqueItemCount < 1 then
        print("Error: Less than two different items found after banking. Stopping script.")
        API.Write_LoopyLoop(false)
    end ]]
end

local function banking2()
    API.DoAction_NPC(0x5, API.OFF_ACT_InteractNPC_route, { 21393 }, 50)
    UTILS.SleepUntil(isBankopen, 30, "Bank open")

    API.RandomSleep2(300, 250, 100)

    if isBankopen() then
        API.RandomSleep2(300, 250, 100)
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(300, 250, 100)
     end
end

local function Buypotions()
    local currentTime = os.time()
    if currentTime - lastPotionTime < 100 then return end
    lastPotionTime = currentTime

    banking2()

    print("Opening the shop to buy potions...")
    UTILS.SleepUntil(function()
        return not (API.isProcessing())
    end, 10, "wait for player idle before shop")

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, { 21393 }, 50)
   
    UTILS.SleepUntil(isOpen, 30, "shop to open")

    if not isOpen() then return end

    local potions = { 1, 3, 4, 5, 6, 7, 8 }
    for _, potion in ipairs(potions) do
        if potion == 1 then
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, potion, API.OFF_ACT_GeneralInterface_route)
        else
            API.DoAction_Interface(0xffffffff, 0xffffffff, 2, 1265, 20, potion, API.OFF_ACT_GeneralInterface_route)
        end
        API.RandomSleep2(100, 200, 300)
    end


    print("Potion buying completed.")
end

local function handleCrafting(item1, item2, actionRoute1, actionRoute2, errorMessage, skipWaitInterface)
    if item1 and item2 then
        API.DoAction_Inventory1(item1, 0, 0, actionRoute1)
        API.RandomSleep2(50, 30, 50)
        API.DoAction_Inventory1(item2, 0, 0, actionRoute2)
        API.RandomSleep2(400, 200, 250)

        if skipWaitInterface then
            while API.isProcessing() do
                UTILS.randomSleep(100)
                API.DoRandomEvents()
                DO_ElidinisSouls()
            end
            return true
        elseif waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
            while API.isProcessing() do
                UTILS.randomSleep(100)
                API.DoRandomEvents()
                DO_ElidinisSouls()
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
        API.Write_LoopyLoop(false)
    end

    local unfItem, berryItem, cleanItem, superItem
    local foundItems = {}
    local itemCounts = {} 
    local itemIDs = {}    
    local skipWait = false

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
                                  string.find(item.textitem, "Jug") or
                                  string.find(item.textitem, "crystal") or
                                  string.find(item.textitem, "Yak") or
                                  string.find(item.textitem, "Wine") or
                                  string.find(item.textitem, "++")) then
            cleanItem = item.itemid1
            itemCounts[item.textitem] = (itemCounts[item.textitem] or 0) + 1
            itemIDs[item.textitem] = item.itemid1

        if item.textitem:lower():find("clean torstol") then
            local equippedCape = API.GetEquipSlot(1).itemid1
            if equippedCape == 31278 then
            skipWait = true
            print("Making Batch overloads")
            return nil, nil
            end
        end

        elseif item.textitem and (string.find(item.textitem, "(3)") or string.find(item.textitem, "berries") or string.find(item.textitem, "Grapes")) then
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

    if handleCrafting(cleanItem, superItem, API.OFF_ACT_Bladed_interface_route, API.OFF_ACT_GeneralInterface_route1, "Herblore interface not detected.", skipWait) then
        return true
    end

    return false
end

local function checkForVialOrUnfItems()
    local inventoryItems = API.ReadInvArrays33()

    if not inventoryItems then
        print("Error: Inventory is empty or could not be read.")
        API.Write_LoopyLoop(false)
    end

    local added = {}

    for i = 1, #inventoryItems do
        local item = inventoryItems[i]

        if item.textitem and (
            string.find(item.textitem, "Grimy") or 
            string.find(item.textitem, "water") or
            string.find(item.textitem, "(unfinished)") or 
            string.find(item.textitem, "flask") or
            string.find(item.textitem, "shaft") or
            string.find(item.textitem, "Headless") or
            string.find(item.textitem, "Primal") or
            string.find(item.textitem, "Uncut") or
            string.find(item.textitem, "Logs") or
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
            string.find(item.textitem, "energy") or
            string.find(item.textitem, "stick") or
            string.find(item.textitem, "%((unfired)%)") or
            string.find(item.textitem, "necroplasm") or
            string.find(item.textitem, "refiner") or
            string.find(item.textitem, "milk") or
            string.find(item.textitem, "amulet")
        ) then
            local cleanedName = string.gsub(item.textitem, "<.->", "")
            print("Found item: " .. cleanedName .. " (" .. item.itemid1 .. ")")

            if not added[item.itemid1] and item.itemid1 > 0 then
                added[item.itemid1] = true
                return item.itemid1, cleanedName
            end
        end
    end
end

local function isLunarSpellbook()
    local state = API.VB_FindPSettinOrder(4).state
    return (state & 0x3) == 2
end

local function isNormalSpellbook()
    local state = API.VB_FindPSettinOrder(4).state
    return (state & 0x3) == 0
end

local function hasRunes(runeReqs)
    local staffID = API.GetEquipSlot(3).itemid1

    local skipRunes = {}

    if staffID == 41885 then -- Elemental battlestaff
        skipRunes[554] = true  -- fire
        skipRunes[555] = true  -- water
        skipRunes[556] = true  -- air
        skipRunes[557] = true  -- earth
    elseif staffID == 11736 then -- Steam battlestaff
        skipRunes[554] = true  -- fire
        skipRunes[555] = true  -- water
    elseif staffID == 6562 then -- Mud battlestaff
        skipRunes[555] = true  -- water
        skipRunes[557] = true  -- earth
    elseif staffID == 1393 then -- fire battlestaff
        skipRunes[554] = true  -- fire
    end

    for id, amount in pairs(runeReqs) do
        if not skipRunes[id] and Inventory:InvStackSize(id) < amount then
            print("Missing runes: id=" .. id .. " required=" .. amount)
            return false
        end
    end

    return true
end

local function performCraftingAction()
    local unfItem, itemName = checkForVialOrUnfItems()
    if not unfItem or not itemName then
        API.Write_LoopyLoop(false)
        return
    end

    itemName = itemName:lower()

    if itemName:find("sandstone") then
        if not isLunarSpellbook() then
            print("Not on Lunar spellbook")
            API.Write_LoopyLoop(false)
            return
        end
        local runeReqs = { [556] = 10, [554] = 6, [9075] = 2 }
        if not hasRunes(runeReqs) then
            print("Missing required runes for Superglass Make spell.")
            API.Write_LoopyLoop(false)
            return
        end
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 125, API.OFF_ACT_GeneralInterface_route)
        return
    end

    local amuletCount = Inventory:InvItemcount(39338)
    if amuletCount > 0 then
        if not isNormalSpellbook() then
            print("Not on Normal spellbook")
            API.Write_LoopyLoop(false)
            return
        end
        local runeReqs = { [556] = 3, [564] = 1 }
        if not hasRunes(runeReqs) then
            print("Missing required runes for Enchant Amulet spell.")
            API.Write_LoopyLoop(false)
            return
        end
        API.DoAction_Interface(0x9e,0xffffffff,0,1461,1,29,API.OFF_ACT_Bladed_interface_route) 
        API.RandomSleep2(300, 300, 100)
        API.DoAction_Inventory1(39338,0,0,API.OFF_ACT_GeneralInterface_route1)
        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
        end
        return
    end

    if itemName:find("amulet") then
        if not isLunarSpellbook() then
            print("Not on Lunar spellbook")
            API.Write_LoopyLoop(false)
            return
        end
        local runeReqs = { [555] = 5, [557] = 10, [9075] = 2 }
        if not hasRunes(runeReqs) then
            print("Missing required runes for String Jewelry.")
            API.Write_LoopyLoop(false)
            return
        end
        API.DoAction_Interface(0xffffffff,0xffffffff,1,1461,1,131,API.OFF_ACT_GeneralInterface_route)
        return
    end

    if itemName:find("%((unfired)%)") then
        if not isLunarSpellbook() then
            print("Not on Lunar spellbook")
            API.Write_LoopyLoop(false)
            return
        end
        local runeReqs = { [555] = 5, [557] = 5, [554] = 10, [9075] = 1 }
        if not hasRunes(runeReqs) then
            print("Missing required runes for Fire Urn spell.")
            API.Write_LoopyLoop(false)
            return
        end
        API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 209, API.OFF_ACT_GeneralInterface_route)
        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
        end
        return
    end

    if  itemName:find("miasma rune") or
        itemName:find("mud rune") or
        itemName:find("%((unicorn horn))%") or
        itemName:find("scale") or
        itemName:find("bird's nest") then
            if not isLunarSpellbook() then
                print("Not on Lunar spellbook")
                API.Write_LoopyLoop(false)
                return
            end
            local runeReqs = { [9075] = 2, [563] = 1 }
            if not hasRunes(runeReqs) then
                print("Missing required runes Telekenetic Grind spell.")
                API.Write_LoopyLoop(false)
                return
            end
            API.DoAction_Interface(0x9e, 0xffffffff, 0, 1461, 1, 211, API.OFF_ACT_Bladed_interface_route)
            API.RandomSleep2(300, 300, 100)
            API.DoAction_Inventory1(unfItem, 0, 0, API.OFF_ACT_GeneralInterface_route1)
            return
    end
    
    if itemName:find("energy") then
        if Inventory:InvStackSize(unfItem) < 120 then
            print("Out of energy, stopping.")
            API.Write_LoopyLoop(false)
            return
        end
        if not API.InvItemcount_String("necklace") or API.InvItemcount_String("necklace") < 1 then
            print("No necklace found in inventory, stopping.")
            API.Write_LoopyLoop(false)
            return
        end
    end

    if itemName:find("necroplasm") then
        if Inventory:InvStackSize(unfItem) < 20 then
            print("Out of necroplasm, stopping.")
            API.Write_LoopyLoop(false)
            return
        end
    end

    if itemName:find("grimy") then
        local equippedCape = API.GetEquipSlot(1).itemid1
        if equippedCape == 9775 then
            print("Found 99 Herblore Cape equipped!")
            API.DoAction_Interface(0xffffffff, 0x85db, 3, 1464, 15, 1, API.OFF_ACT_GeneralInterface_route)
        elseif equippedCape == 31278 then
            print("Found 120 Herblore Cape equipped!")
            API.DoAction_Interface(0xffffffff, 0x7a2e, 3, 1464, 15, 1, API.OFF_ACT_GeneralInterface_route)
        else
            print("No Herblore Cape equipped, cleaning them instead.")
        end

        if API.DoAction_Inventory1(unfItem, 0, 1, API.OFF_ACT_GeneralInterface_route) then
            if waitCraftingInterface() then
                API.KeyboardPress32(0x20, 0)
                UTILS.countTicks(5)
            else
                API.Write_LoopyLoop(false)
            end
        end
        return
    end

    if API.DoAction_Inventory1(unfItem, 0, 1, API.OFF_ACT_GeneralInterface_route) then
        if waitCraftingInterface() then
            API.KeyboardPress32(0x20, 0)
            UTILS.countTicks(5)
        else
            API.Write_LoopyLoop(false)
        end
    end
end


API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    checkXpIncrease()
    local function soulsExist()
        return #API.ReadAllObjectsArray({1},{17720},{}) > 0 or
               #API.ReadAllObjectsArray({1},{17739},{}) > 0 or
               #API.ReadAllObjectsArray({1},{18222},{}) > 0 or
               #API.ReadAllObjectsArray({1},{17802},{}) > 0
    end

    while soulsExist() do
        DO_ElidinisSouls()
        UTILS.randomSleep(200)
    end

    if bankingStateCalls >= 2 then
        API.Write_LoopyLoop(false)
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

            while API.isProcessing() 
            --or API.CheckAnim(50) 
            do
                UTILS.randomSleep(100)
                API.DoRandomEvents()
                DO_ElidinisSouls()
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

            if timeDiff >= 120 then
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
