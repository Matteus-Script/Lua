--[[
# Script Name:   Smelter
# Description:   Smelts bars and deposits them in the furnace
# Author:        Matteus
# Version:       1.2
# Date:          2024.08.21
--]]

local API = require('api')
local UTILS = require('utils')

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local function isOpen()
    return API.Compare2874Status(85, false)
end

local scriptRunning = false
local stopRequested = false

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
        stopRequested = true
        scriptRunning = false
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

local BAR_OPTIONS = {
    "Bronze", "Iron", "Steel", "Mithril", "Adamant", "Rune", "Orikalkum",
    "Necronium", "Bane", "ElderRune", "Primal", "Silver", "Gold", "Cannonball"
}

local settings = {
    selectedBar = "Bronze",
    useElvenRitualShard = true,
    useChronicleAttraction = false,
    useSuperheatForm = true,
}

local function getConfigPath()
    local scriptPath = debug.getinfo(1, "S").source
    if scriptPath and scriptPath:sub(1, 1) == "@" then
        scriptPath = scriptPath:sub(2)
    end

    local scriptDir = scriptPath and scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
    return scriptDir .. "\\Smelter.config.json"
end

local function saveSettings()
    local ok, encoded = pcall(API.JsonEncode, settings)
    if not ok or not encoded then
        print("[Smelter] Failed to encode settings")
        return false
    end

    local configPath = getConfigPath()
    local file, openError = io.open(configPath, "w")
    if not file then
        print("[Smelter] Failed to write config: " .. tostring(openError or configPath))
        return false
    end

    local writeOk, writeError = file:write(encoded)
    local closeOk, closeError = file:close()
    if not writeOk or closeOk == nil then
        print("[Smelter] Failed to save config: " .. tostring(writeError or closeError))
        return false
    end
    return true
end

local function loadSettings()
    local file = io.open(getConfigPath(), "r")
    if not file then
        return false
    end

    local content = file:read("*a")
    file:close()

    local ok, data = pcall(API.JsonDecode, content)
    if not ok or type(data) ~= "table" then
        print("[Smelter] Failed to decode config")
        return false
    end

    if type(data.selectedBar) == "string" and BAR_SELECTION[data.selectedBar] then
        settings.selectedBar = data.selectedBar
    end
    if type(data.useElvenRitualShard) == "boolean" then
        settings.useElvenRitualShard = data.useElvenRitualShard
    end
    if type(data.useChronicleAttraction) == "boolean" then
        settings.useChronicleAttraction = data.useChronicleAttraction
    end
    if type(data.useSuperheatForm) == "boolean" then
        settings.useSuperheatForm = data.useSuperheatForm
    end
    return true
end

loadSettings()
local selectedBar = settings.selectedBar
print("Selected bar: " .. selectedBar)

local firstRun = true

local function performInterfaceAction(action, ...)
    action(...)
    API.RandomSleep2(500, 700, 100)
end

local function hasElvenRitualShard()
    return Inventory:InvItemcount(43358) > 0
end

local chronicleAttractionFallbackOnly = false
local superheatFormFallbackOnly = false

local function isChronicleAttractionOnBar()
    if chronicleAttractionFallbackOnly then
        return false
    end
    local chronicle = API.GetABs_name("Chronicle Attraction", true)
    if chronicle == nil or chronicle.id == 0 then
        chronicleAttractionFallbackOnly = true
        return false
    end
    return true
end

local function isSuperheatFormOnBar()
    if superheatFormFallbackOnly then
        return false
    end
    local superheat = API.GetABs_name("Superheat Form", true)
    if superheat == nil or superheat.id == 0 then
        superheatFormFallbackOnly = true
        return false
    end
    return true
end

local function checkBuffs()
    local buffsToCheck = {}
    if settings.useChronicleAttraction then
        buffsToCheck[#buffsToCheck + 1] = {
            id = 26053,
            name = "Chronicle Attraction",
            action = function()
                if isChronicleAttractionOnBar() then
                    print("Activating Chronicle Attraction from ability bar.")
                    local success = API.DoAction_Ability("Chronicle Attraction", 1, API.OFF_ACT_GeneralInterface_route)
                    if not success then
                        chronicleAttractionFallbackOnly = true
                        print("Chronicle Attraction activation failed on ability bar. Falling back to interface.")
                        performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 30, API.OFF_ACT_GeneralInterface_route)
                    end
                else
                    print("Chronicle Attraction not found on ability bar. Falling back to interface.")
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 30, API.OFF_ACT_GeneralInterface_route)
                end
            end
        }
    end
    if settings.useSuperheatForm then
        buffsToCheck[#buffsToCheck + 1] = {
            id = 26055,
            name = "Superheat Form",
            action = function()
                if isSuperheatFormOnBar() then
                    print("Activating Superheat Form from ability bar.")
                    local success = API.DoAction_Ability("Superheat Form", 1, API.OFF_ACT_GeneralInterface_route)
                    if not success then
                        superheatFormFallbackOnly = true
                        print("Superheat Form activation failed on ability bar. Falling back to interface.")
                        performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 34, API.OFF_ACT_GeneralInterface_route)
                    end
                else
                    print("Superheat Form not found on ability bar. Falling back to interface.")
                    performInterfaceAction(API.DoAction_Interface, 0xffffffff, 0xffffffff, 1, 1458, 40, 34, API.OFF_ACT_GeneralInterface_route)
                end
            end
        }
    end

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
        Interact:Object("Furnace", "Smelt")

        if UTILS.SleepUntil(isOpen, 10, "Waiting for furnace interface to open") then
        break
        end

        retries = retries + 1
        print("Furnace interface failed to open. Retrying... (Attempt " .. retries .. "/" .. maxRetries .. ")")
    end

    if not isOpen() then
        print("Furnace interface failed to open after " .. maxRetries .. " attempts. Stopping script.")
        stopRequested = true
        scriptRunning = false
        API.Write_LoopyLoop(false)
        return
    end

    if not hasSufficientOres(selectedBar) then
        print("Not enough ores in furnace to smelt " .. (selectedBar or "Unknown") .. ". Stopping script.")
        stopRequested = true
        scriptRunning = false
        API.Write_LoopyLoop(false)
        return
    end

    if isOpen() then
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
    if not settings.useElvenRitualShard then
        return
    end

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

local selectedBarIndex = 0
for index, barName in ipairs(BAR_OPTIONS) do
    if barName == selectedBar then
        selectedBarIndex = index - 1
        break
    end
end

local function drawGUI()
    ImGui.SetNextWindowSize(360, 200, ImGuiCond.Always)
    if ImGui.Begin("Smelter") then
        local status = stopRequested and "Stopped" or (scriptRunning and "Running" or "Paused")
        ImGui.Text("Status: " .. status)
        ImGui.Spacing()

        if ImGui.Button(scriptRunning and "Stop" or "Start", 90, 28) and not stopRequested then
            if scriptRunning then
                stopRequested = true
                scriptRunning = false
                API.Write_LoopyLoop(false)
            else
                local startBar = BAR_OPTIONS[selectedBarIndex + 1]
                if not startBar then
                    print("[Smelter] Invalid bar selection; cannot start")
                else
                    selectedBar = startBar
                    settings.selectedBar = startBar
                    firstRun = true
                    if not saveSettings() then
                        print("[Smelter] Failed to save selected bar on start")
                    end
                    print("Starting smelting: " .. selectedBar)
                    scriptRunning = true
                end
                startXp = API.GetSkillXP(trackedSkill)
                lastXpTime = os.time()
            end
        end
        ImGui.SameLine()
        if ImGui.Button("Pause", 90, 28) and not stopRequested then
            scriptRunning = false
        end

        ImGui.Spacing()
        local changed, newIndex = ImGui.Combo("Smelt", selectedBarIndex, BAR_OPTIONS)
        if changed then
            local newBar = type(newIndex) == "number" and BAR_OPTIONS[newIndex + 1] or nil
            if newBar then
                selectedBarIndex = newIndex
                selectedBar = newBar
                settings.selectedBar = newBar
                firstRun = true
                print("[Smelter] Selected bar changed to: " .. newBar)
                if not saveSettings() then
                    print("[Smelter] Failed to save selected bar")
                end
            else
                print("[Smelter] Bar selection returned invalid index: " .. tostring(newIndex))
            end
        end
        ImGui.Text("Selected bar: " .. selectedBar)

        local shardChanged, useShard = ImGui.Checkbox("Use Elven Ritual Shard", settings.useElvenRitualShard)
        if shardChanged then
            settings.useElvenRitualShard = useShard
            print("[Smelter] Elven Ritual Shard " .. (useShard and "enabled" or "disabled"))
            if not saveSettings() then
                print("[Smelter] Failed to save Elven Ritual Shard setting")
            end
        end

        local chronicleChanged, useChronicle = ImGui.Checkbox("Use Chronicle Attraction", settings.useChronicleAttraction)
        if chronicleChanged then
            settings.useChronicleAttraction = useChronicle
            print("[Smelter] Chronicle Attraction " .. (useChronicle and "enabled" or "disabled"))
            if not saveSettings() then
                print("[Smelter] Failed to save Chronicle Attraction setting")
            end
        end

        local superheatChanged, useSuperheat = ImGui.Checkbox("Use Superheat Form", settings.useSuperheatForm)
        if superheatChanged then
            settings.useSuperheatForm = useSuperheat
            print("[Smelter] Superheat Form " .. (useSuperheat and "enabled" or "disabled"))
            if not saveSettings() then
                print("[Smelter] Failed to save Superheat Form setting")
            end
        end
    end
    ImGui.End()
end

if type(ClearRender) == "function" then
    ClearRender()
end
if type(DrawImGui) == "function" then
    DrawImGui(drawGUI)
end

while API.Read_LoopyLoop() do
    if scriptRunning then
        if not API.isProcessing() then
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
    end
    if scriptRunning then
        API.RandomSleep2(600, 700, 100)
    else
        API.RandomSleep2(10, 0, 0)
    end
end

checkFurnaceContents()
