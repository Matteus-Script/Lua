-- Title: Pickpocket and Chests
-- Author: <Matteus>
-- Description: <A configurable Thieving script with support for both NPC pickpocketing and nearby lock-pickable chests. Select an available NPC target or enable chest mode.>
-- Version: <1.0>
-- Category: Thieving
-- Date : 2026.10.13

local API = require("api")

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local IDS = {
    EXCALIBUR = 14632,
    EXCALIBUR_AUGMENTED = 36619,
    ELVEN_SHARD = 43358
}

local maintainCrystalMask = false
local maintainLightForm = false
local maintainFamiliar = false
local crystalMaskFallbackOnly = false
local lightFormFallbackOnly = false
local lastPrayerRestoreAttempt = nil
local missingFamiliarPouchId = nil
local familiarOptions = { "Holy scarab", "Magpie", "Abyssal lurker", "Bunyip" }
local familiarPouches = {
    ["Holy scarab"] = { id = 52825, name = "Holy scarab pouch" },
    Magpie = { id = 12041, name = "Magpie pouch" },
    ["Abyssal lurker"] = { id = 12037, name = "Abyssal lurker pouch" },
    Bunyip = { id = 12029, name = "Bunyip pouch" }
}
local selectedFamiliarIndex = 0
local selectedFamiliar = familiarOptions[selectedFamiliarIndex + 1]
local familiarRefreshTimeMinutes = 2

local function isElvenRitualShardOnBar()
    local shard = API.GetABs_name("Ancient elven ritual shard", true)
    return shard ~= nil
end

local function isLightFormOnBar()
    if lightFormFallbackOnly then
        return false
    end
    local lightForm = API.GetABs_name("Light Form", true)
    return lightForm ~= nil and lightForm.id ~= 0
end

local function isCrystalMaskOnBar()
    if crystalMaskFallbackOnly then
        return false
    end
    local crystalMask = API.GetABs_name("Crystal Mask", true)
    return crystalMask ~= nil and crystalMask.id ~= 0
end

local function drinkRestorePotion()
    local RESTORE_POTIONS = {
        23399, 23401, 23403, 23405, 23407, 23409, 
        3030, 3028, 3026, 3024
    }
    for _, potionId in ipairs(RESTORE_POTIONS) do
        if Inventory:InvItemcount(potionId) > 0 then
            API.DoAction_Inventory1(potionId, 0, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(500, 1000, 1500)
            print("Drank restore potion.")
            return true
        end
    end
    print("No restore potions available.")
    return false
end

local function restorePrayerForLightForm()
    local now = os.clock()
    if lastPrayerRestoreAttempt and now - lastPrayerRestoreAttempt < 5 then
        return
    end

    lastPrayerRestoreAttempt = now
    drinkRestorePotion()
end

local function checkAndSummonFamiliar()
    local hasFamiliar = Familiars:HasFamiliar2()
    local timeRemaining = Familiars:GetTimeRemaining()

    if hasFamiliar and timeRemaining >= familiarRefreshTimeMinutes then
        return
    end

    local pouch = familiarPouches[selectedFamiliar]
    if not pouch then
        print("No pouch is configured for " .. tostring(selectedFamiliar) .. ".")
        return
    end

    if Inventory:InvItemcount(pouch.id) == 0 then
        if missingFamiliarPouchId ~= pouch.id then
            print("No " .. pouch.name .. " in inventory.")
            missingFamiliarPouchId = pouch.id
        end
        return
    end
    missingFamiliarPouchId = nil

    local summoningPoints = API.GetSummoningPoints_()
    if summoningPoints < 100 then
        if not drinkRestorePotion() then
            print("Failed to summon familiar: Not enough summoning points and no restore potions.")
            return
        end
        summoningPoints = API.GetSummoningPoints_()
    end

    if summoningPoints < 100 then
        print("Not enough summoning points to summon " .. selectedFamiliar .. ".")
        return
    end

    API.DoAction_Inventory1(pouch.id, 0, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 600, 600)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 130, API.OFF_ACT_GeneralInterface_route)
    print(selectedFamiliar .. " summoned successfully.")
end

local function healthCheck()
    local prayer = API.GetPrayPrecent()
    local hp = API.GetHPrecent()
    local excalCD = API.DeBuffbar_GetIDstatus(IDS.EXCALIBUR, false)
    local excalFound = Inventory:InvItemcount(IDS.EXCALIBUR_AUGMENTED)
    local elvenCD = API.DeBuffbar_GetIDstatus(IDS.ELVEN_SHARD, false)
    
    if hp < 80 and not excalCD.found and excalFound > 0 then
        API.DoAction_Inventory1(IDS.EXCALIBUR_AUGMENTED, 0, 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(800, 500, 500)
    end

    if maintainLightForm and prayer < 70 then
        if elvenCD.found then
            restorePrayerForLightForm()
        elseif isElvenRitualShardOnBar() then
            print("Activating Ancient Elven Ritual Shard from ability bar.")
            local success = API.DoAction_Ability("Ancient elven ritual shard", 1, API.OFF_ACT_GeneralInterface_route)
            if not success then
                if Inventory:InvItemcount(IDS.ELVEN_SHARD) > 0 then
                    print("Ancient Elven Ritual Shard activation failed on ability bar. Falling back to inventory.")
                    API.DoAction_Inventory1(IDS.ELVEN_SHARD, IDS.ELVEN_SHARD, 1, API.OFF_ACT_GeneralInterface_route)
                else
                    print("Ancient Elven Ritual Shard is unavailable. Using a restore potion if available.")
                    restorePrayerForLightForm()
                end
            end
        elseif Inventory:InvItemcount(IDS.ELVEN_SHARD) > 0 then
            print("Activating Ancient Elven Ritual Shard from inventory.")
            API.DoAction_Inventory1(IDS.ELVEN_SHARD, IDS.ELVEN_SHARD, 1, API.OFF_ACT_GeneralInterface_route)
        else
            print("Ancient Elven Ritual Shard is unavailable. Using a restore potion if available.")
            restorePrayerForLightForm()
        end
        API.RandomSleep2(600, 600, 600)
    end

    if maintainCrystalMask and not API.Buffbar_GetIDstatus(25938, false).found then
        if isCrystalMaskOnBar() then
            print("Activating Crystal Mask from ability bar.")
            local success = API.DoAction_Ability("Crystal Mask", 1, API.OFF_ACT_GeneralInterface_route)
            if not success then
                crystalMaskFallbackOnly = true
                print("Crystal Mask activation failed on ability bar. Falling back to interface.")
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 182, API.OFF_ACT_GeneralInterface_route)
            end
        else
            crystalMaskFallbackOnly = true
            print("Crystal Mask not found on ability bar. Falling back to interface.")
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1461, 1, 182, API.OFF_ACT_GeneralInterface_route)
        end
        API.RandomSleep2(800, 500, 500)
    end

    if maintainLightForm and prayer > 50 and not API.Buffbar_GetIDstatus(26048, false).found then
        if isLightFormOnBar() then
            print("Activating Light Form from ability bar.")
            local success = API.DoAction_Ability("Light Form", 1, API.OFF_ACT_GeneralInterface_route)
            if not success then
                lightFormFallbackOnly = true
                print("Light Form activation failed on ability bar. Falling back to interface.")
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1458, 40, 23, API.OFF_ACT_GeneralInterface_route)
            end
        else
            lightFormFallbackOnly = true
            print("Light Form not found on ability bar. Falling back to interface.")
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1458, 40, 23, API.OFF_ACT_GeneralInterface_route)
        end
        API.RandomSleep2(800, 500, 500)
    end
end
  
local npcOptions = { "None" }
local selectedNpcIndex = 0
local selectedNpcName = nil
local useChests = false
local useBanking = true
local dropNonStackableWhenFull = false
local stopOnNoXp = false
local lastObservedThievingXp = nil
local lastThievingXpGainTime = nil
local thievingXpReadErrorLogged = false
local chestFreeSpaceTarget = math.random(3, 7)
local isRunning = false
local isPaused = false
local lowHealthBanked = false
local lastFamiliarCheck = 0
local nearbyChestCount = 0
local lastLoggedChestCount = nil

local function printMode(message)
    print("[" .. (useChests and "Chests" or "Pickpocket") .. "] " .. message)
end

local function resetThievingXpWatch()
    local thievingXp = API.GetSkillXP("THIEVING")
    if type(thievingXp) == "number" and thievingXp >= 0 then
        lastObservedThievingXp = thievingXp
        lastThievingXpGainTime = os.clock()
        thievingXpReadErrorLogged = false
    else
        lastObservedThievingXp = nil
        lastThievingXpGainTime = nil
        if not thievingXpReadErrorLogged then
            printMode("Could not read Thieving XP for inactivity check; waiting for a valid reading.")
            thievingXpReadErrorLogged = true
        end
    end
end

local PICKPOCKET_NPCS = {
    ["man"] = 1, ["woman"] = 1, ["anja"] = 1, ["drunken man"] = 1,
    ["hengel"] = 1, ["cuffs"] = 1, ["rusty"] = 1, ["narf"] = 1, ["jeff"] = 1,
    ["ikis krum"] = 1, ["foppish pierre"] = 1, ["pompous merchant"] = 1,
    ["gullible tourist"] = 1, ["villager"] = 1,
    ["farmer"] = 10, ["farmer sharon"] = 10, ["farmer rachel"] = 10,
    ["warrior woman"] = 25, ["desert phoenix"] = 25, ["al kharid warrior"] = 25,
    ["dig site workman"] = 25, ["rogue"] = 32,
    ["martin the master gardener"] = 38, ["master farmer"] = 38,
    ["farmer rowan"] = 38, ["master farmer lilah"] = 38, ["master farmer david"] = 38,
    ["port sarim guard"] = 40, ["ranger"] = 40, ["ghotistix"] = 42,
    ["brigand"] = 45, ["lanzig"] = 45, ["agnar"] = 45, ["sassilik"] = 45,
    ["borrokar"] = 45, ["inga"] = 45, ["freidir"] = 45, ["jennella"] = 45,
    ["pontak"] = 45, ["menaphite marketeer"] = 46,
    ["trainee archaeologist"] = 50, ["knight of ardougne"] = 55,
    ["rogue enforcer"] = 62, ["wizards' tower mage"] = 64,
    ["menaphite thug"] = 65, ["watchman"] = 65,
    ["paladin"] = 70, ["monkey knife fighter"] = 70,
    ["gnome child"] = 75, ["gnome woman"] = 75, ["gnome"] = 75,
    ["archaeologist"] = 78, ["hero"] = 80,
    ["crux eqal knight"] = 83, ["arvel"] = 85, ["goreu"] = 85,
    ["lady ithell"] = 85, ["mawrth"] = 85, ["ysgawyn"] = 85, ["bronwyn"] = 85,
    ["waiko islander"] = 86, ["trader"] = 90, ["iorwerth worker"] = 91,
    ["ithell worker"] = 92, ["rogue captain"] = 92, ["cadarn worker"] = 93,
    ["amlodd worker"] = 94, ["trahaearn worker"] = 95, ["hefin worker"] = 96,
    ["crwys worker"] = 97, ["meilyr worker"] = 98,
    ["vyrewatch tither"] = 100, ["goebie scavenger"] = 102,
    ["menaphos market guard"] = 104, ["wizards' tower master mage"] = 106,
    ["archaeology professor"] = 108, ["tzhaar-hur trader"] = 111,
    ["fairy trader"] = 113, ["vyrelord consumer"] = 118, ["vyrelady consumer"] = 118
}

local function validateSelectedTarget()
    local requiredLevel = PICKPOCKET_NPCS[selectedNpcName:lower()]
    if not requiredLevel then
        printMode("No Thieving requirement is configured for " .. selectedNpcName .. ".")
        API.Write_LoopyLoop(false)
        return false
    end

    local thieving = API.GetSkillByName("THIEVING")
    local currentLevel = thieving and thieving.level
    if not currentLevel then
        printMode("Could not read your Thieving level. Stopping script.")
        API.Write_LoopyLoop(false)
        return false
    end

    if currentLevel < requiredLevel then
        printMode(selectedNpcName .. " requires Thieving level " .. requiredLevel
            .. "; your level is " .. currentLevel .. ". Stopping script.")
        API.Write_LoopyLoop(false)
        return false
    end
    return true
end

local function dropNonStackableInventoryItems(targetFreeSpaces)
    local skippedIds = {}
    local droppedCount = 0
    local maximumFreeSpaces = 7

    while API.Read_LoopyLoop() and Inventory:FreeSpaces() < maximumFreeSpaces do
        local items = Inventory:GetItems() or {}
        local candidate
        local candidateCount = 0

        for _, item in ipairs(items) do
            if item.id and item.id > 0 and item.slot and not skippedIds[item.id] then
                local itemName = type(item.name) == "string" and item.name:lower() or ""
                if itemName:find("lockpick", 1, true)
                    or itemName:find("brawling gloves", 1, true)
                    or itemName:find("fremennik equipment patch", 1, true)
                    or itemName:find("ancient warriors' equipment patch", 1, true) then
                    skippedIds[item.id] = true
                else
                    local ok, itemData = pcall(function()
                        return Item:Get(item.id)
                    end)
                    if not ok or not itemData or type(itemData.stackable) ~= "boolean" then
                        printMode("Could not determine whether inventory item "
                            .. tostring(item.name or item.id) .. " is stackable; leaving it alone.")
                        skippedIds[item.id] = true
                    elseif not itemData.stackable then
                        candidate = item
                        for _, inventoryItem in ipairs(items) do
                            if inventoryItem.id == item.id then
                                candidateCount = candidateCount + 1
                            end
                        end
                        break
                    end
                end
            end
        end

        if not candidate then
            break
        end

        local dropped = API.DoAction_Interface(
            0x24, candidate.id, 8, 1473, 5, candidate.slot,
            API.OFF_ACT_GeneralInterface_route2
        )
        if not dropped then
            printMode("Failed to send drop action for "
                .. tostring(candidate.name or candidate.id) .. ".")
            skippedIds[candidate.id] = true
        else
            local dropWaitStart = os.clock()
            local itemRemoved = false
            while API.Read_LoopyLoop() and os.clock() - dropWaitStart < 2 do
                API.DoRandomEvents()
                API.RandomSleep2(150, 50, 50)

                local currentCount = 0
                for _, inventoryItem in ipairs(Inventory:GetItems() or {}) do
                    if inventoryItem.id == candidate.id then
                        currentCount = currentCount + 1
                    end
                end
                if currentCount < candidateCount then
                    itemRemoved = true
                    droppedCount = droppedCount + 1
                    break
                end
            end

            if not itemRemoved then
                printMode("Drop did not remove " .. tostring(candidate.name or candidate.id)
                    .. "; leaving remaining items of that type alone.")
                skippedIds[candidate.id] = true
            end
        end
    end

    if droppedCount == 0 then
        printMode("No non-stackable items could be dropped; free spaces: "
            .. Inventory:FreeSpaces() .. " (preferred minimum: " .. targetFreeSpaces .. ").")
    else
        printMode("Dropped " .. droppedCount .. " non-stackable inventory item(s); free spaces: "
            .. Inventory:FreeSpaces() .. " (preferred minimum: " .. targetFreeSpaces .. ").")
    end

    return Inventory:FreeSpaces() >= targetFreeSpaces
end

local function bankForRecovery()
    local inventoryWasFull = Inventory:IsFull()
    local nearbyEntities = API.ReadAllObjectsArray({0, 12, 1}, {-1}, {}) or {}
    local playerPosition = API.PlayerCoordfloat()
    local nearestBank
    local nearestDepositBox

    for _, entity in ipairs(nearbyEntities) do
        local name = type(entity.Name) == "string" and entity.Name or ""
        local lowerName = name:lower()
        local isBanker = entity.Type == 1 and lowerName:find("banker", 1, true)
        local isBankObject = (entity.Type == 0 or entity.Type == 12)
            and (lowerName:find("bank chest", 1, true) or lowerName:find("bank booth", 1, true))
        local isDepositBox = (entity.Type == 0 or entity.Type == 12)
            and lowerName:find("deposit box", 1, true)

        if (isBanker or isBankObject or isDepositBox) and name ~= "" then
            local distance = entity.Distance
            if not distance and entity.Tile_XYZ then
                distance = API.Math_DistanceF(entity.Tile_XYZ, playerPosition)
            end
            if distance and distance <= 50 then
                if (isBanker or isBankObject)
                    and (not nearestBank or distance < nearestBank.distance) then
                    nearestBank = {
                        name = name,
                        isNpc = isBanker,
                        distance = distance
                    }
                end
                if isDepositBox
                    and (not nearestDepositBox or distance < nearestDepositBox.distance) then
                    nearestDepositBox = {
                        name = name,
                        distance = distance
                    }
                end
            end
        end
    end

    if not nearestBank and not nearestDepositBox then
        printMode("No nearby bank chest, booth, banker, or deposit box was found. Stopping script.")
        API.Write_LoopyLoop(false)
        return false
    end

    if nearestBank then
        printMode("Loading last preset from " .. nearestBank.name)
        if nearestBank.isNpc then
            Interact:NPC(nearestBank.name, "Load Last Preset from", nil, 50)
        else
            Interact:Object(nearestBank.name, "Load Last Preset from", nil, 50)
        end
    else
        printMode("No nearby bank or banker found; depositing all items at "
            .. nearestDepositBox.name)
        Interact:Object(nearestDepositBox.name, "Deposit-All", nil, 50)
    end

    if inventoryWasFull then
        printMode("Waiting for inventory space.")
        while API.Read_LoopyLoop() and Inventory:IsFull() do
            API.DoRandomEvents()
            API.RandomSleep2(250, 100, 150)
        end
    end

    if API.Read_LoopyLoop() then
        local hp = API.GetHPrecent()
        if hp < 100 then
            printMode("Waiting for health to reach 100%.")
            local lastHpChangeTime = os.clock()
            while API.Read_LoopyLoop() and hp < 100 do
                API.DoRandomEvents()
                API.RandomSleep2(500, 100, 100)

                local currentHp = API.GetHPrecent()
                if currentHp ~= hp then
                    hp = currentHp
                    lastHpChangeTime = os.clock()
                elseif os.clock() - lastHpChangeTime >= 5 then
                    printMode("Health has not changed for 5 seconds. Continuing.")
                    break
                end
            end
        end
    end

    return true
end

local function scanNearbyChests(logResults)
    local nearbyObjects = API.ReadAllObjectsArray({0, 12}, {-1}, {})
    local foundChests = {}
    local currentFloor = API.GetFloorLv_2()
    for _, object in ipairs(nearbyObjects or {}) do
        local firstAction = type(object.Action) == "string"
            and object.Action:lower():gsub("%W", "")
            or ""
        local isPickableChest = type(object.Name) == "string"
            and object.Name:lower():find("chest", 1, true)
            and (firstAction == "picklock" or firstAction == "lockpick")
            and (object.Distance or math.huge) <= 10

        if isPickableChest then
            if object.Floor == currentFloor then
                foundChests[#foundChests + 1] = object
            elseif logResults then
                printMode("Nearby lock-pick chest rejected by floor check: "
                    .. tostring(object.Name) .. " (ID " .. tostring(object.Id)
                    .. ", type " .. tostring(object.Type)
                    .. ", object floor " .. tostring(object.Floor)
                    .. ", player floor " .. tostring(currentFloor) .. ").")
            end
        end
    end

    nearbyChestCount = #foundChests
    if logResults and nearbyChestCount ~= lastLoggedChestCount then
        if nearbyChestCount > 0 then
            printMode("Found " .. nearbyChestCount .. " nearby chest(s)")
        else
            printMode("No nearby chests found")
        end
        lastLoggedChestCount = nearbyChestCount
    end
    return foundChests
end

local function scanNpcs()
    local foundNames = {}
    local seenNames = {}
    local allNpcs = API.ReadAllObjectsArray({1}, {-1}, {})
    local playerPosition = API.PlayerCoordfloat()

    for _, npc in ipairs(allNpcs or {}) do
        local name = npc.Name
        local distance = npc.Tile_XYZ and API.Math_DistanceF(npc.Tile_XYZ, playerPosition) or math.huge
        if type(name) == "string"
            and name ~= ""
            and PICKPOCKET_NPCS[name:lower()] ~= nil
            and npc.Id ~= 0
            and distance <= 50
            and npc.Bool1 == 0
            and not seenNames[name] then
            seenNames[name] = true
            foundNames[#foundNames + 1] = name
        end
    end

    table.sort(foundNames)
    npcOptions = { "None" }
    for _, name in ipairs(foundNames) do
        npcOptions[#npcOptions + 1] = name
    end

    local retainedIndex
    if selectedNpcName then
        for index, name in ipairs(npcOptions) do
            if name == selectedNpcName then
                retainedIndex = index
                break
            end
        end
    end

    if retainedIndex then
        selectedNpcIndex = retainedIndex - 1
    else
        selectedNpcName = nil
        selectedNpcIndex = 0
        isRunning = false
        isPaused = false
    end

    printMode("Scan found " .. #foundNames .. " nearby NPC(s) with an available action")
end

local function drawPickpocketGui()
    ImGui.SetNextWindowSize(380, 460, ImGuiCond.FirstUseEver)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.035, 0.025, 0.055, 0.98)
    ImGui.PushStyleColor(ImGuiCol.TitleBg, 0.11, 0.055, 0.19, 1.0)
    ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0.30, 0.12, 0.48, 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.09, 0.065, 0.13, 1.0)
    ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.24, 0.12, 0.36, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Button, 0.20, 0.09, 0.32, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.38, 0.16, 0.58, 1.0)
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0.50, 0.22, 0.72, 1.0)
    ImGui.PushStyleColor(ImGuiCol.CheckMark, 0.78, 0.48, 1.0, 1.0)
    ImGui.PushStyleColor(ImGuiCol.Text, 0.94, 0.90, 1.0, 1.0)
    if ImGui.Begin("Pickpocket and Chests") then
        ImGui.Text("Select an NPC or enable chest lock-picking.")
        ImGui.Spacing()

        if ImGui.Button("Refresh NPCs", 110, 26) then
            scanNpcs()
        end
        ImGui.SameLine()
        if ImGui.Button("Refresh Chests", 110, 26) then
            scanNearbyChests(true)
        end

        ImGui.Spacing()
        ImGui.Text("Pickpocket target")
        ImGui.PushItemWidth(220)
        local changed, newIndex = ImGui.Combo("Target", selectedNpcIndex, npcOptions)
        ImGui.PopItemWidth()
        if changed and npcOptions[newIndex + 1] then
            selectedNpcIndex = newIndex
            selectedNpcName = npcOptions[newIndex + 1] ~= "None"
                and npcOptions[newIndex + 1]
                or nil
            isRunning = false
            isPaused = false
            if selectedNpcName then
                printMode("Selected target: " .. selectedNpcName)
            else
                printMode("No NPC target selected")
            end
        end

        ImGui.Spacing()
        local chestChanged, newUseChests = ImGui.Checkbox("Lock-pick nearby chests", useChests)
        if chestChanged then
            useChests = newUseChests
            if useChests then
                chestFreeSpaceTarget = math.random(3, 7)
            end
            printMode(useChests and "Chest mode selected; no NPC target required" or "Chest mode disabled")
            if useChests then
                scanNearbyChests(true)
            end
        end
        local bankingChanged, newUseBanking = ImGui.Checkbox("Bank when inventory is full", useBanking)
        if bankingChanged then
            useBanking = newUseBanking
            printMode("Automatic banking " .. (useBanking and "enabled" or "disabled"))
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("When enabled, load the last preset from the nearest bank when your inventory is full. The script stops if no nearby bank is found.")
        end
        local dropChanged, newDropNonStackable = ImGui.Checkbox(
            "Drop non-stackable items when full",
            dropNonStackableWhenFull
        )
        if dropChanged then
            dropNonStackableWhenFull = newDropNonStackable
            printMode("Drop non-stackable items when full "
                .. (dropNonStackableWhenFull and "enabled" or "disabled"))
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("In chest mode, randomly aim to keep 3-7 free slots by dropping non-stackable items. If the target cannot be reached, continue as long as at least 1 slot remains.")
        end
        local noXpChanged, newStopOnNoXp = ImGui.Checkbox(
            "Stop after 5 minutes without Thieving XP",
            stopOnNoXp
        )
        if noXpChanged then
            stopOnNoXp = newStopOnNoXp
            if stopOnNoXp then
                resetThievingXpWatch()
            else
                lastObservedThievingXp = nil
                lastThievingXpGainTime = nil
                thievingXpReadErrorLogged = false
            end
            printMode("Stop after 5 minutes without Thieving XP "
                .. (stopOnNoXp and "enabled" or "disabled"))
        end
        if ImGui.IsItemHovered() then
            ImGui.SetTooltip("Stops the script if Thieving XP does not increase for 5 minutes while running (paused time is excluded).")
        end
        local crystalMaskChanged, newMaintainCrystalMask = ImGui.Checkbox(
            "Maintain Crystal Mask",
            maintainCrystalMask
        )
        if crystalMaskChanged then
            maintainCrystalMask = newMaintainCrystalMask
        end
        local lightFormChanged, newMaintainLightForm = ImGui.Checkbox(
            "Maintain Light Form",
            maintainLightForm
        )
        if lightFormChanged then
            maintainLightForm = newMaintainLightForm
        end
        local familiarChanged, newMaintainFamiliar = ImGui.Checkbox(
            "Maintain familiar",
            maintainFamiliar
        )
        if familiarChanged then
            maintainFamiliar = newMaintainFamiliar
        end
        if maintainFamiliar then
            ImGui.PushItemWidth(220)
            local familiarChanged, familiarIndex = ImGui.Combo(
                "Familiar",
                selectedFamiliarIndex,
                familiarOptions
            )
            ImGui.PopItemWidth()
            if familiarChanged and familiarOptions[familiarIndex + 1] then
                selectedFamiliarIndex = familiarIndex
                selectedFamiliar = familiarOptions[familiarIndex + 1]
                printMode("Selected familiar: " .. selectedFamiliar)
            end
        end

        local runMode = useChests and "Lock-picking chests" or "Pickpocketing"
        local status = not isRunning and "Stopped" or (isPaused and "Paused" or runMode)
        ImGui.Text("Status: " .. status)
        local startPauseLabel = not isRunning and "Start"
            or (isPaused and "Resume" or "Pause")
        if ImGui.Button(startPauseLabel, 110, 28) then
            if not isRunning then
                if useChests or selectedNpcName then
                    if useChests or validateSelectedTarget() then
                        isRunning = true
                        isPaused = false
                        if stopOnNoXp then
                            resetThievingXpWatch()
                        end
                        printMode("Started " .. (useChests and "Lock-picking chests" or ("target: " .. selectedNpcName)))
                    else
                        isRunning = false
                        isPaused = false
                    end
                else
                    printMode("Select a target or enable chest lock-picking before starting")
                end
            else
                isPaused = not isPaused
                if stopOnNoXp then
                    resetThievingXpWatch()
                end
                printMode(isPaused and "Paused" or "Resumed")
            end
        end
        ImGui.SameLine()
        if ImGui.Button("Stop", 110, 28) then
            isRunning = false
            isPaused = false
            printMode("Stopped; exiting script.")
            API.Write_LoopyLoop(false)
        end
    end
    ImGui.End()
    ImGui.PopStyleColor(10)
end

scanNpcs()
scanNearbyChests(true)
if type(ClearRender) == "function" then
    ClearRender()
end
if type(DrawImGui) == "function" then
    DrawImGui(drawPickpocketGui)
end

while API.Read_LoopyLoop() do
    API.DoRandomEvents()
    healthCheck()
    if stopOnNoXp and isRunning and not isPaused then
        local currentThievingXp = API.GetSkillXP("THIEVING")
        if type(currentThievingXp) == "number" and currentThievingXp >= 0 then
            if type(lastObservedThievingXp) ~= "number" then
                lastObservedThievingXp = currentThievingXp
                lastThievingXpGainTime = os.clock()
                thievingXpReadErrorLogged = false
            elseif currentThievingXp > lastObservedThievingXp then
                lastObservedThievingXp = currentThievingXp
                lastThievingXpGainTime = os.clock()
                thievingXpReadErrorLogged = false
            elseif currentThievingXp < lastObservedThievingXp then
                lastObservedThievingXp = currentThievingXp
            end

            if lastThievingXpGainTime
                and os.clock() - lastThievingXpGainTime >= 300 then
                printMode("No Thieving XP gained for 5 minutes. Stopping script.")
                isRunning = false
                API.Write_LoopyLoop(false)
                break
            end
        else
            lastObservedThievingXp = nil
            lastThievingXpGainTime = nil
            if not thievingXpReadErrorLogged then
                printMode("Could not read Thieving XP for inactivity check; waiting for a valid reading.")
                thievingXpReadErrorLogged = true
            end
        end
    end
    local foundChests = useChests and scanNearbyChests(false) or {}

    if isRunning and not isPaused then
        if maintainFamiliar and os.clock() - lastFamiliarCheck >= 5 then
            lastFamiliarCheck = os.clock()
            checkAndSummonFamiliar()
        end

        local hp = API.GetHPrecent()
        if hp >= 10 then
            lowHealthBanked = false
        end

        if hp < 10 and not lowHealthBanked then
            lowHealthBanked = true
            printMode("Health is below 10%. Banking to restore health.")
            bankForRecovery()
        elseif Inventory:IsFull()
            or (useChests and dropNonStackableWhenFull
                and Inventory:FreeSpaces() < chestFreeSpaceTarget) then
            local spaceFreed = useChests
                and dropNonStackableWhenFull
                and dropNonStackableInventoryItems(chestFreeSpaceTarget)
            if not spaceFreed then
                local freeSpaces = Inventory:FreeSpaces()
                if freeSpaces >= 1 then
                    chestFreeSpaceTarget = freeSpaces
                elseif useBanking then
                    bankForRecovery()
                else
                    printMode("Inventory is full and no eligible items can be dropped; automatic banking is disabled. Stopping script.")
                    API.Write_LoopyLoop(false)
                end
            end
        elseif hp >= 10 and not API.CheckAnim(80) and not API.ReadPlayerMovin2() then
            if useChests then
                local chest
                for _, candidate in ipairs(foundChests) do
                    if candidate.Id and candidate.Id > 0
                        and candidate.Distance and candidate.Distance <= 10
                        and (not chest or candidate.Distance < chest.Distance) then
                        chest = candidate
                    end
                end

                if chest then
                    if chest.Floor ~= API.GetFloorLv_2() then
                        printMode("Skipping chest on a different floor: "
                            .. tostring(chest.Name) .. " (ID " .. chest.Id .. ").")
                    elseif API.DoAction_Object_Direct(
                        0x29,
                        API.OFF_ACT_GeneralObject_route0,
                        chest
                    ) then
                        API.RandomSleep2(1800, 1200, 1000)
                    else
                        printMode("Failed to send Lock-pick action to "
                            .. tostring(chest.Name) .. " (ID " .. chest.Id .. ").")
                    end
                end
            elseif selectedNpcName and Interact:NPC(selectedNpcName, "Pickpocket", nil, 50) then
                API.RandomSleep2(800, 100, 100)
            end
        end
        API.DoRandomEvents()
    end

    API.RandomSleep2(100, 100, 100)
end
