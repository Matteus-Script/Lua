local API = require("api")
local UTILS = require("utils")

API.SetMaxIdleTime(10)
API.SetDrawTrackedSkills(true)

local CONSTANTS = {
    PICKLOCK_ANIM = 26104,
    DOOR_ID = 95663,
    SARCOPHAGUS_ID = 59796,
    OUTSIDE_AREA = {x = 3288, y = 2801, radius = 10, z = 0},
    ENTRY_AREA = {x = 1942, y = 4492, radius = 10, z = 0},
    DOOR_RETRY_LIMIT = 5,
    DOOR_RETRY_CHECK_DELAY = {min = 400, mid = 600, max = 800},
    MOVEMENT_THRESHOLD = 2,
}

local ROOMS = {
    [1] = {minX=1917,maxX=1937,minY=4463,maxY=4482,post={x=1928,y=4471}},
    [2] = {minX=1942,maxX=1963,minY=4462,maxY=4481,post={x=1954,y=4472}},
    [3] = {minX=1966,maxX=1982,minY=4453,maxY=4471,post={x=1977,y=4464}},
    [4] = {minX=1922,maxX=1946,minY=4446,maxY=4463,post={x=1932,y=4453}},
    [5] = {minX=1949,maxX=1967,minY=4442,maxY=4457,post={x=1960,y=4444}},
    [6] = {minX=1921,maxX=1936,minY=4423,maxY=4446,post={x=1927,y=4429}},
    [7] = {minX=1938,maxX=1958,minY=4419,maxY=4441,post={x=1944,y=4426}},
    [8] = {minX=1963,maxX=1978,minY=4415,maxY=4441,post={x=1975,y=4425}},
}

local function CreateState()
    return {
        room = 1,
        trapDone = false,
        trapJustFinished = false,
        insideStarted = false,
        roomLocked = false,
    }
end

local function CreateDoorState()
    return {
        locked = false,
        waitingAnim = false,
        retryTicks = 0,
        lastCount = 0,
    }
end

local state = CreateState()
local doorState = CreateDoorState()

local function FullReset()
    state = CreateState()
    doorState = CreateDoorState()
end

local function ResetDoorState()
    doorState = CreateDoorState()
end

local function IsPickLockAnimActive()
    return API.ReadPlayerAnim() == CONSTANTS.PICKLOCK_ANIM
end

local function IsMoving()
    if API.IsPlayerMoving_ then
        return API.IsPlayerMoving_()
    end
    return false
end

local function GetPlayerPos()
    return API.PlayerCoord()
end

local function PlayerMovedBy(startPos, threshold)
    local currentPos = GetPlayerPos()
    if not currentPos or not startPos then return false end
    return math.abs(currentPos.x - startPos.x) > threshold
        or math.abs(currentPos.y - startPos.y) > threshold
end

local function WaitForMovement(startPos, maxWait, label)
    return UTILS.SleepUntil(function()
        return PlayerMovedBy(startPos, CONSTANTS.MOVEMENT_THRESHOLD)
    end, maxWait, label)
end

local function InAreaCoords(x, y, radius, z)
    return API.PInArea(x, radius, y, radius, z)
end

local function InRoom(i)
    local r = ROOMS[i]
    if not r then return false end

    return API.PInArea21(
        r.minX,
        r.maxX,
        r.minY,
        r.maxY
    )
end

local function GetCurrentRoom()
    local p = GetPlayerPos()
    if not p then return nil end

    for i = 1, 8 do
        local r = ROOMS[i]
        if r and r.minX then
            if p.x >= r.minX and p.x <= r.maxX
            and p.y >= r.minY and p.y <= r.maxY then
                return i
            end
        end
    end
    return nil
end

local function InPostTrap(i)
    local p = ROOMS[i].post
    local pl = GetPlayerPos()
    if not p or not pl then return false end

    return math.abs(pl.x - p.x) <= 1
       and math.abs(pl.y - p.y) <= 1
end

local function Outside()
    local area = CONSTANTS.OUTSIDE_AREA
    if not InAreaCoords(area.x, area.y, area.radius, area.z) then return end

    print("[ENTRY] Outside pyramid - entering")
    API.RandomSleep2(1200, 1000, 150)
    Interact:Object("An anonymous looking door", "Search")

    local entryArea = CONSTANTS.ENTRY_AREA
    UTILS.SleepUntil(function()
        return InAreaCoords(entryArea.x, entryArea.y, entryArea.radius, entryArea.z)
    end, 15, "Enter pyramid")

    print("[ENTRY] Entered pyramid - at entry area")
    state.insideStarted = false
end

local function Inside()
    local entryArea = CONSTANTS.ENTRY_AREA
    if not InAreaCoords(entryArea.x, entryArea.y, entryArea.radius, entryArea.z) or state.insideStarted then
        return
    end

    print("[ENTRY] Starting minigame at entry area")
    API.RandomSleep2(1200, 1000, 150)
    Interact:NPC("Guardian mummy", "Start minigame")

    UTILS.SleepUntil(function()
        return GetCurrentRoom() == 1
    end, 15, "Room 1 start")

    print("[ENTRY] Minigame started - entering Room 1")
    state.insideStarted = true
    state.room = 1
    state.trapDone = false
end

local function IsValidDoorObject(obj)
    return obj.Id == CONSTANTS.DOOR_ID
        and obj.TileX and obj.TileY
        and obj.Bool1 == 0
        and obj.Action and obj.Action ~= ""
end

local function IsInRoom(obj, room)
    local x = math.floor(obj.TileX / 512)
    local y = math.floor(obj.TileY / 512)
    return x >= room.minX and x <= room.maxX
        and y >= room.minY and y <= room.maxY
end

local function GetDoors(roomIndex)
    local room = ROOMS[roomIndex]
    if not room then return {} end

    local objs = API.ReadAllObjectsArray({0, 12}, {-1}, {})
    local doors = {}

    for _, obj in ipairs(objs) do
        if IsValidDoorObject(obj) and IsInRoom(obj, room) then
            table.insert(doors, obj)
        end
    end

    return doors
end

local function CheckRoomProgression(roomIndex, currentRoom)
    if currentRoom == roomIndex + 1 then
        print("[DOORS] SUCCESS → Room", currentRoom)
        state.room = currentRoom
        state.trapDone = false
        ResetDoorState()
        return true
    end
    return false
end

local function WaitForAnimationStart()
    if doorState.waitingAnim then
        if IsPickLockAnimActive() then
            doorState.waitingAnim = false
        end
        return false
    end
    return true
end

local function WaitForAnimationEnd()
    if IsPickLockAnimActive() then
        return false
    end
    return true
end

local function CheckDoorProgress(currentCount)
    if currentCount < doorState.lastCount then
        print("[DOORS] Left to try:", doorState.lastCount, "→", currentCount)
        doorState.lastCount = currentCount
        doorState.locked = false
        doorState.retryTicks = 0
        return true
    end
    return false
end

local function HandleDoorRetry(currentCount)
    if currentCount == doorState.lastCount then
        doorState.retryTicks = doorState.retryTicks + 1
        print("[DOORS] No change tick:", doorState.retryTicks)

        if doorState.retryTicks >= CONSTANTS.DOOR_RETRY_LIMIT then
            print("[DOORS] Retry clicking door")
            Interact:Object("Tomb door", "Pick-lock")
            doorState.retryTicks = 0
            doorState.waitingAnim = true
            doorState.lastCount = currentCount
        end
        return false
    end
end

local function HandleDoorLockedState(doorCount)
    if not WaitForAnimationStart() then return false end
    if not WaitForAnimationEnd() then return false end

    API.RandomSleep2(
        CONSTANTS.DOOR_RETRY_CHECK_DELAY.min,
        CONSTANTS.DOOR_RETRY_CHECK_DELAY.mid,
        CONSTANTS.DOOR_RETRY_CHECK_DELAY.max
    )

    if CheckDoorProgress(doorCount) then return false end
    HandleDoorRetry(doorCount)
    return false
end

local function ClickDoor()
    print("[DOORS] Clicking door")
    Interact:Object("Tomb door", "Pick-lock")
    doorState.locked = true
    doorState.waitingAnim = true
end

local function HandleDoors(roomIndex)
    if not state.trapDone then return false end

    local doors = GetDoors(roomIndex)
    local count = #doors
    if count == 0 then return false end

    doorState.lastCount = doorState.lastCount or count
    local currentRoom = GetCurrentRoom()

    if CheckRoomProgression(roomIndex, currentRoom) then
        return true
    end

    if doorState.locked then
        return HandleDoorLockedState(count)
    end

    ClickDoor()
    doorState.lastCount = count
    doorState.retryTicks = 0
    return false
end

local function HandleTrap(roomIndex)
    if state.trapDone or not InRoom(roomIndex) then return end

    Interact:Object("Spear trap", "Pass")
    API.RandomSleep2(600, 1000, 150)

    local start = GetPlayerPos()
    WaitForMovement(start, 15, "[TRAP] movement")
    UTILS.SleepUntil(function()
        return InPostTrap(roomIndex)
    end, 15, "[TRAP] post")

    state.trapDone = true
    state.trapJustFinished = true
    print("[TRAP] Completed")
end

local function WaitForSarcophagusCleared()
    UTILS.SleepUntil(function()
        local objs = API.GetAllObjArray1({CONSTANTS.SARCOPHAGUS_ID}, 20, {0})
        return not objs or #objs == 0
    end, 20, "[ROOM 8] waiting sarcophagus removal")
end

local function HandleRoom8()
    if state.room ~= 8 then return false end

    if not state.trapDone then
        HandleTrap(8)
        return false
    end

    if not InPostTrap(8) then
        return false
    end

    API.RandomSleep2(800, 600, 120)
    print("[ROOM 8] Post confirmed → starting sarcophagus")

    Interact:Object("Engraved sarcophagus", "Open")
    WaitForSarcophagusCleared()
    API.RandomSleep2(1200, 800, 200)
    print("[ROOM 8] Sarcophagus cleared")

    Interact:Object("Tomb door", "Quick-leave tomb")
    print("[ROOM 8] Exit clicked")
    return true
end

local function RunRoom(roomIndex)
    if not InRoom(roomIndex) then return false end

    HandleTrap(roomIndex)

    if state.trapJustFinished then
        API.RandomSleep2(800, 600, 120)
        state.trapJustFinished = false
    end

    return HandleDoors(roomIndex)
end

local function HandleRoomProgression()
    local detected = GetCurrentRoom()
    if not state.roomLocked and detected and detected > state.room then
        print(string.format("[ROOM] Room %d → Room %d", state.room, detected))
        state.room = detected
        state.trapDone = false
        state.trapJustFinished = false
        ResetDoorState()
    end
end

local function ExecuteRoomLogic()
    if state.room == 8 then
        state.roomLocked = true
        HandleRoom8()
    elseif InAreaCoords(CONSTANTS.OUTSIDE_AREA.x, CONSTANTS.OUTSIDE_AREA.y,
                        CONSTANTS.OUTSIDE_AREA.radius, CONSTANTS.OUTSIDE_AREA.z) then
        state.roomLocked = false
        FullReset()
    elseif state.room <= 7 then
        state.roomLocked = false
        RunRoom(state.room)
    end
end

local function CheckSceptreStop()

    -- only check when outside pyramid
    if not API.PInArea(3288, 10, 2801, 10, 0) then
        return false
    end

    if Inventory:InvItemcount(21536) > 0 then
        print("[STOP] Sceptre of the gods obtained")

        API.Write_LoopyLoop(false)
        return true
    end

    return false
end

local NOTE_ITEMS = {9040, 9028, 21570, 20661, 9034}

local function IsOutside()
    return API.PInArea(3288, 10, 2801, 10, 0)
end

local function NoteStuff(items)

    if type(items) == "number" then
        items = { items }
    end

    if Inventory:InvStackSize(43045) <= 0 then
        print("[NOTE] Missing notepaper")
        return false
    end

    for _, item in ipairs(items) do

        if Inventory:InvItemcount(item) > 0 then
            Inventory:NoteStuff(item)
            API.RandomSleep2(100, 300, 100)
            print("[NOTE] Noting item:", item)
        end

    end

    return true
end

API.Write_LoopyLoop(true)

while API.Read_LoopyLoop() do

    if IsOutside() and Inventory:IsFull() then
    NoteStuff(NOTE_ITEMS)
    end

    if CheckSceptreStop() then
        break
    end

    Outside()
    Inside()
    HandleRoomProgression()
    ExecuteRoomLogic()

    API.RandomSleep2(200, 100, 150)
end