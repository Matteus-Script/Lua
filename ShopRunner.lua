--[[
# Script Name:   <RuneShop Runner>
# Description:   <Buys Runes from pretty much every runeshop + meat at Ooglog + mines crystal sandstone and red sandstone>
# Author:        <Matteus>
# Version:       <1.2>
# Date:          <2025.03.24>
--]]

--[[
Changelog:
v1.0 - 24-03-2025
    - Initial release
v1.1 - 03-04-2025
    - Added support for Crystalsandstone and Redsandstone make sure you have porter charges and GOTE enabled will add other method in future -turn on Resourceful aura to get more :)
v.1.2 - 05-04-2025
    - Added support for Herblore shops in Taverly, Fort Forinthry and Prifddinas
]]--

local API = require("api")
local LODESTONES = require("lodestones")       
local UTILS = require("utils")

API.SetMaxIdleTime(10)

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false)
end

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
    Crystalsandstone = true,
    TaverlyHerb = true,
    FortHerbshop = true,
    PriffherbShop = true,
}

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

local function BuyItems(items)
    for _, rune in ipairs(items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, rune, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end 
    UTILS.randomSleep(1000)
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
    UTILS.dive(randomizeDiveCoordinates(2100, 3929, 0, 1))
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {4512}, 50)
    UTILS.countTicks(1)
    UTILS.surge()
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route, {4512}, 50)

    UTILS.SleepUntil(function()
        return API.PInArea(3103, 5, 4447, 5, 0)
    end, 15, "Arrival at Lunar isle target area")

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {4513}, 50)

    local opened = UTILS.SleepUntil(isOpen, 10, "Lunar shop open")
    if not opened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
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
    UTILS.surge()
    UTILS.dive(randomizeDiveCoordinates(2573, 3092, 0, 2))
    API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {1600}, 50)
    UTILS.countTicks(1)
    UTILS.surge()
    API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {1600}, 50)

    local insideGuild = UTILS.SleepUntil(inMagesGuild, 20, "entering Mage Guild")
    if not insideGuild then return end

    API.DoAction_Object1(0x34, API.OFF_ACT_GeneralObject_route0, {1722}, 50)
    UTILS.countTicks(3)

    local atShop = UTILS.SleepUntil(isAtShop, 20, "reaching Mage Guild shop")
    if not atShop then return end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {461}, 50)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Mage Guild shop open")
    if not opened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
    SHOP_STATUS.Yannile = false
end


local function BuySarim()
    LODESTONES.PORT_SARIM.Teleport()
    UTILS.dive(randomizeDiveCoordinates(3021, 3227, 0, 1))
    clickRandomTile(3019, 3259, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3018, 3259, 1)
    UTILS.countTicks(8)
    Interact:Object("Door", "Open") 
    UTILS.randomSleep(4000)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {583}, 50)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Port Sarim shop open")
    if not opened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
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

    local Items = {0, 1, 2, 3, 4, 5, 6, 7}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
    SHOP_STATUS.Void = false
end

local function BuyVarrock()
    LODESTONES.VARROCK.Teleport()
    clickRandomTile(3218, 3390, 2)
    UTILS.countTicks(2)
    UTILS.surge()
    UTILS.dive(randomizeDiveCoordinates(3233, 3390, 0, 2))
    UTILS.countTicks(1)
    UTILS.surge()
    clickRandomTile(3253, 3397, 1)

    local reachedShop = UTILS.SleepUntil(function()
        return API.PInArea(3253, 2, 3397, 2, 0)
    end, 10, "reaching Varrock rune shop")

    if not reachedShop then return end

    Interact:Object("Door", "Open", 3)
    UTILS.randomSleep(3000)

    Interact:NPC("Aubury", "Trade", 8)
    UTILS.randomSleep(1000)

    local opened = UTILS.SleepUntil(isOpen, 10, "Varrock rune shop open")
    if not opened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.DoAction_Interface(0xffffffff,0xffffffff,7,1265,14,0,API.OFF_ACT_GeneralInterface_route2)
        API.DoAction_Interface(0xffffffff,0xffffffff,7,1265,14,1,API.OFF_ACT_GeneralInterface_route2)
        API.RandomSleep2(100, 200, 300)
    end
    SHOP_STATUS.Varrock = false
end


local function BuyAlkharid()
    LODESTONES.AL_KHARID.Teleport()
    clickRandomTile(3300, 3211, 2)
    UTILS.countTicks(8)
    UTILS.dive(randomizeDiveCoordinates(3300, 3211, 0, 1))

    Interact:NPC("Ali Morrisane", "Trade")

    local openedDialogue1 = UTILS.SleepUntil(function()
        return API.Compare2874Status(12, false)
    end, 10, "Ali Morrisane first dialogue")

    if not openedDialogue1 then return end

    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("1", 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("3", 0, 50)

    local shopOpened1 = UTILS.SleepUntil(isOpen, 10, "Ali Morrisane first shop open")
    if not shopOpened1 then return end

    local Items1 = {0, 1, 2, 3}
    for _, Runes in ipairs(Items1) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    Interact:NPC("Ali Morrisane", "Trade")
    UTILS.randomSleep(1000)

    local openedDialogue2 = UTILS.SleepUntil(function()
        return API.Compare2874Status(12, false)
    end, 10, "Ali Morrisane second dialogue")

    if not openedDialogue2 then return end

    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("1", 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("4", 0, 50)

    local shopOpened2 = UTILS.SleepUntil(isOpen, 10, "Ali Morrisane second shop open")
    if not shopOpened2 then return end

    local Items2 = {0, 1, 2, 3, 4, 5, 6, 7, 8}
    for _, Runes in ipairs(Items2) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
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
    UTILS.surge()
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    UTILS.dive(randomizeDiveCoordinates(3109, 3557, 0, 2))
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {2257}, 50)
    UTILS.randomSleep(1000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Zamorak Mage shop open")
    if not shopOpened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

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
    end, 10, "Crossed lever")

    if not leverCrossed then return end

    UTILS.randomSleep(1000)
    clickRandomTile(3158, 3948, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3158, 3948, 2)
    Interact:Object("Web", "Slash")
    UTILS.randomSleep(5000)

    clickRandomTile(3120, 3957, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3094, 3958, 1)
    UTILS.countTicks(4)
    UTILS.surge()
    clickRandomTile(3094, 3958, 1)
    UTILS.randomSleep(9000)

    API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route0, {64729}, 50, WPOINT.new(3094, 3958, 0))
    UTILS.randomSleep(3000)
    API.DoAction_Object2(0x29, API.OFF_ACT_GeneralObject_route0, {64729}, 50, WPOINT.new(3091, 3958, 0))
    UTILS.randomSleep(3000)

    Interact:Object("Lever", "Pull")

    local leverCrossedAgain = UTILS.SleepUntil(function()
        return API.PInArea(2539, 5, 4712, 5, 0)
    end, 10, "Crossed second lever")

    if not leverCrossedAgain then return end

    Interact:NPC("Lundail", "Trade")
    UTILS.randomSleep(1000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Magebank shop open")
    if not shopOpened then return end

    local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
    SHOP_STATUS.Magebank = false
end

local function BuyOoglog()
    LODESTONES.OOGLOG.Teleport()
    clickRandomTile(2508, 2837, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(2508, 2837, 2)
    UTILS.randomSleep(3000)
    UTILS.countTicks(3)
    clickRandomTile(2523, 2837, 2)
    UTILS.countTicks(4)
    UTILS.surge()
    UTILS.dive(randomizeDiveCoordinates(2560, 2849, 0, 2))
    clickRandomTile(2560, 2849, 2)
    UTILS.randomSleep(3000)
    UTILS.surge()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 7056 },50)
    --Interact:NPC("Chargurr", "Trade")
    UTILS.randomSleep(3000)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Ooglog shop open")
    if not shopOpened then return end

    local Items = {0, 1, 2}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    SHOP_STATUS.Ooglog = false
end

local function Redsandstone()
    local IDS_redSandstone = {67969, 67970, 67971, 67972}
    local redSandstoneDepleted = {67973}
    LODESTONES.OOGLOG.Teleport()
    clickRandomTile(2586, 2878, 2)
    UTILS.countTicks(1)
    UTILS.surge()
    clickRandomTile(2586, 2878, 2)
    UTILS.countTicks(5)
    UTILS.surge()
    UTILS.dive(randomizeDiveCoordinates(2586, 2878, 0, 2))
    API.DoAction_Object_valid1(0x3a, API.OFF_ACT_GeneralObject_route0, IDS_redSandstone, 50, true)
    API.RandomSleep2(600, 600, 600)
    API.WaitUntilMovingEnds()
    if UTILS.SleepUntil(checkCues, 150, 'Red Sandstone') then
    end
    SHOP_STATUS.Redsandstone = false
end

local function Crystalsandstone()
    local IDS_redSandstone = {112696, 112697, 112698, 112699,}
    local redSandstoneDepleted = {112700}
    LODESTONES.PRIFDDINAS.Teleport()
    clickRandomTile(2166, 3361, 1)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(2144, 3351, 1)
    UTILS.countTicks(5)
    clickRandomTile(2144, 3351, 1)
    UTILS.dive(randomizeDiveCoordinates(2142, 3361, 0, 1))
    UTILS.countTicks(1)
    UTILS.surge()
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
    UTILS.surge()
    API.DoAction_Object1(0x5, API.OFF_ACT_GeneralObject_route1, {66666}, 50)
    local bankOpened = UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")
    if bankOpened then 
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(600, 600, 600)
    end
    clickRandomTile(2922, 3429, 2)
    UTILS.countTicks(2)
    UTILS.surge()
    clickRandomTile(2922, 3429, 2)
    UTILS.countTicks(5)
    UTILS.surge()
    clickRandomTile(2922, 3429, 2)
    UTILS.dive(randomizeDiveCoordinates(2921, 3431, 0, 1))
    UTILS.countTicks(1)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route4, {14854}, 50)

    local shopOpened = UTILS.SleepUntil(isOpen, 10, "Taverly Herb shop open")
    if not shopOpened then return end
    
    local Items = {3, 4, 5, 7, 8, 9, 10}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
    SHOP_STATUS.TaverlyHerb = false
end

local function FortHerbshop()
    LODESTONES.FORT_FORINTHRY.Teleport()
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3297, 3568, 1)
    UTILS.countTicks(1)
    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {125115}, 50)

    UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")

    if API.BankOpen2() then 
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(1000, 1000, 1000)
    end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, {26134}, 50)
    API.RandomSleep2(300, 500, 600)

    UTILS.SleepUntil(isOpen, 10, "Fort Herb shop open")

    if not isOpen() then return end

    local Items = {3, 4, 5, 7, 8, 9}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {125115}, 50)
    API.RandomSleep2(300, 500, 600)

    UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")

    if API.BankOpen2() then 
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(1000, 1000, 1000)
    end

    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route3, {26134}, 50)
    API.RandomSleep2(300, 500, 600)

    UTILS.SleepUntil(isOpen, 10, "Fort Herb shop open")

    if not isOpen() then return end

    local Items2 = {10}
    for _, Runes in ipairs(Items2) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {125115}, 50)
    API.RandomSleep2(300, 500, 600)

    UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")

    if API.BankOpen2() then 
        API.KeyboardPress("3", 0, 50)
        API.RandomSleep2(1000, 1000, 1000)
    end

    SHOP_STATUS.FortHerbshop = false
end


local function PriffherbShop()
    LODESTONES.PRIFDDINAS.Teleport()
    clickRandomTile(2235, 3398, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(2235, 3398, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(2235, 3398, 2)
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {20285}, 50)
    UTILS.randomSleep(4000)

    UTILS.SleepUntil(isOpen, 10, "Priff Herb shop open")

    if not isOpen() then return end

    local Items = {4, 5, 6, 9, 10, 11, 12}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {92692}, 50)

    UTILS.SleepUntil(API.BankOpen2, 10, "Bank open")

    if API.BankOpen2() then
        API.KeyboardPress("3", 0, 50)
    end

    API.RandomSleep2(300, 500, 600)

    SHOP_STATUS.PriffherbShop = false
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
    elseif SHOP_STATUS.Crystalsandstone then
        Crystalsandstone()
    elseif SHOP_STATUS.TaverlyHerb then
        TaverlyHerb()
    elseif SHOP_STATUS.FortHerbshop then
        FortHerbshop()
    elseif SHOP_STATUS.PriffherbShop then
        PriffherbShop()
    else        
        print("Finished buying from all supported shops")
        API.Write_LoopyLoop(false)
    end

    API.RandomSleep2(100, 100, 100)
end
