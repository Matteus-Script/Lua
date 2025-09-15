-- Title: Shoprunner
-- Author: <Matteus>
-- Description: <Buys from most shops (Runes, Meat packs, Broads, Slayer gems, Mines Sandstone, Claims potato cactus)>
-- Version: <1.3.5>
-- Category: Dailies
-- Date : 2025.03.24

local API = require("api")
local LODESTONES = require("lodestones")       
local UTILS = require("utils")

local SHOP_STATUS = {
    Lunar = true,
    Yannile = true,
    Sarim = true,
    Void = true,
    Varrock = true,
    AlKharid = true,
    ZamorakMage = true,
    Magebank = true,
    Ooglog = true,
    Redsandstone = true,
    MenaphosSandstone = true,
    Crystalsandstone = true,
    TaverlyHerb = true,
    FortHerbshop = true,
    PriffherbShop = true,
    ClaimpotatoCactus = true,
    Buybroads = true, 
    Flies = true,
    Mawsandstone = true,
}

local SHOP_BUY_LIST = {
    { 225,   "-- Limpwurt root"           },
    { 235,   "-- Unicorn horn dust"       },
    { 239,   "-- White berries"           },
    { 554,   "-- Fire rune"               },
    { 555,   "-- Water rune"              },
    { 556,   "-- Air rune"                },
    { 557,   "-- Earth rune"              },
    { 558,   "-- Mind rune"              },
    { 559,   "-- Body rune"              },
    { 560,   "-- Death rune"             },
    { 561,   "-- Nature rune"            },
    { 562,   "-- Chaos rune"             },
    { 563,   "-- Law rune"               },
    { 564,   "-- Cosmic rune"            },
    { 565,   "-- Blood rune"             },
    { 566,   "-- Soul rune"              },
    { 9075,  "-- Astral rune"            },
    { 13278, "-- Broad arrowheads"       },
    { 15363, "-- Vial of water Pack"     },
    { 15364, "-- Eye of newt Pack"       },
    { 15365, "-- Raw bird pack"          },
    { 42447, "-- Enchanted gem pack"     },
    { 48960, "-- Powerburst vials"       },
    { 48961, "-- Bomb vial"              },
    { 49281, "-- Flies"                  },
    { 50246, "-- Raw rabbit pack"        },
    { 50247, "-- Raw beef pack"          },
}

local function checkContainerItems(containerID, itemIDs)
    local items = API.Container_Get_all(containerID)
    if not items or #items == 0 then
        print("Container is empty or not accessible.")
        return {}
    end

    local found = {}
    for _, id in ipairs(itemIDs) do
        found[id] = false
    end
    for _, item in ipairs(items) do
        if found[item.item_id] ~= nil and item.item_stack > 0 then
            found[item.item_id] = true
        end
    end
    for id, present in pairs(found) do
        print(string.format("Item ID: %d, In stock: %s", id, tostring(present)))
    end
    return found
end

local function BuyFromShopContainer(containerID)
    local shopItems = API.Container_Get_all(containerID)
    if not shopItems or #shopItems == 0 then
        print("Shop container is empty or not accessible.")
        return
    end

    local idToSlot = {}
    for i, item in ipairs(shopItems) do
        if item.item_id then
            idToSlot[item.item_id] = {slot = i - 1, stack = item.item_stack}
        end
    end

    for _, entry in ipairs(SHOP_BUY_LIST) do
        local itemID, comment = entry[1], entry[2]
        local slotInfo = idToSlot[itemID]
        if slotInfo and slotInfo.stack > 0 then
            print(string.format("Buying slot %d (ID %d) %s", slotInfo.slot, itemID, comment or ""))
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, slotInfo.slot, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end
    end
end

local function abilityWait()
    API.RandomSleep2(2000, 3000, 500)
end
local function canDive()
    local dive = API.GetABs_name("Dive", true)  
    if dive and dive.cooldown_timer < 1 and dive.enabled == true then
        return true
    else
        return false
    end
end

local function canSurge()
    local surge = API.GetABs_name("Surge", true) 
    if surge and surge.cooldown_timer < 1 and surge.enabled == true then
        return true
    else
        return false
    end
end

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false)
end

local function OpenDoor(openDoorID, openX, openY, closedDoorID, closedX, closedY)
    local openPoint = WPOINT.new(openX, openY, 0)
    local closedPoint = WPOINT.new(closedX, closedY, 0)

    local function isDoorOpen()
        local count = #API.GetAllObjArray2({openDoorID}, 5, {0}, openPoint)
        return count > 0
    end

    if not isDoorOpen() then
        API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {closedDoorID}, 5)
        UTILS.SleepUntil(isDoorOpen, 10, "Waiting for door to open")
    end

    return isDoorOpen()
end

local function clickRandomTile(baseX, baseY, range)
    local offsetX = math.random(-range, range)
    local offsetY = math.random(-range, range)
    local randomTile = WPOINT.new(baseX + offsetX, baseY + offsetY, 0)
    API.DoAction_Tile(randomTile)
end

local function randomizeDiveCoordinates(baseX, baseY, baseZ, range)
    local xOffset = math.random(-range, range)
    local yOffset = math.random(-range, range)
    local zOffset = math.random(-range, range)
    return WPOINT.new(baseX + xOffset, baseY + yOffset, baseZ + zOffset)
end

local function checkCues()
    local chatTexts = API.GatherEvents_chat_check()
    for k, v in pairs(chatTexts) do
        if k > 10 then break end  

        for _, cue in ipairs({"You empty the rock of sandstone."}) do
            if string.find(v.text, cue) then
                return true
            end 
        end
    end
    return false
end

local function Lunar()
    LODESTONES.LUNAR_ISLE.Teleport()
    clickRandomTile(2092, 3931, 2)
    UTILS.countTicks(8)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2100, 3929, 0, 1)) else abilityWait() end
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {4512}, 50)
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {4512}, 50)

    UTILS.SleepUntil(function()
        return API.PInArea(3103, 5, 4447, 5, 0)
    end, 15, "Arrival at Lunar isle target area")

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {4513}, 50)

    local opened = UTILS.SleepUntil(isOpen, 10, "Lunar shop open")
    if not opened then return end

    BuyFromShopContainer(419)
    SHOP_STATUS.Lunar = false
end

local function buyMagesGuild()
    LODESTONES.YANILLE.Teleport()

    local function inMagesGuild()
        return API.PInArea(2585, 1, 3088, 1, 0)
    end

    local function isAtShop()
        return API.PInArea(2590, 1, 3092, 1, 0)
    end

    clickRandomTile(2565, 3091, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2573, 3092, 0, 2)) else abilityWait() end
    API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {1600}, 50)
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {1600}, 50)

    local insideGuild = UTILS.SleepUntil(inMagesGuild, 10, "entering Mage Guild")
    if not insideGuild then return end

    API.DoAction_Object1(0x34, API.OFF_ACT_GeneralObject_route0, {1722}, 50)
    UTILS.countTicks(3)

    local atShop = UTILS.SleepUntil(isAtShop, 10, "reaching Mage Guild shop")
    if not atShop then return end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {461}, 50)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Mage Guild shop open")
    if not opened then return end

    BuyFromShopContainer(64) 
    SHOP_STATUS.Yannile = false
end


local function BuySarim()
    LODESTONES.PORT_SARIM.Teleport()
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3021, 3227, 0, 1)) else abilityWait() end
    clickRandomTile(3019, 3259, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3018, 3259, 1)
    local atdoor = UTILS.SleepUntil(function()
        return API.PInArea(3019, 3, 3258, 3)
    end, 10, "reaching Sarim shop door")
    OpenDoor(40109, 3016, 3259, 40108, 3017, 3259)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {583}, 50)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Port Sarim shop open")
    if not opened then return end

    BuyFromShopContainer(25) 
    SHOP_STATUS.Sarim = false
end

local function BuyVoid()
    LODESTONES.PORT_SARIM.Teleport()

    Interact:NPC("Squire", "Travel")

    local function atVoidIsland()
        return API.PInArea(2651, 10, 2673, 10, 0)
    end

    local arrived = UTILS.SleepUntil(atVoidIsland, 15, "arrival at Void Knight Island")
    if not arrived then return end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {3798}, 50)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Void Knight shop open")
    if not opened then return end

    BuyFromShopContainer(388) 
    SHOP_STATUS.Void = false
end

local function BuyVarrock()
    LODESTONES.VARROCK.Teleport()
    clickRandomTile(3218, 3390, 2)
    UTILS.countTicks(2)
    if canSurge() then UTILS.surge() end
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3233, 3390, 0, 2)) end
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() end
    clickRandomTile(3253, 3397, 1)

    local reachedShop = UTILS.SleepUntil(function()
        return API.PInArea(3253, 2, 3397, 2, 0)
    end, 20, "reaching Varrock rune shop")
    if not reachedShop then return end

    OpenDoor(24383, 3253, 3399, 24384, 3253, 3398)
    Interact:NPC("Aubury", "Trade", 8)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Varrock rune shop open")
    if not opened then return end

    BuyFromShopContainer(5) 
    SHOP_STATUS.Varrock = false
end

local subreqs_14 = {
    { name = "Runes",     value = 5, varbits = {9471} },
    { name = "Blackjacks", value = 3, varbits = {9469} },
    { name = "Clothes",    value = 3, varbits = {9470} }
}

local function isCompleted(subreq)
    for _, id in ipairs(subreq.varbits) do
        if API.GetVarbitValue(id) < subreq.value then return false end
    end
    return true
end

local function BuyAlkharid()
    local runesDone = isCompleted(subreqs_14[1])
    local blackjacksDone = isCompleted(subreqs_14[2])
    local clothesDone = isCompleted(subreqs_14[3])

    if not runesDone then
        print("[RogueTrader] Runes not completed, skipping shop.")
        SHOP_STATUS.AlKharid = false
        return
    elseif runesDone and blackjacksDone and clothesDone then
        print("[RogueTrader] All subquests completed.")
    elseif runesDone and (blackjacksDone or clothesDone) then
        local partials = {}
        if blackjacksDone then table.insert(partials, "Blackjacks") end
        if clothesDone then table.insert(partials, "Clothes") end
        print("[RogueTrader] Partial completion: " .. table.concat(partials, ", "))
    end

    LODESTONES.AL_KHARID.Teleport()
    clickRandomTile(3300, 3211, 2)
    UTILS.countTicks(8)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3300, 3211, 0, 1)) else abilityWait() end

    Interact:NPC("Ali Morrisane", "Trade")

    local openedDialogue1 = UTILS.SleepUntil(function()
        return API.Compare2874Status(12, false)
    end, 10, "Ali Morrisane first dialogue")
    if not openedDialogue1 then return end

    API.RandomSleep2(600, 600, 600)
    local firstOption
    if runesDone and not (blackjacksDone or clothesDone) then
        firstOption = "1" 
    elseif runesDone and (blackjacksDone or clothesDone) and not (blackjacksDone and clothesDone) then
        firstOption = "2" 
    elseif runesDone and blackjacksDone and clothesDone then
        firstOption = "3" 
    else
        firstOption = "1" 
    end
    print("[AlKharid] Selecting chat option: " .. firstOption)
    API.KeyboardPress(firstOption, 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("3", 0, 50)

    local shopOpened1 = UTILS.SleepUntil(isOpen, 10, "Ali Morrisane first shop open")
    if not shopOpened1 then return end

    BuyFromShopContainer(313)

    Interact:NPC("Ali Morrisane", "Trade")
    UTILS.randomSleep(1000)

    local openedDialogue2 = UTILS.SleepUntil(function()
        return API.Compare2874Status(12, false)
    end, 10, "Ali Morrisane second dialogue")
    if not openedDialogue2 then return end

    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress(firstOption, 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("4", 0, 50)

    local shopOpened2 = UTILS.SleepUntil(isOpen, 10, "Ali Morrisane second shop open")
    if not shopOpened2 then return end

    BuyFromShopContainer(314)
    SHOP_STATUS.AlKharid = false
end

local function BuyZamorakMage()
    LODESTONES.EDGEVILLE.Teleport()
    Interact:Object("Wilderness wall", "Cross")

    local crossedWall = UTILS.SleepUntil(function()
        return API.PInArea(3066, 1, 3523, 1, 0)
    end, 10, "Crossed Wilderness wall")

    if not crossedWall then return end

    UTILS.countTicks(2)
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3109, 3557, 0, 2)) else abilityWait() end
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {2257}, 50)
    UTILS.randomSleep(1000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Zamorak Mage shop open")
    if not shopOpened then return end

    BuyFromShopContainer(277) 
    SHOP_STATUS.ZamorakMage = false
end

local function BuyMagebank()
    LODESTONES.EDGEVILLE.Teleport()
    clickRandomTile(3094, 3476, 2)
    UTILS.randomSleep(4000)
    Interact:Object("Lever", "Pull")
    UTILS.randomSleep(2000)

    local leverCrossed = UTILS.SleepUntil(function()
        return API.PInArea(3154, 5, 3924, 5, 0)
    end, 20, "Crossed lever")

    if not leverCrossed then return end

    UTILS.randomSleep(1000)
    clickRandomTile(3158, 3948, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3158, 3948, 2)
    Interact:Object("Web", "Slash")
    UTILS.randomSleep(5000)

    clickRandomTile(3120, 3957, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3094, 3958, 1)
    UTILS.countTicks(4)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3094, 3958, 1)
    UTILS.randomSleep(9000)
    API.DoAction_Object_valid2(0x29, API.OFF_ACT_GeneralObject_route0, {64729}, 50, WPOINT.new(3094, 3958, 0), true)
    UTILS.randomSleep(3000)
    API.DoAction_Object_valid2(0x29, API.OFF_ACT_GeneralObject_route0, {64729}, 50, WPOINT.new(3091, 3958, 0), true)
    UTILS.randomSleep(3000)

    Interact:Object("Lever", "Pull")

    local leverCrossedAgain = UTILS.SleepUntil(function()
        return API.PInArea(2539, 5, 4712, 5, 0)
    end, 20, "Crossed second lever")

    if not leverCrossedAgain then return end

    Interact:NPC("Lundail", "Trade")
    UTILS.randomSleep(1000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Magebank shop open")
    if not shopOpened then return end

    BuyFromShopContainer(131) 
    SHOP_STATUS.Magebank = false
end

local function BuyOoglog()
    LODESTONES.OOGLOG.Teleport()
    clickRandomTile(2508, 2837, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2508, 2837, 2)
    UTILS.randomSleep(3000)
    UTILS.countTicks(3)
    clickRandomTile(2523, 2837, 2)
    UTILS.countTicks(4)
    if canSurge() then UTILS.surge() else abilityWait() end
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2560, 2849, 0, 2)) else abilityWait() end
    clickRandomTile(2560, 2849, 2)
    UTILS.randomSleep(3000)
    if canSurge() then UTILS.surge() else abilityWait() end

    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 7056 },50)
    UTILS.randomSleep(3000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Ooglog shop open")
    if not shopOpened then return end

    BuyFromShopContainer(534)

    SHOP_STATUS.Ooglog = false
end

local function Redsandstone()
    local IDS_redSandstone = {67969, 67970, 67971, 67972}
    local redSandstoneDepleted = {67973}
    LODESTONES.OOGLOG.Teleport()
    clickRandomTile(2586, 2878, 2)
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2586, 2878, 2)
    UTILS.countTicks(5)
    if canSurge() then UTILS.surge() else abilityWait() end
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2586, 2878, 0, 2)) else abilityWait() end
    API.DoAction_Object_valid1(0x3a, API.OFF_ACT_GeneralObject_route0, IDS_redSandstone, 50, true)
    API.RandomSleep2(600, 600, 600)
    API.WaitUntilMovingEnds()
    if UTILS.SleepUntil(checkCues, 150, 'Red Sandstone') then
    end
    SHOP_STATUS.Redsandstone = false
end

local function MenaphosSandstone()
    local IDS_redSandstone = {67969, 67970, 67971, 67972}
    local redSandstoneDepleted = {67973}
    LODESTONES.MENAPHOS.Teleport()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 24661 },50)
    API.RandomSleep2(300, 400, 100)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 24661 },50)
    UTILS.SleepUntil(function()
        return API.PInArea(3266, 2, 2729, 2, 0)
    end, 10, "Arrival at Sophanem  area")
    API.RandomSleep2(300, 400, 100)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3304, 2757, 2)
    API.RandomSleep2(300, 400, 100)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3290, 2729, 0, 2)) else abilityWait() end
    clickRandomTile(3320, 2761, 2)
    UTILS.countTicks(10)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ 109350 },50)
    UTILS.countTicks(8)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(3321, 2761, 0, 1)) else abilityWait() end
    API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ 109350 },50)
    UTILS.SleepUntil(function()
        return API.PInArea(3330, 1, 2761, 1, 0)
    end, 20, "Arrival at Sophanem  area")
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_Object_valid1(0x3a, API.OFF_ACT_GeneralObject_route0, IDS_redSandstone, 50, true)
    API.RandomSleep2(300, 400, 100)
    API.WaitUntilMovingEnds()
    if UTILS.SleepUntil(checkCues, 150, 'Red Sandstone') then
    end
    SHOP_STATUS.MenaphosSandstone = false
end

local function Crystalsandstone()
    local IDS_redSandstone = {112696, 112697, 112698, 112699,}
    local redSandstoneDepleted = {112700}
    LODESTONES.PRIFDDINAS.Teleport()
    clickRandomTile(2166, 3361, 1)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2144, 3351, 1)
    UTILS.countTicks(5)
    clickRandomTile(2144, 3351, 1)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2142, 3361, 0, 1)) else abilityWait() end
    UTILS.countTicks(1)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2144, 3351, 1)
    API.DoAction_Object_valid1(0x3a, API.OFF_ACT_GeneralObject_route0, IDS_redSandstone, 50, true)
    API.RandomSleep2(600, 600, 600)
    API.WaitUntilMovingEnds()
    if UTILS.SleepUntil(checkCues, 150, 'Red Sandstone') then
    end
    SHOP_STATUS.Crystalsandstone = false
end

local function TaverlyHerb()
    LODESTONES.TAVERLEY.Teleport()
    clickRandomTile(2876, 3417, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_Object1(0x5, API.OFF_ACT_GeneralObject_route1, {66666}, 50)
    local bankOpened = UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")
    if bankOpened then 
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(600, 600, 600)
    end
    clickRandomTile(2922, 3429, 2)
    UTILS.countTicks(2)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2922, 3429, 2)
    UTILS.countTicks(5)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2922, 3429, 2)
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2921, 3431, 0, 1)) else abilityWait() end
    UTILS.countTicks(1)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route4, {14854}, 50)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Taverly Herb shop open")
    if not shopOpened then return end
    
    BuyFromShopContainer(635)

    if SHOP_STATUS.Flies then
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 6893 },50)
        API.RandomSleep2(2400, 2000, 600)
        UTILS.SleepUntil(isOpen, 10, "Pet shop open")
        BuyFromShopContainer(531)
        SHOP_STATUS.Flies = false 
    end

    SHOP_STATUS.TaverlyHerb = false
end

local function FortHerbshop()
    LODESTONES.FORT_FORINTHRY.Teleport()
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(1)

    local function bankSequence()
        API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {125115}, 50)
        API.RandomSleep2(300, 500, 600)
        UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")
        if API.BankOpen2() then 
            API.KeyboardPress("3", 0, 50)
            API.RandomSleep2(1200, 1500, 1000)
        end
    end

    while true do
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, {26134}, 50)
        API.RandomSleep2(300, 500, 600)
        UTILS.SleepUntil(isOpen, 10, "Fort Herb shop open")
        if not isOpen() then break end
        BuyFromShopContainer(945)
        if not Inventory:IsFull() then break end
        bankSequence()
    end

    bankSequence()

    if SHOP_STATUS.Buybroads then
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route3,{ 30027 },50)
        API.RandomSleep2(300, 500, 600)
        UTILS.SleepUntil(isOpen, 10, "Raptor shop open")
        BuyFromShopContainer(538) 
    end

    SHOP_STATUS.FortHerbshop = false
end

local function BuyBurthorpeBroads()
    LODESTONES.BURTHOPE.Teleport()
    if canDive() then UTILS.dive(randomizeDiveCoordinates(2891, 3547, 0, 1)) else abilityWait() end
    API.RandomSleep2(100, 200, 50)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, {8480}, 50)
    API.RandomSleep2(300, 500, 600)
    UTILS.SleepUntil(isOpen, 10, "Burthorpe broads shop open")
    BuyFromShopContainer(633) 
    API.RandomSleep2(300, 500, 600)
    SHOP_STATUS.Buybroads = false
end

local desert_subreqs = {
    { name = "Faster than a Speeding Bullet", value = 1, varbits = {17760} },
    { name = "So Su Me", value = 1, varbits = {17761} },
    { name = "A Bridge Not Far", value = 1, varbits = {17762} },
    { name = "Heathen Idle", value = 1, varbits = {17763} },
    { name = "Away with the Kalphites", value = 1, varbits = {17764} },
    { name = "All Square", value = 1, varbits = {17765} },
    { name = "Goat Harralander? (all steps)", value = 1, varbits = {17766}, steps = {0,1,2,3,4,5} },
    { name = "Taken for Granite", value = 1, varbits = {17767} },
    { name = "Unbeetleable", value = 1, varbits = {17768} },
    { name = "An Teak", value = 1, varbits = {17769} },
    { name = "Overcut", value = 1, varbits = {17770} },
}

local function isDesertSubreqCompleted(subreq)
    if subreq.steps then
        local value = API.GetVarbitValue(subreq.varbits[1])
        for _, step in ipairs(subreq.steps) do
            if (value & (1 << step)) == 0 then
                return false
            end
        end
        return true
    else
        for _, varbit_id in ipairs(subreq.varbits) do
            if API.GetVarbitValue(varbit_id) < subreq.value then
                return false
            end
        end
        return true
    end
end

local function getDesertSummary()
    local completed, incomplete = 0, {}
    for _, s in ipairs(desert_subreqs) do
        if isDesertSubreqCompleted(s) then completed = completed + 1 else table.insert(incomplete, s.name) end
    end
    return completed, #desert_subreqs, incomplete
end

local function isFairyTale3Completed()
    local fairyTale3 = { name = "Fairy Tale III", value = 180, varbits = {9928} }
    for _, id in ipairs(fairyTale3.varbits) do
        if API.GetVarbitValue(id) < fairyTale3.value then
            return false
        end
    end
    return true
end

local function ClaimpotatoCactus()
    local completed, total = getDesertSummary()
    local fairyTale3Done = isFairyTale3Completed()
    print("[ClaimpotatoCactus] Desert Medium complete:", completed == total, string.format("(%d/%d)", completed, total))
    print("[ClaimpotatoCactus] Fairy Tale III complete:", fairyTale3Done)
    if completed == total and fairyTale3Done then
        print("[ClaimpotatoCactus] Both requirements met. Proceeding.")
        LODESTONES.YANILLE.Teleport()
        clickRandomTile(2528, 3129, 2)
        UTILS.countTicks(4)
        if canSurge() then UTILS.surge() else abilityWait() end
        API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route2,{ 14112 },50)
        UTILS.countTicks(2)
        if canSurge() then UTILS.surge() else abilityWait() end
        API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route2,{ 14112 },50)
        UTILS.SleepUntil(isOpen, 20, "Fairy ring open")
        if not isOpen() then
            SHOP_STATUS.ClaimpotatoCactus = false
            return
        end
        API.RandomSleep2(400, 300, 100)
        API.DoAction_Interface(0xffffffff,0xffffffff,1,784,7,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(400, 300, 100)
        API.DoAction_Interface(0xffffffff,0xffffffff,1,784,25,-1,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(400, 300, 100)
        API.DoAction_Interface(0x2e,0xffffffff,1,784,23,-1,API.OFF_ACT_GeneralInterface_route)
        UTILS.SleepUntil(function()
            return API.PInArea(3251, 1, 3095, 1, 0)
        end, 20, "Arrival Kalphite Queen area")
        UTILS.countTicks(2)
        clickRandomTile(3234, 3106, 2)
        if canDive() then UTILS.dive(randomizeDiveCoordinates(3234, 3106, 0, 1)) else abilityWait() end
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 1152 },50)
        UTILS.SleepUntil(function() return API.Compare2874Status(12, false) end, 20, "Claim potato cactus dialogue")
        if not isOpen() then
            SHOP_STATUS.ClaimpotatoCactus = false
            return
        end
        UTILS.countTicks(4)
        SHOP_STATUS.ClaimpotatoCactus = false
    else
        print("[ClaimpotatoCactus] Skipping: Not all Desert Medium tasks and Fairy Tale III are completed.")
        SHOP_STATUS.ClaimpotatoCactus = false
    end
end

local function PriffherbShop()
    LODESTONES.PRIFDDINAS.Teleport()
    clickRandomTile(2235, 3398, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2235, 3398, 2)
    UTILS.countTicks(3)
    if canSurge() then UTILS.surge() else abilityWait() end
    clickRandomTile(2235, 3398, 2)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {20285}, 50)
    UTILS.randomSleep(4000)

    UTILS.SleepUntil(isOpen, 10, "Priff Herb shop open")
    if not isOpen() then return end

    BuyFromShopContainer(738) 

    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {92692}, 50)

    UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")
    if API.BankOpen2() then
        API.KeyboardPress("3", 0, 50)
    end
    API.RandomSleep2(300, 500, 600)
    SHOP_STATUS.PriffherbShop = false
end

local function isDungeoneeringAtLeast(level)
    local dung = API.GetSkillByName("DUNGEONEERING")
    return dung and dung.level and dung.level >= level
end

local function Mawsandstone()
    if not isDungeoneeringAtLeast(115) then
        print("[Mawsandstone] Skipping: Dungeoneering level is below 115.")
        SHOP_STATUS.Mawsandstone = false
        return
    end
    local IDS_crystalSandstone = {112696, 112697, 112698, 112699}
    local IDS_Maw = {94273}

    if not API.PInArea(2237, 3, 3400, 3, 0) then
        LODESTONES.PRIFDDINAS.Teleport()
        clickRandomTile(2235, 3398, 2)
        UTILS.countTicks(3)
        if canSurge() then UTILS.surge() else abilityWait() end
        clickRandomTile(2235, 3398, 2)
        UTILS.countTicks(3)
        if canSurge() then UTILS.surge() else abilityWait() end
        clickRandomTile(2237, 3400, 2)
        UTILS.SleepUntil(function()
            return API.PInArea(2237, 3, 3400, 3, 0)
        end, 30, "Arriving outside Resource dungeon")
    end
    API.DoAction_Object1(0x39, API.OFF_ACT_GeneralObject_route0, {94320}, 50)
    UTILS.SleepUntil(function()
        return API.PInArea(1374, 3, 4610, 3, 0)
    end, 30, "Waiting to enter Edimmu Resource dungeon")
    API.RandomSleep2(1200, 1000, 500)
    API.DoAction_Object_valid1(0x29, API.OFF_ACT_GeneralObject_route0, IDS_Maw, 50, true)
    API.RandomSleep2(600, 700, 500)
    if canSurge() then UTILS.surge() else abilityWait() end
    API.DoAction_Object_valid1(0x29, API.OFF_ACT_GeneralObject_route0, IDS_Maw, 50, true)
    API.RandomSleep2(7000, 6000, 1000) 
    API.DoAction_Object_valid1(0x3a, API.OFF_ACT_GeneralObject_route0, IDS_crystalSandstone, 50, true)
    UTILS.SleepUntil(checkCues, 150, 'Crystal Sandstone')
    SHOP_STATUS.Mawsandstone = false
end

if API.CacheEnabled then
    print ("Cache is enabled, running the script.")
else
    print("Cache is disabled turn it on.")
    API.Write_LoopyLoop(false)
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    API.DoRandomEvents()
    if SHOP_STATUS.Lunar then
        Lunar()
    elseif SHOP_STATUS.Yannile then
        buyMagesGuild()   
    elseif SHOP_STATUS.Sarim then
        BuySarim()
    elseif SHOP_STATUS.Void then
        BuyVoid()
    elseif SHOP_STATUS.Varrock then   
        BuyVarrock()
    elseif SHOP_STATUS.AlKharid then   
        BuyAlkharid()
    elseif SHOP_STATUS.ZamorakMage then
        BuyZamorakMage()  
    elseif SHOP_STATUS.Magebank then
        BuyMagebank() 
    elseif SHOP_STATUS.Ooglog then
        BuyOoglog() 
    elseif SHOP_STATUS.Redsandstone then
        Redsandstone()
    elseif SHOP_STATUS.MenaphosSandstone then
        MenaphosSandstone()
    elseif SHOP_STATUS.Crystalsandstone then
        Crystalsandstone()
    elseif SHOP_STATUS.TaverlyHerb then
        TaverlyHerb()
    elseif SHOP_STATUS.FortHerbshop then
        FortHerbshop()
    elseif SHOP_STATUS.Buybroads then
        BuyBurthorpeBroads()
    elseif SHOP_STATUS.ClaimpotatoCactus then
        ClaimpotatoCactus()      
    elseif SHOP_STATUS.PriffherbShop then
        PriffherbShop()
    elseif SHOP_STATUS.Mawsandstone then
        Mawsandstone()
    else        
        print("Finished buying from all supported shops")
        API.Write_LoopyLoop(false)
    end

    API.RandomSleep2(100, 100, 100)
end
