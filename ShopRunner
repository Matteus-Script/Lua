--[[
# Script Name:   <RuneShop Runner>
# Description:   <Buys Runes from pretty much every runeshop + meat at Ooglog>
# Author:        <Matteus>
# Version:       <1.0>
# Date:          <2025.03.24>
--]]

local API = require("api")
local LODESTONES = require("lodestones")       
local UTILS = require("utils")

local maxWaitTime = 20
local elapsedTime = 0
local waitInterval = 0.5

API.SetMaxIdleTime(10)

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false)
end

local SHOP_STATUS = {
    BABA_YAGA = true,
    Yannile = true,
    Sarim = true,
    Void = true,
    Varrock = true,
    AlKharid = true,
    ZamorakMage = true,
    Magebank = true,
    Ooglog = true,
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
    API.KeyboardPress("Esc", 0, 50)
    UTILS.randomSleep(1000)
end

local function waitUntil(maxWaitTime, waitInterval)
    local elapsedTime = 0
    while elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
end

local function buyBabaYaga() 
    LODESTONES.LUNAR_ISLE.Teleport()
    clickRandomTile(2092,3931,2)
    UTILS.countTicks(8)
    UTILS.dive(randomizeDiveCoordinates(2101, 3930, 0, 2))
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 4512 },50)
    UTILS.countTicks(1)
    UTILS.surge()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 4512 },50)
    while not API.PInArea(3103, 5, 4447, 5, 0) do
        UTILS.randomSleep(1000) 
    end
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 4513 },50)
    UTILS.randomSleep(1000)
    
        waitUntil(5, 1)
        if not isOpen() then return end

        local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
        BuyItems(Items) 

    SHOP_STATUS.BABA_YAGA = false
end 

local teleportedYannile = false

local function buyMagesGuild()
    if not teleportedYannile  then
        LODESTONES.YANILLE.Teleport()
        teleportedYannile  = true  
    end

    local function atMagesGuild()
        return API.PInArea(2529, 5, 3094, 5, 0)
    end

    local function inMagesGuild()
        return API.PInArea(2585, 1, 3088, 1, 0)
    end

    local function isAtShop()
        return API.PInArea(2590, 1, 3092, 1, 0)
    end

    if atMagesGuild() then
        clickRandomTile(2565, 3091, 2)
        UTILS.countTicks(3)
        UTILS.surge()
        UTILS.dive(randomizeDiveCoordinates(2573, 3092, 0, 2))
        UTILS.countTicks(1)
        UTILS.surge()

        API.DoAction_Object1(0x31, API.OFF_ACT_GeneralObject_route0, {1600}, 50)
    end

    if inMagesGuild() then
        API.DoAction_Object1(0x34, API.OFF_ACT_GeneralObject_route0, {1722}, 50)
        UTILS.countTicks(3)
    end

    if isAtShop() then
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {461}, 50)
        UTILS.randomSleep(1000)

        while not isOpen() and elapsedTime < maxWaitTime do
            UTILS.randomSleep(waitInterval * 1000)
            elapsedTime = elapsedTime + waitInterval
        end

        if not isOpen() then return end

        local Items = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
        SHOP_STATUS.Yannile= false
    end
end

local teleportedSarim = false

local function BuySarim()
     if not teleportedSarim then
        LODESTONES.PORT_SARIM.Teleport()
        teleportedSarim = true
    end 

    local function atPortSarim()
        return API.PInArea(3011, 5, 3215, 5, 0)
    end

    if atPortSarim() then
        UTILS.dive(randomizeDiveCoordinates(3021, 3227, 0, 2))
        clickRandomTile(3019, 3259, 2)
        UTILS.countTicks(3)
        UTILS.surge()
        clickRandomTile(3019, 3259, 2)
        UTILS.countTicks(5)
    end
        Interact:Object("Door", "Open") 
        UTILS.randomSleep(5000)         
        API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {583}, 50)
        UTILS.randomSleep(1000)
    
         while not isOpen() and elapsedTime < maxWaitTime do
            UTILS.randomSleep(waitInterval * 1000)
            elapsedTime = elapsedTime + waitInterval
        end
    
            if not isOpen() then return end
    
            local Items = {0, 1, 2, 3, 4, 5, 6, 7}
            for _, Runes in ipairs(Items) do
                API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(100, 200, 300)
            end
            API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
            SHOP_STATUS.Sarim = false
end

local function BuyVoid()
    LODESTONES.PORT_SARIM.Teleport()
    --clickRandomTile(3026,3205,2)
    Interact:NPC("Squire", "Travel")
    while not API.PInArea(2651, 10, 2673, 10, 0) do
        UTILS.randomSleep(2000) 
    end
    API.DoAction_NPC(0x29, API.OFF_ACT_InteractNPC_route2, {3798}, 50)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
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
    clickRandomTile(3253,3397,1)
    while not API.PInArea(3253, 2, 3397, 2, 0) do
        UTILS.randomSleep(2000) 
    end
    Interact:Object("Door", "Open",3)
    UTILS.randomSleep(3000)
    Interact:NPC("Aubury", "Trade",8)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    SHOP_STATUS.Varrock = false
end

local function BuyAlkharid()
    LODESTONES.AL_KHARID.Teleport()
    clickRandomTile(3300, 3212, 2)
    UTILS.countTicks(5)
    UTILS.dive(randomizeDiveCoordinates(3300, 3212, 0, 2))
    Interact:NPC("Ali Morrisane", "Trade")
    --UTILS.randomSleep(3000)

    while not API.Compare2874Status(12, false) and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not API.Compare2874Status(12, false) then return end  

    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("1", 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("3", 0, 50)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not isOpen() then return end  

    local Items = {0, 1, 2, 3}
    for _, Runes in ipairs(Items) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end

    Interact:NPC("Ali Morrisane", "Trade")
    UTILS.randomSleep(1000)

    elapsedTime = 0 
    while not API.Compare2874Status(12, false) and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not API.Compare2874Status(12, false) then return end  

    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("1", 0, 50)
    API.RandomSleep2(600, 600, 600)
    API.KeyboardPress("4", 0, 50)

    elapsedTime = 0 
    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not isOpen() then return end  

    local Items2 = {0, 1, 2, 3, 4, 5, 6, 7, 8}  
    for _, Runes in ipairs(Items2) do
        API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(100, 200, 300)
    end
    API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
    SHOP_STATUS.AlKharid = false
end

local function BuyZamorakMage()
    LODESTONES.EDGEVILLE.Teleport()
    Interact:Object("Wilderness wall", "Cross")
    while not API.PInArea(3066, 1, 3523, 1, 0) do
        UTILS.randomSleep(2000) 
    end
    UTILS.countTicks(2)
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    UTILS.surge()
    clickRandomTile(3093, 3556, 2)
    UTILS.countTicks(3)
    UTILS.dive(randomizeDiveCoordinates(3109, 3557, 0, 2))
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,{ 2257 },50)
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end
        if not isOpen() then return end
    
        local Items = {0, 1, 2, 3, 4, 5, 6, 7}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
       UTILS.randomSleep(1000) 
    SHOP_STATUS.ZamorakMage = false
end

local function BuyMagebank()
    LODESTONES.EDGEVILLE.Teleport()
    clickRandomTile(3094, 3476, 2)
    UTILS.randomSleep(4000)
    Interact:Object("Lever", "Pull")
    UTILS.randomSleep(2000)
   
    while not API.PInArea(3154, 5, 3924, 5, 0) do
        UTILS.randomSleep(1000) 
    end
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
    UTILS.randomSleep(10000)
    API.DoAction_Object2(0x29,API.OFF_ACT_GeneralObject_route0,{ 64729 },50,WPOINT.new(3094,3958,0));
    UTILS.randomSleep(3000)
    API.DoAction_Object2(0x29,API.OFF_ACT_GeneralObject_route0,{ 64729 },50,WPOINT.new(3091,3958,0));
    UTILS.randomSleep(3000)
    Interact:Object("Lever", "Pull")
    while not API.PInArea(2539, 5, 4712, 5, 0) do
        UTILS.randomSleep(1000) 
    end
    Interact:NPC("Lundail", "Trade")    
    UTILS.randomSleep(1000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

    if not isOpen() then return end
    
         local Items = {0, 1, 2, 3, 4, 5, 6, 7,8,9,10}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end 
       API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000) 
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
    UTILS.surge()
    clickRandomTile(2560, 2849, 2)
    UTILS.randomSleep(3000)
    UTILS.surge()
    Interact:NPC("Chargurr", "Trade")
    UTILS.randomSleep(3000)

    while not isOpen() and elapsedTime < maxWaitTime do
        UTILS.randomSleep(waitInterval * 1000)
        elapsedTime = elapsedTime + waitInterval
    end

      if not isOpen() then return end
    
         local Items = {0, 1, 2}
        for _, Runes in ipairs(Items) do
            API.DoAction_Interface(0xffffffff, 0xffffffff, 7, 1265, 20, Runes, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(100, 200, 300)
        end
        API.KeyboardPress("Esc", 0, 50)
            UTILS.randomSleep(1000)
    SHOP_STATUS.Ooglog = false
end

API.Write_LoopyLoop(true)
while API.Read_LoopyLoop() do
    API.DoRandomEvents()
    if SHOP_STATUS.BABA_YAGA then
        buyBabaYaga()
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
    else        
        print("Finished buying from all supported shops")
        API.Write_LoopyLoop(false)
    end

    API.RandomSleep2(100, 100, 100)
end
