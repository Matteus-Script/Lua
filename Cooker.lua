local API = require("api")
local UTILS = require("utils")

API.SetDrawTrackedSkills(true)
API.SetMaxIdleTime(10)

local function scanInventoryForRaw()
  local inventory = API.ReadInvArrays33()
  local rawItems = {}

  for _, item in ipairs(inventory) do
    if item.textitem and item.textitem:lower():find("raw") then
      table.insert(rawItems, item)
    end
  end

  return rawItems
end

local function printRawItems(rawItems)
  if #rawItems > 0 then
    local itemCounts = {}
    for _, item in ipairs(rawItems) do
      local key = item.itemid1
      if not itemCounts[key] then
        itemCounts[key] = {name = item.textitem, count = 0}
      end
      itemCounts[key].count = itemCounts[key].count + 1
    end
    
    for itemId, data in pairs(itemCounts) do
      print(string.format("Found: %dx %s [%d]", data.count, data.name, itemId))
    end
    return true
  end
  return false
end

local function isOpen()
    return API.Compare2874Status(40, false) or API.Compare2874Status(18, false)
end
local function startCooking()
    Interact:Object("Range", "Cook-at")
    local success = UTILS.SleepUntil(isOpen, 10, "interface to open")
    if success then
        API.KeyboardPress32(0x20, 0)
        UTILS.SleepUntil(function() return not isOpen() end, 10, "interface to close")
        return true
    end
    return false
end

local function waitForCookingComplete()
    API.DoRandomEvents()
    UTILS.SleepUntil(function() 
        local processing = API.isProcessing()
        return not processing 
    end, 80, "Processing...")
    API.RandomSleep2(200, 300, 75)
end

local function refillFromBank()
    Interact:Object("Bank chest", "Load Last Preset from", 10)
end

local rawItems = scanInventoryForRaw()
if not printRawItems(rawItems) then
  print("No raw items at start, banking first...")
end

API.Write_LoopyLoop(true)
local bankAttempts = 0

while (API.Read_LoopyLoop()) do
    API.DoRandomEvents()
    local rawItems = scanInventoryForRaw()
    if #rawItems > 0 then
        if startCooking() then
            waitForCookingComplete()
        end
        bankAttempts = 0
    else
        refillFromBank()
        API.RandomSleep2(800, 1200, 100)
        local rawItems = scanInventoryForRaw()
        if printRawItems(rawItems) then
            bankAttempts = 0
        else
            print("[STOP] No raw items found after bank refill.")
            API.Write_LoopyLoop(false)
        end
        bankAttempts = bankAttempts + 1
        if bankAttempts >= 3 then
            print("[STOP] Bank refill attempts exceeded (3 attempts).")
            API.Write_LoopyLoop(false)
        end
    end
    API.RandomSleep2(300, 700, 150)
end
