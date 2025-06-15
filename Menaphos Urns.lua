-- Title: Urn Crafter (Menaphos)
-- Author: <Matteus>
-- Description: Makes Urns in Priff select your urn then start>
-- Version: <1.0>
-- Category: Crafting
-- Date : 2024.08.26

local API = require("api")

local MAX_IDLE_TIME_MINUTES = 5
local BANK_CHEST = 107491
local POTTERSWHEEL = 107724
local SOFT_CLAY_ID = 1761
local MIN_SOFT_CLAY_COUNT = 2

API.SetDrawTrackedSkills(true)

local function hasEnoughSoftClay()
    return (API.InvItemcount_1(SOFT_CLAY_ID) or 0) >= MIN_SOFT_CLAY_COUNT
end

local function getSelectedItemId()
    return API.VB_FindPSettinOrder(1170, 0).state
end

local function isOpen()
    return getSelectedItemId() ~= -1 and (API.Compare2874Status(18, false) or API.Compare2874Status(40, false))
end

local function waitForPotteryInterface()
    local waitCounter = 0
    local maxWait = 50
    while waitCounter < maxWait do
        if isOpen() then
            return true
        end
        API.RandomSleep2(100, 200, 300)
        waitCounter = waitCounter + 1
    end
    return false
end

--main loop
while API.Read_LoopyLoop() do
    API.DoRandomEvents()
    API.SetMaxIdleTime(MAX_IDLE_TIME_MINUTES)

    if API.CheckAnim(50) or API.ReadPlayerMovin2() or API.isProcessing() then
        API.RandomSleep2(200, 300, 400)
        goto continue
    end

    if not hasEnoughSoftClay() then
        if not API.InvFull_() then
            API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, { BANK_CHEST }, 50)
            API.RandomSleep2(200, 300, 400)
        end
    end

    if hasEnoughSoftClay() then
        API.DoAction_Object1(0x3e, API.OFF_ACT_GeneralObject_route0, { POTTERSWHEEL }, 50)

        if waitForPotteryInterface() then
            API.KeyboardPress32(0x20, 0)
        else
            print("Failed to open the pottery interface.")
        end
    end

    ::continue::
    API.RandomSleep2(200, 300, 400)
end
